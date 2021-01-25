%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG KEYBOARD]

jmp Keyboard_Initialize
jmp Keyboard_Handler_Main
jmp Cursor_Handler_Alt

%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/iodevice.lib"
%INCLUDE "Hardware/fontswriter.lib"

Keyboard_Initialize:
  mov si, DriverCommands
  dec si
WriteNext:
  xor cx, cx
  inc si
  mov bl, [si]
  cmp bl, '$'
  je EndInitialize
  WriteCommand:
      __WritePort KEYBOARD_STATUS, bl
      inc cx
    WaitResponse:
      __ReadPort KEYBOARD_DATA
      cmp cx, 3
      je WriteNext 
      cmp al, RESEND
      je WriteCommand
      cmp al, ACK
      je WriteNext
EndInitialize:
  ret
	
Keyboard_Handler_Main:
	__ReadPort KEYBOARD_DATA
	cmp al, byte[fs:KEYCODE]
	je TillPress
	mov WORD[CountKey], 0000h
VerifyKeys:
	mov byte[fs:KEYCODE], al
	cmp al, BEGIN_CHAR
	jnb Final
	jmp Return
Final:
	__FontsWriter KEY
	jmp Return
TillPress:
	cmp WORD[CountKey], 200
	je WaitTime
	inc WORD[CountKey]
	jmp Return
WaitTime:
	call DelayPress
	jmp VerifyKeys
Return:
	call CursorHandler
	call DelayIntervals
ret
	
DelayPress:
	mov ah, 86h
	mov cx, 0000h
	mov dx, 0C350h   ;50 milisegundos (50000)
	int 15h
ret

DelayIntervals:
	mov ah, 86h
	mov cx, 0000h
	mov dx, 1388h   ;5 milisegundos (5000)
	int 15h
ret


Cursor_Handler_Alt:
	mov byte[fs:CountCursor], CS_CHANGE-1
	mov byte[fs:StateCursor], CS_ERASE
	call CursorHandler
ret

CursorHandler:
	cmp byte[fs:CursorFocus], 1
	jne RetCursor
	cmp byte[fs:CursorTab], 1
	jne RetCursor
	inc byte[fs:CountCursor]
	cmp byte[fs:CountCursor], CS_CHANGE
	je ChgStCursor
	jmp RetCursor
ChgStCursor:
	cmp byte[fs:StateCursor], CS_PAINT
	je State0
	jmp State1
State0:
	mov byte[fs:StateCursor], CS_ERASE
	mov byte[fs:CountCursor], 0
	mov cx, word[fs:POSITION_X]
	cmp cx, word[fs:LIMIT_COLW]
	jae RetCursor
	mov byte[Function], CS_READ
	call ConfigCursor
	call SaveCursor
	mov byte[Function], CS_WRITE
	call ConfigCursor
	call PaintCursor
	jmp RetCursor
State1:
	mov byte[fs:StateCursor], CS_PAINT
	mov byte[fs:CountCursor], 0
	mov cx, word[fs:POSITION_X]
	cmp cx, word[fs:LIMIT_COLW]
	jae RetCursor
	mov byte[Function], CS_WRITE
	call ConfigCursor
	call EraseCursor
RetCursor:
	ret
	
ConfigCursor:
	mov cx, word[fs:POSITION_X]
	mov dx, word[fs:POSITION_Y]
	mov ah, byte[Function]
	mov al, 0
	add cx, FONT_SIZE
	dec dx
	mov bx, 7
	add bx, dx
	mov di, BackColorCursor
ret

SaveCursor:
	int 10h
	mov [di], al
	inc di
	inc dx
	cmp dx, bx
	jne SaveCursor
ret

PaintCursor:
	int 10h
	inc dx
	cmp dx, bx
	jne PaintCursor
ret

EraseCursor:
	mov al, [di]
	int 10h
	inc di
	inc dx
	cmp dx, bx
	jne EraseCursor
ret
	

BackColorCursor db 31,31,31,31,31,31,31,31
Function db 0
	