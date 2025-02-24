
; flat assembler interface for DOS
; Copyright (c) 1999-2021, Tomasz Grysztar.
; All rights reserved.

format	MZ
heap	0
stack	8000h
entry	system:_main

segment datas
	include 	'datas.inc'		; references, strings & constants

segment system use16
	include 	'user16.inc'	; DOS 16-bit commons user library
	include 	'funcs.inc'		; FASM commons functions

_main:
	call 	config_segment		; Configure data segment
	call 	print_logo			; Print initial fasm string
	
	call 	get_argc			; Get ARGS count number
	mov 	[argc], eax			; return the count
	call 	get_argv			; Get ARGS string vector
	mov 	[argv], eax			; return the pointer
		
	call 	get_files_path		; Get the args files path
	jc 		no_args
	
	; TODO: ** check the usage args options before **
	
	call 	init_memory			; Set the memory start & end
	call 	print_memory		; Show this memory size
	
	call 	init_timer			; Start the timer count
	
	; TODO: ** Assembling & formatting code functions **
	;mov 	ebx, 3000000		; Temp code to test the timer
	;call 	Delay_us
	
	call 	finish_timer		; Finish the timer count
	call 	print_time			; Print this runned time
	
	call 	exit_program		; End of the program
	
no_args:
	call 	print_usage			; Show the help params
	call 	exit_program		; End of the program
