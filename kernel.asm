%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG KERNEL]

jmp OSMain

; _____________________________________________
; Directives and Inclusions ___________________

%INCLUDE "Hardware/monitor.lib"
%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"
%INCLUDE "Hardware/win3dmov.lib"

; _____________________________________________


; _____________________________________________
; Starting the System _________________________

OSMain:
	call ConfigSegment
	call ConfigStack
	call VGA.SetVideoMode
	call DrawBackground
	call EffectInit
	call DriversInstall
	jmp GraficInterface
	;jmp SystemKernel

	
	
	

; _____________________________________________
	
; _____________________________________________
; Kernel Functions ____________________________

SystemKernel:
	call KEYBOARD_HANDLER
jmp SystemKernel

DriversInstall:
	__LoadInterface
	__Keyboard_Driver_Load
	call KEYBOARD_INSTALL
	__Fonts_Writer_Load
ret

GraficInterface:
	;__LoadInterface
	
	mov word[PositionX], 100
	mov word[PositionY], 10
	mov word[W_Width], 120
	mov word[W_Height], 120
	mov cx, _WALL
	
	mov byte[CountField], -1
	mov byte[QuantTab], 0
	
Start:
	WallPaper cx, SCREEN_WIDTH, SCREEN_HEIGHT, 40, 20
	Window3D MOVABLE, word[PositionX], word[PositionY], word[W_Width], word[W_Height]
cmp al, 2
je Start

jmp END

ConfigSegment:
	cld
	mov ax, es
	mov ds, ax
ret

ConfigStack:
	cli
	mov ax, 7D00h
	mov ss, ax
	mov sp, 3000h
	sti
ret

END:
; Zera na reinicialização todos os endereços de memória utilizados
	; ________________________________________________________________
	mov word[POSITION_X], 0000h
	mov word[POSITION_Y], 0000h
	mov word[QUANT_FIELD], 0000h
	mov word[LIMIT_COLW], 0000h
	mov word[LIMIT_COLX], 0000h
	mov word[QuantPos], 0000h
	mov word[CountPositions], 0000h
	mov byte[StatusLimitW], 0
	mov byte[StatusLimitX], 0
	mov byte[CursorTab], 0
	; ________________________________________________________________
	; Reinicia sistema
	; _________________________________________
	mov ax, 0040h
	mov ds, ax
	mov ax, 1234h
	mov [0072h], ax
	jmp 0FFFFh:0000h
; _____________________________________________
; _____________________________________________

