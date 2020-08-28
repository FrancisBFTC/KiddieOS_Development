%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG WINDOWS]



pusha
	call DefineWindow
popa
	jmp Return
	
; =====================================
; Inclusion Files

%INCLUDE "Hardware/win16.lib"

; =====================================
	
DefineWindow:
	mov ah, 0Ch
	mov al, byte[Window_Border_Color]
	mov cx, word[Window_PositionX]
	mov dx, word[Window_PositionY]
	cmp byte[Window_Bar], 0
	je WindowNoBar
	jmp WindowWithBar
	
WindowNoBar:
	mov bx, word[Window_Width]
	add bx, cx
	call BorderUp
	LineUp:
		int 10h
		inc cx
		cmp cx, bx
		jne LineUp
		call BorderRightDown
		mov bx, word[Window_PositionY]
		call BorderLeft
	LineLeft:
		int 10h
		dec dx
		cmp dx, bx
		jne LineLeft
		call BackColor
		jmp Return
		
WindowWithBar:
	mov al, byte[Window_Bar_Color]
	mov bx, word[Window_Width]
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
		mov al, byte[Window_Border_Color]
		call BorderRightDown
		mov bx, word[Window_PositionY]
		add bx, 8
		call BorderLeft
		LineLeftBar:
			int 10h
			dec dx
			cmp dx, bx
			jne LineLeftBar
			call BackColor
			call ButtonsBar
			jmp Return
	BackColumn:
		mov cx, word[Window_PositionX]
		mov bx, word[Window_Width]
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
		mov bx, word[Window_Height]
		add bx, dx
		call BorderRight
	LineRight:
		int 10h
		inc dx
		cmp dx, bx
		jne LineRight
		mov bx, word[Window_PositionX]
		call BorderDown
	LineDown:
		int 10h
		dec cx
		cmp cx, bx
		jne LineDown
ret

BorderUp:
	cmp byte[Window_Border], 1
	jne Return
	mov al, byte[Window_Border_Up]
ret

BorderRight:
	cmp byte[Window_Border], 1
	jne Return
	mov al, byte[Window_Border_Right]
ret

BorderDown:
	cmp byte[Window_Border], 1
	jne Return
	mov al, byte[Window_Border_Down]
ret

BorderLeft:
	cmp byte[Window_Border], 1
	jne Return
	mov al, byte[Window_Border_Left]
ret

BackColor:
	mov al, byte[Window_Back_Color]
	mov cx, word[Window_PositionX]
	mov dx, word[Window_PositionY]
	cmp byte[Window_Bar], 1
	je WithBar
	jmp NoBar
WithBar:
	add dx, 9
	mov word[BackInitialPositionY], dx
	add word[BackInitialPositionY], 1
	jmp Salt
NoBar:
	inc dx
	mov word[BackInitialPositionY], dx
Salt:
	inc cx
	mov word[BackInitialPositionX], cx
Initial:
	mov cx, word[BackInitialPositionX]
	mov bx, word[Window_Width]
	add bx, cx
	sub bx, 1
Columns:
	int 10h
	inc cx
	cmp cx, bx
	jne Columns
	mov bx, word[Window_Height]
	add bx, word[BackInitialPositionY]
	sub bx, 1
Rows:
	inc dx
	cmp dx, bx
	jne Initial
ret
	
ButtonsBar:
   mov bx, word[Window_PositionX]
   mov word[SavePositionX], bx
   mov bx, word[Window_PositionY]
   mov word[SavePositionY], bx
   mov bx, word[Window_Width]
   mov word[SaveWidth], bx
   mov bx, word[Window_Height]
   mov word[SaveHeight], bx
Button0:
	cmp byte[ButtonClose], 1
	je Close
Button1:
	cmp byte[ButtonMaximize], 1
	je Maximize
Button2:
	cmp byte[ButtonMinimize], 1
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
	mov byte[Window_Bar], 0
	mov byte[Window_Border_Color], al
	mov byte[Window_Back_Color], al
	mov byte[Window_Border], 0
	mov ax, word[SavePositionX]
	mov cx, word[SaveWidth]
	add ax, cx
	sub ax, dx
	mov word[Window_PositionX], ax
	mov ax, word[SavePositionY]
	add ax, 1
	mov word[Window_PositionY], ax
	mov word[Window_Width], 6
	mov word[Window_Height], 6
ret
	
	
Return:
	ret