; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;              ALGORITMOS DE ORDENAÇÃO
;
;              Programa em Assembly x86
;              Criado por Wender Francis
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%IFNDEF		__VARS_ASM__
%DEFINE 	__VARS_ASM__

; --------------------------------------------------------------------------------------
; ARQUIVO DE DADOS/VARIÁVEIS

i 			dd 1         ; Variável i para todos
j 			dd 0         ; Variável j para todos
x 			dd 0         ; Variável x para todos
pivo		dd 0         ; Variável pivo para QuickSort
minor 		dd 0         ; Variável minor para SelectionSort


; Esta é uma macro para troca de valores em um Vetor
; Dado 2 argumentos, os valores se trocam nas posições

%DEFINE SWAP(A,B) S_SWAP A,B                 ; Pré-definição da Macro S_SWAP

%MACRO S_SWAP 2                              ; Macro S_SWAP com 2 Argumentos
	mov 	ebx, dword[%1]                   ; Mova para ebx o 1ª índice (1ª Argumento)
	shl 	ebx, 2                           ; Multiplique rapidamente o 1ª índice por 4
	push 	ebx                              ; Salve ebx na pilha por causa das alterações
	mov 	eax, dword[esi + ebx]            ; Salve em eax o conteúdo do 1ª índice do Vetor
	mov 	ebx, dword[%2]                   ; Mova para ebx o 2ª índice (2ª Argumento)
	shl 	ebx, 2                           ; Multiplique rapidamente o 2ª índice por 4
	mov 	edx, dword[esi + ebx]            ; Salve em edx o conteúdo do 2ª índice do Vetor
	mov 	dword[esi + ebx], eax            ; O conteúdo do 1ª índice do Vetor vai para o 2ª índice
	pop 	ebx                              ; Restaure ebx (1ª índice)
	mov 	dword[esi + ebx], edx            ; O conteúdo do 2ª índice vai para o 1ª índice
%ENDMACRO                                    ; Fim da Macro e trocas realizadas.

; --------------------------------------------------------------------------------------

%ENDIF