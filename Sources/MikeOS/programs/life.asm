;============================================================
;Program: Life.a86
;Created: 11/20/2021
;By: John Endler
;Editor:Vim
;
;Copyright John Endler - MIT License
;
;About: Conway's Game of Life in 16bit assembly.   
;
; Rules: Any live cell with fewer than 2 live neighbours dies
;      : Any live cell with 2-3 live neighbours lives on to next
;        generation
;      : Any live cell with more than 3 live neighbours dies
;      : Any dead cell with exactly three live neighbours 
;        becomes a live cell 
;
;============================================================

    BITS 16
    %include "mikedev.inc"
    ORG 32768


LIFE_CHAR	    equ '*'
CLEAR_LIFE	    equ 20h
MATRIX_SIZE     equ 2000; size of matrix in bytes
END_OF_MATRIX   equ 1918; end of actual working area of matrix
UP		        equ 48h ; AH
DOWN		    equ 50h ; AH
LEFT		    equ 4Bh ; AH
RIGHT		    equ 4Dh ; AH
S_KEY   	    equ 73h ; AL
C_KEY		    equ 63h ; AL
ESC		        equ 1Bh ; AL


start:
    
   	;call os_seed_random 
	call os_clear_screen          ; clear screen

	call init_matrix            ; initialize matrix

	mov ax, patterns_list; pattern list
	mov bx, help_msg1
	mov cx, help_msg2
	call os_list_dialog           ; list of patterns to choose
	jc no_pattern               ; ESC hit do random

	call os_clear_screen
	;----Load Pattern chosen----;
	cmp ax, 3
	jne acorn_pat
	mov si, glider_gun
	call populate_life          ; populate matrix with pattern
	jmp count_pattern

acorn_pat:
	cmp ax, 4
	jne diehard_pat
	mov si, acorn
	call populate_life
	jmp count_pattern

diehard_pat:
	cmp ax, 5
	jne  .e0
	mov si,  diehard
	call populate_life
	jmp count_pattern
.e0:
	cmp ax, 6
	jne manual
	jmp exit	
manual:
	cmp ax, 1
	jne no_pattern
	call manual_set
	jmp count_pattern
random:
	cmp ax, 2
	je no_pattern
count_pattern:
	mov ax,1                    ; copy matrix to matrix2
	call copy_matrix
	jmp matrix_set
	    
no_pattern:
	call os_clear_screen
	mov si, input_lifes_msg
	call os_print_string
	mov ax, input_lifes
	call os_input_string
	mov si, input_lifes
	call os_string_to_int
	mov word[startlifes], ax   ; save start lives
	call os_print_newline 

	;----Random populate with lifes----;
	call random_populate
	mov ax,1                    ; copy matrix to matrix2
	call copy_matrix

;----Print our intial Matrix----;
matrix_set:
	call os_clear_screen
	mov si, matrix
	call print_matrix

	mov dh, 24
	mov dl, 0
	call os_move_cursor
	mov si, wait_start_msg
	call os_print_string
	call os_hide_cursor
	call os_wait_for_key
	mov dh, 24
	mov dl, 0
	call os_move_cursor
	mov si, start_msg
	call os_print_string

;----Main program loop starts here----;
cycle:
	call evolve                 ; Evolve the population
	xor dx, dx
	call os_move_cursor
	mov si, matrix2
	call print_matrix
	mov ax,2                    ; copy matrix2 to matrix
	call copy_matrix
	mov ax, 1                   ; lets slow down simulation
	call os_pause
	call os_check_for_key
	cmp ax, 0
	jne  .l0 
	jmp cycle                 ; keep going until end of cycles
	;----End of Main Loop----;
.l0:
	;----Display our stats after life cycles are complete----;
	mov dh, 24
	mov dl, 0
	call os_move_cursor

	mov si, any_key_msg
	call os_print_string
	call os_wait_for_key
	jmp start
exit:
	call os_clear_screen
	call os_show_cursor

   	ret

; ==============================================
;               PROCEDURES
; ==============================================
;----------------------------------
; Set positions of lifes in Matrix
;
;
manual_set:
	mov dh, 24
	mov dl, 10
	call os_move_cursor
	mov si, help_msg3
	call os_print_string
	call os_show_cursor
	mov byte[cursor_row], 12
	mov byte[cursor_col], 40	
	mov word[matrix_pos], 1000
	mov dh, 12
	mov dl, 40
	call os_move_cursor
cursor_control:
	call os_wait_for_key
	cmp al, ESC
	je  .e0
	cmp ah, UP
	je move_up
	cmp ah, DOWN
	je move_dn
	cmp ah, LEFT
	je move_left
	cmp ah, RIGHT
	je move_right
	cmp al, S_KEY
	je set_life
	cmp al, C_KEY
	je  C0
	jmp cursor_control
