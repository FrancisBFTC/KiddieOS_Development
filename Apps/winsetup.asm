FORMAT MZ
STACK 256
entry text:main 

segment text
include "../Kiddieos/Library/user16.inc"

sysc.program	equ 0x3000:0x004B
win.graphics  	equ 0x3000:0x004E
shell.cmd 		equ 0x3000:0x0051
;tone.play 		equ 0x3000:0x0054

main:
	mov 	ax, datas
    mov 	ds, ax
	mov 	es, ax

	call 	get_argc
	mov 	[argc], eax
	cmp 	eax, 1
	jz 		no_args
	
	mov 	cx, 1				; argv index
	mov 	dx, argscopy		; buffer to copy string
	call 	get_argvstr
	
	mov 	bx, ax
	mov 	byte[argscopy + bx], '$'
	
	push 	bx
	mov		ah, 09h
	mov 	dx, processing
	int 	0x21
	mov		ah, 09h
	mov 	dx, argscopy
	int 	0x21
	pop 	bx
	
	mov 	byte[argscopy + bx], 0

	mov 	si, perm3
	call 	shell.cmd
	
	mov 	dx, argscopy
	mov 	WORD[baseaddr], 0x6A00
	call 	load_data
	
	cmp 	ax, 0
	jnz 	EXIT
	
	jmp 	with_args
	
no_args:
	mov 	si, perm2
	call 	shell.cmd
	
	mov 	dx, path2
	mov 	WORD[baseaddr], 0x6A00
	call 	load_data
	
	cmp 	ax, 0
	jnz 	EXIT
	
with_args:
	mov 	si, perm1
	call 	shell.cmd
	
	mov 	dx, path1
	mov 	WORD[baseaddr], 0x5000
	call 	load_data
	
	cmp 	ax, 0
	jnz 	EXIT
	
	call 	win.graphics
	
	push 	ds
	mov 	ax, 0x3000
	mov 	ds, ax
	mov 	bl, 1
	call 	sysc.program
	pop 	ds

	mov 	ax, 3
	int 	0x10
	
EXIT:
	mov 	ax, 0x4C02		; AL = 2 é necessário para redesenhar o Shell
	int 	0x21

load_data:
	push 	ds
	pop 	es
	push 	es
	
	; abertura do arquivo
	call 	open
	jc 		error_open
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
	jc 		error_read
	
	xor 	ax, ax
	jmp 	ret.load
	
check_bmp:
	cmp 	eax, 192054
	jz 		resolution_1
	
not_supported:
	mov		ah, 09h
	mov 	dx, size_error
	int 	0x21
	
	mov 	bx, [filehandler]
	call 	close
	
	mov 	ax, 1
	pop 	es
	ret
	
error_open:
	mov		ah, 09h
	mov 	dx, open_error
	int 	0x21
	mov 	ax, 1
	pop 	es
	ret

error_read:
	mov		ah, 09h
	mov 	dx, read_error
	int 	0x21
	
	mov 	bx, [filehandler]
	call 	close
	
	mov 	ax, 1
	pop 	es
	ret
	
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
	
	pop 	cx
	jc 		error_read
	
	add 	WORD [baseaddr], 0x1000
	
	loop 	read_bmp
	xor 	ax, ax
	
ret.load:
	mov 	bx, [filehandler]
	call 	close
	
	pop 	es
	ret

segment datas

filehandler dw 0x0000

highsize 	dw 0x0000
lowsize 	dw 0x0000
sizetot 	dd 0x00000000
baseaddr 	dw 0x0000
argc 		dd 0

path1  		db "K:\kiddieos\system16\winmng32.kxe",0
path2  		db "K:\KiddieOS\Users\BFTC\Images\welcome.bmp",0
perm1	 	db "chmod u=mdxrw K:\kiddieos\system16\winmng32.kxe",0
perm2	 	db "chmod u=mdxrw K:\KiddieOS\Users\BFTC\Images\welcome.bmp",0

size_error 	db "ERROR: BMP File not supported!",0x0D,0x0A,'$'
open_error 	db "ERROR: It's not possible opening the file!",0x0D,0x0A,'$'
read_error 	db "ERROR: It's not possible read the file!",0x0D,0x0A,'$'

processing 	db "Loading ",'$'
perm3 		db "chmod u=mdxrw "
argscopy:	times 100 db 0


