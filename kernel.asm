%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/info.lib"
[BITS SYSTEM]
[ORG KERNEL]

	
OS_VECTOR_JMP:
	jmp OSMain                ; 0000h (called by VBR)
	jmp PrintNameFile         ; 0003h
	jmp Print_Hexa_Value16    ; 0006h
	jmp Print_String          ; 0009h
	jmp Break_Line            ; 000Ch
	jmp Create_Panel          ; 000Fh
	jmp Clear_Screen          ; 0012h
	jmp Move_Cursor			  ; 0015h
	jmp Get_Cursor            ; 0018h
	jmp Show_Cursor			  ; 001Bh
	jmp Hide_Cursor			  ; 001Eh
	jmp Kernel_Menu			  ; 0021h
	jmp Write_Info			  ; 0024h
	jmp PrintNameFile         ; 0027h
	jmp WMANAGER_INIT         ; 002Ah
	jmp Print_Hexa_Value8     ; 002Dh
	jmp Play_Speaker_Tone     ; 0030h
	jmp Print_Dec_Value32     ; 0033h
	jmp Print_Hexa_Value32 	  ; 0036h
	jmp Print_Fat_Date 		  ; 0039h
	jmp Print_Fat_Time		  ; 003Ch
	jmp Calloc                ; 003Fh
	jmp Free                  ; 0042h
	jmp END                   ; 0045h
	
; _____________________________________________
; Directives and Inclusions ___________________

%INCLUDE "Hardware/monitor.lib"
%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"
%INCLUDE "Hardware/speaker.lib"

NameSystem db "KiddieOS",0

VetorHexa  db "0123456789ABCDEF",0
VetorCharsLower db "abcdefghijklmnopqrstuvwxyz",0
VetorCharsUpper db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0

VetorDec 	db "0123456789",0
Zero 		db 0

Extension  db "DRV"

PressKey   db "Press any key to continue...",0

; _____________________________________________

%DEFINE DRIVERS_OFFSET  	  KEYBOARD
%DEFINE FAT16.LoadAllFiles    FAT16
%DEFINE FAT16.LoadFatVbrData  FAT16+15
%DEFINE MEMX86.Detect_Low_Memory 	MEMX86+0
%DEFINE KEYBOARD.Initialize 		KEYBOARD+0
%DEFINE KEYBOARD.Enable_Scancode 	KEYBOARD+3
%DEFINE KEYBOARD.Disable_Scancode 	KEYBOARD+6
%DEFINE KEYBOARD.Set_Default_Parameters 	KEYBOARD+9

%DEFINE PCI.Init_PCI 	PCI

Shell.CounterFName  EQU  (SHELL16+6)
FAT16.DirSegments 	EQU  (FAT16+20)   ; era 17

; _____________________________________________
; Starting the System _________________________

OSMain:
		cld
		mov 	ax, 0x3000		;0x0C00
		mov 	ds, ax
		mov 	es, ax
		mov 	fs, ax
		mov 	gs, ax
		mov 	ax, 0x0000		;0x07D0
		mov 	ss, ax
		mov 	sp, 0x1990		;0xFFFF

	; ===============================================
	; Fill IVT with DOS Interrupt Vector
	
	push 	es
	xor 	ax, ax
	mov 	es, ax
	xor 	bx, bx
	push 	ds
	pop 	ax
	add 	bx, (21h * 4)
	mov 	word[es:bx], DOS_INT_21H
	add 	bx, 2
	mov 	word[es:bx], ax
	pop 	es
	 
	; ===============================================
	
	;call 	Play_Sound
	; Text Mode
	mov 	ah, 00h
	mov 	al, 03h
	int 	10h
	
	call 	FAT16.LoadFatVbrData
	
	mov 	si, Extension
	mov 	bx, DRIVERS_OFFSET
	mov 	word[FAT16.DirSegments], 0x0200	; era 0x07C0
	
	call 	FAT16.LoadAllFiles
	call 	KEYBOARD.Initialize
	call 	MEMX86.Detect_Low_Memory
	call 	PCI.Init_PCI
	clc
	
	mov 	si, Command
	call 	Shell.Execute
	mov 	si, Command1
	call 	Shell.Execute
	mov 	si, Command2
	call 	Shell.Execute
	jmp 	Load_Menu
Shell.Execute:
	jmp 	SHELL16+3
	Command db "cd kiddieos\users",0
	Command1 db "k:\kiddieos\programs\procx86.kxe",0
	Command2 db "..\programs\data.kxe -read -config",0
	times 10 db 0
	
