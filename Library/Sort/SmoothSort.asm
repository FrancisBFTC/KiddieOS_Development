; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ***** FUNÇOES DE ORDENAÇÃO EM SISTEMA BOOTÁVEL *****

; Ordenação por SMOOTHSORT
; 
; Smoothsort (método) é um algoritmo de ordenação de ordenação por comparação. É uma variação do heapsort e foi desenvolvido 
; por Edsger Dijkstra em 1981. Como o heapsort, o limite superior do smoothsort é de O(n log n). A vantagem de smoothsort é que 
; ele se aproxima de tempo O(n) se a entrada já tem algum grau de ordenação, enquanto a média do heapsort é de O(n log n), independentemente 
; do estado inicial em termos de ordenação. 
;
; O array a ser ordenado é dividido em uma string de heaps, cada heap com um tamanho igual a um dos números de Leonardo L(n). 
; O processo de divisão é simples - os nós mais à esquerda do array são feitos no maior heap possível, e o restante é dividido igualmente. 
; O Heapsort, é baseado em uma estrutura de dados denominada heap. Um heap é uma árvore estritamente binária que satisfaz a seguinte propriedade: 
; dado qualquer elemento da árvore, este será sempre maior ou igual que seus filhos diretos. Considerando a transitividade, cada elemento é maior 
; ou igual que todos os seus descendentes na árvore. A árvore é, na verdade, implícita, simulada em um vetor, fazendo com que cada elemento no 
; vetor com índice i seja pai dos elementos com índice (i*2)+1 e (i*2)+2 (considerando o endereço inicial do array igual a zero).
;
; O algoritmo SmoothSort é parecido com o Heapsort, no sentido de que cria, em um primeiro passo, várias árvores, tal que as raízes das árvores 
; devem ser maiores que todos os demais elementos, e a raiz de cada sub-árvore deve manter essa mesma propriedade. Para construir a floresta a 
; partir do vetor, o Smoothsort considera um elemento do vetor de cada vez. Se as duas últimas árvores da floresta tiverem tamanhos correspondentes 
; a dois números consecutivos da seqüência de Leonardo, então essas duas árvores junto com o elemento adicionado se juntam e formam uma nova árvore 
; da floresta, conforme a recorrência: Ln = Ln-1 + Ln-2 + 1. 

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE "Library/Sort/vars.asm"

; --------------------------------------------------------------------------------------------------------------------------
; ARGUMENTOS DA ROTINA SMOOTHSORT ------------------------------------------------------------------------------------------
; IN:  ECX = Tamanho do Vetor
;      ESI = Endereço do Vetor
;
; OUT: Nenhum.
; --------------------------------------------------------------------------------------------------------------------------
SmoothSort:                                ; Label que será chamada por instrução CALL
	pushad                                 ; Armazene todos os registradores na pilha
	
	;TODO fazer o algoritmo em Assembly
	
	popad                                  ; Restaure todos os registradores da pilha
ret                                        ; Retorne para a chamada da instrução CALL
; --------------------------------------------------------------------------------------------------------------------------


;typedef char* String;

;#define IsAscending(A,B) (strcmp(A,B) <= 0)
;
;#define UP(IA,IB) temp = IA; IA += IB + 1; IB = temp;
;#define DOWN(IA,IB) temp = IB; IB = IA - IB - 1; IA = temp;

;static int q, r, p, b, c, r1, b1, c1;
;static String* A;

;static void Sift()
;{
;	int r0, r2, temp;
;	String t;
;	r0 = r1;
;	t = A[r0];
;
;	while (b1 >= 3)
;	{
;		r2 = r1 - b1 + c1;
;
;		if (!IsAscending(A[r1 - 1], A[r2]))
;		{
;			r2 = r1 - 1;
;			DOWN(b1, c1);
;		}
;
;		if (IsAscending(A[r2], t))
;		{
;			b1 = 1;
;		}
;		else
;		{
;			A[r1] = A[r2];
;			r1 = r2;
;			DOWN(b1, c1);
;		}
;	}
;
;	if (r1 - r0)
;		A[r1] = t;
;}
;
;static void Trinkle()
;{
;	int p1, r2, r3, r0, temp;
;	String t;
;	p1 = p;
;	b1 = b;
;	c1 = c;
;	r0 = r1;
;	t = A[r0];
;
;	while (p1 > 0)
;	{
;		while ((p1 & 1) == 0)
;		{
;			p1 >>= 1;
;			UP(b1, c1)
;		}
;
;		r3 = r1 - b1;
;
;		if ((p1 == 1) || IsAscending(A[r3], t))
;		{
;			p1 = 0;
;		}
;		else
;		{
;			--p1;
;
;			if (b1 == 1)
;			{
;				A[r1] = A[r3];
;				r1 = r3;
;			}
;			else
;			{
;				if (b1 >= 3)
;				{
;					r2 = r1 - b1 + c1;
;
;					if (!IsAscending(A[r1 - 1], A[r2]))
;					{
;						r2 = r1 - 1;
;						DOWN(b1, c1);
;						p1 <<= 1;
;					}
;					if (IsAscending(A[r2], A[r3]))
;					{
;						A[r1] = A[r3]; r1 = r3;
;					}
;					else
;					{
;						A[r1] = A[r2];
;						r1 = r2;
;						DOWN(b1, c1);
;						p1 = 0;
;					}
;				}
;			}
;		}
;	}
;
;	if (r0 - r1)
;		A[r1] = t;
;
;	Sift();
;}

;static void SemiTrinkle() {
;	String T;
;	r1 = r - c;
;
;	if (!IsAscending(A[r1], A[r]))
;	{
;		T = A[r];
;		A[r] = A[r1];
;		A[r1] = T;
;		Trinkle();
;	}
;}

;static void SmoothSort(String Aarg[], const int N) {
;	int temp;
;	A = Aarg;
;	q = 1;
;	r = 0;
;	p = 1;
;	b = 1;
;	c = 1;
;
;	while (q < N) {
;		r1 = r;
;		if ((p & 7) == 3)
;		{
;			b1 = b;
;			c1 = c;
;			Sift();
;			p = (p + 1) >> 2;
;			UP(b, c);
;			UP(b, c);
;		}
;		else if ((p & 3) == 1) {
;			if (q + c < N)
;			{
;				b1 = b;
;				c1 = c;
;				Sift();
;			}
;			else
;			{
;				Trinkle();
;			}
;
;			DOWN(b, c);
;			p <<= 1;
;
;			while (b > 1)
;			{
;				DOWN(b, c);
;				p <<= 1;
;			}
;
;			p++;
;		}
;
;		q++;
;		r++;
;	}

;	r1 = r;
;	Trinkle();
;
;	while (q > 1)
;	{
;		--q;
;
;		if (b == 1)
;		{
;			r--;
;			p--;
;
;			while ((p & 1) == 0)
;			{
;				p >>= 1;
;				UP(b, c);
;			}
;		}
;		else
;		{
;			if (b >= 3) {
;				p--;
;				r = r - b + c;
;				if (p > 0)
;					SemiTrinkle();
;
;				DOWN(b, c);
;				p = (p << 1) + 1;
;				r = r + c;
;				SemiTrinkle();
;				DOWN(b, c);
;				p = (p << 1) + 1;
;			}
;		}
;	}
;}


; ***** FIM DAS FUNÇOES DE ORDENAÇÃO *****
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++