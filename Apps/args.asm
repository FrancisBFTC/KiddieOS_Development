%INCLUDE "../KiddieOS/library/user32/kxe.inc"

MsgSuccess db "The argument is correct!",0
MsgError   db "The argument is wrong!",0
StrConv  times 10 db 0

Main(ARGC, ARGV)
	VINT32 Arg1 EQ [ARGV],1
	IF.EQUAL([Arg1], "-test", Success)
	
	NotSuccess:
		Printz(0x04, MsgError)
		jmp 	_END
		
	Success:
		Printz(0x02, MsgSuccess)
		jmp 	_END
		
.EndMain