Load_Menu:
	mov 	si, PressKey
	call 	Print_String
	mov 	ah, 00h
	int 	16h
	

Kernel_Menu:
	call 	Hide_Cursor   ; Set Cursor Shape Hide
	
	Back_Blue_Screen:
		mov     bh, 0001_1111b     ; Blue_White 
		mov     cx, 0x0000         ; CH = 0, CL = 0     
		mov     dx, 0x1950         ; DH = 25, DL = 80
		call    Create_Panel
		
	Dialog_Panel:
		mov     bh, 0100_1111b     ; Red_White 
		mov     cx, 0x0818         ; CH = 8, CL = 24     
		mov     dx, 0x1038         ; DH = 16, DL = 56
		call    Create_Panel
		mov     bh, 0111_0000b     ; White_Black
		mov     cx, 0x0919         ; CH = 9, CL = 25     
		mov     dx, 0x0F37         ; DH = 15, DL = 55
		call    Create_Panel
		
	Dialog_Options:	
		add 	ch, 2
		add 	cl, 1
		push 	cx
		pop		dx
		mov 	byte[Counter], 0
		mov 	byte[Selection], ch
		mov     bh, 0100_1111b     ; Red_White
		call	Select_Event
		push 	dx
	Write_Options:
		pop 	dx
		push 	dx
		call	Move_Cursor
		mov 	si, Option1
		call	Print_String
		inc 	dh
		call	Move_Cursor
		mov 	si, Option2
		call	Print_String
		inc		dh
		call	Move_Cursor
		mov 	si, Option3
		call	Print_String
		pop 	dx
		push 	dx
		mov 	ax, G3
		call 	Play_Speaker_Tone
		jmp 	Select_Options
		
		QUANT_OPTIONS  EQU 3
		Option1    db "Textual Mode   (shell16.osf)",0
		Option2    db "Graphical Mode (winmng.osf)",0
		Option3    db "System Informations",0
		Selection  db 0
		Counter	   db 0
		Systems    dw SHELL16_INIT, WMANAGER_INIT, SYSTEM_INFORMATION
		  
		  
	Select_Options:
		mov 	ah, 00h
		int 	16h
		cmp 	ah, 0x50
		je 		IncSelection
		cmp 	ah, 0x48
		je 		DecSelection
		cmp 	al, 0x0D
		je 		RunSelection
		jmp 	Select_Options
		
	IncSelection:
		cmp		byte[Counter], QUANT_OPTIONS-1
		jne		IncNow
		mov 	byte[Counter], 0
		call 	Erase_Select
		sub		ch, 2
		call	Focus_Select
		jmp 	Write_Options
		IncNow:
			inc 	byte[Counter]
			call 	Erase_Select
			inc 	ch
			call	Focus_Select
			jmp 	Write_Options
	DecSelection:
		cmp		byte[Counter], 0
		jne		DecNow
		mov 	byte[Counter], QUANT_OPTIONS-1
		call 	Erase_Select
		add		ch, 2
		call	Focus_Select
		jmp 	Write_Options
		DecNow:
			dec 	byte[Counter]
			call 	Erase_Select
			dec 	ch
			call	Focus_Select
			jmp 	Write_Options
			
	RunSelection:
		pop 	dx
		xor 	bx, bx
		mov 	bl, byte[Counter]
		shl		bx, 1
		mov 	bx, word[Systems + bx]
		mov 	ax, A3
		call 	Play_Speaker_Tone
		jmp 	bx
	
	Erase_Select:
		mov  	ch, byte[Selection]
		mov 	dh, ch
		mov     bh, 0111_0000b     ; Black_White
		call 	Select_Event
		mov  	ch, byte[Selection]
	ret
	
	Focus_Select:
		mov 	dh, ch
		mov 	byte[Selection], ch
		mov     bh, 0100_1111b     ; Red_White
		call 	Select_Event
	ret	
	
	Select_Event:
		push  	dx
		add		dl, 28
		call	Create_Panel
		pop 	dx
	ret
	
	
	
	WMANAGER_INIT:
		
		mov		ax, 4800h 
		mov 	fs, ax
		mov 	ax, 5800h
		mov 	gs, ax
		
		call 	WINMNG
		
		xor 	ax, ax
		int 	16h
		
		jmp 	OSMain
		
		
	SHELL16_INIT:
	
		jmp 	3000h:SHELL16	; Era 0C00h:...
		
		
	SYSTEM_INFORMATION:
		mov     bh, 0010_1111b     ; Green_White 
		mov     cx, 0x0616         ; CH = 8, CL = 24     
		mov     dx, 0x133A         ; DH = 16, DL = 56
		call    Create_Panel
		mov     bh, 0111_0010b     ; White_Green
		mov     cx, 0x0717         ; CH = 9, CL = 25     
		mov     dx, 0x1239         ; DH = 15, DL = 55
		call    Create_Panel
		inc 	ch
		inc 	cl
		mov 	dx, cx
		mov 	cx, 10
		mov 	si, Informations
		call	Write_Info
		mov 	ah, 00h
		int 	16h
		jmp 	Back_Blue_Screen
		
		Informations:
		SystemName  db "System Name  : KiddieOS",0
		Version 	db "Version      : ",VERSION,0
		Author      db "Author       : Francis (BFTC)",0
		Arquiteture db "Arquitecture : 16-bit (x86)",0
		FileSystem  db "File System  : FAT16",0
		RunningFile db "Running File : kernel.osf",0
		GuiVersion  db "GUI Version  : Window 2.0",0
		SourceCode  db "Source-Code  : Assembly x86",0
		Lang        db "Language     : English (US)",0
		DateTime    db "Date/Time    : 05/01/2021 08:31",0
		
		
		
