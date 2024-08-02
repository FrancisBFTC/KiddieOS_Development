; -----------------------------------------
;	Memory Mapping & Detection Driver
;			on Real Mode
;		 Created by Francis
; -----------------------------------------

%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
%INCLUDE "Hardware/iodevice.lib"

[BITS 	SYSTEM]
[ORG 	MEMX86]



Detect_Low_Memory:
	clc
	xor 	eax, eax		; Detectar padrão
	int 	0x12
	;mov 	ah, 88h			; Detectar extendido
	;int 	15h
	jc 		.Err_DLM
	
	; Reativar impressão quando implementar rolagem de tela
	; no modo protegido e implementar esses prints via INT 0xCE
	;push 	eax
	;mov 	si, msg_suc
	;call 	Print_String
	;mov 	si, msg_size1
	;call 	Print_String
	;pop 	eax
	;call 	Print_Dec_Value32
	;mov 	si, msg_size2
	;call 	Print_String
ret


.Err_DLM:
	mov 	si, msg_err
	call 	Print_String
ret


msg_err: db "MEM => ERROR: its not possible detect low memory!",0xA,0xD,0
msg_suc: db "MEM: Detecting conventional memory...",0xA,0xD,0
msg_size1: db "MEM: There are ",0
msg_size2: db "Kib free memory below 640 Kib (No BDA).",0xA,0xD,0

END_OF_FILE:
	db 'EOF'
