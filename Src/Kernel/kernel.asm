; ----------------------------------------------------
; Binary files functions address
%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/info.lib"
%INCLUDE "Includes/drivers.inc"
%INCLUDE "Includes/shell.inc"
%INCLUDE "Includes/fat.inc"
; ----------------------------------------------------

[BITS SYSTEM]
[ORG KERNEL]

; *********************************************************************
; KERNEL SYSTEM CALLS	
OS_VECTOR_JMP:
	jmp Kernel_Entry          ; 0000h (called by VBR)
	jmp PrintNameFile         ; 0003h
	jmp Print_Hexa_Value16    ; 0006h
	jmp Print_String          ; 0009h
	jmp Break_Line            ; 000Ch
	jmp Create_Panel          ; 000Fh
	jmp Clear_Screen          ; 0012h
	jmp Move_Cursor			  ; 0015h
	jmp Get_Cursor            ; 0018h
	jmp Show_Cursor			  ; 001Bh
	jmp Hide_Cursor			  ; 001Eh
	jmp Kernel_Menu			  ; 0021h
	jmp Write_Info			  ; 0024h
	jmp PrintNameFile         ; 0027h
	jmp WMANAGER_INIT         ; 002Ah
	jmp Print_Hexa_Value8     ; 002Dh
	jmp Play_Speaker_Tone     ; 0030h
	jmp Print_Dec_Value32     ; 0033h
	jmp Print_Hexa_Value32 	  ; 0036h
	jmp Print_Fat_Date 		  ; 0039h
	jmp Print_Fat_Time		  ; 003Ch
	jmp Calloc                ; 003Fh
	jmp Free                  ; 0042h
	jmp Parse_Dec_Value		  ; 0045h
	jmp Reboot_System         ; 0048h
	
; --------------------------------------------------
; Saltos para serem chamados por CALL FAR
; Por programas em outros segmentos, Ex.: DOS
	jmp syscall.prog			; 004Bh
	jmp winmng.video			; 004Eh
	jmp shell.cmd				; 0051h
	jmp tone.play 				; 0054h


; *********************************************************************

; --------------------------------------------------
; Directives and Inclusions

%INCLUDE "Hardware/speaker.lib"
%INCLUDE "Includes/kerneldat.inc"
%INCLUDE "Src/Kernel/font.asm"
; --------------------------------------------------

mikeapi 	db "MIKEOS  API",0

; ----------------------------------------------
; VARIÁVEIS DO DRIVER DE MOUSE
sample_rate db 100
resolution 	db 0

mouse_status db 0
mouse_deltaX db 0
mouse_deltaY db 0
mouse_deltaX_temp dw 0
mouse_deltaY_temp dw 0
right_pressed 	db 0
left_pressed 	db 0
; ----------------------------------------------

; ----------------------------------------------
; VARIÁVEIS DE COORDENADAS GRÁFICAS & PONTEIRO
; Resolução do monitor
%DEFINE SCREEN_WIDTH 320
%DEFINE SCREEN_HEIGHT 200

screen_x dw SCREEN_WIDTH / 2
screen_y dw SCREEN_HEIGHT / 2
screenx_changed dw 0
screeny_changed dw 0
direction_screen dw 0

mouse_bitmap 	dw 0001100000000000b
				dw 0001111000000000b
				dw 0001111110000000b
				dw 0001111111100000b
				dw 0001111111111000b
				dw 0001111110000000b
				dw 0001110011000000b
				dw 0001000001100000b
				dw 0000000000110000b

mouse_bitmap.size EQU ($-mouse_bitmap) / 2
; ----------------------------------------------

; ----------------------------------------------
; VARIÁVEIS DE COORDENADAS E TAMANHOS AUXILIARES
; PARA JANELAS DO MOUSE 
savewx dw 0
savewy dw 0
savex dw 0
savey dw 0

sizewx dw 0
sizewy dw 0
sizex dw 1
sizey dw 1
sizex_tmp dw 1
sizey_tmp dw 1
; ----------------------------------------------

; ----------------------------------------------
; VARIÁVEIS E LISTAS DE ITENS DO MENU DO MOUSE

open_menu_y 	dw 0, 0
update_menu_y 	dw 0, 0
paste_menu_y 	dw 0, 0
create_menu_y 	dw 0, 0
new_menu_y 		dw 0, 0
other_menu_y  	dw 0

option_select_y dw 0
option_select_x dw 0
option_str_addr dw 0

menu_list:	dw open_menu_str
		  	dw update_menu_str
		  	dw paste_menu_str
		  	dw create_menu_str
			dw new_menu_str
menu_list.size EQU ($ - menu_list) / 2

text_font db "KIDDIEOS MOUSE",0
open_menu_str db "ABRIR",0
update_menu_str db "ATUALIZAR",0
paste_menu_str db "COLAR",0
create_menu_str db "CRIAR",0
new_menu_str 	db "NOVO",0
; ----------------------------------------------


; Função: Pinta o bitmap do ponteiro do mouse
; DX = Linha Inicial
; CX = Coluna Inicial
; AH = Cor das Bordas
; AL = Cor do Fundo
; BH = Número de pixels da linha
; BL = Número de linhas
; SI = Bitmap
draw_mouse:
	pusha
	push 	es
  	push	ax
  	push	bx
  	mov   	ax, 0xA000
  	mov   	es, ax
  	mov   	ax, SCREEN_WIDTH
  	mov   	bx, dx
  	xor   	dx, dx
  	mul   	bx
  	mov   	di, ax
  	add   	di, cx
  	pop 	bx
  	pop 	ax
  	push 	bx
  	xchg 	bh, bl
	xor 	bh, bh
	mov 	dx, bx
	shr 	dx, 3
	mov 	cx, bx
	dec 	cx
	mov 	bx, 1
	shl 	bx, cl
	mov 	[bitbase], bx
	pop 	bx 
  draw_config:
    cld
    movzx	cx, bl
    draw_rows:
		push	cx
		movzx 	cx, bh
		push	bx
		mov 	bx, [bitbase]
		mov 	byte[is_first], 1
		mov 	byte[is_last], 0
		draw_cols:
			push 	cx
			mov 	cx, [si]
			and 	cx, bx
			jz 		no_draw_pixel
			cmp 	byte[is_first], 1
			jnz 	isnt_first_pixel
			mov 	[es:di], ah
			mov 	byte[is_first], 0
			jmp 	no_draw_pixel1
		isnt_first_pixel:
			mov 	[es:di], al
			jmp 	no_draw_pixel1
		no_draw_pixel:
			cmp 	byte[is_first], 0
			jnz 	no_draw_pixel1
			cmp 	byte[is_last], 1
			jz 		no_draw_pixel1
			mov 	[es:di - 1], ah
			mov 	byte[is_last], 1
		no_draw_pixel1:
			shr 	bx, 1
			inc 	di
			pop 	cx
		loop 	draw_cols
		pop 	bx
		movzx 	cx, bh
		sub 	di, cx
		add 	di, SCREEN_WIDTH
		add 	si, dx
		pop 	cx
	loop draw_rows
  pop 	es
  popa
ret
is_first db 0
is_last  db 0

; Função: Pinta um desenho dado o Bitmap
; DX = Linha Inicial
; CX = Coluna Inicial
; AH = Cor do fundo (Se 0, então transparente)
; AL = Cor do Pixel do caractere
; BH = Número de pixels da linha
; BL = Número de linhas
; SI = Bitmap
draw_bitmap:
	pusha
	push 	es
	push	ax
	push	bx
	mov   	ax, 0xA000
	mov   	es, ax
  	mov   	ax, SCREEN_WIDTH
  	mov   	bx, dx
  	xor   	dx, dx
  	mul   	bx
  	mov   	di, ax
  	add   	di, cx
  	pop 	bx
  	pop 	ax
  	push 	bx
  	xchg 	bh, bl
	xor 	bh, bh
	mov 	dx, bx
	shr 	dx, 3
	mov 	cx, bx
	dec 	cx
	mov 	bx, 1
	shl 	bx, cl
	mov 	[bitbase], bx
	pop 	bx 
  draw_bit_config:
    cld
    movzx	cx, bl
    draw_bit_rows:
		push	cx
		movzx 	cx, bh
		push	bx
		mov 	bx, [bitbase]
		draw_bit_cols:
			push 	cx
			mov 	cx, [si]
			and 	cx, bx
			jz 		no_draw_bitpixel0
			mov 	[es:di], al
			jmp 	no_draw_bitpixel
		no_draw_bitpixel0:
			cmp 	ah, 0x00
			jz 		no_draw_bitpixel
			mov 	[es:di], ah
		no_draw_bitpixel:
			shr 	bx, 1
			inc 	di
			pop 	cx
		loop 	draw_bit_cols
		pop 	bx
		movzx 	cx, bh
		sub 	di, cx
		add 	di, SCREEN_WIDTH
		add 	si, dx
		pop 	cx
	loop draw_bit_rows
  pop 	es
  popa
