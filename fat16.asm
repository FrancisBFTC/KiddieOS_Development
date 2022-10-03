%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG FAT16]

jmp 	LoadAllExtensionFiles
jmp 	LoadDirectory
jmp 	LoadFAT
jmp 	LoadThisFile
jmp 	LoadV86File


FileSegments    dw 0x0000
DirSegments     dw 0x0000
LoadingDir      db 0

SYS.VM db 0
FileVM  times 11 db 0
ClusterFile     dw  0x0000

DAPSizeOfPacket db 10h
DAPReserved     db 00h
DAPTransfer     dw 0001h
DAPBuffer       dd 00000000h
DAPStart        dq 0000000000000000h

SHELL.ErrorDir   EQU  (SHELL16+7)
SHELL.ErrorFile  EQU  (SHELL16+8)

DATASTART            EQU  0x004E
FATSTART             EQU  0x0050 
ROOTDIRSTART         EQU  0x0003
BYTES_PER_SECTOR     EQU  512
SECTORS_PER_CLUSTER  EQU  1   ;8
MAX_ROOT_ENTRIES     EQU  512

BAD_CLUSTER      EQU 0xFFF7
END_OF_CLUSTER1  EQU 0xFFF8
END_OF_CLUSTER2  EQU 0xFFFF
FCLUSTER_ENTRY   EQU 0x001A
FSIZE_ENTRY      EQU 0x001C
ROOT_SEGMENT     EQU 0x07C0
FAT_SEGMENT      EQU 0x17C0
KERNEL_SEGMENT   EQU 0x0C00
FILE_SEGMENT     EQU 0x3800

DIRECTORY_SIZE   EQU 32
EXT_LENGTH       EQU 3
NAME_LENGTH      EQU 8
  
;Extension       db "SYS"
FileFound       db 0
StringDvr  db " driver loaded at address 0x",0
LoadDriver db 0

LoadDirectory:
	pusha
	mov ax, ROOT_SEGMENT
	mov es, ax
	mov ax, WORD [es:ROOTDIRSTART]
	mov bx, 0x0200
	mov cx, DIRECTORY_SIZE
	call ReadLogicalSectors
	popa
ret
	
LoadFAT:
	pusha
	mov ax, FAT_SEGMENT
    mov es, ax
	mov ax, ROOT_SEGMENT
	mov fs, ax
	mov ax, WORD [fs:FATSTART]  ; Setor Lógico inicial para ler
	mov  cx, (246/2)         ; WORD [SectorsPerFAT]  ;  Metade da fat.
    mov  bx, 0x0200                           ;  Determinando o offset da FAT.
    call  ReadLogicalSectors
	mov ax, ROOT_SEGMENT
	mov es, ax
	popa
ret

LoadAllExtensionFiles:
	mov ax, ROOT_SEGMENT
	mov es, ax
    mov  cx, MAX_ROOT_ENTRIES    ; Instrução LOOP decrementa CX até 0
    mov  di, 0x0200                   ; Determinando o offset do root carregado
	add di, NAME_LENGTH
_Loop:
    push  cx
    mov  cx, EXT_LENGTH       ; 0x000B Eleven character name.
    push  si
    push  di
	call VerifyExt
	pop  di
	pop  si
    call  LoadBinaryFile 
    pop  cx
    add  di, DIRECTORY_SIZE   ; Queue next directory entry (32).
    loop _Loop
	cmp byte[FileFound], 0
	je BOOT_FAILED
	mov byte[FileFound], 0
ret

VerifyExt:
	Verify:
		mov al, byte[es:di]
		cmp al, byte[ds:si]
		jne RetVerify
		inc si
		inc di
		loop Verify
RetVerify:
ret

LoadThisFile:
	clc
	mov 	es, ax
    mov  	cx, MAX_ROOT_ENTRIES    ; Instrução LOOP decrementa CX até 0
    mov  	di, 0x0200                   ; Determinando o offset do root carregado
	cmp 	byte[SYS.VM], 1
	je 		ConfigVM
	jmp 	FLoop
ConfigVM:
	;sti
	mov 	word[DirSegments], 0x07C0
	mov  	si, FileVM         ; Argumento: ponteiro para nome de arquivo
	mov 	ax, 0x5000 				  ; segmento de arquivos 0x5000
	mov 	word[FileSegments], ax
	mov 	byte[LoadingDir], 0
	mov 	byte[LoadDriver], 0
	mov 	bx, 0x0000
FLoop:
    push  cx
    mov  cx, 0x000B       	;  Eleven character name.
    push  si
    push  di
	call VerifyExt
	pop  di
	pop  si
    call  LoadFile 
    pop  cx
    add  di, DIRECTORY_SIZE   ; Queue next directory entry (32).
	cmp byte[FileFound], 1
	je RetLoadThis
    loop FLoop
	stc
RetLoadThis:
	cmp 	byte[SYS.VM], 1
	je 		RetV86Mode
	mov 	byte[FileFound], 0
	mov 	byte[SYS.VM], 0
RetNow:
	ret


RetV86Mode:
	cmp  	dx, END_OF_CLUSTER1    ; 0xFFF8
    je  	ClearVMode
	cmp  	dx, END_OF_CLUSTER2    ; 0xFFFF
	je 		ClearVMode
	cmp 	byte[FileFound], 0
	je 		ClearVMode
ret
ClearVMode:
	mov 	byte[SYS.VM], 0
	mov 	byte[FileFound], 0
ret

LoadV86File:
	mov 	ax, word[FileSegments]
	mov 	es, ax
	xor 	bx, bx
	call 	ReadRest
	jmp 	RetV86Mode
	
