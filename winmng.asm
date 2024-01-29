%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"

[BITS SYSTEM]
[ORG WINMNG]

jmp 	winmng_setup
jmp 	Set_Video_Mode
;jmp 	Win_Program
; Se adicionar mais um salto aqui, não se esquecer de:
;	- Somar +3 no endereço de GUI_VARS em winmng32.asm
;	  para cada salto adicionado, por causa do VESA.lib

%INCLUDE "Hardware/VESA.lib"
%INCLUDE "Kiddieos/Library/user16.inc"

SHELL.cmd 	EQU SHELL16+3
		
winmng_setup:
	mov 	ax, 3
	int 	0x10
	
	call 	Set_Video_Mode
	
	mov 	si, perm1
	call 	SHELL.cmd
	mov 	si, perm2
	call 	SHELL.cmd
	
	mov 	dx, path1
	mov 	WORD[baseaddr], 0x5000
	call 	load_data
	
	mov 	dx, path2
	mov 	WORD[baseaddr], 0x6A00
	call 	load_data

;Win_Program:
	call 	SYSCMNG
	
ret

load_data:
	mov 	ax, ds
	mov 	es, ax
	
	; abertura do arquivo
	call 	open
	mov 	[filehandler], ax

	; pega o tamanho do arquivo
	mov 	bx, [filehandler]
	call 	get_file_size
	mov 	[highsize], dx
	mov 	[lowsize], ax
	mov 	[sizetot], eax
	
	cmp 	WORD [baseaddr], 0x5000
	jnz 	check_bmp
	
	; ler os dados do arquivo
	mov 	bx, [filehandler]
	mov 	cx,	[lowsize]
	mov 	ax, [baseaddr]
	mov 	es, ax
	xor 	dx, dx
	call 	read
	jmp 	ret.load
	
check_bmp:
	cmp 	eax, 192054
	jz 		resolution_1
	
not_supported:
	mov		ah, 09h
	mov 	dx, str_error
	int 	0x21
	jmp 	ret.load
	
resolution_1:
	mov 	cx, 3
read_bmp:
	push 	cx

	mov 	bx, [filehandler]
	mov 	cx,	(192054 / 3)	; 64018 = 0xFA12
	mov 	ax, [baseaddr]
	mov 	es, ax
	xor 	dx, dx
	call 	read
	
	add 	WORD [baseaddr], 0x1000
	
	pop 	cx
	loop 	read_bmp
	
ret.load:
	mov 	bx, [filehandler]
	call 	close
	
	ret

filehandler dw 0x0000

highsize 	dw 0x0000
lowsize 	dw 0x0000
sizetot 	dd 0x00000000
baseaddr 	dw 0x0000

path1  		db "kiddieos\system16\winmng32.kxe",0
path2  		db "KiddieOS\Users\BFTC\Images\Flower2.bmp",0
perm1	 	db "chmod u=mdxrw kiddieos\system16\winmng32.kxe",0
perm2	 	db "chmod u=mdxrw KiddieOS\Users\BFTC\Images\Flower2.bmp",0

str_error 	db "BMP File not supported!",0x0D,0x0A,'$'