; _____________________________________________
	

; _____________________________________________
; Kernel Sub-Routines _________________________


Print_Fat_Time:
	pusha
	mov 	bx, ax
	xor 	eax, eax
	mov 	ax, bx
	and 	ax, (11111b << 11)
	shr 	ax, 11
	cmp 	al, 10
	jnb 	NoTimeZero1
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero1:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, ':'
	int 	0x10
	mov 	ax, bx
	and 	ax, (111111b << 5)
	shr 	ax, 5
	cmp 	al, 10
	jnb 	NoTimeZero2
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero2:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, ':'
	int 	0x10
	mov 	ax, bx
	and 	ax, 11111b
	cmp 	al, 10
	jnb 	NoTimeZero3
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero3:
	call 	Print_Dec_Value32
	popa
ret

Print_Fat_Date:
	pusha
	mov 	bx, ax
	xor 	eax, eax
	mov 	ax, bx
	and 	ax, 11111b
	cmp 	al, 10
	jnb 	NoZero1
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoZero1:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, '/'
	int 	0x10
	mov 	ax, bx
	and 	ax, (1111b << 5)     ;(1111b << 5) = 480 = 111100000b
	shr 	ax, 5
	cmp 	al, 10
	jnb 	NoZero2
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoZero2:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, '/'
	int 	0x10
	mov 	ax, bx
	and 	ax, (1111111b << 9)
	shr 	ax, 9
	sub 	ax, 20
	add 	ax, 2000
	call 	Print_Dec_Value32
	popa
ret

; Exibe nomes de arquivos do FAT16 colocados em ES:DI
PrintNameFile:
	pusha
	mov 	cx, 11
	mov 	ah, 0x0E
	mov 	dl, byte[es:di + 11]
	xor 	bx, bx
Analyze:
	mov 	al, byte[es:di]
	cmp 	al, 0x20
	je 		NoPrintSpace
	cmp 	cx, 11
	je 		Display
	cmp 	al, "."
	je 		Display
	mov 	bl, al
	cmp 	bl, 0x3A
	jb 		ConvertNumber
	jmp 	ConvertCase
ConvertNumber:
	sub 	bl, 0x30
	mov 	al, byte[VetorHexa + bx]
	jmp 	Display
ConvertCase:
	sub 	bl, 0x41
	mov 	al, byte[VetorCharsLower + bx]
Display:
	int 	0x10
	inc 	byte[Shell.CounterFName]
NoPrintSpace:
	cmp 	cx, 4
	jne 	NoPrintDot
	cmp 	dl, 0x20
	jne 	NoPrintDot
	mov 	al, '.'
	int 	10h
NoPrintDot:
	inc 	di 
    loop 	Analyze
.DONE:
	popa
RET

; Exibe Strings estáticas do sistema operacional colocados em DS:SI
Print_String:
	pusha
	mov 	ah, 0eh
	prints:
		mov 	al, [si]
		cmp 	al, 0
		jz		ret_print
		inc 	si
		int 	10h
		jmp 	prints
	ret_print:
		popa
ret	

; Imprime representação hexadecimal de 16 bits colocado em DS:SI
Print_Hexa_Value16:
	pusha
	mov SI, AX
	mov DX, 0xF000
	mov CL, 12
