; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;              ALGORITMOS DE ORDENAÇÃO
;
;              Funções em Assembly x86
;              Criado por Wender Francis
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%IFNDEF 	__SORTINGMETHODS_INC__
%DEFINE 	__SORTINGMETHODS_INC__

; --------------------------------------------------------------------------------------
; ÁREA DE INCLUSÕES DOS ALGORITMOS

%INCLUDE "Library/Sort/InsertionSort.asm"
%INCLUDE "Library/Sort/SelectionSort.asm"
%INCLUDE "Library/Sort/QuickSort.asm"
%INCLUDE "Library/Sort/BubbleSort.asm"
%INCLUDE "Library/Sort/CombSort.asm"
%INCLUDE "Library/Sort/GnomeSort.asm"
%INCLUDE "Library/Sort/CockTailSort.asm"
%INCLUDE "Library/Sort/MergeSort.asm"
%INCLUDE "Library/Sort/ShellSort.asm"
%INCLUDE "Library/Sort/RadixSort.asm"
%INCLUDE "Library/Sort/HeapSort.asm"
%INCLUDE "Library/Sort/TimSort.asm"
%INCLUDE "Library/Sort/StrandSort.asm"
%INCLUDE "Library/Sort/OddEvenSort.asm"
%INCLUDE "Library/Sort/SmoothSort.asm"
%INCLUDE "Library/Sort/BogoSort.asm"
%INCLUDE "Library/Sort/StoogeSort.asm"

; --------------------------------------------------------------------------------------

%ENDIF