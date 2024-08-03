;Binary file editor for KIS_OS 16 bit OS
;
;Program will load file if given on cmdline
;or picked in file chooser or view and edit
;memory starting at 0000h -> FFFFh
;
;FileName: editbin.bin
;
;Updated: 12/05/2016
;     BY: John Endler
;Updated: 01/04/2017 To add box drawing around dump
;Updated: 01/03/2022 to run under MikeOS
;===============================================
    BITS 16
    %include "mikedev.inc"
    ORG 32768

; memory start and end
MEM_START   equ 0x0000  ; start of memory
MEM_FILE    equ 0x9000  ; start of memory file is loaded
MEM_END     equ 0xffff  ; end of memory

;arrow keys pageup pagedn
RIGHT   equ 0x4D
LEFT    equ 0x4B
UP      equ 0x48
DOWN    equ 0x50
PGDN    equ 0x51
PGUP    equ 0x49
RKEY    equ 0x72
F2      equ 0x3C00


RED_ON_BLACK       equ 00000100b
GREEN_ON_BLACK     equ 00000010b
BLACK_ON_YELLOW    equ 11100000b

org 0x8000   ; addr binary will be loaded 
             ; into memory by kernel @ 32768
;==============================================================
;               CODE SECTION MAIN PROGRAM START
;==============================================================


_start:
   ;open file from cmdline

	cmp si,0				; Check for cmdline filename
	je .no_file_cmdline

    mov al, 0x20            ; space as separator of cmd line file 
	call os_string_tokenize	; If so, get it from params

	mov di,filename		    ; Save filename
	call os_string_copy
    jmp open_file

.no_file_cmdline:
	mov ax, title_msg		; Set up screen
	mov bx, footer_select_msg
	mov cx, GREEN_ON_BLACK
	call os_draw_background
	call os_file_selector   ; Get filename to load
	jnc near file_chosen
	;call os_clear_screen	; Quit if Esc pressed in file selector
	;ret
    mov si,memory_msg
    mov di,filename
    call os_string_copy
    mov word[mem_location],MEM_START
    jmp main_start

file_chosen:
	mov si,ax				; Save filename
	mov di,filename
	call os_string_copy

open_file:
	mov ax,si
	mov cx,MEM_FILE             ; 0x9000, 36864
	call os_load_file		    ; Load the file 4K after the program start point
	jnc file_load_success       ; bx holds filesize in bytes

	mov ax,file_load_fail_msg	; If fail, show message and exit
	mov bx,0
	mov cx,0
	mov dx,0
	call os_dialog_box
	call os_clear_screen
	ret				        	; Back to the OS

file_load_success:
    mov word[filesize],bx       ; bx holds filesize in bytes
    mov word[mem_location],MEM_FILE
    
main_start:
	mov ax, title_msg		    ; Set up screen
	mov bx, footer_msg
	mov cx, WHITE_ON_BLACK
	call os_draw_background
    call HeaderFooter           ;print top and bottom of screen
    call ZeroCount
    call GetNsectors            ;get total number of 512byte sectors
.dump:   
    call clear_section
    call DisplayIt              ;else display first 256bytes of file
    call highlite_control
    call os_hide_cursor
    call key_board_handler  ;now handle keyboard input will ret when on quit
    call os_show_cursor
.disk_error:
    call os_clear_screen
    
    ret
    
memory_msg db 'Memory',0

;============================================================
;               END OF MAIN
;============================================================
;               PROCEDURES START HERE
;============================================================
;=============================================
;Print our header and footer of dump display
;
;---------------------------------
HeaderFooter:
    pusha
    mov dx,0101h
    call os_move_cursor               ;move cursor to row 1 col 1
    mov si,sector_hdr_msg             ; SECTOR: 0   
    call os_print_string

 ;display name of file we are editing 
    mov dx,0118h
    call os_move_cursor
    mov si,editmsg
    call os_print_string
    mov si,filename
    call os_print_string

; draw outline box to contain dump of sector
    mov dx,0200h            ; start row-col
    mov bx,1247h            ; height-width of box
    call draw_box

    mov dx,0205h
    call os_move_cursor
    mov cl,1
    mov al,0xcb
    call print_nchars

    mov dx,0237h
    call os_move_cursor
    call print_nchars

    mov dx,1505h
    call os_move_cursor
    mov al,0xca
    call print_nchars

    mov dx,1537h
    call os_move_cursor
    call print_nchars

    mov dx,0300h
    call os_move_cursor
    mov si,header
    call os_print_string
    
    mov dx,1600h                           ;reposition to bottom of edit screen
    call os_move_cursor
    mov si,footer
    call os_print_string

    popa
    ret
