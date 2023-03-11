%INCLUDE "libasm.inc"

proc_id db "PROCESS: ",0
desc_bf db "The '",0
desc_af db "' is running on protected mode!",0
i 	dd 0

Main(ARGC, ARGV)
	VINT32 Process EQ [ARGV],[i]
	Printz(0x0F, proc_id)
	Printz(0x02, desc_bf)
	Printz(0x06, [Process])
	Printz(0x02, desc_af)

.EndMain