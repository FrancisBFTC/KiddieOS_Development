;Swaps two far pointers

;DS:SI = ptr to ptr1
;ES:DI = ptr to ptr2
SwapFarPointers:
	push bx

	mov bx, [si]
	xchg [es:di], bx
	mov [si], bx

	mov bx, [si+02h]
	xchg [es:di+02h], bx
	mov [si+02h], bx

	pop bx
ret  

;Swaps the ISR vector of the IRQ of the card with a saved value
SwapISRs:
	push es
	pusha

	cli

	mov si, nextISR
	xor di, di
	mov es, di
	mov di, ISR_VECTOR
	call SwapFarPointers

	sti

	;Toggle PIC mask bit
	mov dx, PIC_DATA
	in al, dx
	xor al, PIC_MASK
	out dx, al

	popa
	pop es
 ret  


 ;This is the ISR
Sb16Isr:
	push ax
	push dx
	push ds
	push es

	;Ack IRQ to SB16

	mov dx, REG_DSP_ACK_16
	in al, dx

	;EOI to PICs

	mov al, 20h
	out 20h, al

	IF SB16_IRQ SHR 3 
		out 0a0h, al
	END IF

	mov ax, data_seg
	mov ds, ax

	mov ax, [BlockNumber]
	mov bx, [BlockMask]  
	call UpdateBuffer

	not bx
	inc ax
	and al, 01h

	mov [BlockNumber], ax
	mov [BlockMask], bx

	pop es
	pop ds
	pop dx
	pop ax
iret