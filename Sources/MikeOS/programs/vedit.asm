;===============================================
;Text Editor program for KIS_OS          
;
;FileName: vedit.asm
;
;   Date: 09/22/2020
;     BY: John Endler
;
;Last Update: 10/08/2020
;
; Program is attempt at a lite version of 
; VI editor
;
; Updated: 12/31/21 to work in MikeOS
;
; Updated: 01/04/22 fixed bug with scroll_line
;                   changed from byte to word
;                   to handle large file
;
;===============================================

    BITS 16
    %include "mikedev.inc"
    ORG 32768

;arrow keys pageup pagedn
RIGHT   equ 0x4D
LEFT    equ 0x4B
UP      equ 0x48
DOWN    equ 0x50
TAB     equ 0x0F09
SHFTAB  equ 0x0F00
BKSP    equ 0x08
DEL     equ 0x53
PGDN    equ 0x51
PGUP    equ 0x49
ESC     equ 0x1B
ENTR    equ 0x0D

LOAD_DATA   equ 0x9000

;======================================
;           START OF CODE
;======================================

start:
    call os_clear_screen
   ;open file from cmdline
    ;mov bh, 00010111b         ; blue bkg lightgray frg
    ;call os_set_screen_color
	cmp si, 0				    ; Check for cmdline filename
	je .no_file_cmdline

    mov al, 0x20                ; space as separator of cmd line file 
	call os_string_tokenize	    ; If so, get it from params

	mov di, file_name           ; copy the filename in SI
	call os_string_copy         ; 
    mov ax, di                  ; move file pointer to ax
    call os_string_uppercase    ; make file name uppercase
    jmp check_extension         ; check that it has .txt extension

.no_file_cmdline:
    mov ax, top_text
    mov bx, bottom_text
    mov cx, 11110001b
    call os_draw_background
    ;mov bl, TXT
	call os_file_selector       ; Get filename to load
	jnc near file_picked
    
    call os_clear_screen
    ret

file_picked:
	mov si, ax				    ; Save filename
	mov di, file_name
	call os_string_copy         ; copy filename pted to in SI to DI

;----------------------------------
; check file extension .TXT
check_extension:
    mov si, file_name           ; get file name
    mov al, '.'                 ; looking for dot
    call os_find_char_in_string ; returns num bytes to dot
    add si, ax                  ; add it to SI to pt to file extension

    mov ax, si                  ; save for help file check
    mov di, text_ext            ; check if it is TXT
    mov cx, 3
    rep cmpsb                   ; cmp SI/DI
    je .file_exists             ; if = good extension text file
;----see if basic file .BAS----;    
    mov si, ax
    mov di, basic_ext
    mov cx, 3
    rep cmpsb
    je .file_exists
;----see if forth file .4TH----;
    mov si, ax
    mov di, forth_ext
    mov cx, 3
    rep cmpsb
    je .file_exists
; Not text file show error message    
    xor dx, dx
    mov ax, not_text_file
    xor bx, bx
    xor cx, cx
    call os_dialog_box
    xor si, si
    jmp start

.file_exists:
    mov ax, file_name
    call os_file_exists
    jnc open_file

;----if file does not exist create new file----;
    mov bx, LOAD_DATA       ; where file is loaded in memory
    mov byte[bx], 0x0A      ; place newline at first byte
    mov word[file_size], 1  ; filesize is 1 byte
	mov ax, file_name       ; filename from command line
	mov cx, word[file_size] ; set cx to file size
	call os_write_file      ; create new file

;----File ok open and load----;
open_file:
	mov ax, file_name           ; file name ptr
	mov cx, LOAD_DATA           ; 0x9000, 36864
	call os_load_file		    ; Load the file 4K after the program start point
	jnc file_load_success       ; returns in bx holds filesize in bytes
  
;----file fail message----;
	mov ax,file_load_fail_msg	; If fail, show message and exit
	mov bx,0
	mov cx,0
	mov dx,0
	call os_dialog_box
	call os_clear_screen
	ret				        	; Back to the OS

;----file loaded ok----;
file_load_success:
    mov word[file_size], bx        ; bx holds filesize in bytes
    mov word[pedit_byte], LOAD_DATA; pedit_byte = start of file data
    add bx, LOAD_DATA              ; AX = 0x9000, 36864 
    cmp bx, LOAD_DATA              ; empty file
    jne .file_not_empty
    mov byte[bx], 0x0A             ; add new line to empty file
    inc bx
    inc word[file_size]
.file_not_empty:
    mov word[pfile_end], bx        ; set end of file

;--------------------------------------------;
;           Setup Editor Screen
;--------------------------------------------;
edit_screen_start:
    call os_clear_screen

    mov byte[cursor_col], 0
    mov byte[cursor_row], 0
    mov word[scroll_line], 0
    mov word[pedit_byte], LOAD_DATA