Print_Hexa16:
	mov BX, SI
	and BX, DX
	shr BX, CL
	push SI
	mov AH, 0Eh
	mov AL, byte[VetorHexa + BX]
	int 10h
	pop SI
	cmp CL, 0
	jz RetHexa
	sub CL, 4
	shr DX, 4
	jmp Print_Hexa16
RetHexa:
	popa
ret

; Imprime representação hexadecimal de 8 bits colocado em DS:SI
Print_Hexa_Value8:
	pusha
	xor AH, AH
	mov SI, AX
	mov DX, 0x00F0
	mov CL, 4
Print_Hexa8:
	mov BX, SI
	and BX, DX
	shr BX, CL
	push SI
	mov AH, 0Eh
	mov AL, byte[VetorHexa + BX]
	int 10h
	pop SI
	cmp CL, 0
	jz RetHexa1
	sub CL, 4
	shr DX, 4
	jmp Print_Hexa8
RetHexa1:
	popa
ret

Print_Hexa_Value32:
	pushad
	mov 	esi, eax
	mov 	edx, 0xF0000000
	mov 	cl, 28
Print_Hexa32:
	mov 	ebx, esi
	and 	ebx, edx
	shr 	ebx, cl
	push 	esi
	mov 	ah, 0Eh
	mov 	al, byte[VetorHexa + bx]
	int 	10h
	pop 	esi
	cmp 	cl, 0
	jz 		RetHexa32
	sub 	cl, 4
	shr 	edx, 4 
	jmp 	Print_Hexa32
	RetHexa32:
	popad
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
	push 	bx
	mov 	bx, ax
	mov 	ah, 0Eh
	mov 	al, byte[VetorDec + bx]
	int 	10h
	pop 	bx
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

Write_Info:
	call	Move_Cursor
	call	Print_String
	call 	NextInfo
	inc 	dh
	loop 	Write_Info
ret
	
NextInfo:
	inc 	si
	cmp 	byte[si], 0
	jne 	NextInfo
	inc 	si
ret

; Quebra de linha na exibição de Strings
Break_Line:
	mov ah, 0Eh
	mov al, 10
	int 10h
	mov al, 13
	int 10h
ret

; Cria painel no modo texto usando rotina de Limpar tela
Create_Panel:
	pusha
	mov ah, 06h
	mov al, 0
	int 10h
	popa
ret

Clear_Screen:
	mov 	ah, 06h
	mov 	al, 0
	mov 	ch, 0
	mov 	cl, 0
	mov 	dh, 25
	mov 	dl, 80
	int 	10h
ret

; Movimenta o cursor dado os parâmetros em DX
Move_Cursor:
	pusha
	mov ah, 02h
	mov bh, 00h
	int 10h
	popa
ret

Get_Cursor:
	push ax
	push bx
	push cx
	mov ah, 03h
	mov bh, 00h
	int 10h
	pop cx
	pop bx
	pop ax
ret

Hide_Cursor:
	mov 	ah, 01h
	mov 	ch, 20h   ; bit 5 set is hiding cursor
	mov 	cl, 07h
	int 	10h
ret

Show_Cursor:
	mov 	ah, 01h
	mov 	ch, 00h
	mov 	cl, 07h
	int 	10h
ret


; ==============================================================
; Rotina que mostra o conteúdo do vetor formatado
; IN: ECX = Tamanho do Vetor
;     ESI = Endereço do Vetor

; OUT: Nenhum.
; ==============================================================
Show_Vector32:
	pushad
	
	mov 	ax, 0x0E7B
	int 	0x10
	xor 	ebx, ebx
	
ShowVector:
	push 	ebx
	shl		ebx, 2
	mov 	eax, dword[esi + ebx]
	call 	Print_Dec_Value32
	pop 	ebx
	inc 	ebx
	mov 	ah, 0x0E
	mov 	al, ','
	int 	0x10
	loop 	ShowVector
	mov 	ax, 0x0E7D
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	mov 	ax, 0x0E0A
	int 	0x10
	
	popad
ret

; ==============================================================
; Rotina que aloca uma quantidade de bytes e retorna endereço
; IN: ECX = Tamanho de Posições (Size)
;     EBX = Tamanho do Inteiro (SizeOf(int))

