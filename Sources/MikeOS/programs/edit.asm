; ------------------------------------------------------------------
; MikeOS Text Editor
;
; Originally written by Mike Saunders
; Modifications added by Pablo González:
;  - Add support for more than screen-visible columns
;  - Show filename on top
;  - Show current line and column
;  - Add open-file option
;  - Remove unnecessary screen redrawing (which cause blinks)
; Modifications added by Mark Mellor:
;  - Add /n option (new file option from command line)
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768

start:
	call setup_screen

	cmp si, 0				; Were we passed a filename?
	je .no_param_passed

	call os_string_tokenize			; If so, get it from params

	mov di, switch_new			
	call os_string_compare			; look for /n
	jc new_file_from_switch
	
	mov di, filename			; Save file for later usage
	call os_string_copy

	mov ax, si
	mov cx, 36864
	call os_load_file			; Load the file 4K after the program start point
	jnc file_load_success

	mov ax, file_load_fail_msg		; If fail, show message and exit
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	call os_clear_screen
	ret					; Back to the OS


.no_param_passed:
	call os_file_selector			; Get filename to load
	jnc near file_chosen

	call os_clear_screen			; Quit if Esc pressed in file selector
	ret


file_chosen:
	mov si, ax				; Save it for later usage
	mov di, filename
	call os_string_copy


	; Now we need to make sure that the file extension is TXT or BAS...

	mov di, ax
	call os_string_length
	add di, ax

	dec di					; Make DI point to last char in filename
	dec di
	dec di

	mov si, txt_extension			; Check for .TXT extension
	mov cx, 3
	rep cmpsb
	je valid_extension

	dec di

	mov si, bas_extension			; Check for .BAS extension
	mov cx, 3
	rep cmpsb
	je valid_extension

	mov dx, 0
	mov ax, wrong_ext_msg
	mov bx, 0
	mov cx, 0
	call os_dialog_box

	mov si, 0
	jmp start



valid_extension:
	mov ax, filename
	mov cx, 36864				; Load the file 4K after the program start point
	call os_load_file

file_load_success:
	mov word [filesize], bx


	; Now BX contains the number of bytes in the file, so let's add
	; the load offset to get the last byte of the file in RAM

	add bx, 36864

	cmp bx, 36864
	jne .not_empty
	mov byte [bx], 10			; If the file is empty, insert a newline char to start with

	inc bx
	inc word [filesize]

.not_empty:
	mov word [last_byte], bx		; Store position of final data byte


	mov cx, 0				; Lines and columns to skip when rendering (scroll marker)
	mov word [skiplines], 0
	mov word [skipcols], 0

	mov byte [cursor_x], 0			; Initial cursor position will be start of text
	mov byte [cursor_y], 2			; The file starts being displayed on line 2 of the screen

	call setup_screen


	; Now we need to display the text on the screen; the following loop is called
	; whenever the screen scrolls, but not just when the cursor is moved

render_text:
	call clean_text_entry

	mov dh, 2						; Move cursor to near top
	mov dl, 0
	call os_move_cursor


	mov si, 36864				; Point to start of text data
	mov ah, 0Eh				; BIOS char printing routine


	mov word cx, [skiplines]		; We're now going to skip lines depending on scroll level

redraw_lines:
	cmp cx, 0				; Do we have any lines to skip?
	je lines_ok				; If not, start the displaying
	dec cx					; Otherwise work through the lines

.skip_loop:
	lodsb					; Read bytes until newline, to skip a line
	cmp al, 10
	jne .skip_loop				; Move on to next line
	jmp redraw_lines

lines_ok:
	mov word cx, [skipcols]	; We're going to skip columns before we write the text

	cmp cx, 0				; Do we have columns to skip?
	je .display_loop		; If not, we'll display the text 'normally'

.start_skipping:			; Otherwise we'll start skipping columns
	mov di, 0 				; DI indicates if we have reached a new line character

.skip_loop:					; Now we're going to skip the columns
	lodsb					; Get character from file data

	cmp al, 10				; Did we reach a new line character?
	je .end_of_line			; If yes, we don't have more characters to write, go to next line

	loop .skip_loop			; Otherwise continue skipping

	jmp .display_loop		; We've finished. Now we'll display the remaining text 'normally'

