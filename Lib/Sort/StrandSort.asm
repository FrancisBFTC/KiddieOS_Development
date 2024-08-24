; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por STRANDSORT

; O Strand sort é um algoritmo de ordenação. Ele trabalha por repetidas vezes extraindo sublistas ordenadas da lista a ser classificada 
; e mesclando-as com um array resultado. Cada iteração através da lista não-ordenada extrai uma série de elementos que já estavam ordenados,
; e mescla as séries juntas. 
; 
; O nome do algoritmo vem de "vertentes" de dados ordenados dentro da lista não-ordenada que são removidos um de cada vez. 
; É um algoritmo de ordenação por comparação devido ao seu uso de comparações, quando remove vertentes e ao mesclar-los para o array ordenado.

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA STRANDSORT ------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
StrandSort:                                ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;typedef struct node_t *node, node_t;

;struct node_t {
;	int v;
;	node next;	
;};

;typedef struct {
;	node head, tail;
;} slist;

;void push(slist *l, node e){
;	if (!l->head) l->head = e;
;	if (l->tail) l->tail->next = e;
;	l->tail = e;
;}

;node removehead(slist *l){
;	node e = l->head;
;	if(e){
;		l->head = e->next;
;		e->next = 0;
;	}
;	return e;
;};

;void join(slist *a, slist *b){
;	push(a, b->head);
;	a->tail = b->tail;
;}

;void merge(slist *a, slist *b){
;	slist r = { 0 };
;	while(a->head && b->head)
;		push(&r, removehead(a->head->v <= b->head->v ? a : b));	
;		
;	join(&r, a->head ? a : b);
;	*a = r;
;	b->head = b->tail = 0;
;}

;void StrandSort(int *vect, int length){
;	node_t all[length];
;	int i;
;	node e;
;	
;	// array para lista
;	for(i = 0; i < length; i++)
;		all[i].v = vect[i], all[i].next = i < length - 1 ? all + i + 1 : 0;
;		
;	slist list = {all, all + length - 1}, rem, strand = {0}, res = {0};
;	
;	for(e = 0; list.head; list = rem){
;		rem.head = rem.tail = 0;
;		while((e = removehead(&list)))
;			push((!strand.head || e->v >= strand.tail->v) ? &strand : &rem, e);
;		
;		merge(&res, &strand);
;	}
;	
;	// lista para array
;	for(i = 0; res.head; i++, res.head = res.head->next)
;		vect[i] = res.head->v;
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++