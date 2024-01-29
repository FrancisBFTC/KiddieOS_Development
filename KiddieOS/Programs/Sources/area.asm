%INCLUDE "libasm.inc"

radius:		dq 2.51
pi_value: 	dq 0
area: 		dq 0
frstr:	 	db "formula: area = PI * r ^ 2 | r = ", 0
format: 	db 0x0D, "circle area = ",0
ftstr0: 	times 5 db 0
ftstr1: 	times 30 db 0

Main(ARGC, ARGV)
	finit						; Initialize the FPU
	
	fldpi						; Load PI constant to FPU Stack ST0 (PUSH)
	fst 	qword [pi_value]	; Store from ST0 to pi_value (POP)
	
	fld 	qword [radius]		; Load radius to FPU Stack ST0 (PUSH)
	fmul 	qword [radius]		; and multiply by it-self in ST0 (r ^ 2)
  
	fmul 	qword [pi_value]	; multiply pi_value in ST0 (PI * r ^ 2)
	fstp 	qword [area]		; Store the result from ST0 to Area (POP)
	
	Printz(0x0F, frstr)			; print the "circle area" string
	
	; Print the radius value
	FLOAT.ToString([radius],[radius+4], ftstr0, 2)
	Printz(0x05, ftstr0)
	
	; Format & Print 64-bit Float result
	Printz(0x0F, format)
	FLOAT.ToString([area],[area+4], ftstr1, 2)
	Printz(0x05, ftstr1)
	
	
.EndMain