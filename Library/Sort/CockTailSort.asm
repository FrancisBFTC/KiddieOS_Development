; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por COCKTAILSORT

; Cocktail shaker sort, também conhecido como bubble sort bidirecional, cocktail sort, 
; shaker sort (o qual também pode se referir a uma variação do insertion sort), ripple sort, shuffle sort, ou shuttle sort, 
; é uma variante do bubble sort, que é um algoritmo com não-estável e efetua Ordenação por comparação. 
; O algoritmo difere de um bubble sort no qual ordena em ambas as direções a cada iteração sobre a lista. Esse algoritmo de ordenação 
; é levemente mais difícil de implementar que o bubble sort, e e resolve o problema com os chamados coelhos e tartarugas no bubble sort.
; Ele possui performance levemente superior ao bubble sort, mas não melhora a performance assintótica; assim como o bubble sort, 
; não é muito usado na prática (insertion sort é escolhido para ordenação simples), embora seja usado para fins didáticos.
; A complexidade do Cocktail shaker sort em notação big-O é O(n²) para o pior caso e caso médio,
; mas tende a se aproximar de O(n) se a lista se encontra parcialmente ordenada antes da execução do algoritmo. 
; Por exemplo, se cada elemento se encontra em uma posição cuja distância até sua posição ordenada é k (k = 1), a complexidade do algoritmo 
; se torna O(kn).

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA COCKTAILSORT ----------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
CockTailSort:                              ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void CockTailSort(int vet[], int tam){
;	int start, end, swap, aux, i;
;	start = 0;
;	end = tam - 1;
;	swap = 0;
;	while(swap == 0 && start < end){
;		swap = 1;
;		for(i = 0; i < end; i = i + 1){
;			if(vet[i] > vet[i + 1]){
;				aux = vet[i];
;				vet[i] = vet[i + 1];
;				vet[i + 1] = aux;
;				swap = 0;
;			}
;		}
;		end = end - 1;
;		for(i = end; i > start; i = i - 1){
;			if(vet[i] < vet[i - 1]){
;				aux = vet[i];
;				vet[i] = vet[i - 1];
;				vet[i - 1] = aux;
;				swap = 0;
;			}
;		}
;		start = start + 1;
;	}
;} 


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++