.end_of_line:
	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor		; Go back to the line start

	mov di, 1 				; DI = 1: We found a new line character

	jmp skip_return 		; Print the character - It'll move the cursor to the next line

.display_loop: 				; Display the text 'normally'
	lodsb

	cmp al, 10 				; Do we reached a new line character?
	jne skip_return 		; If not, display it

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor 	; Otherwise go back to the line start

	mov di, 1 				; DI indicates we found it

skip_return:
	call os_get_cursor_pos			; Don't wrap lines on screen
	cmp dl, 79
	je .no_print

	int 10h					; Print the character via the BIOS

.no_print:
	mov word bx, [last_byte]
	cmp si, bx				; Have we printed all characters in the file?
	je near get_input

	call os_get_cursor_pos			; Are we at the bottom of the display area?
	cmp dh, 23
	je get_input				; Wait for keypress if so

	cmp di, 1 					; Do we write a new line character
	je lines_ok					; If yes, go to next line, skipping columns if it's necessary 

	jmp lines_ok.display_loop	; If not, continue displaying the current line

	; When we get here, now we've displayed the text on the screen, and it's time
	; to put the cursor at the position set by the user (not where it has been
	; positioned after the text rendering), and get input

get_input:
;	call showbytepos			; USE FOR DEBUGGING (SHOWS CURSOR INFO AT TOP-RIGHT)
	call showlinecolpos 		; Show current line and column in the file


	mov byte dl, [cursor_x]			; Move cursor to user-set position
	mov byte dh, [cursor_y]
	call os_move_cursor

	call os_wait_for_key			; Get input

	cmp ah, KEY_UP				; Cursor key pressed?
	je near go_up
	cmp ah, KEY_DOWN
	je near go_down
	cmp ah, KEY_LEFT
	je near go_left
	cmp ah, KEY_RIGHT
	je near go_right

	cmp al, KEY_ESC				; Quit if Esc pressed
	je close

	jmp text_entry				; Otherwise it was probably a text entry char


; ------------------------------------------------------------------
; Move cursor left on the screen, and backward in data bytes

go_left:
	cmp byte [cursor_x], 0			; Are we at the start of a line?
	je .check_skipped_cols
	dec byte [cursor_x]			; If not, move cursor and data position
	dec word [cursor_byte]
	jmp get_input

.check_skipped_cols:
	cmp word [skipcols], 0		; Can we un-skip columns?
	jne .previous_col			; If yes, do it

	jmp get_input 				; Otherwise get another input

.previous_col:
	dec word [skipcols]
	dec word [cursor_byte] 		; We descended one byte and one column

	jmp render_text

; ------------------------------------------------------------------
; Move cursor right on the screen, and forward in data bytes

go_right:
	pusha

	cmp byte [cursor_x], 79			; Far right of display?
	je .next_col			; Don't do anything if so

	mov word ax, [cursor_byte]
	mov si, 36864
	add si, ax				; Now SI points to the char under the cursor

	inc si

	cmp word si, [last_byte]		; Can't move right if we're at the last byte of data
	je .nothing_to_do

	dec si

	cmp byte [si], 0Ah			; Can't move right if we are on a newline character
	je .nothing_to_do

	inc word [cursor_byte]			; Move data byte position and cursor location forwards
	inc byte [cursor_x]

.nothing_to_do:
	popa
	jmp get_input

.next_col:
	mov word ax, [cursor_byte]
	mov si, 36864
	add si, ax

	inc si

	cmp word si, [cursor_byte]		; Are we in the end of the file?
	je .nothing_to_do				; If so, don't do anything

	dec si

	cmp byte [si], 10
	je .nothing_to_do 				; If the next character is a new line, don't move

	inc word [skipcols]
	inc word [cursor_byte] 			; Increment our position

	popa
	jmp render_text

; ------------------------------------------------------------------
; Move cursor down on the screen, and forward in data bytes

