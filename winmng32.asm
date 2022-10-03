%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"

ORG   0
ALIGN 4

WINMNG1 EQU 0x112000
WinMng32: 

BITS 32
SECTION protectedmode vstart=WINMNG1, valign=4

jmp 	Os_WinMng_Setup
jmp 	Define_Window
jmp 	Show_Window

; =====================================
; Inclusion Files

%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"
%INCLUDE "Hardware/win3dmov.lib"

; =====================================

; *****************************************************************************
; Endereços de valores de interface gráfica (Janelas, Resolução, Mouse, etc..)
; & Estados de propriedades e Eventos.

%DEFINE  GUI_VARS    			WINMNG+0C000h ;Info GUI Address
%DEFINE  SCREEN_X    			GUI_VARS+5   ; word
%DEFINE  SCREEN_Y               GUI_VARS+7   ; word
%DEFINE  BPP_MODE    			GUI_VARS+9   ; byte
%DEFINE  LFBADDR                GUI_VARS+10  ; dword
%DEFINE  CONTROL     			GUI_VARS+14  ; byte
%DEFINE  WINDOW_WIDTH_A     	GUI_VARS+15  ; word
%DEFINE  WINDOW_HEIGHT_A    	GUI_VARS+17  ; word
%DEFINE  WINDOW_POSITIONX_A 	GUI_VARS+19  ; word
%DEFINE  WINDOW_POSITIONY_A 	GUI_VARS+21  ; word
%DEFINE  WINDOW_BAR_COLOR_A 	GUI_VARS+23  ; dword
%DEFINE  WINDOW_BORDER_COLOR_A  GUI_VARS+27  ; dword
%DEFINE  WINDOW_BACK_COLOR_A    GUI_VARS+31  ; dword
%DEFINE  WINDOW_TITLE_BUFFER_A  GUI_VARS+35  ; dword
%DEFINE  WINDOW_ICON_PATH_A     GUI_VARS+39  ; dword
%DEFINE  WINDOW_PROPERTY_A      GUI_VARS+43  ; word
%DEFINE  WINDOW_ID_MASTER_A     GUI_VARS+45  ; byte
%DEFINE  WINDOW_ID_SLAVE_A      GUI_VARS+47  ; byte

%DEFINE  TOP_BAR          0x01
%DEFINE  BUTTON_CLOSE     0x02
%DEFINE  BUTTON_MAXIMIZE  0x04
%DEFINE  BUTTON_MINIMIZE  0x08
%DEFINE  VISIBILITY       0x10
%DEFINE  MOVABLE          0x20
%DEFINE  RESIZABLE        0x40
%DEFINE  OPACITY          0x80
%DEFINE  BLACKSCALE       0x100      
%DEFINE  CLICABLE         0x200
%DEFINE  WRITABLE         0x400
%DEFINE  READJUSTABLE     0x800
%DEFINE  BORDER_COLOR     0x1000
%DEFINE  BACK_COLOR       0x2000
%DEFINE  MAIN_WINDOW      0x4000
%DEFINE  ACTIVE_ELEM      0x8000

; *****************************************************************************


; Tabela de Posições Interativas Pro Mouse & Teclado
; Fórmula de Acesso : ((IPT.Base x PID.Process) + (IPT.Size x WINDOW_SLAVE_ID)) 
;IPT:
;	.StatusP dd 0x00000000  ; Estado de eventos & Propriedades do elemento
;	.BeginXY dd 0x00000000  ; Início exato do frame do elemento
;	.FinalXY dd 0x00000000  ; Final exato do frame do elemento
;	.TotalWH dd 0x00000000  ; Comprimento total & Altura do elemento
;	.EventPT dd 0x00000000  ; Ponteiro de eventos do elemento
; ************************************************************************
; Deslocamentos do Elemento na Tabela de Posições Interativas
IPT.Base  EQU 0x00400000
IPT.Size  EQU 24
IPT.Stat  EQU 0
IPT.Prop  EQU 2
IPT.BegP  EQU 4
IPT.EndP  EQU 8
IPT.WidT  EQU 12
IPT.Heig  EQU 14
IPT.FrmW  EQU 16
IPT.Even  EQU 20
; ************************************************************************


; ************************************************************************
; Tabela de endereços/deslocamento de Frames
; Tabela "FRAMES_BUF" inicializada no início do Windows Manager 
FRAMES_OFF      dd 0x00000000 ; (ResX x ResY x (BPP / 8))
WINDOW_POS   	dd 0x00000000  ; Posição Exata da janela atual
ATUAL_FRAME	    dd 0x00000000  ; Frame da janela atual

FRAMES_BUF:
	MVIDEO_BUF  dd 0x00000000  ; Memória de vídeo
	MSPACE_BUF  dd 0x00000000  ; Frame do MainSpace (Área de trabalho)
	FRAMES_ICN  dd 0x00000000  ; Frame de Ícones do MainSpace
	WMOUSE_WIN  dd 0x00000000  ; Frame de Janelas do Mouse
	FRAMES_WIN  dd 0x00000000  ; Offset para Frame de Janelas Gráficas
; ************************************************************************


; ************************************************************************
; Variáveis para Imagens do KiddieOS
FORMAT_IMG  dw 0x0000      ; Formato de imagem (BMP ou ICN)
MEMORY_BMP  dd 0x50000     ; Memória inicial de imagens BMP
MEMORY_ICN  dd 0x30000     ; Memória inicial de imagens ICN

BMP_LENGTH    EQU  2       ;BMP -> (DimX x DimY)
BMP_DIMENS_X  EQU  18      ;BMP -> Offset of Dimension X
BMP_DIMENS_Y  EQU  22      ;BMP -> Offset of Dimension Y
; ************************************************************************


; ************************************************************************
; Variáveis auxiliares de resolução & janelas
ScreenXTotal    dd 0
WidthTotal      dd 0
BytesPerPixel   dd 0

; RGB Colors
R1   db 0x00
GB1  dw 0x0000
RN1  db 0x00
GBN1 dw 0x0000
RN2  db 0x00
GBN2 dw 0x0000
ARGB1 dd 0x00000000
ARGB2 dd 0x00000000
BC  db 0 ; ByteColor
; ************************************************************************

	
Define_Window:
	xor 	eax, eax
	xor 	ecx, ecx
	xor 	edx, edx
	mov 	edi, DWORD [MVIDEO_BUF]
	mov 	bx, WORD [WINDOW_PROPERTY_A]
	and 	bx, (MAIN_WINDOW+ACTIVE_ELEM)
	jz 		DefineMasterID
DefineSlaveID:
	mov 	ax, WORD [WINDOW_ID_SLAVE_A]
	jmp 	MultiplyID
DefineMasterID:
	mov 	ax, WORD [WINDOW_ID_MASTER_A]
