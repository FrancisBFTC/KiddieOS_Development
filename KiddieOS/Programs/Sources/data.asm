; This is an argument recognition program.

%INCLUDE "libasm.inc" 	; Includes KiddieOS macros and function structures

; STRINGS TO TERMINAL
MsgRead		db "Performing data reading...",0x0D,0
MsgWrite	db "Performing data writing...",0x0D,0
MsgConfig	db "Performing data configuration...",0x0D,0
MsgDebug	db "Performing data debugging...",0x0D,0
NoArgs 		db "No arguments were entered!",0

; VECTOR INDEX
i 			dd 0 	

; MAIN FUNCTION MACRO
Main(ARGC, ARGV)
	mov 	ecx, [ARGC]
	Args_Processing:
	
		VINT32 Args EQ [ARGV],[i]				; Read vector index of the ARGV
		IF.EQUAL([Args], "-read", DataReading)	; IF Args=="-read", Print Reading String
		IF.EQUAL([Args], "-write", DataWriting) ; IF Args=="-write", Print Writing String
		IF.EQUAL([Args], "-config", DataConfig) ; IF Args=="-config", Print Config String
		IF.EQUAL([Args], "-debug", DataDebug) 	; IF Args=="-debug", Print Debug String
		IF.EQUAL([Args], "data.kxe", NoArguments) ; IF Args=="data.kxe", Return to the loop
		
		NoArguments:
			cmp 	ecx, 1
			jne 	Loop_Return
			Printz(0x04, NoArgs)
			jmp 	Loop_Return
		DataReading:
			Printz(0x02, MsgRead)	; Print Reading String
			jmp 	Loop_Return
		DataWriting:
			Printz(0x03, MsgWrite)	; Print Writing String
			jmp 	Loop_Return
		DataConfig:
			Printz(0x05, MsgConfig)	; Print Config String
			jmp 	Loop_Return
		DataDebug:
			Printz(0x06, MsgDebug)	; Print Debug String
		
	Loop_Return:
		inc 	DWORD[i]
		dec 	ecx
		cmp 	ecx, 0
		jne 	Args_Processing
	
.EndMain