go_down:
	; First up, let's work out which character in the RAM file data
	; the cursor will point to when we try to move down

	pusha

	mov word cx, [cursor_byte]
	mov si, 36864
	add si, cx				; Now SI points to the char under the cursor

.loop:
	inc si
	cmp word si, [last_byte]		; Is it pointing to the last byte in the data?
	je .do_nothing				; Quit out if so

	dec si

	lodsb					; Otherwise grab a character from the data
	inc cx					; Move our position along
	cmp al, 0Ah				; Look for newline char
	jne .loop				; Keep trying until we find a newline char

	mov word [cursor_byte], cx

.nowhere_to_go:
	popa

	cmp byte [cursor_y], 22			; If down pressed and cursor at bottom, scroll view down
	je .scroll_file_down
	inc byte [cursor_y]			; If down pressed elsewhere, just move the cursor
	mov byte [cursor_x], 0			; And go to first column in next line

	cmp word [skipcols], 0			; Do we have skipped columns?
	jne .scroll_file_left			; If so, reset 'skipcols' and redraw the screen

	cmp byte [force_render], 0		; Do we need to render the text again?
	jne .render_text_forced 		; If so, do it

	jmp get_input 					; Otherwise, just continue

.scroll_file_left:
	mov word [skipcols], 0
	jmp render_text

.scroll_file_down:
	inc word [skiplines]			; Increment the lines we need to skip
	mov byte [cursor_x], 0			; And go to first column in next line
	jmp render_text				; Redraw the whole lot


.do_nothing:
	popa
.render_text_forced:
	mov byte [force_render], 0 		; Reset force_render
	jmp render_text


; ------------------------------------------------------------------
; Move cursor up on the screen, and backward in data bytes

go_up:
	pusha

	mov word cx, [cursor_byte]
	mov si, 36864
	add si, cx				; Now SI points to the char under the cursor

	cmp si, 36864				; Do nothing if we're already at the start of the file
	je .start_of_file

	mov byte al, [si]			; Is the cursor already on a newline character?
	cmp al, 0Ah
	je .starting_on_newline

	jmp .full_monty				; If not, go back two newline chars


.starting_on_newline:
	cmp si, 36865
	je .start_of_file

	cmp byte [si-1], 0Ah			; Is the char before this one a newline char?
	je .another_newline_before
	dec si
	dec cx
	jmp .full_monty


.another_newline_before:			; And the one before that a newline char?
	cmp byte [si-2], 0Ah
	jne .go_to_start_of_line

	; If so, it means that the user pressed up on a newline char with another newline
	; char above, so we just want to move back to that one, and do nothing else

	dec word [cursor_byte]
	jmp .display_move



.go_to_start_of_line:
	dec si
	dec cx
	cmp si, 36864
	je .start_of_file
	dec si
	dec cx
	cmp si, 36864				; Do nothing if we're already at the start of the file
	je .start_of_file
	jmp .loop2



.full_monty:
	cmp si, 36864
	je .start_of_file

	mov byte al, [si]
	cmp al, 0Ah				; Look for newline char
	je .found_newline
	dec cx
	dec si
	jmp .full_monty


.found_newline:
	dec si
	dec cx

.loop2:
	cmp si, 36864
	je .start_of_file

	mov byte al, [si]
	cmp al, 0Ah				; Look for newline char
	je .found_done
	dec cx
	dec si
	jmp .loop2


.found_done:
	inc cx
	mov word [cursor_byte], cx
	jmp .display_move


.start_of_file:
	mov word [cursor_byte], 0
	mov byte [cursor_x], 0
	mov word [skipcols], 0


.display_move:
	popa
	cmp byte [cursor_y], 2			; If up pressed and cursor at top, scroll view up
	je .scroll_file_up
	dec byte [cursor_y]			; If up pressed elsewhere, just move the cursor
	mov byte [cursor_x], 0			; And go to first column in previous line

	cmp word [skipcols], 0
	jne .scroll_file_left			; If we skipped some columns, reset them and redraw the screen

	cmp byte [force_render], 1		; Do we have to render?
	je .render_forced 				; If so, do it

	jmp get_input 					; Otherwise just move the cursor

.render_forced:
	mov word [force_render], 0
	jmp render_text

