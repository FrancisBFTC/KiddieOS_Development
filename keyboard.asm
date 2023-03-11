%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG KEYBOARD]

jmp 	Keyboard_Initialize
jmp		Enable_Scancode
jmp 	Disable_Scancode
jmp 	Set_Default_Parameters
jmp 	Keyboard_Handler_Main
jmp 	Cursor_Handler_Alt

%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/iodevice.lib"
%INCLUDE "Hardware/fontswriter.lib"



Keyboard_Initialize:
	cli
	mov 	si, key_msg_init
	call 	Print_String
Self_Test:
	__WritePort KEYBOARD_COMMAND, 0xFF
Wait_ACK1:
	__ReadPort 	KEYBOARD_DATA
	cmp 	al, 0xAA		; Inicialização aprovada
	je 		Next_Commands	
	cmp 	al, 0xFA		; Inicialização aprovada
	je 		Next_Commands	
	cmp 	al, 0xFD 		; autotest reprovado
	je 		failed_selftest
	cmp 	al, 0xFC		; autotest reprovado
	je 		failed_selftest
	cmp 	al, RESEND
	je 		Self_Test
	jmp 	Wait_ACK1
Next_Commands:
	call 	Disable_Scancode
	call 	Identify_Keyboard
	call 	Enable_Scancode
EndInitialize:
	;sti
	ret
	
failed_selftest:
	mov 	si, error_failed_test
	call 	Print_String
ret

Enable_Scancode:
	__WritePort KEYBOARD_COMMAND, 0xF4
Wait_ACK2:
	__ReadPort 	KEYBOARD_DATA
	cmp 	al, RESEND
	je 		Enable_Scancode
	cmp 	al, ACK
	je 		End_Enable
	jmp 	Wait_ACK2
End_Enable:
	mov 	si, scancode_en
	call 	Print_String
	;sti
ret

Disable_Scancode:
	;cli
	__WritePort KEYBOARD_COMMAND, 0xF5
Wait_ACK3:
	__ReadPort 	KEYBOARD_DATA
	cmp 	al, RESEND
	je 		Disable_Scancode
	cmp 	al, ACK
	je	 	End_Disable
	jmp 	Wait_ACK3
End_Disable:
	mov 	si, scancode_dis
	call 	Print_String
	;sti
ret


Set_Default_Parameters:
	;cli
	__WritePort KEYBOARD_COMMAND, 0xF6
Wait_ACK4:
	__ReadPort 	KEYBOARD_DATA
	cmp 	al, RESEND
	je 		Set_Default_Parameters
	cmp 	al, ACK
	je	 	End_Default
	jmp 	Wait_ACK4
End_Default:
	mov 	si, default_params
	call 	Print_String
	;sti
ret


Wait_Buffer_Clear:
	__ReadPort 	KEYBOARD_STATUS
	and 	al, 0x02
	cmp 	al, 0x02
	je	 	Wait_Buffer_Clear
ret

Wait_Buffer_Set:
	__ReadPort 	KEYBOARD_STATUS
	and 	al, 0x02
	cmp 	al, 0x02
	jne	 	Wait_Buffer_Set
ret

Identify_Keyboard:
	;cli
	__WritePort KEYBOARD_COMMAND, 0xF2
Wait_ACK5:
	__ReadPort 	KEYBOARD_DATA
	cmp 	al, RESEND
	je 		Identify_Keyboard
	cmp 	al, ACK
	je	 	Start_Identify
	jmp 	Wait_ACK5
Start_Identify:
	mov 	cx, 1000
	Wait_Bytes:
		__ReadPort 	KEYBOARD_DATA
		cmp 	al, 0x00
		je 		Standard_PS2_Mouse
		cmp 	al, 0x03
		je 		Mouse_With_Scroll_Wheel
		cmp 	al, 0x04
		je 		Five_Button_Mouse
		cmp 	cx, 1000
		jne 	NoSaveAgain
		mov 	[Save1stByte], al
	NoSaveAgain:
		cmp 	cx, 1000
		jb 		Verify2nd
		jmp 	Return_Wait
	Verify2nd:
		cmp 	al, [Save1stByte]
		je 		Return_Wait
		jmp 	Scan_Vector_Types
	Return_Wait:
		loop 	Wait_Bytes
Scan_Vector_Types:
	mov 	cl, [Save1stByte]
	mov 	ch, al
	mov 	si, Table_Index
