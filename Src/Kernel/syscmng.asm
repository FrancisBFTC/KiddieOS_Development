%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
%INCLUDE "Hardware/iodevice.lib"

[BITS 16]
[ORG SYSCMNG] 

jmp 	SwitchTo32BIT	;_SYSCALL_MAIN


STACK32_TOP  	EQU 0x200000
CODE32_VRAM  	EQU 0x100000
VIDEO_MEMORY    EQU 0x0B8000
PROGRAM_BUFFER  EQU 0x50000  ; 0005h:0000h, buffer para programas
PROGRAM_VRAM    EQU CODE32_VRAM+0x4000
 
Return_Value dw 0
Counter 	 db 0
Params       dd 0
ArgsAddr 	 dd 0
Out_Of_Shell db 0
ack_net_int  db 0


; ==================================================================
; Inicializaçao da chamada de programas e mudanças do processador

_SYSCALL_MAIN:
	
	


; ==================================================================
	
	
SwitchTo32BIT:
	mov 	byte[Out_Of_Shell], bl
	
	call 	EnableA20       ; Habilite o portão A20 (usa o método rápido como prova de conceito)
	
	
	mov 	dword[ArgsAddr], esi
	shl 	ecx, 16
	mov 	cx, dx
	mov 	dword[Params], ecx
	
	;push 	dx
	
	
	; ICW1 - Reinicializar faz o PIC esperar ao menos 3 words
	; de configuração
    __WritePort 0x20, 0x11  ; Reinicia o controlador
    __WritePort 0xA0, 0x11

   ; ICW2 - Deslocamento vetorial - Vetores de interrupção
   ; PIC mestre de dados (0x21) desloca IRQ0 para vetor 0x20
   ; PIC escravo de dados (0xA1) desloca IRQ8 para vetor 0x28
    __WritePort 0x21, 0x20  
    __WritePort 0xA1, 0x28

    ;// ICW3
    __WritePort 0x21, 0x04
    __WritePort 0xA1, 0x02

    ;// ICW4
    __WritePort 0x21, 0x01
    __WritePort 0xA1, 0x01

    ; // OCW1
	; Exemplo: BIT<0> de 0x21 = TIMER, BIT<1> de 0x21 = KEYBOARD
	; BIT<4> de 0xA1 = Mouse PS/2
    __WritePort 0x21, 11111011b  ; Desabilita todas as interrupções (Não-Mascaráveis)
    __WritePort 0xA1, 11111001b
	
	sti
	
	;pop 	dx
	
	mov		ax, 0x3000
	mov		ds,ax
	
    mov 	eax,cs          ; EAX = CS
    shl 	eax,4           ; EAX = (CS << 4)
    mov 	ebx,eax         ; Faça uma cópia de (CS << 4)
	
	cmp 	byte[Counter], 0
	ja 		NotLoadStructsAgain
	
	push 	eax
	
	push 	esi
	;push 	ecx
	
	mov 	si, IDT_Start
	mov 	di, Vector.Address 
	mov 	cx, IDTSIZE
FillIDT:
	mov 	eax, dword[di]
	and 	eax, 0x0000FFFF
	mov 	word[si], ax 
	mov 	eax, dword[di]
	and 	eax, 0xFFFF0000
	shr 	eax, 16
	mov 	word[si+6], ax
	add 	si, 8
	add 	di, 4
	loop 	FillIDT
	
	;pop 	ecx
	pop 	esi
	
	pop 	eax
	
	add 	[GDT+2], eax           ; Adicione o endereço linear básico ao endereço GDT_Start
    lgdt 	[GDT]
	add 	[IDT32+2], eax

	; Calcule o endereço linear dos rótulos usando (segmento << 4) + deslocamento.
    ; EBX já é (segmento << 4). Adicione-o aos deslocamentos dos rótulos para
    ; converta-os em endereços lineares
	
NotLoadStructsAgain:	
	lidt 	[IDT32]
	
	mov 	edi, ProtectedMode16     ;  EDI = entrada de modo protegido de 16 bits (endereço linear)
	add 	edi, ebx                 ;  Endereço linear de ProtectedMode16
	add 	ebx, Code32Bit  		 ;  EBX = (CS << 4) + Code32Bit
	
	;push 	dx
	;mov 	edx, ecx              ; Transfira quantidade de argumentos Shell
	;shl 	edx, 16               ; Para byte alto de EDX
	;pop 	dx
	
	push 	ds
	push 	es
	push 	fs
	push 	gs
	mov 	ecx, cs
	
    push 	dword CODE_SEG32            ; 0x08 = Seletor de codigo 32 bit em CS
    push	ebx            			    ; Deslocamento linear de Code32Bit
    mov 	bp, sp          			; Endereço m16:32 no topo da pilha, aponte BP para ele
	
	
    mov 	eax,cr0
    or 		eax,1
    mov 	cr0,eax         			; Definir sinalizador de modo protegido
	
    jmp 	dword far [bp]
                      	
; Habilite a20 (método rápido). Isso pode não funcionar em todos os hardwares
EnableA20:
    cli
    in 		al, 0x92         ; Leia a porta A de controle do sistema
    test 	al, 0x02         ; Teste o valor a20 atual (bit 1)
    jnz 	.skipfa20        ; Se já e 1, nao habilita
    or 		al, 0x02         ; Defina A20 bit (bit 1) como 1
    and 	al, 0xfe         ; Sempre escreva um zero no bit 0 para evitar
                             ;     uma reinicialização rápida em modo real
    out 	0x92, al         ; Habilite linha A20
