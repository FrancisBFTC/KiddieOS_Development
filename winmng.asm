%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG WINMNG]


jmp Os_WinMng_Setup

%INCLUDE "Hardware/VESA.lib"
%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"

FAT16.LoadDirectory   EQU	(FAT16+3)
FAT16.LoadFAT         EQU	(FAT16+6)
FAT16.LoadThisFile    EQU	(FAT16+9)
FAT16.FileSegments    EQU   (FAT16+15)
FAT16.DirSegments 	  EQU   (FAT16+17)
FAT16.LoadingDir      EQU   (FAT16+19)

WinMng32_File  db "WINMNG32KXE"
ImagesBMP	   db "CHILD   BMP"
			
Os_WinMng_Setup:
	mov 	ax, 3
	int 	0x10
	
	call 	Set_Video_Mode
	
	mov 	ax, 0x07C0
	mov 	es, ax
	mov  	si, WinMng32_File         ; Argumento: ponteiro para nome de arquivo
	mov 	ax, 0x9000 				  ; segmento de programas 0x9000
	mov 	word[FAT16.FileSegments], ax
	mov 	ax, es
	mov 	word[FAT16.DirSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	mov 	bx, 0x0000
	call 	FAT16.LoadThisFile
	
	mov 	si, ImagesBMP
	mov 	ax, 0x07C0
	mov 	es, ax
	mov 	ax, 0x5000           ; 0x3000
	mov 	word[FAT16.FileSegments], ax
	mov 	ax, es
	mov 	word[FAT16.DirSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	mov 	bx, 0x0000
	call 	FAT16.LoadThisFile
	call 	SYSCMNG
	
	xor 	ax, ax
	int 	0x16
	
ret