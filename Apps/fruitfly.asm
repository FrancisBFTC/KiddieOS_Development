; ---------------------------------------------------------
; 
;		FruitFly Emulator v1.0.0 for KiddieOS	
;	  		Created by Alexandros De Regt	
;	 	   Reviewed by Wenderson Francisco
;
; ---------------------------------------------------------

FORMAT MZ
STACK 8000h
entry text:main 

segment text

main:
    ; set our right ds
    mov 	ax, datas
    mov 	ds, ax
	mov 	es, ax

	call 	get_argc
	mov 	[argc], eax
	cmp 	eax, 1
	jz 		enter_emulator
	
	mov 	cx, 1				; argv index
	mov 	dx, inputresult		; buffer to copy string
	call 	get_argvstr
	
	mov 	bx, ax
	mov 	byte[inputresult + bx], 0
	mov 	[inputcommandset + 1], bl
	
	jmp 	process_file
	
; INTERN EMULATOR
enter_emulator:
    ; greet our nice  users
    mov 	dx, welcome_message
    call 	print
	mov 	dx, moreinformation
	call 	print
	

command_line:
    ; ask for file
    mov 	dx, askforfilemessage
    call 	print 
    call 	readstring
    call 	trimstringforfile
    mov 	dx, newlinemessage
    call 	print

process_file:	
	call 	checkauxiliarcommands
	
    ; open file
	mov 	dx, inputresult
	call 	open
    jc 		error.open
	
	mov 	[filehandler], ax
  
	mov 	bx, [filehandler]
	call 	get_file_size
	
	; read file into buffer
	mov 	cx, ax
    mov 	bx, [filehandler] 
    call 	read
    jc 		error.read

    ; close the file
    mov 	bx, [filehandler]
	call 	close
    jc 		error


    mov 	word [program_counter], 0x0000
	
; enter the main loop to interpret the instructions
mainloop:
    ; store current instruction word from program counter
    mov 	cx , [program_counter]
    cmp 	cx, 0x0FFF
    je 		warningnoexit
    add 	cx, cx
    mov 	si, memorylane 
    add 	si, 8
    add 	si, cx 
    mov 	ax, [si]
    mov 	[current_instruction], ax
	
    ; store argument of the instruction word
    mov 	ax , [current_instruction]
    mov 	bx, 0x0FFF
    and 	ax, bx 
    mov 	[current_argument], ax
	
    ; store command/opcode of the instruction word
    mov 	ax , [current_instruction]
    mov 	bx, 0xF000
    and 	ax, bx 
    shr 	ax, 12
    mov 	word[current_opcode], ax

	; opcode checks
    ;cmp 	word[current_opcode], 0x0
    ;je 		command_nope

    ;cmp 	word[current_opcode], 0x1
    ;je 		command_jne

    ;cmp 	word[current_opcode], 0x2
    ;je 		command_jl

    ;cmp 	word[current_opcode], 0x3
    ;je 		command_jm

    ;cmp 	word[current_opcode], 0x4
    ;je 		command_je

    cmp 	word[current_opcode], 0x5
    je 		command_flags

    cmp 	word[current_opcode], 0x6
    je 		command_jump

    ;cmp 	word[current_opcode], 0x7
    ;je 		command_rb2a

    ;cmp 	word[current_opcode], 0x8
    ;je 		command_ra2a

    ;cmp 	word[current_opcode], 0x9
    ;je 		command_a2rb

    cmp 	word[current_opcode], 0xA
    je 		command_a2ra

    cmp 	word[current_opcode], 0xB
    je 		command_call

    cmp 	word[current_opcode], 0xC
    je 		command_v2ra

    cmp 	word[current_opcode], 0xD
    je 		command_syscall

    cmp 	word[current_opcode], 0xE
    je 		command_v2rb

    cmp 	word[current_opcode], 0xF
    je 		command_exit
    

    ; if we are here, we have a unknown instruction!
    mov 	dx, unknowninstruction
    call 	print
    mov 	ax, [current_opcode]
    call 	printhex
	mov 	dx, unknowninaddress
	call 	print
	mov 	ax, [program_counter]
	add 	ax, ax
    call 	printhex
    mov 	dx, newlinemessage
    call 	print
	mov 	dx, errormessage
    call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
    jmp 	command_line

