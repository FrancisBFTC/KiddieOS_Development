; String.asm Library Jumps **************
%DEFINE os_string_copy		0000h
%DEFINE os_string_compare	0003h
%DEFINE os_string_join 		0006h
%DEFINE os_string_to_int 	0009h
%DEFINE os_int_to_string 	000Ch
%DEFINE os_string_uppercase 000Fh
%DEFINE os_string_lowercase 0012h
%DEFINE os_string_length	0015h
; ***************************************

; Math.asm Library Jumps ****************
%DEFINE os_bcd_to_int		0018h
%DEFINE os_get_random 		001Bh       ; Change offset someday
; ***************************************

; Screen.asm Library Jumps **************
%DEFINE os_print_string		001Eh
%DEFINE os_input_string 	0021h
%DEFINE os_print_newline 	0024h
%DEFINE os_print_1hex		0027h
%DEFINE os_print_2hex		002Ah
%DEFINE os_print_4hex		002Dh
%DEFINE os_move_cursor 		0030h
%DEFINE os_get_cursor_pos 	0033h
%DEFINE os_show_cursor		0036h
%DEFINE os_hide_cursor 		0039h
%DEFINE os_clear_screen 	003Ch
%DEFINE os_dialog_box 		003Fh
%DEFINE os_list_dialog 		0042h
%DEFINE os_file_selector 	0045h
; ***************************************

; Keyboard.asm Library Jumps **************
%DEFINE os_wait_for_key		0048h
%DEFINE os_check_for_key	004Bh
; ***************************************

; Disk.asm Library Jumps **************
%DEFINE os_get_file_list	004Eh
%DEFINE os_file_exists 		0051h
%DEFINE os_load_file		0054h
%DEFINE os_write_file 		0057h
%DEFINE os_rename_file 		005Ah
%DEFINE os_remove_file 		005Dh
%DEFINE os_get_file_size 	0060h
; ***************************************

; Misc.asm Library Jumps ****************
%DEFINE os_get_api_version	0063h
%DEFINE os_pause 			0066h
%DEFINE os_fatal_error 		0069h
; ***************************************

; ports.asm Library Jumps ***************
%DEFINE os_port_byte_out	006Ch
%DEFINE os_port_byte_in 	006Fh
%DEFINE os_serial_port_enable 0072h
%DEFINE os_send_via_serial 	0075h
%DEFINE os_get_via_serial 	0078h
; ***************************************

; ports.asm Library Jumps ***************
%DEFINE os_speaker_tone 	007Bh
%DEFINE os_speaker_off 		007Eh
; ***************************************