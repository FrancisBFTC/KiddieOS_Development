; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por CombSort

; O algoritmo Comb sort (ou Combo sort ou ainda algoritmo do pente) é um algoritmo de ordenação relativamente simples, 
; e faz parte da família de algoritmos de ordenação por troca.O Comb sort melhora o Bubble sort, e rivaliza com algoritmos 
; como o Quicksort. A ideia básica é eliminar as tartarugas ou pequenos valores próximos do final da lista, já que em um bubble sort 
; estes retardam a classificação tremendamente. 

; O Algoritmo repetidamente reordena diferentes pares de itens, separados por um salto, que é calculado a cada passagem. 
; Método semelhante ao Bubble Sort, porém mais eficiente. Na Bubble sort, quando quaisquer dois elementos são comparados, 
; eles sempre têm um gap (distância um do outro) de 1. A ideia básica do Comb sort é que a diferença pode ser muito mais do que um. 
; (O Shell sort também é baseado nesta ideia, mas é uma modificação do insertion sort em vez do bubble sort). 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA COMBSORT --------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
CombSort:                                  ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void CombSort (int vet[], int tam){
;	int i, j, gap, swapped = 1;
;	int aux;
;	gap = tam;
;	while(gap > 1 || swapped == 1){
;		gap = gap * 10 / 13;
;		if (gap == 9 || gap == 10) gap = 11;
;		if (gap < 1) gap = 1;
;		swapped = 0;
;		for(i = 0, j = gap; j < tam; i++, j++){
;			if(vet[i] > vet[j]){
;				aux = vet[i];
;				vet[i] = vet[j];
;				vet[j] = aux;
;				swapped = 1;
;			}
;		} 
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++