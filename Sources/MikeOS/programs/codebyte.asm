;----------------------------------------------------------
; codebyte.asm
;
; Date:02/10/2022
;
; By: John Endler
;
; Program dumps 512 bytes of address 0x9000-91ff
;
; Edit 512 bytes starting @ address 0x9000
;
; Load 512 byte file to edit, run & save
;
; Save byte code to file end filename with extension .512
; so you know it was created with codebyte program
;
; Clear cmd clears 512 bytes starting at 0x9000-91ff
;
; Run byte code starting @ 0x9000
; 
; To enter machine code bytes starting at address 0x9000
; type edit at prompt, you will then be prompted for address
; to enter machine code (address prompt = 0x)
; When prompted for address ( 0x ) type address (exp. 9000)
;   Once you type address it will automatically end your address
; with a colon( exp. 0x9000:) follow this with your machine code
; bytes (exp. 0x9000: b4 cd10 9d6f65 ) press enter when done.
;   When entering machine code bytes you can enter each byte followed
; by a space or enter all your bytes with no spaces its up to you.
;   You are then prompted with  address prompt again where you 
; can enter another address (exp. 0x9010 ) followed by more 
; machine code or ESC to exit edit mode.
;   If you entered a valid machine code program you can type
; run to run program.
;
;   If you make a mistake entering your machine code there is
; no backspacing out what you entered since each char entered
; is encoded and store as you type, so just hit enter and
; enter address where you made mistake and enter the correct
; machine code bytes.
;----------------------------------------------------------

    BITS 16
    %include "mikedev.inc"
    ORG 32768

    LOAD_DATA   equ 0x9000

start:

    call os_clear_screen
    call hex_dump           ; dump 512 bytes from LOAD_DATA
                            ; of addr 9000-91FF
    mov si,break_line       
    call os_print_string    ; 
    mov si,command_menu     ; print command menu
    call os_print_string
    call command_input      ; get action to take
    mov si,commands         ; get command list
    mov di,command_buffer   ; get entered command
    .command_loop:
        lodsb               ; get command length
        and ax,0x00ff       ; is it end of list zero
        je start            ; nothing entered or incorrect entry
        xchg ax,cx          ; place count in cx
        push di             ; save input buffer
        rep cmpsb           ; compare command entered
        jne .next_command
        call word[si]       ; call command
        pop di              ; stack cleanup
        jmp start
        .next_command:
            add si,cx       ; add cx to get next cmd in list
            inc si          ; jmp over address
            inc si
            pop di          ; restore command buffer
            jmp .command_loop

    exit_command:
        pop ax              ; discard DI & return address from call 
        pop ax              ; to exit
        call os_clear_screen
        ret

;---------------------------------------------
; Edit address starting @ 0x9000-0x91FF
; 512 bytes
;
edit_command:

    ;-- get address of start of edit bytes --;
    .addr_loop:
        call os_clear_screen
        call hex_dump           ; dump address 9000-91FF to screen
        mov si,break_line       
        call os_print_string    ; 
        xor dx,dx               ; temp storage for write addr
        mov si,hexedit_prompt   ; show prompt after dump
        call os_print_string

        call read_key           ; read single keystroke
        jc .return              ; ESC key return
        call ascii_to_hex_digit ; encode key returned in al
        mov dh,al               ; dh=00001111
        shl dh,4                ; 1st nibble dh=11110000 dl=00000000
        call read_key
        jc .return
        call ascii_to_hex_digit
        or dh,al                ; or 1st & 2nd nibble to make 1st byte
        call read_key
        jc .return
        call ascii_to_hex_digit ; encode key returned in al
        mov dl,al
        shl dl,4                ; 3rd nibble dl=1111000
        call read_key
        jc .return
        call ascii_to_hex_digit
        or dl,al                ; or 3rd & 4th nibble to make 2nd byte dl=11111111
        xchg ax,dx              ; dx=11111111-11111111
        mov di,write_addr       ; di=write addr
        stosw                   ; write addr entered above

    ;-- get edit bytes --;
        mov si,colon
        call os_print_string
        
        mov di,[write_addr]
        xor dx,dx
    .byte_loop:
        call read_key
        jc .return              ; if ESC pressed
        cmp al,0x0d             ; return key done entering bytes
        je .return_key
        cmp al,0x20             ; skip spaces
        je .byte_loop
        call ascii_to_hex_digit ; encode key returned in al
        mov dl,al               ; dh=00001111
        shl dl,4                ; 1st nibble dh=11110000 dl=00000000
        call read_key
        call ascii_to_hex_digit
        or al,dl                ; or 1st & 2nd nibble to make 1st byte
        stosb
        jmp .byte_loop

    .return_key:
        jmp .addr_loop

    .return:

        ret