;----print line at row 23----;
    mov dh, 23              ; row 24
    mov dl, 0               ; column
    call os_move_cursor
    call os_print_horiz_line
;----print file name under edit----;    
    mov dh, 23
    mov dl, 35
    call os_move_cursor
    mov si, file_name
    call os_print_string

;----Show F1 help msg----;
    mov dh, 24
    mov dl, 1
    call os_move_cursor
    mov si, f1_help_msg
    call os_print_string

    call redraw              ; display redraw screen text 
;======================================================
;           Get Keyboard Input loop
;
get_key:
    xor bx, bx               ; used to clear -1 if call to down
    mov dl, byte[cursor_col] ; set user position of cursor
    mov dh, byte[cursor_row]
    call os_move_cursor

    call os_wait_for_key     ; wait for keyboard input

;=======================================================
;       Movement Keys
;
    cmp ah, RIGHT
    je right
    cmp al, 0x6C    ; key l
    je right

    cmp ah, LEFT
    je left
    cmp al, 0x68    ; key h
    je left

    cmp ah, DOWN
    je down
    cmp al, 0x6A    ; key j 
    je down

    cmp ah, UP
    je up
    cmp al, 0x6B    ; key k
    je up

    cmp ax, 0x1177  ; w jump forward next word
    je next_word

    cmp ax, 0x3062  ; b jump back to previous word
    je back_word
    
    cmp al, 0x30    ; 0=goto start of line
    je start_of_line

    cmp al, 0x24    ; ^$=goto end of line
    je end_of_line

    cmp ax, 0x3B00  ; F1 key help
    jne .cmd_mode
    call help
    jmp near .clear_msg

;----Command Mode----;
.cmd_mode:
    cmp ax, 0x273A  ; ^:=command mode
    je near .command

;----Text deletion----;
    cmp ax, 0x2044  ; ^d=D delete line
    jne .x_key
    call remove_line
    jmp get_key
.x_key:
    cmp ax, 0x2D78  ; x=delete char
	je near .x_delete; delete char

;----Open new line above/below----;    
    cmp ax, 0x186F          ; o key open new line below
    je .newline_below
    cmp ax, 0x184F          ; O key open line above
    je .newline_above

;----switch to text insert/replace modes----;
    cmp al, 0x69    ; i=insert mode
    je .insert_mode

    cmp al, 0x72    ; r=replace mode
    je .replace_mode 

    jmp get_key

;----Delete char, x Key----;
.x_delete:
    mov si, word[pedit_byte]
	cmp si, word[pfile_end] ; if EOF do nothing
	je get_key 

    mov al, byte[si]
	call move_all_bytes_backward
    cmp al, 0x0a
    je near .rmv_NL
    call redraw_line        ; else just redraw line under edit
    jmp get_key

;----NL removed redraw screen----;
.rmv_NL:
	call redraw
    jmp get_key

;----start text mode msg----;
.insert_mode:
    mov dh, 24              ; show text mode message
    mov dl, 1
    call os_move_cursor
    mov si, mode_msg_text
    call os_print_string
    call text_entry
    jmp .clear_msg        ; return for text entry

;----Replace string mode msg----;
.replace_mode:
    mov dh, 24
    mov dl, 1
    call os_move_cursor
    mov si, mode_msg_replace
    call os_print_string
    call replace_text
    jmp .clear_msg

;---- shift o, make newline above----;
.newline_above:
    xor ax, ax                  
    mov al, byte[cursor_col]    ; get current cursor column
    sub word[pedit_byte], ax    ; sub from from edit byte to get start of line
	call move_all_bytes_forward ; make new line above

    mov di, word[pedit_byte]    ; 1st char in new line created
    
	mov byte[di], 0Ah			; Add newline char

    mov byte[cursor_col], 0     ; move cursor to 1st column
    mov bl, -1                  ; -1 in BL for call down to return
	call down                   ; call to down needs -1 to return
    dec byte[cursor_row]        ; move up to new text line
    dec byte[pedit_byte]        ; start on 1st byte on new line
    call redraw
    jmp .insert_mode

;---- o, create new text line below----;
.newline_below:
    mov si, word[pedit_byte]    ; byte we are on
    ;----loop start----;
    .find_nl:
        cmp byte[si], 0x0A      ; find the end of current line
        je .at_eol
        inc si
        jmp .find_nl
    ;----loop end----;
    
.at_eol:
    mov word[pedit_byte], si    ; set edit byte to end of line 0x0A

	call move_all_bytes_forward

    mov di, word[pedit_byte]    
    
	mov byte[di], 0Ah			; Add newline char

    mov bl, -1              ; -1 in BL for call down to return
	call down               ; call to down needs -1 to return
    xor bx, bx              ; clear call to down

    mov byte[cursor_col], 0 ; start st 1st char on new text line
    call redraw
    jmp .insert_mode

