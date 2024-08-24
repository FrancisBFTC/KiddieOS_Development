%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG WINDOW]



pusha
	call DefineWindow
popa
	jmp Return
	
; =====================================
; Inclusion Files

%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"

; =====================================
	
DefineWindow:
	mov 	ax, 0xA000
	mov 	es, ax
	xor 	di, di
	mov 	ax, 800
	mov 	cx, word[fs:Window_PositionY]
	mul 	cx
	push 	ax
	mov 	ax, dx
	shl 	eax, 16
	pop 	ax
	mov 	cx, word[fs:Window_PositionX]
	mov 	edi, eax
	add 	edi, ecx
	xor 	eax, eax
	mov 	al, byte[fs:Window_Border_Color]
	mov 	dx, word[fs:Window_PositionY]
	cmp 	byte[fs:Window_Bar], 0
	je 		WindowNoBar
	jmp 	WindowWithBar
	
WindowNoBar:
	call BorderUpColor
	LineUp:
		mov 	cx, word[fs:Window_Width]
		rep 	stosb
		call 	BorderRightDown
		call 	BorderLeftColor
		mov 	cx, word[fs:Window_Height]
		inc 	di
	LineLeft:
		sub 	di, 800
		stosb
		dec 	di
		loop	LineLeft
		call 	BackColor
ret
		
WindowWithBar:
	push 	dx
	mov 	dx, 03C4h                     ; dx = Registro de Indice
	mov 	ah, byte[fs:Window_Bar_Color] ; Plano de cor "Window_Bar_Color"
	mov 	al, 0x02                      ; Indice = Map Mask 
	out 	dx, ax                        ; Escreve todos os planos de bits
	pop 	dx
	
	push 	cx
	mov 	cx, word[fs:Window_Width]
	shr 	cx, 2   ; Divide por 4
	xor 	ax, ax
	mov 	eax, 0xF0000000
	rep 	stosd
	pop 	cx
	
	jmp 	$
	
	add bx, cx
	push ax
	mov ax, dx
	add ax, 9
	mov [StateWindowBar], ax
	pop ax
	PaintBar:
		int 10h
		inc cx
		cmp cx, bx
		jne PaintBar
		int 10h
		inc dx
		inc al
		cmp dx, word[StateWindowBar]
		jne BackColumn
		mov al, byte[fs:Window_Border_Color]
		call BorderRightDown
		mov bx, word[fs:Window_PositionY]
		add bx, 8
		call BorderLeftColor
		LineLeftBar:
			int 10h
			dec dx
			cmp dx, bx
			jne LineLeftBar
			call BackColor
			call ButtonsBar
			jmp Return
	BackColumn:
		mov cx, word[fs:Window_PositionX]
		mov bx, word[fs:Window_Width]
		add bx, cx
		push bx
		mov bx, word[StateWindowBar]
		sub bx, 6
		cmp dx, bx
		ja IncColorAgain
		pop bx
		jmp PaintBar
	IncColorAgain:
		pop bx
		inc al
		jmp PaintBar
	
BorderRightDown:
		dec 	di
		mov 	cx, word[fs:Window_Height]
		call 	BorderRightColor
	LineRight:
		add 	di, 800
		stosb
		dec 	di
		loop	LineRight
		call 	BorderDownColor
	LineDown:
		std
		mov 	cx, word[fs:Window_Width]
		rep 	stosb
		cld
ret

BorderUpColor:
	cmp byte[fs:Window_Border], 1
	jne Return
	mov al, byte[fs:Window_Border_Up]
ret

BorderRightColor:
	cmp byte[fs:Window_Border], 1
	jne Return
	mov al, byte[fs:Window_Border_Right]
ret

BorderDownColor:
	cmp byte[fs:Window_Border], 1
	jne Return
	mov al, byte[fs:Window_Border_Down]
ret

BorderLeftColor:
	cmp byte[fs:Window_Border], 1
	jne Return
	mov al, byte[fs:Window_Border_Left]
ret

BackColor:
	mov 	al, byte[fs:Window_Back_Color]
	cmp 	byte[fs:Window_Bar], 1
	jne 	NoHaveBar
	add 	di, ((800*9)+1)
	jmp 	DrawBack
NoHaveBar:
	add 	di, (800+1)
	mov 	cx, word[fs:Window_Height]
	sub 	cx, 1
DrawBack:
	push 	cx
	mov 	cx, word[fs:Window_Width]       ;bx
	sub 	cx, 2
	push 	cx
	rep 	stosb
	pop 	cx
	sub 	di, cx
	pop 	cx
	add 	di, 800
	loop 	DrawBack
	jmp 	$
ret
	
ButtonsBar:
   mov bx, word[fs:Window_PositionX]
   mov word[SavePositionX], bx
   mov bx, word[fs:Window_PositionY]
   mov word[SavePositionY], bx
   mov bx, word[fs:Window_Width]
   mov word[SaveWidth], bx
   mov bx, word[fs:Window_Height]
   mov word[SaveHeight], bx
Button0:
	cmp byte[fs:ButtonClose], 1
	je Close
Button1:
	cmp byte[fs:ButtonMaximize], 1
	je Maximize
Button2:
	cmp byte[fs:ButtonMinimize], 1
	je Minimize
	jmp Return
Close:
	mov al, 42
	mov dx, 7
	call ButtonProperty
	call DefineWindow
	mov ah, 0Ch
	mov al, 30
	sub cx, 2
	sub dx, 2
	int 10h
	dec cx
	dec dx
	int 10h
	dec cx
	dec dx
	int 10h
	add cx, 2
	int 10h
	sub cx, 2
	add dx, 2
	int 10h
	jmp Button1
Maximize:
	mov al, 25
	mov dx, 15
	call ButtonProperty
	call DefineWindow
	mov ah, 0Ch
	mov al, 30
	sub cx, 2
	sub dx, 2
	int 10h
	dec cx
	int 10h
	dec cx
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	int 10h
	jmp Button2
Minimize:
	mov al, 25
	mov dx, 23
	call ButtonProperty
	call DefineWindow
	mov ah, 0Ch
	mov al, 30
	sub cx, 2
	sub dx, 2
	int 10h
	dec cx
	int 10h
	dec cx
	int 10h
    jmp Return

	
ButtonProperty:
	mov byte[fs:Window_Bar], 0
	mov byte[fs:Window_Border_Color], al
	mov byte[fs:Window_Back_Color], al
	mov byte[fs:Window_Border], 0
	mov ax, word[SavePositionX]
	mov cx, word[SaveWidth]
	add ax, cx
	sub ax, dx
	mov word[fs:Window_PositionX], ax
	mov ax, word[SavePositionY]
	add ax, 1
	mov word[fs:Window_PositionY], ax
	mov word[fs:Window_Width], 6
	mov word[fs:Window_Height], 6
ret
	
	
Return:
	ret