MultiplyID:
	mov 	ecx, DWORD [FRAMES_OFF] ;0x30000
	mul 	ecx
	add 	eax, DWORD [FRAMES_WIN]
	mov 	DWORD [ATUAL_FRAME], eax
	add 	edi, eax
	xor 	eax, eax
	xor 	ecx, ecx
	mov 	ax, WORD [WINDOW_POSITIONY_A]
	mul 	DWORD [ScreenXTotal]
	mov 	ecx, eax
	xor 	eax, eax
	mov 	ax, WORD [WINDOW_POSITIONX_A]
	mul 	DWORD [BytesPerPixel]
	add 	eax, ecx
	add 	edi, eax
	mov 	DWORD [WINDOW_POS], edi
	
	call 	CreateIPT
	
	and 	bx, MAIN_WINDOW
	jz 		IsNotAMainWindow
	
IsAMainWindow:
	xor 	eax, eax
	mov 	bx, WORD [WINDOW_PROPERTY_A]
	push 	WORD [WINDOW_PROPERTY_A]
	and 	WORD [WINDOW_PROPERTY_A], 0xDFFF
	and 	bx, BORDER_COLOR
	jz 		MainWindowNBColor
	jmp 	MainWindowWBColor
MainWindowNBColor:
	mov 	DWORD [ARGB1], 0x00808080
	mov 	DWORD [ARGB2], 0x00121212
	call 	0x08:WindowElemNBColor
	pop 	WORD [WINDOW_PROPERTY_A]
	jmp 	MainWindow
MainWindowWBColor:
	call 	0x08:WindowElemWBColor
	pop 	WORD [WINDOW_PROPERTY_A]
	jmp 	MainWindow
	
IsNotAMainWindow:
	xor 	eax, eax
	mov 	bx, WORD [WINDOW_PROPERTY_A]
	and 	bx, BORDER_COLOR
	mov 	DWORD [ARGB1], 0x00808080
	mov 	DWORD [ARGB2], 0x00121212
	jz 		WindowElemNBColor
	jmp 	WindowElemWBColor
	
	
CreateIPT:
	pushad
	xor 	eax, eax
	mov 	ebx, IPT.Size
	mov 	ax, WORD [WINDOW_ID_SLAVE_A]
	mul 	ebx
	add 	eax, IPT.Base
	mov 	esi, eax
	
	mov 	WORD [esi + IPT.Stat], 0
	mov 	ax, WORD [WINDOW_PROPERTY_A]
	mov 	WORD [esi + IPT.Prop], ax
	mov 	eax, edi
	mov 	DWORD [esi + IPT.FrmW], eax
	sub 	eax, DWORD [ATUAL_FRAME]
	mov 	DWORD [esi + IPT.BegP], eax
	push 	eax
	mov 	eax, DWORD [ScreenXTotal]
	mov 	bx, WORD [WINDOW_HEIGHT_A]
	mov 	WORD [esi + IPT.Heig], bx
	mul 	ebx
	mov 	ecx, eax
	mov 	eax, [BytesPerPixel]
	mov 	bx, WORD [WINDOW_WIDTH_A]
	mul 	bx
	mov 	WORD [esi + IPT.WidT], bx
	add 	ecx, eax
	pop 	eax
	add 	eax, ecx
	mov 	DWORD [esi + IPT.EndP], eax
	mov 	DWORD [esi + IPT.Even], 0
	popad
ret

; **************************************************************
; Início de Elemento com bordas definidas pelo usuário

WindowElemWBColor:
	mov 	cx, WORD [WINDOW_WIDTH_A]
	mov 	eax, DWORD [WINDOW_BORDER_COLOR_A]
	mov 	DWORD [ARGB1], eax
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, OPACITY
	jz  	PutTransparencyWB
	jmp 	OpaqueLineUpWB

PutTransparencyWB:
	rol 	WORD [GB1], 8
	mov 	esi, R1
	mov 	ebx, edi
	sub 	ebx, DWORD [ATUAL_FRAME]
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, BLACKSCALE
	jz 		TransLineUpWB
	jmp 	TransLineUPWBScale

; ==========================================================
; Início do Elemento opaco (Sem transparência)
		
	OpaqueLineUpWB:
		stosd
		loop 	OpaqueLineUpWB
		sub 	edi, [BytesPerPixel]
		mov 	cx, WORD [WINDOW_HEIGHT_A]
	OpaqueLineRightWB:
		stosd
		sub 	edi, [BytesPerPixel]
		add 	edi, DWORD [ScreenXTotal]
		loop 	OpaqueLineRightWB
		sub 	edi, DWORD [ScreenXTotal]
		mov 	cx, WORD [WINDOW_WIDTH_A]
	OpaqueLineDownWB:
		stosd
		sub 	edi, 8  ; [BytesPerPixel] x 2
		loop 	OpaqueLineDownWB
		mov 	cx, WORD [WINDOW_HEIGHT_A]
		add 	edi, [BytesPerPixel]
	OpaqueLineLeftWB:
		stosd
		sub 	edi, [BytesPerPixel]
		sub 	edi, DWORD [ScreenXTotal]
		loop	OpaqueLineLeftWB
		jmp 	VerifyPropertyBack
		
; Fim do elemento opaco (Sem transparência)
; ==========================================================

; =====================================================================
; Início do Elemento transparente em qualquer escala (Sem opacidade)

	TransLineUpWB:
		mov 	al, BYTE [esi + 2]
		or  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		or  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		or  	al, BYTE [ebx + 4]
		stosb
		add 	ebx, 3
		loop 	TransLineUpWB
		sub 	edi, [BytesPerPixel]
		sub 	ebx, [BytesPerPixel]
		mov 	cx, WORD [WINDOW_HEIGHT_A]
	TransLineRightWB:
		mov 	al, BYTE [esi + 2]
		or  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		or  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		or  	al, BYTE [ebx + 4]
		stosb
		sub 	edi, [BytesPerPixel]
		add 	edi, DWORD [ScreenXTotal]
		add 	ebx, DWORD [ScreenXTotal]
		loop 	TransLineRightWB
		sub 	edi, DWORD [ScreenXTotal]
		sub 	ebx, DWORD [ScreenXTotal]
		mov 	cx, WORD [WINDOW_WIDTH_A]
	TransLineDownWB:
		mov 	al, BYTE [esi + 2]
		or  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		or  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		or  	al, BYTE [ebx + 4]
		stosb
		sub 	ebx, 3
		sub 	edi, 6
		loop 	TransLineDownWB
		mov 	cx, WORD [WINDOW_HEIGHT_A]
		add 	edi, [BytesPerPixel]
		add 	ebx, [BytesPerPixel]
	TransLineLeftWB:
		mov 	al, BYTE [esi + 2]
		or  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		or  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		or  	al, BYTE [ebx + 4]
		stosb
		sub 	edi, [BytesPerPixel]
		sub 	edi, DWORD [ScreenXTotal]
		sub 	ebx, DWORD [ScreenXTotal]
		loop	TransLineLeftWB
		jmp 	VerifyPropertyBack
		
