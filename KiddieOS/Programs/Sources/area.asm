%INCLUDE "../../library/user32/kxe.inc"

INT32 radius 	EQ 2.51
INT32 pi_value 	EQ 0
INT32 area 		EQ 0
CHAR  frstr 	EQ "formula: area = PI * r ^ 2 | r = "
VCHAR ftstr0 @ 5  EQ 0
VCHAR ftstr1 @ 30 EQ 0

format: 	db 0x0D, "circle area = ",0

Main(ARGC, ARGV)
	finit						; Initialize the FPU
	
	fldpi						; Load PI constant to FPU Stack ST0 (PUSH)
	fst 	dword [pi_value]	; Store from ST0 to pi_value (POP)
	
	fld 	dword [radius]		; Load radius to FPU Stack ST0 (PUSH)
	fmul 	dword [radius]		; and multiply by it-self in ST0 (r ^ 2)
  
	fmul 	dword [pi_value]	; multiply pi_value in ST0 (PI * r ^ 2)
	fstp 	dword [area]		; Store the result from ST0 to Area (POP)
	
	Printz(0x0F, frstr)			; print the "circle area" string
	
	; Print the radius value : 2 decimal places
	FLOAT.ToString(0, [radius],ftstr0, 2)
	Printz(0x05, ftstr0)
	
	; Format & Print 64-bit Float result : 2 decimal places
	Printz(0x0F, format)
	FLOAT.ToString(0, [area],ftstr1, 2)
	Printz(0x05, ftstr1)
	
	
.EndMain