;----after text/replace mode move msg----;
.clear_msg:
    mov dh, 24
    mov dl, 1
    call os_move_cursor
    mov si, clear_mode_msg
    call os_print_string
;----Show F1 help msg----;
    mov dh, 24
    mov dl, 1
    call os_move_cursor
    mov si, f1_help_msg
    call os_print_string
    jmp get_key

;----Command Mode----;
.command:
    call command_mode
    cmp ax, -1
    jne .clear_msg

;----Exit the VI editor----;
.exit:
    xor dx, dx
    call os_move_cursor
    call os_clear_screen
    ret

;-------------------------------------------------
;           Move Cursor Update edit_byte
;-------------------------------------------------
;       MOVE RIGHT
right:
    mov si, word[pedit_byte]      ; SI pts to byte under cursor  
    cmp byte[si], 0x0a            ; check for end of line
    je get_key
    cmp byte[cursor_col], 79      ; check if last column  
    je get_key
    inc si                        ; inc our SI pointing to byte under cursor
    mov word[pedit_byte], si      ; save it  
    inc byte[cursor_col]          ; mov 1 column over
    jmp get_key
;------------------------------------
;       MOVE LEFT
left:
    mov si, word[pedit_byte]    ; get byte under cursor
    cmp byte[cursor_col], 0     ; make sure we are not at beginning of row
    je get_key
    dec si                      ; move back 1
    mov word[pedit_byte], si    ; save new edit byte
    dec byte[cursor_col]        ; and new column
    jmp get_key
;--------------------------------------
;       Jump to next word
next_word:
    mov si, word[pedit_byte]    ; get edit byte
    mov cl, byte[cursor_col]    ; and column

    cmp cl, 79                  ; check if at last column
    je get_key                  ; if yes do nothing
    cmp byte[si], 0x0a          ; check for end of line
    je  get_key
    ;----Find spaces loop----;
    .find_next_space:
        lodsb                   ; load byte si to AL inc SI
        inc cl                  ; coloumn
        cmp al, 0x0A
        je get_key
        cmp al, 0x20            ; is it a space
        jne .find_next_space
    ;----end loop----;    
    
    dec si                      ; move back to 1st letter found
    dec cl

    ;----find word loop----;
    .find_next_word:
        lodsb
        inc cl
        cmp al, 0x20
        je .find_next_word
    ;----end word loop----;
    dec si
    dec cl
    mov byte[cursor_col], cl    ; save new cursor position
    mov word[pedit_byte], si    ; save our edit byte position
    jmp get_key

;--------------------------------------
;       Jump to previous word
back_word:
    mov si, word[pedit_byte]    ; get edit byte
    mov cl, byte[cursor_col]    ; get cursor column

    cmp cl, 0
    je get_key

    std                         ; set direction to dec
    ;----find next space----;
    .find_next_space:
        lodsb
        dec cl
        cmp cl, 0
        je .ret_back
        cmp al, 0x20
        jne .find_next_space
    ;----end find space loop----;
    inc cl
    inc si
    ;----find previous word----;
    .find_end_word:
        lodsb
        dec cl
        cmp cl, 0
        je .ret_back
        cmp al, 0x20
        je .find_end_word
        inc cl
        inc si
    .find_start_word:
        lodsb
        dec cl
        cmp al, 0x20
        jne .find_start_word
    ;----end find start loop----;

    inc cl
    inc cl
    inc si
    inc si
    mov byte[cursor_col], cl    ; save new column
    mov word[pedit_byte], si    ; save new edit byte
.ret_back:
    cld                         ; set dir flag inc
    jmp get_key
;-------------------------------------
;       Move down a row
down:
    mov si, word[pedit_byte]    ; get edit byte position

    ;----start loop----;   
    .find_eol:
        lodsb                     ; load al with byte for SI inc SI
        cmp al, 0x0a              ; check for end of line
        je .eol
        jmp .find_eol             ; keep looking
    .eol:    
        dec si                    ; bring back to 0x0a  
        cmp si, word[pfile_end]   ; see if we are at end of file
        jge .call_check
    ;----end loop----;   
    
    inc si                        ; next char after 0x0a points to next row
    cmp byte[cursor_row], 21      ; we display only rows 0-21
    je .scroll_line               ; are we at last row?
    inc byte[cursor_row]          ; move down 1 row
    mov byte[cursor_col], 0       ; set back to first column
    mov word[pedit_byte], si      ; update edit byte
.call_check:
    cmp bl, -1                    ; check if this procedure was called or jmp to
    je .call_ret
    jmp get_key                   ; return from jump  

.call_ret:
    ret                           ; return from call
.scroll_line:
    inc word[scroll_line]         ; inc number of rows that have been scrolled
    mov byte[cursor_col], 0       ; stay @ row 21, move to col=0
    mov word[pedit_byte], si      ; update edit byte to beginning of next row
    call redraw                   ; redraw the display to scroll 
    jmp .call_check               ; ret to get next key
