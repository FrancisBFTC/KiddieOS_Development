; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;         FileSystem 16-bit DOS Library
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ---------------------------------------------------
; OPEN FILE ONLY TO READ
; IN: DX = FileName
open_to_read:
	mov 	ah, 0x3D
	mov 	al, 0
	int 	21h
ret

; ---------------------------------------------------
; READ FILE TO BUFFER 
; IN: DX = Buffer
;     CX = Size
;	  BX = Handler
read_file:
	;call 	get_file_size
	mov 	cx, [SIZE_BUFFER]
	mov 	dx, si
	mov 	ah, 0x3F
	int 	21h
ret

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
	int 	21h
ret

; ---------------------------------------------------
; GET FILE SIZE THROUGH SEEK
; IN:
;   - bx: HANDLER
; OUT:
;   - dx:ax = END OF FILE
get_file_size:
	push 	bx
	push 	si
	
	mov 	al, 2
	call 	seek
	
	pop 	si
	pop 	bx
	
	push 	si
	push 	ax
	
	mov 	al, 0
	call 	seek

	pop 	ax
	pop 	si
ret