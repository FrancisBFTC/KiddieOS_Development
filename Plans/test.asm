Vector:
  dw NameSystem
  dw Preparing
SIZE EQU ($ - Vector) / 2

NameSystem db "Bem-vindo ao RipyOS",0
Preparing db "Preparando o sistema ...",0

EffectInit:
    mov bl, 44
    xor ax, ax  ; AX = 0
    xor cx, cx  ; CX = 0
  Start0:
    push cx     ; Salva CX
    push ax     ; Salva AX
    start:
        mov dh, byte[CursorRaw]
        mov dl, byte[CursorCol]
        call MoveCursor
        pop ax ; restaure AX
        push bx
        mov bx, ax
        mov si, [Vector + bx]
        pop bx
        call PrintString
        push bx
        mov bl, [State]
        cmp bl, 0
        je Increment
        jmp Decrement
    Increment:
        pop bx
        inc bl
        call Waiting
        push ax
        cmp bl, 50
        jne start
        push bx
        mov bl, 1
        mov byte[State], bl
        pop bx
        jmp start
    Decrement:
        pop bx
        dec bl
        call Waiting
        push ax
        cmp bl, 44
        jne start
        push bx               
        mov bl, 0
        mov byte[State], bl
        mov bx, [Count]
        inc bx
        mov WORD[Count], bx
        cmp bx, 10 
        jne ReturnLoop
        jmp ReturnProg
    ReturnLoop:
        pop bx
        jmp start
    ReturnProg:
        pop bx
        pop ax
        pop cx
        add ax, 2
        inc cx
        cmp cx, SIZE
        jne Start0
ret

; DETALHE: CX é o contador de Strings em Vector e AX é o deslocamento da String. Logo, devemos empilhar/salvar CX e AX no Início sendo Start0, nós usamos AX em BX como deslocamento de SI (SI + 0) e sempre salvamos este "0" até o final do efeito. No final, recuperamos AX que é 0, e adicionamos +2, porque na próxima vez que voltar pra Start0, será salvo 2 e deslocado SI + 2 (BX = AX, SI + BX).