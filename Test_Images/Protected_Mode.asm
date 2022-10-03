; Assemble with NASM as
;     nasm -f bin enterpm.asm -o enterpm.com

STACK32_TOP EQU 0x200000
CODE32_REL  EQU 0x110000
VIDEOMEM    EQU 0x0b8000

use16
; COM program CS=DS=SS
org 100h

    call check_pmode    ; Check if we are already in protected mode
                        ;    This may be the case if we are in a VM8086 task.
                        ;    EMM386 and other expanded memory manager often
                        ;    run DOS in a VM8086 task. DOS extenders will have
                        ;    the same effect

    jz not_prot_mode    ; If not in protected mode proceed to switch
    mov dx, in_pmode_str;    otherwise print an error and exit back to DOS
    mov ah, 0x9
    int 0x21            ; Print Error
    ret

not_prot_mode:
    call a20_on         ; Enable A20 gate (uses Fast method as proof of concept)
    cli

    ; Compute linear address of label gdt_start
    ; Using (segment << 4) + offset
    mov eax,cs          ; EAX = CS
    shl eax,4           ; EAX = (CS << 4)
    mov ebx,eax         ; Make a copy of (CS << 4)
    add [gdtr+2],eax    ; Add base linear address to gdt_start address
                        ;     in the gdtr
    lgdt [gdtr]         ; Load gdt

    ; Compute linear address of label code_32bit
    ; Using (segment << 4) + offset
    add ebx,code_32bit  ; EBX = (CS << 4) + code_32bit

    push dword 0x08     ; CS Selector
    push ebx            ; Linear offset of code_32bit
    mov bp, sp          ; m16:32 address on top of stack, point BP to it

    mov eax,cr0
    or eax,1
    mov cr0,eax         ; Set protected mode flag

    jmp dword far [bp]  ; Indirect m16:32 FAR jmp with
                        ;    m16:32 constructed at top of stack
                        ;    DWORD allows us to use a 32-bit offset in 16-bit code

; 16-bit functions that run in real mode

; Check if protected mode is enabled, effectively checkign if we are
; in in a VM8086 task. Set ZF to 0 if in protected mode

check_pmode:
    smsw ax             ; Get lower 16 bits of control register in AX
    test ax, 0x1        ; Test the PE bit (bit 0) and set ZF flag accordingly
    ret 

; Enable a20 (fast method). This may not work on all hardware
a20_on:
    cli
    in al, 0x92         ; Read System Control Port A
    test al, 0x02       ; Test current a20 value (bit 1)
    jnz .skipfa20       ; If already 1 skip a20 enable
    or al, 0x02         ; Set a20 bit (bit 1) to 1
    and al, 0xfe        ; Always write a zero to bit 0 to avoid
                        ;     a fast reset into real mode
    out 0x92, al        ; Enable a20
.skipfa20:
    sti
    ret

in_pmode_str: db "Processor already in protected mode - exiting",0x0a,0x0d,"$"

align 4
gdtr:
    dw gdt_end-gdt_start-1
    dd gdt_start

gdt_start:
    ; First entry is always the Null Descriptor
    dd 0
    dd 0

gdt_code:
    ; 4gb flat r/w/executable code descriptor
    dw 0xFFFF           ; limit low
    dw 0                ; base low
    db 0                ; base middle
    db 0b10011010       ; access
    db 0b11001111       ; granularity
    db 0                ; base high

gdt_data:
    ; 4gb flat r/w data descriptor
    dw 0xFFFF           ; limit low
    dw 0                ; base low
    db 0                ; base middle
    db 0b10010010       ; access
    db 0b11001111       ; granularity
    db 0                ; base high
gdt_end:

; Code that will run in 32-bit protected mode
; Align code to 4 byte boundary. code_32bit label is
; relative to the origin point 100h
align 4
code_32bit:
use32
; Set virtual memory address of pm code/data to CODE32_REL
; We will be relocating this section from low memory where DOS
; originally loaded it.
section protectedmode vstart=CODE32_REL, valign=4
start_32:
    cld                 ; Direction flag forward
    mov eax,0x10        ; 0x10 is flat selector for data
    mov ds,eax
    mov es,eax
    mov fs,eax
    mov gs,eax
    mov ss,eax
    mov esp,STACK32_TOP ; Should set ESP to a usable memory location
                        ; Stack will be grow down from this location

    mov edi,start_32    ; EDI = linear address where PM code will be copied
    mov esi,ebx         ; ESI = linear address of code_32bit
    mov ecx,PMSIZE_LONG ; ECX = number of DWORDs to copy
    rep movsd           ; Copy all code/data from code_32bit to CODE32_REL
    jmp 0x08:.relentry  ; Absolute jump to relocated code

.relentry:
    mov ah, 0x57        ; Attribute white on magenta

    ; Print a string to display
    mov esi,str         ; ESI = address of string to print
    mov edi,VIDEOMEM    ; EDI = base address of video memory
    call print_string_attr

    cli
endloop:
    hlt                 ; Halt CPU with infinite loop
    jmp endloop

print_string_attr:
    push ecx
    xor ecx,ecx         ; ECX = 0 current video offset
    jmp .loopentry
.printloop:
    mov [edi+ecx*2],ax  ; Copy attr and character to display
    inc ecx             ; Next word position
.loopentry:
    mov al,[esi+ecx]    ; Get next character to print
    test al,al
    jnz .printloop      ; If it's not NUL continue
.endprint:
    pop ecx
    ret

str: db "Protected Mode",0