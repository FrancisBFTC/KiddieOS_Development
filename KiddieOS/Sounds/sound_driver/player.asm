format MZ
entry code:main
stack 5000h

 ; CABEÇALHO DO MIDI
 define MIDI_SIGNATURE 0		; MThd
 define MIDI_HEADER_SIZE 4
 define MIDI_FORMAT 8
 define TRACKS_COUNT 10
 define TICKS_NUM_QNOTE 12
 
 ; FORMATOS DE MIDI
 define SINGLE_TRACK 0000h
 define SYNC_MULTI_TRACK 0001h
 define ASYNC_MULTI_TRACK 0002h
 
 ; CABEÇALHO DA PRIMEIRA FAIXA
 define TRACK_SIGNATURE 14		; MTrk
 define TRACK_SIZE 18
 
segment code
main:
	mov 	ax, datas
	mov 	ds, ax
	mov 	es, ax
	
	;jmp 	start
	
	mov 	dx, filename
	call 	open_to_read
	jc 		error.file
	mov 	[handler], ax
	
	mov 	bx, [handler]
	mov 	dx, 22
	call 	seek
	jc 		error.file
	
	mov 	bx, [handler]
	mov 	si, buffer_sound
	call 	read_file
	jc 		error.file
	
	jmp 	start

start:
	
	call 	soundblaster16.init

loop_s:
	call 	soundblaster16.setmaxvolume
	
	call 	soundblaster16.playsound
	
	;mov 	ah, 07h
	;int 	21h
	;cmp 	al, 0x0A
	;jnz 	loop_s
	
	;mov 	cx, 5
	;call 	reset_ivt_address
	
	jmp 	EXIT
	
	;xor 	cx, cx
	;mov 	cx, TRACK_SIGNATURE
	;mov 	si, buffer_sound
	;mov 	ax, [si + TRACKS_COUNT]
	;xchg 	ah, al
	
	
EXIT:
	mov 	ax, 4C00h
	int 	21h
	
error.file:
	mov 	ah, 07h
	int 	21h
	mov 	ah, 09h
	mov 	dx, msgerror
	int 	21h
	mov 	ax, 4C00h
	int	 	21h

	include "..\Library\fs.asm"
	include "..\Library\sound.asm"
	include "..\Library\intr.asm"
	
segment datas
	filename db "coin.mid",0
	msgerror db "erro em ler arquivo de musica!",0x0A,0x0D,'$'
	debug 	db "ocorreu a interrupcao!",0x0A,0x0D,'$'
	handler dw 0x0000
	save_address dd 0x00000000
	irq_set db 0

buffer_sound:	
			times 822 db 0
SIZE_BUFFER dw ($ - buffer_sound)

				;db 00h, 0ffh, 03h, 05h, 53h, 65h, 71h, 2Dh 
				;db 31h, 00h, 0ffh, 54h, 05h, 61h, 00h, 0fh 
				;db 00h, 00h, 00h, 0ffh, 58h, 04h, 04h, 02h 
				;db 18h, 08h, 00h, 0ffh, 51h, 03h, 07h, 0ah 
				;db 9Bh, 00h, 0ffh, 2fh, 00h, 8Bh, 6Fh, 20h 
				;db 45h, 73h, 71h, 75h, 65h, 72h, 64h, 61h 
				;db 0ffh, 2fh, 00h