; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por SHELLSORT

; Criado por Donald Shell em 1959, publicado pela Universidade de Cincinnati, Shell sort é o mais eficiente algoritmo 
; de classificação dentre os de complexidade quadrática. É um refinamento do método de inserção direta. O algoritmo difere 
; do método de inserção direta pelo fato de no lugar de considerar o array a ser ordenado como um único segmento, ele considera 
; vários segmentos sendo aplicado o método de inserção direta em cada um deles.
; Basicamente o algoritmo passa várias vezes pela lista dividindo o grupo maior em menores. Nos grupos menores é aplicado o 
; método da ordenação por inserção.

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA SHELLSORT -------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
ShellSort:                                 ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;void ShellSort (int *vet, int tam){
;	int i, j, value;
;	int gap = 1;
;	
;	while(gap < tam){
;		gap = 3 * gap + 1;
;	}
;	while(gap > 0){
;		for(i = gap; i < tam; i++){
;			value = vet[i];
;			j = i;
;			while(j > gap - 1 && value <= vet[j - gap]){
;				vet[j] = vet[j - gap];
;				j = j - gap;
;			}
;			vet[j] = value;
;		}
;		gap = gap / 3;
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++