; Fim do elemento transparente em qualquer escala (Sem opacidade)
; =====================================================================

; =====================================================================
; Início do Elemento transparente na escala de preto (Sem opacidade)

	TransLineUPWBScale:
		mov 	al, BYTE [esi + 2]
		and  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		and  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		and  	al, BYTE [ebx + 4]
		stosb
		add 	ebx, [BytesPerPixel]
		loop 	TransLineUPWBScale
		sub 	edi, [BytesPerPixel]
		sub 	ebx, [BytesPerPixel]
		mov 	cx, WORD [WINDOW_HEIGHT_A]
	TransLineRightWBScale:
		mov 	al, BYTE [esi + 2]
		and  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		and  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		and  	al, BYTE [ebx + 4]
		stosb
		sub 	edi, [BytesPerPixel]
		add 	edi, DWORD [ScreenXTotal]
		add 	ebx, DWORD [ScreenXTotal]
		loop 	TransLineRightWBScale
		sub 	edi, DWORD [ScreenXTotal]
		sub 	ebx, DWORD [ScreenXTotal]
		mov 	cx, WORD [WINDOW_WIDTH_A]
	TransLineDownWBScale:
		mov 	al, BYTE [esi + 2]
		and  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		and  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		and  	al, BYTE [ebx + 4]
		stosb
		sub 	ebx, 3
		sub 	edi, 6
		loop 	TransLineDownWBScale
		mov 	cx, WORD [WINDOW_HEIGHT_A]
		add 	edi, [BytesPerPixel]
		add 	ebx, [BytesPerPixel]
	TransLineLeftWBScale:
		mov 	al, BYTE [esi + 2]
		and  	al, BYTE [ebx + 0]
		stosb
		mov 	al, BYTE [esi + 1]
		and  	al, BYTE [ebx + 2]
		stosb
		mov 	al,	BYTE [esi + 0]
		and  	al, BYTE [ebx + 4]
		stosb
		sub 	edi, [BytesPerPixel]
		sub 	edi, DWORD [ScreenXTotal]
		sub 	ebx, DWORD [ScreenXTotal]
		loop	TransLineLeftWBScale
		
; Fim do elemento transparente na escala de preto (Sem opacidade)
; =====================================================================

; ==========================================================
; Elemento tem ou não tem fundo?

VerifyPropertyBack:
	add 	edi, [ScreenXTotal]
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, BACK_COLOR
	jz 		NoBackColorWB
	call 	BackColor
NoBackColorWB:
	retf
	
; ==========================================================

; Fim do elemento com bordas definidas pelo usuário
; **************************************************************

; **************************************************************
; Início de Elemento com bordas definidas pelo sistema

WindowElemNBColor:
	mov 	cx, WORD [WINDOW_WIDTH_A]
	mov 	eax, DWORD [ARGB1]
	LineUpNB:
		stosd
		loop 	LineUpNB
		sub 	edi, [BytesPerPixel]
		mov 	cx, WORD [WINDOW_HEIGHT_A]
	LineRightNB:
		stosd
		sub 	edi, [BytesPerPixel]
		add 	edi, DWORD [ScreenXTotal]
		loop 	LineRightNB
		sub 	edi, DWORD [ScreenXTotal]
		sub 	edi, [BytesPerPixel]
		mov 	cx, WORD [WINDOW_WIDTH_A]
		sub 	cx, 1
		mov 	eax, DWORD [ARGB2]
	LineDownNB:
		stosd
		sub 	edi, 8  ; [BytesPerPixel] x 2
		loop 	LineDownNB
		mov 	cx, WORD [WINDOW_HEIGHT_A]
		add 	edi, [BytesPerPixel]
		sub 	cx, 1
	LineLeftNB:
		stosd
		sub 	edi, [BytesPerPixel]
		sub 	edi, DWORD [ScreenXTotal]
		loop	LineLeftNB
		mov 	dx, WORD [WINDOW_PROPERTY_A]
		and 	dx, BACK_COLOR
		jz 		NoBackColorNB
		call 	BackColor
NoBackColorNB:
	retf
	
; Fim do elemento com bordas definidas pelo sistema
; **************************************************************

; **************************************************************
; Início de desenho do fundo de elementos/janelas

BackColor:
	mov 	cx, WORD [WINDOW_WIDTH_A]
	mov 	eax, [BytesPerPixel]
	mul 	cx
	sub 	ax, 8   ; [BytesPerPixel] x 2
	mov 	DWORD [WidthTotal], eax
	mov 	eax, DWORD [WINDOW_BACK_COLOR_A]
	mov 	DWORD [ARGB1], eax
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, OPACITY
	jz	 	PutTransparencyBack
	jmp 	GoScreenPosition
	
PutTransparencyBack:
	add 	edi, [ScreenXTotal]
	add 	edi, [BytesPerPixel]
	mov 	cx, WORD [WINDOW_HEIGHT_A]
	sub 	cx, 2
	rol 	WORD [GB1], 8
	mov 	esi, R1
	mov 	ebx, edi
	sub 	ebx, DWORD [ATUAL_FRAME]
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, BLACKSCALE
	jz 		TransBackColor
	jmp 	TransBackColorBScale
		
GoScreenPosition:
	add 	edi, [ScreenXTotal]
	add 	edi, [BytesPerPixel]
	mov 	cx, WORD [WINDOW_HEIGHT_A]
	sub 	cx, 2

; ==========================================================
; Início do fundo opaco (Sem transparência)
	
OpaqueBackColor:
	push 	cx
	mov 	cx, word[WINDOW_WIDTH_A]
	sub 	cx, 2
OpaqueDrawLine:
	stosd
	loop 	OpaqueDrawLine
OpaqueNextLine:
	sub 	edi, [WidthTotal]
	add 	edi, [ScreenXTotal]
	pop 	cx
	loop 	OpaqueBackColor
ret

; Fim do fundo opaco (Sem transparência)
; ==========================================================

; ================================================================
; Início do fundo transparente em qualquer escala (Sem opacidade)

TransBackColor:
	push 	cx
	mov 	cx, word[WINDOW_WIDTH_A]
	sub 	cx, 2
TransDrawLine:
	mov 	al, BYTE [esi + 2]
	or  	al, BYTE [ebx + 0]
	stosb
	mov 	al, BYTE [esi + 1]
	or  	al, BYTE [ebx + 2]
	stosb
	mov 	al,	BYTE [esi + 0]
	or  	al, BYTE [ebx + 4]
	stosb
	add 	ebx, 3
	loop 	TransDrawLine