sector_hdr_msg:   db " SECTOR: 0",0
editmsg:          db "Editing: ",0


header:  db 0xba,"0000",0xba
         db " 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F "
         db 0xba,"0123456789ABCDEF",0xba,13,10
         db 0xc7
         times 4 db 0xc4
         db 0xd7
         times 49 db 0xc4
         db 0xd7
         times 16 db 0xc4
         db 0xb6,13,10,0

footer:  db " [r]Replace byte   [F2]Save changes",0

;======================================================================
;Get number of 512byte sectors in file
;
GetNsectors:
    push bx

    xor dx,dx                ;clear for div remainder
    mov ax,[filesize]        ;get file size for div
    mov bx,256               ;1/2 sector=256 sectors=512 bytes 
    div bx                   ;div eax by 256
    dec ax                   ;count sectors from 0
    test dx,dx               ;see if carry means last sectors is smaller then 256bytes
    Jz .no_carry
    inc ax                   ;if last sectors is less than 256 add 1
.no_carry:
    mov word[sectors],ax    ;save number of 256byte sectors in file
   
    pop bx
    ret
;============================================================
;               CLEAR BUFFERS 
;============================================================
;===========================================================
;Clear Line Count 
;
;This will clear line count to zeros after or File
;reads
;
;Receives:nothing
;Returns:nothing
;Sets: linect in data section back to |0000|
;----------------------------------------------------------
ZeroCount:
    push di
    push cx

    mov cx,2            ;need to replace 8bytes
    mov di,displaylinect;at this location
    inc di              ;move to first digit after |
    mov ax,'00'         ;place '00' 
rep stosw               ;store al in linect inc di dec cx

    pop cx
    pop di
    ret
; **********************************************************
; clear portion
; **********************************************************
clear_section:
    pusha

; hex section 
    mov ah,6        ; scroll up
    mov al,16       ; 16 lines
    mov bh,2        ; Green
    mov ch,05       ; start row
    mov cl,07       ; start col
    mov dh,14h      ; end row
    mov dl,35h      ; end col
    int 0x10
; asc section
    mov bh,3        ; Cyan
    mov ch,05h
    mov cl,38h
    mov dh,14h
    mov dl,47h
    int 0x10
    popa
    ret
;============================================================
;Handle keyboard events
;
key_board_handler:

.key_loop:
    call os_wait_for_key
    cmp ah,RIGHT
    je .right
    cmp ah,LEFT
    je .left
    cmp ah,UP
    je .up
    cmp ah,DOWN
    je .down
    cmp ah,PGDN
    je .pgdn
    cmp ah,PGUP
    je .pgup
    cmp al, RKEY
    je .enter
    cmp ax,F2      
    je .save
    cmp al,KEY_ESC
    je .exit
    jmp .key_loop

.right:
    mov ax,word[hex_old]
    cmp ax,1434h            ; check for last byte in 256 byte display
    je .key_loop            ; if on last byte no move
    cmp al,34h              ; check for end of row
    jne .not_end_row
    inc ah                  ; add one to row
    mov byte[hex_new+1],ah  ; things in memory are reverse
    mov byte[hex_new],07h   ; ah holds new row start col 7
    mov byte[asc_new+1],ah  ;
    mov byte[asc_new],38h   ; start of ascii col 38h
    inc word[hlitebyte]
    jmp .move_highlite
.not_end_row:
    add word[hex_new],0003h ; if not end of row just move right
    inc word[asc_new]
    inc word[hlitebyte]
    jmp .move_highlite
    
.left:
    mov ax,word[hex_old]
    cmp ax,0507h            ; check for first byte in 256 byte display
    je .key_loop            ; if we are at first byte do not move
    cmp al,07h              ; see if we are in first col
    jne .not_begin_row
    dec ah                  ; subtract one off row to move up one row
    mov byte[hex_new+1],ah  ; row
    mov byte[hex_new],34h   ; last col in row
    mov byte[asc_new+1],ah
    mov byte[asc_new],47h   ; last col in ascii dump
    dec word[hlitebyte]
    jmp .move_highlite