ret
bitbase dw 0

; Função: Escreve um texto na tela
; SI = String para Imprimir
; AH = Fundo - 0 : Transparente, non-zero: Cor
; DX = Coordenada Y
; CX = Coordenada X
write_font:
	pusha
	mov 	al, 1fh
	mov 	bx, 0x0808
	mov 	di, bitmap_A
	printfont:
		cmp 	byte[si], 0
		jz		ret_printfont
		push 	si
		push 	ax
		xor 	ax, ax
		mov 	al, [si]	
		mov 	si, di
		sub 	al, 0x41
		shl 	ax, 3
		add 	si, ax
		pop 	ax
		call 	draw_bitmap
		pop 	si
		inc 	si
		add 	cx, 8
		jmp 	printfont
	ret_printfont:
		popa
ret

; Função: Desenha um retângulo de seleção
; DX = Coordenada Y
; CX = Coordenada X
; AL = Cor de seleção
; sizex = Comprimento
; sizey = Altura
mouse_selection:
	pusha
	push 	es
	push	ax
	mov   	ax, 0xA000
	mov   	es, ax
	mov   	ax, 320
	mov   	bx, dx
	xor   	dx, dx
	mul   	bx
	mov   	di, ax
	add   	di, cx
	pop 	ax
	mov 	word[direction_screen], SCREEN_WIDTH
	mov 	dx, [sizex]
	mov 	bx, [sizey]
	mov 	[sizex_tmp], dx
	mov 	[sizey_tmp], bx
	mov 	cx, dx
	or 		cx, bx
	jz 		ret_mouse_selection
	cmp 	bx, 0
	jz 		paint_line_horiz
	call 	conv_direction_y
	mov 	cx, [sizey_tmp]
	cmp 	dx, 0
	jz 		paint_line_vertc_begin
	jmp 	line_horiz_up
	paint_line_vertc_begin:
		push 	cx
		call 	conv_direction
		pop 	cx
	paint_line_vertc:
		mov 	[es:di], al
		add   	di, [direction_screen]
		loop  	paint_line_vertc
		jmp 	ret_mouse_selection
	paint_line_horiz:
		call 	conv_direction_x_up
		mov  	cx, [sizex_tmp]
		rep  	stosb
		jmp 	ret_mouse_selection
	line_horiz_up:
		call 	conv_direction_x_up
		mov  	cx, [sizex_tmp]
		rep  	stosb
		call 	conv_direction_y
		mov  	cx, [sizey_tmp]
	line_vertc_right:
		mov 	[es:di], al
		add   	di, [direction_screen]
		loop  	line_vertc_right
	line_horiz_down:
		call 	conv_direction_x_down
		mov   	cx, [sizex_tmp]
		rep   	stosb
		call 	conv_direction_y
		mov   	cx, [sizey_tmp]
	line_vertc_left:
		mov 	[es:di], al
		add  	di, [direction_screen]
		loop  	line_vertc_left
		cld
ret_mouse_selection:
	pop 	es
	popa
ret
conv_direction_x_up:
	cld
	call 	conv_direction
check_dir_x:
	mov 	cx, dx
	and 	cx, 8000h
	jz 		ret_conv_x_up
	mov 	cx, dx
	not 	cx
	inc 	cx
	mov 	[sizex_tmp], cx
	std
ret_conv_x_up:
	ret
conv_direction_x_down:
	std
	not 	word[direction_screen]
	inc 	word[direction_screen]
	mov 	cx, dx
	and 	cx, 8000h
	jz 		ret_conv_x_down
	mov 	cx, dx
	not 	cx
	inc 	cx
	mov 	[sizex_tmp], cx
	cld
ret_conv_x_down:
	ret
conv_direction_y:
	mov 	cx, bx
	and 	cx, 8000h
	jz 		ret_conv_y
	mov 	cx, bx
	not 	cx
	inc 	cx
	mov 	[sizey_tmp], cx
ret_conv_y:
	ret
conv_direction:
	mov 	cx, bx
	and 	cx, 8000h
	jz 		ret_conv_dir
	not 	word[direction_screen]
	inc 	word[direction_screen]
ret_conv_dir:
	ret

; Função: Apaga um retângulo de seleção
; savey = Coordenada Y salva anteriormente
; savex = Coordenada X salva anteriormente
; Nota: Entradas automáticas
erase_selection:
	mov 	dx, [savey]
	mov 	cx, [savex]
	mov 	al, 0x00
	call 	mouse_selection
	mov 	word[savex], 0
	mov 	word[savey], 0
	mov 	word[sizex], 0
	mov 	word[sizey], 0
ret

; Função: Salva as coordenadas de seleção
; screen_y = Coordenada Y do mouse
; screen_x = Coordenada X do mouse
; Nota: Entradas automáticas
save_coord_selection:
	mov 	dx, [screen_y]
	sub 	dx, 5
	mov 	cx, [screen_x]
	sub 	cx, 4
	mov 	ax, [savex]
	mov 	bx, [savey]
	and 	ax, bx
	jnz 	no_update_save
	mov 	[savey], dx
	mov 	[savex], cx
	mov 	word[sizex], 1
	mov 	word[sizey], 1
no_update_save:
	ret

; Função: Verifica se precisa apagar retângulo de seleção
check_to_mouse_selection:
	cmp 	byte[left_pressed], 1
	jnz 	no_erase_selection

	mov 	dx, [savey]
	mov 	cx, [savex]
	mov 	al, 0x00
	call 	mouse_selection

no_erase_selection:
	ret

; Função: Desenha a janela do menu do mouse
; DX = Coordenada Y do mouse
; CX = Coordenada X do mouse
; AL = Cor de Fundo da janela
; sizewx = Comprimento da janela
; sizewy = Altura da janela
paint_window_mouse:
	pusha
	push 	es
	push	ax
  	mov   	ax, 0xA000
  	mov   	es, ax
  	mov   	ax, SCREEN_WIDTH
  	mov   	bx, dx
  	xor   	dx, dx
  	mul   	bx
  	mov   	di, ax
  	add   	di, cx
  	pop 	ax
	mov  	cx, [sizewy]
  	paint_win_cols:
		push 	cx
    	cld
		push 	ax
		cmp 	al, 0
		jz 		is_not_divisible
		xor  	dx, dx
		push 	ax
		mov 	ax, cx
		mov 	bx, 22
		div 	bx
		pop 	ax
		cmp 	dx, 0
		jnz 	is_not_divisible
		mov 	al, 16h
	is_not_divisible:
    	mov  	cx, [sizewx]
		rep  	stosb
		pop 	ax
    paint_win_line:
		sub 	di, [sizewx]
      	add  	di, SCREEN_WIDTH
		pop 	cx
      	loop  	paint_win_cols
  pop 	es
  popa
ret

; Função: Apaga a janela do menu do mouse
; savewy = Coordenada Y salva
; savewx = Coordenada X salva
; Nota: Entradas automáticas
erase_window_mouse:
	cmp 	byte[right_pressed], 0
	jz		no_right_pressed

	mov 	dx, [savewy]
	mov 	cx, [savewx]
	mov 	al, 00h 			; AL = Cor do Pixel = preto
	mov 	word[sizewx], 80
	mov 	word[sizewy], 100
	call 	paint_window_mouse
	mov 	byte[right_pressed], 0
	
no_right_pressed:
	ret

; Função: Apaga o mouse pelo buffer de fundo
; DX = Coordenada Y anterior do mouse
; CX = Coordenada X anterior do mouse
; sizewx = Quantidade de colunas de pixels
; sizewy = Quantidade de linhas de pixels
paint_mouse_back:
	pusha
	push 	es
  	mov   	ax, 0xA000
  	mov   	es, ax
  	mov   	ax, SCREEN_WIDTH
  	mov   	bx, dx
  	xor   	dx, dx
  	mul   	bx
  	mov   	di, ax
  	add   	di, cx
	mov 	si, background
	mov  	cx, [sizewy]
  	paint_mou_cols_back:
		push 	cx
    	cld
    	mov  	cx, [sizewx]
		rep  	movsb
    paint_mou_line_back:
		sub 	di, [sizewx]
      	add  	di, SCREEN_WIDTH
		pop 	cx
      	loop  	paint_mou_cols_back
  pop 	es
  popa
ret

; Função: Apaga o ponteiro do mouse
; DX = Coordenada Y anterior do mouse
; CX = Coordenada X anterior do mouse
erase_pointer_mouse:
	mov 	word[sizewx], 16
	mov 	word[sizewy], 9
	call 	paint_mouse_back
ret

