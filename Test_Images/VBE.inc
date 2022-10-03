;
; File: VESA.lib
;
;     Setup graphic mode via VESA.
;
;---------------------------------------------------------;
;                                                         ;
; Autor: (c) Craig Bamford, All rights reserved.          ;
; Version: Frederico Martins Nora.                        ;
; SubVersion: Wender Francis                              ;
;                                                         ;
;=========================================================;
; Histórico de revisão:                                   ;
;                                                         ;
; Vesa Information Block                       01/05/2011 ;
; Versão                                    13/março/2013 ;
; revisão 1                                  27/maio/2013 ;
; revisão 2                                    7/jan/2014 ;
; revisão 3                                          2015 ;
; Revisão 4 By Wender Francis                  01/08/2021 ;
;                                                         ;
;=========================================================;

GUI:
	.Video_Mode    dw 0
	.Screen_X      dw 0
	.Screen_Y      dw 0
	.BitsPerPixel  db 0
	.LinearFrameBuffer dd 0
	.Control  db 0
	.Window_Width  		  dw 0x0000
	.Window_Height        dw 0x0000
	.Window_PositionX     dw 0x0000
	.Window_PositionY     dw 0x0000
	.Window_Bar_Color     dd 0x00000000
	.Window_Border_Color  dd 0x00000000
	.Window_Back_Color    dd 0x00000000
	.Window_Title_Buffer  dd 0x00000000
	.Window_Icon_Path     dd 0x00000000
	.Window_Property      dw 0x0000
	.Window_ID_Master     dw 0x0000
	.Window_ID_Slave      dw 0x0000
	
frame_buffer  dd  0                                       ;
;=========================================================;
; VESA INFORMATION BLOCK                                  ;
;=========================================================;
VESA_Info:		                                          ;
    .Signature		    db	"VBE2"                ;
    .Version		    dw	1                     ;
    .OEMStringPtr		dd	1                     ;
    .Capabilities		db	4                     ;
    .VideoModePtr		dd	1                     ;
    .TotalMemory		dw	1                     ;
    .OEMSoftwareRev 	dw	1                     ;
    .OEMVendorNamePtr	dd	1                     ;
    .OEMProductNamePtr	dd	1                     ;
    .OEMProductRevPtr	dd	1                     ;
    .Reserved    		db	222                   ;
    .OEMData	    	db	256 ;256             ;
;=========================================================;
; VESA MODE INFORMATION                                   ;
;=========================================================;
Mode_Info:	                                              ;
    .ModeAttributes 	  dw	1                 ;
    .WinAAttributes 	  db	1              	  ;
    .WinBAttributes 	  db	1             	  ;
    .WinGranularity 	  dw	1             	  ;
    .WinSize		      dw	1                 ;
    .WinASegment		  dw	1                 ;
    .WinBSegment		  dw	1                 ;
    .WinFuncPtr		      dd	1                 ;
    .BytesPerScanLine	  dw	1                 ;
    .XResolution		  dw	0  ;*width        ;
    .YResolution		  dw	0  ;*height       ;
    .XCharSize		      db	1                 ;
    .YCharSize		      db	1                 ;
    .NumberOfPlanes 	  db	1                 ;
    .BitsPerPixel		  db	0  ;*bpp          ;
    .NumberOfBanks		  db	1                 ;
    .MemoryModel		  db	1                 ;
    .BankSize		      db	1                 ;
    .NumberOfImagePages	  db	1                 ;
    .Reserved_page		  db	1                 ;
    .RedMaskSize		  db	1                 ;
    .RedMaskPos		      db	1                 ;
    .GreenMaskSize		  db	1                 ;
    .GreenMaskPos		  db	1                 ;
    .BlueMaskSize		  db	1                 ;
    .BlueMaskPos		  db	1                 ;
    .ReservedMaskSize	  db	1                 ;
    .ReservedMaskPos	  db	1                 ;
    .DirectColorModeInfo  db    1                 ;
;=========================================================;
; VBE 2.0 extensions.                                     ;
;=========================================================;
    .PhysBasePtr		dd	0    ;*LFB            ;
    .OffScreenMemOffset	dd	1                     ;
    .OffScreenMemSize	dw	1                     ;
;=========================================================;
; VBE 3.0 extensions.                                     ;
;=========================================================;
    .LinBytesPerScanLine  dw	1                 ;
    .BnkNumberOfPages	  db	1                 ;
    .LinNumberOfPages	  db	1                 ;
    .LinRedMaskSize 	  db	1                 ;
    .LinRedFieldPos 	  db	1                 ;
    .LinGreenMaskSize	  db	1                 ;
    .LinGreenFieldPos	  db	1                 ;
    .LinBlueMaskSize	  db	1                 ;
    .LinBlueFieldPos	  db	1                 ;
    .LinRsvdMaskSize	  db	1                 ;
    .LinRsvdFieldPos	  db	1                 ;
    .MaxPixelClock		  dd	1                 ;
