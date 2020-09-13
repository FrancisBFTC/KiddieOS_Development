%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG BOOTLOADER]

	
call LoadSystem
jmp 0800h:KERNEL

LoadSystem:
	mov ah, 02h
	mov al, KERNEL_NUM_SECTORS ;6
	mov ch, 0
	mov cl, KERNEL_SECTOR
	mov dh, 0
	mov dl, 80h
	mov bx, 0800h
	mov es, bx
	mov bx, KERNEL
	int 13h
ret


times 510-($-$$) db 0
dw 0xAA55