%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG KEYBOARD]

jmp Keyboard_Initialize
jmp Keyboard_Handler_Main

%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/iodevice.lib"

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
	cmp al, [KEYCODE]
	je TillPress
	mov word[CountKey], 0000h
VerifyKeys:
	mov byte[KEYCODE], al
	cmp al, BEGIN_CHAR
	jnb Final
	jmp Return
Final:
	cmp al, FINAL_CHAR
	jnbe Return
	mov ah, 0Eh
	int 10h
	jmp Return
TillPress:
	cmp WORD[CountKey], 200
	je WaitTime
	cmp WORD[CountKey], 210
	je VerifyKeys
	inc WORD[CountKey]
	jmp Return
WaitTime:
	mov WORD[CountKey], 210
	call DelayPress
	jmp VerifyKeys
Return:	
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