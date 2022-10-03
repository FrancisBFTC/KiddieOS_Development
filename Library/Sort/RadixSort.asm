; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por RADIXSORT

; O Radix sort é um algoritmo de ordenação rápido e estável que pode ser usado para ordenar itens que estão identificados por chaves únicas.
; Cada chave é uma cadeia de caracteres ou número, e o radix sort ordena estas chaves em qualquer ordem relacionada com a lexicografia.
; Na ciência da computação, radix sort é um algoritmo de ordenação que ordena inteiros processando dígitos individuais. Como os inteiros
; podem representar strings compostas de caracteres (como nomes ou datas) e pontos flutuantes especialmente formatados, radix sort não é 
; limitado somente a inteiros. 
; O algoritmo de ordenação radix sort foi originalmente usado para ordenar cartões perfurados. Um algoritmo computacional para o 
; radix sort foi inventado em 1954 no MIT por Harold H. Seward.

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

b 		dd 0     ; Ponteiro para vetor
major 	dd 0
exp 	dd 1
bucket 	times 10 dd 0
b1 		times 15 dd 0

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA RADIXSORT -------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
RadixSort:                                 ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	; Inicialização das variáveis
	mov 	dword[i], 0                    ; Inicializa a variável i
	mov 	eax, dword[esi + 0]            ; Move para eax Vector[0]
	mov 	dword[major], eax              ; Move Vector[0] para variável major
	mov 	dword[exp], 1                  ; Inicializa variável exp com 1
	
	; Alocação de um endereço de memória -> b[ ]
	mov 	ebx, 4                         ; Tamanho do inteiro pra alocar fica em EBX (4 bytes = 1 int)
	call 	Calloc                         ; Chamada de função pra alocar 'ECX' inteiros
	mov 	dword[b], eax                  ; Guarda no ponteiro 'b' o endereço alocado pela função
	
	; 1ª loop p/ armazenar o valor maior do vetor
	push 	ecx                            ; Salve ECX na pilha pois ele será alterado no loop
	loop_for_rad1:                         ; Label de início do LOOP
		mov 	ebx, dword[i]              ; Mova o índice i para EBX
		shl 	ebx, 2                     ; Multiplique este índice por 4
		mov 	ebx, dword[esi + ebx]      ; Mova um valor do vetor para ebx, EBX = Vector[i]
		cmp 	ebx, dword[major]          ; Compare Vector[i] com a variável major
		jbe 	return_loopfor_rad1        ; Se for menor ou igual, salte para o retorno do loop
		mov 	dword[major], ebx          ; Se for maior, então mova Vector[i] para major
	return_loopfor_rad1:                   ; retorno do loop FOR
		inc 	dword[i]                   ; Incremente o índice i
		loop 	loop_for_rad1              ; Volte para o início do loop e decremente ECX até valer 0
	pop 	ecx                            ; ECX valendo 0, restaure o valor anterior de ECX
	
	; Loop while externo para filtrar os dígitos
	loop_while_rad1:                       ; Início do loop WHILE
		xor 	edx, edx                   ; Zere EDX para a divisão
		mov 	eax, dword[major]          ; Mova para eax o valor da variável major
		mov 	ebx, dword[exp]            ; Mova para ebx o valor da variável exp
		div 	ebx                        ; Divida major por exp e guarde o resultado em eax
		cmp 	eax, 0                     ; Compare o resultado com 0
		jna 	ReturnRadix                ; Se não for maior, então encerre o ciclo WHILE
		                                   ; Se for maior, então continue o ciclo WHILE...
		
	; Inicializa vetor bucket com zeros
		mov 	edi, bucket                ; Mova o endereço de bucket para edi
		push 	ecx                        ; Salve ecx na pilha, pois vai alterar no rep
		push 	edi                        ; Salve edi na pilha, pois vai alterar no stosd
		mov 	ecx, 10                    ; Mova para ecx o valor 10 (Tamanho de bucket)
		mov 	eax, 0                     ; Mova para eax o valor 0, para o stosd
		rep 	stosd                      ; Repita ECX vezes o movimento de EAX para ES:EDI, incrementando EDI
		pop 	edi                        ; Restaure o endereço de EDI
		pop 	ecx                        ; Restaure o tamanho de Vector[] em ECX
		
	; 1ª loop interno p/ incrementar ECX valores de bucket[n],
	; onde n é o dígito LSB atual de Vector[i]
		mov 	dword[i], 0                ; Inicialize o índice i com 0
	loop_rad1:                             ; Início do 1ª loop FOR
		cmp 	dword[i], ecx              ; Compare i com tamanho do Vector[]
		jnb 	init_loop2                 ; Se não for menor, Encerre e Inicie o 2ª loop interno
		xor 	edx, edx                   ; Se for menor, zere edx para as divisões
		mov 	ebx, dword[i]              ; Mova para ebx o índice i
		shl 	ebx, 2                     ; Multiplique o índice por 4
		mov 	eax, dword[esi + ebx]      ; EAX = Vector[i]
		mov 	ebx, dword[exp]            ; Mova o valor de exp para EBX
		div 	ebx                        ; Divida Vector[i] por exp, resultado em EAX
		xor 	edx, edx                   ; Zere EDX pra próxima divisão
		mov 	ebx, 10                    ; Mova 10 para EBX
		div 	ebx                        ; Divida Resultado da divisão anterior por 10
		mov 	ebx, edx                   ; Mova o resto desta divisão para EBX
		shl 	ebx, 2                     ; Multiplique EBX por 4 pois será um índice, n = índice
		inc 	dword[edi + ebx]           ; Incremente o valor de bucket neste índice, bucket[n]++
		inc 	dword[i]                   ; Incremente o índice i
		jmp 	loop_rad1                  ; Volte para o início do 1ª loop FOR
		
	; 2ª loop interno p/ somar valor na posição posterior de bucket[]
	; Com valor da posição atual e salvar nesta posição, em 10 posições
	init_loop2:                            ; Início do 2ª loop FOR p/ inicialização
		mov 	dword[i], 1                ; Inicialize índice i com 0
	loop_rad2:                             ; Início do loop p/ comparações
		cmp 	dword[i], 10               ; Compare o índice i com 10
		jnb  	init_loop3                 ; Se não for menor, encerre e inicie 3ª loop
		mov 	ebx, dword[i]              ; Se for menor, mova para EBX o índice i
		sub 	ebx, 1                     ; Subtraia o índice por 1 (i = i - 1)
		shl 	ebx, 2                     ; Multiplique o índice por 4
		mov 	eax, dword[edi + ebx]      ; EAX = bucket[i - 1]
		add 	ebx, 4                     ; Adicione índice por 4 (i + 1 em C)
		add 	dword[edi + ebx], eax      ; Mesmo que dizer bucket[i] += bucket[i - 1]
		inc 	dword[i]                   ; Incremente o índice i
		jmp 	loop_rad2                  ; Volte ao 2ª loop FOR
		
		
	; 3ª loop interno pra fazer com que cada valor em Vector[i]
	; Seja colocado em cada posição de b[n], onde n são posições
	; incrementadas em bucket[] no 1ª loop interno
	init_loop3:                            ; Início do 3ª loop p/ inicialização
		mov 	dword[i], ecx              ; Inicialize i com o tamanho de Vector[] 
		sub 	dword[i], 1                ; Subtraia i - 1 (i = size - 1)
	loop_rad3:                             ; Início do 3ª loop p/ comparação
		cmp 	dword[i], 0xFFFFFFFF       ; Compare índice i com -1 (0xFFFFFFFF em Asm)
		je	 	last_loop                  ; Se for igual, encerre este loop e vá para o 4ª loop
		                                   ; Se for maior ou 0, então prossiga...
										   
		;Código abaixo equivalente a: b[--bucket[(vector[i] / exp) % 10]] = vector[i];
		mov 	edi, bucket                ; EDI guarda o endereço de bucket[]
		xor 	edx, edx                   ; Zere edx para as divisões
		mov 	ebx, dword[i]              ; Mova índice i para EBX
		shl 	ebx, 2                     ; Multiplique EBX por 4
		mov 	eax, dword[esi + ebx]      ; Vetor em EAX, EAX = Vector[i]
		mov 	ebx, dword[exp]            ; Expoente em EBX, EBX = EXP
		div 	ebx                        ; Divida Vector[i] por EXP, resultado em EAX
		xor 	edx, edx                   ; Zere EDX para próxima divisão
		mov 	ebx, 10                    ; Mova 10 para EBX
		div 	ebx                        ; Divida o resultado de EAX por 10
		mov 	ebx, edx                   ; EBX = Resto da divisão (em EDX)
		shl 	ebx, 2                     ; Este resto será um índice em Asm, então x 4
		sub		dword[edi + ebx], 1        ; Equivalente a --bucket[EBX], subtraíndo o valor - 1
		mov 	ebx, dword[edi + ebx]      ; EBX = Novo valor subtraído de bucket[EBX]
		shl 	ebx, 2                     ; x 4 como sempre pois é um índice para b[]
		push 	ebx                        ; Salve este índice na pilha
		mov 	ebx, dword[i]              ; Substitua EBX por um novo índice, EBX = i
		shl 	ebx, 2                     ; x 4 ou << 2 que são a mesma coisa
		mov 	eax, dword[esi + ebx]      ; EAX = Vector[i]
		pop 	ebx                        ; Restaure EBX da pilha (O índice de b[] )
		mov 	edi, dword[b]              ; Mova o endereço alocado de b[] para EDI
		mov 	dword[es:edi + ebx], eax   ; b[EBX] = Vector[i] ou b[bucket[EBX]] = Vector[i]
		dec 	dword[i]                   ; Decremente o índice i ou i--
		jmp 	loop_rad3                  ; Volte para o 3ª loop interno
		
	; 4ª loop interno p/ mover os valores pré-ordenados de b[] 
	; para Vector[], porém todo este processo de 4 loops é feito n vezes, onde
	; n é o tamanho de dígitos do maior item no Vector[], após n vezes,
	; todo o vetor já estará ordenado.
	last_loop:                             ; Início do 4ª loop p/ Inicialização
		mov 	dword[i], 0                ; Inicialize i com 0
	loop_rad4:                             ; Início do 4ª loop p/ Comparação
		cmp 	dword[i], ecx              ; Compare i com tamanho do vetor
		jnb 	return_while_rad1          ; Se não for menor, encerre o loop e vai para retorno do WHILE
		mov 	ebx, dword[i]              ; Mova pra EBX o índice i 
		shl 	ebx, 2                     ; Multiplique por 4 para o deslocamento
		mov 	edi, dword[b]              ; Mova para EDI o endereço do ponteiro b -> b[ ]
		mov 	eax, dword[es:edi + ebx]   ; Mova para EAX o valor de b[i] -> EAX = b[i]
		mov 	dword[esi + ebx], eax      ; Mova para Vector[i] o valor de EAX -> Vector[i] = b[i]
		inc 	dword[i]                   ; Incremente o índice i
		jmp 	loop_rad4                  ; Volte ao 4ª loop interno

	
	; Retorno ao ínicio do while externo com multiplicação antes,
	; Esta operação é necessária para filtrar o próximo dígito 
	; de cada item no Vector[] e basear os 4 loops com este dígito.
	return_while_rad1:                     ; Label de retorno para loop externo WHILE
		xor 	edx, edx                   ; Zere edx para multiplicação (Para não afetar)
		mov 	eax, dword[exp]            ; Mova para EAX o valor de exp
		mov 	ebx, 10                    ; Mova para EBX o valor 10
		mul 	ebx                        ; Multiplique exp por 10, resultado em EAX
		mov 	dword[exp], eax            ; Mova o resultado para exp novamente -> EXP *= 10
		jmp 	loop_while_rad1            ; Retorne ao início do loop WHILE externo
		
