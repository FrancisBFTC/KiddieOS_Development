 ;This is called to update the block given


 ;AX = Block number (Either 0 or 1)
 ;BX = Block mask (0 for block 0, 0ffffh for block 1)
UpdateBuffer:
	push es
	pusha

  ;Set ES:DI to point to start of the current block

	mov di, [bufferSegment]
	mov es, di
	mov di, BLOCK_SIZE
	and di, bx
	add di, [bufferOffset]

	;Read from file

	push ds

	mov ax, es
	mov ds, ax
	mov dx, di

	mov ah, 3fh
	mov bx, [fileHandle]
	mov cx, BLOCK_SIZE
	int 21h

	pop ds  

	;Check if EOF

	cmp ax, BLOCK_SIZE
	je _ub_end

	mov ax, 4200h
	mov bx, [fileHandle]
	xor cx, cx
	mov dx, 44d
	int 21h

 _ub_end:
	popa
	pop es
	ret

 ;This is called to initialize both blocks
 ;Set CF on return (and set DX to the offset of a string) to show an error and exit
InitBuffer:
	push ax
	push bx

  ;finit

  ;xor ax, ax
  ;mov bx, ax
  ;call UpdateBuffer

  ;inc al
  ;not bx
  ;call UpdateBuffer


	mov ax, 3d00h
	mov dx, strWaveFile
	int 21h

	mov dx, strFileNotFound
	mov [fileHandle], ax
	jc _ib_end

  ;Read sample rate

	mov bx, ax
	mov ax, 4200h
	xor cx, cx
	mov dx, 18h
	int 21h

	mov dx, strFileError
	jc _ib_end

	mov ah, 3fh
	mov bx, [fileHandle]
	mov cx, 2
	mov dx, sampleRate
	int 21h
	
	mov dx, [sampleRate]             ;DEBUG

	mov dx, strFileError
	jc _ib_end

  ;Set file pointer to start of data

	mov ax, 4200h
	mov bx, [fileHandle]
	xor cx, cx
	mov dx, 44d
	int 21h


_ib_end:
	pop bx
	pop ax
	ret


 ;Closed to finalize the buffer before exits

FinitBuffer:
	push ax
	push bx
	push dx

	mov bx, [fileHandle]
	test bx, bx
	jz _fib_end

	mov ah, 3eh
	int 21h

_fib_end:
	pop dx
	pop bx
	pop ax
	ret
	
	
 ;Allocate a buffer of size BLOCK_SIZE * 2 that doesn't cross
 ;a physical 64KiB
 ;This is achieved by allocating TWICE as much space and than
 ;Aligning the segment on 64KiB if necessary


AllocateBuffer:
	push bx
	push cx
	push ax
	push dx

  ;Compute linear address of the buffer

	mov bx, data_seg
	shr bx, 0ch
	mov cx, data_seg
	shl cx, 4
	add cx, buffer
	adc bx, 0                                 ;BX:CX = Linear address



  ;Does it starts at 64KiB?

	test cx, cx
	jz _ab_end                                ;Yes, we are fine

	mov dx, cx
	mov ax, bx

  ;Find next start of 64KiB

	xor dx, dx
	inc ax

	push ax
	push dx

	;Check if next boundary is after our buffer

	sub dx, cx
	sub ax, bx

	cmp dx, BUFFER_SIZE / 2

	pop dx
	pop ax
	jae _ab_end



	mov bx, dx
	and bx, 0fh
	mov [bufferOffset], bx

	mov bx, ax
	shl bx, 0ch
	shr dx, 04h
	or bx, dx
	mov [bufferSegment], bx

_ab_end:
	clc

	pop dx
	pop ax
	pop cx
	pop bx

	ret


;Free the buffer

FreeBufferIfAllocated:

  ;Nothing to do

ret