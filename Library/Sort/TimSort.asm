; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por TIMSORT

; Timsort é um algoritmo de ordenação híbrido derivado do merge sort e do insertion sort, projetado para ter boa performance 
; em vários tipos de dados do mundo real. Foi inventado por Tim Peters em 2002 para ser usado na linguagem de programação Python,
; e tem sido o algoritmo de ordenação padrão de Python desde a versão 2.3. Ele atualmente é usado para ordenar arrays em Java SE 7.
; Tim Peters descreve o algoritmo da seguinte forma:

; um adaptativo, estável, merge sort natural, modestamente chamado de timsort (hey, eu mereço <wink>). Tem desempenho sobrenatural em muitos 
; tipos de arrays parcialmente ordenados (menos de lg(N!) comparações necessárias, e tão poucas quanto N-1), no entanto, tão rápido quanto o 
; algoritmo anterior altamente sintonizado, híbrido, samplesort de Python em matrizes aleatórias. Em suma, a rotina principal passa sobre a 
; matriz uma vez, da esquerda para a direita, alternadamente, identificando o próximo passo, em seguida, fundindo-os em passos anteriores "inteligentemente". 
; Todo o resto é complicação pela velocidade, e alguma medida duramente conquistada da eficiência de memória.

; TimSort é um algoritmo híbrido de ordenação baseado no MergeSort e InsertionSort. O algoritmo baseia-se na ideia de que, no mundo real, um vetor de dados 
; a ser ordenado contém sub-vetores já ordenados, não importando como (decrescentemente ou crescentemente). Assim, o TimSort está à frente da maioria dos algoritmos 
; de ordenação, mesmo não apresentando descobertas matemáticas complexas. O fato é que na realidade o TimSort não é um algoritmo autônomo, mas um híbrido, 
; uma combinação eficiente de outros algoritmos, temperado com as idéias do autor. O algoritmo completo comentado, traduzido do Python para Java pode ser encontrado 
; no site da openjdk

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA TIMSORT ---------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
TimSort:                                   ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;const int RUN = 32;

;int min(int X, int Y){
;	return (((X) < (Y)) ? (X) : (Y));
;}

;void TimSort(int vector[], int n){
;	int i, s, left;
;	for(i = 0; i < n; i+=RUN)
;		Insertion(vector, i, min((i+RUN-1), (n-1)));
;	
;	for(s = RUN; s < n; s *= 2){
;		for(left = 0; left < n; left += s*2){
;			int mid = left + s - 1; // encontra o ponto final do subarray esquerdo mid+1 é o ponto inicial do subarray direito
;			int right = min((left + 2*s - 1), (n-1));
;			Merge(vector, left, mid, right); // mescla sub array arr[esquerda.....mid] & arr[mid+1....right]
;		}
;	}
;		
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++