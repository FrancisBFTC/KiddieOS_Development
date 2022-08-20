%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG WMANAGER]

mov		ax, 4800h 
mov 	fs, ax

jmp Os_Wmanager_Setup

%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"
%INCLUDE "Hardware/win3dmov.lib"

Os_Wmanager_Setup:
	mov word[PositionX], 100
	mov word[PositionY], 10
	mov word[W_Width], 120
	mov word[W_Height], 120
	mov cx, _WALL
	
	mov byte[fs:CountField], -1
	mov byte[fs:QuantTab], 0
	
Start:
	WallPaper cx, SCREEN_WIDTH, SCREEN_HEIGHT, 40, 20
	Window3D MOVABLE, word[PositionX], word[PositionY], word[W_Width], word[W_Height]
cmp al, 2
je Start

jmp Reboot_System



; Rotina que cria janela 3D com elementos visuais
;_________________________________________________________________________
WindowCreate:
	SaveInMemory ERASE, BACK, 1
	call Resizing1
	__CreateWindow 0,0,0,0,0,0,0,ax,bx,cx,dx   				; Sombra da janela
	__ShowWindow 1                                  		; Window´s Shadow
	call Resizing2
	__CreateBorder 28,18,18,28
	__CreateWindow 1,1,1,0,16,18,COLOR_WINDOW,ax,bx,cx,dx   ; Janela principal
	__ShowWindow 1                               		 	; Main Window
	call Resizing3
	__CreateBorder 18,28,28,18
	__CreateWindow 0,0,0,0,0,0,COLOR_WINDOW-1,ax,bx,cx,dx   ; Janela Interior - "Bordas Maiores"
	__ShowWindow 1                                          ; Intern Window - "Longers Borders"
	call Resizing4
	__CreateBorder 28,18,18,28
	__CreateWindow 0,0,0,0,0,0,COLOR_WINDOW,ax,bx,cx,dx     ; Janela do centro - "FieldSet"
	__ShowWindow 1                                          ; Center´s Window - "FieldSet"
	call Resizing5
	__CreateBorder 18,28,28,18
	__CreateField Text1,0,0,31,ax,bx,cx,8                   ; 1ª campo de texto
	__ShowField 1                                           ; 1st Text Field
	call Resizing6
	__CreateBorder 18,28,28,18
	__CreateField Text2,0,0,31,ax,bx,cx,8                   ; 2ª campo de texto
	__ShowField 1                                           ; 2st Text Field
	call Resizing7
	__CreateBorder 28,18,18,28
	__CreateButton Button1,0,0,COLOR_WINDOW-2,ax,bx,cx,10   ; 1ª Botão
	__ShowButton 1                                          ; 1st Button
	call Resizing8
	__CreateBorder 28,18,18,28
	__CreateButton Button2,0,0,COLOR_WINDOW-2,ax,bx,cx,10   ; 2ª Botão
	__ShowButton 1                                          ; 2st Button
	
	; ADICIONE MAIS ELEMENTOS VISUAIS AQUI ...
	; EM CASO DE NOVOS ELEMENTOS ENSIRA NOVOS REAJUSTES
ret
;_________________________________________________________________________


; Executa a chamada de Movimento da janela com sobreposições de pixels
;_________________________________________________________________________
NextStep:
	cmp byte[IsMovable], MOVABLE
	call WindowMoviment 
	jmp RetMovement

WindowMoviment:
	cmp byte[IsMovable], MOVABLE
	ja RetMovement
	jb WaitToEnd 
	LoopMoviment:
		call KEYBOARD_HANDLER
		cmp byte[fs:KEYCODE], K_F1
		je RetMovement
		call VerifyKey
		cmp al, 0
		je LoopMoviment
		cmp al, 2
		je RetMovement
		jmp LoopMoviment
WaitToEnd:
	call KEYBOARD_HANDLER
	cmp byte[fs:KEYCODE], K_F1
	jne WaitToEnd
RetMovement:
	ret