;-------------------------------------
;       Move up a row
up:
    xor ax, ax
    mov al, byte[cursor_col]
    mov si, word[pedit_byte]
    sub si, ax
    cmp si, LOAD_DATA
    je get_key
    mov si, word[pedit_byte]
    cmp byte[si], 0x0a            ; see if we are on a new line char to start
    jne .no_newline
    dec si                        ; get off new line before starting loop
.no_newline:
    std                           ; set string operations to decrement
    mov cx, 2                     ; loop back to 2nd 0x0a
    
    ;----start loop----
    .find_0a:
        lodsb                     ; load AL in SI
        cmp al, 0x0a              ; find newline ?
        je .found
        cmp si, LOAD_DATA         ; are we back at start of text file 
        je .top 
        jmp .find_0a              ; keep looking
    .found:
        loop .find_0a             ; found 1 looking for 2nd 0x0a
    ;----End loop----    

.done_up:
    inc si                    ; pts back to 0x0a  
    inc si                    ; pts to start of next line of text
    jmp .redraw_display
.top:
    cmp cx, 1
    je .redraw_display
    cld
    mov word[pedit_byte], si
    mov byte[cursor_col], 0
    mov byte[cursor_row], 0
    jmp get_key
.redraw_display:
    cld                       ; set string operations back to inc
    mov word[pedit_byte], si  ; update edit byte
    mov byte[cursor_col], 0   ; back to first column in new row
    cmp byte[cursor_row], 0
    je .scroll_up
    dec byte[cursor_row]
    jmp get_key
.scroll_up:
    cmp word[scroll_line], 0
    jle get_key
    dec word[scroll_line]
    call redraw
    jmp get_key 
;---------------------------------------------
; Move to start of text line 0 key
;
start_of_line:
    mov si, word[pedit_byte]    ; get byte under cursor
    cmp byte[cursor_col], 0     ; make sure we are not at beginning of row
    je get_key
    mov cl, byte[cursor_col]
;----loop start----
    .move_back:
        dec si                  ; move back 1
        dec cl                  ; dec column
        cmp cl, 0               ; are we back at start of row
        jne .move_back
;----end loop----
    mov word[pedit_byte], si    ; save new edit byte
    mov byte[cursor_col], 0     ; start of column
    jmp get_key

;---------------------------------------------
; Move to end of text line ^$ keys
;
end_of_line:
    mov si, word[pedit_byte]      ; SI pts to byte under cursor  
    cmp byte[si], 0x0a            ; check for end of line
    je get_key
    cmp byte[cursor_col], 79      ; check if last column  
    je get_key
    mov cl, byte[cursor_col]      ; get current column  
;----loop start----
    .find_eol:
        lodsb                      ; get byte to AL inc SI
        cmp al, 0x0a               ; end of line?
        je .end_of_line
        inc cl                     ; inc column
        jmp .find_eol
;----loop end----
.end_of_line:
    dec si                          ; move back to NL char 0x0A
    mov word[pedit_byte], si
    mov byte[cursor_col], cl        ; save new column
    jmp get_key

;================================================
; Command Mode
; IN: nothing
;OUT: AX=0 normal return or -1 to exit program
;
command_mode:
    pusha

;----show : prompt----;
    mov dh, 24           ; row 
    mov dl, 0            ; col
    call os_move_cursor
    mov si, mode_msg_cmd
    call os_print_string
;----move cursor to after :----;
    mov dh, 24
    mov dl, 2
    call os_move_cursor
    call os_wait_for_key
    cmp al, ESC           ; do nothing ret to move mode
    je .ret

    mov bx, ax            ; save key pressed
    mov ah, 0x0E          ; show key pressed
    int 0x10
    call os_wait_for_key  ; wait for enter to execute or 
    cmp al, ESC           ; ESC to cancel and ret
    je .ret
    
;----restore key pressed----;    
    mov ax, bx
    cmp ax, 0x1177         ; w key save file
    jne .s
    mov ax, file_name
    call save_file
    jmp .ret
.s:
    cmp ax, 0x1F73         ; s key save file as
    je .save_as
    cmp ax, 0x316E         ; n key create new file
    je .create_new
    cmp ax, 0x1372         ; r key run Basic Interpreter
    je .run_basic
    cmp ax, 0x2D78         ; x save file and exit VI
    je .save_quit
    cmp ax, 0x1071         ; q key quit VI
    je .ret_quit
    cmp ax, 0x2368         ; h key show help
    jne .ret
	call help
    jmp .ret

.save_as:
    call save_file_as
    jmp .ret
.run_basic:
    call os_clear_screen
    mov ax, LOAD_DATA
    mov si, 0
    call os_run_basic
    mov si, code_run_end
    call os_print_string
    call os_wait_for_key
    ;call redraw
    popa
    jmp edit_screen_start
