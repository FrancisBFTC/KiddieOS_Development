; ------------------------------------------------------------------
; Machine code monitor -- by Yutaka Saito and Mike Saunders
;
; Accepts code in hex format, ORGed to 36864 (4K after where
; this program is loaded)
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768


	; This line determines where the machine code will
	; be generated -- if you change it, you will need to
	; ORG the code you enter at the new address

	CODELOC	equ 36864


	mov si, help_msg1		; Print help text
	call os_print_string

	mov si, help_msg2
	call os_print_string

main_loop:
	mov si, help_msg3		; Print quick instruction reference
	call os_print_string

	mov si, main_prompt		; Print prompt
	call os_print_string

	mov ax, input			; Get input
	mov bx, 255
	call os_input_string

	mov ax, input			; If empty, show prompt again
	call os_string_length
	cmp ax, 0
	je main_loop

	mov si, input			; Otherwise, let's check for commands
	cmp byte [si], 'i'
	je input_code

	cmp byte [si], 'x'
	je execute

	cmp byte [si], 'd'
	je dump_ram

	cmp byte [si], 'p'
	je poke_byte

	cmp byte [si], 'q'
	je quit

	jmp main_loop


input_code:
	call os_print_newline

	mov si, code_prompt		; Print prompt
	call os_print_string

	mov ax, input			; Get input
	mov bx, 255
	call os_input_string

	mov ax, input			; If empty, show prompt again
	call os_string_length
	cmp ax, 0
	je main_loop

	mov ax, input
	call os_string_uppercase	; Otherwise, convert any lowercase hex to uppercase...

	mov si, input			; ... and start converting to machine code...
	mov di, run

.more:
	cmp byte [si], '$'		; If char in string is '$', end of code
	je .done
	cmp byte [si], ' '		; If space, move on to next char
	je .space

	mov al, [si]			; Otherwise, convert hex
	and al, 0F0h
	cmp al, 40h
	je .H_A_to_F
.H_1_to_9:
	mov al, [si]
	sub al, 30h
	mov ah, al
	sal ah, 4
	jmp .H_end
.H_A_to_F:
	mov al, [si]
	sub al, 37h
	mov ah, al
	sal ah, 4
.H_end:
	inc si
	mov al, [si]
	and al, 0F0h
	cmp al, 40h
	je .L_A_to_F
.L_1_to_9:
	mov al, [si]
	sub al, 30h
	jmp .L_end
.L_A_to_F:
	mov al, [si]
	sub al, 37h
.L_end:
	or al, ah
	mov [di], al
	inc di
.space:
	inc si
	jmp .more
.done:
	mov byte [di], 0		; Write terminating zero

	mov si, run			; Copy machine code to location for execution
	mov di, CODELOC
	mov cx, 255
	cld
	rep movsb

	call os_print_newline
	jmp main_loop


execute:
	call os_print_newline

	call CODELOC			; Run program

	call os_print_newline

	jmp main_loop



dump_ram:
	call os_print_newline
	mov si, dump_msg1
	call os_print_string

	mov ax, buffer			; Get starting point of dump
	mov bx, 16
	call os_input_string

	mov si, buffer
	call os_string_to_int
	mov dx, ax			; Save starting point for later

	call os_print_newline
	mov si, dump_msg2
	call os_print_string

	mov ax, buffer			; Get number of bytes to show
	mov bx, 16
	call os_input_string

	mov si, buffer
	call os_string_to_int
	mov cx, ax			; Set the counter

	call os_print_newline

.loop:
	mov si, dx			; Starting point

	mov ax, 0			; Zero out the word
	lodsb

	call os_print_2hex		; ...and show it

	call os_print_space

	inc dx				; Move on to next byte

	dec cx				; Check out counter, and keep looping until zero
	cmp cx, 0
	jne .loop

	call os_print_newline
	jmp main_loop



poke_byte:
	call os_print_newline
	mov si, poke_msg1
	call os_print_string

	mov ax, buffer			; Get location in RAM
	mov bx, 16
	call os_input_string

	mov si, buffer
	call os_string_to_int

	mov di, ax

	call os_print_newline
	mov si, poke_msg2
	call os_print_string

	mov ax, buffer			; Get get value to be poked into the location
	mov bx, 16
	call os_input_string

	mov si, buffer
	call os_string_to_int

	mov byte [di], al

	call os_print_newline
	jmp main_loop



quit:
	call os_print_newline
	mov si, quit_msg
	call os_print_string
	ret


	input		times 255 db 0	; Code entered by user (in ASCII)
	run		times 255 db 0	; Translated machine code to execute

	buffer		times 16 db 0

	help_msg1	db 'MikeOS machine code tool', 10, 13, 0
	help_msg2	db '(See the User Handbook for a quick guide)', 10, 13, 0
	help_msg3	db 'Commands: i = input code, x = execute, d = dump RAM, p = poke byte, q = quit', 10, 13, 0
	help_msg4	db 'Enter instructions in hex, terminated by $ character:', 10, 13, 0
	dump_msg1	db 'Enter starting point in RAM (decimal): ', 0
	dump_msg2	db 'Enter number of bytes to show: ', 0
	poke_msg1	db 'Enter location in RAM (decimal): ', 0
	poke_msg2	db 'Enter value to poke into this location (decimal): ', 0
	quit_msg	db 'Quitting to MikeOS...', 10, 13, 0

	main_prompt	db '> ', 0
	code_prompt	db 'Code: ', 0


; ------------------------------------------------------------------

