ResetDSP:
	push ax
	push dx

	;Set reset bit

	mov dx, REG_DSP_RESET
	mov al, 01h
	out dx, al

	;Wait 3 us

	in al, 80h
	in al, 80h
	in al, 80h

	;Clear reset bit

	xor al, al
	out dx, al

	;Poll BS until bit 7 is set

	mov dx, REG_DSP_READ_BS

_rd_poll_bs:
	in al, dx
	test al, 80h
	jz _rd_poll_bs

	;Poll data until 0aah

	mov dx, REG_DSP_READ

_rd_poll_data:
	in al, dx
	cmp al, 0aah
	jne _rd_poll_data

	pop dx
	pop ax
ret

;AL = command/data
WriteDSP:
	push dx
	push ax

	mov dx, REG_DSP_WRITE_BS

_wd_poll:
	in al, dx
	test al, 80h
	jz _wd_poll

	pop ax

	mov dx, REG_DSP_WRITE_DATA
	out dx, al

	pop dx
ret

;Return AL 
ReadDSP:
	push dx

	mov dx, REG_DSP_READ_BS

_rdd_poll:
	in al, dx
	test al, 80h
	jz _rdd_poll

	pop ax

	mov dx, REG_DSP_READ
	in al, dx

	pop dx
ret

;AX = sampling
SetSampling:
	push dx

	xchg al, ah

	push ax

	mov al, DSP_SET_SAMPLING_OUTPUT
	call WriteDSP

	pop ax

	call WriteDSP

	mov al, ah
	call WriteDSP

	pop dx
ret


;Starts a playback

;AX = Sampling
;BL = Mode
;CX = Size
StartPlayback:

	;Set sampling

	call SetSampling

	;Start playback command

	mov al, DSP_DMA_16_OUTPUT_AUTO
	call WriteDSP
	mov al, bl            
	call WriteDSP							;Format 
	mov al, cl
	call WriteDSP                            ;Size (Low)
	mov al, ch   
	call WriteDSP                            ;Size (High)

ret

;Stops the playback

StopPlayback:
	push ax

	mov al, DSP_STOP_DMA_16
	call WriteDSP

	pop ax
ret