;----------------------------------------------
; Load command
; we will not load more than 512 byte files 
; files over 512 bytes will not be loaded 
; to address 9000-91ff
;
load_command:
    call os_clear_screen
    call hex_dump           ; dump address 9000-91FF to screen
    mov si,break_line       
    call os_print_string       ; 
    mov si,load_prompt
    call os_print_string
    call command_input
    mov ax,command_buffer   ; filename to load @ 0x9000
    call os_get_file_size    
    cmp bx,512               ; jmp over fail
    jg .load_fail
    mov bx,512              ; load 512 bytes
    mov cx,LOAD_DATA        ; load file here 0x9000
    call os_load_file
    jc .load_fail
    jmp .return
    .load_fail:
        mov ax, file_load_fail  ; 1st string
        mov bx, file_load_fail2 ; 2nd string
        mov cx, 0
        mov dx, 0
        call os_dialog_box
    .return:
        ret

;----------------------------------------------
; Save command
; we always save 512 bytes from 9000-91ff
;
save_command:
        call os_clear_screen
        call hex_dump           ; dump address 9000-91FF to screen
        mov si,break_line       
        call os_print_string       ; 
        mov si,save_prompt      ; save file prompt after dump
        call os_print_string
        call command_input      ; get file name
        mov ax,command_buffer   ; get input file name
        call os_remove_file     ; remove file if it exists
        ;
        ; write file to disk
        ;
        mov cx,512              ; all files will be 512 bytes long
        mov bx,LOAD_DATA        ; write this to file
        call os_write_file
        jc .failure
        jmp .return
        .failure:
            mov ax, file_fail_msg ; 1st string
            mov bx, 0             ; 2nd string
            mov cx, 0
            mov dx, 0
            call os_dialog_box
    .return:
        ret
;---------------------------------------------
; Run command
;
run_command:
    call os_clear_screen
    call LOAD_DATA      ; run our program
    call read_key
    ret
;---------------------------------------------
; Clear command
;
clear_command:
    mov cx,512
    mov di,LOAD_DATA        ; address 0x9000
    mov al,0x00             ; clear all 512 bytes to zero
    rep stosb
    ret
;---------------------------------------------
; read key and output char
;
; OUT: Al=keycode
;
read_key:

    xor ah,ah       ; get input key
    int 0x16        ; key code in al
    cmp al,0x1b     ; esc key
    jne .output
    stc
    ret
.output:
    clc
    mov ah,0x0e     ; output key
    int 0x10

    ret

;----------------------------------------------
; get command input 
command_input:
    mov di,command_buffer       ; save to input buffer
    xor cx,cx                   ; use for char input count

    .get_input:
        mov ah,00               ; wait for keypress
        int 0x16
        cmp al,0x0d             ; see if enter key
        je .done
        cmp al,0x08             ; see if backspace
        je .erase_char
        stosb                   ; save char to input buffer
        mov ah,0x0e             ; teletype char to screen
        int 0x10
        inc cl                  ; increment char input count
        jmp .get_input
    .erase_char:
        cmp cl,0                ; no more chars to backspace out
        je .get_input           ; 
	    mov ah,0x0E			    ; If not, write space and move cursor back
        int 0x10
	    mov al,0x20
	    int 0x10
	    mov al,0x08
	    int 0x10
        dec edi
        dec cl                  ; decrement char input
        mov byte[di],0          ; clear input buffer char
        jmp .get_input
    
    .done:
        ret
