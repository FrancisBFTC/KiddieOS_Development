; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por GNOMESORT

; Algoritmo similiar ao Insertion sort com a diferença que o Gnome sort leva um elemento para sua posição correta, 
; com uma seqüencia grande de trocas assim como o Bubble sort. O algoritmo percorre o vetor comparando seus elementos dois a dois, 
; assim que ele encontra um elemento que está na posição incorreta, ou seja, um número maior antes de um menor, ele troca a posição 
; dos elementos, e volta com este elemento até que encontre o seu respectivo lugar.

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA GNOMESORT -------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
GnomeSort:                                 ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void Swap(int *, int *);
;void GnomeSort(int[], int);

;void Swap(int *X, int *Y){
;	int Z = *X;
;	*X = *Y;
;	*Y = Z;
;}

;void GnomeSort(int vet[], int tam){
;	int previous = 0, next = 0, i = 0;
;	
;	for(i = 0; i < tam; i++){
;		if(vet[i] > vet[i + 1]){
;			previous = i;
;			next = i + 1;
;			while(vet[previous] > vet[next]){
;				Swap(&vet[previous], &vet[next]);
;				if(previous > 0)
;					previous--;
;				if(next > 0)
;					next--;
;			}
;		}
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++