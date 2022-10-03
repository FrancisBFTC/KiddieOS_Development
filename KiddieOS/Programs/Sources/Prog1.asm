%INCLUDE "libasm.inc"

StrConv times 10 db 0
i 	    dd 0
Spaces  db " ",0
Str1    db "Quant. Argumentos : ",0
Str2    db 0x0D,"Arg ",0
HexBuf  dd "00000000",0
Str3    db ": ",0


Main(ARGC, ARGV)

	cli
	; ==============================================================
	; First Example
	
	INT.ToString([ARGC], StrConv)
	STR.Restore_Args1
	Printz(0x02, Str1)
	Printz(0x05, StrConv)
	
	mov 	ecx, [ARGC]
Show_Args:
	Printz(0x02, Str2)
	INT.ToString([i], StrConv)
	STR.Restore_Args1
	Printz(0x05, StrConv)
	Printz(0x02, Str3)
	VINT32 ArgAddr EQ [ARGV],[i]
	Printz(0x05, [ArgAddr])
	inc 	dword[i]
	dec 	ecx
	cmp 	ecx, 0
	jnz 	Show_Args
	
	
	; ==============================================================
	sti
	
.EndMain