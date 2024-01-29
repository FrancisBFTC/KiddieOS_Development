[BITS 16]
[ORG 0000h]


jmp Boot_Begin

LBASIZE   EQU  61173  ; ((Cylinder x Sector))

BUFFER_NAME           db "MSDOS5.0"    ;MSDOS5.0
BPB:
BytesPerSector        dw 0x0200
SectorsPerCluster     db 1   ;8
ReservedSectors       dw 4      ;4 -> funcionando
TotalFATs             db 0x02
MaxRootEntries        dw 0x0200
TotalSectorsSmall     dw 0x0000
MediaDescriptor       db 0xF8    ; 0xF8
SectorsPerFAT         dw 246     ; 246   
SectorsPerTrack       dw 63      ; 63  
NumHeads              dw 255     ; 255
HiddenSectors         dd 0x00000003   ;5  3 -> funcionando
TotalSectorsLarge     dd 0x00EE2000
DriveNumber           db 0x00    
Flags                 db 0x00
Signature             db 0x28   ; <- alterar para 0x28
BUFFER_VOLUME_ID      dd 0x80808080
VolumeLabel           db "KIDDIEOS   "
SystemID              db "FAT16   "  

DAPSizeOfPacket db 10h
DAPReserved     db 00h
DAPTransfer     dw 0001h
DAPBuffer       dd 00000000h
DAPStart        dq 0000000000000000h

DATASTART      EQU 	0x0600 + 0x4E	; era DW
FATSTART       EQU 	0x0600 + 0x50	; era DW
ROOTDIRSTART   EQU 	0x0600 + 0x52	; era EQU BUFFER_NAME
ROOTDIRSIZE    EQU 	0x0600 + 0x56	; era EQU BUFFER_NAME+4

BAD_CLUSTER      EQU 0xFFF7
END_OF_CLUSTER   EQU 0xFFF8
FCLUSTER_ENTRY   EQU 0x001A
FSIZE_ENTRY      EQU 0x001C
ROOT_SEGMENT     EQU 0x0200	  ; era 0x07C0
FAT_SEGMENT      EQU 0x1000   ; era 0x17C0
KERNEL_SEGMENT   EQU 0x3000   ; era 0x0C00
DIRECTORY_SIZE   EQU 32
EXT_LENGTH       EQU 3
NAME_LENGTH      EQU 8
  
Extension       db "OSF"
ClusterFile     dw  0x0000
FileFound       db 0

Boot_Begin:
    cli
    mov  	ax, 0x07C0    ; era ROOT_SEGMENT = 0x07C0
    mov  	ds, ax
	xor  	ax, ax
    mov  	es, ax
    mov  	ax, 0x0000
    mov  	ss, ax
    mov  	sp, 0x1990	   ; era 0x6000, atual = deslocamento de 16 bytes para diretórios
    sti
	
	mov 	ax, 3
	int 	0x10
	
	mov 	byte [DriveNumber], dl
	
	call 	LoadRootDirectory
	call 	LoadFAT
	call 	SearchFile
	mov 	dl, byte [DriveNumber]
	
	JMP 	0x3000:0x0		; era 0C00h:0000H
	
	
LoadRootDirectory:
	xor  	cx, cx
	mov  	ax, WORD [ReservedSectors]  
    add  	ax, WORD [HiddenSectors]
	mov  	WORD [es:FATSTART], ax
	
    mov  	ax, DIRECTORY_SIZE
    mul  	WORD [MaxRootEntries]
    div  	WORD [BytesPerSector] 
    mov  	WORD [es:ROOTDIRSIZE], ax  ; 32 setores
    mov 	cx, ax                   ; CX = 32
	
    xor 	ax, ax
    mov  	al, BYTE [TotalFATs]
    mul  	WORD [SectorsPerFAT]   
	add  	ax, WORD [es:FATSTART]
    
	;sub ax, 1 ; <- Setor Escondido da MBR
    mov 	word [es:ROOTDIRSTART], ax   ; Setor 499
	push 	ax
    add  	ax, cx
    mov  	WORD [es:DATASTART], ax     ; Setor 530
	
	mov 	ax, ROOT_SEGMENT
	mov 	es, ax
    pop 	ax                        ; setor inicial para ler
    mov  	bx, 0x0000				  ; era 0x0200, de 0x2000 descendo até 0x0800 é a pilha
    call  	ReadLogicalSectors
ret

LoadFAT:
	mov 	ax, FAT_SEGMENT		; FAT_SEGMENT = 0x0001
    mov 	es, ax
	xor 	ax, ax
	mov 	fs, ax
	
	mov 	ax, WORD [fs:FATSTART]  		; Setor Lógico inicial para ler
	mov  	cx, WORD [SectorsPerFAT]  	; Era Metade da fat (246/2).
    mov  	bx, 0x0000          		; Era 0x17C0:0x0200, agora é 0x0001:0x0000
    call  	ReadLogicalSectors
ret	
	