; O único procedimento que pode saltar pra cá 
; é o loop WHILE externo, pois é aqui que finaliza 
; a execução e desaloca o ponteiro b
ReturnRadix:
	mov 	ebx, b                         ; EBX = Endereço de b[ ]
	call 	Free                           ; Desaloca este endereço
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void RadixSort(int vector[], int size){
;	int i;                          ; Confere
;	int *b;                         ; Confere
;	int major = vector[0];          ; Confere
;	int exp = 1;                    ; Confere
;	
;	b = (int *) calloc(size, sizeof(int));   ; Confere
;	
;	for(i = 0; i < size; i++)    ; Confere
;		if(vector[i] > major)    ; Confere
;			major = vector[i];   ; Confere
;	
;	while((major / exp) > 0){    ; Confere
;		int bucket[10] = { 0 };  ; Confere
;		
;		for(i = 0; i < size; i++)               ; Confere
;			bucket[(vector[i] / exp) % 10]++;   ; Confere
;			
;		for(i = 1; i < 10; i++)           ; Confere
;			bucket[i] += bucket[i - 1];   ; Confere
;			
;		for(i = size - 1; i >= 0; i--)                        ; Confere
;			b[--bucket[(vector[i] / exp) % 10]] = vector[i];  ; Confere
;			
;		for(i = 0; i < size; i++)  ; Confere
;			vector[i] = b[i];      ; Confere
;		
;		exp *= 10;                 ; Confere
;	}
;	
;	free(b);
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++