; Função: Salva o fundo detrás do mouse no buffer
; DX = Coordenada Y do mouse
; CX = Coordenada X do mouse
; sizewx = Quantidade de pixels em colunas
; sizewy = Quantidade de pixels em linhas
save_mouse_back:
	pusha
	push 	ds
	
  	mov   	ax, 0xA000
  	mov   	ds, ax
  	mov   	ax, SCREEN_WIDTH
  	mov   	bx, dx
  	xor   	dx, dx
  	mul   	bx
  	mov   	si, ax
  	add   	si, cx
	mov 	di, background
	mov  	cx, [es:sizewy]
	save_back_cols:
		push 	cx
    	cld
    	mov  	cx, [es:sizewx]
		rep  	movsb
    save_back_line:
		sub 	si, [es:sizewx]
      	add  	si, SCREEN_WIDTH
		pop 	cx
      	loop  	save_back_cols
	pop 	ds
	popa
ret
background times 16*9 db 0

; Função: Selecionar itens do menu do mouse
; DX = Coordenada Y do mouse
; CX = Coordenada X do mouse
menu_selection:
	pusha
	cmp 	byte[right_pressed], 0
	jz 		ret_menu_selection

	mov 	si, menu_list
	mov 	bx, open_menu_y
	mov 	ax, menu_list.size	; 4
	call 	mouse_loop_select

ret_menu_selection:
	popa
ret

; Função: Varredura de Itens sobre a lista de menu
; DX = Coordenada Y do mouse
; CX = Coordenada X do mouse
; SI = Ponteiro da lista de itens
; BX = Coordenada do item inicial
; AX = Quantidade de itens
mouse_loop_select:
	cmp 	dx, [bx]		; open_menu_y
	jae 	check_begin_y
	jmp 	ret_loop_select
check_begin_y:
	cmp 	dx, [bx + 4]	; update_menu_y
	jae 	check_next_y

	mov 	si, [si]
	call 	select_mouse_option
	jmp 	ret_loop_select

check_next_y:
	add 	si, 2
	add 	bx, 4			; update_menu_y
	dec 	ax
	jnz 	check_begin_y
ret_loop_select:
	ret

; Função: Seleciona um item de menu
; CX = Coordenada X do mouse
; SI = String do item
; BX = Coordenada do item atual
; ENTRADAS/SAÍDAS AUTOMÁTICAS ->
; savewx = Coordenada X salva
; option_select_y = Coordenada Y do item selecionado
; option_select_x = Coordenada X do item selecionado
; option_str_addr = String do item selecionado
select_mouse_option:
	add 	cx, 3
	cmp 	cx, [bx + 2]
	jb 		ret_select_mouse
	mov 	dx, [savewx]
	add 	dx, 80 - 6
	cmp 	cx, dx
	ja 		ret_select_mouse

	push 	si
	mov 	dx, [option_select_y]
	mov 	cx, [option_select_x]
	or 		dx, cx
	jz 		no_erase_menu_selection

	mov 	dx, [option_select_y]
	mov 	cx, [option_select_x]
	mov 	si, [option_str_addr]
	mov 	ah, 0x13
	call 	write_font

no_erase_menu_selection:
	mov 	dx, [bx]
	mov 	cx, [bx + 2]
	mov 	ah, 0x16
	pop 	si
	call 	write_font
	mov 	[option_select_y], dx
	mov 	[option_select_x], cx
	mov 	word[option_str_addr], si
ret_select_mouse:
	ret

; Função: Movimento do ponteiro do mouse
; AX = DeltaY calculado
; BX = DeltaX calculado
; screeny_changed: screen_y antes da possível mudança de limites
; screenx_changed: screen_x antes da possível mudança de limites
; screen_y: Nova coordenada Y (após possível mudança)
; screen_x: Nova coordenada X (após possível mudança)
mouse_pointer_move:
	mov 	dx, [screeny_changed]			; DX = Linha Inicial
	mov 	cx, [screenx_changed]			; CX = Coluna Inicial
	sub 	dx, ax
	sub 	cx, bx
	call 	erase_pointer_mouse

	call 	check_to_mouse_selection

	mov 	dx, [screen_y]			; DX = Linha Inicial
	mov 	cx, [screen_x]			; CX = Coluna Inicial
	call 	menu_selection

	mov 	word[sizewx], 16
	mov 	word[sizewy], 9
	call 	save_mouse_back

	cmp 	byte[left_pressed], 1
	jnz 	no_repaint_selection

	mov 	dx, [savey]
	mov 	cx, [savex]
	mov 	al, 0x01
	mov 	bx, [mouse_deltaX_temp]
	add 	[sizex], bx
	mov 	bx, [mouse_deltaY_temp]
	add 	[sizey], bx
	call 	mouse_selection

	mov 	byte[left_pressed], 0

no_repaint_selection:
	mov 	dx, [screen_y]			; DX = Linha Inicial
	mov 	cx, [screen_x]			; CX = Coluna Inicial
	mov 	ah, 19h	 				; AH = Cor das Bordas
	mov 	al, 1Fh					; AL = Cor do Fundo
	mov 	bh, 16 					; BH = Número de pixels da linha
	mov 	bl, mouse_bitmap.size 	; BL = Número de linhas
	mov 	si, mouse_bitmap		; SI = Bitmap
	call 	draw_mouse				; Desenha o mouse
ret

; Função: Abre menu do mouse com seus itens
; Nota: Entradas internas descritas em outras funções
open_mouse_menu:
	mov 	word[option_select_y], 0
	mov 	word[option_select_x], 0
	
    call 	erase_window_mouse
	mov 	byte[right_pressed], 1
	mov 	dx, [screen_y]	; DX = Linha Inicial
	mov 	cx, [screen_x]	; CX = Coluna Inicial
	mov 	[savewy], dx
	mov 	[savewx], cx
	mov 	al, 13h 			; AL = Cor do Pixel = cinza
	mov 	word[sizewx], 80
	mov 	word[sizewy], 100
	call 	paint_window_mouse

	mov 	di, open_menu_y
	mov 	si, menu_list
	mov 	bl, menu_list.size
	add 	dx, 2
	add 	cx, 2
write_menu_options:
	push 	si
	mov 	si, [si]
	xor 	ah, ah
	call 	write_font
	mov 	[di], dx
	mov 	[di + 2], cx
	add 	dx, 9 + 3
	pop 	si
	add 	si, 2
	add 	di, 4
	dec 	bl
	jnz 	write_menu_options

	sub 	dx, 3
	mov 	[di], dx

	mov 	dx, [screen_y]			; DX = Linha Inicial
	mov 	cx, [screen_x]			; CX = Coluna Inicial
	mov 	word[sizewx], 16
	mov 	word[sizewy], 9
	call 	save_mouse_back
ret

; Função: Inicia o desenho inicial do ponteiro do mouse
; Nota: Entradas internas descritas em outras funções
init_mouse_pointer:
	mov 	dx, [screen_y]			; DX = Linha Inicial
	mov 	cx, [screen_x]			; CX = Coluna Inicial
	mov 	word[sizewx], 16
	mov 	word[sizewy], 9
	call 	save_mouse_back

	mov 	dx, [screen_y]			; DX = Linha Inicial
	mov 	cx, [screen_x]			; CX = Coluna Inicial
	mov 	ah, 19h	 				; AH = Cor das Bordas
	mov 	al, 1Fh					; AL = Cor do Fundo
	mov 	bh, 16 					; BH = Número de pixels da linha
	mov 	bl, mouse_bitmap.size 	; BL = Número de linhas
	mov 	si, mouse_bitmap		; SI = Bitmap
	call 	draw_mouse				; Desenha o mouse
ret

wait_to_write:
    in al, 0x64
    and al, 00000010b
    jnz wait_to_write
ret

wait_to_read:
     in al, 0x64
     and al, 00100001b
     jz wait_to_read
ret

send_command:
    mov cx, 10  ; numero de tentativas
start:
	pusha
    push ax
    call wait_to_write
    mov al, 0xD4
    out 0x64, al

    call wait_to_write
    pop ax
    out 0x60, al
    call wait_to_read
    
check_ack:
     in al, 0x60
     cmp al, 0xFA
     je AknowledgeCommand
	 popa
     loop start

     stc
     ret

AknowledgeCommand:
	 popa
     clc
     ret

mouse_start:
	; Configura escala 1:1 (2:1 = 0xE7)
	mov al, 0xE6
    call send_command
    jc error_mouse

	; Configura taxa de amostragem (sample = 80)
	mov al, 0xF3
	call send_command
	jc error_mouse
	mov al, [sample_rate]
	call send_command
	jc error_mouse

	; Configura resolução (res = 0 = 1 count/mm)
	mov al, 0xE8
	call send_command
	jc error_mouse
	mov al, [resolution]
	call send_command
	jc error_mouse

	; Habilita Packets Streaming (Envio automático de pacotes)
    mov al, 0xF4  
    call send_command
    jc error_mouse

	mov 	ah, 00h
	mov 	al, 13h
	int 	0x10

	call 	init_mouse_pointer

wait_packet:
    call wait_to_read
    in al, 0x60
    mov [mouse_status], al

    call wait_to_read
    in al, 0x60
    mov [mouse_deltaX], al

    call wait_to_read
    in al, 0x60
    mov [mouse_deltaY], al