SearchFile:
	mov 	ax, ROOT_SEGMENT
	mov 	es, ax
    mov  	cx, WORD [MaxRootEntries]    ; Instrução LOOP decrementa CX até 0
    mov  	di, 0x0000                   ; Era, 0x0200, Determinando o offset do root carregado
	add 	di, NAME_LENGTH
	xor 	bx, bx
_Loop:
    push  	cx
    mov  	cx, EXT_LENGTH       ; Extension size.
    mov  	si, Extension    	  ; NameFile to find.
    push  	di
	repe 	cmpsb
	pop  	di
	jne  	NoFounded
    call  	LoadFile
NoFounded:	
    pop  	cx
    add  	di, DIRECTORY_SIZE   ; Queue next directory entry (32).
    loop 	_Loop
	cmp 	byte[FileFound], 0
	je 		BOOT_FAILED
ret
		

LoadFile:
	push 	bx
	push 	di
	push 	bx
	
	mov 	byte[FileFound], 1
	
	sub 	di, NAME_LENGTH
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov 	WORD [ClusterFile], dx
	
    mov 	ax, KERNEL_SEGMENT
    mov 	es, ax
	
    mov 	ax, FAT_SEGMENT
    mov 	gs, ax
	
	mov 	ax, ROOT_SEGMENT
	mov 	fs, ax
	
ReadDataFile:
    pop  	bx    ; Buffer do arquivo  
	
    mov  	ax, WORD [ClusterFile]   
    call  	ClusterLBA              		 ; Conversão de Cluster para LBA.
    xor  	cx, cx
    mov  	cl, BYTE [SectorsPerCluster]    ; 1 Setor para ler
    call  	ReadLogicalSectors

    push 	bx
    
	; Calculando o deslocamento do próximo Cluster do arquivo
    mov 	ax, WORD [ClusterFile]    ; identify current cluster
    add 	ax, ax                	  ; 16 bit(2 byte) FAT entry
    mov 	bx, 0x0000                ; Era 0x0200, location of FAT in memory
    add 	bx, ax                    ; index into FAT    
    mov 	dx, WORD [gs:bx]          ; read two bytes from FAT
    mov  	WORD [ClusterFile], dx   ; DX está com o próximo Cluster
	
    cmp  	dx, END_OF_CLUSTER    ; Ou 0xFFFF
    jne  	ReadDataFile
	
	pop 	bx
	pop 	di
	pop 	bx
	
	mov 	ax, ROOT_SEGMENT	; Era 0x07C0
	mov 	es, ax
	
	mov 	edx, DWORD[es:di + (FSIZE_ENTRY - NAME_LENGTH)]
	add 	bx, dx
	add 	bx, 2
ret	

; Converter cluster FAT em eschema de Endereçamento LBA
; LBA = ((ClusterFile - 2) * SectorsPerCluster) + DATASTART 
ClusterLBA:
	push 	es
    sub 	ax, 0x0002
    xor 	cx, cx
    mov 	cl, BYTE [SectorsPerCluster]
    mul 	cx
	xor 	cx, cx
	mov 	es, cx
    add 	ax, WORD [es:DATASTART]
	pop 	es
ret

	
ReadLogicalSectors:
    mov 	WORD [DAPBuffer]   ,bx
    mov 	WORD [DAPBuffer+2] ,es  ; ES:BX para onde os dados vão
    mov 	WORD [DAPStart]    ,ax  ; Setor lógico inicial para ler
_MAIN:
    mov 	di, 0x0005	  ; 5 tentativas de leitura
_SECTORLOOP:
    push  	ax
    push  	bx
    push  	cx

    push 	si
    mov 	ah, 0x42
	mov 	dl, byte[DriveNumber]
    mov 	si, DAPSizeOfPacket
    int 	0x13
    pop 	si
    jnc  	_SUCCESS      ; Test for read error.
    xor  	ax, ax        ; BIOS reset disk.
    int  	0x13          ; Invoke BIOS.    
    dec  	di            ; Decrement error counter.
    
    pop  	cx
    pop  	bx
    pop  	ax
	
    jnz  	_SECTORLOOP
	jmp 	BOOT_FAILED
	
_SUCCESS:
    pop  	cx
    pop  	bx
    pop  	ax

    ; Queue next buffer.
    add 	bx, WORD [BytesPerSector] 
    cmp 	bx, 0x0000
    jne 	_NEXTSECTOR

    ; Trocando de segmento.
    push 	ax
    mov  	ax, es
    add  	ax, 0x1000   ; era 0x1000, porém agora foi alterado para linear
    mov  	es, ax
    pop  	ax
	
_NEXTSECTOR:
    inc  	ax                     ; Queue next sector.
    mov 	WORD [DAPBuffer], bx
	mov 	WORD [DAPBuffer+2],es  ; ES:BX para onde os dados vão
    mov 	WORD [DAPStart], ax
    loop  	_MAIN                 ; Read next sector.
ret

BOOT_FAILED:
    int  	0x18

MBR_SIG:
	TIMES 510-($-$$) DB 0
	DW 0xAA55