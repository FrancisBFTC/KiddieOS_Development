[BITS 16]
[ORG 0x0600]

; ---------------------------------------------
; CONFIGURAÇÕES DE DISCO
CYLINDERS 	      EQU   985
HEADS             EQU   255
SECTORS			  EQU   63
TOTALSECTORS      EQU   15826944

; ---------------------------------------------

; ---------------------------------------------
; ENDEREÇOS DO BOOT LIBRARY
BOOT_LIBRARY 		EQU 0x800
BOOT.Read_Sectors	EQU BOOT_LIBRARY
BOOT.Print_String 	EQU BOOT_LIBRARY+3
BOOT.Write_Info 	EQU BOOT_LIBRARY+6
BOOT.Move_Cursor	EQU BOOT_LIBRARY+9
BOOT.ASCII_Convert  EQU BOOT_LIBRARY+12
BOOT.Print_Dec_Value32 	EQU BOOT_LIBRARY+15
BOOT.Print_Char 		EQU BOOT_LIBRARY+18
BOOT.Show_Bytes_Info	EQU BOOT_LIBRARY+21
BOOT.Show_Label			EQU BOOT_LIBRARY+24
BOOT.Check_Signature	EQU BOOT_LIBRARY+27
BOOT.Check_Error_Partition  EQU BOOT_LIBRARY+30

; ---------------------------------------------

jmp BootStrap

BUFFER_NAME           db "MSDOS5.0"    ;MSDOS5.0
BPB:
BytesPerSector        dw 0x0200
SectorsPerCluster     db 1   ;8
ReservedSectors       dw 7    ;7
TotalFATs             db 0x02
MaxRootEntries        dw 0200h
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

DATASTART      	dw  0x0000     	; 0x3E
FATSTART       	dw  0x0000	  	; 0x40
ROOTDIRSTART   	dd  0x00000000 	; 0x42
ROOTDIRSIZE    	dd  0x00000000 	; 0x46
PARTITION		dd 	0x00000000	; 0x4A                    ; Our Partition Table Entry Offset
	
BootStrap:
	cli                 ; Desabilitamos as interrupções
	xor 	ax, ax          ; ax = 0
	mov 	ds, ax          ; define segmento de dados para 0
	mov 	es, ax          ; define segmento extra para 0
	mov 	ss, ax          ; define segmento de pilha para 0
	mov 	sp, ax          ; define ponteiro de pilha para 0
	.CopyLower:
		mov 	cx, 0x0100  ; 256 WORDS na MBR
		mov 	si, 0x7C00  ; Endereço da MBR Atual
		mov 	di, 0x0600  ; Novo endereço da MBR
		rep 	movsw       ; Cópia da MBR
		jmp 	0:LowStart
		
LowStart:
	sti                          ; Habilita as interrupções
	mov 	[DriveNumber], dl    ; Salvar o Drive de Boot
	
	mov 	ah, 02h
	mov 	al, 2
	mov 	ch, 0
	mov 	cl, 2
	mov 	dl, 80h
	mov 	dh, 0
	mov 	bx, BOOT_LIBRARY
	int 	13h
	