.skipfa20:
    sti
ret


; Ponto de entrada e código de modo protegido de 16 bits
ProtectedMode16:
	mov 	word[Return_Value], ax
    mov 	ax, DATA_SEG16       ; Defina todos os segmentos de dados para o seletor de dados de 16 bits
    mov 	ds, ax
    mov 	es, ax
    mov 	fs, ax
    mov 	gs, ax
    mov 	ss, ax
	
	; Desativar paginação (bit 31) e modo protegido (bit 0)
    ; O kernel terá que se certificar de que o GDT está em
    ; a 1:1 (página de identidade mapeada), bem como memória inferior
    ; onde o programa DOS reside antes de retornar
    ; para nós com um RETF
	mov 	eax, cr0              ; Disable protected mode
    and 	eax, 0x7FFFFFFE     
	mov 	cr0, eax
	
	
	jmp 	0x3000:RealMode16
	;push 	cx
	;push 	RealMode16
	;retf
	
; Ponto de entrada de modo real de 16 bits
RealMode16:
	xor 	esp, esp          ; Limpar todos os bits no ESP
	mov 	ss, dx            ; Restaura o segmento de pilha de modo real
	lea 	sp, [bp+8]        ; Restaurar SP em modo real
	
	; (BP + 8 para pular o ponto de entrada de 32 bits e o seletor que
	; foi colocado na pilha em modo real)
	
    pop 	gs                      ; Restaurar o resto do segmento de dados de modo real
	pop 	fs
	pop 	es
	pop 	ds

	lidt 	[IDT16]                 ; Restaura a tabela de interrupção de modo real
    
	cli
	__WritePort 0x20, 0x11  ; Restaura controlador PIC
    __WritePort 0xA0, 0x11
	__WritePort 0x21, 0x08
    __WritePort 0xA1, 0x70
	__WritePort 0x21, 0x00
    __WritePort 0xA1, 0x00
    __WritePort 0x21, 0x00
    __WritePort 0xA1, 0x00
    __WritePort 0x21, 0x00
    __WritePort 0xA1, 0x00
	sti
	
	inc 	byte[Counter]
ret

; --------------------------------------------

Ini_Mode8086: call 	bx

; Pode ser inserido outras rotinas v86 aqui

mov 	eax, 0xFFFF
jmp 	$
	
; --------------------------------------------

ERROR:
	int 0x18
	
%INCLUDE "Hardware/gdtidt_x86.lib"



; Código que será executado no modo protegido de 32 bits
;
; Após a entrada, os registros contêm:
; EDI = entrada de modo protegido de 16 bits (endereço linear)
; ESI = buffer de memória do programa (endereço linear)
; EBX = Code32Bit (endereço linear)
; ECX = segmento de código de modo real DOS
;ALIGN 4
Code32Bit:
BITS 32

%DEFINE PM_MODE_VSTART 1	
SECTION protectedmode vstart=CODE32_VRAM, valign=4

Start32:
	mov 	ebp, esp
	mov 	edx, ss
	
    cld
    mov 	eax,DATA_SEG32              ; 0x10 = é um seletor plano para dados
    mov 	ds,eax
    mov 	es,eax
    mov 	fs,eax
    mov 	gs,eax
    mov 	ss,eax
    mov 	esp,STACK32_TOP             ; Deve definir ESP para um local de memória utilizável
	
	;push 	CODE_SEG16                 ; Coloque o ponto de entrada remoto 0x18 do modo protegido de 16 bits: ProtectedMode16
    ;push 	edi
	
	push 	edx
	push 	ebp
	push 	ecx
	
	; A pilha vai crescer para baixo a partir deste local
	push 	esi
	mov 	edi,CODE32_VRAM    ; EDI = endereço linear onde o código PM será copiado
    mov 	esi,ebx            ; ESI = endereço linear de Code32Bit
    mov 	ecx,PMSIZE_LONG    ; ECX = número de DWORDs para copiar
    rep 	movsd              ; Copie todos os códigos/dados de Code32Bit para CODE32_VRAM
	pop 	esi
	call 	CODE_SEG32:EntryCode32
	
	pop 	ecx
	pop 	ebp
	pop 	edx
	
	; Elimina a necessidade dos dois PUSH's comentados lá em cima
	jmp 	CODE_SEG16:ProtectedMode16+0x30000
	;retf		; Era isto
	

EntryCode32:
	mov 	esi, dword[ArgsAddr+0x30000]
	mov 	eax, dword[Params+0x30000]
	mov 	byte[CursorRaw], ah
	mov 	byte[CursorCol], al
	shr 	eax, 16

	; Argumentos de linha de comando
	push 	eax		; EAX => 1ª parâmetro da função MAIN (ARGC)
	push 	esi		; ESI => 2ª parâmetro da função MAIN (ARGV)
	
	cmp 	byte[Counter+0x30000], 0
	ja 		NoLoadTSSAgain
	mov 	dword[TSS.ESP0], esp
	mov 	word [TSS.SS0],  ss
	mov 	ax, 0x28
	ltr 	ax
