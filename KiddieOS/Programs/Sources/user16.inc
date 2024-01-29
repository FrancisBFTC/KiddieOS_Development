;	DOS PROGRAM LIBRARY 16-BIT


; ---------------------------------------------------
; GET CLI ARGUMENTS COUNT
; IN:
;   - nothing
; OUT:
;   - eax: ARGUMENTS COUNT (ARGC)
get_argc:
	push 	ebp
	
	mov 	ebp, esp
	mov 	eax, [ss:bp + 12 + 2]
	
	pop 	ebp	
ret
; ---------------------------------------------------

; ---------------------------------------------------
; GET CLI STRINGS VECTOR
; IN:
;   - nothing
; OUT:
;   - eax: STRINGS VECTOR (ARGV)
get_argv:
	push 	ebp
	
	mov 	ebp, esp
	mov 	eax, [ss:bp + 16 + 2]
	
	pop 	ebp	
ret
; ---------------------------------------------------

; ---------------------------------------------------
; GET ARGV STRING
; IN:
;   - cx: INDEX
;	- dx: BUFFER
; OUT:
;   - ax: 00h if error, cf = 1
;	- ax: CHARS COUNT COPIED if success, cf = 0
get_argvstr:
	push 	ebp
	mov 	ebp, esp
	mov 	eax, [ss:bp + 16 + 2]
	pop 	ebp	
	
	push 	ebp
	mov 	ebp, esp
	mov 	bx, [ss:bp + 12 + 2]
	pop 	ebp	

	push 	es
		
	cmp  	cx, bx
	jae 	error_copy
	
	mov 	esi, eax
	and 	eax, 0xFFFF0000
	shr 	eax, 4
	mov 	es, ax
	mov 	bx, cx
	shl 	bx, 2
	mov 	esi, [es:si + bx]
	mov 	di, dx
	xor 	cx, cx
copy_arg:
	mov 	al, [es:si]
	mov 	[di], al
	inc 	si
	inc 	di
	inc 	cx
	cmp 	al, 0
	jnz  	copy_arg
	dec 	di
	mov 	ax, cx
	dec 	ax
		
	cmp 	ax, 0
	jz 		error_copy
	
	pop 	es
	clc
	ret
	
error_copy:
	xor 	ax, ax
	pop 	es
	stc
	ret
; ---------------------------------------------------

; ---------------------------------------------------
; PRINTS STRING
; IN:
;   - dx: STRING
; OUT:
;   - nothing
print:
	pusha
	
	mov 	ah, 09h
	int 	21h
	
	popa
ret
; ---------------------------------------------------
	
; ---------------------------------------------------
; READ STRINGS
; IN:
;   - dx: BUFFER
; OUT:
;   - nothing
input:
	pusha
	
	push 	dx
	xor 	cx, cx
	mov 	di, dx
	mov 	cl, [di]
	add 	di, 2
	xor 	ax, ax
	rep 	stosb
	pop 	dx
		
	mov 	ah, 0Ah
	int 	21h
	
	popa
ret
; ---------------------------------------------------
	
; ---------------------------------------------------
; BREAK LINE
; IN:
;   - nothing
; OUT:
;   - nothing
breakl:
	pusha
	
	mov 	ah, 06h
	mov 	dl, 0x0A
	int 	0x21
	
	popa
ret
; ---------------------------------------------------
	
; ---------------------------------------------------
; PRINTS HEXSTRING
; IN:
;   - ax: HEXA NUMBER
; OUT:
;   - nothing
printhex:
    pusha
    
	push 	ax 
    and 	ax, 0xF000
    shr 	ax, 12
    call 	.checkup
    pop 	ax
    
	push 	ax 
    and 	ax, 0x0F00
    shr 	ax, 8
    call 	.checkup
    pop 	ax
	
    push 	ax 
    and 	ax, 0x00F0
    shr 	ax, 4
    call 	.checkup
    pop ax
    
	push 	ax 
    and 	ax, 0x000F
    call 	.checkup
    pop 	ax
    
	popa
    ret
	
.checkup:
    pusha
    
	mov 	si, chck0 
    add 	si, ax 
    mov 	cl, [si]
    mov 	di, mdg0 
    mov 	[di], cl
    mov 	dx, mdg0 
    call 	print
    
	popa
    ret
; ---------------------------------------------------

; ---------------------------------------------------
; OPEN FILE TO READ
; IN:
;   - dx: STRING
; OUT:
;   - ax: FILE HANDLER, CF = 0
open:
	mov 	ah, 0x3D
	mov 	al, 0  ; read
	int 	21h
ret
; ---------------------------------------------------
	
; ---------------------------------------------------
; READ FILE
; IN:
;   - bx: HANDLER
; OUT:
;   - nothing
read:
	mov 	ah, 0x3F
	mov 	dx, buffer_datas
	int 	0x21
	mov 	bx, ax
	mov 	word[buffer_datas + bx], 0x240A 
ret
; ---------------------------------------------------
	
; ---------------------------------------------------
; SEEK FILE
; IN:
;   - bx: HANDLER
; OUT:
;   - dx_ax: NEW FILE POSITION 
seek:
	mov 	ah, 42h
	mov 	al, 0
	mov 	cx, 0
	mov 	dx, 10
	int 	21h
ret
; ---------------------------------------------------
	
; ---------------------------------------------------
; CLOSE FILE
; IN:
;   - bx: HANDLER
; OUT:
;   - AX = 0, CF = 0
close:
	mov 	ah, 3Eh
	int 	21h
ret
; ---------------------------------------------------


; ---------------------------------------------------
; GET FILE SIZE THROUGH SEEK
; IN:
;   - bx: HANDLER
; OUT:
;   - dx:ax = END OF FILE
get_file_size:
	push 	bx
	mov    	ah, 42h
	mov    	al, 2                  ; from the end of file
	mov    	cx, 0                  ; high
	mov    	dx, 0                  ; low
	int  	21h
	pop 	bx
	
	push 	ax
	push 	dx
	
	mov    ah, 42h                ; set the file pointer to the start position
	mov    al, 0                  ; start of file
	mov    cx, 0                  ; high
	mov    dx, 0                  ; low
	int  	21h
	
	pop 	dx
	pop 	ax
ret