;=================================================
; Filename: pong.asm
;
; Date: 11/03/2021
;
; Retro Pong Game, by John Endler
;
;  Play against the computer using
; the up down arrows to control your paddle on the
; left side of screen.
;  It takes 7 points to win game and the more
; points you score the better the computer gets.
;
;=================================================


%include "mikedev.inc"


;-------- CONSTANTS -----------
VIDEO_MEM	    	 equ 0xb800	; Color text mode memory location
ROW_LENGTH		     equ 160	    ; 80 Character row * 2 bytes each(color/char)
PLAYER_COLUMN        equ 4		; Player column position
CPU_COLUMN    		 equ 154	    ; CPU column position
KEY_Y                equ 0x15     ; reset game
KEY_Q                equ 0x10
ESC                  equ 0x1B
SCREEN_WIDTH	     equ 80
SCREEN_HEIGHT	     equ 23
PADDLE_HEIGHT        equ 5
BALL_START_COLUMN    equ 78	    ; Ball column position for start of round
CPU_INTELLIGENCE     equ 10
GAME_WON			 equ 0x37	    ; Score needed to end game ascii 7

;-----Load Program-----
ORG 32768

;-----------------Game Start-------------------

start_game:
    call os_hide_cursor
    call os_clear_screen

    mov ax, welcome_msg
    mov bx, line1
    mov cx, line2
    xor dx, dx
    call os_dialog_box

	 ;Set up video memory
	mov ax, VIDEO_MEM
	mov es, ax	; ES:DI = B800:0000

    ;---Draw court sides---;
    mov ax, 0x023d
    xor di, di
    mov cx, 79
    rep stosw

    mov ax, 0x023D
    mov di, 3840
    mov cx, 79
    rep stosw

