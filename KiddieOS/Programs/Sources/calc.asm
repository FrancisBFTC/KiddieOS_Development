; ********************************************************
;			 CALCULATOR APPLICATION v1.0.0
;				  Created by Francis
;                   CALC.KXE FILE
;
; ********************************************************

; --------------------------------------------------------
; Necessaries inclusions
%INCLUDE "../../library/user32/kxe.inc"
%INCLUDE "../../library/user32/math.inc"
; --------------------------------------------------------

; --------------------------------------------------------
; Auxiliar strings & int variables
INT32 	i EQ 1
INT32 val EQ 0

CHAR resstr	EQ "Result = "
CHAR expstr	EQ "Expression = "
CHAR break 	EQ 0x0D

VINT result @ 20 EQ 0

; --------------------------------------------------------

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Main function macro
; IN:  ARGC = Arguments Counter
;      ARGV = Arguments Vector
; OUT: EAX  = Program return value (normally 0)
Main(ARGC, ARGV)
	VINT32 formula EQ [ARGV]@[i]
	
	mov 	esi, [formula]
	call 	expr_parse
	
	INT.ToString(eax, result)

PrintVal:
	Printz(0x0F, expstr)
	Printz(0x06, format_buffer)
	Printz(0x0F, break)
	Printz(0x0F, resstr)
	Printz(0x05, result)
.EndMain
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

