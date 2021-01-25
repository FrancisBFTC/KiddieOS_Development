%INCLUDE "Hardware/memory.lib"
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
	jmp END                   ; 002Dh

;Vetor1: dw VetorHexa
;Vetor2: dw VetorCharsLower
;Vetor3: dw VetorCharsUpper
; _____________________________________________
; Directives and Inclusions ___________________

%INCLUDE "Hardware/monitor.lib"
%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"

NameSystem db "KiddieOS",0

VetorHexa  db "0123456789ABCDEF",0
VetorCharsLower db "abcdefghijklmnopqrstuvwxyz",0
VetorCharsUpper db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0

; _____________________________________________

%DEFINE DRIVERS_OFFSET  KEYBOARD
%DEFINE FAT16.LoadAllFiles  FAT16
Extension  db "SYS"

Shell.CounterFName  EQU SHELL16+6
FAT16.DirSegments 	EQU   (FAT16+14)

; _____________________________________________
; Starting the System _________________________

OSMain:
	cli		
	mov ax, 0x07D0
	mov ss, ax	
	mov sp, 0FFFFh
	sti		

	cld				

	mov 	ax, 0800h
	mov 	ds, ax
	mov 	es, ax
	
	
	; Text Mode
	mov 	ah, 00h
	mov 	al, 03h
	int 	10h
	
	
	
	mov 	si, Extension
	mov 	bx, DRIVERS_OFFSET
	mov 	word[FAT16.DirSegments], 0x07C0
	call 	FAT16.LoadAllFiles
	
	mov		ax, 4800h 
	mov 	fs, ax
	mov 	ax, 5800h
	mov 	gs, ax
	
	mov ah, 00h
	int 16h

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
		jmp 	Select_Options
		
		QUANT_OPTIONS  EQU 3
		Option1    db "Textual Mode   (shell16.bin)",0
		Option2    db "Graphical Mode (wmanager.bin)",0
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
		call 	VGA.SetVideoMode
		call 	DrawBackground
		call 	EffectInit
		
		jmp 	0800h:WMANAGER
		
		
	SHELL16_INIT:
	
		jmp 	0800h:SHELL16
		
		
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
		Version     db "Version      : v1.2.0",0
		Author      db "Author       : Francis (BFTC)",0
		Arquiteture db "Arquitecture : 16-bit (x86)",0
		FileSystem  db "File System  : FAT16",0
		RunningFile db "Running File : kernel.bin",0
		GuiVersion  db "GUI Version  : Window 2.0",0
		SourceCode  db "Source-Code  : Assembly x86",0
		Lang        db "Language     : English (US)",0
		DateTime    db "Date/Time    : 05/01/2021 08:31",0
		
		
		
; _____________________________________________
	

; _____________________________________________
; Kernel Sub-Routines _________________________

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