.save_quit:
    mov ax, file_name
	call save_file
    jmp .ret_quit
.create_new:
    call new_file
.ret:
    popa
    ret
;----if q or x key exit VI----;
.ret_quit:
    popa
    mov ax, -1
    ret
;===================================================================
;     Text Mode starts here when i key is pressed in Move Mode
;
text_entry:
	pusha

.get_text_key:
    mov dl, byte[cursor_col] ; set user position of cursor
    mov dh, byte[cursor_row]
    call os_move_cursor

    call os_wait_for_key     ; wait for keyboard input

	cmp ah, DEL				; Delete?
	je near .delete_pressed ; delete char

	cmp al, BKSP
	je near .backspace_pressed ; delete char

	cmp al, KEY_ENTER          ; start newline 
	je near .enter_pressed
    
    cmp al, ESC             ; back to Move Mode
    je near .move_mode_ret

	cmp al, 32				; Only deal with displayable chars
	jl near .get_text_key

	cmp al, 126
	je near .get_text_key

	call os_get_cursor_pos
	cmp dl, 78              ; see if we are at end of line no more text
	jg near .get_text_key


;----Text char entry is here----;
	push ax                  ; save key code

	call move_all_bytes_forward

    mov si, word[pedit_byte] ; char under cursor

	pop ax                  ; get key code back

	mov byte[si], al        ; save char to byte entered
	inc word[pedit_byte]    ; move to next byte
	inc byte[cursor_col]
    
    call redraw_line        ; just redraw line under edit
    jmp .get_text_key        

;----ESC key pressed---;
.move_mode_ret:
    popa
    ret                 ; exit Move Text Mode

;----Delete Key----;
.delete_pressed:
    mov si, word[pedit_byte]
	cmp si, word[pfile_end] ; if EOF do nothing
	je .get_text_key 

    mov al, byte[si]
	call move_all_bytes_backward
    cmp al, 0x0A        ; are we removing a NL char
    je .rmv_NL
    call redraw_line        ; else just redraw line under edit
    jmp .get_text_key

;----NL removed redraw screen----;
.rmv_NL:
	call redraw
    jmp .get_text_key

;----Backspace----;
.backspace_pressed:
	cmp word[pedit_byte], 0 ; do not backspace if first byte 
	je .get_text_key

	cmp byte[cursor_col], 0 ; do not backspace if first column
	je .get_text_key

	dec word[pedit_byte]
	dec byte[cursor_col]

    mov si, word[pedit_byte]
	cmp si, word[pfile_end]
	je .get_text_key

	call move_all_bytes_backward
	call redraw_line
    jmp .get_text_key

;----Enter Key----;
.enter_pressed:
	call move_all_bytes_forward

    mov di, word[pedit_byte]
    
	mov byte[di], 0Ah			; Add newline char

    mov bl, -1              ; -1 in BL for call down to return
	call down               ; call to down needs -1 to return
    call redraw
    jmp .get_text_key

;-----------------------------------------------;
; Called from Move Mode ^d=D remove line
;
remove_line:
    pusha
    ;----start loop----;
    .line_start:				; Cut line
	    cmp byte[cursor_col], 0 ; go back to start of line
	    je .delete_line         ; back to start of line?
	    dec byte[cursor_col]
	    dec word[pedit_byte]
	    jmp .line_start
    ;----end loop----;

.delete_line:
    mov si, word[pedit_byte]; start of line    
	inc si
	cmp si, word[pfile_end] ; see if end of file
	je .do_nothing_here

	dec si                  
	cmp byte [si], 0x0a     ; see if NL char
	je .final_char          ; at end of line a chars have been deleted

	call move_all_bytes_backward
	jmp .delete_line

.final_char:
	call move_all_bytes_backward ; remove last char NL 0x0A

.do_nothing_here:
    call redraw
    
    popa
    ret

;-------------------------------------------------------------
; Replace Text Mode r key
;
replace_text:
    pusha
    mov di, word[pedit_byte] ; DI pts to edit byte
    mov si, .undo_buffer     ; SI pts to undo buffer   
    xor bx, bx               ; offset into undo buffer

.get_text_key:
    mov dl, byte[cursor_col] ; set user position of cursor
    mov dh, byte[cursor_row]
    call os_move_cursor

    call os_wait_for_key     ; wait for keyboard input

	cmp al, BKSP             ; backspace undo change
	je near .backspace

    cmp al, ESC              ; exit back to Move Mode
    je near .move_mode_ret

	cmp al, 32				; Only deal with displayable chars
	jl near .get_text_key

	cmp al, 126
	je near .get_text_key

	call os_get_cursor_pos
	cmp dl, 78
	jg near .get_text_key