; ***************************************************************
; INSTRUCTIONS EMULATION FUNCTIONS

; NOP COMMAND
; ---------------------------------------------------
command_nope:
    pusha
    
	call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
; ---------------------------------------------------

; JUMP IF NOT EQUAL
; ---------------------------------------------------
command_jne:
    pusha
    
	mov 	ax, [register_A]
    mov 	bx, [register_B]
    cmp 	ax, bx 
    jne 	.eeks
    
	call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
    
	.eeks:
		mov 	ax, [current_argument]
		mov 	[program_counter], ax
    
	popa 
    jmp 	mainloop
; ---------------------------------------------------

; JUMP IF BELOW
; ---------------------------------------------------
command_jl:
    pusha
	
    mov 	ax, [register_A]
    mov 	bx, [register_B]
    cmp 	ax, bx 
    jl 		.eeks
	
    call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
    
	.eeks:
		mov 	ax, [current_argument]
		mov 	[program_counter], ax
    
	popa 
    jmp 	mainloop
; ---------------------------------------------------

; JUMP IF ABOVE
; ---------------------------------------------------
command_jm:
    pusha
	
    mov 	ax, [register_A]
    mov 	bx, [register_B]
    cmp 	ax, bx 
    jg 		.eeks
    
	call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
    
	.eeks:
		mov 	ax, [current_argument]
		mov 	[program_counter], ax
    
	popa 
    jmp 	mainloop
; ---------------------------------------------------

; JUMP IF EQUAL
; ---------------------------------------------------
command_je:
    pusha
	
    mov 	ax, [register_A]
    mov 	bx, [register_B]
    cmp 	ax, bx 
    je 		.eeks
    
	call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
    
	.eeks:
		mov ax, [current_argument]
		mov [program_counter], ax
    
	popa 
    jmp 	mainloop
; ---------------------------------------------------

; FLAGS COMMAND
; ---------------------------------------------------
command_flags:
    pusha
    
	mov 	ax, [current_argument]
    cmp 	ax, 0x11
    je 		.command_flags_return
    jmp 	invalidflags
    
	.finosub:
		call 	inc_instructionpointer
    
	popa
	jmp mainloop

	.command_flags_return:
		; decrease jump stack index
		mov 	ax, [jump_stack_index]
		dec 	ax
		mov 	[jump_stack_index], ax
    
		; get the value 
		mov 	di,	jump_stack 
		add 	di, [jump_stack_index]
		add 	di, [jump_stack_index]
		mov 	ax, [di]
    
		; set the pc to the right value
		mov 	[program_counter], ax
    
		; clear the jump_stack value 
		mov word[di], 0x0000
		
	popa 
	jmp mainloop
; ---------------------------------------------------

; INCONDITIONAL JUMP
; ---------------------------------------------------
command_jump:
    pusha
    
	mov 	ax, [current_argument]
    mov 	[program_counter], ax
    
	popa 
    jmp mainloop
; ---------------------------------------------------

; REGISTER 'B' TO ADDRESS
; ---------------------------------------------------
command_rb2a:
    pusha
	
    mov 	ax, [register_B]
    mov 	si, memorylane
    add 	si, 8
    mov 	bx, [current_argument]
    add 	si, bx 
    mov 	[si], ax
    call 	inc_instructionpointer
	
    popa
    jmp 	mainloop
; ---------------------------------------------------

; REGISTER 'A' TO ADDRESS
; ---------------------------------------------------
command_ra2a:
    pusha
	
    mov 	ax, [register_A]
    mov 	si, memorylane
    add 	si, 8
    mov 	bx, [current_argument]
    add 	si, bx 
    mov 	[si], ax
    call 	inc_instructionpointer
	
    popa
    jmp 	mainloop
; ---------------------------------------------------