check_button_left:
    mov al, [mouse_status]
    and al, 00000001b
    jnz ButtonLeft

	call 	erase_selection

check_button_right:
    mov al, [mouse_status]
    and al, 00000010b
    jnz ButtonRight

check_button_middle:
    mov al, [mouse_status]
    and al, 00000100b
    jnz ButtonMiddle

check_process_movement:
	mov 	al, [mouse_deltaX]
	mov 	bl, [mouse_deltaY]
	or 		al, bl
	jz 		wait_packet

	call 	process_movement
    jmp 	wait_packet

ButtonLeft:
	mov 	word[option_select_y], 0
	mov 	word[option_select_x], 0

	call 	erase_window_mouse

	mov 	byte[left_pressed], 1
	call 	save_coord_selection

	jmp 	check_button_right

ButtonRight:
	call 	open_mouse_menu
   	jmp 	check_button_middle

ButtonMiddle:

   	jmp 	check_process_movement

process_movement:
	movzx 	ax, byte[mouse_deltaX]
	mov 	bl, [mouse_status]
	and 	bl, 00010000b
	jz 		no_deltax_neg
	or 		ax, 0xFF00
no_deltax_neg:
	add 	[screen_x], ax
	mov 	[mouse_deltaX_temp], ax
	push 	ax

	movzx 	ax, byte[mouse_deltaY]
	mov 	bl, [mouse_status]
	and 	bl, 00100000b
	jz 		no_deltay_neg
	or 		ax, 0xFF00
no_deltay_neg:
	not 	ax
	add 	ax, 1
	add 	[screen_y], ax
	mov 	[mouse_deltaY_temp], ax
	push 	ax
	
	mov ax, [screen_y]
	mov [screeny_changed], ax
	mov ax, [screen_x]
	mov [screenx_changed], ax
	and ax, 8000h
	jnz zero_screenx
	cmp word[screen_x], SCREEN_WIDTH - 13
	jae set_screenx
	mov ax, [screen_y]
	and ax, 8000h
	jnz zero_screeny
	cmp word[screen_y], SCREEN_HEIGHT - 5
	jae set_screeny
	jmp done_mouse_move
zero_screenx:
	mov word[screen_x], -2
	jmp done_mouse_move
set_screenx:
	mov word[screen_x], SCREEN_WIDTH - 13
	jmp done_mouse_move
zero_screeny:
	mov word[screen_y], 0
	jmp done_mouse_move
set_screeny:
	mov word[screen_y], SCREEN_HEIGHT - 5

done_mouse_move:
	pop 	ax
	pop 	bx
	call 	mouse_pointer_move
ret

error_mouse:
     mov si, error_msg
     call Print_String
     xor ax, ax
	 int 16h
ret

error_msg  db "Nao foi possivel configurar o mouse!",0
left_msg  db "L",0
right_msg  db "R",0
middle_msg  db "M",0
mouse_msg  db "O mouse foi configurado!",13,10,0
msg_deltaX db "Valor DeltaX: ",0
msg_deltaY db "Valor DeltaY: ",0
msg_mouseX db "Valor Coluna: ",0
msg_mouseY db "Valor Linha: ",0
; --------------------------------------------------
; THE KERNEL ENTRY MAIN

Kernel_Entry:
	cld
	mov 	ax, 0x3000		;0x0C00
	mov 	ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov 	gs, ax
	mov 	ax, 0x0000		;0x07D0
	mov 	ss, ax
	mov 	sp, 0x1990		;0xFFFF

	jmp 	mouse_start
	; Uncomment only for debugging of the kernel
	;mov 	ah, 00h
	;int 	16h

	; -------------------------------------------------------------------------
	; CÓDIGOS PARA CRIAR A INT 21H DO DOS PELA IVT
	
	mov 	bx, 21h
	mov 	si, DOS_INT_21H
	call 	Create_IVT_Intr

	mov 	bx, 22h
	mov 	si, MIKE_INT_22H
	call 	Create_IVT_Intr

	; -------------------------------------------------------------------------
	
	; Text Mode
	mov 	ah, 00h
	mov 	al, 03h
	int 	10h
	
	; -------------------------------------------------------------------------
	; INICIALIZAÇÃO DO SISTEMA DE ARQUIVOS
	call 	FAT16.LoadFatVbrData

	mov 	si, Extension
	mov 	bx, DRIVERS_OFFSET
	mov 	word[FAT16.DirSegments], 0x0200	; era 0x07C0
	call 	FAT16.LoadAllFiles
	call 	MEMX86.Detect_Low_Memory

	mov 	word[FAT16.FileSegments], 0x2000
	mov 	word[FAT16.DirSegments], 0x200
	mov 	byte[FAT16.LoadingDir], 0
	mov 	ax, 0x200
	mov 	bx, 0x0000
	mov 	si, mikeapi
	call 	FAT16.LoadThisFile
	clc

	call 	Check_Volumes		; Configura partições & volumes
	; -------------------------------------------------------------------------

	;call 	KEYBOARD.Initialize 		; Há alguns problemas a ser resolvidos
	;call 	PCI.Init_PCI

	clc
	
	; -------------------------------------------------------------------------
	; INICIALIZAÇÃO DE DRIVER PCI E SERVIÇOS DE REDE VIA APLICAÇÃO
	;mov 	si, pci_program
	;call 	SHELL.Execute
	;mov 	ebx, 1000000		; 2 seconds
	;call 	Delay_us
	;xor 	ebx, ebx
	;mov 	si, rtl_program
	;call 	SHELL.Execute
	
	; --------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; KERNEL INITIAL USER-INTERFACE
Load_Menu:
	mov 	si, PressKey
	call 	Print_String
	mov 	ah, 00h
	int 	16h

Kernel_Menu:
	call 	Hide_Cursor   ; Set Cursor Shape Hide
	
	Back_Blue_Screen:
		mov     bh, 0001_1111b     ; Blue_White 
		mov     cx, 0x0000         ; CH = 0, CL = 0     
		mov     dx, 0x1950         ; DH = 25, DL = 80
		call    Create_Panel
		
	Dialog_Panel:
		mov     bh, 0100_1111b     ; Red_White 
		mov     cx, 0x0818         ; CH = 8, CL = 24     
		mov     dx, 0x1038         ; DH = 16, DL = 56
		call    Create_Panel
		mov     bh, 0111_0000b     ; White_Black
		mov     cx, 0x0919         ; CH = 9, CL = 25     
		mov     dx, 0x0F37         ; DH = 15, DL = 55
		call    Create_Panel
		
	Dialog_Options:	
		add 	ch, 2
		add 	cl, 1
		push 	cx
		pop		dx
		mov 	byte[Counter], 0
		mov 	byte[Selection], ch
		mov     bh, 0100_1111b     ; Red_White
		call	Select_Event
		push 	dx
	Write_Options:
		pop 	dx
		push 	dx
		call	Move_Cursor
		mov 	si, Option1
		call	Print_String
		inc 	dh
		call	Move_Cursor
		mov 	si, Option2
		call	Print_String
		inc		dh
		call	Move_Cursor
		mov 	si, Option3
		call	Print_String
		pop 	dx
		push 	dx
		mov 	ax, G3
		call 	Play_Speaker_Tone
		jmp 	Select_Options
		
		QUANT_OPTIONS  EQU 3
		Option1    db "Textual Mode   (shell16.osf)",0
		Option2    db "Graphical Mode (winmng.osf)",0
		Option3    db "System Informations",0
		Selection  db 0
		Counter	   db 0
		Systems    dw SHELL16_INIT, WMANAGER_INIT, SYSTEM_INFORMATION
		  
		  
	Select_Options:
		mov 	ah, 00h
		int 	16h
		cmp 	ah, 0x50
		je 		IncSelection
		cmp 	ah, 0x48
		je 		DecSelection
		cmp 	al, 0x0D
		je 		RunSelection
		jmp 	Select_Options
		
	IncSelection:
		cmp		byte[Counter], QUANT_OPTIONS-1
		jne		IncNow
		mov 	byte[Counter], 0
		call 	Erase_Select
		sub		ch, 2
		call	Focus_Select
		jmp 	Write_Options
		IncNow:
			inc 	byte[Counter]
			call 	Erase_Select
			inc 	ch
			call	Focus_Select
			jmp 	Write_Options
	DecSelection:
		cmp		byte[Counter], 0
		jne		DecNow
		mov 	byte[Counter], QUANT_OPTIONS-1
		call 	Erase_Select
		add		ch, 2
		call	Focus_Select
		jmp 	Write_Options
		DecNow:
			dec 	byte[Counter]
			call 	Erase_Select
			dec 	ch
			call	Focus_Select
			jmp 	Write_Options
			
	RunSelection:
		pop 	dx
		xor 	bx, bx
		mov 	bl, byte[Counter]
		shl		bx, 1
		mov 	bx, word[Systems + bx]
		mov 	ax, A3
		call 	Play_Speaker_Tone
		jmp 	bx
	
	Erase_Select:
		mov  	ch, byte[Selection]
		mov 	dh, ch
		mov     bh, 0111_0000b     ; Black_White
		call 	Select_Event
		mov  	ch, byte[Selection]
	ret
	
	Focus_Select:
		mov 	dh, ch
		mov 	byte[Selection], ch
		mov     bh, 0100_1111b     ; Red_White
		call 	Select_Event
	ret	
	
	Select_Event:
		push  	dx
		add		dl, 28
		call	Create_Panel
		pop 	dx
	ret
	
	
	
	WMANAGER_INIT:
		
		mov		ax, 4800h 
		mov 	fs, ax
		mov 	ax, 5800h
		mov 	gs, ax
		
		call 	WINMNG
		
		mov 	ah, 00h
		mov 	al, 03h
		int 	10h
		
		mov 	byte[SHELL.CursorRaw], 0
		mov 	byte[SHELL.CursorCol], 0
		jmp 	Kernel_Menu
		
		
	SHELL16_INIT:
	
		jmp 	3000h:SHELL16	; Era 0C00h:...
		
		
	SYSTEM_INFORMATION:
		mov     bh, 0010_1111b     ; Green_White 
		mov     cx, 0x0616         ; CH = 8, CL = 24     
		mov     dx, 0x133A         ; DH = 16, DL = 56
		call    Create_Panel
		mov     bh, 0111_0010b     ; White_Green
		mov     cx, 0x0717         ; CH = 9, CL = 25     
		mov     dx, 0x1239         ; DH = 15, DL = 55
		call    Create_Panel
		inc 	ch
		inc 	cl
		mov 	dx, cx
		mov 	cx, 10
		mov 	si, Informations
		call	Write_Info
		mov 	ah, 00h
		int 	16h
		jmp 	Back_Blue_Screen
		
	Informations:
		SystemName  db "System Name  : KiddieOS",0
		Version 	db "Version      : ",VERSION,0
		Author      db "Author       : Francis (BFTC)",0
		Arquiteture db "Arquitecture : 16-bit (x86)",0
		FileSystem  db "File System  : FAT16",0
		RunningFile db "Running File : kernel.osf",0
		GuiVersion  db "GUI Version  : Window 2.0",0
		SourceCode  db "Source-Code  : Assembly x86",0
		Lang        db "Language     : English (US)",0
		DateTime    db "Date/Time    : 05/01/2021 08:31",0