Get_ID_Keyboard:
	cmp 	[si], cx
	je 		Show_String_ID
	add 	si, 4
	jmp 	Get_ID_Keyboard
Standard_PS2_Mouse:
	mov 	si, standard_mouse
	call 	Print_String
	;sti
	ret
Mouse_With_Scroll_Wheel:
	mov 	si, mouse_scroll
	call 	Print_String
	;sti
	ret
Five_Button_Mouse:
	mov 	si, five_button
	call 	Print_String
	;sti
	ret
Show_String_ID:
	add 	si, 2
	mov 	si, [si]
	call 	Print_String
	;sti
ret
Save1stByte  db 0

Unknown_Error:
	mov 	si, unknown_err
	call 	Print_String
	call 	Print_Hexa_Value8
	call 	Break_Line
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
	
; 0xFF : Resetar teclado e iniciar autoteste
; 0xF4 : Ativar recepção de scan code
; 0xED 00 : Definir LED ScrollLock
; 0xED 01 : Definir LED NumberLock
; 0xED 02 : Definir LED CapsLock

BackColorCursor db 31,31,31,31,31,31,31,31
Function db 0
key_msg_init 	db "KEYBOARD: Initializing PS/2 keyboard...",0xA,0xD,0
scancode_en 	db "KEYBOARD: Scan Code reception enabled!",0xA,0xD,0
scancode_dis 	db "KEYBOARD: Scan Code reception disabled!",0xA,0xD,0
default_params	db "KEYBOARD: Default parameters set!",0xA,0xD,0
str_sc_set		db "KEYBOARD: The Scan code set is 0x",0
error_failed_test db "KEYBOARD => ERROR: Initialization and autotest failed!",0xA,0xD,0
unknown_err db "KEYBOARD => ERROR: Unknown Response => 0x",0

standard_mouse 	db "PS/2: Standard PS/2 mouse type!",0xA,0xD,0
mouse_scroll 	db "PS/2: Mouse with scroll wheel type!",0xA,0xD,0
five_button 	db "PS/2: Mouse with five button type!",0xA,0xD,0

Table_Index:
	dw 0xFAFA, Ancient_AT_keyboard		; Ancient AT keyboard
	dw 0xAB83, MF2_keyboard				; MF2 keyboard
	dw 0xAB41, MF2_keyboard				; MF2 keyboard
	dw 0xABC1, MF2_keyboard				; MF2 keyboard
	dw 0xAB84, IBM_Thinkpads			; IBM ThinkPads, Spacesaver keyboards, many other "short" keyboards
	dw 0xAB54, IBM_Thinkpads			; IBM ThinkPads, Spacesaver keyboards, many other "short" keyboards
	dw 0xAB85, NCD_N_97_keyboard		; NCD N-97 keyboard or 122-Key Host Connect(ed) Keyboard
	dw 0xAB86, x122_key_keyboards		; 122-key keyboards
	dw 0xAB90, Japanese_G_keyboards		; Japanese "G" keyboards
	dw 0xAB91, Japanese_P_keyboards		; Japanese "P" keyboards
	dw 0xAB92, Japanese_A_keyboards		; Japanese "A" keyboards
	dw 0xACA1, NCD_Sun_layout_keyboard	; NCD Sun layout keyboard
	
Ancient_AT_keyboard 	db "KEYBOARD: Ancient AT keyboard type.",0xA,0xD,0
MF2_keyboard			db "KEYBOARD: MF2 keyboard type.",0xA,0xD,0
IBM_Thinkpads			db "KEYBOARD: IBM ThinkPads, Spacesaver or other short keyboards type.",0xA,0xD,0
NCD_N_97_keyboard		db "KEYBOARD: NCD N-97 keyboard or 122-Key Host Connect(ed) type.",0xA,0xD,0
x122_key_keyboards 		db "KEYBOARD: 122-key keyboards type.",0xA,0xD,0
Japanese_G_keyboards	db "KEYBOARD: Japanese 'G' keyboards type.",0xA,0xD,0
Japanese_P_keyboards	db "KEYBOARD: Japanese 'P' keyboards type.",0xA,0xD,0
Japanese_A_keyboards	db "KEYBOARD: Japanese 'A' keyboards type.",0xA,0xD,0
NCD_Sun_layout_keyboard db "KEYBOARD: NCD Sun layout keyboard type.",0xA,0xD,0

END_OF_FILE:
	db 'EOF'
	