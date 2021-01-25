[ORG 0x0600]

%DEFINE DIRECTORY_SIZE  32
%DEFINE TRACK_PER_HEAD  971

jmp BootStrap

BUFFER_NAME           db "MSDOS5.0"    ;MSDOS5.0
BPB:
BytesPerSector        dw 0x0200
SectorsPerCluster     db 1
ReservedSectors       dw 67  ;64
TotalFATs             db 0x02
MaxRootEntries        dw 0x0200
TotalSectorsSmall     dw LBASIZE    ; -> FUNCIONANDO (HCS=255/971/63-1)
MediaDescriptor       db 0xF8    ; 0xF8
SectorsPerFAT         dw 246     ; 246   
SectorsPerTrack       dw 63      ; 17  
NumHeads              dw 255     ; 4
HiddenSectors         dd 0x00000000
TotalSectorsLarge     dd 0x00000000
DriveNumber           db 0x80    
Flags                 db 0x00
Signature             db 0x29
BUFFER_VOLUME_ID      dd 0x6EB150E3  ;0x980E63F5
VolumeLabel           db "KIDDIEOS   "
SystemID              db "FAT16   "  


DAPSizeOfPacket db 10h
DAPReserved     db 00h
DAPTransfer     dw 0001h
DAPBuffer       dd 00000000h
DAPStart        dq 0000000000000000h

PartOffset 		dw 0x0000                    ; Our Partition Table Entry Offset

BootStrap:
  cli                         ; We do not want to be interrupted
  xor ax, ax                  ; 0 AX
  mov ds, ax                  ; Set Data Segment to 0
  mov es, ax                  ; Set Extra Segment to 0
  mov ss, ax                  ; Set Stack Segment to 0
  mov sp, ax                  ; Set Stack Pointer to 0
  .CopyLower:
    mov cx, 0x0100            ; 256 WORDs in MBR
    mov si, 0x7C00            ; Current MBR Address
    mov di, 0x0600            ; New MBR Address
    rep movsw                 ; Copy MBR
  jmp 0:LowStart              ; Jump to new Address
 
LowStart:
  sti                         ; Start interrupts
  mov BYTE [DriveNumber], dl    ; Save BootDrive
  .CheckPartitions:           ; Check Partition Table For Bootable Partition
    mov bx, PART1               ; Base = Partition Table Entry 1
    mov cx, 4                 ; There are 4 Partition Table Entries
    .CKPTloop:
      mov al, BYTE [bx]       ; Get Boot indicator bit flag
      test al, 0x80           ; Check For Active Bit
      jnz .CKPTFound          ; We Found an Active Partition
      add bx, 0x10            ; Partition Table Entry is 16 Bytes
	  loop .CKPTloop
    jmp ERROR                 ; ERROR!
    .CKPTFound:
      mov WORD [PartOffset], bx    ; Save Offset
      add bx, 8               ; Increment Base to LBA Address
  .ReadVBR:
    mov EAX,  DWORD [bx]       ; Start LBA of Active Partition
    mov bx, 0x7C00            ; We Are Loading VBR to 0x07C0:0x0000
    mov cx, 1                 ; Only one sector
    call ReadSectors          ; Read Sector
	
 
  .jumpToVBR:
    cmp WORD [0x7DFE], 0xAA55 ; Check Boot Signature
    jne ERROR                 ; Error if not Boot Signature
    mov si, WORD [PartOffset]      ; Set DS:SI to Partition Table Entry
    mov dl, BYTE [DriveNumber]  ; Set DL to Drive Number
    jmp 0x7C00                ; Jump To VBR
	
	
ReadSectors:
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
	jmp ERROR   ; -> O erro é dado bem aqui quando roda diretamente no VirtualBox
	
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


 
ERROR:
  int  0x18
  

; Deslocamento para o offset da tabela de partição
TIMES 0x1BE-($-$$) DB 0 

; PARTITION TABLE

LBASIZE   EQU  61173  ; ((Cylinder x Sector))
OFFSETL   EQU  63      ; Offset of the active partition

PART1:

 FLAG:        db  0x80     
 HCS_BEGIN:   db  0x00, 0x00, 0x00  ; (0, 0, 0)
 PART_TYPE:   db  0xEF           
 HCS_FINAL:   db  0x00, 0xCB, 0xFF  ; (0, 971, 63)
 LBA_BEGIN:   dd  OFFSETL ;0
 PART_SIZE:   dd  LBASIZE-OFFSETL
 
	PT2  dd 0000CBFFh, 0xEF01CBFF, (LBASIZE+OFFSETL), (LBASIZE-OFFSETL) ; Second Partition Entry
	PT3  dd 0001CBFFh, 0xEF02CBFF, (LBASIZE * 2),  LBASIZE 	            ; Third Partition Entry;
	PT4  dd 0002CBFFh, 0xEF03CBFF, (LBASIZE * 3),  LBASIZE              ; Fourth Partition Entry
 

MBR_SIGNATURE: 

    TIMES 510-($-$$) DB 0
    DW 0xAA55