.not_begin_row:
    sub word[hex_new],0003h ; we just need to move back one col
    dec word[asc_new]
    dec word[hlitebyte]
    jmp .move_highlite

.up:
    mov ax,word[hex_old]
    cmp ah,05h              ; see if we are at top row of display
    je .key_loop            ; then don't move
    dec ah                  ; move up one row
    mov byte[hex_new+1],ah  ; new row
    mov byte[asc_new+1],ah  ; col stays the same
    sub word[hlitebyte],16
    jmp .move_highlite

.down:
    mov ax,word[hex_old]
    cmp ah,14h              ; bottom row of display
    je .key_loop
    inc ah
    mov byte[hex_new+1],ah  ; new row
    mov byte[asc_new+1],ah  ; col stays the same
    add word[hlitebyte],16
.move_highlite:
    call update_display_hlitebyte
    call UpdateBinary
    call highlite_control
    jmp .key_loop
.pgup:
    cmp word[offsetbyte],0000h
    je .key_loop
    sub word[offsetbyte],256
    sub word[count],512
    dec word[sectornum]
    call ZeroCount
    call clear_section
    call DisplayIt
    mov word[hex_new],0507h
    mov word[asc_new],0538h
    call highlite_control
    jmp .key_loop
.pgdn:
    mov ax, word[sectors]
    cmp word[sectornum], ax
    je .key_loop
    add word[offsetbyte],256
    inc word[sectornum]
    call clear_section
    call DisplayIt
    mov word[hex_new],0507h
    mov word[asc_new],0538h
    call highlite_control
    jmp .key_loop
.enter:
    call edit_byte
    jmp .key_loop
.save:
    call save_changes
    jmp .key_loop
.exit:
    ret

;============================================================
;will handle  highlite on screen for HEX and ASCII location
; IN: nothing
;OUT: writes hex_old asc_old hex_attrib asc_attrib
;
;READS: hex_old, asc_old, hex_new, asc_new
;       hex_attrib asc_attrib
;
highlite_control:
    pusha

;clear old hex highlite
    mov di,word[hex_old]   ;last cursor position
    mov bl,byte[hex_attrib];previous screen Attribute
    mov si,2
.hexclear:    
    mov dx,di              ;hex position
    call os_move_cursor
    mov ah,08              ;read char attrib
    mov bh,0               ;page
    int 0x10               ;returns ah=attrib, al=char
;now write new attrib using same char
    mov ah,09              ;write char attrib
    mov bh,0               ;page
    mov cx,1               ;number of chars
    int 0x10
    inc di                 ;next char
    dec si                 ;one less char
    cmp si,0
    jne .hexclear

;clear old ascii highlite
    mov bl,byte[asc_attrib];previous ascii attribute
    mov dx,word[asc_old]   ;last cursor position save
    call os_move_cursor
    mov ah,08
    mov bh,0
    int 0x10
    mov ah,09
    mov bh,0
    mov cx,1
    int 0x10

;now highlite new byte hex ascii
    mov di,word[hex_new]   ; new hex position
    mov word[hex_old],di   ; save to old hex for next move
    mov bl,BLACK_ON_YELLOW
    mov si,2
.hex_highlite:    
    mov dx,di              ;hex position
    call os_move_cursor
    mov ah,08              ;read char attrib
    mov bh,0               ;page
    int 0x10               ;returns ah=attrib, al=char
    mov byte[hex_attrib],ah;save screen attribute

;now write new attrib using same char
    mov ah,09           ;write char attrib
    mov bh,0            ;page
    mov cx,1            ;number of chars
    int 0x10
    inc di              ;next char
    dec si              ;one less char
    cmp si,0
    jne .hex_highlite

;now do ascii
    mov dx,word[asc_new]
    mov word[asc_old],dx
    call os_move_cursor
    mov ah,08
    mov bh,0
    int 0x10
    mov byte[asc_attrib],ah ; save old attribute
    mov ah,09
    mov bh,0
    mov cx,1
    int 0x10

    popa
    ret
;============================================================
edit_byte:
    pusha
    
;clear old hex highlite
    mov dx,word[hex_old]   ;last cursor position
    mov bl,RED_ON_BLACK    ;set edit screen Attribute
    call os_move_cursor
