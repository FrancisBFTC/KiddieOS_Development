[BITS 16]
[ORG 0x0600]

TOTALSECTORS      EQU   0x00EE2000
TRACK_PER_HEAD    EQU   971
HEADS             EQU   255
SECTORS_PER_TRACK EQU   63

jmp BootStrap

BUFFER_NAME           db "MSDOS5.0"    ;MSDOS5.0
BPB:
BytesPerSector        dw 0x0200
SectorsPerCluster     db 1   ;8
ReservedSectors       dw 7    ;7   ;6
TotalFATs             db 0x02
MaxRootEntries        dw 0x0200
TotalSectorsSmall     dw 0x0000
MediaDescriptor       db 0xF8
SectorsPerFAT         dw 246     ; 246   
SectorsPerTrack       dw 63      ; 17  
NumHeads              dw 255     ; 4
HiddenSectors         dd 0x00000000   ;0   ;1
TotalSectorsLarge     dd TOTALSECTORS
DriveNumber           db 0x00    
Flags                 db 0x00
Signature             db 0x28  ; <- FUNCIONANDO! (Funciona na máquina real e virtual, 0x29 só na virtual)
BUFFER_VOLUME_ID      dd 0x80808080 ; <- Vou deixar este ID mesmo
VolumeLabel           db "KIDDIEOS   "
SystemID              db "FAT16   "  

	
DAPSizeOfPacket db 10h
DAPReserved     db 00h
DAPTransfer     dw 0001h
DAPBuffer       dd 0
DAPStart        dq 0

DATASTART      dw  0x0000     ; 0x4E
FATSTART       dw  0x0000	  ; 0x50
ROOTDIRSTART   dd  0x00000000 ; 0x52
ROOTDIRSIZE    dd  0x00000000 ; 0x56
 
PartOffset 		dw 0x0000                    ; Our Partition Table Entry Offset
	
BootStrap:
	cli                 ; Desabilitamos as interrupções
	xor ax, ax          ; ax = 0
	mov ds, ax          ; define segmento de dados para 0
	mov es, ax          ; define segmento extra para 0
	mov ss, ax          ; define segmento de pilha para 0
	mov sp, ax          ; define ponteiro de pilha para 0
	.CopyLower:
		mov cx, 0x0100  ; 256 WORDS na MBR
		mov si, 0x7C00  ; Endereço da MBR Atual
		mov di, 0x0600  ; Novo endereço da MBR
		rep movsw       ; Cópia da MBR
		jmp 0:LowStart
		
LowStart:
	sti                          ; Habilita as interrupções
	mov byte[DriveNumber], dl    ; Salvar o Drive de Boot
	.CheckPartitions:
		mov bx, PART1            ; base = Partição 1
		mov cx, 4                ; Há 4 entradas de partições
		.CKPTLoop:
			mov al, byte[bx]     ; Pegar o indicador de boot
			test al, 0x80        ; Verifica o bit ativo (10000000)
			jnz .CKPTFound       ; Nós encontramos a partição ativa
			add bx, 0x10         ; Desloca 16 bytes
			loop .CKPTLoop
			mov si, PartNoFound
            jmp ERROR
		.CKPTFound:
			mov word[PartOffset], bx     ; Salve o offset da partição ativa
			add bx, 8                    ; desloque 8 bytes para a LBA Inicial
		.ReadVBR:
			mov EAX, DWORD[bx]           ; Movemos o endereço da LBA inicial
			mov bx, 0x7C00               ; Vamos carregar a VBR para 0x07C0:0x0000
			mov cx, 1                    ; Apenas 1 setor para ler
			mov dl, [DriveNumber]
			call ReadSectors             ; Le este setor
			
			
		.JumpToVBR:
			mov si, MissSig
			cmp word[0x7DFE], 0xAA55     ; Verifica se existe assinatura de boot
			jne ERROR                    ; Se não existir, falha de boot
			mov si, word[PartOffset]     ; Define DS:SI Para a partição ativa
			mov dl, byte[DriveNumber]    ; Defina DL para o número de Drive
			jmp 0x7C00                   ; Salte para a VBR no endereço 07C0:0000
			
			
	ReadSectors:
		mov word[DAPBuffer], bx
		mov word[DAPBuffer+2], es        ; ES:BX - Para onde os dados vão
		mov word[DAPStart], ax           ; Setor lógico inicial
	_MAIN:
		mov di, 0x0005                   ; 5 tentativas de leitura
	_SECTORLOOP:
		push ax
		push bx
		push cx
		
		mov si, ErrorEDDs
		mov bx,0x55aa
		mov ah,0x41
		int 0x13
		jc ERROR
		cmp bx,0xaa55
		jne ERROR
		
		mov ah, 0x42
		mov si, DAPSizeOfPacket
		int 0x13
		jnc _SUCCESS           ; Testa por erro de leitura
		xor ax, ax             ; BIOS Reset Disk
		int 0x13
		dec di
		
		pop cx
		pop bx
		pop ax
		
		jnz _SECTORLOOP
		mov si,ErrorSector
		jmp ERROR
		
    _SUCCESS:
		pop cx
		pop bx
		pop ax
		
		; Desloca para próximo Buffer
		add bx, word[BytesPerSector]
		cmp bx, 0x0000
		jne _NEXTSECTOR
		
		push ax
		mov ax, es
		add ax, 0x1000
		mov es, ax
		pop ax
		
	_NEXTSECTOR:
		inc ax
		mov word[DAPBuffer], bx
		mov word[DAPStart], ax
		loop _MAIN
ret

ERROR:
	call Print_Error
	int 0x18


Print_Error:
	pusha
.next:
	cld 			    ; flag de direcção
	lodsb			    ; a cada loop carrega si p --> al, actualizando si
	cmp 	al, 0		; compara al com o 0
	je 		.end		; se al for 0 pula para o final do programa	
	mov		ah, 0x0e	; função TTY da BIOS imprime caracter na tela
	int 	0x10		; interrupção de vídeo
	jmp 	.next
.end:
	popa
ret

PartNoFound   db "Error: No Active Partition!",0xd,0xa,0
MissSig       db "Error: VBR Missing Boot Signature!",0xd,0xa,0
ErrorSector   db "Error: Read Sector!",0xd,0xa,0
ErrorEDDs     db "Error: BIOS EDDs not supported",0xd,0xa,0

; Deslocamento para o offset da tabela de partição
TIMES 0x1BE-($-$$) DB 0  

; PARTITION TABLE

OFFSETL    EQU  3             ; 1536 bytes de deslocamento
LBASIZE    EQU (TOTALSECTORS - (OFFSETL + 1))  ; 0xEE1FFC Tamanho lógico da partição

PART1:

	FLAG: 		 db 0x80               ; Inicializável
	HCS_BEGIN:   db 0x00, 0x00, 0x03   ;(0, 0, 3)
 	PART_TYPE    db 0x0B               ; Tipo FAT
	HCS_FINAL    db 0xFE, 0xCA, 0xFF   ; (254, 970, 63)
	LBA_BEGIN    dd OFFSETL            ; Deslocamento
   	PART_SIZE    dd LBASIZE            ; Tamanho de setores LBA
 

    PT2  DD  00000000h, 00000000h, 00000000h, 00000000h
    PT3  DD  00000000h, 00000000h, 00000000h, 00000000h
    PT4  DD  00000000h, 00000000h, 00000000h, 00000000h
 
MBR_SIGNATURE: 

    TIMES 510-($-$$) DB 0
    DW 0xAA55