TransNextLine:
	sub 	edi, [WidthTotal]
	add 	edi, [ScreenXTotal]
	sub 	ebx, [WidthTotal]
	add 	ebx, [ScreenXTotal]
	pop 	cx
	loop 	TransBackColor
ret

; Fim do fundo transparente em qualquer escala (Sem opacidade)
; ================================================================


; ================================================================
; Início do fundo transparente na escala de preto (Sem opacidade)

TransBackColorBScale:
	push 	cx
	mov 	cx, word[WINDOW_WIDTH_A]
	sub 	cx, 2
TransDrawLineBScale:
	mov 	al, BYTE [esi + 2]
	and  	al, BYTE [ebx + 0]
	stosb
	mov 	al, BYTE [esi + 1]
	and  	al, BYTE [ebx + 2]
	stosb
	mov 	al,	BYTE [esi + 0]
	and  	al, BYTE [ebx + 4]
	stosb
	add 	ebx, 3
	loop 	TransDrawLineBScale
TransNextLineBScale:
	sub 	edi, [WidthTotal]
	add 	edi, [ScreenXTotal]
	sub 	ebx, [WidthTotal]
	add 	ebx, [ScreenXTotal]
	pop 	cx
	loop 	TransBackColorBScale
ret

; Fim do fundo transparente na escala de preto (Sem opacidade)
; ================================================================

; Fim de desenho do fundo de elementos/janelas
; **************************************************************


; **************************************************************
; Início de desenho da janela principal
		
MainWindow:
	mov 	bx, WORD [WINDOW_PROPERTY_A]
	and 	bx, TOP_BAR
	jnz 	Draw_Bar
	
; ------------------------------------------------------------------------
; Janelas internas da janela principal (Também executado pelo DrawBar)

Intern_Windows:
	push 	WORD [WINDOW_WIDTH_A]
	push 	WORD [WINDOW_HEIGHT_A]
	mov 	eax, DWORD [WINDOW_BAR_COLOR_A]
	push 	DWORD [WINDOW_BORDER_COLOR_A]
	mov 	DWORD [WINDOW_BORDER_COLOR_A], eax
	mov 	bx, WORD [WINDOW_PROPERTY_A]
	or 		bx, BORDER_COLOR
	mov 	ax, WORD [WINDOW_PROPERTY_A]
	mov 	WORD [MainProperty], ax
	and 	WORD [WINDOW_PROPERTY_A], 0xDFFF
	mov 	DWORD [ARGB1], 0x00121212
	mov 	DWORD [ARGB2], 0x00808080
	mov 	ecx, 2
Loop_Borders:
	push 	ecx
	xor 	eax, eax
	add 	edi, [ScreenXTotal]
	add 	edi, [BytesPerPixel]
	sub 	WORD [WINDOW_WIDTH_A], 2
	sub 	WORD [WINDOW_HEIGHT_A], 2
	and 	bx, BORDER_COLOR
	jz 		MWNBColor
	jmp 	MWWBColor
MWNBColor:
	call 	0x08:WindowElemNBColor	
	jmp 	Continue_Loop
MWWBColor:
	call 	0x08:WindowElemWBColor
Continue_Loop:
	pop 	ecx
	pop 	DWORD[WINDOW_BORDER_COLOR_A]
	push 	DWORD[WINDOW_BORDER_COLOR_A]
	mov 	ax, WORD[MainProperty]
	mov 	WORD [WINDOW_PROPERTY_A], ax
	mov 	bx, ax
	dec 	ecx
	jnz     Loop_Borders
	mov 	ax, WORD[MainProperty]
	mov 	WORD [WINDOW_PROPERTY_A], ax
	pop 	DWORD[WINDOW_BORDER_COLOR_A]
	pop 	WORD [WINDOW_HEIGHT_A]
	pop 	WORD [WINDOW_WIDTH_A]
	jmp 	ReturnMainWindow

; ------------------------------------------------------------------------
; Topo da barra da janela principal (Depois executa janela interna)

Draw_Bar:
	mov 	cx, WORD [WINDOW_WIDTH_A]
	mov 	eax, [BytesPerPixel]
	mul 	cx
	sub 	ax, 8   ; [BytesPerPixel] x 2
	mov 	DWORD [WidthTotal], eax
	mov 	eax, DWORD [WINDOW_BAR_COLOR_A]
	mov 	DWORD [ARGB1], eax
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, OPACITY
	jz  	PutTransparencyDB
	jmp 	OpaqueDrawBar
PutTransparencyDB:
	add 	edi, [ScreenXTotal]
	add 	edi, [BytesPerPixel]
	mov 	cx, 10
	rol 	WORD [GB1], 8
	mov 	esi, R1
	mov 	ebx, edi
	sub 	ebx, DWORD [ATUAL_FRAME]
	mov 	dx, WORD [WINDOW_PROPERTY_A]
	and 	dx, BLACKSCALE
	jz 		TransDrawBar
	jmp 	TransDrawBarBScale

; ================================================================
; Início do topo da barra opaco (Sem transparência)

OpaqueDrawBar:
	add 	edi, [ScreenXTotal]
	add 	edi, [BytesPerPixel]
	mov 	cx, 10
OpDrawBar:
	push 	cx
	mov 	cx, word[WINDOW_WIDTH_A]
	sub 	cx, 2
OpaqueDrawBarLine:
	stosd
	loop 	OpaqueDrawBarLine
OpaqueNextBarLine:
	sub 	edi, [WidthTotal]
	add 	edi, [ScreenXTotal]
	pop 	cx
	loop 	OpDrawBar
	jmp 	DrawInternWindows
	
; Fim do topo da barra opaco (Sem transparência)
; ================================================================

; =============================================================================
; Início do topo da barra transparente em qualquer escala (Sem opacidade)

TransDrawBar:
	push 	cx
	mov 	cx, word[WINDOW_WIDTH_A]
	sub 	cx, 2
TransDrawBarLine:
	mov 	al, BYTE [esi + 2]
	or  	al, BYTE [ebx + 0]
	stosb
	mov 	al, BYTE [esi + 1]
	or  	al, BYTE [ebx + 2]
	stosb
	mov 	al,	BYTE [esi + 0]
	or  	al, BYTE [ebx + 4]
	stosb
	add 	ebx, 3
	loop 	TransDrawBarLine
TransNextBarLine2:
	sub 	edi, [WidthTotal]
	add 	edi, [ScreenXTotal]
	sub 	ebx, [WidthTotal]
	add 	ebx, [ScreenXTotal]
	pop 	cx
	loop 	TransDrawBar
	jmp 	DrawInternWindows

