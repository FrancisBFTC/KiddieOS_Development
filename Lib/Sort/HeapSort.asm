; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por HEAPSORT

; O algoritmo heapsort é um algoritmo de ordenação generalista, e faz parte da família de algoritmos de ordenação por seleção. 
; Foi desenvolvido em 1964 por Robert W. Floyd e J.W.J Williams. 
; Tem um desempenho em tempo de execução muito bom em conjuntos ordenados aleatoriamente, tem um uso de memória bem comportado e o 
; seu desempenho em pior cenário é praticamente igual ao desempenho em cenário médio. Alguns algoritmos de ordenação rápidos têm 
; desempenhos espectacularmente ruins no pior cenário, quer em tempo de execução, quer no uso da memória. 

; O heapsort que trabalha no lugar e o tempo de execução em pior cenário para ordenar n elementos é de O (n log n). Lê-se logaritmo 
; (ou log) de "n" na base 2. Para valores de n, razoavelmente grandes, o termo log n é quase constante, de modo que o tempo de 
; ordenação é quase linear com o número de itens a ordenar.
; O heapsort utiliza uma estrutura de dados chamada heap, para ordenar os elementos à medida que os insere na estrutura. Assim,
; ao final das inserções, os elementos podem ser sucessivamente removidos da raiz da heap, na ordem desejada, lembrando-se sempre 
; de manter a propriedade de max-heap. 

; A heap pode ser representada como uma árvore (uma árvore binária com propriedades especiais) ou como um vetor. Para uma ordenação 
; decrescente, deve ser construída uma heap mínima (o menor elemento fica na raiz). Para uma ordenação crescente, deve ser construído 
; uma heap máxima (o maior elemento fica na raiz). 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA HEAPSORT --------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
HeapSort:                                  ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void HeapSort (int vector[], int n){
;	int i = n / 2;
;	int father, son, t;
;	while(true){
;		if(i > 0){
;			i--;
;			t = vector[i];
;		} else {
;			n--;
;			if (n <= 0) return;
;			t = vector[n];
;			vector[n] = vector[0];
;		}
;		
;		father = i;
;		son = i * 2 + 1;
;		
;		while(son < n){
;			if((son + 1 < n) && (vector[son + 1] > vector[son]))
;				son++;
;			if(vector[son] > t){
;				vector[father] = vector[son];
;				father = son;
;				son = father * 2 + 1;
;			} else {
;				break;
;			}
;		}
;		vector[father] = t;
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++