; ----------------------------------------------------------------------------

		
; ----------------------------------------------------------------------------
; KERNEL FUNCTIONS LIBRARY

syscall.prog: 	
	call SYSCMNG
retf

winmng.video:	
	call WINMNG+3
retf

shell.cmd:		
	call SHELL16+3
retf

tone.play:		
	call Play_Speaker_Tone
retf
	
Create_IVT_Intr:
	pusha
	push 	es
	xor 	ax, ax
	mov 	es, ax
	shl 	bx, 2
	mov 	ax, ds
	mov 	word[es:bx], si
	add 	bx, 2
	mov 	word[es:bx], ax
	pop 	es
	popa
ret

Check_Volumes:
	pusha
	push 	es
	xor 	ax, ax
	mov 	es, ax
	mov 	si, 0x600 + 0x1BE
	mov 	ecx, 4
	xor 	bx, bx
	mov 	di, SHELL.VolumeStruct
	mov 	byte[VolumeLetters], 'K'
ChV.read_partitions:
	push 	cx
	cmp 	byte[es:si + 4], 0x00
	jz 		ChV.next_partition
	cmp 	byte[es:si + 4], 0x0F
	jz 		ChV.extended_found
	cmp 	byte[es:si + 4], 0x05
	jz 		ChV.extended_found
	jmp 	ChV.get_info_part

	ChV.extended_found:
		mov 	eax, [es:si + 12]
		mov 	[lba_size_extended], eax

		cmp 	byte[isLogical], 1
		jz 		ChV.next_partition

		mov 	eax, [es:si + 8]
		mov 	[lba_begin_extended], eax
		inc 	bx
		jmp 	ChV.next_partition
		
	ChV.get_info_part:
		inc 	bx
		
		;cmp 	byte[isLogical], 1
		;jz 		PR.skip_lba_read

		; Talvez este código tenha que executar em cada partição lógica
		; para conhecer a VBR dela (se houver). Neste caso, comentei o código acima.
		mov 	eax, [es:si + 8]	; bp 3000:000008c2
		mov 	dx, VBR_buffer
		call 	ReadBootRecord

	ChV.skip_lba_read:
		push 	si
		mov 	al, [es:si + 4]
		mov 	edx, [es:si + 8]
		mov 	si, VBR_buffer 
		call 	check_filesystem
		pop 	si

	ChV.next_partition:
		add 	si, 16
		pop 	cx
		dec 	cx
		cmp 	cx, 0
		jnz 	ChV.read_partitions
		
		pop 	es

		cmp 	dword[lba_size_extended], 0		; bp 3000:000008fb
		jz 		RET.Check_Volumes

		mov 	eax, [lba_begin_extended]
		cmp 	byte[isLogical], 1
		jnz 	ChV.without_logical

		sub 	si, 16
		mov 	edx, [es:si + 8]
		add 	eax, edx
		mov 	[lba_begin_logical], edx

	ChV.without_logical:
		mov 	dx, EBR_buffer
		call 	ReadBootRecord

		mov 	si, EBR_buffer + 0x1BE
		mov 	cx, 2
		mov 	dword[lba_size_extended], 0

		push 	ds
		pop 	es
		mov 	eax, [lba_begin_extended]	; depurar bp 3000:0000093E
		add 	eax, [es:si + 8]
		add 	eax, [lba_begin_logical]
		mov 	[es:si + 8], eax
		mov 	byte[isLogical], 1

		push 	es
		jmp 	ChV.read_partitions
RET.Check_Volumes:
	mov 	dword[lba_size_extended], 0
	mov 	dword[lba_begin_extended],0
	mov 	dword[lba_begin_logical], 0
	mov 	byte[isLogical], 0
	popa
ret

ReadBootRecord:
	push 	bx
	push 	es
	mov 	bx, dx
	mov 	cx, 1
	push 	ds
	pop 	es
	call 	FAT16.ReadSectors
	pop 	es
	pop 	bx
ret

check_filesystem:
	pusha			; bp 3000:0000097b
	push 	es
	push 	ds
	pop 	es

check_fs_struct:
	push 	di
	mov 	di, format_types
	mov 	cx, COUNT_FORMAT_TYPES
loop_fs_check:
	cmp 	[ds:di], al
	jz 		fs_found
loop_fs_check2:
	add 	di, 9
	loop 	loop_fs_check
	jmp 	fs_not_found

fs_found:
	push 	di
	inc 	di
	cmp 	al, 0x06
	jz 		check_fat_struct
	cmp 	al, 0x0B
	jz 		check_fat_struct
	cmp 	al, 0x0C
	jz 		check_fat_struct
	cmp 	al, 0x07
	jz 		check_ntfs_exfat_struct
	jmp 	RET.check_filesystem_fail

check_ntfs_exfat_struct:
	push 	si
	add		si, 3
	mov 	word[label_offset], 512
	jmp 	other_found

check_fat_struct:
	push 	si
	cmp 	al, 0x0C
	jz 		fat32_found
	add 	si, 54
	mov 	word[label_offset], 43
	jmp 	other_found
fat32_found:
	add 	si, 82
	mov 	word[label_offset], 71

other_found:
	push 	cx
	mov 	cx, 8
	repe 	cmpsb
	pop 	cx
	pop 	si
	pop 	di
	jne 	loop_fs_check2
	;jne 	fs_not_found

	mov 	cx, [ds:si + 0x1FE]
	cmp 	cx, 0xAA55
	jnz 	fs_not_found

	mov 	[save_value_si], si
	mov 	cx, 8
	mov 	si, di
	pop 	di
	push 	di
	inc 	si
	add 	di, 17
	rep 	movsb
	mov 	si, [save_value_si]

	pop 	di

	mov 	[di + 0], bl		; partition id
	mov 	[di + 1], al 		; filesystem id
	mov 	[di + 2], edx		; initial lba
	mov 	al, [VolumeLetters]
	mov 	byte[di + 25], al	; drive letter
	inc 	byte[VolumeLetters]

	push 	di
	push 	si
	add 	si, [label_offset]
	add  	di, 6
	mov 	cx, 11		; Depuração parou aqui! Endereço -> bp 3000:000009ba (Verificar DS:DI)
	rep 	movsb
	pop 	si
	pop 	di

	; DI + 17 is the FS String

	jmp 	RET.check_filesystem_ok
	
fs_not_found:
	pop 	di
	jmp 	RET.check_filesystem_fail

RET.check_filesystem_fail:
	pop 	es
	popa
ret
RET.check_filesystem_ok:
	pop 	es
	popa
	add 	di, 26
ret