.e0:
	call os_hide_cursor
	ret
set:
	mov dh, byte[cursor_row]
	mov dl, byte[cursor_col]
	call os_move_cursor
	jmp cursor_control
move_up:
	cmp byte[cursor_row], 1
	je set
	dec byte[cursor_row]
	sub word[matrix_pos], 80 
	jmp set
move_dn:
	cmp byte[cursor_row], 23
	je set
	inc byte[cursor_row]
	add word[matrix_pos], 80
	jmp set
move_left:
	cmp byte[cursor_col], 1
	je set
	dec byte[cursor_col]
	dec word[matrix_pos]
	jmp set
move_right: 
	cmp byte[cursor_col], 78
	je set
	inc byte[cursor_col]
	inc word[matrix_pos]
	jmp set
set_life:
	mov bx, word[matrix_pos]
	mov byte[matrix+bx], LIFE_CHAR 	
	mov al, LIFE_CHAR
	call print_char
	jmp set
C0:
	mov bx, word[matrix_pos]
	mov byte[matrix+bx], CLEAR_LIFE
	mov al, CLEAR_LIFE
	call print_char
	jmp set

;---Print character---;
print_char:
	pusha
	mov ah, 0Eh
	mov bx, 000fh
	int 10h
	popa
	ret
    
; ----------------------------------------------
; Take our 25 row x 80 column matrix and make
; dead zone in matrix making the game field
; 23 rows x 78 columns
; This way we can use one check of surrounding
; cells without having to deal with corners or
; sides
;-----------------------------------------------
init_matrix:
	pusha

	;--fill matrix with spaces--;
	mov al, 20h
	mov di, matrix
	mov cx, MATRIX_SIZE
	rep stosb
	;----Null top row----;
	mov di, matrix  ; addr of matrix into edi
	mov cx,77             ; size of row
	mov al,0              ; null top row
	rep stosb
	mov byte[di], 0Ah        ; end row with new line
	mov byte[di+1], 0Dh      ; carriage return

	;----Null bottom row----;
	mov cx,79             ; null the bottom row
	mov di, matrix+1920 ; set to bottom row
	rep stosb 

	mov di, matrix  ; now do both sides nulling left side adding 
	mov bx, 80
null_nl:
	mov byte[matrix+bx],0        ; add null byte to left side
	add bx,78
	mov byte[matrix+bx],0Ah      ; add new line to right side
	inc bx
	mov byte[matrix+bx], 0Dh     ; add carriage return
	inc bx                    ; next byte
	cmp bx,1920               ; see if we are done with sides
	jl null_nl

	popa
	ret
; ----------------------------------------------
; Copy matrix to matrix
; 
;  IN: AX holds 1 to copy matrix to matrix2
;      or AX holds 2 for copy matrix2 to matrix
; ----------------------------------------------
copy_matrix:
	pusha

	cmp ax,1              ; are we copying matrix to matrix2
	jne copy2
	mov si, matrix  ; source
	mov di, matrix2 ; destination
	jmp copy
copy2:
	mov si, matrix2 ; if 2 copy matrix2 to matrix
	mov di, matrix
copy:
	mov cx,MATRIX_SIZE
	rep movsb

	popa
	ret

; ----------------------------------------------
; Populate the matrix with lifes
;
;  IN: si holds life pattern
; ----------------------------------------------
populate_life:
	pusha

	cld
	xor ax,ax
	mov di, matrix        ; addr of matrix to populate
cal:
	lodsb          ; mov byte esi to al which is row inc esi 
	mov bx,80      ; start of our working matrix
	mul bx         ; multiply row by 80
	xor bx, bx
	mov bl,byte[si]   ; mov column to ebx
	add ax,bx      ; this will give us location of byte in matrix to set
	mov bx,ax
	mov byte[di+bx],LIFE_CHAR; set byte in matrix
	inc si               ; mov to next row,column pair in esi
	xor ax,ax
	cmp byte[si],0          ; see if we reached end of row,column pairs
	jne cal

	popa
	ret
; ------------------------------------------
; Random Population
; ------------------------------------------
random_populate:
	pusha

	mov cx,word[startlifes]
lives:
	mov ax, 1                   ; start of matrix 1
	mov bx, END_OF_MATRIX       ; end of matrix
	push cx
	call os_get_random
	mov bx, cx                  ; random number ret in CX
	pop cx
	cmp byte[matrix+bx],0       ; make sure we are not in deadzone
	je lives
	cmp byte[matrix+bx],0Ah    ; newline in deadzone
	je lives
	cmp byte[matrix+bx], 0Dh   ; carriage return in deadzone
	je lives
	cmp byte[matrix+bx],LIFE_CHAR;see if cell is already populated
	je lives
	mov byte[matrix+bx],LIFE_CHAR;make cell alive
	loop lives

	popa
	ret