; Fim do topo da barra transparente em qualquer escala (Sem opacidade)
; =============================================================================	

; =============================================================================
; Início do topo da barra transparente na escala de preto (Sem opacidade)

TransDrawBarBScale:
	push 	cx
	mov 	cx, word[WINDOW_WIDTH_A]
	sub 	cx, 2
TransDrawLineBScale2:
	mov 	al, BYTE [esi + 2]
	and  	al, BYTE [ebx + 0]
	stosb
	mov 	al, BYTE [esi + 1]
	and  	al, BYTE [ebx + 2]
	stosb
	mov 	al,	BYTE [esi + 0]
	and  	al, BYTE [ebx + 4]
	stosb
	add 	ebx, 3
	loop 	TransDrawLineBScale2
TransNextLineBScale2:
	sub 	edi, [WidthTotal]
	add 	edi, [ScreenXTotal]
	sub 	ebx, [WidthTotal]
	add 	ebx, [ScreenXTotal]
	pop 	cx
	loop 	TransDrawBarBScale

; Fim do topo da barra transparente na escala de preto (Sem opacidade)
; =============================================================================	
%DEFINE	PADDING_UP     2
%DEFINE	PADDING_RIGHT_CL  2
%DEFINE	PADDING_RIGHT     1
%DEFINE WIDTH_B  11
%DEFINE HEIGHT_B 9

; =============================================================================
; Início de desenho das janelas internas e botões do topo

DrawInternWindows:
	sub 	edi, [ScreenXTotal]
	sub 	edi, [BytesPerPixel]
	
	push 	WORD [WINDOW_HEIGHT_A]
	sub 	WORD [WINDOW_HEIGHT_A], 10
	
	call 	0x08:Intern_Windows
	
	pop 	WORD [WINDOW_HEIGHT_A]
	
	xor 	esi, esi 
	xor 	edi, edi
	
	mov 	ebx, DWORD [esp + 20]
	mov 	ax, bx
	rol 	ebx, 16
	inc 	ax
	mov 	bx, ax
	
	push 	dword But_Colors 
	push 	ebx
	
	mov 	dx, WORD [WINDOW_POSITIONX_A]
	add 	dx, WORD [WINDOW_WIDTH_A]
	mov 	cx, WIDTH_B
	sub 	dx, (WIDTH_B+PADDING_RIGHT_CL)
	shl 	edx, 16
	shl 	ecx, 16
	mov 	dx, WORD [WINDOW_POSITIONY_A]
	add 	dx, PADDING_UP
	mov 	cx, HEIGHT_B
	mov 	ax, WORD [WINDOW_PROPERTY_A]
	mov 	WORD [MainProperty], ax
	mov 	bx, ax
	and 	bx, BUTTON_CLOSE
	jz 		DrawBMax
DrawBClose:
	xor 	eax, eax            
	mov 	ebx, 0x2090
	mov 	DWORD[But_Colors+8], 0x00FF0000
	int 	0xCD
	pop 	ebx
	inc 	bx
	push 	ebx
	sub 	edi, [ScreenXTotal]
	sub 	edi, [ScreenXTotal]
	add 	edi, 8   ; BytesPerPixel x 2
	mov 	eax, 0xFFFFFFFF
	stosd
	stosd
	sub 	edi, [BytesPerPixel]
	sub 	edi, [ScreenXTotal]
	mov 	cx, 4
DrawX1:	
	stosd
	sub 	edi, [ScreenXTotal]
	loop 	DrawX1
	add 	edi, [ScreenXTotal]
	sub 	edi, 8  ; BytesPerPixel x 2
	stosd
	sub 	edi, 16   ; BytesPerPixel²
	stosd
	stosd
	sub 	edi, [BytesPerPixel]
	add 	edi, [ScreenXTotal]
	mov 	cx, 4
DrawX2:	
	stosd
	add 	edi, [ScreenXTotal]
	loop 	DrawX2
	sub 	edi, [ScreenXTotal]
	sub 	edi, 8  ; BytesPerPixel x 2
	stosd
	mov 	dx, WORD [WINDOW_POSITIONX_A]
	mov 	cx, WIDTH_B
	sub 	dx, (WIDTH_B+PADDING_RIGHT)
	shl 	edx, 16
	shl 	ecx, 16
	mov 	dx, WORD [WINDOW_POSITIONY_A]
	mov 	cx, HEIGHT_B
DrawBMax:
	mov 	bx, WORD [MainProperty]
	and 	bx, BUTTON_MAXIMIZE
	jz 		DrawBMin
	xor 	eax, eax            
	mov 	ebx, 0x2090
	mov 	DWORD[But_Colors+8], 0x000025FF
	int 	0xCD
	pop 	ebx
	inc 	bx
	push 	ebx
	sub 	edi, [ScreenXTotal]
	sub 	edi, [ScreenXTotal]
	add 	edi, 8   ; BytesPerPixel x 2
	mov 	eax, 0xFFFFFFFF
	mov 	cx, 5
DrawSquareDown:
	stosd
	loop 	DrawSquareDown
	mov 	cx, 3
	sub 	edi, [ScreenXTotal]
	sub 	edi, [BytesPerPixel]
DrawSquareRight:
	stosd
	sub 	edi, [ScreenXTotal]
	sub 	edi, [BytesPerPixel]
	loop 	DrawSquareRight
	add 	edi, [ScreenXTotal]
	sub 	edi, [BytesPerPixel]
	mov 	cx, 4
DrawSquareUp:
	stosd
	sub 	edi, 8
	loop 	DrawSquareUp
	mov 	cx, 2
	add 	edi, [ScreenXTotal]
	add 	edi, [BytesPerPixel]
DrawSquareLeft:
	stosd
	add 	edi, [ScreenXTotal]
	sub 	edi, [BytesPerPixel]
	loop 	DrawSquareLeft
	mov 	dx, WORD [WINDOW_POSITIONX_A]
	mov 	cx, WIDTH_B
	sub 	dx, (WIDTH_B+PADDING_RIGHT)
	shl 	edx, 16
	shl 	ecx, 16
	mov 	dx, WORD [WINDOW_POSITIONY_A]
	mov 	cx, HEIGHT_B
DrawBMin:
	mov 	bx, WORD [MainProperty]
	and 	bx, BUTTON_MINIMIZE
	jz 		ReturnDrawButtons
	xor 	eax, eax            
	mov 	ebx, 0x2090
	mov 	DWORD[But_Colors+8], 0x000025FF
	int 	0xCD
	pop 	ebx
	inc 	bx
	push 	ebx
	mov 	cx, 3
OffsetUp:
	sub 	edi, [ScreenXTotal]
	loop 	OffsetUp
	add 	edi, 8
	mov 	eax, 0xFFFFFFFF
	mov 	cx, 5
