; TEST CODE.EXE DOS PROGRAM

format 	MZ
entry 	code:main
stack 	512
	
segment code
	config:
		mov 	ax, data_seg
		mov 	ds, ax
		mov 	es, ax
	ret
	
	main:
		call 	config
		
		call 	get_argc
		mov 	[argc], eax
		call 	get_argv
		mov 	[argv], eax
		
		mov 	cx, 1
		mov 	dx, args
		call 	get_argvstr
		jc 		error_args
		
		mov 	bx, ax
		mov 	byte[args + bx], 0
		
		; TO TEST ARGUMENTS
		mov 	dx, args
		call 	open
		jc 		open_error
		mov 	[handler1], ax
		
		mov 	bx, [handler1]
		call 	get_file_size
		mov    [LENGTH_LOW], ax
		mov    [LENGTH_HIGH], dx

		mov 	bx, [handler1]
		mov 	cx, [LENGTH_LOW]
		call 	read
		jc 	 	read_error
		mov 	bx, [handler1]
		call 	close
		jc 		close_error
		mov 	dx, buffer_datas
		call 	print
		
		JMP 	exit
		
		; WAIT AND OPEN THE 1st FILE
		mov 	dx, string1
		call 	print
		mov 	dx, buffer1
		call 	input
		call 	breakl
		
		mov 	dx, buffer1 + 2
		call 	open
		jc 		open_error
		mov 	[handler1], ax
		
		mov 	dx, succes1
		call 	print
		
		; WAIT AND OPEN THE 2nd FILE
		mov 	dx, string2
		call 	print
		mov 	dx, buffer2
		call 	input
		call 	breakl
		
		mov 	dx, buffer2 + 2
		call 	open
		jc 		open_error
		mov 	[handler2], ax
		
		mov 	bx, [handler1]
		call 	seek
		jc 		seek_error
		
		mov 	bx, [handler2]
		call 	seek
		jc 		seek_error
		
		mov 	dx, succes2
		call 	print
	
	again:
		; READ AND PRINT THE 1st FILE
		mov 	bx, [handler1]
		call 	read
		jc 	 	read_error
		
		mov 	dx, data1
		call 	print
		mov 	dx, buffer_datas
		call 	print
		
		; READ AND PRINT THE 2nd FILE
		
		mov 	bx, [handler2]
		call 	read
		jc 	 	read_error
		
		mov 	dx, data2
		call 	print
		mov 	dx, buffer_datas
		call 	print
		
		mov 	ah, 0x07
		int 	21h
		cmp 	al, '0'
		jne 	again
		
		mov 	bx, [handler1]
		call 	close
		jc 		close_error
		
		mov 	bx, [handler2]
		call 	close
		jc 		close_error
		
		jmp 	exit
		
	open_error:
		xor 	dx, dx
		mov 	bx, ax
		shl 	bx, 1
		
		mov 	si, erroropenarray
		add 	si, bx
		mov 	bx, si
		mov 	dx, [si]
		call 	print
		jmp 	exit
		
	read_error:
		cmp 	ax, 05h
		jz 		Denied
		cmp 	ax, 06h
		jz 		Ilegal
		mov 	dx, failed
		call 	print
		jmp 	exit
	Denied:
		mov 	dx, denied_err
		call 	print
		jmp 	exit
	Ilegal:
		mov 	dx, ilegal_err
		call 	print
		jmp 	exit
		
	seek_error:
		cmp 	ax, 01h
		jz 		func_invalid
		cmp 	ax, 06h
		jz 		handler_invalid
		mov 	dx, failed
		call 	print
		jmp 	exit
	func_invalid:
		mov 	dx, seekerror1
		call 	print
		jmp 	exit
	handler_invalid:
		mov 	dx, seekerror2
		call 	print
		jmp 	exit
		
	close_error:
		mov 	dx, closeerror1
		call 	print
		jmp 	exit
		
	error_args:
		mov 	dx, errorargv
		call 	print
		jmp 	exit
		
		
	include		"user16.inc"
	
	exit:
		mov 	ax, 4C00h
		int 	21h
	
segment data_seg

	handler1 dw ?
	handler2 dw ?
	string1 db "type the 1st file: ",'$'
	string2 db "type the 2nd file: ",'$'
	data1 	db "1st DATA: ",'$'
	data2 	db "2nd DATA: ",'$'
	succes1 db "1st file opened successfully!",0x0D,0x0A,'$'
	succes2 db "2nd file opened successfully!",0x0D,0x0A,'$'
	failed db "failed to open the file!",0x0D,0x0A,'$'
	denied_err db "Denied access in read file!",0x0D,0x0A,'$'
	ilegal_err db "illegal handler or not open!",0x0D,0x0A,'$'
	seekerror1 db "SEEK ERROR: function invalid number!",0x0D,0x0A,'$'
	seekerror2 db "SEEK ERROR: invalid handler!",0x0D,0x0A,'$'
	closeerror1 db "CLOSE ERROR: invalid handler!",0x0D,0x0A,'$'
	errorargv db "ERROR: argv out of range!",0x0D,0x0A,'$'
	chck0 	db "0123456789ABCDEF$"
	mdg0 	db " $"
	
	buffer1 db 30,?, 30 dup(0)
	buffer2 db 30,?, 30 dup(0)
	buffer_datas: times 50 db 0
	argc 	dd 0
	argv 	dd 0
	args:	times 20 db 0
	LENGTH_LOW  dw 0
	LENGTH_HIGH dw 0
	
	
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
	; --------------------------------------------------------------------------------------------------