;now clear hex byte
    mov ah,09              ;write char attrib
    mov al,' '
    mov bh,0               ;page
    mov cx,2               ;number of chars
    int 0x10
    call os_move_cursor    ;move cursor for edit
    call os_show_cursor    ;show cursor
    mov ax,byte_input      ;save new bytes here
    call os_input_string
    call os_string_uppercase ;make upper case
    call os_move_cursor    ;move cursor for diplay of new byte
    mov si,byte_input
    call os_print_string   ;show new byte
    mov byte[hex_attrib],RED_ON_BLACK
    mov byte[asc_attrib],RED_ON_BLACK
    mov ax,byte_input        ;convert new hex bytes 
    call HexToByte           ;to byte format for memory
    mov di,word[mem_location];save it here
    add di,word[hlitebyte]   ;plus offset into memory
    stosb

;change ascii char displayed    
    mov dx,word[asc_old]
    call os_move_cursor
    dec di
    mov al,byte[di]
	cmp al, 20h	           ;ascii space lower part of table
	jb .dot		           ;if below save a '.'
	cmp al, 7Dh	           ;top of printable chars
	ja .dot		           ;if above save a '.' 
    jmp .show_char
    
.dot:
	mov al, 2Eh		            ;save '.' to editascii
.show_char:
    mov ah,0Eh
    int 0x10

    mov dx,word[hex_old]
    call os_move_cursor
    call os_hide_cursor
    call highlite_control
    call UpdateBinary

    popa
    ret

;========================================================
;save_changes
;
;save changes to file
; IN: nothing
;OUT: changes to file
save_changes:
    pusha

    mov ax,filename			; Delete the file if it already exists
	call os_remove_file
    
	mov word cx,[filesize]
	mov bx,36864
	call os_write_file

	jc .failure				    ; If we couldn't save file...

    mov dx,1701h
    call os_move_cursor
    mov si,.save_msg
    call os_print_string
    call os_wait_for_key
    mov dx,1701h
    call clear_to_eol
    mov dx,word[hex_old]
    call os_move_cursor

    popa
    ret

.failure:

    mov dx,1701h
    call os_move_cursor
    mov si,.save_fail_msg
    call os_print_string
    call os_wait_for_key
    mov dx,1701h
    call clear_to_eol
    mov dx,word[hex_old]
    call os_move_cursor

    popa
    ret
.save_fail_msg: db '[!]File save Failed... Press any key to continue...',0
.save_msg:      db '[!]File saved... Press any key to continue...',0

;========================================================
;               CONVERSION PROCEDURES
;========================================================
;===============================================
;Hex to byte conversion procedure
;
;Receive: Hex number addr to convert in AX
;Returns: converted input in AL
;
;Sets: carry flag if bad input
;
HexToByte:
    push si
    push cx
    

    cld
    mov si,ax     ;input holds bytes to convert
    mov cx,2      ;convert to bytes
.hextobyte:
    lodsb           ;load first hex digit to convert from input
    cmp al,'0'      ;see if it is digit 0-9
    jb  .badhex
    cmp al,'9'
    ja  .tryhex
    sub al,48       ;make it a hex digit 0-9 converts to nibble
    jmp .done
.tryhex:
    cmp al,'A'      ;check if it is hex A-F
    jb  .badhex
    cmp al,'F'
    ja  .islower
    sub al,55       ;'A'-10 make it a hex digit 10-15,0xah-0xfh converts to nibble 
    jmp .done
.islower:
    sub al,20h      ;make upper case -0x20 or 32 decimal
    jmp .tryhex     ;test to see if we have uppercase letter A-F now
.badhex:
    stc             ;set carry flag for bad input
    jmp .ret
.done:
    cmp cx,2       ;see if this is first byte
    jne .last
    push cx        ;save for loop
    mov cx,4        ;multiply by 16
    shl al,cl
    mov ah,al       ;save the nibble
    pop cx
    loop .hextobyte ;do 2nd byte
.last:
    or  al,ah       ;combine nibbles to return byte in al
    clc             ;clear carry flag for good conversion
.ret:
    pop cx
    pop si
    ret
;=================================================
;Convert byte from file to hex digit
;
; IN: BX offset into 16 bytes to display
;Out: displayhex     Buffer   16bytes
;
;Uses: hextable for conversion
;
ByteToHex:
    push cx
    push di
    push bx

    cld                           ;clear direction flag for stosb
	mov di,displayhex             ;save converted hex here
	inc di 	                      ;mov past first space
	xor cx, cx                    ;start ptr at zero first byte
    mov si,word[mem_location]
