; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;              ALGORITMOS DE ORDENAÇÃO
;
;              Programa em Assembly x86
;              Criado por Wender Francis
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

[ORG 0x0000]

jmp 		MAIN		; Execute o MAIN


; --------------------------------------------------------------------------------------
; ÁREA DE DADOS DO PROGRAMA

VetorDec 	db "0123456789",0
Zero 		db 0

Off_s		dd  0                                               ; Offset -1 do 1ª Vetor
Vector1 	dd 	8, 5, 9, 1, 3, 2, 0, 4, 7, 6, 24, 23, 11, 10    ; Vetor Exemplo 1 de tamanho 14
Vector2 	dd 	8, 12, 14, 1, 3, 2, 0, 4, 7, 6, 17, 16, 11, 10  ; Vetor Exemplo 2 de tamanho 14
Vector3 	dd 	14, 12, 13, 1, 5, 3, 8, 11, 9, 6, 4, 2, 10, 7   ; Vetor Exemplo 3 de tamanho 14

InsSort 	db 13,10,"++++ INSERTIONSORT ++++",13,10,13,10,0
SelSort 	db 13,10,"++++ SELECTIONSORT ++++",13,10,13,10,0
QuiSort 	db 13,10,"++++ QUICKSORT ++++",13,10,13,10,0

; --------------------------------------------------------------------------------------


; --------------------------------------------------------------------------------------
; ÁREA DE INCLUSÕES DOS ALGORITMOS

%INCLUDE "InsertionSort.asm"
%INCLUDE "SelectionSort.asm"
%INCLUDE "QuickSort.asm"
%INCLUDE "BubbleSort.asm"
%INCLUDE "CombSort.asm"
%INCLUDE "GnomeSort.asm"
%INCLUDE "CockTailSort.asm"
%INCLUDE "MergeSort.asm"
%INCLUDE "ShellSort.asm"
%INCLUDE "RadixSort.asm"
%INCLUDE "HeapSort.asm"
%INCLUDE "TimSort.asm"
%INCLUDE "StrandSort.asm"
%INCLUDE "OddEvenSort.asm"
%INCLUDE "SmoothSort.asm"
%INCLUDE "BogoSort.asm"
%INCLUDE "StoogeSort.asm"

; --------------------------------------------------------------------------------------


MAIN:
	cld
	mov 	ax, 0x0800
	mov 	ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov 	gs, ax
	cli 
	mov 	ax, 0x07D0
	mov 	ss, ax
	mov 	sp, 0xFFFF
	sti
	
	; Configura Modo de Texto (80x20)
	mov 	ah, 00h
	mov 	al, 03h
	int 	10h
	
	; Limpa a tela
	mov 	ax, 03h
	int 	10h
	
Program:

	; Exibe Vector1 antes e depois do InsertionSort
	mov 	si, InsSort
	call 	Print_String
	
	mov 	ecx, 14
	mov 	esi, Vector1
	
	call 	Show_Vector32
	call 	InsertionSort
	call 	Show_Vector32
	
	; Exibe Vector2 antes e depois do SelectionSort
	mov 	si, SelSort
	call 	Print_String
	
	mov 	ecx, 14
	mov 	esi, Vector2
	
	call 	Show_Vector32
	call 	SelectionSort
	call 	Show_Vector32
	
	; Exibe Vector3 antes e depois do QuickSort
	mov 	si, QuiSort
	call 	Print_String
	
	mov 	eax, 0
	mov 	ecx, 14
	mov 	esi, Vector3
	
	call 	Show_Vector32
	call 	QuickSort
	call 	Show_Vector32
	
	jmp 	$
	
	
; --------------------------------------------------------------------------------------
; ÁREA DE FUNÇÕES DO PROGRAMA

; ==============================================================
; Rotina que mostra o conteúdo do vetor formatado
; IN: ECX = Tamanho do Vetor
;     ESI = Endereço do Vetor

; OUT: Nenhum.
; ==============================================================
Show_Vector32:
	pushad
	
	mov 	ax, 0x0E7B
	int 	0x10
	xor 	ebx, ebx
	
ShowVector:
	push 	ebx
	shl		ebx, 2
	mov 	eax, dword[esi + ebx]
	call 	Print_Dec_Value32
	pop 	ebx
	inc 	ebx
	mov 	ah, 0x0E
	mov 	al, ','
	int 	0x10
	loop 	ShowVector
	mov 	ax, 0x0E7D
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	mov 	ax, 0x0E0A
	int 	0x10
	
	popad
ret


; ==============================================================
; Rotina que imprime Strings na Tela
; IN: ESI = Endereço da String

; OUT: Nenhum.
; ==============================================================
Print_String:
	pusha
	mov 	ah, 0Eh
	Prints:
		mov 	al, [si]
		cmp 	al, 0
		jz 		ret_print
		inc 	si
		int 	10h
		jmp 	Prints
	ret_print:
	popa
ret


; ==============================================================
; Rotina que imprime inteiros decimais de 32 bits
; IN: EAX = Endereço da String

; OUT: Nenhum.
; ==============================================================
Print_Dec_Value32:
	pushad
	cmp 	eax, 0
	je 		ZeroAndExit
	xor 	edx, edx
	mov 	ebx, 10
	mov 	ecx, 1000000000
DividePerECX:
	cmp 	eax, ecx      ; EAX = 950000
	jb 		VerifyZero
	mov 	byte[Zero], 1
	push 	eax
	div 	ecx
	xor 	edx, edx
	push 	ax
	push 	bx
	mov 	bx, ax
	mov 	ah, 0Eh
	mov 	al, byte[VetorDec + bx]
	int 	10h
	pop 	bx
	pop 	ax
	mul 	ecx
	mov 	edx, eax
	pop 	eax
	sub 	eax, edx
	xor 	edx, edx
DividePer10:
	cmp 	ecx, 1
	je 		Ret_Dec32
	push 	eax
	mov 	eax, ecx
	div 	ebx
	mov 	ecx, eax
	pop 	eax
	jmp 	DividePerECX
VerifyZero:
	cmp 	byte[Zero], 0
	je 		ContDividing
	push 	ax
	mov 	ax, 0E30h
	int 	10h
	pop 	ax
ContDividing:
	jmp 	DividePer10
ZeroAndExit:
	mov 	ax, 0E30h
	int  	10h
Ret_Dec32:
	mov 	byte[Zero], 0
	popad
ret

; FIM DAS FUNÇÕES DO PROGRAMA
; --------------------------------------------------------------------------------------
