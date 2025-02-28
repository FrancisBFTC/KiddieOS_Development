; ------------------------------------------
;
;      Hardware Interrupts Config ISRs
;
; ------------------------------------------

; ------------------------------------------
; CONFIG IVT HARDWARE INTERRUPT
; IN: DX = isr label
;	  CX = interrupt index
set_ivt_address:
	pusha
	push 	es
	mov 	byte[irq_set], 1
	xor 	ax, ax
	mov 	es, ax
	mov 	bx, 80h
	shl 	bx, 2
	push 	cs
	pop 	ax
	shl 	cx, 2
	add 	bx, cx
	;mov 	di, save_address
	;push 	eax
	;mov 	eax, [es:bx]
	;mov 	[di], eax 
	;pop 	eax
	mov 	word[es:bx], dx
	add 	bx, 2
	mov 	word[es:bx], ax
	pop 	es
	popa
ret

; ------------------------------------------
; RESET IVT HARDWARE INTERRUPT
; IN: CX = interrupt index
reset_ivt_address:
	pusha
	push 	es
	cli
	xor 	ax, ax
	mov 	es, ax
	mov 	di, 80h
	shl 	di, 2
	shl 	cx, 2
	add 	di, cx
	mov 	eax, 0	;[save_address]
	stosd
	pop 	es
	popa
	mov 	bx, 0
	call 	config_pics
	sti
ret

; ------------------------------------------
; CONFIG INTERRUPT AND PICS
; IN: DX = isr label
;	  CX = interrupt index
set_new_isr:
	pusha
	
	cli
	call 	set_ivt_address
	mov 	bx, 1
	call 	config_pics
	sti
	
	popa
ret

; ------------------------------------------
; CONFIGURE PICS CONTROLLER
; IN: BX = 0 | 1
config_pics:
	; ICW1 - Reinicializar faz o PIC esperar ao menos 3 words
	; de configuração
    OUTB	0x20, 0x11  ; Reinicia o controlador
    OUTB	0xA0, 0x11

   ; ICW2 - Deslocamento vetorial - Vetores de interrupção
   ; PIC mestre de dados (0x21) desloca IRQ0 para vetor 0x70
   ; PIC escravo de dados (0xA1) desloca IRQ8 para vetor 0x78
	cmp 	bx, 0
	jz 		no_irq_def2
    mov 	bl, 80h
no_irq_def2:
	mov 	bh, bl
	add 	bh, 8
	OUTB 	0x21, bl 
    OUTB	0xA1, bh

    ;// ICW3
    OUTB	0x21, 0x04
    OUTB	0xA1, 0x02

    ;// ICW4
    OUTB	0x21, 0x01
    OUTB	0xA1, 0x01

    ; // OCW1
	; Exemplo: BIT<0> de 0x21 = TIMER, BIT<1> de 0x21 = KEYBOARD
	; BIT<4> de 0xA1 = Mouse PS/2
	mov 	al, 11111111b
	
	cmp 	bx, 0
	jz 		no_irq_def
	mov 	al, 1
	shl 	al, cl
	mov 	cl, 11111111b
	xor 	al, cl
no_irq_def:
    OUTB	0x21, al  ; Desabilita todas as interrupções (Não-Mascaráveis)
    OUTB	0xA1, 11111111b	 ; Habilita apenas a interrupção 5 -> IRQ5 -> Placa de som!
ret