.loop:
	movzx ax, byte[si+bx]      ;copy byte zero extended
	push ax    	                  ;save byte in eax for conversion
	shr al, 4		               ;get top 4 bits
    push bx
    mov bx,ax
	mov al,[hextable+bx]	       ;convert to hex
	stosb			               ;save top 4 bits from al to edi inc edi
    pop bx
	pop ax			               ;restore saved byte
	and ax, 000Fh	               ;remove top 4 bits
    push bx
    mov bx,ax
	mov al,[hextable+bx]           ;convert to hex
	stosb			               ;save lower nibble from al to edi inc edi
    pop bx
	inc di			               ;mov past space in edithex line
	inc bx			               ;mov ptr into file for next byte
    inc cx
	cmp cx, 16                     ;have we done 16 bytes 1 line on screen
	jne .loop	

    pop bx
	pop di
    pop cx
	ret	

;=================================================
;On Entry AX holds word to convert to hex digits
;
;Input:  word to covert in AX, Location to store
;        it in DI
;Output: Print DI to screen
;
;Uses: hextable for conversion
;
WordToHex:
    pusha

    push di
    cld                   ;clear direction flag for stosb
    inc di                ;move passed | char in linect
	mov cx,12             ;start at top 4 bits in eax
.get_nibbles:
    push ax               ;save dword in eax for conversion
	shr ax,cl 		      ;get 4 bits
    and ax,000Fh          ;use lower 4 bits
	mov bx,ax
    mov al,[hextable+bx]  ;convert to hex
	stosb			      ;save byte from al to edi inc edi
	pop ax			      ;restore saved dword
    sub cx,4              ;get next 4 bits      
    test cx,cx            ;are we on last 4 bits
    jnz .get_nibbles

    and ax,000Fh          ;get last 4 bits
    mov bx,ax
    mov al,[hextable+bx]
    stosb
    pop si                ;place saved di into si
    call os_print_string

    popa
	ret	

;==================================================
;Convert to binary
;
;Procedure will show binary of highlited Byte
;
;Uses: offsetbyte for location in editbuffer
;Uses: hextable & bintable for conversion
;Receive: nothing
;Returns: nothing
;
UpdateBinary:
    push bx
    push di
    push si

    mov bx,[hlitebyte]              ;where is phantom cursor
    mov di,bin                    ;save binary here for display
    mov si,word[mem_location]
    inc di                        ;inc to move past | char
    movzx ax,byte[si+bx]       ;get byte at this location to convert

    ;convert to HEX

	push ax    	                  ;save byte in eax for conversion
	shr al, 4		               ;get top 4 bits
    push bx
    mov bx,ax
	mov al, [hextable+bx]	       ;convert to hex
    pop bx
    cmp al,65                      ;see if letter A-F
    jge .letter
    sub al,48                      ;is digit 1-9
    jmp .shift
.letter:
    sub al,55                      ;converting letter A-F
.shift:
    shl al,2                       ;muliply by 4 for table lookup
    mov si,bintable               ;conversion table
    add si,ax                    ;point to converted binary
    mov cx,4                      ;mov this nibble 
    rep movsb

	pop ax			               ;restore saved byte for secound nibble
	and ax, 000Fh    	           ;remove top 4 bits
    push bx
    mov bx,ax
	mov al, [hextable+bx]	       ;convert to hex
    pop bx
    cmp al,65                      ;from here down same conversion as above  
    jge .letter1
    sub al,48
    jmp .shift1
.letter1:
    sub al,55
.shift1:
    shl al,2
    mov si,bintable
    add si,ax
    mov cx,4
    rep movsb
    
    mov dx,1636h                  ;place binary display here
    call os_move_cursor
    mov si,binout
    call os_print_string          ;show binary
    
    pop si 
    pop di
    pop bx
    ret
;===============================================
;Update display count
;
; IN: nothing
;OUT: nothing
;
;Prints: hlitebyte in upper left of dump
;
update_display_hlitebyte:
    pusha

    mov dx,0300h          ;repostion cursor for byte editing
    call os_move_cursor
    mov ax,word[hlitebyte]
    mov di,displayhlitebyte
    call WordToHex        ;will print what is passed in di  

    popa
    ret
;===============================================
;Convert string to word
;
;Receives: Pointer to string in SI
; Returns: Word in AX
;
;===============================================
StrToWord:
    push di
    push bx

    xor cx,cx           ;count of bytes to convert
