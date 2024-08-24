; multi-segment DOS executable
; flat assembler syntax


format MZ
entry code_seg:_start 	; entry point
stack 256
	
segment data_seg

	ErrorMsgs 	dw 0xFFFF
				dw NotAbleMsg
				dw NotFoundMsg
				dw PathNFMsg
				dw NoHandlerMsg
				dw DeniedMsg
				times 6 dw 0
				dw NotAllowedMsg

	msg 		  db 'Lets open a file in DOS:',0x0D,0x0A,'$'
	DeniedMsg  	  db "Error: Access denied!",0x0D,0x0A,'$'
	NoHandlerMsg  db "Error: No handler available!",0x0D,0x0A,'$'
	PathNFMsg 	  db "Error: path not found!",0x0D,0x0A,'$'
	NotFoundMsg	  db "Error: file not found!",0x0D,0x0A,'$'
	NotAbleMsg	  db "Error: sharing not enabled",0x0D,0x0A,'$'
	NotAllowedMsg db "Error: Access mode not allowed!",0x0D,0x0A,'$'
	OpenSuccess   db "Success: The file has been opened!",0x0D,0x0A,'$'
	PressKey 	  db "Type anything: ",'$'
	path 		  db 'config\file.txt',0
	buffer db 10,?, 10 dup(' ')
	
segment code_seg
print_buffer:
	mov 	dx, buffer + 2
	mov 	ah, 9
	int 	21h
ret
	
_start:
	mov 	ax, data_seg
	mov 	ds, ax
	mov 	es, ax
	
	mov		ah, 09h
	mov 	dx, msg
	int 	0x21
	
	
	mov 	ah, 0x3D
	mov 	al, 1
	mov 	dx, path
	int 	0x21
	jc 		error_open
	
	mov		ah, 09h
	mov 	dx, OpenSuccess
	int 	0x21

	jmp 	wait_key
	
error_open:
	xor 	dx, dx
	mov 	bx, ax
	mov 	ax, 2
	mul 	bx
	mov 	bx, ax
	
	mov		ah, 09h
	mov 	dx, ErrorMsgs
	add 	dx, bx
	mov 	bx, dx
	mov 	dx, [ds:bx] ;+ 0x20]
	int 	0x21
	
wait_key:
	mov 	ah, 09h
	mov 	dx, PressKey
	int 	0x21
	
	mov 	dx, buffer
	mov 	ah, 0ah
	int 	21h
	
	mov 	ah, 06h
	mov 	dl, 0x0A
	int 	0x21
	
	xor 	bx, bx
	mov 	bl,	[buffer + 1]
	mov 	byte[buffer + bx + 2], '$'
	call 	print_buffer
	;mov 	dx, buffer + 2
	;mov 	ah, 9
	;int 	21h
	
EXIT:
	mov 	ax, 0x4C00
	int 	0x21
	