.scroll_file_left:
	mov word [skipcols], 0 			; Redraw the screen (we've set 'skipcols' to zero)
	jmp render_text

.scroll_file_up:
	cmp word [skiplines], 0			; Don't scroll view up if we're at the top
	jle get_input
	dec word [skiplines]			; Otherwise decrement the lines we need to skip
	jmp render_text


; ------------------------------------------------------------------
; When an key (other than cursor keys or Esc) is pressed...

text_entry:
	pusha

	cmp ax, 3B00h				; F1 pressed?
	je near .f1_pressed

	cmp ax, 3C00h				; F2 pressed?
	je near save_file

	cmp ax, 3D00h				; F3 pressed?
	je near new_file

	cmp ax, 3E00h				; F4 pressed?
	je near open_file

	cmp ax, 3F00h				; F5 pressed?
	je near .f5_pressed

	cmp ax, 4200h				; F8 pressed?
	je near .f8_pressed

	cmp ah, 53h				; Delete?
	je near .delete_pressed

	cmp al, 8
	je near .backspace_pressed

	cmp al, KEY_ENTER
	je near .enter_pressed

	cmp al, 32				; Only deal with displayable chars
	jl near .nothing_to_do

	cmp al, 126
	je near .nothing_to_do

	cmp word [filesize], 28672	; Do we reached the filesize limit?
	je .no_more 				; If so, don't allow more writing

	jmp .more					; Otherwise, allow more text

.no_more:
	mov ax, no_more_msg1
	mov bx, no_more_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box 			; Tell the user the filesize limit has been reached

	call setup_screen

	jmp render_text

.more:
	push ax

	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov si, 36864
	add si, cx				; Now SI points to the char under the cursor

	pop ax

	mov byte [si], al
	inc word [cursor_byte]

	call os_get_cursor_pos
	cmp dl, 78
	jg near .next_col 			; If we are at the end of the screen, skip columns

	inc byte [cursor_x]

.nothing_to_do:
	popa
	jmp render_text

.next_col:
	inc word [skipcols]

	jmp .nothing_to_do

.delete_pressed:
	mov si, 36865
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .nothing_to_do

	cmp byte [si], 0Ah
	jl .at_final_char_in_line

.one_backward:
	call move_all_chars_backward
	popa
	jmp render_text

.at_final_char_in_line:
	call move_all_chars_backward		; Char and newline character too
	call move_all_chars_backward		; Char and newline character too
	popa
	jmp render_text

.backspace_pressed:
	cmp word [cursor_byte], 0
	je .nothing_to_do

	cmp byte [cursor_x], 0
	je .check_cols

	dec word [cursor_byte]
	dec byte [cursor_x]

	mov si, 36864
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .nothing_to_do

	cmp byte [si], 0Ah
	jl .at_final_char_in_line

	call move_all_chars_backward
	popa
	jmp render_text

.check_cols:
	cmp word [skipcols], 0
	je .nothing_to_do 			; If we don't have columns skipped, don't do anything

	dec word [skipcols] 		; Otherwise, decrement skipped columns
	dec word [cursor_byte]

	mov si, 36864
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .nothing_to_do

	cmp byte [si], 0Ah
	jl .at_final_char_in_line

	call move_all_chars_backward

	popa
	jmp render_text


.enter_pressed:
	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov di, 36864
	add di, cx				; Now SI points to the char under the cursor

	mov byte [di], 0Ah			; Add newline char

	popa

	mov byte [force_render], 1	; go_down will only render the text again if we ask it or if we are at the row 23
	jmp go_down


.f1_pressed:					; Show some help info
	mov dx, 0				; One-button dialog box

	mov ax, .msg_1
	mov bx, .msg_2
	mov cx, .msg_3
	call os_dialog_box

	popa
	call setup_screen
	jmp render_text


	.msg_1	db	'Use Backspace to remove characters,', 0
	.msg_2	db	'and Delete to remove newline chars.', 0
	.msg_3	db	'Unix-formatted text files only!', 0



.f5_pressed:				; Cut line
	cmp word [skipcols], 0
	jne .unskip_cols
	cmp byte [cursor_x], 0
	je .done_going_left
	dec byte [cursor_x]
	dec word [cursor_byte]
	jmp .f5_pressed

.unskip_cols:
	dec word [skipcols]
	dec word [cursor_byte]
	jmp .f5_pressed


.done_going_left:
	mov si, 36864
	add si, word [cursor_byte]
	inc si
	cmp si, word [last_byte]
	je .do_nothing_here

	dec si
	cmp byte [si], 10
	je .final_char

	call move_all_chars_backward
	jmp .done_going_left

.final_char:
	call move_all_chars_backward

.do_nothing_here:
	popa
	jmp render_text



.f8_pressed:				; Run BASIC
	mov word ax, [filesize]
	cmp ax, 4
	jl .not_big_enough

	call os_clear_screen

	mov ax, 36864
	mov si, 0
	mov word bx, [filesize]

	call os_run_basic

	call os_print_newline
	mov si, .basic_finished_msg
	call os_print_string
	call os_wait_for_key
	call os_show_cursor

	popa
	call setup_screen
	jmp render_text


.not_big_enough:
	mov ax, .fail1_msg
	mov bx, .fail2_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	call setup_screen
	popa
	jmp render_text


	.basic_finished_msg	db ">>> BASIC finished - hit a key to return to the editor", 0
	.fail1_msg		db 'Not enough BASIC code to execute!', 0
	.fail2_msg		db 'You need at least an END command.', 0


; ------------------------------------------------------------------
; Move data from current cursor one character ahead

move_all_chars_forward:
	pusha

	mov si, 36864
	add si, word [filesize]			; SI = final byte in file

	mov di, 36864
	add di, word [cursor_byte]

.loop:
	mov byte al, [si]
	mov byte [si+1], al
	dec si
	cmp si, di
	jl .finished
	jmp .loop

.finished:
	inc word [filesize]
	inc word [last_byte]

	popa
	ret


; ------------------------------------------------------------------
; Move data from current cursor + 1 to end of file back one char

move_all_chars_backward:
	pusha

	mov si, 36864
	add si, word [cursor_byte]

.loop:
	mov byte al, [si+1]
	mov byte [si], al
	inc si
	cmp word si, [last_byte]
	jne .loop

.finished:
	dec word [filesize]
	dec word [last_byte]

	popa
	ret


; ------------------------------------------------------------------
; SAVE FILE

save_file:
	mov ax, filename			; Delete the file if it already exists
	call os_remove_file

	mov ax, filename
	mov word cx, [filesize]
	mov bx, 36864
	call os_write_file

	jc .failure				; If we couldn't save file...

	mov ax, file_save_succeed_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	popa
	call setup_screen
	jmp render_text


.failure:
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	popa
	call setup_screen
	jmp render_text


new_file_from_switch:			; new file from /n switch
	pusha				
	mov ax, 65535

; ------------------------------------------------------------------
; NEW FILE

new_file:
	cmp ax, 65535			; new file from switch
	je .clear
	
	mov ax, confirm_msg
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	cmp ax, 1
	je .do_nothing

.clear:
	mov di, 36864			; Clear the entire text buffer
	mov al, 0
	mov cx, 28672
	rep stosb

	mov word [filesize], 1

	mov bx, 36864			; Store just a single newline char
	mov byte [bx], 10
	inc bx
	mov word [last_byte], bx

	mov cx, 0			; Reset other values
	mov word [skiplines], 0
	mov word [skipcols], 0

	mov byte [cursor_x], 0
	mov byte [cursor_y], 2

	mov word [cursor_byte], 0
	


.retry_filename:
	mov ax, filename
	mov bx, new_file_msg
	call os_input_dialog


	mov ax, filename			; Delete the file if it already exists
	call os_remove_file

	mov ax, filename
	mov word cx, [filesize]
	mov bx, 36864
	call os_write_file
	jc .failure				; If we couldn't save file...

.do_nothing:
	popa

	call setup_screen
	jmp render_text


.failure:
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .retry_filename


; ------------------------------------------------------------------
; OPEN FILE

open_file:
	mov ax, confirm_msg
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	cmp ax, 1
	je .do_nothing

.file_selector:
	call os_file_selector			; Get filename to load
	jnc near .file_chosen

	popa
	call setup_screen 				; ESC was pressed
	jmp render_text 				; Continue with the current file

.file_chosen:
	mov si, ax				; Save it for later usage
	mov di, filename
	call os_string_copy


	; Now we need to make sure that the file extension is TXT or BAS...

	mov di, ax
	call os_string_length
	add di, ax

	dec di					; Make DI point to last char in filename
	dec di
	dec di

	mov si, txt_extension			; Check for .TXT extension
	mov cx, 3
	rep cmpsb
	je .valid_extension 				; Located near the start

	dec di

	mov si, bas_extension			; Check for .BAS extension
	mov cx, 3
	rep cmpsb
	je .valid_extension 				; Located near the start

	mov dx, 0
	mov ax, wrong_ext_msg
	mov bx, 0
	mov cx, 0
	call os_dialog_box

	jmp .file_selector

.valid_extension:
	mov di, 36864
	mov al, 0
	mov cx, 28672
	rep stosb 				; Clean the file buffer

	mov ax, filename
	mov cx, 36864				; Load the file 4K after the program start point
	call os_load_file

	mov word [filesize], bx


	; Now BX contains the number of bytes in the file, so let's add
	; the load offset to get the last byte of the file in RAM

	add bx, 36864

	cmp bx, 36864
	jne .not_empty
	mov byte [bx], 10			; If the file is empty, insert a newline char to start with

	inc bx
	inc word [filesize]

.not_empty:
	mov word [last_byte], bx		; Store position of final data byte

	mov word [skiplines], 0			; Reset all the variables
	mov word [skipcols], 0
	mov byte [cursor_x], 0			; Initial cursor position will be start of text
	mov byte [cursor_y], 2			; The file starts being displayed on line 2 of the screen
	mov word [cursor_byte], 0

.do_nothing:
	popa

	call setup_screen
	jmp render_text


; ------------------------------------------------------------------
; Quit

close:
	call os_clear_screen
	ret


; ------------------------------------------------------------------
; Setup screen with colours, titles and horizontal lines

setup_screen:
	pusha

	mov ax, txt_title_msg			; Set up the screen with info at top and bottom
	mov bx, txt_footer_msg
	mov cx, BLACK_ON_WHITE
	call os_draw_background

	mov dh, 1				; Draw lines at top and bottom
	mov dl, 0				; (Differentiate it from the text file viewer)
	call os_move_cursor
	mov ax, 0				; Use single line character
	call os_print_horiz_line

	mov dh, 23
	mov dl, 0
	call os_move_cursor
	call os_print_horiz_line

	mov dh, 0
	mov dl, 20
	call os_move_cursor

	mov ax, filename
	call os_string_length

	cmp ax, 0 				; If there isn't a filename, don't write it on top
	je .no_filename

	mov si, .separator
	call os_print_string 	; Print the separator of the program title and the filename

	mov si, filename
	call os_print_string 	; Print the filename

.no_filename:
	; Now we're going to change the fore-color of each function key or shortcut

	mov dh, 24
	mov dl, 1
	mov cx, 3
	call change_color 		; Esc

	mov dl, 11
	mov cx, 2
	call change_color		; F1

	mov dl, 20
	mov cx, 2
	call change_color		; F2

	mov dl, 29
	mov cx, 2
	call change_color		; F3

	mov dl, 38
	mov cx, 2
	call change_color 		; F4

	mov dl, 46
	mov cx, 2
	call change_color		; F5

	mov dl, 62
	mov cx, 2
	call change_color 		; F8

	popa
	ret

	.separator db '- ', 0


; ------------------------------------------------------------------
; Change the fore-color to red. DH, DL, CX: row, col, times

change_color:
	pusha

.change:
	push cx
	call os_move_cursor

	mov ah, 08h
	mov bh, 0
	int 10h 					; Save the char in AL

	mov bl, ah
	and bl, 11110000b 			; Just save background-color
	add bl, 4 					; Change fore-color to red

	mov ah, 09h
	mov cx, 1
	mov bh, 0
	int 10h 					; Write the character with its new fore-color

	pop cx
	dec cx
	cmp cx, 0
	jle .done_coloring

	inc dl
	jmp .change

.done_coloring:
	popa
	ret


; ------------------------------------------------------------------
; Just clean the text area, avoiding blinking every time and wasting less time

clean_text_entry:
	pusha

	mov dh, 2
	mov dl, 0

.bucle:
	call os_move_cursor

	mov ah, 0Ah
	mov al, 32
	mov bh, 0
	mov cx, 79
	int 10h

	inc dh
	cmp dh, 23
	jne  .bucle

	popa
	ret

; ------------------------------------------------------------------
; DEBUGGING -- SHOW POSITION OF BYTE IN FILE AND CHAR UNDERNEATH CURSOR
; ENABLE THIS IN THE get_input SECTION ABOVE IF YOU NEED IT

showbytepos:
	pusha

	mov word ax, [cursor_byte]
	call os_int_to_string
	mov si, ax

	mov dh, 0
	mov dl, 60
	call os_move_cursor

	call os_print_string
	call os_print_space

	mov si, 36864
	add si, word [cursor_byte]
	lodsb

	call os_print_2hex
	call os_print_space

	mov ah, 0Eh
	int 10h

	call os_print_space

	popa
	ret


; ------------------------------------------------------------------
; Show the current line and column on the file

showlinecolpos:
	pusha
	; Now we're going to show the current line and column on the top

	mov dh, 0
	mov dl, 55
	call os_move_cursor

	mov si, .content
	call os_print_string

	mov dl, 63
	call os_move_cursor

	mov bx, 0
	mov bl, [cursor_y]		; Calculate current line
	sub bx, 1				; Text area starts at cursor_y = 2, and its index 0
	mov word cx, [skiplines]
	add bx, cx

	mov [.lines], bx 		; Save current line

	mov bx, 0
	mov bl, [cursor_x] 		; Calculate current  column
	add bx, 1				; cursor_x is index 0
	mov word cx, [skipcols]
	add bx, cx

	mov [.cols], bx

	mov dh, 0
	mov dl, 62
	call os_move_cursor

	mov ax, [.lines]
	call os_int_to_string
	mov si, ax
	call os_print_string 	; Show the current line

	mov dh, 0
	mov dl, 75
	call os_move_cursor

	mov ax, [.cols]
	call os_int_to_string
	mov si, ax
	call os_print_string 	; Show the current column

	popa
	ret

	.content	db 179, ' Line:      Column:     ', 0
	.lines 		dw 0
	.cols 		dw 0


; ------------------------------------------------------------------
; Data section

	txt_title_msg	db 'MikeOS Text Editor', 0
	txt_footer_msg	db 'Esc Quit  F1 Help  F2 Save  F4 Open  F3 New  F5 Delete line  F8 Run BASIC', 0

	txt_extension	db 'TXT', 0
	bas_extension	db 'BAS', 0
	wrong_ext_msg	db 'You can only load .TXT or .BAS files!', 0
	confirm_msg	db 'Are you sure? Unsaved data will be lost!', 0

	file_load_fail_msg	db 'Could not load file! Does it exist?', 0
	new_file_msg		db 'Enter a new filename:', 0
	file_save_fail_msg1	db 'Could not save file!', 0
	file_save_fail_msg2	db '(Write-only media or bad filename?)', 0
	file_save_succeed_msg	db 'File saved.', 0
	no_more_msg1 	db 'Filesize limit reached! Please delete', 0
	no_more_msg2	db 'some chars or create a new file', 0


	skiplines	dw 0
	skipcols 	dw 0

	cursor_x	db 0			; User-set cursor position
	cursor_y	db 0

	cursor_byte	dw 0			; Byte in file data where cursor is

	last_byte	dw 0			; Location in RAM of final byte in file

	filename	times 32 db 0		; 12 would do, but the user
						; might enter something daft
	filesize	dw 0

	force_render	db 0			; 0 = No; 1 = Yes
	
	switch_new	db '/n', 0

; ------------------------------------------------------------------
