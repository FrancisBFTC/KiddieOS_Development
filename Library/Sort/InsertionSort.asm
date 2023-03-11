; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por Inserção
;
; Insertion Sort ou ordenação por inserção é o método que percorre um vetor de elementos da esquerda para a direita 
; e à medida que avança vai ordenando os elementos à esquerda. Possui complexidade C(n) = O(n) no melhor caso e C(n) = O(n²) 
; no caso médio e pior caso. É considerado um método de ordenação estável.

; Um método de ordenação é estável se a ordem relativa dos itens iguais não se altera durante a ordenação. 
; O funcionamento do algoritmo é bem simples: consiste em cada passo a partir do segundo elemento selecionar 
; o próximo item da sequência e colocá-lo no local apropriado de acordo com o critério de ordenação.

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA INSERTIONSORT ---------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
InsertionSort:                             ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	mov 	dword[i], 1                    ; Inicializa a variável i com 1
	mov 	dword[j], 0                    ; Inicializa a variável j com 0
	mov 	dword[x], 0                    ; Inicializa a variável x com 0
	dec 	ecx                            ; ecx - 1 (tamanho - 1), porque i começa com 1
	loop_for_Ins:                          ; Inicio do loop FOR -> for(...){
		mov 	ebx, dword[i]              ; Mova o valor de i para ebx
		shl 	ebx, 2                     ; Multiplique rápidamente ebx por 4 (4 bytes = 32 bits)
		mov 	eax, dword[esi + ebx]      ; Acesse o índice i no Vetor através de esi + ebx ou Vector[i], mova para eax
		mov 	dword[x], eax              ; Mova o conteúdo de eax para a variável x
		mov 	ebx, dword[i]              ; Mova o índice i para ebx
		dec 	ebx                        ; Subtraia ebx - 1, ou seja, i - 1
		mov 	dword[j], ebx              ; Mova ebx (i - 1) para j, que equivale a j = i - 1
		mov 	dword[esi-4], eax          ; Mova eax (Valor de x) para esi-4 (4 bytes), que seria Vector[-1] = x
	loop_while_Ins:                        ; Inicio do loop WHILE para comparação -> while(...){
		mov 	ebx, dword[j]              ; mova o valor de j (i - 1) para ebx
		shl 	ebx, 2                     ; Multiplique rápidamente ebx por 4 (4 bytes = 32 bits)
		mov 	eax, dword[esi + ebx]      ; Acesse o índice j no Vetor através de esi + ebx ou Vector[j], mova para eax 
		cmp 	dword[x], eax              ; Compare x com o conteúdo de Vector[j] (eax)
		jb      return_while_Ins           ; Se for menor, salte para o retorno do loop WHILE
		jmp     return_for_Ins             ; Se não for, então salte para o retorno do loop FOR
	return_while_Ins:                      ; Retorno do loop WHILE com procedimentos
		mov 	dword[esi+ebx+4], eax      ; Mova o conteudo de Vector[j] para Vector[j+1] -> esi+ebx+4 (4 bytes = 1 int)
		dec 	dword[j]                   ; Decremente j, obs.: Se j for -1, em Asm ele sera 0xFFFFFFFF
		jmp     loop_while_Ins             ; Volte para o inicio do loop WHILE para comparação
	return_for_Ins:                        ; Retorno do loop FOR com procedimentos
		mov 	eax, dword[x]              ; Mova o valor de x para eax
		mov 	dword[esi+ebx+4], eax      ; Mova x para Vector[j+1]
		inc 	dword[i]                   ; Incremente o índice i
		cmp 	dword[i], ecx              ; Compare índice i com o tamanho do vetor em ecx
		jbe     loop_for_Ins               ; Se for menor ou igual, Volte para o laço externo FOR
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


; EQUIVALENTE LINGUAGEM C
;void InsertionSort (int vector[], int size){
;    int i, j, x;
;    for (i=1; i<=size; i++){                // começando do 2ª item, navega no Array até chegar no último item
;        x = vector[i];                      // armazena em x o 2ª item
;        j = i-1;                            // j apontará pro 1ª item
;        vector[-1] = x;                     // armazena o 2ª item em uma posição -1.
;        while (x < vector[j]){              // enquanto o 2ª item for menor que o 1ª item...
;            vector[j+1] = vector[j];        // a 2ª posição recebe o 1ª item
;            j--;                            // j aponta pro item x na posição -1.
;        }                                   // Itera no While até x seja igual ao valor da posição -1 (que é x)
;        vector[j+1] = x;                    // armazena o 2ª item na 1ª posição
;    }                                       // Na próxima iteração o 2ª item passará a ser o 3ª, depois o 4ª,etc..
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++