;----Text char pressed save----;
    cmp byte[di], 0x0a     ; check for end of line 
    je .get_text_key       ; do nothing

    mov dl, byte[di]       ; get byte under edit
    mov byte[si+bx], dl    ; save to undo buffer
    inc bx                 ; next position in undo buffer 

	stosb                  ; save char to byte under cursor inc DI
	inc word[pedit_byte]   ; move edit byte ptr
	inc byte[cursor_col]   ; inc our column 

    call redraw_line       ; redraw line to show changes 
    jmp .get_text_key        

.backspace:
    cmp bx, 0
    je .get_text_key        ; no more undo
    
    dec di                  ; move back 1 edit byte
    dec bx                  ; move index back 1
    mov dl, byte[si+bx]     ; get byte from undo buffer
    mov byte[di], dl        ; put back in edit byte
    dec word[pedit_byte]
    dec byte[cursor_col]
    call redraw_line
    jmp .get_text_key

;----ESC key return to Move Mode----;
.move_mode_ret:
    popa
    ret
.undo_buffer times 79 db 0     ; this will hold replaced chars for BKSP undo

; ------------------------------------------------------------------
; Move data from current cursor one character ahead
; increase file size by 1 byte
;
move_all_bytes_forward:
	pusha

	mov si, LOAD_DATA               ; where file data starts
	add si, word [file_size]    	; SI = final byte in file

	mov di, word[pedit_byte]        ; current byte under cursor

   ;----start loop----
    .loop:
    	mov byte al, [si]           ; get last byte
    	mov byte [si+1], al         ; move up on memory location
    	dec si                      ; next byte to move
    	cmp si, di                  ; have we reached our edit byte
    	jl .finished
    	jmp .loop
   ;----end loop----
.finished:
	inc word[file_size]            ; file size 1 byte bigger
    inc word[pfile_end]            ; point to new file end

	popa
	ret


; ------------------------------------------------------------------
; Move data from current cursor + 1 to end of file back one char
; decrease file size 1 byte
;
move_all_bytes_backward:
	pusha

	mov si, word[pedit_byte]
    
    ;----start loop----
    .loop:
	    mov byte al, [si+1]         ; grab next byte up
	    mov byte [si], al           ; move back 1 byte
	    inc si                      ; move up in text file
	    cmp si, word[pfile_end]
	    jne .loop
    ;----end loop----

.finished:
	dec word[file_size]         ; file reduced by 1 byte
    dec word[pfile_end]         ; point to new file end

	popa
	ret

; ------------------------------------------------------------------
; SAVE FILE
; IN: AX=addr of file name
;
save_file:
    pusha

	call os_remove_file        ; remove file pointed to by AX

	mov word cx, [file_size]
	mov bx, LOAD_DATA
	call os_write_file         ; write file pointed to by AX
	jc .failure			       ; If we couldn't save file...

    popa
    ret

.failure:
	mov ax, file_save_fail_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
    
    popa
	call redraw
    ret
;-------------------------------------------------
; Save file as
;
save_file_as:
    pusha

.retry_filename:
    mov dh, 24      ; row
    mov dl, 2       ; col
    call os_move_cursor
    mov si, new_file_msg
    call os_print_string
	mov ax, file_name
    call os_input_string

	mov ax, file_name		; Delete the file if it already exists
	call os_remove_file

;----write file AX=addr of file name----;
	mov cx, word[file_size]
	mov bx, LOAD_DATA
	call os_write_file  
	jc .failure				; If we couldn't save file...
    jmp .exit

.failure:
	mov ax, file_new_fail_msg   ; 1st string
	mov bx, 0                   ; 2nd string
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .retry_filename

.exit:
 ;----show new file name in editor----;   
    mov dh, 23              ; row 24
    mov dl, 0               ; column
    call os_move_cursor
    call os_print_horiz_line
    mov dh, 23
    mov dl, 35
    call os_move_cursor
    mov si, file_name
    call os_print_string
    call redraw             ; need redraw to remove file name dialog

    popa
    ret

;-------------------------------------------------
; NEW FILE
;
new_file:
    pusha

	mov di, LOAD_DATA       ;Clear the entire text buffer
	mov al, 0
	mov cx, 28672
	rep stosb

	mov word [file_size], 1 ; new file set file size to 1 byte

	mov bx, LOAD_DATA		; location of file data
	mov byte [bx], 0x0A     ; Store newline char
	inc bx
	mov word [pfile_end], bx ; set end of file after NL char

;----Set all values to new file----;
	mov word[pedit_byte], LOAD_DATA

    ;mov word[ppage_start], LOAD_DATA
	mov byte[cursor_col], 0
	mov byte[cursor_row], 0

.retry_filename:
    mov dh, 24      ; row
    mov dl, 2       ; col
    call os_move_cursor
    mov si, new_file_msg
    call os_print_string
	mov ax, file_name
    call os_input_string

	mov ax, file_name		; Delete the file if it already exists
	call os_remove_file

;----create our new file on disk----;
	mov ax, file_name
	mov cx, word[file_size]
	mov bx, LOAD_DATA
	call os_write_file
	jc .failure				; If we couldn't save file...
    jmp .exit