DrawLineButton:
	stosd
	loop 	DrawLineButton
ReturnDrawButtons:
	pop 	ebx
	pop 	edi
	mov 	eax, ebx
	
	
; Fim de desenho das janelas internas e botões do topo
; =============================================================================

ReturnMainWindow:
	retf

But_Colors   dd 0,0,0	
MainProperty dw 0
	
; Fim de desenho da janela principal
; **************************************************************


BMPImageLoad:
	mov 	ebx, esi
	add 	esi, DWORD [ebx+BMP_LENGTH]
	add 	esi, (24/8)            ; 24 BPP / 8 = 3 Bytes
	mov 	cx, WORD [ebx+BMP_DIMENS_X]
	mov 	eax, (24/8)        	   ; 244 BPP / 8 = 3 Bytes
	mul 	cx
	xor 	edx, edx
	mov 	dx, ax
	mov 	cx, WORD [ebx+BMP_DIMENS_Y]
PaintImg:
	push 	cx
	mov 	cx, WORD [ebx+BMP_DIMENS_X]
	push 	edi
LoopPaint: 
 	sub  	esi, (24/8)  
	push 	ecx  
	mov 	ecx, (24/8) 
Move32bpp: 	movsb
	loop 	Move32bpp
	mov 	byte [edi], 0xFF
	inc 	edi
	sub 	esi, (24/8) 
	pop 	ecx
	loop 	LoopPaint
	pop 	edi
	add 	edi, [ScreenXTotal]
	pop 	cx
	loop 	PaintImg
	
ret
	
ImageDraw:
	mov 	cx, WORD [ebx+BMP_DIMENS_Y]
	mov 	dx, WORD [ebx+BMP_DIMENS_X]
Copy:
	pushad
	mov 	ecx, edx
CopyBuffer: movsd
	loop 	CopyBuffer
	popad
	add 	edi, [ScreenXTotal]
	add 	esi, [ScreenXTotal]
	loop 	Copy
ret

Show_Window:
	mov 	esi, IPT.Base
	mov 	eax, IPT.Size
	mul 	ebx
	add 	esi, eax
	mov 	bx, WORD [esi + IPT.Prop]
	and 	bx, VISIBILITY
	jz 		RetShow_Window
	mov 	cx, WORD [esi + IPT.Heig]
	mov 	dx, WORD [esi + IPT.WidT]
	mov 	edi, DWORD [esi + IPT.BegP]
	mov 	esi, DWORD [esi + IPT.FrmW]
WindowCopy:
	pushad
	mov 	ecx, edx
CopyLine:	movsd
	loop 	CopyLine
	popad
	add 	edi, [ScreenXTotal]
	add 	esi, [ScreenXTotal]
	loop 	WindowCopy
RetShow_Window:
	retf
	
Os_WinMng_Setup:
	xor 	eax, eax
	xor 	ebx, ebx
	mov 	al, BYTE [BPP_MODE]
	shr 	eax, 3         ; 32 / 8 = 4 bytes
	mov     [BytesPerPixel], eax
	mul     WORD [SCREEN_X]
	mov     [ScreenXTotal], eax
	mov 	bx, WORD [SCREEN_Y]
	mul 	ebx
	mov 	[FRAMES_OFF], eax
	mov 	ecx, 4
	xor 	ebx, ebx
	mov 	eax, [LFBADDR]
InitConfig:
	mov 	[FRAMES_BUF + ebx], eax
	add 	eax, [FRAMES_OFF]
	add 	ebx, 4
	loop 	InitConfig
	sub 	eax, [MVIDEO_BUF]
	mov     [FRAMES_BUF + ebx], eax
	
	
	mov 	dword[MEMORY_BMP], 0x500000
	
	mov 	eax, 0x0A
	mov 	edi, DWORD[MEMORY_BMP]
	mov 	esi, WallPaper1
	int 	0xCE
	jnc 	PaintWallPaper
	jmp 	CreateObjects
PaintWallPaper:
	mov 	esi, DWORD [MEMORY_BMP]   ; Image Buffer
	mov 	edi, DWORD [MSPACE_BUF]   ; Double_Buffer
	call 	BMPImageLoad
	mov 	esi, DWORD [MSPACE_BUF]
	mov 	edi, DWORD [MVIDEO_BUF]
	call 	ImageDraw
	

CreateObjects:
	push 	dword COLORS     ; Top, Borders, Back	
	push 	dword 0x00000001          ; ID = 1
	xor 	eax, eax         ; Function 0
	mov 	esi, TitleWindow ; Window Title
	mov 	edi, WallPaper1    ; Window Icon Path
	mov 	ebx, 0x609F      ; Window´s Properties
	mov 	ecx, 0x014600D8  ; 144x112 = WidthxHeight
	mov 	edx, 0x000A0010  ; X = 10, Y = 16
	mov 	DWORD[COLORS],   0x000000FF  ; Top Color
	mov 	DWORD[COLORS+4], 0x1000FF00  ; Border Color
	mov 	DWORD[COLORS+8], 0xFFFFFFFF  ; Back Color
	int 	0xCD             ; Return -> EAX = ID Next Element
	pop 	DWORD [Win1]

	and 	eax, 0xFFFF
	mov 	[Next], eax
	
	push 	dword[Next]      ; ID = Next ID Window
	xor 	eax, eax         ; Function 0
	mov 	esi, TitleWindow ; Window Title
	mov 	edi, Flowers    ; Window Icon Path
	mov 	ebx, 0x609F      ; Window´s Properties, ID = 3
	mov 	ecx, 0x010A0100  ; 144x112 = WidthxHeight
	mov 	edx, 0x015A0010  ; X = 170, Y = 16
	mov 	DWORD[COLORS],   0x0000FF00	  ; Top Color
	mov 	DWORD[COLORS+4], 0x000000FF   ; Border Color
	mov 	DWORD[COLORS+8], 0x00FF0000   ; Back Color
	int 	0xCD             ; Invoke the Windows
	pop 	DWORD [Win2]
	and 	eax, 0xFFFF
	mov 	[Next], eax
	pop 	edi
	
	; First Window Image
	mov 	eax, 0x0A
	mov 	edi, DWORD[MEMORY_BMP]
	mov 	esi, Flowers
	int 	0xCE ; Load BMP File
	mov 	eax, 1
	mov 	ebx, [Win1]
	int 	0xCD ; Show Window
	mov 	esi, DWORD [MEMORY_BMP]   ; Image Buffer
	mov 	edi, DWORD [MSPACE_BUF]   ; Double_Buffer
	call 	BMPImageLoad ; Create Image
	mov 	esi, DWORD [MSPACE_BUF]
	mov 	edi, DWORD [MVIDEO_BUF]
	add 	edi, 13 * 4
	mov 	eax, [ScreenXTotal]
	mov 	ecx, 29
	mul 	ecx
	add 	edi, eax
	call 	ImageDraw ; Show Image
	
