%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG GRUB]

; ================================================

; ARQUIVO APENAS DE TESTE, AINDA NÃO FUNCIONAL!
; BUGS E PROBLEMAS DESCONHECIDOS!

; ================================================

	mov ax, 0800h
	xor SI, SI
	xor DI, DI
	cld
	mov DS, AX
	mov ES, AX
	mov FS, AX
	mov GS, AX
	cli
	mov ax, 7D00h
	mov ss, ax
	mov sp, 3000h
	sti
	mov ah, 00h
	mov al, 03h
	int 10h
	
Start:
	mov si, String
	call PrintString
	mov ax, 0x003A
	call Print_Hexa_Value16
	

jmp $

; Imprime representação hexadecimal de 32 bits colocado em SI
Print_Hexa_Value32:
	pusha
	push ax
	and eax, 0xFFFF0000
	shr eax, 16
	call Print_Hexa_Value16
	pop ax
	call Print_Hexa_Value16
	popa
ret

; Imprime representação hexadecimal de 16 bits colocado em SI
Print_Hexa_Value16:
	pusha
	mov DX, 0xF000
	mov CL, 12
	mov SI, AX
Print_Hexa16:
	mov BX, SI
	and BX, DX
	shr BX, CL
	push SI
	mov AH, 0Eh
	mov AL, byte[Vetor + BX]
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
	
; Imprime String colocada em SI	
PrintString:
	pusha
	mov AH, 0eh
	mov AL, [SI]
Print:
	int 10h
	inc SI
	mov AL, [SI]
	cmp AL, 0
	jnz Print
	popa
ret

BreakLine:
	pusha
	mov ah, 0eh
	mov al, 13
	int 10h
	mov al, 10
	int 10h
	popa
ret

String db "Valor qualquer : ",0
Vetor  db "0123456789ABCDEF"