;=========================================================;
; Reserved                                                ;
;=========================================================;
    .Reserved1		db	190                       ;
;=========================================================;
; VESA MODE INFORMATION END                               ;
;=========================================================;
;
;-------------------------------------------------------------------
;

;
; ====================================================================
; Lista padrão de Modos VESA
; ====================================================================
;
	
;
; 0x4112 is 640x480x24bit	(*inicialização)   (3 bytes por pixel) 
; 0x4115 is 800x600x24bit	(*gui)             (3 bytes por pixel) 
; 0x4118 is 1024x768x24bit   	
; 0x411B is 1280x1024x24bit	
; 0x4129 is 640x480x32bit
; 0x412E is 800x600x32bit
; 0x4138 is 1024x768x32bit 
; 0x413D is 1280x1024x32bit 	


;  1: 182h, 320x200x8
;  2: 10Dh, 320x200x15           29: 185h, 640x400x24
;  3: 10Eh, 320x200x16           30: 186h, 640x400x32
;  4: 10Fh, 320x200x24 *         31: 101h, 640x480x8
;  5: 120h, 320x200x32           32: 110h, 640x480x15
;  6: 192h, 320x240x8            33: 111h, 640x480x16
;  7: 193h, 320x240x15           34: 112h, 640x480x24
;  8: 194h, 320x240x16           35: 121h, 640x480x32
;  9: 195h, 320x240x24           36: 103h, 800x600x8
; 10: 196h, 320x240x32           37: 113h, 800x600x15
; 11: 1A2h, 400x300x8            38: 114h, 800x600x16
; 12: 1A3h, 400x300x15           39: 115h, 800x600x24 *
; 13: 1A4h, 400x300x16           40: 122h, 800x600x32
; 14: 1A5h, 400x300x24           41: 105h, 1024x768x8
; 15: 1A6h, 400x300x32           42: 116h, 1024x768x15
; 16: 1B2h, 512x384x8            43: 117h, 1024x768x16
; 17: 1B3h, 512x384x15           44: 118h, 1024x768x24
; 18: 1B4h, 512x384x16           45: 123h, 1024x768x32
; 19: 1B5h, 512x384x24           46: 107h, 1280x1024x8
; 20: 1B6h, 512x384x32           47: 119h, 1280x1024x15
; 21: 1C2h, 640x350x8            48: 11Ah, 1280x1024x16
; 22: 1C3h, 640x350x15           49: 11Bh, 1280x1024x24
; 23: 1C4h, 640x350x16           50: 124h, 1280x1024x32
; 24: 1C5h, 640x350x24           51: 140h, 1400x1050x8
; 25: 1C6h, 640x350x32           52: 141h, 1400x1050x15
; 26: 100h, 640x400x8            53: 142h, 1400x1050x16
; 27: 183h, 640x400x15           54: 143h, 1400x1050x24
; 28: 184h, 640x400x16           55: 144h, 1400x1050x32

;
; ====================================================================
; Final da lista padrão
; ====================================================================
;

; Video modes:
; ============
; VirtualBox:
; Oracle VirtualBox: 0x????   640x480x24bpp
; Oracle VirtualBox: 0x0115   800x600x24BPP*
; Oracle VirtualBox: 0x0118  1024x768x24BPP
;
; Nvidia GeForce:  
; GeForce_8400_GS equ 0x06E4  
; GeForce 8400 GS: 0x0115   800x600x32BPP


;
; Define a placa de video
;
;1 = oracle virtual machine.
;2 = nvidia geforce
;
my_video_card: dd 0


BPP_Required   db 32   ; BPP Requisitado
ReX_Required   dw 300  ; Resolução X Requisitado
ReY_Required   dw 200  ; Resolução Y Requisitado

LoadingVesa db "Loading VESA...",0
Press    	db "Press Enter To Continue...",0

Set_Video_Mode:
    pusha
	
	call 	Search_Mode
	
	call 	VESA.GetWidth
    mov 	word [GUI.Screen_X], ax
	
	call 	VESA.GetHeight
    mov 	word [GUI.Screen_Y], ax

	call 	VESA.GetBPP
    mov 	byte [GUI.BitsPerPixel], al
	
	call 	VESA.GetLFB
	mov dword [GUI.LinearFrameBuffer], eax
	xor eax, eax
	
	
	popa	