.failure:
	mov ax, file_new_fail_msg   ; 1st string
	mov bx, 0                   ; 2nd string
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .retry_filename

.exit:
 ;----show new file name in editor----;   
    mov dh, 23              ; row 24
    mov dl, 0               ; column
    call os_move_cursor
    call os_print_horiz_line
    mov dh, 23
    mov dl, 35
    call os_move_cursor
    mov si, file_name
    call os_print_string
    call redraw

    popa
    ret

;----------------------------------------
; redraw line under edit
;
redraw_line:
    pusha
    
    mov si, word[pedit_byte] ; get edit byte
    xor bx, bx
    mov bl, byte[cursor_col] ; current cursor column
    sub si, bx               ; sub to move edit byte back to start of line

;----move cursor to start of column----;
    mov dl, 0                
    mov dh, byte[cursor_row]
    call os_move_cursor

;----clear line with spaces----;
    mov al, ' '
    mov cx, 79
    mov ah, 0x0E
    ;----start loop----;
    .clear:
        int 0x10
        loop .clear
    ;----end of loop----;

;----now redraw line AH=0x0E----;
    mov dl, 0               ; set column
    mov dh, byte[cursor_row]; current row under edit
    call os_move_cursor

    ;----start loop to print chars----;
    .text_out:
        lodsb                ; get byte 
        cmp al, 0x0A         ; see if new line
        je .exit
        int 0x10             ; teletype char to screen AH=0x0E
        jmp .text_out 
    ;----loop ends----;

.exit:    
    popa
    ret

;----------------------------------------------------------------
;Draw/Re-Draw screen text
;
redraw:
    pusha


    mov dh, 21              ; clear screen to row 21
    call clear_to_nrow

    xor dx, dx
    call os_move_cursor     ; move cursor back to top left of screen

    mov si, LOAD_DATA       ; if first page
    mov cx, word[scroll_line]
.skip_lines:    
    cmp cx, 0
    je .no_skip
    dec cx
    .skip_line:
        lodsb
        cmp al, 10
        jne .skip_line
        jmp .skip_lines        
 .no_skip:   
    mov ah, 0x0E            ; BIOS print char teletype

    ;----loop start of show text----;
    align 2
    show_text:
	    lodsb					; Get character from file data
	    cmp al, 10				; Go to start of line if it's a carriage return character
	    jne not_newline

	    call os_get_cursor_pos  
	    mov dl, 0				; Set DL = 0 (column = 0) 
	    call os_move_cursor

    not_newline:
	    call os_get_cursor_pos	; Don't wrap lines on screen
	    cmp dl, 79
	    je .no_print

	    int 10h					; Print the character via the BIOS

    .no_print:
	    mov word bx, [pfile_end]
	    cmp si, bx				; Have we printed all characters in the file?
	    je .ret

	    call os_get_cursor_pos	; Are we at the bottom of the display area?
	    cmp dh, 22              ; only 22 lines of text on screen
	    je .ret

	    jmp show_text   		; If not, keep rendering the characters
    ;----loop end of show text----;

.ret:
    popa
    ret
;------------------------------------------------
; Show Help 
; save open file to temp file and setup screen
; for help message, load help message.
; Cleanup after help message exit and restore
; previous open file.
;
help:
    pusha

    mov ax, temp_file       ; temp file name to save open file
    call save_file          ; save open file
	mov di, LOAD_DATA       ; Clear the entire text buffer
	mov al, 0
	mov cx, 28672
	rep stosb

	mov ax, help_file           ; open help file
	mov cx, LOAD_DATA           ; 0x9000, 36864
	call os_load_file		    ; on ret BX = filesize 

    add bx, LOAD_DATA           ; set end of file
    mov word[phelp_end], bx     ; set end of file

;----clear screen draw horz line----;
    call os_clear_screen
    mov dh, 23              ; row 24
    mov dl, 0               ; column
    call os_move_cursor
    call os_print_horiz_line
;----show file name under edit----;
    mov dh, 23
    mov dl, 35
    call os_move_cursor
    mov si, file_name
    call os_print_string
;----show help message----;
    mov dh, 24
    mov dl, 1
    call os_move_cursor
    mov si, mode_msg_help
    call os_print_string

    call os_hide_cursor     ; hide the cursor
    call draw_help          ; draw help screen text
    call os_show_cursor     ; show cursor on return

; clear help file data from buffer
    
	mov di, LOAD_DATA       ;Clear the entire text buffer
	mov al, 0
	mov cx, 28672
	rep stosb
; setup original screen showing Move Mode
    call os_clear_screen

    mov dh, 23              ; row 24
    mov dl, 0               ; column
    call os_move_cursor
    call os_print_horiz_line