DUAL_BOOT_INTERFACE:
		mov 	ah, 01h
		mov 	ch, 20h
		mov 	cl, 07h
		int 	10h
		mov 	ax, 0600h
		mov     bh, 0001_1111b     ; Blue_White 
		mov     cx, 0x0616         ; CH = 8, CL = 24     
		mov     dx, 0x133A         ; DH = 16, DL = 56
		int 	10h
		mov     bh, 0111_0001b     ; White_Blue
		mov     cx, 0x0717         ; CH = 9, CL = 25     
		mov     dx, 0x1239         ; DH = 15, DL = 55
		int 	10h
		call 	BOOT.Show_Label
		mov 	byte[counter], 0
		mov 	cx, 0x0818
		call	Focus_Select
	Write_Options:
		mov 	dx, 0x0818
		call	CheckPartitions
	Select_Options:
		mov 	ah, 00h
		int 	16h
		cmp 	ah, 0x50
		je 		IncSelection
		cmp 	ah, 0x48
		je 		DecSelection
		cmp 	al, 0x0D
		je 		RunSelection
		jmp 	Select_Options
	IncSelection:
		mov 	cl, [parts]
		dec 	cl
		cmp		[counter], cl
		jz		Select_Options
		inc 	byte[counter]
		call 	Erase_Select
		inc 	ch
		call	Focus_Select
		jmp 	Write_Options
	DecSelection:
		cmp		byte[counter], 0
		jz		Select_Options
		dec 	byte[counter]
		call 	Erase_Select
		dec 	ch
		call	Focus_Select
		jmp 	Write_Options
	Erase_Select:
		mov  	cx, [select]
		mov 	dx, cx
		mov     bh, 0111_0001b     ; Black_White
		call 	Select_Event
	ret
	Focus_Select:
		mov 	dx, cx
		mov 	[select], cx
		mov     bh, 0001_1111b     ; Red_White
		call 	Select_Event
	ret	
	Select_Event:
		add		dl, 28
		mov 	ax, 0600h
		int 	10h
		sub 	dl, 28
	ret
	
	RunSelection:
		xor 	bx, bx
		mov 	bl, [counter]
		shl 	bx, 4
		add 	bx, 8
		add 	bx, PART1
	
		.ReadVBR:
			mov 	eax, DWORD[bx]           ; Movemos o endereço da LBA inicial
			mov 	[PARTITION], eax
			mov 	bx, 0x7C00               ; Vamos carregar a VBR para 0x07C0:0x0000
			mov 	cx, 1                    ; Apenas 1 setor para ler
			mov 	dl, [DriveNumber]
			call 	BOOT.Read_Sectors             ; Le este setor
				
		.JumpToVBR:
			call 	BOOT.Check_Signature
			mov 	dl, byte[DriveNumber]    ; Defina DL para o número de Drive
			sub 	DWORD[PARTITION], 3
			mov 	ebx, [PARTITION]     ; Define DS:SI Para a partição ativa
			jmp 	0x7C00                   ; Salte para a VBR no endereço 07C0:0000



	str_part 	db "Partition",0
	
	parts 		db 0
	counter 	db 0
	select 		dw 0

CheckPartitions:
	mov 	bx, PART1            ; base = Partição 1
	mov 	cx, 4                ; Há 4 entradas de partições
	mov 	byte[parts], 0
	CKPTLoop:
		mov 	al, [bx]     ; Pegar o indicador de boot
		mov 	di, bx
		add 	bx, 0x10         ; Desloca 16 bytes
		test 	al, 0x80        ; Verifica o bit ativo (10000000)
		jnz 	CKPTFound       ; Nós encontramos a partição ativa
		loop 	CKPTLoop
		mov 	al, [parts]
		call 	BOOT.Check_Error_Partition
		ret
	CKPTFound:
		call 	BOOT.Move_Cursor
		inc 	byte[parts]
		mov 	si, str_part
		call 	BOOT.Print_String
		mov 	al, [parts]
		call 	BOOT.ASCII_Convert
		call 	BOOT.Show_Bytes_Info
		loop 	CKPTLoop
ret

; Deslocamento para o offset da tabela de partição
TIMES 0x1BE-($-$$) DB 0  

; PARTITION TABLE

OFFSETL    	EQU  3             ; 1536 bytes de deslocamento
GBYTES 		EQU 5			   ; 5GB 1st partition

LBA 	EQU ((GBYTES * (1024 * 1024 * 1024)) / 512)
C 		EQU ((LBA / SECTORS / HEADS) - 1)
H 		EQU (((LBA / SECTORS) % HEADS) - 1)
S 		EQU (LBA % SECTORS)
CY 		EQU (C & 0xFF)
SE 		EQU (S | ((C & 0x300) >> 2))+3

