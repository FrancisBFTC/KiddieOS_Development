[BITS 16]
[ORG 0x07C0]

	
call LoadSystem
jmp 0800h:0x0000

LoadSystem:
	mov ah, 02h
	mov al, 3
	mov ch, 0
	mov cl, 1
	mov dh, 0
	mov dl, 80h
	mov bx, 0800h
	mov es, bx
	mov bx, 0x0000
	int 13h
ret


times 510-($-$$) db 0
dw 0xAA55