ReadRest:
	push 	bx
	push 	di
	push 	bx
	jmp 	SetOtherSegments
	
	
LoadFile:
	push bx
	push di
	push bx
	cmp cl, 0
	jne RetLoadFile
	
	mov byte[FileFound], 1
	mov byte[LoadDriver], 0
	
	cmp 	byte[LoadingDir], 1
	jne 	IsLoadingFile
	jmp 	IsLoadingDir
	
IsLoadingDir:
	cmp 	byte[es:di + 11], 0x30
	jne	 	IsNotADir
	jmp 	ContinueLoad
IsLoadingFile:
	cmp 	byte[es:di + 11], 0x30
	je	 	IsNotAFile
ContinueLoad:
	mov dx, WORD [es:di + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov WORD [ClusterFile], dx
	
	mov ax, word[FileSegments]  ;FILE_SEGMENT
    mov es, ax
	jmp SetOtherSegments
	
IsNotADir:
	cmp 	byte[es:di + 11], 0x10
	je 		ContinueLoad
	mov 	byte[SHELL.ErrorDir], 1
	jmp 	RetLoadFile
IsNotAFile:
	mov 	byte[SHELL.ErrorFile], 1
	jmp 	RetLoadFile

	
LoadBinaryFile:
	push bx
	push di
	push bx
	cmp cl, 0
	jne RetLoadFile
	
	mov byte[FileFound], 1
	mov byte[LoadDriver], 1
	
	sub di, NAME_LENGTH
	mov dx, WORD [es:di + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov WORD [ClusterFile], dx
	
    mov ax, KERNEL_SEGMENT
    mov es, ax
	
SetOtherSegments:
	
	mov ax, ROOT_SEGMENT
    mov fs, ax
	
    mov ax, FAT_SEGMENT
    mov gs, ax
	
ReadDataFile:
    pop  bx    ; Buffer do arquivo  
	
    mov  ax, WORD [ClusterFile]   
    call  ClusterLBA          		 ; Conversão de Cluster para LBA.
    xor  cx, cx
    mov  cl, SECTORS_PER_CLUSTER    ; 8 Setores para ler
    call  	ReadLogicalSectors

    push bx
    
	; Calculando o deslocamento do próximo Cluster do arquivo
    mov ax, WORD [ClusterFile]    ; identify current cluster
    add ax, ax                	  ; 16 bit(2 byte) FAT entry
    mov bx, 0x0200                ; location of FAT in memory
    add bx, ax                    ; index into FAT    
    mov dx, WORD [gs:bx]          ; read two bytes from FAT
    mov  WORD [ClusterFile], dx   ; DX está com o próximo Cluster
	
	cmp 	byte[SYS.VM], 1
	je 		RetLoadFile
	
    cmp  dx, END_OF_CLUSTER1    ; 0xFFF8
    je  EndOfFile
	cmp  dx, END_OF_CLUSTER2    ; 0xFFFF
	je 	EndOfFile
	
	jmp ReadDataFile
	
	
EndOfFile:	
	pop bx
	pop di
	pop bx
	
	mov ax, word[DirSegments]
	mov es, ax
	mov edx, DWORD[es:di + FSIZE_ENTRY]
	
	cmp byte[LoadDriver], 0
	jz  SaveNextOffset
	
	push di
	push si
	sub di, NAME_LENGTH
	call PrintNameFile
	mov si, StringDvr
	call Print_String
	mov ax, bx
	call Print_Hexa_Value16
	call Break_Line
	pop si
	pop di
	
	mov edx, DWORD[es:di + (FSIZE_ENTRY - NAME_LENGTH)]
	
SaveNextOffset:
	add bx, dx
	add bx, 2
ret
RetLoadFile:
    pop bx
	pop di
	pop bx
ret
	
	

; Converter cluster FAT em eschema de Endereçamento LBA
; LBA = ((ClusterFile - 2) * SectorsPerCluster) + DATASTART 
ClusterLBA:
    sub ax, 0x0002
    xor cx, cx
    mov cl, SECTORS_PER_CLUSTER
    mul cx
    add ax, WORD [fs:DATASTART]
ret

	
ReadLogicalSectors:
    mov WORD [DAPBuffer]   ,bx
    mov WORD [DAPBuffer+2] ,es  ; ES:BX para onde os dados vão
    mov WORD [DAPStart]    ,ax  ; Setor lógico inicial para ler
_MAIN:
    mov di, 0x0005	  ; 5 tentativas de leitura
_SECTORLOOP:
    push  ax
    push  bx
    push  cx

    push si
    mov ah, 0x42
    mov dl, 0x80
    mov si, DAPSizeOfPacket
    int 0x13
    pop si
    jnc  _SUCCESS      ; Test for read error.
    xor  ax, ax        ; BIOS reset disk.
    int  0x13          ; Invoke BIOS.    
    dec  di            ; Decrement error counter.
    
    pop  cx
    pop  bx
    pop  ax
	
    jnz  _SECTORLOOP    
	jmp BOOT_FAILED
	
_SUCCESS:
    pop  cx
    pop  bx
    pop  ax
	
    ; Queue next buffer.
    add bx, BYTES_PER_SECTOR
    cmp bx, 0x0000
    jne _NEXTSECTOR

    ; Trocando de segmento.
    push ax
    mov  ax, es
    add  ax, 0x1000
    mov  es, ax
    pop  ax
	
_NEXTSECTOR:
    inc  ax                     ; Queue next sector.
    mov WORD [DAPBuffer], bx
    mov WORD [DAPStart], ax
    loop  _MAIN                 ; Read next sector.
ret
	
BOOT_FAILED:
    int  0x18

