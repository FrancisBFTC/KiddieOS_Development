format MZ
stack 1000h
entry code_seg:main
	
	include "sb16inc\cfg.asm"
 
segment code_seg
	include "sb16inc\buffer.asm"
	include "sb16inc\isr.asm"
	include "sb16inc\dsp.asm"
	include "sb16inc\dma.asm"


main:

	;Basic initialization
	mov ax, data_seg
	mov ds, ax
	mov es, ax
	mov [bufferSegment], ax
	mov ax, cs
	mov [nextISR + 2], ax

	;S E T   T H E   N E W   I S R
	call SwapISRs

	;A L L O C A T E   T H E   B U F F E R
	call AllocateBuffer
	mov dx, strErrorBuffer
	jc _error

	;I N I T   T H E   B U F F E R
	call InitBuffer
	jc _finit_buffer

	;S E T U P   D M A
	mov si, [bufferSegment]
	mov es, si
	mov si, [bufferOffset]
	mov di, BLOCK_SIZE * 2
	call SetDMA
	
	
	;S T A R T   P L A Y B A C K
	call ResetDSP
	
	mov ax, [sampleRate]            		;Sampling
	mov bx, FORMAT_MONO OR FORMAT_SIGNED    ;Format
	mov cx, BLOCK_SIZE                      ;Size
	call StartPlayback

	;W A I T
	mov ah, 09h
	mov dx, strPressAnyKey
	int 21h

	xor ah, ah
	int 16h

	;S T O P
	call StopPlayback
	mov dx, strBye

_finit_buffer:

	;F R E E   B L O C K   R E S O U R C E S
	call FinitBuffer


	;E R R O R   H A N D L I N G
	;When called DX points to a string

_error:

	;R E S T O R E   T H E   O L D   I S R s
	call SwapISRs
	
	call FreeBufferIfAllocated

	mov ah, 09h
	int 21h

	;E N D

_end:
	mov ax, 4c00h
	int 21h
	
segment data_seg
	include "sb16inc\data.asm"
