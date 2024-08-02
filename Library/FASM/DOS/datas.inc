	include '..\version.inc'
	
	align 4
	_logo db 'flat assembler  version ',VERSION_STRING,24h
	_copyright db 'Copyright (c) 1999-2021, Tomasz Grysztar',0Dh,0Ah,0

	align 4
	_usage db 0Dh,0Ah
		db 'usage: fasm <source> [output]',0Dh,0Ah
		db 'optional settings:',0Dh,0Ah
		db ' -m <limit>         set the limit in kilobytes for the available memory',0Dh,0Ah
		db ' -p <limit>         set the maximum allowed number of passes',0Dh,0Ah
		db ' -d <name>=<value>  define symbolic variable',0Dh,0Ah
		db ' -s <file>          dump symbolic information for debugging',0Dh,0Ah
		db 24h
	   
	align 4
	_memory_prefix 	db '  (',24h
	_memory_suffix 	db ' bytes memory)',0Dh,0Ah,24h
	_passes_suffix 	db ' passes, ',24h
	_seconds_suffix db ' seconds, ',24h
	_bytes_suffix 	db ' bytes.',0Dh,0Ah,24h

	;no_32bit_dpmi 		db	'no 32-bit DPMI services are available',24h
	;str_proc_isnt_able 	db	'processor is not able to enter 32-bit real mode',24h
	;str_without_dpmi1 	db	'system is in protected mode without 32-bit DPMI services',24h
	;str_not_memory 		db 'not enough conventional memory',24h
	;str_required 		db	'required 80386 or better',24h
	;init_error_prefix 	db 0Dh,0Ah,'error: ',24h
	;init_error_suffix 	db '.',0Dh,0Ah,24h

	align 4
	error_prefix 		db 'error: ',0
	error_suffix 		db '.'
	cr_lf 				db 0Dh,0Ah,0
	line_number_start 	db ' [',0
	line_data_start 	db ':',0Dh,0Ah,0
	preprocessed_instruction_prefix db 'processed: ',0
	
	align 4
	Zero db 0
	VetorDec db "0123456789",0
	
	align 4
	psp_segment 		dw 	?			; not using
	environment_segment	dw  ?			; not using
	argc 				dd  ?			; For a while, using this
	argv 				dd  ?			; For a while, using this
	srcf:				times 50 db 0	; For a while, using this
	desf:				times 50 db 0	; For a while, using this
	num_str: 			times 20 db 24h
	buffer:				dw  ?			; reserve more space
	size_path 			dw 0
	ret_save 			dw 0
	memory_start		dd 0
	memory_end			dd 0
	time_start 			dd 0
	time_end 			dd 0
	time_sec 			dd 0
	time_mili			dd 0