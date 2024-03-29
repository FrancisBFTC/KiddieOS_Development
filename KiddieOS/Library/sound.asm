; ------------------------------------------
;
;    DOS Library SoundBlaster Functions
;
; ------------------------------------------

 macro OUTB arg1*, arg2* {
    mov  dx, arg1 
    mov  al, arg2 
    out  dx, al 
 }
 
 macro INB arg1* { 
	mov	 dx, arg1 
    in	 al, dx 
 }
 

; wait a time
delay:
	mov  ah,  86h 
	mov  cx,  0x0000 
	mov  dx,  0xFFFF 
	int  15h
ret

; reset the SB16 DSP
sound_blaster_reset:
	pusha
	
	OUTB 	0x226,  1  ; set bit reset
	call 	delay
	OUTB 	0x226,  0  ; clear bit reset
	
	popa
ret

sound_blaster_isr:
	cli
	pusha
	
	mov 	byte[irq_set], 1
	mov 	ah, 09h
	mov 	dx, debug
	int 	21h
	
	; Ack IRQ to SB16
	INB 0x22E		; confirm interrupt 8
	INB 0x22F		; confirm interrupt 16
	
	; EOI to PICS (END OF INTERRUPT)
	OUTB 0xA0, 0x20
	OUTB 0x20, 0x20
	
	popa
	sti
iret

enable_sb_int:
	OUTB 0x224 ,  0x80	  ; habilita interrupção
	OUTB 0x225 ,  0x02	  ; configura interrupção 5
ret

speaker_on:
	OUTB 0x22C ,  0xD1	  ;liga o alto-falante
ret

speaker_off:
	OUTB 0x22C ,  0xD3	  ;desliga o alto-falante
ret

soundblaster16.setmaxvolume:
	OUTB 0x224 ,  0x22
	OUTB 0x224 ,  0xFF
ret

set_dma:
	pusha
	
	;Configurar DMA canal 1 
	; ----------------------------------------------------------------
	OUTB 0x0A,  5  ;desativa canal 1 (número do canal + 0x04) 
	OUTB 0x0C,  1  ;flip flop 
	OUTB 0x0B,  0x49  ;modo de transferência automática
	OUTB 0x83,  0x05  ;TRANSFERÊNCIA DE PÁGINA (EXEMPLO DE POSIÇÃO NA MEMÓRIA 0x[01]0F04 ) - DEFINA ESTE VALOR PARA VOCÊ 
  
	call 	get_offset
	
	OUTB 0x02,  al  ;POSIÇÃO BIT BAIXO (EXEMPLO POSIÇÃO NA MEMÓRIA 0x010F[04]) - DEFINA ESTE VALOR PARA VOCÊ 
	OUTB 0x02,  ah  ;POSIÇÃO BIT ALTO (EXEMPLO POSIÇÃO NA MEMÓRIA 0x01[0F]04) - DEFINA ESSE VALOR PARA VOCÊ 
	
	mov 	ax, [SIZE_BUFFER]
 
	OUTB 0x03,  al  ;CONTAR BIT BAIXO (EXEMPLO 0x0FFF) - DEFINIR ESTE VALOR PARA VOCÊ 
	OUTB 0x03,  ah  ;CONTAR BIT ALTO (EXEMPLO 0x0FFF) - DEFINIR ESTE VALOR PARA VOCÊ 
	OUTB 0x0A,  1  ;habilitar canal 1
	; ----------------------------------------------------------------
	
	popa
ret

; BX = hertz -> 165
set_dsp:
	pusha
	
	; Tocar som Sound Blaster
	; ----------------------------------------------------------------
	OUTB 0x22C ,  0x40  ;definir constante de tempo
	OUTB 0x22C ,  bl  ;definir constante de tempo
	;OUTB 0x22C ,  bh  ;definir constante de tempo
	OUTB 0x22C ,  0xC0  ;som de 16 bits 0xC0 = 8 bits
	OUTB 0x22C ,  0x00  ;dados de som mono e sem sinal 
	
	mov 	ax, [SIZE_BUFFER]
	dec 	ax
	
	OUTB 0x22C ,  al  ;CONTAGEM LOW BIT - COUNT L ENGTH- 1 (EXEMPLO 0x0FFF SO 0x0FFE) - DEFINA ESTE VALOR PARA VOCÊ 
	OUTB 0x22C ,  ah  ;CONTAGEM DE BIT ALTO - CONTAGEM DE COMPRIMENTO-1 (EXEMPLO 0x0FFF SO 0x0FFE) - DEFINA ESTE VALOR PARA VOCÊ
	; ----------------------------------------------------------------
	
	popa
ret

get_offset:
	mov 	ax, ds
	and 	ax, 0x0FFF
	shl 	ax, 4
	add 	ax, buffer_sound
ret

soundblaster16.playsound:
	pusha
	
	call 	speaker_on
	call 	set_dma
	
	mov 	byte[irq_set], 0
	
	mov 	bx, 165
	call 	set_dsp
	
	;wait_int:
	;	cmp 	byte[irq_set], 0
	;	jz		wait_int	

	call	speaker_off
	
	popa
	mov 	ax, 1
ret


soundblaster16.init:
	pusha
	
	call 	sound_blaster_reset
	
	;mov 	dx, sound_blaster_isr
	;mov 	cx, 5
	;call 	set_new_isr
	
	;call 	enable_sb_int
	
	popa
ret