; IN: EBX = microseconds
Delay_us:
	pusha
	mov 	ah, 86h
	mov 	dx, bx
	shr 	ebx, 16
	mov 	cx, bx
	int 	15h
	popa
ret

Print_Fat_Time:
	pusha
	mov 	bx, ax
	xor 	eax, eax
	mov 	ax, bx
	and 	ax, (11111b << 11)
	shr 	ax, 11
	cmp 	al, 10
	jnb 	NoTimeZero1
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero1:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, ':'
	int 	0x10
	mov 	ax, bx
	and 	ax, (111111b << 5)
	shr 	ax, 5
	cmp 	al, 10
	jnb 	NoTimeZero2
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero2:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, ':'
	int 	0x10
	mov 	ax, bx
	and 	ax, 11111b
	cmp 	al, 10
	jnb 	NoTimeZero3
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero3:
	call 	Print_Dec_Value32
	popa
ret


Print_Fat_Date:
	pusha
	mov 	bx, ax
	xor 	eax, eax
	mov 	ax, bx
	and 	ax, 11111b
	cmp 	al, 10
	jnb 	NoZero1
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoZero1:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, '/'
	int 	0x10
	mov 	ax, bx
	and 	ax, (1111b << 5)     ;(1111b << 5) = 480 = 111100000b
	shr 	ax, 5
	cmp 	al, 10
	jnb 	NoZero2
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoZero2:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, '/'
	int 	0x10
	mov 	ax, bx
	and 	ax, (1111111b << 9)
	shr 	ax, 9
	sub 	ax, 20
	add 	ax, 2000
	call 	Print_Dec_Value32
	popa
ret

; Exibe nomes de arquivos do FAT16 colocados em ES:DI
PrintNameFile:
	pusha
	mov 	cx, 11
	mov 	ah, 0x0E
	mov 	dl, byte[es:di + 11]
	xor 	bx, bx
Analyze:
	mov 	al, byte[es:di]
	cmp 	al, 0x20
	je 		NoPrintSpace
	cmp 	cx, 11
	je 		Display
	cmp 	al, "."
	je 		Display
	mov 	bl, al
	cmp 	bl, 0x3A
	jb 		ConvertNumber
	jmp 	ConvertCase
ConvertNumber:
	sub 	bl, 0x30
	mov 	al, byte[VetorHexa + bx]
	jmp 	Display
ConvertCase:
	sub 	bl, 0x41
	mov 	al, byte[VetorCharsLower + bx]
Display:
	int 	0x10
	inc 	byte[SHELL.CounterFName]
NoPrintSpace:
	cmp 	cx, 4
	jne 	NoPrintDot
	cmp 	dl, 0x08
	jb 		PrintDot
	cmp 	dl, 0x20
	jne 	NoPrintDot
PrintDot:
	mov 	al, '.'
	int 	10h
NoPrintDot:
	inc 	di 
    loop 	Analyze
.DONE:
	popa
RET

; Exibe Strings estáticas do sistema operacional colocados em DS:SI
Print_String:
	pusha
	mov 	ah, 0eh
	prints:
		mov 	al, [si]
		cmp 	al, 0
		jz		ret_print
		inc 	si
		int 	10h
		jmp 	prints
	ret_print:
		popa
ret	

; Imprime representação hexadecimal de 16 bits colocado em DS:SI
Print_Hexa_Value16:
	pusha
	mov SI, AX
	mov DX, 0xF000
	mov CL, 12
Print_Hexa16:
	mov BX, SI
	and BX, DX
	shr BX, CL
	push SI
	mov AH, 0Eh
	mov AL, byte[VetorHexa + BX]
	int 10h
	pop SI
	cmp CL, 0
	jz RetHexa
	sub CL, 4
	shr DX, 4
	jmp Print_Hexa16
RetHexa:
	popa
ret

; Imprime representação hexadecimal de 8 bits colocado em DS:SI
Print_Hexa_Value8:
	pusha
	xor AH, AH
	mov SI, AX
	mov DX, 0x00F0
	mov CL, 4
Print_Hexa8:
	mov BX, SI
	and BX, DX
	shr BX, CL
	push SI
	mov AH, 0Eh
	mov AL, byte[VetorHexa + BX]
	int 10h
	pop SI
	cmp CL, 0
	jz RetHexa1
	sub CL, 4
	shr DX, 4
	jmp Print_Hexa8
RetHexa1:
	popa
ret

Print_Hexa_Value32:
	pushad
	mov 	esi, eax
	mov 	edx, 0xF0000000
	mov 	cl, 28
Print_Hexa32:
	mov 	ebx, esi
	and 	ebx, edx
	shr 	ebx, cl
	push 	esi
	mov 	ah, 0Eh
	mov 	al, byte[VetorHexa + bx]
	int 	10h
	pop 	esi
	cmp 	cl, 0
	jz 		RetHexa32
	sub 	cl, 4
	shr 	edx, 4 
	jmp 	Print_Hexa32
	RetHexa32:
	popad
ret

Print_Dec_Value32:
	pushad
	cmp 	eax, 0
	je 		ZeroAndExit
	xor 	edx, edx
	mov 	ebx, 10
	mov 	ecx, 1000000000
DividePerECX:
	cmp 	eax, ecx      ; EAX = 950000
	jb 		VerifyZero
	mov 	byte[Zero], 1
	push 	eax
	div 	ecx
	xor 	edx, edx
	push 	ax
	push 	bx
	mov 	bx, ax
	mov 	ah, 0Eh
	mov 	al, byte[VetorDec + bx]
	int 	10h
	pop 	bx
	pop 	ax
	mul 	ecx
	mov 	edx, eax
	pop 	eax
	sub 	eax, edx
	xor 	edx, edx
DividePer10:
	cmp 	ecx, 1
	je 		Ret_Dec32
	push 	eax
	mov 	eax, ecx
	div 	ebx
	mov 	ecx, eax
	pop 	eax
	jmp 	DividePerECX
VerifyZero:
	cmp 	byte[Zero], 0
	je 		ContDividing
	push 	ax
	mov 	ax, 0E30h
	int 	10h
	pop 	ax
ContDividing:
	jmp 	DividePer10
ZeroAndExit:
	mov 	ax, 0E30h
	int  	10h
Ret_Dec32:
	mov 	byte[Zero], 0
	popad
ret

Parse_Dec_Value:
	pusha
	mov 	edx, 1
	mov 	ebx, 10
	
	push 	ecx
	dec 	si
EndSI:
	inc 	si
	loop 	EndSI
	pop 	ecx
	
Parsing:
	push 	ecx
	mov 	ecx, 10
	std
	lodsb
	cld
	mov 	di, VetorDec
	repne 	scasb
	
	push 	ebx
	inc 	ecx
	sub 	ebx, ecx
	
	push 	edx
	mov 	eax, edx
	xor 	edx, edx
	mul 	ebx
	pop 	edx
	
	add 	[Number], eax
	pop 	ebx
	mov 	eax, edx
	xor 	edx, edx
	mul 	ebx
	mov 	edx, eax
	
	pop 	ecx
	loop 	Parsing
	
	popa
	mov 	eax, [Number]
	mov 	byte[Number], 0
ret
Number 	dd 	0

Write_Info:
	call	Move_Cursor
	call	Print_String
	call 	NextInfo
	inc 	dh
	loop 	Write_Info
ret
	
NextInfo:
	inc 	si
	cmp 	byte[si], 0
	jne 	NextInfo
	inc 	si
ret

; Quebra de linha na exibição de Strings
Break_Line:
	mov ah, 0Eh
	mov al, 10
	int 10h
	mov al, 13
	int 10h
ret

; Cria painel no modo texto usando rotina de Limpar tela
Create_Panel:
	pusha
	mov ah, 06h
	mov al, 0
	int 10h
	popa
ret

Clear_Screen:
	mov 	ah, 06h
	mov 	al, 0
	mov 	ch, 0
	mov 	cl, 0
	mov 	dh, 25
	mov 	dl, 80
	int 	10h
ret

; Movimenta o cursor dado os parâmetros em DX
Move_Cursor:
	pusha
	mov ah, 02h
	mov bh, 00h
	int 10h
	popa
ret

Get_Cursor:
	push ax
	push bx
	push cx
	mov ah, 03h
	mov bh, 00h
	int 10h
	pop cx
	pop bx
	pop ax
ret

Hide_Cursor:
	pusha
	mov 	ah, 01h
	mov 	ch, 20h   ; bit 5 set is hiding cursor
	mov 	cl, 07h
	int 	10h
	popa
ret

Show_Cursor:
	pusha
	mov 	ah, 01h
	mov 	ch, 00h
	mov 	cl, 07h
	int 	10h
	popa
ret


; ==============================================================
; Rotina que mostra o conteúdo do vetor formatado
; IN: ECX = Tamanho do Vetor
;     ESI = Endereço do Vetor

; OUT: Nenhum.
; ==============================================================
Show_Vector32:
	pushad
	
	mov 	ax, 0x0E7B
	int 	0x10
	xor 	ebx, ebx
	