;---------------------------------------------
; hex dump of memory location LOAD_DATA
; dump 512 bytes
;
hex_dump:
    mov si,top_hex
    call os_print_string
    mov si,break_line
    call os_print_string
    xor bx,bx                 ; line counter
    mov dx,LOAD_DATA
    .dump_line:
        cmp bx,32             ; lines to print 16
        jge done              ; 32 bytes printed
        mov si,[addr_line+bx] ; print address string
        call os_print_string
        mov si,dx             ; get addr for hex dump
        xor cx,cx               ; byte counter for 32 bytes
        
        xor di,di               ; track number of bytes printed 
        .next_byte:
            lodsb
            cmp cx,32           ; bytes per line
            je .continue        ; go to next addr line
            call hex_digit_to_ascii
            inc cx
            inc dx              ; inc address to print
            inc di              ; inc bytes printed
            cmp di,4            ; see if 8 bytes printed
            jne .next_byte
            xor di,di           ; 8 printed clear di
            mov al,0x20         ; print a space between
            mov ah,0x0e         ; every 8 bytes per line
            int 10h
            jmp .next_byte

        .continue:
            inc bx            ; update line counter
            inc bx
            mov si,newline
            call os_print_string ; print for next line dump
            jmp .dump_line
    done:
        ret


;---------------------------------
;   hex digit to hex character
;   
;   IN: AL=hex byte
;  OUT: AL=ascii character
;
hex_digit_to_ascii:
    push bx
    push ax             ; save hex digit

    shr al,4            ; get upper nibble
    call convert        ; convert and print
    mov bl,al
    pop ax              ; restore byte
    and al,0x0f         ; get lower nibble
    call convert        ; convert and print
    or al,bl
    pop bx
    ret
;
; converts a hex number 0x0-0xf into hex character
;
convert:
    cmp al,0x0a         
    sbb al,0x69
    das
    mov ah,0x0e
    int 0x10
    ret 


;------------------------------------
; convert ascii to hex digit
;
;  IN: al=input to convert
; OUT: al=converted bytes
;
ascii_to_hex_digit:

    sub al,0x30         ; avoid spaces (anything below ASCII 0x30)
    cmp al,0x0a         ; see if its a number 0-9 below 10(0xa)
    jc .done           
    sub al,0x07         ; make it a letter hex a-f
    and al,0x0f
.done:
    
    ret
;===================================================================
;
; messages
;

hexedit_prompt  db  'Enter address(9000-91FF),'
                db  ' followed by hex bytes.(ESC) to exit',0x0d,0x0a
                db  '0x',0
newline         db  0x0d,0x0a,0
colon           db  ': ',0

command_menu    db  'Type edit, load, save, run, clear or exit..',0x0d,0x0a
                db  '>> ',0
save_prompt     db  'File name: ',0
load_prompt     db  'Load File: ',0

;-- Printed addresses --;
top_hex db '      00010203 04050607 08090A0B 0C0D0E0F '
        db       '10111213 14151617 18191A1B 1C1D1E1F',0x0d,0x0a,0
break_line   db '========================================'
             db '========================================',0

file_fail_msg   db  'File not saved ERROR!',0
file_load_fail  db  'Load file failed ERROR!',0
file_load_fail2 db  'File is over 512 bytes..',0

l1  db '9000: ',0
l2  db '9020: ',0
l3  db '9040: ',0
l4  db '9060: ',0
l5  db '9080: ',0
l6  db '90A0: ',0
l7  db '90C0: ',0
l8  db '90E0: ',0
l9  db '9100: ',0
l10 db '9120: ',0
l11 db '9140: ',0
l12 db '9160: ',0
l13 db '9180: ',0
l14 db '91A0: ',0
l15 db '91C0: ',0
l16 db '91E0: ',0

;-- map of printed addresses --;
addr_line   dw l1, l2, l3, l4, l5, l6, l7, l8, l9, l10, l11, l12, l13, l14, l15, l16

commands    db  4,'edit'
            dw  edit_command
            db  4,'load'
            dw  load_command
            db  4,'save'
            dw  save_command
            db  3,'run'
            dw  run_command
            db  5,'clear'
            dw  clear_command
            db  4,'exit'
            dw  exit_command
            db  0

file_name   times  16  db 0

command_buffer  times 12 db 0

;-- write address --;
write_addr  dw 0x0000



