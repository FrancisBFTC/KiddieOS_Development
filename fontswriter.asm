%INCLUDE "Hardware\memory.lib"
[BITS SYSTEM]
[ORG FONTSWRITER]

cmp bx, 1
je ProcChars
jmp Return

%INCLUDE "Hardware\keyboard.lib"
%INCLUDE "Hardware\fontswriter.lib"
%INCLUDE "Hardware\win16.lib"
%INCLUDE "Hardware\fonts.lib"

ProcChars:
	cmp al, K_TAB
	je TextPositions
	cmp al, K_ESC
	je ChangeCursor
	cmp byte[CursorFocus], 1
	jne Return
	cmp byte[CursorTab], 1
	jne Return
	cmp al, K_ENTER
	je Return
	cmp al, K_CTRLLEFT
	je Return
	cmp al, K_SHIFTLEFT
	je Return
	cmp al, K_SHIFTRIGHT
	je Return
	cmp al, K_ALTLEFT
	je Return
	cmp al, K_CAPSLOCK
	je Return
	xor ah, ah
	xor dx, dx
	push ax
	mov si, Chars
	xor bx, bx
	mov bx, 26   ;5 x 5 + 1
	mul bx
	sub ax, bx
	add si, ax
	xor bx, bx
	xor ax, ax
	mov bl, [si]
	pop ax
	cmp al, K_BACKSPACE
	je Erase
Show:
	call PrintChar
	jmp Return
Erase:
	call EraseChar
	jmp Return
	
ChangeCursor:
	;call CURSOR_HANDLER
	cmp byte[CursorFocus], 1
	je Change
	mov byte[CursorFocus], 1
	jmp Return
Change:
	mov byte[CursorFocus], 0
	jmp Return

TextPositions:
	cmp byte[Window_Exist], 1
	jne Return
	cmp byte[Field_Exist], 1
	jne Return
	;call CURSOR_HANDLER
	inc byte[QuantTab]
	mov bl, byte[QuantTab]
	mov al, byte[QUANT_FIELD]
	cmp bl, al
	jbe ProcPositions
	mov word[QuantPos], 0000h
	mov byte[QuantTab], 1
	mov byte[CountField], -1
ProcPositions:
	xor ax, ax
	xor bx, bx
	mov bx, word[QuantPos]
	mov ax, word[POSITIONS + bx]
	mov word[POSITION_X], ax
	add word[QuantPos], 2
	mov bx, word[QuantPos]
	mov ax, word[POSITIONS + bx]
	add ax, 2
	mov word[POSITION_Y], ax
	add word[QuantPos], 2
	mov bx, word[QuantPos]
	mov ax, word[POSITIONS + bx]
	mov word[LIMIT_COLW], ax
	add word[QuantPos], 2
	mov bx, word[QuantPos]
	mov ax, word[POSITIONS + bx]
	mov word[LIMIT_COLX], ax
	add word[QuantPos], 2
	mov bx, word[QuantPos]
	mov di, word[POSITIONS + bx]
	mov ax, word[ds:di]
	mov word[QUANT_KEY], ax
	add word[QuantPos], 2
	mov bx, word[QuantPos]
	mov ax, word[POSITIONS + bx]
	mov word[C_ADDR], ax
	add word[QuantPos], 2
	inc byte[CountField]
	xor ax, ax
	xor bx, bx
	mov byte[CursorTab], 1
	jmp Return
	
PrintChar:
	push ax
	;call CURSOR_HANDLER
	pop ax
	mov cx, word[POSITION_X]
	mov dx, word[POSITION_Y]
	call VerifyLimitColW
	cmp byte[StatusLimitW], 1
	je RetPrintChar
	
	push ax
	xor dx, dx
	mov ax, 12
	mov cl, byte[CountField]
	mul cl
	mov bx, ax
	mov cx, word[POSITION_X]
	mov dx, word[POSITION_Y]
	add cx, FONT_SIZE
	mov word[POSITION_X], cx
	mov word[POSITIONS + bx], cx
	add bx, 8
	
	pop ax
	push bx
	mov bx, word[QUANT_KEY]
	mov di, word[C_ADDR]
	mov byte[ds:di + bx], al
	inc word[QUANT_KEY]
	mov ax, word[QUANT_KEY]
	pop bx
	mov di, word[POSITIONS + bx]
	mov word[ds:di], ax
	
	add word[LIMIT_COLW], 4
	mov byte[ColorChars], 0
	call ConfigurePixel
	call PaintChar
	
RetPrintChar:
	ret
	
EraseChar:
	;call CURSOR_HANDLER
	mov cx, word[POSITION_X]
	mov dx, word[POSITION_Y]
	call VerifyLimitColX
	cmp byte[StatusLimitX], 1
	je RetEraseChar
	
	
	add word[LIMIT_COLW], 4
	mov al, byte[BS_COLOR]
	mov byte[ColorChars], al
	call ConfigurePixel
	call PaintChar
	
	xor dx, dx
	mov ax, 12
	mov cl, byte[CountField]
	mul cl
	mov bx, ax
	mov cx, word[POSITION_X]
	mov dx, word[POSITION_Y]
	sub cx, FONT_SIZE
	mov word[POSITION_X], cx
	mov word[POSITIONS + bx], cx
	add bx, 8
	
	push bx
	dec word[QUANT_KEY]
	mov bx, word[QUANT_KEY]
	mov di, word[C_ADDR]
	mov byte[ds:di + bx], CS_ERASE
	mov ax, word[QUANT_KEY]
	pop bx
	mov di, word[POSITIONS + bx]
	mov word[ds:di], ax
	
	
RetEraseChar:
	ret

VerifyLimitColW:
	cmp cx, word[LIMIT_COLW]
	jb RetVerifyW
	mov byte[StatusLimitW], 1
ret
RetVerifyW:
	mov byte[StatusLimitW], 0
ret

VerifyLimitColX:
	cmp cx, word[LIMIT_COLX]
	ja RetVerifyX
	mov byte[StatusLimitX], 1
ret
RetVerifyX:
	mov byte[StatusLimitX], 0
ret

ConfigurePixel:
	mov ah, 0Ch
	mov al, byte[ColorChars]
ret

PaintChar:
	mov bh, 0
Paint:
	mov bl, [si]
	cmp bl, '$'
	jne Continue
	jmp RetPaint
Continue:
	cmp bl, 1
	je PaintX
	inc cx
Increment:
	inc si
	inc bh
	cmp bh, FONT_SIZE
	je PaintY
	jmp Paint
PaintX:
	cmp cx, word[LIMIT_COLW]
	jae NonSetPixel
	int 10h
NonSetPixel:
	inc cx
	jmp Increment
PaintY:
	inc dx
	mov cx, word[POSITION_X]
	jmp PaintChar
RetPaint:
	sub word[LIMIT_COLW], 4
ret

Return:
	ret