;_________________________________________________________________________


; Cálculos de reajustes dos elementos visuais
;_________________________________________________________________________
Resizing1:         ; Reajuste para sombra da janela
	add ax, 2
	add bx, 2
	add dx, 9
ret

Resizing2:         ; Reajuste para janela principal
	sub ax, 2
	sub bx, 2
	sub dx, 9
ret

Resizing3:         ; Reajuste para janela interior
	add ax, 3
	add bx, 12
	sub cx, 6
	sub dx, 6
ret

Resizing4:         ; Reajuste para janela do centro
	add ax, 6
	add bx, 6
	sub cx, 12
	sub dx, 12
ret

Resizing5:         ; Reajuste para 1ª campo de texto
	add ax, 6
	add bx, dx
	push ax
	xor ax, ax
	mov ax, bx
	xor bx, bx
	mov bx, 2
	xor dx, dx
	div bx
	mov bx, ax
	push cx
	xor ax, ax
	mov ax, word[PositionY]
	xor cx, cx
	mov cx, 2
	xor dx, dx
	div cx
	mov cx, ax
	sub cx, 4
	sub bx, 4
	add bx, cx
	pop cx
	pop ax
	sub cx, 12
ret

Resizing6:         ; Reajuste para 2ª campo de texto
	add bx, 12
ret

Resizing7:         ; Reajuste do 1ª botão
	push ax
	add ax, cx
	mov dx, ax
	push dx
	xor ax, ax
	mov ax, cx
	xor cx, cx
	xor dx, dx
	mov cx, 2
	div cx
	mov cx, ax
	sub cx, 6
	xor dx, dx
	pop dx
	pop ax
	add bx, 14
ret

Resizing8:         ; Reajuste do 2ª botão
	add ax, cx
	add ax, 12
	push ax
	add ax, cx
	cmp dx, ax
	ja Resize
	pop ax
	jmp RetResizing8
Resize:
	pop ax
	inc ax
RetResizing8:
	ret

; EM CASO DE NOVOS ELEMENTOS, 
; ADICIONE MAIS ROTINAS DE REAJUSTES AQUI ...
;_________________________________________________________________________


; Rotina que salva valores dos parâmetros: X, Y, W, H
;_________________________________________________________________________
SaveValues:
	cmp cx, MIN_WIDTH_SIZE
	jb ChangeWidth
Cond2:
	cmp dx, MIN_HEIGHT_SIZE
	jb ChangeHeight
	SaveNow:
		mov word[PositionX], ax
		mov word[PositionY], bx
		mov word[WidthWindow], cx
		mov word[HeightWindow], dx
		mov word[W_Width], cx
		mov word[W_Height], dx
		add word[WidthWindow], 3
		add word[HeightWindow], 12
		jmp RetSaveValues
	ChangeWidth:
		mov cx, 50
		jmp Cond2
	ChangeHeight:
		mov dx, 45
		jmp SaveNow
RetSaveValues:
	ret
;_________________________________________________________________________


; Rotinas de armazenamento de pixels na memória chamadas pelas Macros:
; SaveInMemory & GetInMemory. 
; Ambas as rotinas para sobreposição de pixels
;_________________________________________________________________________


; Captura e armazena pixels do fundo ou da janela atual
;_________________________________________________________________________
SaveColorWindow:
	mov ah, 0Dh
	mov cx, word[PositionX]
	mov dx, word[PositionY]
	call AddSize
	mov es, bx 
	xor bx, bx
	GetColor:
		int 10h
		mov byte[es:di + bx], al
		inc cx
		inc bx
		cmp cx, word[WidthWindow]
		jne GetColor
		mov cx, word[PositionX]
		inc dx
		cmp dx, word[HeightWindow]
		jne GetColor
ret

AddSize:
	cmp al, 1
	jne RetAdd
	add word[WidthWindow], cx
	add word[HeightWindow], dx
RetAdd:
	ret
;_________________________________________________________________________