; 	Second Window Image
	mov 	eax, 0x0A
	mov 	edi, DWORD[MEMORY_BMP]
	mov 	esi, GoogleImg
	int 	0xCE
	mov 	eax, 1
	mov 	ebx, [Win2]
	int 	0xCD
	mov 	esi, DWORD [MEMORY_BMP]   ; Image Buffer
	mov 	edi, DWORD [MSPACE_BUF]   ; Double_Buffer
	call 	BMPImageLoad
	mov 	esi, DWORD [MSPACE_BUF]
	mov 	edi, DWORD [MVIDEO_BUF]
	add 	edi, 0x15D * 4
	mov 	eax, [ScreenXTotal]
	mov 	ecx, 29
	mul 	ecx
	add 	edi, eax
	call 	ImageDraw
	
ReturnF:
	retf
	
	WallPaper1	db  "FOREST1 BMP"
	Flowers 	db  "WELCOME BMP"  ; "FLOWER1 BMP"
	GoogleImg	db  "BROWSER BMP"
			
	TitleWindow db "My transparent Window"
	COLORS      dd 0, 0, 0
	Win1 dd 0
	Win2 dd 0
	Next dd 0
	
; -----------------------------------------------
; Rotina de cópia de janelas 24 bits
;WindowsDraw42bit:
;	mov 	cx, WORD [WINDOW_HEIGHT_A]
;WindowCopy24:
;	push 	ecx
;	push 	edi
;	push 	esi
;	mov 	ecx, eax
;	cmp 	ecx, 0
;	je 		RestProcess24
;CopyLine24: movsd
;	loop 	CopyLine24
;RestProcess24:
;	mov 	ecx, edx
;	cmp 	ecx, 0
;	je 		NextLine24
;CopyRest24:	movsb
;	loop 	CopyRest24
;NextLine24:
;	pop 	esi
;	pop 	edi
;	pop 	ecx
;	add 	edi, [ScreenXTotal]
;	add 	esi, [ScreenXTotal]
;	loop 	WindowCopy24
;ret
; -----------------------------------------------

; -----------------------------------------------
; Rotina teste de arrastamento de janelas
;	mov 	ecx, 80
;Test_Moviment:
;	push 	ecx
;	push 	esi
;	push 	edi
;	
;	mov 	eax, 1
;	mov 	ebx, 1
;	int 	0xCD
;
;	pop 	edi
;;	pop 	esi
;	pop 	ecx
;	
;	add 	edi, 8
;	loop 	Test_Moviment
; -----------------------------------------------

WindowCreate: ret

; Executa a chamada de Movimento da janela com sobreposições de pixels
;_________________________________________________________________________
NextStep:
	cmp byte[IsMovable], MOVABLE
	call WindowMoviment 
	jmp RetMovement

WindowMoviment:
	cmp byte[IsMovable], MOVABLE
	ja RetMovement
	jb WaitToEnd 
	LoopMoviment:
		call KEYBOARD_HANDLER
		cmp byte[fs:KEYCODE], K_F1
		je RetMovement
		call VerifyKey
		cmp al, 0
		je LoopMoviment
		cmp al, 2
		je RetMovement
		jmp LoopMoviment
WaitToEnd:
	call KEYBOARD_HANDLER
	cmp byte[fs:KEYCODE], K_F1
	jne WaitToEnd
RetMovement:
	ret
;_________________________________________________________________________


; Rotina que salva valores dos parâmetros: X, Y, W, H
;_________________________________________________________________________
SaveValues:
	cmp cx, MIN_WIDTH_SIZE
	jb ChangeWidth
Cond2:
	cmp dx, MIN_HEIGHT_SIZE
	jb ChangeHeight
	SaveNow:
		mov word[PositionX], ax
		mov word[PositionY], bx
		mov word[WidthWindow], cx
		mov word[HeightWindow], dx
		mov word[W_Width], cx
		mov word[W_Height], dx
		add word[WidthWindow], 3
		add word[HeightWindow], 12
		jmp RetSaveValues
	ChangeWidth:
		mov cx, 50
		jmp Cond2
	ChangeHeight:
		mov dx, 45
		jmp SaveNow
RetSaveValues:
	ret
;_________________________________________________________________________


; Rotinas de armazenamento de pixels na memória chamadas pelas Macros:
; SaveInMemory & GetInMemory. 
; Ambas as rotinas para sobreposição de pixels
;_________________________________________________________________________


; Captura e armazena pixels do fundo ou da janela atual
;_________________________________________________________________________
SaveColorWindow:
	mov ah, 0Dh
	mov cx, word[PositionX]
	mov dx, word[PositionY]
	call AddSize
	mov es, bx 
	xor bx, bx
	GetColor:
		int 10h
		mov byte[es:di + bx], al
		inc cx
		inc bx
		cmp cx, word[WidthWindow]
		jne GetColor
		mov cx, word[PositionX]
		inc dx
		cmp dx, word[HeightWindow]
		jne GetColor
ret

AddSize:
	cmp al, 1
	jne RetAdd
	add word[WidthWindow], cx
	add word[HeightWindow], dx
RetAdd:
	ret
;_________________________________________________________________________


; Apaga e redesenha janela com pixels salvos por SaveColorWindow
;_________________________________________________________________________
RepaintWindow:
	mov ah, 0Ch
	mov cx, word[PositionX]
	mov dx, word[PositionY]
	mov es, bx  
	xor bx, bx
	Repaint1:
		mov al, byte[es:di + bx]
		int 10h
		inc cx
		inc bx
		cmp cx, word[WidthWindow]
		jne Repaint1
		mov cx, word[PositionX]
		inc dx
		cmp dx, word[HeightWindow]
		jne Repaint1
ret


;_________________________________________________________________________


; Rotina de verificação de teclas
; Aqui é controlado as funcionalidades de movimentação e
; redimensionamento da janela através de teclas definidas
; ________________________________________________________________________
VerifyKey:
	cmp byte[fs:CursorFocus], 1
	je CursorIsFocus
	cmp byte[fs:KEYCODE], ARROW_RIGHT
	je IncRight
	cmp byte[fs:KEYCODE], ARROW_LEFT
	je DecLeft
	cmp byte[fs:KEYCODE], ARROW_DOWN
	je IncDown
	cmp byte[fs:KEYCODE], ARROW_UP
	je DecUp
	cmp byte[fs:KEYCODE], CTRL_D
	je ResizeRight
	cmp byte[fs:KEYCODE], CTRL_A
	je ResizeLeft
	cmp byte[fs:KEYCODE], CTRL_S
	je ResizeDown
	cmp byte[fs:KEYCODE], CTRL_W
	je ResizeUp
	cmp byte[fs:KEYCODE], CTRL_Z
	je ChangeToWall
	cmp byte[fs:KEYCODE], CTRL_X
	je ChangeToIron
	;cmp al, OUTRA_TECLA   -> Descomente para adicionar outras teclas
	;je AlgumaRotina          de controle para outra rotina
	mov al, 0
	jmp RetVerifyKey