NoLoadTSSAgain:
		
	mov 	edi,PROGRAM_VRAM       ; EDI = Endereço linear para onde o programa sera copiado
    mov 	esi,PROGRAM_BUFFER     ; ESI = Endereço Linear do programa (0x0900:0)
    mov 	ecx, DWORD[PROGRAM_BUFFER+5]              ; ECX = numero de DWORDs para copiar
    rep 	movsb	   	           ; Copiar todas as ECX dwords de ESI para EDI 
    call 	CODE_SEG32:PROGRAM_VRAM   ; Salto absoluto para o novo endereço
	
	pop 	esi
	pop 	ecx
	
	mov 	WORD [Return_Value], ax
	
	cmp 	byte[Out_Of_Shell+0x30000], 1
	je 		ClearCursorCol
	mov 	byte[CursorCol], 12
	jmp 	DefineCursors
ClearCursorCol:
	mov 	byte[CursorCol], 0
DefineCursors:
	mov 	byte[Out_Of_Shell+0x30000], 0
	mov 	dh, byte[CursorRaw]
	mov 	dl, byte[CursorCol]
	mov 	si, dx
	
	; --------------------------------------------------
	; Program trash cleaner in the RAM memory 
	push 	eax
	xor 	eax, eax
	mov 	edi, PROGRAM_VRAM
	mov 	ecx, DWORD[PROGRAM_BUFFER+5]
	push 	ecx
	rep 	stosb
	
	pop 	ecx
	mov 	edi, PROGRAM_BUFFER
	rep 	stosb
	pop 	eax	
	; --------------------------------------------------
	
retf
WindowManager  db "WINMNG32KXE"


BITS 32
LIB_String32:
	push 	ebx
	xor 	ebx, ebx
	mov 	bx, ax
	shl 	ebx, 2
	mov 	ebx, dword[MonitorRoutines + ebx]
	jmp 	ebx
	
MonitorRoutines:
	dd Print_String32           ; Função 0 (0x00)
	dd Print_Zero_Terminated    ; Função 1 (0x01)
	dd Get_String               ; Função 2 (0x02)
	TIMES 7 dd 0                ; Função 3 a 9 (0x03 a 0x09) - Reservadas p/ rotinas de Strings
	dd Load_File                ; Função 10 (0x0A)
	TIMES 9 dd 0                ; Função 11 a 19 (0x0B a 0x13) - Reservadas p/ rotinas de Arquivos
	dd Init_Device              ; Função 20 (0x14)
	dd Close_Device             ; Função 21 (0x15)
	dd Get_Class                ; Função 22 (0x16)
	dd Get_SubClass             ; Função 23 (0x17)
	dd Get_Interface            ; Função 24 (0x18)
	dd Get_Device               ; Função 25 (0x19)
	dd Get_Vendor               ; Função 26 (0x1A)
	dd Get_Classes              ; Função 27 (0x1B)
	
	; TODO alterar o lugar das ISRs abaixo p/ rotinas de Strings
	dd Get_Hexa_Value32         ; Função 28 (0x1C)
	dd Get_Hexa_Value16         ; Função 29 (0x1D)
	dd Get_Dec_Value32          ; Função 30 (0x1E)
	dd Malloc		            ; Função 31 (0x1F)
	dd Free 		            ; Função 32 (0x20)
	dd Float_To_String 			; Função 33 (0x21)
	dd Get_Hexa_Value8          ; Função 34 (0x22)
	
	; Rotinas de serviços de IRQs
	dd IRQ_Handler_Register 	; Função 35 (0x23)
	
Print_String32:
	pop 	ebx
	pushad
	push 	edx
	push 	ecx
	xor 	cx, cx
	xor 	eax, eax
	mov 	edi, VIDEO_MEMORY
	mov 	dh, byte[CursorRaw]
	mov 	al, (80*2)
	mov 	cl, dh
	mul 	cl
	mov 	cl, byte[CursorCol]
	shl 	cl, 1
	add 	ax, cx
	add 	edi, eax
	pop 	ecx
	pop 	edx
Print_S:
    mov 	al,byte [ds:esi]
    mov 	byte [edi],al 
    inc 	edi 
    mov 	al, dl
    mov 	byte [edi],al 
	inc 	esi
	inc 	edi
	loop 	Print_S
	popad
	inc 	byte[CursorRaw]
iretd
CursorRaw  db 0
CursorCol  db 0

Print_Zero_Terminated:
	pop 	ebx
	pushad
InitCoord:
	push 	edx
	xor 	cx, cx
	xor 	eax, eax
	mov 	edi, VIDEO_MEMORY
	mov 	dh, byte[CursorRaw]
	mov 	al, (80*2)
	mov 	cl, dh
	mul 	cl
	mov 	cl, byte[CursorCol]
	shl 	cl, 1
	add 	ax, cx
	add 	edi, eax
	pop 	edx
Start_PZT:
	mov 	al,byte [ds:esi]
	cmp 	al, 0x0D
	je      LineBreak
    mov     al,byte [ds:esi]
	cmp 	al, 0
	jz 		Exit_PZT
    mov     byte [edi],al 
    inc     edi 
    mov     al, dl
    mov     byte [edi],al 
	inc 	esi
	inc 	edi
	inc 	byte[CursorCol]
	jmp 	Start_PZT
LineBreak:
	push 	edx
	inc 	byte[CursorRaw]
	cmp 	byte[CursorRaw], 25
	jnz 	NoScrollingScreen
;Wait_Enter_Key:
;	__ReadPort 	0x60
;	cmp 	al, 0x9C
;	jnz 	Wait_Enter_Key
	call 	ScrollingScreen
NoScrollingScreen:
	pop 	edx
	cmp 	byte[Out_Of_Shell+0x30000], 1
	je 		ClearCursorCol1
	mov 	byte[CursorCol], 12
	jmp 	NoClearCol
