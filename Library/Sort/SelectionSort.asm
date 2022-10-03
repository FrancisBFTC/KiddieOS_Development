; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por Seleção
;
; A ordenação por seleção ou selection sort consiste em selecionar o menor item e colocar 
; na primeira posição, selecionar o segundo menor item e colocar na segunda posição, segue 
; estes passos até que reste um único elemento. Para todos os casos (melhor, médio e pior caso) 
; possui complexidade C(n) = O(n²) e não é um algoritmo estável.

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA SELECTIONSORT ---------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
SelectionSort:                             ; Label que será chamada pela Instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	mov 	dword[i], 0                    ; Inicialize a variável de índice i
	mov 	dword[j], 0                    ; Inicialize a variável de índice j
	mov 	dword[minor], 0                ; Inicialize a variável de seleção minor
	init_for1_Sel:                         ; Inicio do 1ª loop FOR (Laço Externo)
		mov 	ebx, dword[i]              ; Mova para ebx o índice i
		push 	ecx                        ; Salve o tamanho do vetor (ecx) na pilha...
		sub 	ecx, 1                     ; Porque subtraímos ecx - 1 aqui.
		cmp 	ebx, ecx                   ; Compare o índice i com tamanho - 1 (ecx - 1)
		jb      loop_for1_Sel              ; Se for menor, Então começe a iteração do loop FOR
		pop 	ecx                        ; Se não, desempilhe ecx e...
		jmp     return_Sel                 ; Saia da rotina e retorne para a CALL
	loop_for1_Sel:                         ; Sendo menor, a execução vem pra cá (Pré-início do 2ª loop)
		pop 	ecx                        ; Desempilhe ecx
		mov 	dword[minor], ebx          ; Salve o índice i (ebx) em minor (variável de seleção do menor)
	init_for2_Sel:                         ; Início do 2ª loop FOR (Laço Interno)
		mov 	dword[j], ebx              ; Mova o índice i para j
		add 	dword[j], 1                ; Some j + 1, que com a instrução anterior ficaria: j = i + 1
	loop_for2_Sel:                         ; Label para comparação no 2ª loop FOR
		cmp 	dword[j], ecx              ; Compare índice j com o tamanho do vetor (ecx)
		jb      loop_for2_Sel1             ; Se for menor, Salte para a execução dentro do 2ª loop FOR
		jmp     return_for1_Sel            ; Se não for, Então vai para o retorno do 1ª loop FOR
	loop_for2_Sel1:                        ; Label para execução no 2ª loop FOR
		shl 	ebx, 2                     ; Multiplique o índice i por 4 (Porque 1 inteiro é 4 bytes)
		mov 	eax, dword[esi + ebx]      ; Acesse o índice i no vetor e mova para eax, sendo Vector[i]
		mov 	ebx, dword[j]              ; Substitua ebx com outro índice -> o índice j
		shl 	ebx, 2                     ; Multiplique este índice j por 4
		mov 	edx, dword[esi + ebx]      ; Acesse o índice j no vetor e mova para edx, sendo Vector[j]
		cmp 	edx, eax                   ; Compare Vector[j] com Vector[minor], onde minor = i
		jb      select_minor               ; Se for menor, Salte para a atribuição de minor = j (Seleção do menor valor)
		jmp     return_for2_Sel            ; Se não for, então vai para o retorno do 2ª loop FOR
	return_for1_Sel:                       ; Retorno do 1ª loop FOR com procedimentos
		SWAP 	(minor, i)                 ; Faça uma troca de valores entre Vector[minor] e Vector[i]
		inc 	dword[i]                   ; Incremente o índice i
		jmp     init_for1_Sel              ; Volte para o início do 1ª loop FOR
	return_for2_Sel:                       ; Retorno para o 2ª loop FOR
		inc 	dword[j]                   ; Incremente o índice j
		mov 	ebx, dword[minor]          ; Ebx fica com o índice de "menor" valor pois será usado na condicional do 2ª loop
		jmp     loop_for2_Sel              ; Volte para o 2ª loop
	select_minor:                          ; Label de Seleção do menor valor -> Atribuição de minor = j
		mov 	ebx, dword[j]              ; Ebx recebe o índice j
		mov 	dword[minor], ebx          ; Minor recebe o índice de ebx (j)
		jmp     return_for2_Sel            ; Vá para o retorno do 2ª loop FOR
return_Sel:                                ; Label de retorno da rotina de seleção (Vindo do ínicio do 1ª Loop)
	popad                                  ; Restaure todos os registradores da pilha, armazenados em "pushad"
ret                                        ; Retorno para a chamada pela Instrução CALL e dados ordenados!

; --------------------------------------------------------------------------------------------------------------------------


; ALGORITMO ACIMA EQUIVALENTE A:

;void SelectionSort (int vector[], int size){
;    int i, j, minor, aux;                           // Declara as variáveis
;    for (i = 0; i < size-1; i++){                   // Laço externo que começa na 1ª posição
;        minor = i;                                  // seleciona o (1ª ou 2ª ou ... Nª) índice atual
;        for (j = i+1; j < size; j++){               // Laço interno que percorre todo o array começando pelo índice após o selecionado
;            if (vector[j] < vector[minor])          // Se o item atual for menor que o item na Nª posição selecionada (índice atual)
;               minor = j;                           // Redefine a variável "menor" para o índice com o menor item
;        }                                           // Itera no laço interno até que o índice seja igual ao tamanho do array
;        SSWAP(vector[minor], vector[i]);            // Faz a troca do menor valor selecionado com a Nª posição selecionada
;    }
;}

; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++