;---------Main Game loop---------;
game_loop:
	; Clear Screen to black every loop
	xor ax, ax
	mov di, 161         ; clear only from 2nd row to 24 row
	mov cx, 80*25-160
	rep stosw

	;---Draw middle separating line---;
	mov ax, 0x2020  	; green background, black foreground
	mov di, 238;398			; Start at middle of 80 character row
	mov cl, 12			; draw net
	.draw_net_loop:
		stosw                   ; inc's di by word
		add di, 2*ROW_LENGTH-2	; next row sub 2 to bring back to screen center
		loop .draw_net_loop	    ; Loops until cx is zero

	;--Draw player and CPU paddles---;
	imul di, [player_row], ROW_LENGTH	; row of paddle * row length
	imul bx, [cpu_row], ROW_LENGTH      ; row of cpu paddle * row length
	mov cl, PADDLE_HEIGHT               ; loop with height of paddles
	.draw_paddles_loop:
		mov [es:di+PLAYER_COLUMN], ax   ; ax holds background/foreground color 
		mov [es:bx+CPU_COLUMN], ax
		add di, ROW_LENGTH              ; move down 1 row to draw player paddle
		add bx, ROW_LENGTH              ; same for cpu paddle
		loop .draw_paddles_loop
	
	;----------------Scores----------------;
	;--poke player score--;
	mov ah, 0x02
    mov al, byte [player_score]
	mov di, ROW_LENGTH+66		; Player score
	stosw

    ;--poke cpu score--;
    mov al, byte [cpu_score]
    mov di, ROW_LENGTH+90
    stosw

    ;--get keyboard input--;
	;; Get Player input
    call os_check_for_key
	cmp ax, 0
    je move_cpu_up		; No key entered, don't check, move on

	cmp ah, KEY_UP		; Check what key user entered...
	je move_paddle_up
	cmp ah, KEY_DOWN
	je move_paddle_down
    cmp al, ESC
	je end_game

	jmp move_cpu_up		        ; unmapped key pressed

	;--Move player paddle up--;
	move_paddle_up:
	    ; empty keyboard buffer if arrow key held down
        .empty_buffer:
            call os_check_for_key
            cmp ax, 0
            jne .empty_buffer

		cmp word [player_row], 1; check if player paddle is at top
        je move_cpu_up
        dec word [player_row]	; Move 1 row up
		jmp move_cpu_up

	;--Move player paddle down--;
	move_paddle_down:
	    ; empty keyboard buffer if arrow key held down
        .empty_buffer:
            call os_check_for_key
            cmp ax, 0
            jne .empty_buffer

        ;--check if player paddle is at bottom of screen
		cmp word [player_row], SCREEN_HEIGHT - PADDLE_HEIGHT
		jg move_cpu_up								; Yes, don't move
		inc word [player_row]						; No, can move 1 row down
		jmp move_cpu_up

	;--Move CPU paddle--;
	move_cpu_up:
		;; CPU AI, Only move cpu every cpu_ai # of game loop cycles
		mov bl, [cpu_ai]        ; get cpu itelligence level
		cmp [cpu_delay], bl		; Did we reach the itelligence level of cycles?
		jl inc_cpu_delay
		mov byte [cpu_delay], 0
		jmp move_ball

		inc_cpu_delay:
			inc byte [cpu_delay]

		mov bx, [cpu_row]
		cmp bx, [ball_row]		; Is top of CPU paddle at or above the ball?
		jl move_cpu_down	    ; Yes, move on
        cmp word [cpu_row], 1
        je move_ball
		dec word [cpu_row]		; No, move cpu up
		jmp move_ball

	move_cpu_down:
		add bx, PADDLE_HEIGHT-1
		cmp bx, [ball_row]		; Is bottom of CPU paddle at or below the ball?
		jg move_ball		    ; Yes, move on
		cmp bx, 23			    ; No, is bottom of cpu at bottom of screen?
		je move_ball		    ; Yes, move on
		inc word [cpu_row]		; No, move cpu down one row

	;--Move Ball--;
	move_ball:
		;--poke ball to screen memory--;
		imul di, [ball_row], ROW_LENGTH
		add di, [ball_column]
		mov word [es:di], 0xE020		; Green bg, black fg

		mov bl, [ball_dir_column]		; Ball column position change
		add [ball_column], bl
		mov bl, [ball_dir_row]		    ; Ball row position change
		add [ball_row], bl

	;--Check if ball hits paddles or screen limits--;
	check_hit_top_or_bottom:
		mov cx, [ball_row]
        cmp cx, 1
		jle reverse_ball_row	; If ball hit top of screen
		cmp cx, 23				; Did ball hit bottom of screen
		jne check_hit_player

	reverse_ball_row:
		neg byte [ball_dir_row]
        jmp end_hit_checks

	check_hit_player:
		cmp word [ball_column], PLAYER_COLUMN+2	; Is ball at same position as player paddle?
		jne check_hit_cpu			            ; No, move on
		mov bx, [player_row]
		cmp bx, [ball_row]				; Is top of player paddle at or above the ball?
		jg check_hit_cpu			    ; No player did not hit ball
		add bx, PADDLE_HEIGHT		    ; Check if hit bottom of player paddle
		cmp bx, [ball_row]
		jl check_hit_cpu			    ; Bottom of paddle is above ball no hit
		jmp reverse_ball_column			; Otherwise hit ball, reverse column direction

	check_hit_cpu:
		cmp word [ball_column], CPU_COLUMN-2 ; Is ball at same position as CPU paddle?
		jne check_hit_left			         ; No see if ball hit screen limit
        mov bx, [cpu_row]
		cmp bx, [ball_row]				     ; Is top of cpu paddle <= the ball
		jg check_hit_left			         ; No see if ball hit screen limit
		add bx, PADDLE_HEIGHT
		cmp bx, [ball_row]				     ; Is bottom of cpu paddle >= the ball
		jl check_hit_left			         ; No check screen limit

	reverse_ball_column:
		neg byte [ball_dir_column]			; Yes, hit player/cpu,reverse column direction

	check_hit_left:
		cmp word [ball_column], 0			; Did ball hit/pass left side of screen?
		jg check_hit_right			; No, move on
		inc byte [cpu_score]
		;mov bx, PLAYERBALLSTARTX	; No, reset ball for next round
		jmp reset_ball

	check_hit_right:
		cmp word [ball_column], ROW_LENGTH	; Did ball hit/pass right side of screen?
		jl end_hit_checks		            ; No, move on
		inc byte [player_score]
        inc byte [intelligence]
		mov bx, BALL_START_COLUMN 		    ; No, reset ball for next round

	;--Reset Ball for next play--;
	reset_ball:
		cmp byte [cpu_score], GAME_WON	    ; Did CPU win the game?
		je game_lost
		cmp byte [player_score], GAME_WON		; Did player win game?
		je game_won

		;--Check/Change cpu intelligence for every player point scored
		imul cx, [intelligence], CPU_INTELLIGENCE
		jcxz reset_ball_random
		mov [cpu_ai], cx


	reset_ball_random:
        mov ax, 4
        mov bx, 22
        call os_get_random
		mov word [ball_row], cx
		mov word [ball_column], BALL_START_COLUMN

	end_hit_checks:
        mov ax, 1       ; slow game play down
        call os_pause