; ------------------------------------------
; Evolve Matrix Life
;
; Because we set a deadzone around our 
; matrix it makes checking the surrounding
; bytes easier.
; ------------------------------------------
evolve:
	pusha
	xor ax,ax         ; count of lives
	mov cx, 1         ; column checked
	mov bx,81         ; start here in matrix
evolve_loop:
	cmp byte[matrix+bx+1],LIFE_CHAR ; checking for life
	jne  b2
	inc ax                    ; add 1 to eax if we find life
b2:
	cmp byte[matrix+bx-1],LIFE_CHAR ; check surrounding area
	jne  b3
	inc ax
b3:
	cmp byte[matrix+bx-81],LIFE_CHAR 
	jne  b4
	inc ax
b4:
	cmp byte[matrix+bx-80],LIFE_CHAR
	jne  b5
	inc ax
b5:
	cmp byte[matrix+bx-79],LIFE_CHAR
	jne  b6
	inc ax
b6:
	cmp byte[matrix+bx+79],LIFE_CHAR
	jne  b7
	inc ax
b7:
	cmp byte[matrix+bx+80],LIFE_CHAR
	jne  b8
	inc ax
b8:
	cmp byte[matrix+bx+81],LIFE_CHAR
	jne next
	inc ax
next:  
	call set_matrix   ; after checking for surrounding life 
	xor ax,ax         
	inc bx           ; next cell in matrix
	inc cx
	cmp cx,78        ; 80 cells in row 78 end of working area
	jne cont
	add bx,3         ; add 3 to bx to get to next row
	mov cx, 1        ; start column count over
cont:
	cmp bx,END_OF_MATRIX; we only check to this byte because
	jge  end_evolve  ; it is end of working matrix area
	jmp evolve_loop
end_evolve:;exit:

	popa
	ret

; Set cell as dead or alive or nochange
set_matrix:
	cmp ax,2                ; see if only 2 neighbors
	jne check3
	cmp byte[matrix+bx],LIFE_CHAR ; see if cell is alive
	jne die                 
	mov byte[matrix2+bx],LIFE_CHAR; set matrix2 to alive
	jmp done
check3:
	cmp ax,3                ; see if 3 neighbors
	jne die
	mov byte[matrix2+bx],LIFE_CHAR; set cell to living
	jmp done
die:
	mov byte[matrix2+bx],' '; all other conditions cell dies
done:
	ret

;=============================================
; Print Matrix
; IN: SI = matrix addr
;---------------------------------------------
print_matrix:
	pusha
    
	mov cx, END_OF_MATRIX ; print the whole matrix
	mov ah, 0Eh
;----print loop----;
.l0:;print:
        lodsb
        int 10h
        loop .l0;.print

        popa
        ret

; ==============================================
;               PROGRAM DATA
; ==============================================
; Predefined patterns
glider_gun  db 6,2,6,3,7,2,7,3,4,14,4,15,5,13,5,17,6,12
            db 6,18,7,12,7,16,7,18,7,19,8,12,8,18,9,13
            db 9,17,10,14,10,15,4,22,4,23,5,22,5,23,6,22
            db 6,23,3,24,7,24,2,26,3,26,7,26,8,26,4,36
            db 5,36,4,37,5,37,0

acorn       db 10,20,10,21,08,21,09,23,10,24,10,25,10,26,0

diehard     db 10,20,10,21,11,21,11,25,11,26,11,27,09,26,0


input_lifes_msg  db 'Enter number of lifes(max=1200): ',0
wait_start_msg   db '>>>Press any key to start simulation<<<',0
start_msg        db '                 >>>Simulation Started(Press ESC to end)<<<',0
help_msg1        db '*************Game of Life*************',0
help_msg2        db '            Select Option',0
any_key_msg      db '                        >>press any key to exit<<           ',0
help_msg3	     db '----Arrow keys to move, s=set life, c=clear life, ESC=Done----',0 
patterns_list    db 'Manual,Random,Glider Gun,Acorn,Diehard,Exit',0

cursor_col	db	0
cursor_row	db	0
matrix_pos	dw	0
lifecycles  dw  0
startlifes  dw  0 
endlifes    dw  0

input_lifes times 12 db 0



; Matrix of row col board
matrix      times MATRIX_SIZE db 20h    ; fill matrix with spaces
matrix2     times MATRIX_SIZE db 20h    ; 2nd matrix