; Apaga e redesenha janela com pixels salvos por SaveColorWindow
;_________________________________________________________________________
RepaintWindow:
	mov ah, 0Ch
	mov cx, word[PositionX]
	mov dx, word[PositionY]
	mov es, bx  
	xor bx, bx
	Repaint1:
		mov al, byte[es:di + bx]
		int 10h
		inc cx
		inc bx
		cmp cx, word[WidthWindow]
		jne Repaint1
		mov cx, word[PositionX]
		inc dx
		cmp dx, word[HeightWindow]
		jne Repaint1
ret


;_________________________________________________________________________


; Rotina de verificação de teclas
; Aqui é controlado as funcionalidades de movimentação e
; redimensionamento da janela através de teclas definidas
; ________________________________________________________________________
VerifyKey:
	cmp byte[fs:CursorFocus], 1
	je CursorIsFocus
	cmp byte[fs:KEYCODE], ARROW_RIGHT
	je IncRight
	cmp byte[fs:KEYCODE], ARROW_LEFT
	je DecLeft
	cmp byte[fs:KEYCODE], ARROW_DOWN
	je IncDown
	cmp byte[fs:KEYCODE], ARROW_UP
	je DecUp
	cmp byte[fs:KEYCODE], CTRL_D
	je ResizeRight
	cmp byte[fs:KEYCODE], CTRL_A
	je ResizeLeft
	cmp byte[fs:KEYCODE], CTRL_S
	je ResizeDown
	cmp byte[fs:KEYCODE], CTRL_W
	je ResizeUp
	cmp byte[fs:KEYCODE], CTRL_Z
	je ChangeToWall
	cmp byte[fs:KEYCODE], CTRL_X
	je ChangeToIron
	;cmp al, OUTRA_TECLA   -> Descomente para adicionar outras teclas
	;je AlgumaRotina          de controle para outra rotina
	mov al, 0
	jmp RetVerifyKey
CursorIsFocus:
	mov al, 0
ret
IncRight:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2  ;move 2 pixels
	call UpdatePosRight
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
DecLeft:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2   ;move 2 pixels
	call UpdatePosLeft
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
IncDown:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2  ;move 2 pixels
	call UpdatePosDown
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
DecUp:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2  ;move 2 pixels
	call UpdatePosUp
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
ResizeRight:
	GetInMemory ERASE, BACK
	inc word[W_Width]
	jmp ResizeWindow
ResizeLeft:
	GetInMemory ERASE, BACK
	dec word[W_Width]
	jmp ResizeWindow
ResizeDown:
	GetInMemory ERASE, BACK
	inc word[W_Height]
	jmp ResizeWindow
ResizeUp:
	GetInMemory ERASE, BACK
	dec word[W_Height]
	jmp ResizeWindow
ChangeToWall:
	mov al, 2
	mov cx, _WALL
ret
ChangeToIron:
	mov al, 2
	mov cx, _IRON
ret
; __________________________________________________________________________________
;
; ADICIONE AQUI OUTRAS ROTINAS DE FUNCIONALIDADE PELAS TECLAS...
; Exemplo -> AlgumaRotina:
;				Códigos...
;			 jmp RetVerifyKey
; __________________________________________________________________________________

RetVerifyKey:
	mov cx, word[PositionX]
	mov dx, word[PositionY]
ret

; Atualizador de posições do redirecionamento de teclas (TextFields) e
; do redesenho da janela durante a movimentação
; ________________________________________________________________________
UpdatePosRight: ;atualiza todas as posições para a direita
	add word[PositionX], ax
	add word[WidthWindow], ax
	add word[fs:POSITION_X], ax
	add word[fs:LIMIT_COLX], ax
	add word[fs:LIMIT_COLW], ax
	mov cl, 0
	xor bx,bx
UpdateR:
	add word[fs:POSITIONS + bx], ax 
	add bx, 4
	add word[fs:POSITIONS + bx], ax
	add bx, ax
	add word[fs:POSITIONS + bx], ax
	add bx, 6
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateR
ret