ClearCursorCol1:
	mov 	byte[CursorCol], 0
NoClearCol:
	inc 	esi
	add 	edi, 2
	jmp 	InitCoord
Exit_PZT:
	popad
	;inc 	byte[CursorRaw]
iretd

ScrollingScreen:
	pushad
	cld
	dec 	byte[CursorRaw]
	mov 	edi, VIDEO_MEMORY
	mov 	esi, VIDEO_MEMORY+(80*2)
	mov 	ecx, (80*2)*(25-1)
	rep 	movsb
	mov 	ecx, (80*2)
	xor 	eax, eax
	mov 	edi, VIDEO_MEMORY+(80*2)*(25-1)
	rep 	stosb
	popad
ret

Get_String:
	pop 	ebx
	pushad
	;mov 	al,byte [esi]
    ;mov 	byte [ds:edi],al 
	;inc 	edi
	;add 	esi, 2
	mov 	esi, VIDEO_MEMORY
	mov 	al, 160
	mul 	dl
	mov 	bh, dh
	shl 	bh, 1
	add 	ax, bx
	add 	esi, eax
Get_S:
    movsb       
    inc 	esi
    loop 	Get_S
    popad
iretd

Get_Hexa_Value32:
	pop 	ebx
	pushad
	mov 	esi, ebx
	mov 	edx, 0xF0000000
	mov 	cl, 28
Print_Hexa32:
	xor 	ebx, ebx
	mov 	ebx, esi
	and 	ebx, edx
	shr 	ebx, cl
	push 	esi
	mov 	esi, VetorHexa
	mov 	al, byte[esi + ebx]
	stosb
	pop 	esi
	cmp 	cl, 0
	jz      RetHexa32
	sub 	cl, 4
	shr 	edx, 4 
	jmp 	Print_Hexa32
	RetHexa32:
	popad
iretd
VetorHexa db "0123456789ABCDEF",0

Get_Hexa_Value8:
	pop 	ebx
	pushad
	XOR 	BH, BH
	mov 	SI, BX
	mov     DX, 0x00F0
	mov 	CL, 4
Print_Hexa8:
	xor 	EBX, EBX
	mov 	BX, SI
	and 	BX, DX
	shr 	BX, CL
	push 	SI
	mov 	esi, VetorHexa
	mov 	al, byte[esi + ebx]
	stosb
	pop 	SI
	cmp 	CL, 0
	jz      RetHexa8
	sub 	CL, 4
	shr 	DX, 4
	jmp 	Print_Hexa8
RetHexa8:
	popad
iretd

Get_Hexa_Value16:
	pop 	ebx
	pushad
	mov 	SI, BX
	mov     DX, 0xF000
	mov 	CL, 12
Print_Hexa16:
	xor 	EBX, EBX
	mov 	BX, SI
	and 	BX, DX
	shr 	BX, CL
	push 	SI
	mov 	esi, VetorHexa
	mov 	al, byte[esi + ebx]
	stosb
	pop 	SI
	cmp 	CL, 0
	jz      RetHexa
	sub 	CL, 4
	shr 	DX, 4
	jmp 	Print_Hexa16
RetHexa:
	popad
iretd


Get_Dec_Value32:
	pop 	ebx
	pushad
	mov 	esi, VetorDec
	mov 	eax, ebx
	cmp 	eax, 0
	je      ZeroAndExit
	test 	eax, (1 << 31)
	jz 		is_positive
	mov 	byte[edi], '-'
	inc 	edi
	not 	eax
	add 	eax, 1
is_positive:
	xor 	edx, edx
	mov 	ebx, 10
	mov 	ecx, 1000000000
DividePerECX:
	cmp 	eax, ecx
	jb      VerifyZero
	mov 	byte[Zero], 1
	push 	eax
	div 	ecx
	xor 	edx, edx
	push 	eax
	push 	ebx
	mov 	ebx, eax
	mov 	al, byte[esi + ebx]
	stosb
	pop 	ebx
	pop 	eax
	mul 	ecx
	mov 	edx, eax
	pop 	eax
	sub 	eax, edx
	xor 	edx, edx
DividePer10:
	cmp 	ecx, 1
	je      Ret_Dec32
	push 	eax
	mov 	eax, ecx
	div 	ebx
	mov 	ecx, eax
	pop 	eax
	jmp 	DividePerECX
VerifyZero:
	cmp 	byte[Zero], 0
	je      ContDividing
	push 	eax
	mov 	al, '0'
	stosb
	pop 	eax
ContDividing:
	jmp 	DividePer10
ZeroAndExit:
	mov 	al, '0'
	stosb
Ret_Dec32:
	mov 	byte[Zero], 0
	popad
iretd
Zero db 0
VetorDec db "0123456789",0

Float_To_String:
	pop 	ebx
	pushad
	mov 	esi, VetorDec
	mov 	eax, ebx
	cmp 	eax, 0
	je      ZeroAndExit_1
	mov 	[commacount], edx
	xor 	edx, edx
	mov 	ebx, 10
	mov 	ecx, 1000000000
DividePerECX_1:
	cmp 	eax, ecx
	jb      VerifyZero_1
	mov 	byte[Zero], 1
	push 	eax
	div 	ecx
	xor 	edx, edx
	push 	eax
	push 	ebx
	mov 	ebx, eax
	mov 	al, byte[esi + ebx]
	stosb
	pop 	ebx
	pop 	eax
	mul 	ecx
	mov 	edx, eax
	pop 	eax
	sub 	eax, edx
	xor 	edx, edx