.findend:
    cmp byte[si],0       ;see if NULL term string
    je  .endstr
    cmp byte[si],0ah     ;newline end of string
    je  .endstr
    inc si
    inc cx
    jmp .findend
.endstr:
    dec si               
    mov di,jumptable     ;used for multiplying
    xor dx,dx
    xor bx,bx
    xor ax,ax
.convert:
    mov al,byte[si]      ;get ascii byte
    sub al,30h           ;convert to number
    mul word[di]         ;multiply 1, 10, 100, etc.. 
    add bx,ax            ;add to bx
    add di,2             ;point to next multiple in jumptable
    dec si               ;convert next ascii char
    xor ax,ax            ;clear for next conversion
    loop .convert
    
    mov ax,bx            ;move result to eax for return of Dword

    pop bx
    pop di
    ret

;==============================================
;Convert Word To String
;
;Receives: nothing
; Returns: nothing
;
;Sets: sectorct
;
;==============================================
WordToStr:
    pusha                 ;use stack to save converted

;clear sectorct
    mov cx,4
    mov al,0
    mov di,sectorct
    rep stosb

    mov ax,word[sectornum]  ;get number of 256 byte sectors
    xor si,si               ;use to count converted digits
.loop:                      ;convert to printable numbers 
    xor dx,dx               ;clear for div
    mov bx,10
    div bx                  ;div eax by 10 rem in edx
    add dx,48               ;makeit ascii digit
    push dx                 ;save to stack
    inc si
    test ax,ax              ;see if anymore digits
    jz .done
    jmp .loop

;Done with conversion     
.done:
    mov cx,si              ;get number of digits we saved on stack for loop 
    mov di,sectorct        ;save here
.@1:
    pop ax                 ;get first digit
    stosb                  ;move to sectormsg, inc edi
    loop .@1
       
    popa
    ret
    
;====================================================
;
;-----------------------------------------------------
;               CONVERSION TABLES
;-----------------------------------------------------
    jumptable:  dw 0001
                dw 0010
                dw 0100
                dw 1000
;binary table used to convert hex to binary    
    bintable:   db '0000000100100011'
                db '0100010101100111'
                db '1000100110101011'
                db '1100110111101111'

;hex table used to convert nibble to hex digit 	
	hextable:  db '0123456789ABCDEF'

;===========================================================
;               DISPLAY PROCEDURES
;===========================================================
;======================================================
;Fill editascii  buffer
;
;Need to save index count in BX for call to 
;DumpBytes
;
; IN: BX 16 byte line offset to convert
;OUT: index
;
FillAscii:
    pusha

    cld                         ;clear direction flag for stosb
	mov di, displayascii        ;store converted ascii here
    mov si,word[mem_location]
	inc di 		                ;mov past | char
	xor cx, cx	            	;clear for index into buffer 
.loop:
	movzx ax, byte[si+bx]       ;get byte read from file
	cmp ax, 20h		            ;ascii space lower part of table
	jb .dot			            ;if below save a '.'
	cmp ax, 7Dh		            ;top of printable chars
	ja .dot			            ;if above save a '.' 
	stosb			            ;save byte in al to editascii inc edi
	jmp .next		            ;get next byte in buffer

.dot:
	mov ax, 2Eh		            ;save '.' to editascii
	stosb		                ;save byte in al to editascii inc edi
.next:
    inc bx                      ;point to next byte in buffer
	inc cx			                	
    cmp cx, 16	                ;are we done
	jne .loop	                ;continue until end	

	mov word[index],bx          ;save index into display

    popa
	ret

;===================================================
;DisplayIt the 256 byte dump
;on entry editbuffer is filled from file read
;
;Calls: ByteToHex, FillAscii, WordToHex, DumpBytes,
;       ZeroCount
;Uses: cx-for loop count of 16byte lines
;      bx-for index into editbuffer
;      var index, var count, var read
;
DisplayIt:
    pusha

    mov dx,0500h
    call os_move_cursor   ;position cursor for dump
    
    mov bx,word[offsetbyte]
    mov word[hlitebyte],bx
    mov cx,16             ;16 lines of 16bytes totals 256bytes displayed