; ADDRESS TO REGISTER 'B'
; ---------------------------------------------------
command_a2rb:
    pusha
    
	mov 	si, memorylane
    add 	si, 8
    mov 	bx, [current_argument]
    add 	si, bx
	mov 	ax, [si]
	mov 	[register_B], ax
	call 	inc_instructionpointer
    
	popa
    jmp mainloop
; ---------------------------------------------------

; ADDRESS TO REGISTER 'A'
; ---------------------------------------------------
command_a2ra:
    pusha
    
	mov 	si, memorylane
    add 	si, 8
    mov 	bx, [current_argument]
    add 	si, bx
	mov 	ax, [si]
	mov 	[register_A], ax
	call inc_instructionpointer
    
	popa
    jmp mainloop
; ---------------------------------------------------

; COMMAND TO CALL SUB-ROUTINES
; ---------------------------------------------------
command_call:
    pusha

    ; push value to the call stack
    mov 	di, jump_stack 
    add 	di, [jump_stack_index]
    add 	di, [jump_stack_index]
    mov 	ax, [program_counter]
    inc 	ax 
    mov 	[di], ax

    ; increse callstack
    mov 	ax, [jump_stack_index]
    inc 	ax
    mov 	[jump_stack_index], ax

    ; do the actual call
    mov 	ax, [current_argument]
    mov 	[program_counter], ax
    
	popa 
    jmp mainloop
; ---------------------------------------------------

; VALUE TO REGISTER 'A'
; ---------------------------------------------------
command_v2ra:
    pusha
	
	mov 	ax, [current_argument]
	mov 	[register_A], ax
    call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
; ---------------------------------------------------

; COMMAND TO SYSCALLS (FUNCTIONS CALLS)
; ---------------------------------------------------
command_syscall:
    pusha
    
	mov 	ax, [current_argument]
    add 	ax, ax 
    mov 	si, memorylane
    add 	si, 8
    add 	si, ax 
    mov 	ax, 0
    mov 	ax, [si]
    cmp 	ax, 1
    je 		command_syscall_print
    jmp 	invalidsyscall
    
	.finosub:
		call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
; ---------------------------------------------------

; PRINT FUNCTION SYSCALL
; ---------------------------------------------------
command_syscall_print:
    mov 	ax, [current_argument]
    add 	ax, ax 
    mov 	si, memorylane
    add 	si, 8 ; basepath
    add		si, ax ; add currentargument
    add 	si, 2 ; grab the arguments after this
    
	push 	si 
    .again: 
		mov 	al, [si]
		inc 	si
		cmp 	al, 0
		jne 	.again 
		dec 	si
		mov 	byte[si], '$'
		pop 	si
		mov 	dx, si 
		call 	print
		mov 	dx, newlinemessage
		call 	print
		jmp 	command_syscall.finosub
; ---------------------------------------------------

; INVALID SYSCALL
; ---------------------------------------------------
invalidsyscall:
    mov 	dx, invalidsyscallstring
    call 	print 
    call 	printhex
    mov 	dx, newlinemessage
    call 	print
	mov 	dx, errormessage
    call 	print

	cmp 	byte[argc], 1
	ja 		exit
    jmp 	command_line 
; ---------------------------------------------------

; INVALID FLAGS
; ---------------------------------------------------
invalidflags:
    mov 	dx, invalidflagsstring
    call 	print 
    call 	printhex
    mov 	dx, newlinemessage
    call 	print
	mov 	dx, errormessage
    call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
    jmp 	command_line 
; ---------------------------------------------------

; VALUE TO REGISTER 'B'
; ---------------------------------------------------
command_v2rb:
    pusha
	
	mov		ax, [current_argument]
	mov 	[register_B], ax
    call 	inc_instructionpointer
    
	popa
    jmp 	mainloop
; ---------------------------------------------------

; EXIT OF THE SXE PROGRAM
; ---------------------------------------------------
command_exit:
    mov 	dx, normalprogramexitmessage
    call 	print
	mov 	ax, [current_argument]
	call 	printhex
	mov 	dx, newlinemessage
    call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
    jmp 	command_line
; ---------------------------------------------------