ShowVector:
	push 	ebx
	shl		ebx, 2
	mov 	eax, dword[esi + ebx]
	call 	Print_Dec_Value32
	pop 	ebx
	inc 	ebx
	mov 	ah, 0x0E
	mov 	al, ','
	int 	0x10
	loop 	ShowVector
	mov 	ax, 0x0E7D
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	mov 	ax, 0x0E0A
	int 	0x10
	
	popad
ret

; ==============================================================
; Rotina que aloca uma quantidade de bytes e retorna endereço
; IN: ECX = Tamanho de Posições (Size)
;     EBX = Tamanho do Inteiro (SizeOf(int))

; OUT: EAX = Endereço Alocado
; ==============================================================
Calloc:
	pushad
	
	xor 	eax, eax
	push 	ds
	pop 	es
	mov 	eax, MEMX86
	push 	ecx
	mov 	ecx, MEMX86_NUM_SECTORS
	
	Skip_Offset:
		add 	eax, 512
		loop 	Skip_Offset
		
	add 	eax, 4
	mov 	edi, eax
	xor 	eax, eax
	pop 	ecx
	push 	edi
	
	;mov 	es, ax
	
	cmp 	ebx, 1
	je 		Alloc_Size8
	cmp 	ebx, 2
	je 		Alloc_Size16
	cmp 	ebx, 4
	je 		Alloc_Size32
	jmp 	Return_Call
	
	; TODO 
	; Dados que podem estar na memória serão perdidos
	; nesta alocação, então melhor certificar que salvamos 
	; estes dados em algum lugar (talvez via push)
	; e recuperarmos na função Free()
	Alloc_Size8:  
		mov 	dword[Size_Busy], ecx
		rep 	stosb
		jmp 	Return_Call
	Alloc_Size16: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 1
		rep 	stosw
		jmp 	Return_Call
	Alloc_Size32: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 2
		rep 	stosd
		jmp 	Return_Call
	
Return_Call:
	pop 	DWORD[Return_Var_Calloc]
	popad
	mov 	eax, DWORD[Return_Var_Calloc]
	mov 	byte[Memory_Busy], 1
ret

Return_Var_Calloc dd 0
Size_Busy 	dd 0
Memory_Busy db 0


; ==============================================================
; Libera espaço dado um endereço alocado
; IN: EBX = Ponteiro de Endereço Alocado
;
; OUT: Nenhum.
; ==============================================================
Free:
	pushad
	mov 	edi, ebx
	;mov 	dword[ebx], 0x00000000
	push 	ds
	pop 	es
	mov 	al, 0
	mov 	ecx, dword[Size_Busy]
	rep 	stosb
	
	;push 	ds
	;pop 	es
	
	mov 	dword[Size_Busy], 0
	mov 	dword[Return_Var_Calloc], 0
	mov 	dword[Memory_Busy], 0
	popad
ret

; ----------------------------------------------------------
; MikeOS Services Routines

%macro istc 0
	push 	bp
	mov 	bp, sp
	or	 	WORD [bp + 6], 1
	pop 	bp
%endmacro

%macro iclc 0
	push 	bp
	mov 	bp, sp
	and	 	WORD [bp + 6], 0xFFFE
	pop 	bp
%endmacro

%macro intern 1
	mov 	byte[fs:intern_call], %1
	call 	store_call_status
%endmacro

MIKE_INT_22H:
	push 	bx
	xor 	bx, bx
	mov 	bp, sp
	mov 	bx, [bp + 8]  ; BP + 8 = 1 push (BX = 4 bytes) + 1 push (INT = 6 bytes) -> 10
	shl 	bx, 1
	push 	cs
	pop 	fs
	mov 	bx, [fs:MIKE_SERVICE + bx]
	mov 	[fs:isr_addr], bx
	pop 	bx
	mov 	byte[fs:tmp_call], 0
	mov 	byte[fs:intern_call], 0
	call 	store_call_status
	jmp 	WORD [fs:isr_addr]

isr_addr 	dw 0

MIKE_SERVICE:
	dw os_string_copy
	dw os_string_compare
	dw os_string_join
	dw os_string_to_int
	dw os_int_to_string
	dw os_string_uppercase
	dw os_string_lowercase
	dw os_string_length
	dw os_bcd_to_int
	dw os_get_random
	dw os_print_string
	dw os_input_string
	dw os_print_newline
	dw os_print_1hex
	dw os_print_2hex
	dw os_print_4hex
	dw os_move_cursor
	dw os_get_cursor_pos
	dw os_show_cursor
	dw os_hide_cursor
	dw os_clear_screen
	dw os_dialog_box
	dw os_list_dialog
	dw os_file_selector
	dw os_wait_for_key
	dw os_check_for_key
	dw os_get_file_list
	dw os_file_exists
	dw os_load_file
	dw os_write_file
	dw os_rename_file
	dw os_remove_file
	dw os_get_file_size
	dw os_get_api_version
	dw os_pause
	dw os_fatal_error
	dw os_port_byte_out
	dw os_port_byte_in
	dw os_serial_port_enable
	dw os_send_via_serial
	dw os_get_via_serial
	dw os_speaker_tone
	dw os_speaker_off

%INCLUDE "Lib/MikeOS/Functions/string.asm"
%INCLUDE "Lib/MikeOS/Functions/math.asm"
%INCLUDE "Lib/MikeOS/Functions/screen.asm"
%INCLUDE "Lib/MikeOS/Functions/keyboard.asm"
%INCLUDE "Lib/MikeOS/Functions/disk.asm"
%INCLUDE "Lib/MikeOS/Functions/misc.asm"
%INCLUDE "Lib/MikeOS/Functions/ports.asm"
%INCLUDE "Lib/MikeOS/Functions/sound.asm"

return:

.common:
	call 	restore_call_status
	cmp 	byte[fs:intern_call], 0
	jz 		.ret_extern
	mov 	byte[fs:intern_call], 0
	ret
.ret_extern:
	iret

.nocarry:
.fail:
	call 	restore_call_status
	cmp 	byte[fs:intern_call], 0
	jz 		.ret_extern_fail
	mov 	byte[fs:intern_call], 0
	clc
	ret
.ret_extern_fail:
	iclc
	iret

.carry:
.okay:
	call 	restore_call_status
	cmp 	byte[fs:intern_call], 0
	jz 		.ret_extern_okay
	mov 	byte[fs:intern_call], 0
	stc
	ret
.ret_extern_okay:
	istc
	iret

store_call_status:
	pusha
	xor 	bx, bx
	mov 	bl, [fs:index_call]
	mov 	al, [fs:intern_call]
	mov 	[fs:tmp_call + bx], al
	inc 	byte[fs:index_call]
	popa
ret

restore_call_status:
	pusha
	xor 	bx, bx
	dec 	byte[fs:index_call]
	mov 	bl, [fs:index_call]
	mov	 	al, [fs:tmp_call + bx]
	mov 	[fs:intern_call], al
	popa
ret

intern_call 	db 0
tmp_call 		db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
index_call 		db 0
; ----------------------------------------------------------


; ---------------------------------------------------------
; DOS Services Routines

DOS_INT_21H:
	push 	ds 
	push 	cs
	pop 	ds
	push 	bx
	push 	ax
	xor 	bx, bx
	shr 	ax, 8
	mov 	bx, ax
	shl 	bx, 1
	mov 	bx, word[DOS_SERVICES + bx]
	jmp 	bx
	
DOS_SERVICES:
	dw 0x0000                   ; Função 0 (0x00)
	dw dos_read_input           ; Função 1 (0x01) com echo
	dw dos_write_char           ; Função 2 (0x02)
	dw 0x0000                   ; Função 3 (0x03)
	dw 0x0000                   ; Função 4 (0x04)
	dw dos_printer_output       ; Função 5 (0x05)
	dw dos_input_output         ; Função 6 (0x06)
	dw dos_char_input           ; Função 7 (0x07) sem echo
	dw 0x0000                   ; Função 8 (0x08)
	dw dos_write_string         ; Função 9 (0x09)
	dw dos_read_string 			; Função 10 (0x0A)
	times 0x32 dw 0x0000		; 0x0A - 0x3C (Reserved)
	dw dos_open_file			; Função 0x3D
	dw dos_close_file			; Função 0x3E
	dw dos_read_file			; Função 0x3F
	dw 0x0000					; Função 0x40
	dw 0x0000					; Função 0x41
	dw dos_seek_file			; Função 0x42
	dw 0x0000					; Função 0x43
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw dos_exit_prog			; Função 0x4C
	
dos_read_input:
	pop 	ax
	pop 	bx
	
wait_key:
	mov 	ah, 1
	int 	0x16
	jz 		wait_key
	
	pop 	ds
iret
	
