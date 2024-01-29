; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por BOGOSORT (CaseSort ou Estou com Sorte)
;
; Bogosort (também conhecido como CaseSort ou Estou com Sort), é um algoritmo de ordenação extremamente ineficiente. 
; É baseado na reordenação aleatória dos elementos. Não é utilizado na prática, mas pode ser usado no ensino de algoritmos 
; mais eficientes. Seu nome veio do engraçado termo quantum bogodynamics e, ultimamente, a palavra bogus. 

; Esse algoritmo é probabilístico por natureza. Se todos os elementos a serem ordenados são distintos, a complexidade 
; esperada é O(n × n!). O tempo exato de execução esperado depende do quantos diferentes valores de elementos ocorrem, 
; e quantas vezes cada um deles ocorre, mas para casos não-triviais o tempo esperado de execução é exponencial ou 
; super-exponencial a n.

; Ele termina pela mesma razão do teorema do macaco infinito; existe alguma probabilidade de que aconteça a permutação correta, 
; dado que em um infinito número de tentativas fatalmente a encontrará. Deve-se notar que com os algoritmos geradores de números 
; pseudo-aleatórios, que têm um número finito de estados e não são realmente aleatórios, o algoritmo pode nunca terminar para certos 
; conjuntos de valores a serem ordenados. Bogosort é um algoritmo de ordenação não estável. 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA BOGOSORT --------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
BogoSort:                                  ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;bool is_sorted(int *a, int n)
;{
;  while ( --n >= 1 ) {
;    if ( a[n] < a[n-1] ) return false;
;  }
;  return true;
;}
 
;void shuffle(int *a, int n)
;{
;  int i, t, r;
;  for(i=0; i < n; i++) {
;    t = a[i];
;    r = rand() % n;
;    a[i] = a[r];
;    a[r] = t;
;  }
;}
 
;void BogoSort(int *vector, int tam)
;{
;  while ( !is_sorted(vector, tam) ) shuffle(vector, tam);
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++