DividePer10_1:
	cmp 	ecx, 1
	je      Ret_Dec32_1
	push 	eax
	mov 	eax, ecx
	div 	ebx
	mov 	ecx, eax
	pop 	eax
	jmp 	DividePerECX_1
VerifyZero_1:
	cmp 	byte[Zero], 0
	je      ContDividing_1
	push 	eax
	mov 	al, '0'
	stosb
	pop 	eax
ContDividing_1:
	jmp 	DividePer10_1
ZeroAndExit_1:
	mov 	al, '0'
	stosb
Ret_Dec32_1:
	mov 	byte[Zero], 0
	mov 	ecx, [commacount]
findpoint:
	dec 	edi
	mov 	al, [es:edi]
	mov 	[es:edi + 1], al
	loop 	findpoint
	mov 	al, '.'
	stosb
	
	popad
iretd
commacount dd 0


; ==============================================================
; Rotina que aloca uma quantidade de bytes e retorna endereço
; IN: ECX = Tamanho de Posições (Size)
;     EBX = Tamanho do Inteiro (SizeOf(int))

; OUT: EAX = Endereço Alocado
; ==============================================================
Malloc:
	pop 	ebx
	pushad
	
	mov  	edi, [0x104000+13]
	push 	edi
	
	cmp 	ebx, 1
	je 		Alloc_Size8
	cmp 	ebx, 2
	je 		Alloc_Size16
	cmp 	ebx, 4
	je 		Alloc_Size32
	jmp 	Return_Call
	
	Alloc_Size8:  
		mov 	dword[Size_Busy], ecx
		;rep 	stosb
		jmp 	Return_Call
	Alloc_Size16: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 1
		;rep 	stosw
		jmp 	Return_Call
	Alloc_Size32: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 2
		;rep 	stosd
		jmp 	Return_Call
	
Return_Call:
	pop 	DWORD[Return_Var_Calloc]
	popad
	mov 	eax, DWORD[Return_Var_Calloc]
	mov 	byte[Memory_Busy], 1
iretd

Return_Var_Calloc dd 0
Size_Busy         dd 0
Memory_Busy       db 0

; ==============================================================
; Libera espaço dado um endereço alocado
; IN: EBX = Ponteiro de Endereço Alocado
;
; OUT: Nenhum.
; ==============================================================
Free:
	pop 	ebx
	pushad
	mov 	edi, [ebx]
	mov 	dword[ebx], 0x00000000
	
	mov 	eax, 0
	mov 	ecx, [Size_Busy]
	rep 	stosb
	
	mov 	dword[Size_Busy], 0
	mov 	dword[Return_Var_Calloc], 0
	mov 	dword[Memory_Busy], 0
	popad
iretd


LoadFile               EQU (FAT16+9)
LoadRest               EQU (FAT16+12)
SYS.VM                 EQU ((FAT16+20) + 30000h)
PTR_FILE               EQU ((FAT16+21) + 30000h)
V86_STACK_SEG          EQU 0x0000  ; v8086 stack SS
V86_STACK_OFS          EQU 0x1990  ; v8086 stack SP
V86_CS_SEG             EQU 0x3000  ; v8086 code segment CS
EFLAGS_VM_BIT          EQU 17      ; EFLAGS VM bit
EFLAGS_BIT1            EQU 1       ; EFLAGS bit 1 (reserved, always 1)
EFLAGS_IF_BIT          EQU 9       ; EFLAGS IF bit
EFLAGS_ID_BIT          EQU 21
EFLAGS_VIF_BIT         EQU 19
EFLAGS_NT_BIT          EQU 14
TSS.EFLAGS             EQU TSS_Start.EFLAGS+30000h
TSS.EAX                EQU TSS_Start.EAX+30000h
TSS.EBX                EQU TSS_Start.EBX+30000h
TSS.ECX                EQU TSS_Start.ECX+30000h
TSS.EDX                EQU TSS_Start.EDX+30000h
TSS.ESP                EQU TSS_Start.ESP+30000h
TSS.EBP                EQU TSS_Start.EBP+30000h
TSS.ESI                EQU TSS_Start.ESI+30000h
TSS.EDI                EQU TSS_Start.EDI+30000h
TSS.ESP0               EQU TSS_Start.ESP0+30000h
TSS.SS0                EQU TSS_Start.SS0+30000h
TSS.ES                 EQU TSS_Start.ES+30000h
TSS.DS                 EQU TSS_Start.DS+30000h
TSS.FS                 EQU TSS_Start.FS+30000h
TSS.GS                 EQU TSS_Start.GS+30000h
TSS.SS                 EQU TSS_Start.SS+30000h

Load_File:
	pop 	ebx
	
	mov 	byte[SYS.VM], 1
	mov 	ecx, 11
	push 	edi
	push 	esi
	mov 	edi, PTR_FILE
	rep 	movsb
	pop 	esi
	pop 	edi
	
	mov 	ebx, LoadFile
	
	mov 	eax, cr4
	and 	eax, 0xFFFFFFFC
	or  	eax, 11b 	          ; -> CR4.PVI = 1, CR4.VME = 1
	mov 	cr4, eax
	
	mov 	dword[TSS.ESP0], esp
	
SwitchVMode:
	mov 	ecx, (512*1) / 4  ; BytesPerSector x SectorsPerCluster / DWORD_SIZE
	jmp 	Run8086Program

