; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2019 MikeOS Developers -- see doc/LICENSE.TXT
;
; PC SPEAKER SOUND ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency; OUT: Nothing (registers preserved)

define C1 	9121
define C1S 	8609
define D1  	8126
define D1S 	7670
define E1 	7239
define F1 	6833
define F1S 	6449
define G1 	6087
define G1S 	5746
define A1 	5423
define A1S 	5119
define B1  	4831
define C2 	4560
define C2S 	4304
define D2 	4063
define D2S 	3834
define E2 	3619
define F2 	3416
define F2S 	3224
define G2 	3043
define G2S 	2873
define A2 	2711
define A2S 	2559
define B2 	2415
define C3 	2280
define C3S 	2152
define D3 	2031
define D3S 	1917
define E3 	1809
define F3 	1715
define F3S 	1612
define G3 	1521
define G3S 	1436
define A3 	1355
define A3S 	1292
define B3 	1207
define C4 	1140

SB 	EQU 1000000		; Semibreve = 1s
M 	EQU (SB / 2) 	; Mínima = 500ms
SM 	EQU (M / 2) 	; Semínima = 250ms
CC	EQU (SM / 2)	; Colcheia = 125ms
SC 	EQU (CC / 2) 	; Semicolcheia = 62.5ms
F 	EQU (SC / 2)	; Fusa = 31.25ms
SF 	EQU (F / 2) 	; Semifusa = 15.625ms

Play_Speaker_Tone:
	pusha

	mov 	cx, ax			; Store note value for now

	mov 	al, 182
	out 	0x43, al
	mov 	ax, cx			; Set up frequency
	out 	0x42, al
	mov 	al, ah
	out 	0x42, al

	in 		al, 0x61			; Switch PC speaker on
	or 		al, 00000011b
	out 	0x61, al
	
	call 	Wait_Time
	call 	Off_Speaker_Tone
	
	popa
ret

Wait_Time:
	pusha
	xor 	ax, ax
	mov 	ax, dx
	xor 	dx, dx
	mov 	cx, 60
	div 	cx
	xor 	ecx, ecx
	mov 	cx, ax
	xor 	edx, edx
	mov 	eax, ebx
	div 	ecx
	mov 	ebx, eax
	
	mov 	ah, 86h
	mov 	dx, bx
	shr 	ebx, 16
	mov 	cx, bx
	int 	15h
	popa
ret

; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)

Off_Speaker_Tone:
	pusha

	in 		al, 0x61
	and 	al, 11111100b
	out 	0x61, al

	popa
ret
