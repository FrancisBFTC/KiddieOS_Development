%INCLUDE "../../Hardware/memory.lib"
%INCLUDE "../../Hardware/kernel.lib"


[ORG 0x2000]
[BITS 32]
;ALIGN 4

FILEMNG 	EQU  0x120000
File_Mng: 

;SECTION protectedmode vstart=FILEMNG, valign=4

jmp 	LoadThisFile32

FileSegments    	 dw   0x0000
DirSegments     	 dw   0x0000
LoadingDir      	 db   0
LoadDriver 			 db   0
FileFound       	 db   0
ClusterFile     	 dw   0x0000


SHELL.ErrorDir       EQU  ((SHELL16+0C000h)+7)
SHELL.ErrorFile      EQU  ((SHELL16+0C000h)+8)

DATASTART            EQU  0x004E
FATSTART             EQU  0x0050 
ROOTDIRSTART         EQU  0x0003
BYTES_PER_SECTOR     EQU  512
SECTORS_PER_CLUSTER  EQU  8
MAX_ROOT_ENTRIES     EQU  512

BAD_CLUSTER          EQU  0xFFF7
END_OF_CLUSTER1      EQU  0xFFF8
END_OF_CLUSTER2      EQU  0xFFFF
FCLUSTER_ENTRY       EQU  0x001A
FSIZE_ENTRY          EQU  0x001C
ROOT_SEGMENT         EQU  0x7E00
VBR_SEGMENT          EQU  0x7C00
KERNEL_SEGMENT   	 EQU  0xC000
FAT_SEGMENT          EQU  0x17E00
FILE_SEGMENT     	 EQU  0x38000

DIRECTORY_SIZE       EQU  32
EXT_LENGTH       	 EQU  3
NAME_LENGTH      	 EQU  8
  


DAP:
	.SizeOfPacket db 16
	.Reserved     db 0
	.Transfer     dw SECTORS_PER_CLUSTER
	.Buffer       dd 0
	.Start        dq 0

LoadThisFile32:
	jmp 	$
	xor 	eax, eax
	mov 	ax, 0x0011
	mov 	es, ax
    mov  	ecx, MAX_ROOT_ENTRIES    ; Instrução LOOP decrementa CX até 0
    mov  	edi, ROOT_SEGMENT        ; Determinando o offset do root carregado
.Loop32:
    push  	ecx
    mov   	ecx, 0x000B       		 ;  Eleven character name.
    push  	esi
    push  	edi
.Verify:
	mov 	ebx, esi
	mov 	al, byte[es:0x0fee]
	cmp 	byte[edi], al
	inc 	edi
	inc 	esi
	jne	 	.NextDirSt
	loop 	.Verify
	jmp 	$
	pop   	edi
	pop   	esi
    call  	LoadFile32
	jmp 	.NextDir	
.NextDirSt:
	pop   	edi
	pop   	esi
.NextDir:
    pop   	ecx
    add   	edi, DIRECTORY_SIZE   	; Queue next directory entry (32).
	cmp   	byte[FileFound], 1
	je    	RetLoadThis32
    loop  	.Loop32
RetLoadThis32:
	jmp 	$
	mov		byte[FileFound], 0
ret


LoadFile32:
	push 	ebx
	
	mov 	byte[FileFound], 1
	mov 	byte[LoadDriver], 0
	
	cmp 	byte[LoadingDir], 1
	jne 	IsLoadingFile
	jmp 	IsLoadingDir
	
IsLoadingDir:
	cmp 	byte[edi + 11], 0x30
	jne	 	IsNotADir
	jmp 	ContinueLoad
IsLoadingFile:
	cmp 	byte[edi + 11], 0x30
	je	 	IsNotAFile
ContinueLoad:
	mov 	dx, WORD [edi + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov 	WORD [ClusterFile], dx

	jmp 	ReadDataFile
	
IsNotADir:
	cmp 	byte[edi + 11], 0x10
	je 		ContinueLoad
	mov 	byte[SHELL.ErrorDir], 1
	jmp 	RetLoadFile32
IsNotAFile:
	mov 	byte[SHELL.ErrorFile], 1
	jmp 	RetLoadFile32

	
LoadBinary32:
	push 	ebx
	
	mov 	byte[FileFound], 1
	mov 	byte[LoadDriver], 1
	
	sub 	edi, NAME_LENGTH
	mov 	dx, WORD [edi + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov 	WORD [ClusterFile], dx
	
ReadDataFile:
    pop  	ebx             ; Buffer do arquivo  
	
    mov  	ax, WORD [ClusterFile]   
    call  	ClusterLBA              		 ; Conversão de Cluster para LBA.
    call  	Read_Cluster
	
    push 	ebx
    
	; Calculando o deslocamento do próximo Cluster do arquivo
    mov 	ax, WORD [ClusterFile]    	; identify current cluster
    add 	eax, eax                	; 16 bit(2 byte) FAT entry
    mov 	ebx, FAT_SEGMENT            ; location of FAT in memory
    add 	ebx, eax                    ; index into FAT    
    mov 	dx, WORD [ebx]              ; read two bytes from FAT
    mov 	WORD [ClusterFile], dx   	; DX está com o próximo Cluster
	
    cmp  	dx, END_OF_CLUSTER1    		; 0xFFF8
    je  	EndOfFile
	cmp  	dx, END_OF_CLUSTER2    		; 0xFFFF
	je 		EndOfFile
	jmp 	ReadDataFile

EndOfFile:	
	pop 	ebx
	
	mov 	edx, DWORD[edi + FSIZE_ENTRY]
	
	cmp 	byte[LoadDriver], 0
	jz  	SaveNextOffset
	
	mov 	edx, DWORD[edi + (FSIZE_ENTRY - NAME_LENGTH)]
	
SaveNextOffset:
	add 	ebx, edx
	add 	ebx, 2
ret
RetLoadFile32:
    pop 	ebx
ret
	
	

; Converter cluster FAT em eschema de Endereçamento LBA
; LBA = ((ClusterFile - 2) * SectorsPerCluster) + DATASTART 
ClusterLBA:
    sub 	eax, 2
    xor 	ecx, ecx
    mov 	ecx, SECTORS_PER_CLUSTER
    mul 	ecx
	mov 	cx, WORD [VBR_SEGMENT + DATASTART]
    add 	eax, ecx
ret

	
Read_Cluster:
    mov 	DWORD [DAP.Buffer], ebx
    mov 	DWORD [DAP.Start],  eax     ; Setor lógico inicial para ler
_STARTREAD:
	mov 	ecx, 0x0005	               ; 5 tentativas de leitura
    push  	eax
    push  	ebx

_TRYAGAIN:
    push 	esi
    mov 	ah, 0x42
    mov 	dl, 0x80
    mov 	esi, DAP.SizeOfPacket
    int 	0x13
    pop 	esi
    jnc  	_NEXTOFFSET                  ; Test for read error.
    xor  	eax, eax                     ; BIOS reset disk.
    int  	0x13                         ; Invoke BIOS.    
    dec  	ecx                          ; Decrement error counter.
    jnz  	_TRYAGAIN   
	jmp 	ERROR
	
_NEXTOFFSET:
    pop  	ebx
    pop  	eax
	add 	ebx, (BYTES_PER_SECTOR * SECTORS_PER_CLUSTER)
_Done:
	ret

ERROR:
    int  	0x18