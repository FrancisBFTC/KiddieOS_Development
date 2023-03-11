; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por ODDEVENSORT
;
; O Odd-even sort é um algoritmo de ordenação relativamente simples. É um algoritmo de ordenação por comparação baseado 
; no bubble sort com o qual compartilha muitas características. Ele funciona através da comparação de todos os pares indexados 
; (ímpar, par) de elementos adjacentes na lista e, se um par está na ordem errada (o primeiro é maior do que o segundo),
; os elementos são trocados. 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA ODDEVENSORT -----------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
OddEvenSort:                               ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;#define swap(A,B) aux = A; A = B; B = aux;
;
;void OddEvenSort(int vector[], int n){
;	int sorted = 0;
;	int x, aux;
;	while(!sorted){
;		sorted = 1;
;		for(x = 1; x < n-1; x += 2){
;			if(vector[x] > vector[x+1]){
;				swap(vector[x], vector[x+1]);
;				sorted = 0;
;			}
;		}
;		for(x = 0; x < n-1; x += 2){
;			if(vector[x] > vector[x+1]){
;				swap(vector[x], vector[x+1]);
;				sorted = 0;
;			}
;		}
;			
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++