Back8086Program:
	mov 	ax, word[TSS.ES]
	mov 	es, ax
	mov 	ds, ax
	mov 	fs, ax
	mov 	gs, ax
	mov 	ss, ax
	mov 	eax, dword[TSS.EAX]
	mov 	ebx, dword[TSS.EBX]
	mov 	ecx, dword[TSS.ECX] 
	mov 	edx, dword[TSS.EDX]
	mov 	esp, dword[TSS.ESP]
	mov 	ebp, dword[TSS.EBP]
	mov 	edi, dword[TSS.EDI]
	mov 	esp, dword[TSS.ESP0]
	mov 	ss,  word[TSS.SS0]
CopyData:
	mov 	esi, 0x50000
	rep 	movsd
	mov 	esi, dword[TSS.ESI]
	mov 	ebx, LoadRest
	cmp 	byte[SYS.VM], 1
	je 		SwitchVMode
	mov 	ecx, (512*1) / 4
	mov 	eax, 0
	mov 	edi, 0x50000
	rep 	stosd
	mov 	eax, cr4
	and 	eax, 0xFFFFFFFC
	mov 	cr4, eax
iretd
	

Run8086Program:
	mov 	dword[TSS.EAX], eax
	mov 	dword[TSS.EBX], ebx
	mov 	dword[TSS.ECX], ecx
	mov 	dword[TSS.EDX], edx
	mov 	dword[TSS.ESP], esp
	mov 	dword[TSS.EBP], ebp
	mov 	dword[TSS.ESI], esi
	mov 	dword[TSS.EDI], edi
	mov 	ax, es
	mov 	word[TSS.ES], ax
	mov 	word[TSS.DS], ax
	mov 	word[TSS.FS], ax
	mov 	word[TSS.GS], ax
	mov 	word[TSS.SS], ax
	mov		ax, 0x0200
	mov  	edx, 0x3000
    push 	edx
    push 	edx
    push 	edx
    push 	edx
    push 	V86_STACK_SEG
    push 	V86_STACK_OFS
    push 	dword 1<<EFLAGS_VM_BIT | 1<<EFLAGS_BIT1 | 1<<EFLAGS_ID_BIT
    push 	V86_CS_SEG   
    push 	Ini_Mode8086
iret
	
PCI_ADDR 	EQU  0x150000
Init_Device:
	pop 	ebx
	pushad
	mov 	edi, PCI_ADDR       ; EDI = Endereço linear para onde o programa sera copiado
    mov 	esi, (PCI+0x30000)    ; ESI = Endereço Linear do programa (0x0900:0)
    mov 	ecx, (PCI_NUM_SECTORS*512)               ; ECX = numero de DWORDs para copiar
    rep 	movsb	   	           ; Copiar todas as ECX dwords de ESI para EDI
	
	call 	PCI_ADDR+(5*0)
	popad
iret

Close_Device:
	pop 	ebx
	pushad
	xor 	eax, eax
	mov 	edi, PCI_ADDR   
    mov 	ecx, ((PCI_NUM_SECTORS*512) / 4)
    rep 	stosd
	popad
iret

Get_Class:
	pop 	ebx
	push 	eax
	push 	ebx
	push 	ecx
	
	mov 	al, bh
    call 	PCI_ADDR+(5*1)
	
	pop 	ecx
	pop 	ebx
	pop 	eax
iret

Get_SubClass:
	pop 	ebx
	push 	eax
	push 	ebx
	push 	ecx
	
	mov 	al, bh
    call 	PCI_ADDR+(5*2)
	
	pop 	ecx
	pop 	ebx
	pop 	eax
iret

Get_Interface:
	pop 	ebx
	push 	eax
	push 	ebx
	push 	ecx
	
	mov 	al, bh
    call 	PCI_ADDR+(5*3)
	
	pop 	ecx
	pop 	ebx
	pop 	eax
iret

Get_Device:
	pop 	ebx
	push 	eax
	push 	ebx
	push 	ecx
	
	mov 	al, bh
    call 	PCI_ADDR+(5*4)
	
	pop 	ecx
	pop 	ebx
	pop 	eax
iret

Get_Vendor:
	pop 	ebx
	push 	eax
	push 	ebx
	push 	ecx
	
	mov 	al, bh
    call 	PCI_ADDR+(5*5)
	
	pop 	ecx
	pop 	ebx
	pop 	eax
iret

Get_Classes:
	pop 	ebx
	push 	ebx
	push 	ecx
	
	mov 	al, bh
    call 	PCI_ADDR+(5*6)
	
	pop 	ecx
	pop 	ebx
iret

IRQ_Handler_Register:
	pop 	ebx
	pushad
	
	shl 	ebx, 2
	mov 	eax, esi
	mov 	edi, IRQ_Table_Handler
	add 	edi, ebx
	stosd
	
	;mov 	[IRQ_Table_Handler + (ebx * 4)], esi
	
	popad
iretd


;----------------------------------------------------
; TODO criar mais ISRs aqui de Dispositivos
;----------------------------------------------------

LIB_Graphic32:
	push 	ebx
	xor 	ebx, ebx
	mov 	bx, ax
	shl 	ebx, 2
	mov 	ebx, dword[GraphicRoutines + ebx]
	jmp 	ebx
	
GraphicRoutines:
	dd Create_Window
	dd Show_Window