ret

; Captura informações do cartão VBE
VBE_Info_Card:
	xor 	ax, ax
	mov 	es, ax
	mov 	di, VESA_Info
	mov 	ax, 4f00h
    int 	10h
ret

; Captura informações do modo gráfico
; CX = Número do modo
VBE_Info_Mode:
	xor 	ax, ax
	mov 	es, ax
	mov 	di, Mode_Info
	mov 	ax, 4f01h
    int 	10h
ret

; Inicialize o modo gráfico
; BX = Número do modo
; BIT 15 = Limpagem de tela
; BIT 14 = Ativação do LFB
VBE_Init_Mode:
	mov bx, 0xC000
	add bx, word [GUI.Video_Mode]    ;Adiciona o número do modo.
	mov ax, 4f02h
    int 10h
ret
	
;----------------------------------------
; Search_Mode:
;     Procura por VESA.
;     Ver se a máquina suporta o padrão VESA.
;	  Se suportar, procura na lista de modos especiais
Search_Mode:
	call 	VBE_Info_Card
	
	; Se VESA é suportada.
	cmp 	ax, word 0x004F
    je		GetAddress
	jmp 	ErrorVesa
	
	; Pegar Endereço da lista de modos
GetAddress:
	mov 	ebx, DWORD [VESA_Info.VideoModePtr]
	push 	ebx
	and 	ebx, 0x0000FFFF
	mov 	di, bx
	pop 	ebx
	shr 	ebx, 16
	and 	ebx, 0x0000FFFF
	mov 	ax, bx
	mov 	es, ax
	push 	es
	push 	di
	xor 	bx, bx
	
	; Pesquisa modo por modo
Find_Mode:
	pop 	di
	pop 	es
	mov 	cx, WORD [es:di + bx]
	cmp 	cx, 0xFFFF
	je 		No_Mode
	push 	es
	push 	di
	call 	VBE_Info_Mode
	add 	bx, 2
	mov 	ax, word [es:Mode_Info.XResolution]
	cmp 	word [ReX_Required], ax
	jne 	Find_Mode
	mov 	ax, word [es:Mode_Info.YResolution]
	cmp 	word [ReY_Required], ax
	jne 	Find_Mode
	mov 	ax, word [es:Mode_Info.BitsPerPixel]
	cmp 	word [BPP_Required], ax
	jne 	Find_Mode
	mov 	word[GUI.Video_Mode], cx
	call 	VBE_Init_Mode
	pop  	di
	pop 	es
Done:
	xor  	ax, ax
	clc
ret

	; Caso não encontrar o modo especial
No_Mode:
	pusha
	mov 	si, Mode_No_Found
	call 	Print_String
	popa
	stc    ;Flag avisa que nao há vesa.
ret

	; Caso não suportar VESA
ErrorVesa:	
    pusha  
	mov 	si, No_Vesa_Msg
    call 	Print_String 
	popa
	stc    ;Flag avisa que nao há vesa.	
ret

;Pegar Bits Por Pixel.	
VESA.GetBPP:
    mov al, byte [ModeInfo_BitsPerPixel]
ret

;Pegar largura da tela em pixels.		
VESA.GetWidth:
    mov ax, word [ModeInfo_XResolution] 
ret
	
;Pegar altura da tela em pixels.	
VESA.GetHeight:
    mov ax, word [ModeInfo_YResolution]
ret

;Pegar o Linear Frame Buffer.	
VESA.GetLFB:
    mov eax, dword [es:ModeInfo_PhysBasePtr]
ret

;vesa OK.
;.vesaOK:     
;	;Prepara a string para apresentar o número da versão.
;	mov ax, word [di+4]
 ;   mov dx, ax
  ;  add ax, word 48*256+48   
;	mov word [Version], ax
;	;Mostra número da versão.
;	pusha
 ;   mov si, msg_ver_vesa
  ;  call Print_String
;	mov ax, word[Version]
;    call Print_Hexa_Value16
;    popa
	

;
; Mensagens.
;

No_Machine 	   db "Error: No Machine",13,10,0		
No_Vesa_Msg    db "Error: No VESA Here!",13,10,0
Mode_No_Found  db "Error: Resolution Mode Not Found!",0
Vesa_Ver_Msg   db "Vesa Version : ",0	
Version 	   dw 0x0000

;	mov 	dh, 14
;	mov 	dl, 31
;	call 	Move_Cursor
;	mov 	si, LoadingVesa
;	call 	Print_String
;	inc 	dh
;	call 	Move_Cursor
;	mov 	si, Press
;	call 	Print_String	
;
;fim.
;