macro EXECUTABLE arg1 {
	db arg1
	db 0xCD,0x01,0x01,0x01,0x00
}

macro CALLS arg1 {
	dw 0xB000 + arg1
}

macro EXIT arg1 {
	dw 0xF000 + arg1
}

macro SYSCALLS arg1 {
	dw 0xD000 + arg1
}

macro RETURN {
	dw 0x5011
}

macro PRINT arg1 {
	dw 0x0001
	db arg1,0x0A,0
}