LBA2 	EQU TOTALSECTORS - LBA
C1 		EQU ((TOTALSECTORS / SECTORS / HEADS) - 1)
H1 		EQU (((TOTALSECTORS / SECTORS) % HEADS) - 1)
S1 		EQU (TOTALSECTORS % SECTORS)
CY1 	EQU (C1 & 0xFF)
SE1 	EQU (S1 | ((C1 & 0x300) >> 2))


PART1:

	.FLAG: 		  db 0x80               	; Inicializável
	.CHS_BEGIN:   db 0x00, OFFSETL, 0x00   	; H, S, C -> CHS = 0,0,3
 	.PART_TYPE    db 0x06               	; Tipo FAT
	.CHS_FINAL    db H, SE, CY   			; H, S, C -> CHS = 651,179,43
	.LBA_BEGIN    dd OFFSETL            	; Deslocamento
   	.PART_SIZE    dd LBA          			; Tamanho de setores LBA
	
;PART2:

;	.FLAG: 		  db 0x00               ; Não-Inicializável
;	.CHS_BEGIN:   db H, SE+1, CY   		; H, S, C -> CHS = 651,179,44
 ;	.PART_TYPE    db 0x0F               ; Tipo FAT
;	.CHS_FINAL    db H1, SE1, CY1   	; H, S, C -> CHS = 984, 45, 21  
;	.LBA_BEGIN    dd LBA + OFFSETL  	; Deslocamento
;  	.PART_SIZE    dd LBA2            	; Tamanho de setores LBA


; A Ordem armazenada na RAM é: HSC (Head, Sector, Cylinder)
; No entanto, a forma de ler/compreender é CHS (Cylinder, Head, Sector).
; Cilindros e Cabeçotes começam em 0, apenas no Cilindro 0 e Cabeçote 0 
; o setor começaria em 0, mas para os cilindros e cabeçotes adiantes, o setor começa em 1.
; Existem até 1024 cilindros (de 0 a 1023), Para cada cilindro existem até 255 cabeçotes (de 0 a 254).
; Para cada cabeçote existem 63 setores (Exceto o cabeçote e cilindro 0 que tem 64 setores).

; Se o cilindro começa em 0 e cabeçote 0, estamos falando da trilha 0. Se o cilindro está em 0 e cabeçote em 1
; Se trata da trilha 1... até o cabeçote 254 do mesmo cilindro, teremos a trilha 254. No entanto,
; C=0, H=255 não é utilizada para dados, apenas "bits de paridade" em formatações RAID, portanto, a trilha 255
; vai "saltar" o H=255 indo para C=1 e H=0, reiniciando o ciclo de contagem.

;PART1:

;	.FLAG: 		  db 0x80               ; Inicializável
;	.CHS_BEGIN:   db 0x00, 0x03, 0x00   ; H, S, C -> CHS = 0,0,3
 ;	.PART_TYPE    db 0x06               ; Tipo FAT
;	.CHS_FINAL    db 0xB3, 0xAB, 0x8B   ; H, S, C -> CHS = 651,179,43
;	.LBA_BEGIN    dd 3            		; Deslocamento
 ; 	.PART_SIZE    dd 10485760           ; Tamanho de setores LBA
	
;PART2:

;	.FLAG: 		  db 0x80               ; Inicializável
;	.CHS_BEGIN:   db 0xB3, 0xAC, 0x8B   ; H, S, C -> CHS = 651,179,44
;	.PART_TYPE    db 0x06               ; Tipo FAT
;	.CHS_FINAL    db 0x2D, 0xD5, 0xD8   ; H, S, C -> CHS = 984, 45, 21  
;	.LBA_BEGIN    dd 10485763  			; Deslocamento
 ;  .PART_SIZE    dd 5341184            ; Tamanho de setores LBA
 

    PT2  DD  00000000h, 00000000h, 00000000h, 00000000h
    PT3  DD  00000000h, 00000000h, 00000000h, 00000000h
    PT4  DD  00000000h, 00000000h, 00000000h, 00000000h
 
MBR_SIGNATURE: 

    TIMES 510-($-$$) DB 0
    DW 0xAA55