; INCREMENT PROGRAM COUNTER
; ---------------------------------------------------
inc_instructionpointer:
    pusha 
    
	mov 	cx, [program_counter]
    inc 	cx 
    mov 	[program_counter], cx
    
	popa 
    ret
; ---------------------------------------------------

; EXIT OF THE PROGRAM NO "EXIT COMMAND"
; ---------------------------------------------------
warningnoexit:
    mov 	dx, warningnoexitmessage
    call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
    jmp 	command_line 
    ret
; ---------------------------------------------------

; INSTRUCTIONS EMULATION FUNCTIONS END
; ***************************************************************	

; ERRORS TYPES
; ---------------------------------------------------	
error:
    mov 	dx, errormessage
    call 	print 
    jmp 	exit

.open:
	xor 	dx, dx
	mov 	bx, ax
	shl 	bx, 1
	
	mov 	si, erroropenarray
	add 	si, bx
	mov 	bx, si
	mov 	dx, [si]
	call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
	jmp 	command_line
	
.read:
	cmp 	ax, 01h
	jz 		.access
	
	mov 	dx, ilegalerr
	call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
	jmp 	command_line
.access:
	mov 	dx, deniederr
	call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
	jmp 	command_line
; ---------------------------------------------------	

; **********************************************************
; EMULATOR UTIL FUNCTIONS

include "../Lib/KiddieOS/User16.inc"

; ---------------------------------------------------
; EXITS PROGRAM
; IN:
;   - EXITCODE
; OUT:
;   - nothing
exit:
    mov 	ah, 0x4C
    mov 	al, 0
    int 	0x21
; ---------------------------------------------------

; ---------------------------------------------------
; CHECK EMULATOR COMMANDS
; IN:
;	- nothing
; OUT:
;	- nothing
checkauxiliarcommands:
	pusha
	
	;int3
	xor 	cx, cx
	mov 	si, emuvector.strs
	mov 	cx, [CMDSCOUNT]
	
	.checkcmds:
		push 	cx
		push 	si
		
		mov 	si, [si]
		mov 	di, inputresult
		mov 	cl, [inputcommandset + 1]
		rep 	cmpsb
		je 		.execcmds
		
		pop 	si
		pop 	cx
		add 	si, 2
		loop 	.checkcmds
	
	.returncheck:
		popa
		ret
	
	.execcmds:
		pop 	si
		pop 	cx
		mov 	bx, [CMDSCOUNT]
		sub 	bx, cx
		add 	bx, bx
		mov 	bx, [emuvector.cmds + bx]	
		jmp 	bx
; ---------------------------------------------------	
	
; ---------------------------------------------------
; EMULATOR COMMANDS
emu:

.EXIT:
	add 	sp, 16 + 2			; pusha + call
	mov 	dx, terminatedemulator
	call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
	jmp 	exit
	
.HELP:
	add 	sp, 16 + 2			; pusha + call
	mov 	dx, informationshelp
	call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
	jmp 	command_line
	
.VERSION:
	add 	sp, 16 + 2			; pusha + call
	mov 	dx, versionemulator
	call 	print
	
	cmp 	byte[argc], 1
	ja 		exit
	jmp 	command_line
; ---------------------------------------------------
	
; UTIL FUNCTIONS END	
; **********************************************************

