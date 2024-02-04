FORMAT MZ
STACK 256
entry text:main 

segment text
include "Kiddieos/Library/sound.inc"

SetColor:
	push	es
	pusha
	mov 	dh, 6
	mov 	dl, 12
	mov 	ax, 0xB800
	mov 	es, ax
	mov 	cx, dx
	xor 	bx, bx
	xor 	dx, dx
	mov 	ax, 160
	mov 	bl, ch
	mul 	bx
	shl 	cl, 1
	xor 	ch, ch
	add 	ax, cx
	mov 	di, ax
	cld
	inc 	di
	mov 	cx, 26
	cmp 	byte[color], 0x0F
	jnz 	nozerocolor
	mov 	[color], 0
nozerocolor:
	inc 	byte[color]
	mov 	al, [color]
changecolor1:
	stosb
	inc 	di
	loop 	changecolor1
	
	popa
	pop 	es
ret

part1:
	mov 	ebx, M
	call 	Wait_Time

	call 	SetColor
	
	mov 	ebx, SM
	mov 	ax, C3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SM
	mov 	ax, C3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, D3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, M
	mov 	ax, C3
	call 	Play_Speaker_Tone
	
	call 	SetColor
ret

part2:
	mov 	ebx, M
	mov 	ax, F3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, E3
	call 	Play_Speaker_Tone
	
	call 	SetColor
ret

part3:
	mov 	ebx, M
	mov 	ax, G3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, F3
	call 	Play_Speaker_Tone
	
	call 	SetColor
ret

part4:
	mov 	ebx, M
	call 	Wait_Time

	call 	SetColor
	
	mov 	ebx, SM
	mov 	ax, C3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SM
	mov 	ax, C3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, C4
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, M
	mov 	ax, A3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, M
	mov 	ax, F3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, E3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, M
	mov 	ax, D3
	call 	Play_Speaker_Tone
	
	call 	SetColor
ret

part5:
	mov 	ebx, SM
	mov 	ax, A3S
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SM
	mov 	ax, A3S
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, A3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, M
	mov 	ax, F3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, M
	mov 	ax, G3
	call 	Play_Speaker_Tone
	
	call 	SetColor
	
	mov 	ebx, SB
	mov 	ax, F3
	call 	Play_Speaker_Tone
	
	call 	SetColor
ret


main:
	mov 	ax, datas
    mov 	ds, ax
	mov 	es, ax
	
	mov		ah, 09h
	mov 	dx, msg
	int 	0x21
	
	mov 	cx, 2		; 2 times
	mov 	dx, 60		; 60 BPM = 1 BPS
systemplay:
	
	call 	part1
	call 	part2
	call 	part1
	call 	part3
	call 	part4
	call 	part5
	
	mov 	dx, 120
	
	loop 	systemplay

	mov 	ax, 0x4C00
	int 	0x21


segment datas
	msg 	db "Happy Birthday, my friend!",'$'
	color 	db 0