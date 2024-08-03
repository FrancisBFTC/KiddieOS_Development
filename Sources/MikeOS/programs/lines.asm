;===========================================
; file: lines.asm
;   By: John Endler
; Date: 11/02/2021
;
; Switch to VGA 320x200 256 color Mode
; Draw diagonal lines on screen directly
; to screen memory A000 using ES:DI....
;
; Change line drawing speed by pressing
; f key to speedup
; s key to slowdown
; c key to clear screen
; Escape key to exit program
;
;
; 256 color vga 320x200
;
; ES:DI(A000:0000)
;===========================================

%include "mikedev.inc"     ; change this line to use in MikesOS

;----Constants----;
S_KEY   equ   0x1F73      ; slow down pixel speed
F_KEY   equ   0x2166      ; speed up pixel speed
C_KEY   equ   0x2E63      ; clear screen
ESC_KEY equ   27


org 32768               ; load program after kernel


start:

;---Change to VGA mode 13h (320x200 256 color)---;
    mov ax, 0x13
    int 0x10

    ;--setup VRAM segment(ES:DI A000:0000)--;
    push 0xA000
    pop es

    mov cx, word [pixelSpeed]   ; set intial pixel speed

pixel_loop:
    imul di, word [pixelROW], 320 ; column(x=320) * row(y)
    add di, word [pixelCOL]       ; + x(column)
    mov ax, word [pixelColor]     ; pixel color
    stosb                         ; store byte es:di inc di

    ;--Update pixel location--;
    mov bx, word [pixelDirRow]    ; get pixel direction row (1 or -1)
    add word [pixelROW], bx       ; set new pixel row
    mov bx, word [pixelDirCol]    ; get pixel direction col (1 or -1)
    add word [pixelCOL], bx       ; set new pixel column

    ;--check if we are at screen edges--;
    check_edges:
        cmp word [pixelROW], 199  ; did we hit right side of screen
        je neg_row                ; if yes neg direction
        cmp word [pixelROW], 0    ; did we hit left side of screen
        jne check_col
        neg_row:
            neg word [pixelDirRow] ; change pixel direction row

    check_col:
        cmp word [pixelCOL], 319  ; did we hit bottom of screen
        je neg_col                ; if yes change direction
        cmp word [pixelCOL], 0    ; did we hit top of screen
        jne continue
        neg_col:
            neg word [pixelDirCol] ; change pixel direction column

        continue:
            ;---Check keyboard input---;
            call os_check_for_key
            cmp ax, S_KEY               ; slow pixel ?
            jne f_key
            cmp word [pixelSpeed], 5    ; do not go any slower than speed 5
            jle f_key
            sub word [pixelSpeed], 10

            f_key:
                cmp ax, F_KEY               ; speed up pixel
                jne c_key
                add word [pixelSpeed], 10
            c_key:
                cmp ax, C_KEY               ; clear screen
                je start;reset_screen
            cmp al, ESC_KEY
            je exit
    loop pixel_loop                 ; uses cx pixel speed for loop

   ;--Delay--;
    mov ax, 1                       ; slow down screen writing
    call os_pause

    ;--starting new pixel loop--;
    mov cx, word [pixelSpeed]       ; reset pixel speed for next loop
    cmp word [pixelColor], 0x00FF   ; are we at last color in 256 palete
    je reset_color                  ; if yes reset to first color
    inc word [pixelColor]           ; or increment to next color
    jmp pixel_loop
    reset_color:
        mov word [pixelColor], 0x0001 ; go to our start color in 256 palete
    jmp pixel_loop                    ; start pixel loop over

;-----Exiting lines program reset our ES register back
;     reset video mode back to text 80x25             -----;
 exit:
   ; push 0x2000
   ; pop es
   ; mov ax, 0x0003		; Set text output with certain attributes
   ; mov bx, 0			; to be bright, and not blinking
   ; int 10h

    jmp 0xffff:0
    ret



;-----------------DATA-------------------;
pixelROW    dw  0       ; row variable
pixelCOL    dw  0       ; column variable
pixelDirRow dw  1       ; direction row 1 or -1
pixelDirCol dw  1       ; direction col 1 or -1
pixelColor  dw  1       ; pixel color 0x01-0xFF
pixelSpeed  dw  25      ; pixel start speed
