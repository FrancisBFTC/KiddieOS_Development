config_segment:
	mov 	ax, datas
	mov 	ds, ax
	mov 	es, ax
ret

store_psp_args:
	mov		ax,	ds
	mov		dx, [2Ch]
	mov		[psp_segment], ax
	mov		[environment_segment], dx
ret

print_logo:
	mov		dx, _logo
	call 	print
ret

print_usage:
	mov		dx, _usage
	call 	print
ret

print_memory:
	mov		dx, _memory_prefix
	call	print
	mov		ebx, [memory_end]
	sub		ebx, [memory_start]
	mov 	edi, num_str
	call	int_to_string
	mov 	dx, num_str
	call 	print
	mov		dx, _memory_suffix
	call	print
	call 	clear_num_buffer
ret

print_time:
	mov		ebx, [time_sec]
	mov 	edi, num_str
	call	int_to_string
	mov 	dx, num_str
	call 	print
	mov		ah,2
	mov		dl,'.'
	int		21h
	call 	clear_num_buffer
	mov		ebx, [time_mili]
	mov 	edi, num_str
	call	int_to_string
	mov 	dx, num_str
	call 	print
	mov		dx, _seconds_suffix
	call	print
	call 	clear_num_buffer
ret

clear_num_buffer:
	cld
	mov 	ecx, 20
	mov 	al, 24h
	mov 	edi, num_str
	rep		stosb
ret

get_seconds:
	mov		eax, [time_end]
	sub		eax, [time_start]
	xor 	edx, edx
	mov		ebx, 100
	mul		ebx
	mov		ebx, 182
	div		ebx
	xor		edx, edx
	mov		ebx, 10
	div		ebx
ret

; Inicializar memória alta XMS, não é necessário habilitar linha A20
; Pois o syscmng.osf já fez isto pra gente e já estamos no modo IREAL
init_memory:
	mov 	dword[memory_start], 0x200000
	mov 	dword[memory_end], 0x300000
ret

init_timer:
	call 	get_time 			; Get the current time
	mov 	[time_start], eax	; Store the beginning time
ret

finish_timer:
	call 	get_time 			; Get the final time
	mov 	[time_end], eax		; Store the final time
	
	call 	get_seconds			; Get the time seconds
	mov 	[time_sec], eax		; Integer part are the secs
	mov 	[time_mili], edx	; Decimal part are the ms
ret

exit_program:
	add 	sp, 2
	mov 	ax, 4C00h
	int 	21h
ret

get_files_path:
	mov 	bx, sp
	mov 	ax, [ss:bx]
	mov 	[ret_save], ax
	
	add 	sp, 2
	mov 	cx, 1
	mov 	dx, srcf
	call 	get_argvstr
	jc 		no_args_found
	sub 	sp, 2
	
	mov 	bx, ax
	mov 	[size_path], bx
	mov 	word[srcf + bx], 0x2400	; to debugging, only change 00 to 0A and uncomment line below
	;mov 	dx, srcf
	;call 	print
	
	add 	sp, 2
	mov 	cx, 2
	mov 	dx, desf
	call 	get_argvstr
	jc 		conv_exe_ext
	
	mov 	bx, ax
	mov 	word[desf + bx], 0x2400	; to debugging, only change 00 to 0A and uncomment line below
	;mov 	dx, srcf
	;call 	print
	jmp 	args_found
	
conv_exe_ext:
	cld
	mov 	cx, [size_path]
	mov 	si, srcf
	mov 	di, desf
	sub 	cx, 3
	rep 	movsb
	mov 	dword[di], "exe$"
	mov 	byte[di+3], 0			; to debugging, only change 0 to $ and uncomment line below
	;mov 	dx, srcf
	;call 	print
	jmp 	args_found
	
no_args_found:
	sub 	sp, 2
	mov 	ax, [ret_save]
	mov 	bx, sp
	mov 	[ss:bx], ax
	stc
	ret
args_found:
	sub 	sp, 2
	mov 	ax, [ret_save]
	mov 	bx, sp
	mov 	[ss:bx], ax
	clc
	ret