;----show file name under edit----;
    mov dh, 23
    mov dl, 35
    call os_move_cursor
    mov si, file_name
    call os_print_string
    mov dh, 24
    mov dl, 1
    call os_move_cursor
    mov si, clear_mode_msg
    call os_print_string

; reload original file to buffer
	mov ax, temp_file           ; file name ptr
	mov cx, LOAD_DATA           ; 0x9000, 36864
	call os_load_file		    ; Load the file 4K after the program start point
    call redraw

; remove temp file 
	mov ax, temp_file		; Delete the temp file
    call os_remove_file

    popa
    ret

;-----------------------------------------------------------------
; Draw Help message
;
draw_help:
    pusha

redraw_help:
    xor dx, dx
    call os_move_cursor
    mov ah, 0x0E            ; BIOS print char teletype
    mov si, LOAD_DATA
    mov cl, byte[scroll_help]

    ;----Skip scrolled lines----;
    .skip_lines:    
        cmp cl, 0
        jle .no_skip
        dec cl
        .skip_line:
            lodsb
            cmp al, 10
            jne .skip_line
            jmp .skip_lines        
    ;----end loop skip lines----;

    .no_skip:   
    
    ;----start show help loop----;
    .show_help:
        lodsb					; Get character from file data
        cmp al, 10				; Go to start of line if it's a carriage return character
        jne .not_newline

        call os_get_cursor_pos  
        mov dl, 0				; Set DL = 0 (column = 0) 
        call os_move_cursor

    .not_newline:
        call os_get_cursor_pos	; Don't wrap lines on screen
        cmp dl, 79
        je .no_print

        int 10h					; Print the character via the BIOS

    .no_print:
        mov word bx, [phelp_end]
        cmp si, bx				; Have we printed all characters in the file?
        je .wait_key

        call os_get_cursor_pos	; Are we at the bottom of the display area?
        cmp dh, 22              ; only 22 lines of text on screen
        je .wait_key

        jmp .show_help   		; If not, keep rendering the characters
    ;----end show help loop----;

.wait_key:
    call os_wait_for_key

    cmp ah, DOWN                ; down arrow/j key
    je .down
    cmp al, 0x6A                ; key j 
    je .down

    cmp ah, UP
    je .up
    cmp al, 0x6B                ; key k
    je .up

    cmp al, ESC
    je .exit
    jmp .wait_key

.exit:
    popa
    ret

.down:
	mov word bx, [phelp_end]
	cmp si, bx				; last page of help?
    je .wait_key

    mov dh, 21
    call clear_to_nrow
    inc byte[scroll_help]
    jmp redraw_help
.up:
    cmp byte[scroll_help], 0
    je .wait_key
    mov dh, 21
    call clear_to_nrow

    dec byte[scroll_help]
    jmp redraw_help
;=========================================
; IN: DH=row to clear to
clear_to_nrow:
	pusha

	mov ah, 7			; Scroll full-screen
	mov al, 0			; Normal white
	mov bh, 7			; on black
	mov cx, 0			; Top-left
	mov dl, 79
	int 10h

	popa
	ret
;==========================================
;           DATA SECTION
;==========================================
file_save_fail_msg  db 'File save FAILED!!!',0
file_load_fail_msg  db 'Failed to load file...',0
file_new_fail_msg   db 'Failed to Create New File!',0

;-----Pad the below messages out to 78 chars plus term NULL-----;
clear_mode_msg      times 78 db ' '
                    db 0;
mode_msg_text       db ' -- INSERT --'
     .pad_text      times 78 - (.pad_text - mode_msg_text) db ' '
                    db 0

mode_msg_replace    db ' -- REPLACE --'
    .pad_replace    times 78 - (.pad_replace - mode_msg_replace) db ' '
                    db 0

mode_msg_cmd        db ' :'
    .pad_cmd        times 78 - (.pad_cmd - mode_msg_cmd) db ' '
                    db 0

mode_msg_help       db ' Help: up/down = k/j keys,  ESC = Exit Help',0
    .pad_help       times 78 - (.pad_help - mode_msg_help) db ' '
                    db 0

text_ext            db 'TXT',0
basic_ext           db 'BAS',0
forth_ext           db '4TH',0
not_text_file       db 'Not a text file can not open..',0
top_text            db 'Text File Line Editor',0
bottom_text         db 'Press ESC to Cancel...',0


help_file           db 'VEDITHLP.TXT',0
temp_file           db 'TEMP.TXT',0

new_file_msg        db ' Enter file name: ',0
code_run_end        db 0x0d,0x0a,'>>>Basic Program End<<< Hit any key...',0

f1_help_msg         db 'F1 = Help',0

file_name           times  32 db 0

pfile_end    dw  0  ; end of file
file_size    dw  0  ; file size in bytes
pedit_byte   dw  0  ; the byte under cursor
phelp_end    dw  0  ; end of help message

scroll_line dw  0
scroll_help db  0
cursor_col  db  0
cursor_row  db  0

