%IFNDEF __DRIVERS_INC__
%DEFINE __DRIVERS_INC__

; -----------------------------------------------------------
; Begin drivers offset
%DEFINE DRIVERS_OFFSET	KEYBOARD
; -----------------------------------------------------------

; -----------------------------------------------------------
; Memory driver address
%DEFINE MEMX86.Detect_Low_Memory 		MEMX86+0
; -----------------------------------------------------------

; -----------------------------------------------------------
; Keyboard driver address
%DEFINE KEYBOARD.Initialize 			KEYBOARD+0
%DEFINE KEYBOARD.Enable_Scancode 		KEYBOARD+3
%DEFINE KEYBOARD.Disable_Scancode 		KEYBOARD+6
%DEFINE KEYBOARD.Set_Default_Parameters KEYBOARD+9
; -----------------------------------------------------------

; -----------------------------------------------------------
; PCI driver address
%DEFINE PCI.Init_PCI 	PCI
; -----------------------------------------------------------

%ENDIF