UpdatePosLeft:	;atualiza todas as posições para a esquerda
	sub word[PositionX], ax
	sub word[WidthWindow], ax
	sub word[fs:POSITION_X], ax
	sub word[fs:LIMIT_COLX], ax
	sub word[fs:LIMIT_COLW], ax
	mov cl, 0
	xor bx,bx
UpdateL:
	sub word[fs:POSITIONS + bx], ax 
	add bx, 4
	sub word[fs:POSITIONS + bx], ax
	add bx, ax
	sub word[fs:POSITIONS + bx], ax
	add bx, 6
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateL
ret

UpdatePosDown:		;atualiza todas as posições para baixo
	add word[PositionY], ax
	add word[HeightWindow], ax
	add word[fs:POSITION_Y], ax
	mov cl, 0
	xor bx,bx
	add bx, ax
UpdateD:
	add word[fs:POSITIONS + bx], ax
	add bx, 12 ;8
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateD
ret

UpdatePosUp:	;atualiza todas as posições para cima
	sub word[PositionY], ax
	sub word[HeightWindow], ax
	sub word[fs:POSITION_Y], ax
	mov cl, 0
	xor bx,bx
	add bx, ax
UpdateU:
	sub word[fs:POSITIONS + bx], ax
	add bx, 12 ;8
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateU
ret

Rewriter: ;analise
	call WriteESC
	xor bx, bx
LoopTab:
	push bx
	call WriteTAB
	call WriteChars
	pop bx
	inc bl
	cmp bl, byte[fs:QUANT_FIELD]
	jne LoopTab
	call WriteTAB
	call WriteESC
ret
WriteESC:
	mov al, K_ESC
	__FontsWriter KEY
WriteTAB:
	mov al, K_TAB
	__FontsWriter KEY
WriteChars:
	mov word[fs:QUANT_KEY], 0000h
	mov si, word[fs:C_ADDR]
	dec si
	GetChars:
		inc si
		mov al, byte[ds:si]
		cmp al, 0
		je RetWriteChars
		push si
		call WriteFont
		pop si
		jmp GetChars
WriteFont:
	__FontsWriter KEY
RetWriteChars:
	ret

; ________________________________________________________________________


; Rotina de redimensionamento de janela que captura valores
; pré-alterados pelas rotinas anteriores, Dependendo da tecla
; uma rotina diferente é executada, chamando como última a esta.
; __________________________________________________________________________________
ResizeWindow:
	mov byte[fs:QUANT_FIELD], 0
	mov byte[fs:CountField], -1
	mov word[fs:QuantPos], 0000h
	mov byte[fs:QuantTab], 0
	mov word[fs:CountPositions], 0000h
	mov byte[fs:StatusLimitW], 0
	mov byte[fs:StatusLimitX], 0
	mov byte[fs:CursorTab], 0
	Window3D MOVABLE+1, word[PositionX],word[PositionY],word[W_Width],word[W_Height]
	call Rewriter
	mov al, 0
ret
	
; __________________________________________________________________________________




; Referências de memória base para manipular e guardar 
; valores utilizados na movimentação e redimensionamento
; de janelas
; __________________________________________________________________________________

PositionX 	  dw 0000h
PositionY 	  dw 0000h
WidthWindow   dw 0000h
HeightWindow  dw 0000h
W_Width       dw 0000h
W_Height      dw 0000h
IsMovable     db 1
ValuePosition dw 0000h

; __________________________________________________________________________________


; Referências de memória para armazenar e manipular valores durante
; o processo de desenho dos papéis de parede
; __________________________________________________________________________________

obj_quantX     dw 0000h
obj_quantY     dw 0000h
CountWallX     dw 0000h
CountWallY     dw 0000h
LastBlockSaveX dw 0000h
LastBlockSaveY dw 0000h
StateObj       db 0
StateBlockX    db 0
StateBlockY    db 0

; __________________________________________________________________________________