segment datas
	
	define  	FFVERSION "v1.0.0"
	
	; ----------- INPUTS EMULATOR ----------------------------------------------------------------------
	INPUT_SIZE 	EQU 	20
	inputcommandset: db INPUT_SIZE, 0
	inputresult: times INPUT_SIZE db 0
				 db '$'
	; -------------------------------------------------------------------------------------------------- 
	
	; ----------- PROGRAM EMULATION STRINGS ------------------------------------------------------------
	welcome_message db "Fruitfly virtual machine for KiddieOS",0x0a
					db "Created by Alexandros de Regt, https://fruitfly.sanderslando.nl ",0x0a,'$'
	moreinformation db "type 'help' for more informations.",0x0a,'$'
					
	
	askforfilemessage 		db 0x0a,"FRUITFLY> ",'$'
	newlinemessage 			db 0x0a,'$'
	defaultfile 			db "A:\TEST.SXE",0
	normalprogramexitmessage	db "Program exits succesfully with code 0x",'$'
	errormessage 				db "Program exits with errors",0x0a,'$'
	invalidsyscallstring		db "ERROR: Unknown syscall 0x",'$'
	invalidflagsstring 			db "ERROR: Unknown flag 0x",'$'
	unknowninstruction 			db "FATAL: unknown instruction 0x",'$'
	unknowninaddress			db " in address 0x",'$'
	warningnoexitmessage 		db "WARNING: exit without EXIT",0x0a,'$'
	terminatedemulator 			db "Fruitfly emulator terminated by user!",0x0a,'$'
	informationshelp 			db "Below is a list of commands that can be used:",0x0a,0x0a
								db "version/--version: show emulator version.",0x0a
								db "help/--help: print this information.",0x0A
								db "exit: closes the emulator.",0x0a,0x0a
								db "<file>.sxe: run SXE program.",0x0a,'$'
	versionemulator				db "FruitFly Virtual Machine ",FFVERSION, 0x0a,'$'
	; --------------------------------------------------------------------------------------------------
	
	; ------------ AUXILIAR STRINGS TO FUNCTIONS -------------------------------------------------------
	;chck0 	db "0123456789ABCDEF$"
	;mdg0 	db " $"
	; --------------------------------------------------------------------------------------------------
	
	; ------------- FILE ERRORS HANDLING STRINGS -------------------------------------------------------
	erroropenarray 	dw 0xFFFF
					dw notablemsg
					dw fileerrmsg
					dw patherrmsg
					dw nohandlermsg
					dw deniedmsg
					times 6 dw 0
					dw notallowedmsg
				
	deniedmsg  	  db "Error: Access denied!",0x0D,0x0A,'$'
	nohandlermsg  db "Error: No handler available!",0x0D,0x0A,'$'
	patherrmsg 	  db "Error: path not found!",0x0D,0x0A,'$'
	fileerrmsg	  db "Error: file not found!",0x0D,0x0A,'$'
	notablemsg	  db "Error: sharing not enabled",0x0D,0x0A,'$'
	notallowedmsg db "Error: Access mode not allowed!",0x0D,0x0A,'$'
	
	deniederr db "Error: Denied access in read file!",0x0D,0x0A,'$'
	ilegalerr db "Error: illegal handler or not open!",0x0D,0x0A,'$'
	; --------------------------------------------------------------------------------------------------
	
	; --------------- EMULATOR AUXILIAR COMMANDS -------------------------------------------------------
	emuvector.strs:
				dw emu.exit
				dw emu.help
				dw emu.version
				dw emu.helpcli
				dw emu.versioncli
				; ADD MORE COMMANDS STRINGS ADDRESS HERE
	CMDSCOUNT 	dw ($ - emuvector.strs) / 2
	
	emuvector.cmds:
				dw emu.EXIT
				dw emu.HELP
				dw emu.VERSION
				dw emu.HELP
				dw emu.VERSION
				; ADD MORE COMMANDS FUNCTIONS ADDRESS HERE
				
	emu.exit	db "exit",0
	emu.help	db "help",0
	emu.version db "version",0
	emu.helpcli 	db "--help",0
	emu.versioncli 	db "--version",0
	
	; ADD MORE COMMANDS STRINGS HERE
	; --------------------------------------------------------------------------------------------------

	; --------------- FRUITFLY PROGRAM VARIABLES & BUFFERS ---------------------------------------------
	argc 				dd 0
	
	filehandler 		dw 0
	program_counter 	dw 0
	
	register_A 			dw 0
	register_B 			dw 0
	current_instruction dw 0
	current_argument 	dw 0
	current_opcode 		dw 0
	jump_stack_index 	dw 0
	stacker_index 		dw 0
	
	jump_stack:	times 10 dd 0
	stacker:	times 10 dd 0
	memorylane: times 8206 db 0
	; --------------------------------------------------------------------------------------------------