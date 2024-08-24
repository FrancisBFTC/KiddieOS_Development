%INCLUDE "../Lib/KiddieOS/libasm.inc"

Vector  dd 20, 30, 40, 50	
StrConv times 10 db 0
i 	    dd 0
Spaces  db " ",0


Main(ARGC, ARGV)

	; ------------------------------------------------------
	; First Example
	mov 	eax, 0x14
	int 	0xCE
	
	Get_SubClass_Name(0, 13, 0)
	STRING MyDevice EQ RETURN(0)
	Printz(0x07, [MyDevice])
	
	mov 	eax, 0x15
	int 	0xCE
	; ------------------------------------------------------
	
	; ------------------------------------------------------
	; Second Example
	mov 	ecx, 4
Show_Vector:
	push 	ecx
	VINT32 	Var EQ Vector,[i]
	INT.ToString([Var], StrConv)        ; Convert INTEGER Value to TEXT
	STR.Restore_Args1                   ; POP arguments
	Printz	(0x02, StrConv)             ; Print converted value on Screen
	Printz	(0x00, Spaces)              ; Print Space
	inc 	dword[i]
	pop 	ecx
	loop 	Show_Vector
	; ------------------------------------------------------

.EndMain