jmp game_loop

reset_game:
    mov word [player_row], 10
    mov word [cpu_row], 10
    mov word [ball_column], 66
    mov word [ball_row], 7
    mov word [ball_dir_column], -2
    mov word [ball_dir_row], 1
    mov byte [player_score], 0x30
    mov byte [cpu_score], 0x30
    mov byte [intelligence], 0
    mov byte [cpu_ai], 1
    jmp game_loop

game_won:
	;--poke player score--;
	mov ah, 0x02
    mov al, byte [player_score]
	mov di, ROW_LENGTH+66		; Player score
	stosw

    mov cx, 4
    mov si, win_msg             ; move addr of message into ds:si
    mov di, 162                 ; move screen into es:di
    rep movsw                   ; move word from si to di inc both by word

    jmp play_again


game_lost:
    ;--poke cpu score--;
    mov ah, 0x02
    mov al, byte [cpu_score]
    mov di, ROW_LENGTH+90
    stosw

    mov cx, 4
    mov si, lose_msg            ; move addr of message into ds:si
    mov di, 162                 ; move screen into es:di
    rep movsw                   ; move word from si to di inc both by word


play_again:
    mov cx, 25
    mov si, play_msg
    mov di, 322
    rep movsw

    call os_wait_for_key
    cmp al, ESC
    je end_game
    cmp ah, KEY_Y
    je reset_game
    cmp ah, KEY_Q
    je end_game
    jmp play_again

end_game:
;---restore ES----
    mov ax, 0x2000
    mov es, ax
    call os_clear_screen
    call os_show_cursor
    ret
;-----END PROGRAM-----

;==============================================;
;------------DATA------------;
;----------VARIABLES---------;
screen_color:       dw 0xF020
player_row:         dw 10	; Start player row position
cpu_row:	        dw 10	; Start cpu row position
ball_column:	    dw 78	; Starting ball column position
ball_row:	        dw 12   ; Starting ball row position
ball_dir_column:    db -2	; Ball column direction
ball_dir_row:       db 1	; Ball row direction
player_score:       db 0x30 ; 0 in ascii
cpu_score:	        db 0x30 ; 0 in ascii
cpu_delay:	        db 0	; # of cycles before CPU allowed to move
cpu_ai:             db 1	; CPU AI level
intelligence:       db 0    ;

;---------------------MESSAGES----------------------;
win_msg     dw   0x0257,0x0249,0x024E,0x0221        ; WIN!
lose_msg    dw   0x044C,0x044F,0x0453,0x0445        ; LOSE
play_msg    dw   0x0250,0x024C,0x0241,0x0259,0x0220 ; PLAY
            dw   0x0241,0x0247,0x0241,0x0249,0x024E ; AGAIN
            dw   0x0228,0x0279,0x023D,0x0259,0x0245 ; ( y=YES
            dw   0x0253,0x0220,0x0271,0x023D,0x0251 ; q=QUIT)?
            dw   0x0255,0x0249,0x0254,0x0229,0x023F
welcome_msg db  '******Welcome to Retro Pong Game******',0
line1       db  'Play against the computer using the up',0
line2       db  'down arrow keys, score 7 points to win!',0
