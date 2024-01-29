; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por STOOGESORT (Ordenação Pateta)
;
; O Stooge Sort, ou ordenação "Pateta", é um algoritmo de ordenação que se faz do uso das técnicas de divisão e conquista, 
; ou seja, recursivamente o algoritmo realiza partições virtuais da entrada e transforma o problema maior em pequenos subproblemas 
; até que a ordenação seja mínima.

; Comparado a outros algoritmos de ordenação mais conhecidos, como o Insertion Sort e o Bubble Sort, ele chega a ser mais lento. 
; Devido à sua ineficiência, recomenda-se que não seja usado na ordenação de grandes volumes de dados. 
; O nome do algoritmo faz referência a uma comédia norte-americana chamada The Three Stooges (em português, Os Três Patetas), 
; em que Moe batia repetidamente nos outros dois patetas, assim como o Stooge Sort repetidamente ordena 2/3 do array. 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA STOOGESORT ------------------------------------------------------------------------------------------
; IN:  ECX = Índice Final
;      EAX = Índice Inicial
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
StoogeSort:                                ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;#define SWAP(r,s)  do{ t=r; r=s; s=t; } while(0)

;void StoogeSort(int vect[], int x, int y)
;{
;   int t;

;   if (vect[y] < vect[x]) SWAP(vect[x], vect[y]);
;   if (y - x > 1)
;   {
;       t = (y - x + 1) / 3;
;       StoogeSort(vect, x, y - t);
;       StoogeSort(vect, x + t, y);
;       StoogeSort(vect, x, y - t);
;   }
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++