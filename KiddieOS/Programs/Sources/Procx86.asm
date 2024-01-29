%INCLUDE "libasm.inc"

msg db "'Ola Como vao Galerinha do BOO?",0
i 	dd 1

Main(ARGC, ARGV)
	VINT32 Process EQ [ARGV],[i]
	Printz(0x0F, msg)
	Printz(0x02, [Process])
.EndMain