GUI_VARS    		   EQU  WINMNG+30000h   ;Info GUI Address
WINDOW_WIDTH_A     	   EQU  GUI_VARS+15
WINDOW_HEIGHT_A    	   EQU  GUI_VARS+17
WINDOW_POSITIONX_A 	   EQU  GUI_VARS+19
WINDOW_POSITIONY_A 	   EQU  GUI_VARS+21
WINDOW_BAR_COLOR_A 	   EQU  GUI_VARS+23
WINDOW_BORDER_COLOR_A  EQU  GUI_VARS+27
WINDOW_BACK_COLOR_A    EQU  GUI_VARS+31 
WINDOW_TITLE_BUFFER_A  EQU  GUI_VARS+35  
WINDOW_ICON_PATH_A     EQU  GUI_VARS+39  
WINDOW_PROPERTY_A      EQU  GUI_VARS+43  
WINDOW_ID_MASTER_A     EQU  GUI_VARS+45  
WINDOW_ID_SLAVE_A      EQU  GUI_VARS+47

Create_Window:
	pop 	ebx
	mov 	DWORD [WINDOW_TITLE_BUFFER_A], esi
	mov 	DWORD [WINDOW_ICON_PATH_A], edi
	mov 	WORD [WINDOW_PROPERTY_A], bx
	push 	ecx
	shr 	ecx, 16
	mov 	WORD [WINDOW_WIDTH_A], cx
	pop 	ecx
	mov 	WORD [WINDOW_HEIGHT_A], cx
	push 	edx
	shr 	edx, 16
	mov 	WORD [WINDOW_POSITIONX_A], dx
	pop 	edx
	mov 	WORD [WINDOW_POSITIONY_A], dx
	
	push 	ebp
	mov 	ebp, esp
	mov 	ebx, DWORD [ebp + (12 + 4)]   ; 12 + 4 = IDs
	push 	ebx
	shr 	ebx, 16
	mov 	WORD [WINDOW_ID_MASTER_A], bx
	pop 	ebx
	mov 	WORD [WINDOW_ID_SLAVE_A], bx
	mov 	edi, DWORD[ebp + (16 + 4)]    ; 16 + 4 = Colors
	pop 	ebp
	
	mov 	eax, DWORD[edi]       
	mov 	DWORD [WINDOW_BAR_COLOR_A], eax 
	mov 	eax, DWORD[edi + 4]
	mov 	DWORD [WINDOW_BORDER_COLOR_A], eax
	mov 	eax, DWORD [edi + 8]
	mov 	DWORD [WINDOW_BACK_COLOR_A], eax
	call 	CODE_SEG32:PROGRAM_VRAM+5
iretd

Show_Window:
	pop 	ebx
	xor 	edx, edx
	mov 	WORD [WINDOW_ID_SLAVE_A], bx
	call 	CODE_SEG32:PROGRAM_VRAM+8
iretd

IRQ_Table_Handler:
	dd 0x00000000	 ; System intervals timer - IRQ0
	dd 0x00000000	 ; PS/2 Keyboard - IRQ1
	dd 0x00000000	 ; Cascade (Catched to IRQ9) - IRQ2
	dd 0x00000000	 ; COM2 & COM4 - IRQ3
	dd 0x00000000	 ; COM1 & COM3 - IRQ4
	dd 0x00000000	 ; LPT2 or Sound board - IRQ5
	dd 0x00000000	 ; Floppy Disk - IRQ6
	dd 0x00000000	 ; LPT1 - IRQ7
	dd 0x00000000	 ; Real Time Clock (RTC) - IRQ8
	dd 0x00000000	 ; Cascade (Catched to IRQ2) - IRQ9
	dd 0x00000000	 ; Undefined - IRQ10
	dd 0x00000000	 ; Undefined - IRQ11
	dd 0x00000000	 ; PS/2 Mouse - IRQ12
	dd 0x00000000	 ; Math co-processor - IRQ13
	dd 0x00000000	 ; Primary IDE drive - IRQ14
	dd 0x00000000	 ; Secundary IDE drive - IRQ15
	
IRQ_Timer:
	pushad
	__WritePort 0x20, 0x20
	mov 	eax, 0x01
	mov 	edx, 0x02
	mov 	esi, TimerStr
	int 	0xCE
	;__WritePort 0xA0, 0x20
	popad
iretd
TimerStr db "TIMER",0

IRQ_Keyboard:
	pushad
	in al, 0x60
	;mov 	edi, BufferKey
	;mov 	byte[edi], al
	;mov 	eax, 0x01
	;mov 	esi, edi
	;mov 	edx, 0x74
	;int 	0xCE
	mov 	eax, 0x01
	mov 	edx, 0x02
	mov 	esi, BufferKey
	int 	0xCE
	__WritePort 0x20, 0x20
	popad
iretd
BufferKey db "Teclado",0

; IRQ 0x0A
IRQ_Network:
	pushad
	cld

	call 	DWORD[IRQ_Table_Handler + (10 * 4)]

	__WritePort 0xA0, 0x20
	__WritePort 0x20, 0x20
	
	popad
iretd

; ISR 0
DE_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, DE_String
	hlt
	DE_String db "Fault: Divide Error (#DE Exception)"
iretd

; ISR 1
DB_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	pushfd
	or  dword[esp], 0x100
	and dword[esp], 0xFFFEFFFF
	popfd
	mov esi, DB_String
	hlt
	jmp Debugging
	DB_String db "Trap: Debug Exception (#DB Exception)"
Debugging:
	pop esi
iretd

; ISR 2
NMI_Int: 
iretd

; ISR 3
BP_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, BP_String
	hlt
	pushfd
	or  dword[esp], 0x10000
	popfd
	jmp BackRun
	BP_String db "Trap: Breakpoint - INT3 (#BP_Exception)"
