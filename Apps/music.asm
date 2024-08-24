FORMAT MZ
STACK 256
entry text:main 

segment text
include "../Kiddieos/Library/sound.inc"

main:
	mov 	ebx, SM
	mov 	ax, C3
	call 	Play_Speaker_Tone
	

	mov 	ax, 0x4C00
	int 	0x21