.@dump:
	call ByteToHex		  ;convert data in buffer to hex
	call FillAscii		  ;fill ascii buffer 
   
    mov di,displaylinect
    mov ax,word [count]   ;print the byte count line numbers
    call WordToHex        ;will print byte count before each line
    mov si,displayhex
    call os_print_string

    add word [count],16   ;add 16 for every line done
    mov bx,word[index]    ;restore index into editbuffer
    loop .@dump
    call update_display_hlitebyte
    call UpdateBinary     ;show binary byte
    mov dx,010ah
    call os_move_cursor
    call WordToStr
    mov si,sectorct       ;show sector we are in
    call os_print_string
    mov si,clr8msg
    call os_print_string
    mov dx,1733h
    call os_move_cursor

    popa
    ret
;========================================================
; IN: DX=DL-Col, DH-Row
;OUT: nothing
clear_to_eol:
    pusha

    mov ah,6
    xor al,al                 ;clear
    mov ch,dh                 ;all same line
    mov cl,dl                 ;start at cursor position
    mov dl,79                 ;stop at EOL
    mov bh,7                  ;normal attribute
    int 0x10
    
    popa
    ret
;-------------------------------------------------------------------
; draw_box -- Draw a double line box to screen
;
; IN: DX = start position of box ROW-COL, BX = size Height-Width
;OUT: nothing

draw_box:
    pusha

    xor cx,cx
    call os_move_cursor ; move to start of top left of box
; top of box
    mov cl,1            ; print 1 char
    mov al,0xc9         ; top left
    call print_nchars
    mov cl,bl           ; width of box
    mov al,0xcd         ; horz dbl line
    call print_nchars
    mov al,0xbb         ; top right 
    mov cl,1
    call print_nchars

; now print sides of box
.sides:
    inc dh              ; next row
    call os_move_cursor
    mov cl,1            ; 1 char
    mov al,0xba         ; left of box side char dbl vert line
    call print_nchars
    mov cl,bl           ; width of box
    mov al,20h          ; print spaces
    call print_nchars
    mov cl,1            ; 1 char 
    mov al,0xba         ; right side of box vert dbl line
    call print_nchars
    dec bh              ; reduce height of box by 1
    cmp bh,0            ; see if we are done
    jne .sides

; bottom of box    
    inc dh              ; now position 1 row down
    call os_move_cursor
    mov cl,1
    mov al,0xc8         ; bottom left of box
    call print_nchars
    mov cl,bl           ; width of box
    mov al,0xcd         ; dbl horz line =
    call print_nchars
    mov cl,1
    mov al,0xbc         ; bottom right of box
    call print_nchars
    ;call os_print_newline

    popa
    ret
;-------------------------------------------------------------------
; print_nchars  -- print n number of characters to screen
; IN: AL = addr char CX = number of chars to print
;OUT: nothing
;
print_nchars:
    pusha

    mov ah,0x0E         ; int 10h teletype
.repeat:
    int 10h             ; print it
    loop .repeat        ; until CX is zero

    popa
    ret

;==========================================================
title_msg     db "Edit Binary Version 0.1.5 (c)2016 (KIS_OS)",0
footer_msg    db "[ESC]exit [DIR KEYS]navigate sector [PGDN]next sector [PGUP]prev sector",0
footer_select_msg db "Select file or [ESC] to exit",0


;hex values and ascii chars placed here for display
displayhex      db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
displayascii	db 0xba,"................",0xba,13,10,0

sectorct    db 0,0,0,0,0,0

clr8msg     db '     ',0

;store converted count here as ascii for display to screen 
displaylinect      db 0xba,'0000',0xba,0

displayhlitebyte   db 0xba,'0000',0xba,0

binout      db '  Binary='
   bin      db '[00000000]',13,10,0

file_load_fail_msg  db 'Failed to load file...',0

filename   times 32 db 0
byte_input times 3  db 0 ; hold byte input

hex_old    dw 0507h    ; track  hex highlite
asc_old    dw 0538h    ; track ascii highlite
hex_new    dw 0507h    ; track  hex highlite
asc_new    dw 0538h    ; track ascii highlite
hex_attrib db 02h      ; hold previous attribute
asc_attrib db 03h      ; hold previous attribute 

filesize   dw 0000h    ; hold file size
count      dw 0000h    ; word for line count left side of screen
sectors    dw 0000h    ; hold number of sectors in file
sectornum  dw 0000h    ; track sector we are editing
offsetbyte dw 0000h    ; track offsetbyte into file or memory
hlitebyte  dw 0000h    ; byte that highlite is on
index      dw 0000h    ; index used for dump 256 bytes to screen

mem_location dw MEM_START ; default memory start 