BackRun:
	pop esi
iretd

; ISR 4
OF_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, OF_String
	hlt
	jmp BackRun1
	OF_String db "Trap: Overflow - INTO (#OF_Exception)"
BackRun1:
	pop esi
iretd

; ISR 5
BR_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, BR_String
	hlt
	BR_String db "Fault: BOUND Range Exceeded (#BR_Exception)"
iretd

; ISR 6
UD_Exception:
	popad
	mov 	eax, 0x1C
	mov 	ebx, esi
	mov 	edi, BufferHex
	int 	0xCE
	mov 	esi, UD_String
	mov 	eax, 0x01
	mov 	edx, 0x74
	int 	0xCE
	mov 	eax, 0x01
	mov 	esi, BufferHex
	mov 	edx, 0x74
	int 	0xCE
	mov 	eax, 0x01
	mov 	esi, SSW
	mov 	edx, 0x74
	int 	0xCE
	mov 	ax, 0x06
	jmp 	$
iretd
UD_String:
	 db 0x0D, "---------------------------------------------------"
	 db 0x0D, "|                APPLICATION ERROR                |"
 	 db 0x0D, "|                                                 |"
	 db 0x0D, "|    Fault: Invalid Opcode - Undefined Opcode     |"
	 db 0x0D, "|      (#UD_Exception) at address 0x",0
SSW  db       "      |"	
	 db 0x0D, "|_________________________________________________|"
	 db 0
	
; ISR 7
NM_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, NM_String
	hlt
	NM_String db "Fault: Device Not Available - No Math Coprocessor (#NM_Exception)"
iretd

; ISR 8
DF_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, DF_String
	hlt
	jmp ReturnError1
	DF_String db "Abort: Double Fault (#DF_Exception)"
ReturnError1:
	mov al, 0
	stc
	pop esi
iretd

; ISR 9
CoProc_Segment_Overrun: 
iretd

; ISR 10
TS_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, TS_String
	hlt
	jmp ReturnError2
	TS_String db "Fault: Invalid TSS (#TS_Exception)"
ReturnError2:
	mov al, 10
	stc
	pop esi
iretd

; ISR 11
NP_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, NP_String
	hlt
	jmp ReturnError3
	NP_String db "Fault: Segment Not Present (#NP_Exception)"
ReturnError3:
	mov al, 11
	stc
	pop esi
iretd

; ISR 12
SS_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, SS_String
	hlt
	jmp ReturnError4
	SS_String db "Fault: Stack-Segment Fault (#SS_Exception)"
ReturnError4:
	mov al, 12
	stc
	pop esi
iretd

; ISR 13
GP_Exception:
	popad
	mov 	eax, 0x1C		; Função de conversão Hexa para String
	mov 	ebx, esi		; Endereço da Instrução de Erro
	mov 	edi, BufferHex	; Ponteiro de Buffer para Conversão
	int 	0xCE
	mov 	eax, 0x01
	mov 	esi, GP_String
	mov 	edx, 0x74
	int 	0xCE
	mov 	eax, 0x01
	mov 	esi, BufferHex
	mov 	edx, 0x74
	int 	0xCE
	mov 	eax, 0x01
	mov 	esi, GPW
	mov 	edx, 0x74
	int 	0xCE
	mov 	ax, 13
	jmp 	$
iretd
GP_String:
	 db 0x0D, "---------------------------------------------------"
	 db 0x0D, "|                APPLICATION ERROR                |"
 	 db 0x0D, "|                                                 |"
	 db 0x0D, "|    Fault: General Protection (#GP_Exception)    |"
	 db 0x0D, "|               at address 0x",0
GPW  db       "             |"	
	 db 0x0D, "|_________________________________________________|"
	 db 0
	BufferHex: db "00000000",0
	
; ISR 14
PF_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, PF_String
	hlt
	jmp ReturnError6
	PF_String db "Fault: Page Fault (#PF_Exception)"
ReturnError6:
	mov al, 14
	stc
	pop esi
iretd

; ISR 15
Reserved_Intel: 
iretd

; ISR 16
MF_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, MF_String
	hlt
	MF_String db "Fault: x87 FPU Floating-Point Error - Math Fault (#MF_Exception)"
iretd

; ISR 17
AC_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, AC_String
	hlt
	jmp ReturnError7
	AC_String db "Fault: Alignment Check (#AC_Exception)"
ReturnError7:
	mov al, 0
	stc
	pop esi
iretd

; ISR 18
MC_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, MC_String
	hlt
	MC_String db "Abort: Machine Check (#MC_Exception)"
iretd

; ISR 19
XM_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, XM_String
	hlt
	XM_String db "Fault: SIMD Floating-Point Exception (#XM_Exception)"
iretd

; ISR 20
VE_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	mov esi, VE_String
	hlt
	VE_String db "Fault: Virtualization Exception (#VE_Exception)"
iretd

; ISR 21
CP_Exception:
	cmp 	eax, 0xFFFF
	je 		Back8086Program
	push esi
	mov esi, CP_String
	hlt
	jmp ReturnError8
	CP_String db "Fault: Control Protection Exception (#CP_Exception)"
ReturnError8:
	mov al, 21
	pop esi
iretd

; ISR 22-31   -> Intel Reserved (Do not use)
; ISR 32-255  -> User Defined Interrupts (Non-Reserved)

PMSIZE_LONG equ ($-$$+3)>>2