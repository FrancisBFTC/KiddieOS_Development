; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por bolha em C

; O bubble sort, ou ordenação por flutuação (literalmente "por bolha"), é um algoritmo de ordenação dos mais simples.
; A ideia é percorrer o vetor diversas vezes, a cada passagem fazendo flutuar para o topo o maior elemento da sequência. 
; Essa movimentação lembra a forma como as bolhas em um tanque de água procuram seu próprio nível, e disso vem o nome do algoritmo.

; No melhor caso, o algoritmo executa n  operações relevantes, onde n representa o número de elementos 
; do vetor. No pior caso, são feitas n ^ 2 operações. A complexidade desse algoritmo é de 
; Ordem quadrática. Por isso, ele não é recomendado para programas que precisem de velocidade e operem com quantidade elevada de dados. 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA BUBBLESORT ------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
BubbleSort:                                ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void BubbleSort (int vet[], int tam){
;	int mem, exc, i, j;
;	exc = 1; 								/*Será a verificação de troca em casa passada*/
;	for(j=tam-1; (j>=1) && (exc==1); j--){
;		exc = 0; 							/*Se continuar valendo 0 na próxima vez, então não houve troca e encerra*/
;		for(i=0; i < j; i++){
;			if(vet[i] > vet[i+1]){
;				mem = vet[i];
;				vet[i] = vet[i+1];
;				vet[i+1] = mem;
;				exc = 1;					 /* Havendo troca, com exc=1 então vai continuar executando.*/
;			}
;		}
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++