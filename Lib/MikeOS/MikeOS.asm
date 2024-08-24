; ----------------------------------------------------------
; MikeOS Compatible API Interface
;
; Author: Wenderson Francisco
; System: KiddieOS 16-bit
; Date: 08/08/2024
; ----------------------------------------------------------

[BITS 16]
[ORG 0000h]

API_NUMBER      EQU     0x22    ; MikeOS's Interruption Number

; String.asm Library Jumps **************
	jmp os_string_copy			; 0000h
	jmp os_string_compare		; 0003h
	jmp os_string_join 			; 0006h
	jmp os_string_to_int 		; 0009h
	jmp os_int_to_string 		; 000Ch
	jmp os_string_uppercase 	; 000Fh
	jmp os_string_lowercase 	; 0012h
	jmp os_string_length		; 0015h
; ***************************************

; Math.asm Library Jumps ****************
	jmp os_bcd_to_int			; 0018h
    jmp os_get_random 			; 001Bh
; ***************************************

; Screen.asm Library Jumps **************
	jmp os_print_string			; 001Eh
	jmp os_input_string 		; 0021h
	jmp os_print_newline 		; 0024h
	jmp os_print_1hex			; 0027h
	jmp os_print_2hex			; 002Ah
	jmp os_print_4hex			; 002Dh
	jmp os_move_cursor 			; 0030h
	jmp os_get_cursor_pos 		; 0033h
	jmp os_show_cursor			; 0036h
	jmp os_hide_cursor 			; 0039h
	jmp os_clear_screen 		; 003Ch
	jmp os_dialog_box 			; 003Fh
	jmp os_list_dialog 			; 0042h
	jmp os_file_selector 		; 0045h
; ***************************************

; Keyboard.asm Library Jumps **************
	jmp os_wait_for_key			; 0048h
	jmp os_check_for_key		; 004Bh
; ***************************************

; Disk.asm Library Jumps **************
	jmp os_get_file_list		; 004Eh
	jmp os_file_exists 			; 0051h
	jmp os_load_file			; 0054h
	jmp os_write_file 			; 0057h
	jmp os_rename_file 			; 005Ah
	jmp os_remove_file 			; 005Dh
	jmp os_get_file_size 		; 0060h
; ***************************************

; Misc.asm Library Jumps ****************
	jmp os_get_api_version		; 0063h
	jmp os_pause 				; 0066h
	jmp os_fatal_error 			; 0069h
; ***************************************

; ports.asm Library Jumps ***************
	jmp os_port_byte_out		; 006Ch
	jmp os_port_byte_in 		; 006Fh
	jmp os_serial_port_enable	; 0072h
	jmp os_send_via_serial 		; 0075h
	jmp os_get_via_serial 		; 0078h
; ***************************************

; ports.asm Library Jumps ***************
	jmp os_speaker_tone 		; 007Bh
	jmp os_speaker_off 			; 007Eh
; ***************************************

; ***************************************
; String Functions
os_string_copy:
    push    WORD 0
    jmp     library_handler
os_string_compare:
    push    WORD 1
    jmp     library_handler
os_string_join:
    push    WORD 2
    jmp     library_handler
os_string_to_int:
    push    WORD 3
    jmp     library_handler
os_int_to_string:
    push    WORD 4
    jmp     library_handler
os_string_uppercase:
    push    WORD 5
    jmp     library_handler
os_string_lowercase:
    push    WORD 6
    jmp     library_handler
os_string_length:
    push    WORD 7
    jmp     library_handler
; ***************************************

; ***************************************
; Math Functions
os_bcd_to_int:
    push    WORD 8
    jmp     library_handler
os_get_random:
    push    WORD 9
    jmp     library_handler
; ***************************************

; ***************************************
; Screen Text Functions
os_print_string:
    push    WORD 10
    jmp     library_handler
os_input_string:
    push    WORD 11
    jmp     library_handler
os_print_newline:
    push    WORD 12
    jmp     library_handler
os_print_1hex:
    push    WORD 13
    jmp     library_handler
os_print_2hex:
    push    WORD 14
    jmp     library_handler
os_print_4hex:
    push    WORD 15
    jmp     library_handler
os_move_cursor:
    push    WORD 16
    jmp     library_handler
os_get_cursor_pos:
    push    WORD 17
    jmp     library_handler
os_show_cursor:
    push    WORD 18
    jmp     library_handler
os_hide_cursor:
    push    WORD 19
    jmp     library_handler
os_clear_screen:
    push    WORD 20
    jmp     library_handler
; ***************************************

; ***************************************
; Screen GUI Functions
os_dialog_box:
    push    WORD 21
    jmp     library_handler
os_list_dialog:
    push    WORD 22
    jmp     library_handler
os_file_selector:
    push    WORD 23
    jmp     library_handler
; ***************************************

; ***************************************
; Keyboard Functions
os_wait_for_key:
    push    WORD 24
    jmp     library_handler
os_check_for_key:
    push    WORD 25
    jmp     library_handler
; ***************************************

; ***************************************
; Files Functions
os_get_file_list:
    push    WORD 26
    jmp     library_handler
os_file_exists:
    push    WORD 27
    jmp     library_handler
os_load_file:
    push    WORD 28
    jmp     library_handler
os_write_file:
    push    WORD 29
    jmp     library_handler
os_rename_file:
    push    WORD 30
    jmp     library_handler
os_remove_file:
    push    WORD 31
    jmp     library_handler
os_get_file_size:
    push    WORD 32
    jmp     library_handler
; ***************************************

; ***************************************
; Michelaneous Functions
os_get_api_version:
    push    WORD 33
    jmp     library_handler
os_pause:
    push    WORD 34
    jmp     library_handler
os_fatal_error:
    push    WORD 35
    jmp     library_handler
; ***************************************

; ***************************************
; I/O Serial Functions
os_port_byte_out:
    push    WORD 36
    jmp     library_handler
os_port_byte_in:
    push    WORD 37
    jmp     library_handler
os_serial_port_enable:
    push    WORD 38
    jmp     library_handler
os_send_via_serial:
    push    WORD 39
    jmp     library_handler
os_get_via_serial:
    push    WORD 40
    jmp     library_handler
; ***************************************

; ***************************************
; Sound Functions
os_speaker_tone:
    push    WORD 41
    jmp     library_handler
os_speaker_off:
    push    WORD 42
    jmp     library_handler
; ***************************************

library_handler:
    int     API_NUMBER
    pop     WORD[crash]
ret

crash dw 0