dos_write_char:
	pop 	ax
	pop 	bx
	
	;mov 	ah, 0x0E
	;mov 	al, dl
	;int 	0x10
	push 	es
	mov 	ax, ds
	mov 	es, ax
	mov 	[character], dl
	mov 	cx, 1
	mov 	di, character
	mov 	al, 0
	call 	SHELL.PrintData
	pop 	es
	
	mov 	al, [character]
	pop 	ds
iret

character db 0

dos_printer_output:
	pop 	ax
	pop 	bx
	
	xor 	dh, dh
	push 	dx
	xor 	dx, dx
	mov 	cx, 3
search_printer:
	mov 	ah, 0x01
	int 	0x17
	and 	ah, 00111111b
	cmp 	ah, 0
	jnz 	next_port
	
	pop 	ax
	mov 	ah, 00h
	int 	0x17
	jmp 	return_printer
	
next_port:	
	inc 	dx
	loop 	search_printer
	pop 	ax

return_printer:
	pop 	ds
iret

dos_input_output:
	pop 	ax
	pop 	bx
	
	cmp 	dl, 255
	jne 	write_char
	
	mov 	ah, 1
	int 	0x16
	jz 		error_no_char
	
	pop 	ds
	push 	bp
	mov 	bp, sp
	and	 	WORD [bp + 6], 0xFFBF
	pop 	bp
	mov 	ah, 0x00
	int 	0x16
	jmp 	return_in_out
	
error_no_char:
	pop 	ds
	push 	bp
	mov 	bp, sp
	or	 	WORD [bp + 6], 0x40
	pop 	bp
	xor 	ax, ax
	jmp 	return_in_out
	
write_char:
	mov 	ah, 2
	int 	0x21
	;mov 	ah, 0x0E
	mov 	al, dl
	;int 	0x10
	pop 	ds
	
return_in_out:
	iret
	


dos_char_input:
	pop 	ax
	pop 	bx
	
wait_echo:
	mov 	ah, 1
	int 	0x16
	jz 		wait_echo
	
no_echo:
	mov 	ax, 0x00
	int 	0x16
	
	pop 	ds
iret

dos_write_string:
	pop 	ax
	pop 	bx
	pusha
	
	;add 	dx, [SHELL.DOS_HEADER_BYTES]
	mov 	di, dx
	mov 	al, 1
	call 	SHELL.PrintData
	
	popa
	pop 	ds
iret

dos_read_string:
	pop 	ax
	pop 	bx
	
	xor 	bx, bx
	xor 	cx, cx
	
	mov 	ax, es
	mov 	ds, ax
	
	mov 	di, dx
	mov 	byte[di + 1], 0
	cmp 	byte[di], 0
	jz 		return_read_str
read_str:
	push 	di
	push 	cx
	mov 	ah, 07h
	int 	0x21
	cmp 	al, 0x08
	jz 		back_char
	mov 	ah, 02h
	mov 	dl, al
	int 	0x21
	cmp 	al, 0x0D
	jz 		return_read_wpop
	pop 	cx
	pop 	di
	xor 	bx, bx
	mov 	bl, [offset_char]
	mov 	[es:di + bx + 2], al
	inc 	cl
	mov 	[es:di + 1], cl
	inc 	bl
	mov 	[offset_char], bl
	cmp 	byte[es:di], bl
	jnz 	read_str
	push 	di
	push 	cx
is_major:
	mov 	ah, 07h
	int 	0x21
	cmp 	al, 0x08
	jne 	is_major
back_char:
	pop 	cx
	pop 	di
	cmp 	byte[offset_char], 0
	jz 		read_str
	mov 	ah, 0Eh
	mov 	al, 0x08
	int 	0x10
	mov 	ah, 0Eh
	mov 	al, 0
	int 	0x10
	mov 	ah, 0Eh
	mov 	al, 0x08
	int 	0x10
	mov 	al, 0
	xor 	bx, bx
	dec 	byte[offset_char]
	mov 	bl, [offset_char]
	mov 	[es:di + bx + 2], al
	dec 	byte[es:di + 1]
	dec 	cx
	jmp 	read_str
	
return_read_wpop:
	pop 	cx
	pop 	di

return_read_str:
	mov 	byte[offset_char], 0
	pop 	ds
	iret

offset_char db 0

dos_open_file:
	pop 	ax
	pop 	bx
	
	;add 	dx, [SHELL.DOS_HEADER_BYTES]
	mov 	si, dx
	
	mov 	bx, ds
	mov 	gs, bx
	mov 	bx, SHELL.CD_SEGMENT
	
	pop 	ds
	
	push 	es
	push 	WORD[gs:bx]
	push 	ax
	
	mov 	ax, 0x3000
	mov 	es, ax
	
	mov 	di, SHELL.BufferAux2
	call 	SHELL.Copy_Buffers
	
	mov 	ds, ax
	mov 	si, SHELL.BufferAux2
	mov 	di, SHELL.BufferKeys
	mov 	byte[SHELL.IsCommand], 0
	call 	SHELL.Format_Command_Line
	
	call 	SHELL.Store_Dir
	
	mov 	cx, 1
	call 	SHELL.Load_File_Path
	mov 	ax, 03h
	pop 	dx
	jc 		open_error
	
	; Note: DH = 2 funciona o comando SIZE no Basic, porém tem que ficar abrindo o arquivo
	; pelo WRITE para mudar as permissões, já que CHMOD não está funcionando.
	; DH = 4 torna as permissões para sistema, funcionando os jogos do MikeOS, mas, o comando SIZE não funciona.
	mov 	dh, 4
	mov 	ax, [SHELL.CD_SEGMENT]
	call 	FAT16.OpenThisFile
	jc 		open_error
	
	clc
	jmp 	return_dos_open
	
open_error:
	mov 	[handler], ax
	pop 	WORD[SHELL.CD_SEGMENT]
	call 	SHELL.Restore_Dir
	mov 	ax, [handler]
	pop 	es
	mov 	bx, es
	mov 	ds, bx
	push 	bp
	mov 	bp, sp
	or	 	WORD [bp + 6], 1
	pop 	bp
	iret
return_dos_open:
	mov 	[handler], ax
	pop 	WORD[SHELL.CD_SEGMENT]
	call 	SHELL.Restore_Dir
	mov 	ax, [handler]
	pop 	es
	mov 	bx, es
	mov 	ds, bx
	push 	bp
	mov 	bp, sp
	and	 	WORD [bp + 6], 0xFFFE
	pop 	bp
	iret
handler dw 0x0000

dos_read_file:
	pop 	ax
	pop 	bx
	
	mov 	ax, es
	mov 	[FAT16.DirSegments], ax
	mov 	ax, 0x6800
	mov 	[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	
	push 	es
	call 	FAT16.LoadFile
	pop 	es
	jc 		read_error
	
	pop 	ds
	push 	bp
	mov 	bp, sp
	and	 	WORD [bp + 6], 0xFFFE
	pop 	bp
	iret
	
read_error:
	pop 	ds
	push 	bp
	mov 	bp, sp
	or	 	WORD [bp + 6], 1
	pop 	bp
	iret
	
dos_seek_file:
	pop 	ax
	pop 	bx
	
	call 	FAT16.SetSeek
	jc 		seek_error
	
	pop 	ds
	push 	bp
	mov 	bp, sp
	and	 	WORD [bp + 6], 0xFFFE
	pop 	bp
	iret
	
seek_error:
	pop 	ds
	push 	bp
	mov 	bp, sp
	or	 	WORD [bp + 6], 1
	pop 	bp
	iret
	
dos_close_file:
	pop 	ax
	pop 	bx
	
	mov 	WORD [FAT16.FileSegments], 0x6800
	call 	FAT16.CloseFile
	jc 		close_error
	
	pop 	ds
	push 	bp
	mov 	bp, sp
	and	 	WORD [bp + 6], 0xFFFE
	pop 	bp
	iret
	
close_error:
	pop 	ds
	push 	bp
	mov 	bp, sp
	or	 	WORD [bp + 6], 1
	pop 	bp
	iret
	
	
	
	

dos_exit_prog:
	pop 	ax
	pop 	bx
	pop 	ds
	
	add 	sp, 6
retf

; ---------------------------------------------------------

; --------------------------------------------------------


Reboot_System:
	; Reinicia sistema
	; _________________________________________
	mov ax, 0040h
	mov ds, ax
	mov ax, 1234h
	mov [0072h], ax
	jmp 0FFFFh:0000h
; _____________________________________________
; _____________________________________________

%DEFINE MIKEOS_VER '4.7.0'	; OS version number
%DEFINE MIKEOS_API_VER 18	; API version for programs to check


disk_buffer		equ	24576
ParaPerEntry	equ 2
fmt_12_24	db 0		; Non-zero = 24-hr format
fmt_date	db 0, '/'

;%INCLUDE "features/disk.asm"
;%INCLUDE "features/keyboard.asm"
;%INCLUDE "features/misc.asm"
;%INCLUDE "features/ports.asm"
;%INCLUDE "features/screen.asm"
;%INCLUDE "features/sound.asm"
;%INCLUDE "features/basic.asm"