; OUT: EAX = Endereço Alocado
; ==============================================================
Calloc:
	pushad
	
	xor 	eax, eax
	push 	ds
	pop 	es
	mov 	eax, MEMX86
	push 	ecx
	mov 	ecx, MEMX86_NUM_SECTORS
	
	Skip_Offset:
		add 	eax, 512
		loop 	Skip_Offset
		
	add 	eax, 4
	mov 	edi, eax
	xor 	eax, eax
	pop 	ecx
	push 	edi
	
	;mov 	es, ax
	
	cmp 	ebx, 1
	je 		Alloc_Size8
	cmp 	ebx, 2
	je 		Alloc_Size16
	cmp 	ebx, 4
	je 		Alloc_Size32
	jmp 	Return_Call
	
	; TODO 
	; Dados que podem estar na memória serão perdidos
	; nesta alocação, então melhor certificar que salvamos 
	; estes dados em algum lugar (talvez via push)
	; e recuperarmos na função Free()
	Alloc_Size8:  
		mov 	dword[Size_Busy], ecx
		rep 	stosb
		jmp 	Return_Call
	Alloc_Size16: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 1
		rep 	stosw
		jmp 	Return_Call
	Alloc_Size32: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 2
		rep 	stosd
		jmp 	Return_Call
	
Return_Call:
	pop 	DWORD[Return_Var_Calloc]
	popad
	mov 	eax, DWORD[Return_Var_Calloc]
	mov 	byte[Memory_Busy], 1
ret

Return_Var_Calloc dd 0
Size_Busy 	dd 0
Memory_Busy db 0


; ==============================================================
; Libera espaço dado um endereço alocado
; IN: EBX = Ponteiro de Endereço Alocado
;
; OUT: Nenhum.
; ==============================================================
Free:
	pushad
	mov 	edi, ebx
	;mov 	dword[ebx], 0x00000000
	push 	ds
	pop 	es
	mov 	al, 0
	mov 	ecx, dword[Size_Busy]
	rep 	stosb
	
	;push 	ds
	;pop 	es
	
	mov 	dword[Size_Busy], 0
	mov 	dword[Return_Var_Calloc], 0
	mov 	dword[Memory_Busy], 0
	popad
ret

; ---------------------------------------------------------
; DOS Services Routines

DOS_INT_21H:
	push 	ds 
	push 	cs
	pop 	ds
	push 	bx
	push 	ax
	xor 	bx, bx
	shr 	ax, 8
	mov 	bx, ax
	shl 	bx, 1
	mov 	bx, word[DOS_SERVICES + bx]
	jmp 	bx
	
DOS_SERVICES:
	dw 0x0000                   ; Função 0 (0x00)
	dw 0x0000                   ; Função 1 (0x01)
	dw dos_write_char           ; Função 2 (0x02)
	dw 0x0000                   ; Função 3 (0x03)
	dw 0x0000                   ; Função 4 (0x04)
	dw 0x0000                   ; Função 5 (0x05)
	dw 0x0000                   ; Função 6 (0x06)
	dw 0x0000                   ; Função 7 (0x07)
	dw 0x0000                   ; Função 8 (0x08)
	dw dos_write_string         ; Função 9 (0x09)
	
dos_write_char:
	pop 	ax
	pop 	bx
	pusha
	
	mov 	ah, 0x0E
	mov 	al, dl
	int 	0x10
	
	popa
	pop 	ds
iret


dos_write_string:
	pop 	ax
	pop 	bx
	pop 	ds
	pusha
	
	add 	dx, (0x1C << 4)
	mov 	si, dx
	mov 	ah, 0eh
	dos_prints:
		mov 	al, [si]
		cmp 	al, '$'
		jz		dos_ret_print
		inc 	si
		int 	10h
		jmp 	dos_prints
	dos_ret_print:
	
	popa
iret
; ---------------------------------------------------------

; --------------------------------------------------------


END:
; Zera na reinicialização todos os endereços de memória utilizados
	; ________________________________________________________________
	mov word[fs:POSITION_X], 0000h
	mov word[fs:POSITION_Y], 0000h
	mov word[fs:QUANT_FIELD], 0000h
	mov word[fs:LIMIT_COLW], 0000h
	mov word[fs:LIMIT_COLX], 0000h
	mov word[fs:QuantPos], 0000h
	mov word[CountPositions], 0000h
	mov byte[fs:StatusLimitW], 0
	mov byte[fs:StatusLimitX], 0
	mov byte[fs:CursorTab], 0
	; ________________________________________________________________
	; Reinicia sistema
	; _________________________________________
	mov ax, 0040h
	mov ds, ax
	mov ax, 1234h
	mov [0072h], ax
	jmp 0FFFFh:0000h
; _____________________________________________
; _____________________________________________
