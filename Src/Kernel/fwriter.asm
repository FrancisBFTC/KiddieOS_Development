%INCLUDE "Hardware\memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG FWRITER]

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
	cmp al, K_CAPSLOCK  ;up
	je ChangeCapsLock   ;up
	cmp byte[fs:CursorFocus], 1
	jne Return
	cmp byte[fs:CursorTab], 1
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
	xor ah, ah
	xor dx, dx
	push ax
	call VerifyFontCase  ;Up
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
	
; _____________________________________
AsciiConversor: ;Up
	xor bx, bx
	mov bl, al
	mov al, byte[ds:di + bx]
ret

VerifyFontCase:  ;up
	mov si, FontLower
	mov di, LowerChars
	cmp byte[CapsLockStatus], 0
	jz ReturnCase
	mov si, FontUpper
	mov di, UpperChars
ReturnCase:
	ret
	
ChangeCapsLock:   ;up
	cmp byte[CapsLockStatus], 1
	je ChgCaps
	mov byte[CapsLockStatus], 1
ret
ChgCaps:
	mov byte[CapsLockStatus], 0
ret
; _____________________________________

ChangeCursor:
	call CURSOR_HANDLER
	cmp byte[fs:CursorFocus], 1
	je Change
	mov byte[fs:CursorFocus], 1
ret
Change:
	mov byte[fs:CursorFocus], 0
ret

TextPositions:
	cmp byte[fs:Window_Exist], 1
	jne Return
	cmp byte[fs:Field_Exist], 1
	jne Return
	call CURSOR_HANDLER
	inc byte[fs:QuantTab]
	mov bl, byte[fs:QuantTab]
	mov al, byte[fs:QUANT_FIELD]
	cmp bl, al
	jbe ProcPositions
	mov word[fs:QuantPos], 0000h
	mov byte[fs:QuantTab], 1
	mov byte[fs:CountField], -1
ProcPositions:
	xor ax, ax
	xor bx, bx
	mov bx, word[fs:QuantPos]
	mov ax, word[fs:POSITIONS + bx]
	mov word[fs:POSITION_X], ax
	add word[fs:QuantPos], 2
	mov bx, word[fs:QuantPos]
	mov ax, word[fs:POSITIONS + bx]
	add ax, 2
	mov word[fs:POSITION_Y], ax
	add word[fs:QuantPos], 2
	mov bx, word[fs:QuantPos]
	mov ax, word[fs:POSITIONS + bx]
	mov word[fs:LIMIT_COLW], ax
	add word[fs:QuantPos], 2
	mov bx, word[fs:QuantPos]
	mov ax, word[fs:POSITIONS + bx]
	mov word[fs:LIMIT_COLX], ax
	add word[fs:QuantPos], 2
	mov bx, word[fs:QuantPos]
	mov di, word[fs:POSITIONS + bx]
	mov ax, word[ds:di]
	mov word[fs:QUANT_KEY], ax
	add word[fs:QuantPos], 2
	mov bx, word[fs:QuantPos]
	mov ax, word[fs:POSITIONS + bx]
	mov word[fs:C_ADDR], ax
	add word[fs:QuantPos], 2
	inc byte[fs:CountField]
	xor ax, ax
	xor bx, bx
	mov byte[fs:CursorTab], 1
	jmp Return
	
PrintChar:
	push ax
	call CURSOR_HANDLER
	pop ax
	mov cx, word[fs:POSITION_X]
	mov dx, word[fs:POSITION_Y]
	call VerifyLimitColW
	cmp byte[fs:StatusLimitW], 1
	je RetPrintChar
	
	push ax
	xor dx, dx
	mov ax, 12
	mov cl, byte[fs:CountField]
	mul cl
	mov bx, ax
	mov cx, word[fs:POSITION_X]
	mov dx, word[fs:POSITION_Y]
	add cx, FONT_SIZE
	mov word[fs:POSITION_X], cx
	mov word[fs:POSITIONS + bx], cx
	add bx, 8
	
	pop ax
	push bx
	call AsciiConversor ;Up
	mov bx, word[fs:QUANT_KEY]
	mov di, word[fs:C_ADDR]
	mov byte[ds:di + bx], al
	inc word[fs:QUANT_KEY]
	mov ax, word[fs:QUANT_KEY]
	pop bx
	mov di, word[fs:POSITIONS + bx]
	mov word[ds:di], ax
	
	add word[fs:LIMIT_COLW], 4
	mov byte[ColorChars], 0
	call ConfigurePixel
	call PaintChar
	
RetPrintChar:
	ret
	
EraseChar:
	call CURSOR_HANDLER
	mov cx, word[fs:POSITION_X]
	mov dx, word[fs:POSITION_Y]
	call VerifyLimitColX
	cmp byte[fs:StatusLimitX], 1
	je RetEraseChar
	
	
	add word[fs:LIMIT_COLW], 4
	mov al, byte[fs:BS_COLOR]
	mov byte[ColorChars], al
	call ConfigurePixel
	call PaintChar
	
	xor dx, dx
	mov ax, 12
	mov cl, byte[fs:CountField]
	mul cl
	mov bx, ax
	mov cx, word[fs:POSITION_X]
	mov dx, word[fs:POSITION_Y]
	sub cx, FONT_SIZE
	mov word[fs:POSITION_X], cx
	mov word[fs:POSITIONS + bx], cx
	add bx, 8
	
	push bx
	dec word[fs:QUANT_KEY]
	mov bx, word[fs:QUANT_KEY]
	mov di, word[fs:C_ADDR]
	mov byte[ds:di + bx], CS_ERASE
	mov ax, word[fs:QUANT_KEY]
	pop bx
	mov di, word[fs:POSITIONS + bx]
	mov word[ds:di], ax
	
	
RetEraseChar:
	ret

VerifyLimitColW:
	cmp cx, word[fs:LIMIT_COLW]
	jb RetVerifyW
	mov byte[fs:StatusLimitW], 1
ret
RetVerifyW:
	mov byte[fs:StatusLimitW], 0
ret

VerifyLimitColX:
	cmp cx, word[fs:LIMIT_COLX]
	ja RetVerifyX
	mov byte[fs:StatusLimitX], 1
ret
RetVerifyX:
	mov byte[fs:StatusLimitX], 0
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
	cmp cx, word[fs:LIMIT_COLW]
	jae NonSetPixel
	int 10h
NonSetPixel:
	inc cx
	jmp Increment
PaintY:
	inc dx
	mov cx, word[fs:POSITION_X]
	jmp PaintChar
RetPaint:
	sub word[fs:LIMIT_COLW], 4
ret

Return:
	ret