CursorIsFocus:
	mov al, 0
ret
IncRight:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2  ;move 2 pixels
	call UpdatePosRight
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
DecLeft:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2   ;move 2 pixels
	call UpdatePosLeft
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
IncDown:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2  ;move 2 pixels
	call UpdatePosDown
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
DecUp:
	SaveInMemory REPAINT, WIND, 0
	GetInMemory ERASE, BACK
	mov ax, 2  ;move 2 pixels
	call UpdatePosUp
	mov al, 1
	SaveInMemory ERASE, BACK, 0
	GetInMemory REPAINT, WIND
	jmp RetVerifyKey
ResizeRight:
	GetInMemory ERASE, BACK
	inc word[W_Width]
	jmp ResizeWindow
ResizeLeft:
	GetInMemory ERASE, BACK
	dec word[W_Width]
	jmp ResizeWindow
ResizeDown:
	GetInMemory ERASE, BACK
	inc word[W_Height]
	jmp ResizeWindow
ResizeUp:
	GetInMemory ERASE, BACK
	dec word[W_Height]
	jmp ResizeWindow
ChangeToWall:
	mov al, 2
	;mov cx, _WALL
ret
ChangeToIron:
	mov al, 2
	;mov cx, _IRON
ret
; __________________________________________________________________________________
;
; ADICIONE AQUI OUTRAS ROTINAS DE FUNCIONALIDADE PELAS TECLAS...
; Exemplo -> AlgumaRotina:
;				Códigos...
;			 jmp RetVerifyKey
; __________________________________________________________________________________

RetVerifyKey:
	mov cx, word[PositionX]
	mov dx, word[PositionY]
ret

; Atualizador de posições do redirecionamento de teclas (TextFields) e
; do redesenho da janela durante a movimentação
; ________________________________________________________________________
UpdatePosRight: ;atualiza todas as posições para a direita
	add word[PositionX], ax
	add word[WidthWindow], ax
	add word[fs:POSITION_X], ax
	add word[fs:LIMIT_COLX], ax
	add word[fs:LIMIT_COLW], ax
	mov cl, 0
	xor bx,bx
UpdateR:
	add word[fs:POSITIONS + bx], ax 
	add bx, 4
	add word[fs:POSITIONS + bx], ax
	add bx, ax
	add word[fs:POSITIONS + bx], ax
	add bx, 6
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateR
ret

UpdatePosLeft:	;atualiza todas as posições para a esquerda
	sub word[PositionX], ax
	sub word[WidthWindow], ax
	sub word[fs:POSITION_X], ax
	sub word[fs:LIMIT_COLX], ax
	sub word[fs:LIMIT_COLW], ax
	mov cl, 0
	xor bx,bx
UpdateL:
	sub word[fs:POSITIONS + bx], ax 
	add bx, 4
	sub word[fs:POSITIONS + bx], ax
	add bx, ax
	sub word[fs:POSITIONS + bx], ax
	add bx, 6
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateL
ret

UpdatePosDown:		;atualiza todas as posições para baixo
	add word[PositionY], ax
	add word[HeightWindow], ax
	add word[fs:POSITION_Y], ax
	mov cl, 0
	xor bx,bx
	add bx, ax
UpdateD:
	add word[fs:POSITIONS + bx], ax
	add bx, 12 ;8
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateD
ret

UpdatePosUp:	;atualiza todas as posições para cima
	sub word[PositionY], ax
	sub word[HeightWindow], ax
	sub word[fs:POSITION_Y], ax
	mov cl, 0
	xor bx,bx
	add bx, ax
UpdateU:
	sub word[fs:POSITIONS + bx], ax
	add bx, 12 ;8
	inc cl
	cmp cl, byte[fs:QUANT_FIELD]
	jne UpdateU
ret

Rewriter: ;analise
	call WriteESC
	xor bx, bx
LoopTab:
	push bx
	call WriteTAB
	call WriteChars
	pop bx
	inc bl
	cmp bl, byte[fs:QUANT_FIELD]
	jne LoopTab
	call WriteTAB
	call WriteESC
ret
WriteESC:
	mov al, K_ESC
	__FontsWriter KEY
WriteTAB:
	mov al, K_TAB
	__FontsWriter KEY
WriteChars:
	mov word[fs:QUANT_KEY], 0000h
	mov si, word[fs:C_ADDR]
	dec si
	GetChars:
		inc si
		mov al, byte[ds:si]
		cmp al, 0
		je RetWriteChars
		push si
		call WriteFont
		pop si
		jmp GetChars
WriteFont:
	__FontsWriter KEY
RetWriteChars:
	ret

; ________________________________________________________________________


; Rotina de redimensionamento de janela que captura valores
; pré-alterados pelas rotinas anteriores, Dependendo da tecla
; uma rotina diferente é executada, chamando como última a esta.
; __________________________________________________________________________________
ResizeWindow:
	mov byte[fs:QUANT_FIELD], 0
	mov byte[fs:CountField], -1
	mov word[fs:QuantPos], 0000h
	mov byte[fs:QuantTab], 0
	mov word[CountPositions], 0000h
	mov byte[fs:StatusLimitW], 0
	mov byte[fs:StatusLimitX], 0
	mov byte[fs:CursorTab], 0
	Window3D MOVABLE+1, word[PositionX],word[PositionY],word[W_Width],word[W_Height]
	call Rewriter
	mov al, 0
ret
	
; __________________________________________________________________________________




; Referências de memória base para manipular e guardar 
; valores utilizados na movimentação e redimensionamento
; de janelas
; __________________________________________________________________________________

PositionX 	  dw 0000h
PositionY 	  dw 0000h
WidthWindow   dw 0000h
HeightWindow  dw 0000h
W_Width       dw 0000h
W_Height      dw 0000h
IsMovable     db 1
ValuePosition dw 0000h

; __________________________________________________________________________________


; Referências de memória para armazenar e manipular valores durante
; o processo de desenho dos papéis de parede
; __________________________________________________________________________________

obj_quantX     dw 0000h
obj_quantY     dw 0000h
CountWallX     dw 0000h
CountWallY     dw 0000h
LastBlockSaveX dw 0000h
LastBlockSaveY dw 0000h
StateObj       db 0
StateBlockX    db 0
StateBlockY    db 0

; __________________________________________________________________________________