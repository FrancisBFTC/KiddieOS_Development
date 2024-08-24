[BITS 16]
[ORG 0x0800]

jmp 	Read_Sectors
jmp 	Print_String
jmp 	Write_Info
jmp 	Move_Cursor
jmp 	ASCII_Convert
jmp 	Print_Dec_Value32
jmp 	Print_Char
jmp 	Show_Bytes_Info
jmp 	Show_Label
jmp 	Check_Signature
jmp 	Check_Error_Partition

; ***************************************************************************************
; BOOT LIBRARY

BOOT_LIBRARY:
	DAPSizeOfPacket 	db 10h
	DAPReserved     	db 00h
	DAPTransfer     	dw 0001h
	DAPBuffer       	dd 0
	DAPStart        	dq 0

; ----------------------------------------------------
; Read logical sectors
	Read_Sectors:
		mov 	[DAPBuffer], bx
		mov 	[DAPBuffer+2], es        	; ES:BX - Para onde os dados vão
		mov 	[DAPStart], eax         	; Setor lógico inicial
	_MAIN:
		mov 	di, 0x0005                  	; 5 tentativas de leitura
	_SECTORLOOP:
		push 	eax
		push 	bx
		push 	cx
		
		mov 	si, ErrorEDDs
		mov 	bx, 0x55aa
		mov 	ah, 0x41
		int 	0x13
		jc 		ERROR
		cmp 	bx, 0xaa55
		jne 	ERROR
		
		mov 	ah, 0x42
		mov 	si, DAPSizeOfPacket
		int 	0x13
		jnc 	_SUCCESS           ; Testa por erro de leitura
		xor 	ax, ax             ; BIOS Reset Disk
		int 	0x13
		dec 	di
		
		pop 	cx
		pop 	bx
		pop 	eax
		
		jnz 	_SECTORLOOP
		
		mov 	si,ErrorSector
		jmp 	ERROR
		
    _SUCCESS:
		pop 	cx
		pop 	bx
		pop 	eax
		
		; Desloca para próximo Buffer
		add 	bx, 512
		cmp 	bx, 0x0000
		jne 	_NEXTSECTOR
		
		push 	eax
		mov 	ax, es
		add 	ax, 0x1000
		mov 	es, ax
		pop 	eax
		
	_NEXTSECTOR:
		inc 	eax
		mov 	[DAPBuffer], bx
		mov 	[DAPStart], eax
		loop 	_MAIN
		xor 	eax, eax
ret
; ----------------------------------------------------

; ----------------------------------------------------
; Print chars
Print_String:
	mov		ah, 0x0e	; função TTY da BIOS imprime caracter na tela
Print:
	lodsb			    ; a cada loop carrega si p --> al, actualizando si
	int 	0x10		; interrupção de vídeo
	cmp 	al, 0		; compara al com o 0
	jne 	Print		; se al for 0 pula para o final do programa
ret
; ----------------------------------------------------

; ----------------------------------------------------
; Print informations set
Write_Info:
	mov 	ah, 02h
	mov 	bh, 00h
	int 	10h
	call	Print_String
	inc 	dh
	loop 	Write_Info
ret
; ----------------------------------------------------

Move_Cursor:
	push 	bx
	mov 	ah, 02h
	mov 	bh, 00h
	int 	10h
	inc 	dh
	pop 	bx
ret

ASCII_Convert:
	add 	al, 0x30
	mov 	ah, 0x0E
	int 	10h
ret

Print_Dec_Value32:
	pushad
	cmp 	eax, 0
	je 		ZeroAndExit
	xor 	edx, edx
	mov 	ebx, 10
	mov 	ecx, 1000000000
DividePerECX:
	cmp 	eax, ecx      ; EAX = 950000
	jb 		VerifyZero
	mov 	byte[Zero], 1
	push 	eax
	div 	ecx
	xor 	edx, edx
	push 	ax
	call 	ASCII_Convert
	pop 	ax
	mul 	ecx
	mov 	edx, eax
	pop 	eax
	sub 	eax, edx
	xor 	edx, edx
DividePer10:
	cmp 	ecx, 1
	je 		Ret_Dec32
	push 	eax
	mov 	eax, ecx
	div 	ebx
	mov 	ecx, eax
	pop 	eax
	jmp 	DividePerECX
VerifyZero:
	cmp 	byte[Zero], 0
	je 		ContDividing
	push 	ax
	mov 	ax, 0E30h
	int 	10h
	pop 	ax
ContDividing:
	jmp 	DividePer10
ZeroAndExit:
	mov 	ax, 0E30h
	int  	10h
Ret_Dec32:
	mov 	byte[Zero], 0
	popad
ret
Zero 	db 0

Print_Char:
	mov 	ah, 0x0E
	int 	0x10
ret

Show_Bytes_Info:
	pushad
	mov 	si, prefix
	call 	Print_String
	lea 	si, [di + 12]
	mov 	eax, [si]
	xor 	edx, edx
	mul 	dword[BytesPerSector]
	div 	dword[MegaBytesNumber]
	call 	Print_Dec_Value32
	mov 	si, sufix
	call 	Print_String
	popad
ret

Show_Label:
	pusha
	mov 	dx, 0x061E
	call 	Move_Cursor
	mov 	si, LabelBoot
	call 	Print_String
	popa
ret

Check_Signature:
	mov 	si, MissSig
	cmp 	word[0x7DFE], 0xAA55     ; Verifica se existe assinatura de boot
	jne 	ERROR                    ; Se não existir, falha de boot
ret

Check_Error_Partition:
	mov 	si, PartNoFound
	cmp 	al, 0
    jz 		ERROR
ret

ERROR:
	call 	Print_String
	int 	0x18

	BytesPerSector 	dd 512
	MegaBytesNumber dd 1048576
	LabelBoot 	db "KiddieOS Boot Manager",0
	prefix 		db " -",0
	sufix 		db " MB",0
	ErrorSector   db "Error: Read Sector!",0xd,0xa,0
	ErrorEDDs     db "Error: BIOS EDDs not supported",0xd,0xa,0
	PartNoFound   db "Error: No Active Partition!",0xd,0xa,0
	MissSig       db "Error: VBR Missing Boot Signature!",0xd,0xa,0

; ***************************************************************************************