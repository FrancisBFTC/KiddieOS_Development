%DEFINE DIRECTORY_SIZE  32

jmp Boot_Begin

BUFFER_NAME           db "MSDOS5.0"    ;MSDOS5.0
BPB:
BytesPerSector        dw 0x0200
SectorsPerCluster     db 1
ReservedSectors       dw 2
TotalFATs             db 0x02
MaxRootEntries        dw 0x0200
TotalSectorsSmall     dw 65512    ; -> FUNCIONANDO (CHS=963/4/17-5)
MediaDescriptor       db 0xF8    ; 0xF8
SectorsPerFAT         dw 246     ; 246   
SectorsPerTrack       dw 17  
NumHeads              dw 4
HiddenSectors         dd 0      ;5 ;; 1+1+3 ( mbr + vbr + reserved sectors depois do vbr)
TotalSectorsLarge     dd 0x0000 
DriveNumber           db 0x80    
Flags                 db 0x00
Signature             db 0x29
BUFFER_VOLUME_ID      dd 0x980E63F5
VolumeLabel           db "KIDDIEOS   "
SystemID              db "FAT16   "  


DAPSizeOfPacket db 10h
DAPReserved     db 00h
DAPTransfer     dw 0001h
DAPBuffer       dd 00000000h
DAPStart        dq 0000000000000000h

DATASTART      dw  0x0000
FATSTART       dw  0x0000
ROOTDIRSTART   EQU (BUFFER_NAME)
ROOTDIRSIZE    EQU (BUFFER_NAME+4)
END_OF_CLUSTER EQU 0xFFF8


NameFile     	db "KERNEL  BIN"
ClusterFile     dw  0x0000

Boot_Begin:
    cli
    mov  ax, 0x07C0
    mov  ds, ax
    mov  es, ax
    mov  ax, 0x0000
    mov  ss, ax
    mov  sp, 0x6000
    sti
	
	mov byte [DriveNumber], byte dl 
    mov ax, 02h
    int 010h
    ;call SetDataDirectory
	;call LoadRootDirectory
	;call SearchFile
	;call LoadFile
	;jmp  RunFile
	
	
SetDataDirectory:
	xor  cx, cx
	mov  ax, WORD [ReservedSectors]  
    add  ax, WORD [HiddenSectors]
	mov  WORD [FATSTART], ax
	
    mov  ax, DIRECTORY_SIZE
    mul  WORD [MaxRootEntries]
    div  WORD [BytesPerSector] 
    mov  WORD [ROOTDIRSIZE], ax  ; 32 setores
    mov cx, ax                   ; CX = 32
	
    xor ax, ax
    mov  al, BYTE [TotalFATs]
    mul  WORD [SectorsPerFAT]   
	add  ax, WORD [FATSTART]
   
    mov word [ROOTDIRSTART], ax   ; Setor 559
    add  ax, cx                   
    mov  WORD [DATASTART], ax     ; Setor 591
	
	
	
LoadRootDirectory:
    mov  ax, word [ROOTDIRSTART]  ; setor inicial para ler
    mov  cx, word [ROOTDIRSIZE]   ; instrução LOOP decrementa CX até 0
    mov  bx, 0x0200
    call  ReadLogicalSectors
	
	
	
SearchFile:
    mov  cx, WORD [MaxRootEntries]    ; Instrução LOOP decrementa CX até 0
    mov  di, 0x0200                   ; Determinando o offset do root carregado
_Loop:
    push  cx
    mov  cx, 0x000B       ; Eleven character name.
    mov  si, NameFile    ; Image name to find.
    push  di
    rep  cmpsb            ; Test for entry match.
    pop  di
    je  LoadFat          ; Se o arquivo foi encontrado.
    pop  cx
    add  di, DIRECTORY_SIZE   ; Queue next directory entry (32).
    loop _Loop
    jmp  _FAILED
	
	
	
LoadFat:
	mov dx, WORD [di + 0x001A]  ; Cluster do arquivo no FAT
    mov WORD [ClusterFile], dx
	
	mov ax, 0x17C0
    mov es, ax 
	
	mov ax, WORD [FATSTART]  ; Setor Lógico inicial para ler
	mov  cx,  (246/2) ; WORD [SectorsPerFAT]  ;  Metade da fat.
    mov  bx, 0x0200                           ;  Determinando o offset da FAT.
    call  ReadLogicalSectors
	
	
	
LoadFile:
    ; Buffer para o arquivo. ES:BX = 0000h:8000h
    xor ax, ax
    mov es, ax
    mov bx, 0x8000
    push  bx
	
	; Em GS vai ficar o segmento da FAT
    mov ax, 0x17C0
    mov gs, ax
	
ReadDataFile:
    pop  bx    ; Buffer do arquivo                               

    mov  ax, WORD [ClusterFile]   
    call  ClusterLBA              		 ; Conversão de Cluster para LBA.
    xor  cx, cx
    mov  cl, BYTE [SectorsPerCluster]    ; 1 Setor para ler
    call  ReadLogicalSectors

    push bx
    
	; Calculando o deslocamento do próximo Cluster do arquivo
    mov ax, WORD [ClusterFile]    ; identify current cluster
    add ax, ax                	  ; 16 bit(2 byte) FAT entry
    mov bx, 0x0200                ; location of FAT in memory
    add bx, ax                    ; index into FAT    
    mov dx, WORD [gs:bx]          ; read two bytes from FAT
    mov  WORD [ClusterFile], dx   ; DX está com o próximo Cluster
	
	push ax
	mov ah, 0eh
	mov al, 'X'
	int 10h
	pop ax
	
    cmp  dx, END_OF_CLUSTER    ; Ou 0xFFFF
    jne  ReadDataFile
	 
	
RunFile:
	mov dl, byte [DriveNumber]
	JMP 0000H:8000H
	
	

; Converter cluster FAT em eschema de Endereçamento LBA
; LBA = ((ClusterFile - 2) * SectorsPerCluster) + DATASTART 
ClusterLBA:
    sub ax, 0x0002
    xor cx, cx
    mov cl, BYTE [SectorsPerCluster]
    mul cx
    add ax, WORD [DATASTART]
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
	jmp _FAILED
	
_SUCCESS:
    pop  cx
    pop  bx
    pop  ax

    ; Queue next buffer.
    add bx, WORD [BytesPerSector] 
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



_FAILED:
    int  0x18


MBR_SIGNATURE: 

    TIMES 510-($-$$) DB 0
    DW 0xAA55
 
dw 0xAA55                     ; Boot Signature