[BITS 16]
[ORG 0000h]

jmp Boot_Begin

LBASIZE   EQU  61173  ; ((Cylinder x Sector))

BUFFER_NAME           db "MSDOS5.0"    ;MSDOS5.0
BPB:
BytesPerSector        dw 0x0200
SectorsPerCluster     db 1
ReservedSectors       dw 62
TotalFATs             db 0x02
MaxRootEntries        dw 0x0200
TotalSectorsSmall     dw LBASIZE     ;65512    ; -> FUNCIONANDO (HCS=255/971/63-1)
MediaDescriptor       db 0xF8    ; 0xF8
SectorsPerFAT         dw 246     ; 246   
SectorsPerTrack       dw 63      ; 63  
NumHeads              dw 255     ; 255
HiddenSectors         dd 0x00000005  ;2
TotalSectorsLarge     dd 0x00000000
DriveNumber           db 0x80    
Flags                 db 0x00
Signature             db 0x29
BUFFER_VOLUME_ID      dd 0x6EB150E3
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

BAD_CLUSTER      EQU 0xFFF7
END_OF_CLUSTER   EQU 0xFFF8
FCLUSTER_ENTRY   EQU 0x001A
FSIZE_ENTRY      EQU 0x001C
ROOT_SEGMENT     EQU 0x07C0
FAT_SEGMENT      EQU 0x17C0
KERNEL_SEGMENT   EQU 0x0800
DIRECTORY_SIZE   EQU 32
EXT_LENGTH       EQU 3
NAME_LENGTH      EQU 8
  
Extension       db "BIN"
ClusterFile     dw  0x0000
FileFound       db 0
Vetor   db "0123456789ABCDEF"

Boot_Begin:
    cli
    mov  ax, ROOT_SEGMENT
    mov  ds, ax
    mov  es, ax
    mov  ax, 0x0000
    mov  ss, ax
    mov  sp, 0x6000
    sti
	
	mov byte [DriveNumber], byte dl 
    mov ax, 02h
    int 010h
	
	call LoadRootDirectory
	call LoadFAT
	call SearchFile
	mov dl, byte [DriveNumber]
	;jmp $
	JMP 0800h:0000H
	
	
LoadRootDirectory:
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
	push ax
    add  ax, cx                   
    mov  WORD [DATASTART], ax     ; Setor 591
	

    pop ax                        ; setor inicial para ler
    mov  bx, 0x0200
    call  ReadLogicalSectors
ret

LoadFAT:
	mov ax, FAT_SEGMENT
    mov es, ax 
	
	mov ax, WORD [FATSTART]  ; Setor Lógico inicial para ler
	mov  cx, (246/2)         ; WORD [SectorsPerFAT]  ;  Metade da fat.
    mov  bx, 0x0200                           ;  Determinando o offset da FAT.
    call  ReadLogicalSectors
ret	
	
SearchFile:
	mov ax, ROOT_SEGMENT
	mov es, ax
    mov  cx, WORD [MaxRootEntries]    ; Instrução LOOP decrementa CX até 0
    mov  di, 0x0200                   ; Determinando o offset do root carregado
	add di, NAME_LENGTH
	xor bx, bx
_Loop:
    push  cx
    mov  cx, EXT_LENGTH       ; 0x000B Eleven character name.
    mov  si, Extension    ; NameFile Image name to find.
    push  di
	call VerifyExt
	pop  di
    call  LoadFile          
    pop  cx
    add  di, DIRECTORY_SIZE   ; Queue next directory entry (32).
    loop _Loop
	cmp byte[FileFound], 0
	je BOOT_FAILED
ret

VerifyExt:
	Verify:
		mov al, [es:di]
		cmp al, [ds:si]
		jne RetVerify
		inc si
		inc di
		loop Verify
RetVerify:
ret
		
	
	
LoadFile:
	push bx
	push di
	push bx
	cmp cl, 0
	jne RetLoadFile
	
	
	mov byte[FileFound], 1
	
	sub di, NAME_LENGTH
	mov dx, WORD [es:di + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov WORD [ClusterFile], dx
	
    mov ax, KERNEL_SEGMENT
    mov es, ax
	
    mov ax, FAT_SEGMENT
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
	;call Print_Hexa_Value16
	;mov ah, 00h
	;int 16h
	
    cmp  dx, END_OF_CLUSTER    ; Ou 0xFFFF
    jne  ReadDataFile
	
	pop bx
	pop di
	pop bx
	
	mov ax, 0x07C0
	mov es, ax
	
	mov edx, DWORD[es:di + (FSIZE_ENTRY - NAME_LENGTH)]
	add bx, dx
	add bx, 2
	;call Print_Hexa_Value16
	;mov ah, 00h
	;int 16h
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
	jmp BOOT_FAILED
	
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
	
	

BOOT_FAILED:
    int  0x18


TIMES 510-($-$$) DB 0

db 0x55, 0xAA