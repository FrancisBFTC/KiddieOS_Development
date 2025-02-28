%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG FAT16]

jmp 	LoadAllExtensionFiles  	; FAT16+0
jmp 	LoadDirectory		 	; FAT16+3
jmp 	LoadFAT					; FAT16+6
jmp 	LoadThisFile			; FAT16+9
jmp 	WriteThisFile 			; FAT16+12
jmp 	LoadStartData			; FAT16+15
jmp 	WriteThisEntry			; FAT16+18
jmp 	DeleteThisFile 			; FAT16+21
jmp 	OpenThisFile 			; FAT16+24
jmp 	LoadFile 				; FAT16+27
jmp 	SetSeekFile				; FAT16+30
jmp 	CloseFile 				; FAT16+33
jmp 	ReadLogicalSectors		; FAT16+36

FileSegments    dw 0x0000		; FAT16+39
DirSegments     dw 0x0000		; FAT16+41
LoadingDir      db 0			; FAT16+43
	
SYS.VM db 0						; FAT16+44
FileVM  times 11 db 0			; FAT16+45
ClusterFile     dw  0x0000		; FAT16+56

kernel_call 	db 0
file_pointer 	dd 0

DAPSizeOfPacket db 10h
DAPReserved     db 00h
DAPTransfer     dw 0001h
DAPBuffer       dd 00000000h
DAPStart        dq 0000000000000000h

SHELL.ErrorDir   EQU  (SHELL16+25)
SHELL.ErrorFile  EQU  (SHELL16+26)

DATASTART            DW   0x0000
FATSTART             DW   0x0000 
ROOTDIRSTART         DW   0x0000
PARTITION 			 DD   0x00000000

BYTES_PER_SECTOR     EQU  512
MAX_ROOT_ENTRIES     EQU  512
SECTORS_PER_CLUSTER  EQU  1
SECTORS_PER_FAT		 EQU  246


BAD_CLUSTER      EQU 0xFFF7
END_OF_CLUSTER1  EQU 0xFFF8
END_OF_CLUSTER2  EQU 0xFFFF
FCLUSTER_ENTRY   EQU 0x001A
FSIZE_ENTRY      EQU 0x001C
FPERM_ENTRY 	 EQU 0x000C
FPERM_ENTRY2 	 EQU 0x0014
ROOT_SEGMENT     EQU 0x0200	  ; era 0x07C0
FAT_SEGMENT      EQU 0x1000   ; era 0x17C0
KERNEL_SEGMENT   EQU 0x3000   ; era 0x0C00
FILE_SEGMENT     EQU 0x6800   ; 

; CAMPOS DA ENTRADA PARA ARQUIVOS ABERTOS
; FILE_NAME    -> "AAAAAAAABBB" A = name, B = extension 	 (0x00)
; ATTRIB       -> 0x00			(0x0B)
; ACCESS_MODE  -> 00yy0xxxb  y = share mode, x = access mode (0x0C)
; OPS_FLAGS    -> 00000000b		(0x0D)
; SAVE_LOADED  -> 0x0000		(0x0E)
; POINTER_FILE -> 0x00000000	(0x10)
; PERMISSIONS  -> 0x0000		(0x14)
; ID_FILE 	   -> 0x0000		(0x16)
; CLUSTER_INI  -> 0x0000		(0x18)
; CLUSTER_CHG  -> 0x0000		(0x1A)
; SIZE_BYTES   -> 0x00000000	(0x1C)

ACCESS_MODE		 EQU 0x000C
OPS_FLAG 		 EQU 0x000D
SAVE_LOADED  	 EQU 0x000E
POINTER_FILE 	 EQU 0x0010
CLUSTER_INI 	 EQU 0x0018
CLUSTER_CHG 	 EQU 0x001A
ID_FILE 		 EQU 0x0016
SIZE_BYTES 		 EQU 0x001C

DIRECTORY_SIZE   EQU 32
EXT_LENGTH       EQU 3
NAME_LENGTH      EQU 8
  
;Extension       db "SYS"
FileFound       db 0
StringID 		db "FAT16: ",0
StringDvr  		db " driver loaded at address 0x",0
LoadDriver db 0

LoadDirectory:
	pusha
	xor eax, eax
	mov ax, ROOT_SEGMENT
	mov es, ax
	mov ax, [ROOTDIRSTART]
	mov bx, 0x0000
	mov cx, 2		;DIRECTORY_SIZE = 32
	add eax, [PARTITION]
	call ReadLogicalSectors
	popa
	mov bx, 16*2
ret
	
LoadFAT:
	pusha
	mov ax, FAT_SEGMENT
    mov es, ax
	mov ax, ROOT_SEGMENT
	mov fs, ax
	mov ax, [FATSTART]  	 		; Setor Lógico inicial para ler
	mov  cx, SECTORS_PER_FAT 		;  Metade da fat (246 / 2).
    mov  bx, 0x0000                 ;  Determinando o offset da FAT.
	add eax, [PARTITION]
    call  ReadLogicalSectors
	mov ax, ROOT_SEGMENT
	mov es, ax
	popa
ret

LoadStartData:
	pusha
	push 	es
	xor 	ax, ax
	mov 	es, ax
	mov 	ax, WORD[es:0x600 + 0x3E]
	mov 	[DATASTART], ax
	mov 	ax, WORD[es:0x600 + 0x40]
	mov 	[FATSTART], ax
	mov 	ax, WORD[es:0x600 + 0x42]
	mov 	[ROOTDIRSTART], ax
	mov 	eax, DWORD[es:0x600 + 0x4A]
	mov 	[PARTITION], eax
	xor 	eax, eax
	pop 	es
	popa
ret

LoadAllExtensionFiles:
	mov 	ax, ROOT_SEGMENT
	mov 	es, ax
    mov  	cx, MAX_ROOT_ENTRIES    ; Instrução LOOP decrementa 512 até 0
    mov  	di, 0x0000              ; Determinando o offset do root carregado
	add 	di, NAME_LENGTH
	mov 	byte[kernel_call], 1
_Loop:
    push  	cx
    mov  	cx, EXT_LENGTH       ; 0x000B Eleven character name.
    push  	si
    push  	di
	repe 	cmpsb
	pop  	di
	pop  	si
	jne 	NoFounded
    call  	LoadBinaryFile
NoFounded:	
    pop  	cx
    add  	di, DIRECTORY_SIZE   ; Queue next directory entry (32).
    loop 	_Loop
	cmp 	byte[FileFound], 0
	je 		BOOT_FAILED
	mov 	byte[FileFound], 0
	mov 	byte[kernel_call], 0
ret


LoadThisFile:
	push 	es
	clc
	mov 	byte[kernel_call], 1
	mov 	es, ax
    mov  	cx, MAX_ROOT_ENTRIES    ; Instrução LOOP decrementa CX até 0
    mov  	di, 0x0000              ; Determinando o offset do root carregado
FLoop:
    push  	cx
    mov  	cx, 0x000B       	;  Eleven character name.
    push  	si
    push  	di
	repe 	cmpsb
	pop  	di
	pop  	si
	jne 	NoFoundedThis
    call  	LoadFile
NoFoundedThis:
    pop  	cx
    add  	di, DIRECTORY_SIZE   ; Queue next directory entry (32).
	cmp 	byte[FileFound], 1
	je 		RetLoadThis
	xor 	ax, ax
    loop 	FLoop
	mov 	byte[kernel_call], 0
	mov 	al, byte[LoadingDir]
	inc 	al
	pop 	es
	mov 	byte[FileFound], 0
	xor 	dx, dx
	stc
	ret
ProcessErrorCode:
	mov 	byte[kernel_call], 0
	pop 	es
	stc
	ret
RetLoadThis:
	mov 	byte[FileFound], 0
	cmp 	byte[SHELL.ErrorDir], 1
	je 		ProcessErrorCode
	cmp 	byte[SHELL.ErrorFile], 1
	je 		ProcessErrorCode
	mov 	byte[kernel_call], 0
	clc
	pop 	es
	ret
	
; AX = Segmento de Diretório Atual
; DL = Flag do Tipo de Abertura
;	MODO DE ACESSO:
;		BIT<2-0> = 000 = pra leitura
;		BIT<2-0> = 001 = pra escrita
;		BIT<2-0> = 010 = pra escrita/leitura
; 	MODO DE COMPARTILHAMENTO:
;		BIT<5-4> = 00  = Não negar
;		BIT<5-4> = 01  = Negar tudo
;		BIT<5-4> = 10  = Negar escrita
;		BIT<5-4> = 11  = Negar leitura
; DH = Tipo de usuário
;	0 = convidado/outros; 1 = grupos de usuários;
;	2 = usuário; 3 = admin; 4 = sistema;
; SI = Nome do arquivo formatado
OpenThisFile:
	push 	es
	clc
; --------------------------------------------------------------------
; VERIFICAÇÃO DE ERROS INICIAIS DE PERMISSÃO
	mov 	cx, dx
	and 	dl, 00000111b	; Isolar bits do modo de acesso
	cmp 	dl, 2			; Compare com o último modo
	ja 		ERR.NotAllowed	; Se for maior, é um erro "Access Mode Not Allowed"
	mov 	dx, cx
	and 	dl, 01110000b 	; Isolar bits do modo de compatibilidade
	shr 	dl, 4 			; Move para o LSB
	cmp 	dl, 4			; Compare com o último modo
	ja 		ERR.NotAllowed	; Se for maior, é um erro "Access Mode Not Allowed"
	mov 	dx, cx
; --------------------------------------------------------------------
	
	mov 	es, ax 		; ES = CD_SEGMENT
	xor 	di, di		; ES:DI = CD_SEGMENT:0x0000
OpenSearch:
	push 	cx			; Empilha algum contador se houver
	mov 	cx, 11 		; 11 caracteres do nome de arquivo na entrada
	push 	si			; Empilha nome de arquivo a ser buscado
	push 	di			; Empilha nome de arquivo da entrada
	rep 	cmpsb		; Compare os 2 nomes de arquivos
	pop 	di			; Desempilha nome de arquivo da entrada
	pop 	si			; Desempilha nome de arquivo a ser buscado
	pop 	cx			; Desempilha algum contador
	jne 	NextEntry	; Caso os nomes não forem iguais, procure a próxima entrada

; Rotina que cria a estrutura de referência do arquivo 	
	; Verificar se é permissão do sistema,usuário ou admin
; -----------------------------------------------------------------
	mov 	ax, word[es:di + FPERM_ENTRY2]
	and 	ax, 0x003F
	
	cmp 	ch, 0
	je 		CheckOthers
	cmp 	ch, 1
	je 		CheckGroups
	cmp 	ch, 2
	je 		CheckUsers
	cmp 	ch, 3
	je	 	CheckAdmin
	cmp 	ch, 4
	je 		FindOpened
	jmp 	ERR.Denied
	
CheckOthers:
	mov 	ax, word[es:di + FPERM_ENTRY2]
	and 	ax, 0xF800
	shr 	ax, 11
	jmp 	CheckUsers
CheckGroups:
	mov 	ax, word[es:di + FPERM_ENTRY2]
	and 	ax, 0x07C0
	shr 	ax, 6
	
CheckUsers:
	mov 	dl, byte[es:di + FPERM_ENTRY]	; Restaura as permissões
	and 	dl, (1 << 5)					; Isola o bit 5 (admin)
	shr 	dl, 5							; Desloca pro início
	cmp 	dl, 0							; Compare com 0
	jz 		ERR.Denied						; Se for 0, contém apenas permissão de admin
CheckAdmin:
	mov 	dl, al							; Pega os bits de permissão
	mov 	bl, cl							; Coloque o modo de abertura em BL
	and 	bl, 00000011b 					; Isola os 2 últimos bits
	cmp 	bl, 0							; É pra leitura?
	je 		OpenToRead
	cmp 	bl, 1							; É pra escrita?
	je 		OpenToWrite
	cmp 	bl, 2							; É pra leitura/escrita
	je 		OpenToRW
	jmp 	ERR.NotAllowed					; Caso não for nenhum, é erro não permitido
	
OpenToRead:
	and 	dl, (1 << 1)				; Isola o bit 1 de leitura
	jmp 	CheckPermission
OpenToWrite:
	and 	dl, (1 << 0)				; Isola o bit 0 de escrita
	jmp 	CheckPermission
OpenToRW:
	and 	dl, 00000011b				; Isola o bit 0 e 1 de leitura/escrita
	cmp 	dl, 3
	jne 	ERR.Denied
	mov 	si, OpenBuffer
	jmp 	FindOpened
CheckPermission:
	cmp 	dl, 0						; Compare DL com 0
	jz 		ERR.Denied 					; Se for, não tem permissão de leitura

FindOpened:
	xor 	ax, ax
	mov 	si, OpenBuffer
	mov 	dx, word[es:di + FCLUSTER_ENTRY]
	push 	cx
	mov  	cx, (512 / 32)		; Máximo 16 entradas
IsOpenFile:
	cmp 	word[si + CLUSTER_INI], dx
	jne 	NextOpenFile
	jmp 	CheckIfSystem
NextOpenFile:
	cmp 	word[si], 0x0000
	je 		CheckIfSystem
	add 	si, 32
	inc 	ax
	loop 	IsOpenFile
	pop 	cx
	jmp 	ERR.NoHandler
	
CheckIfSystem:
	pop 	cx
	cmp 	ch, 4
	je 		CreateStruct
	
CheckShare:
	mov 	dl, byte[si + FPERM_ENTRY]		; Pega os bits de permissão/compartilhamento
	and 	dl, 11000000b 					; Isola os 2 bits MSBs (Share mode)
	cmp 	dl, 0
	jnz 	CheckShareType
	mov 	dl, cl
	and 	dl, 00110000b
	shl 	dl, 2
	or 		[es:di + FPERM_ENTRY], dl 	; Define os bits de compartilhamento
	and 	byte[es:di + FPERM_ENTRY], 11000000b
	mov 	dl, cl
	and 	dl, 0x03
	or 		[es:di + FPERM_ENTRY], dl
	jmp 	CreateStruct
	
CheckShareType:
	shr 	dl, 6
	cmp 	dl, 1
	je 		ERR.NotAble
	cmp 	dl, 2
	je 		WriteDenied
	jmp 	ReadDenied
	
WriteDenied:
	mov 	bl, cl
	and 	bl, 00000011b
	cmp 	bl, 1
	je 		ERR.Denied
	cmp 	bl, 2
	je 		ERR.Denied
	jmp 	CreateStruct

ReadDenied:
	mov 	bl, cl
	and 	bl, 00000011b
	cmp 	bl, 0
	je 		ERR.Denied
	cmp 	bl, 2
	je 		ERR.Denied
	
CreateStruct:
	push 	ds
	push 	es
	pop 	ds
	pop 	es
	push 	cx
	xchg 	di, si
	mov 	cx, 32
	rep 	movsb
	xchg 	di, si
	pop 	cx
	push 	ds
	push 	es
	pop 	ds
	pop 	es
	sub 	si, 32
	mov 	[si + ID_FILE], ax
	mov 	DWORD[si + POINTER_FILE], 0x00000000
	mov 	WORD[si + SAVE_LOADED], 0x0000
	mov 	BYTE[si + OPS_FLAG], 0x00
	mov 	ax, [si + CLUSTER_CHG]
	mov 	[si + CLUSTER_INI], ax
	mov 	ax, si
; -----------------------------------------------------------------
	
	jmp 	RetOpen 	; Retorne a rotina de abertura
NextEntry:
	add  	di, DIRECTORY_SIZE		; Desloca para próxima entrada
	cmp 	word[es:di], 0x0000		; Verifique se a entrada é zerada
	jne 	OpenSearch 				; Caso não for, continue buscando arquivo
FileNotFound:
	mov 	ax, 02h			; Código de Erro: Arquivo não encontrado
OpenErr:
	pop 	es
	stc
	ret
RetOpen:
	pop 	es
	clc
ret

ERR:
.NotAllowed:
	mov 	ax, 0Ch			; Código de Erro: Modo de acesso não permitido
	jmp 	OpenErr
.Denied:
	mov 	ax, 05h			; Código de Erro: Acesso negado
	jmp 	OpenErr
.NotAble:
	mov 	ax, 01h			; Código de Erro: Compartilhamento não habilitado
	jmp 	OpenErr
.NoHandler:
	mov 	ax, 04h			; Código de Erro: Nenhum manipulador disponível
	jmp 	OpenErr

	
; AX = Segmento de Diretório Atual
; BX = Buffer que contém os dados
; CX = Quantidade de Dados
; DX = Flag de Criação/Acréscimo
; SI = Nome do arquivo formatado
WriteThisFile:
	push 	es
	clc
	mov 	es, ax 		; ES = CD_SEGMENT
	xor 	di, di		; ES:DI = 0x0200:0x0000 = 0x2000
Search:
	push 	cx			; Empilha a quantidade de chars
	mov 	cx, 11 		; 11 caracteres do nome de arquivo na entrada
	push 	si			; Empilha nome de arquivo a ser buscado
	push 	di			; Empilha nome de arquivo da entrada
	rep 	cmpsb		; Compare os 2 nomes de arquivos
	pop 	di			; Desempilha nome de arquivo da entrada
	pop 	si			; Desempilha nome de arquivo a ser buscado
	pop 	cx			; Desempilha a quantidade de chars
	jne 	SearchNext	; Caso os nomes não forem iguais, procure a próxima entrada
	call 	WriteFile 	; Verifica se é Append ou Create (Flag de escrita)
	jmp 	RetWrite 	; Retorne a rotina de escrita
SearchNext:
	add  	di, DIRECTORY_SIZE		; Desloca para próxima entrada
	cmp 	word[es:di], 0x0000		; Verifique se a entrada é zerada
	jne 	Search 					; Caso não for, continue buscando arquivo
	call 	CreateFile 				; Nos dois casos (Append/Create), cria um arquivo
RetWrite:
	clc
	pop 	es
ret

; AX = Segmento de Diretório Atual
; DX = Deslocamento da entrada (Tipo de alteração)
; BX = Dependendo do tipo, BX conterá o valor
; SI = Nome do arquivo formatado
WriteThisEntry:
	push 	es
	clc
	mov 	es, ax 		; ES = CD_SEGMENT
	xor 	di, di		; ES:DI = 0x0200:0x0000 = 0x2000
SearchEntry:
	push 	cx			; Empilha a quantidade de entradas
	mov 	cx, 11 		; 11 caracteres do nome de arquivo na entrada
	push 	si			; Empilha nome de arquivo a ser buscado
	push 	di			; Empilha nome de arquivo da entrada
	rep 	cmpsb		; Compare os 2 nomes de arquivos
	pop 	di			; Desempilha nome de arquivo da entrada
	pop 	si			; Desempilha nome de arquivo a ser buscado
	pop 	cx			; Desempilha a quantidade de entradas
	jne 	SearchNextE	; Caso os nomes não forem iguais, procure a próxima entrada
	call 	ChangeEntry ; Altera entrada
	jmp 	RetWriteEnt ; Retorne a rotina de escrita
SearchNextE:
	add  	di, DIRECTORY_SIZE		; Desloca para próxima entrada
	;cmp 	word[es:di], 0x0000		; Verifique se a entrada é zerada
	;jne 	SearchEntry 			; Caso não for, continue buscando arquivo
	loop 	SearchEntry
	mov 	al, 1
	stc
	pop 	es
	ret
RetWriteEnt:
	clc
	pop 	es
ret


; AX = Segmento de Diretório Atual
; SI = Nome do arquivo formatado
DeleteThisFile:
	push 	es
	clc
	mov 	es, ax 		; ES = CD_SEGMENT
	xor 	di, di		; ES:DI = 0x0200:0x0000 = 0x2000
SearchToDel:
	push 	cx			; Empilha a quantidade de chars
	mov 	cx, 11 		; 11 caracteres do nome de arquivo na entrada
	push 	si			; Empilha nome de arquivo a ser buscado
	push 	di			; Empilha nome de arquivo da entrada
	rep 	cmpsb		; Compare os 2 nomes de arquivos
	pop 	di			; Desempilha nome de arquivo da entrada
	pop 	si			; Desempilha nome de arquivo a ser buscado
	pop 	cx			; Desempilha a quantidade de chars
	jne 	NextToDel	; Caso os nomes não forem iguais, procure a próxima entrada
	call 	DeleteFile  ; Altera entrada
	jmp 	RetDelFile 	; Retorne a rotina de escrita
NextToDel:
	add  	di, DIRECTORY_SIZE		; Desloca para próxima entrada
	;cmp 	word[es:di], 0x0000		; Verifique se a entrada é zerada
	;jne 	SearchToDel 			; Caso não for, continue buscando arquivo
	loop 	SearchToDel
	mov 	al, 0x01				; Error Code: Arquivo não encontrado
	stc
	pop 	es
	ret
RetDelFile:
	clc
	pop 	es
ret

DeleteFile:
	push 	ax
	
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]
	call 	ClearFATClusters		; Limpa clusters
	
	push 	bx
	mov 	ax, dx					; Recupera número de cluster livre
	shl 	ax, 1					; Multiplica por 2
	mov 	bx, 512					; Define denominador 512 pra divisão
	xor 	dx, dx					; Zera dx pra não causar conflitos
	div 	bx						; Divide (FreeCluster * 2) por 512
	add 	ax, 7					; Soma setor inicial do FAT mais resultado
	mov 	[InitialFAT], ax		; Setor inicial do FAT do novo arquivo
	
	pop 	ax						; Recupera BX em AX
	mov 	bx, 512					; Define denominador 512 pra divisão
	xor 	dx, dx					; Zera dx pra não causar conflitos
	div 	bx						; Divide (FreeCluster * 2) por 512
	add 	ax, 7					; Soma setor inicial do FAT mais resultado
	sub 	ax, [InitialFAT]		; Calcule a diferença de setores FAT
	add 	ax, 1					; Some +1 = Quantidade de Setores FAT para Escrever
	
	push 	di
	push 	es
	
	mov 	cx, [InitialFAT]		; CX é o setor de FAT inicial calculado
	sub 	cx, 7					; Subtrair pelo setor inicial padrão
	xor 	bx, bx					; Zere BX pra começar as somas de Offset
	cmp 	cx, 0					; Compare CX com 0
	jz 		ClearFatFile			; Se for igual, então Offset também será 0
	
AddOffset:							; Se for diferente, então BX tem que valer próximos offsets
	add 	bx, 512					; Adicione BX pro próximo offset (próximo setor)
	loop 	AddOffset				; Retorne CX vezes
	
ClearFatFile:
	mov 	cx, ax					; CX = Quantidade de setores FAT
	mov 	ax, FAT_SEGMENT			; Defina Segmento do FAT
	mov 	es, ax					; Para o Registrador ES = ES:BX
	mov 	ax, [InitialFAT]		; AX = Setor do FAT inicial pré-calculado
	add 	eax, [PARTITION]
	call  	WriteLogicalSectors		; Escreva CX setor(es) de ES:BX a partir do Setor AX
	
	pop 	es
	pop 	di
	
	push 	di
	mov 	cx, 32
	mov 	ax, 0
	rep 	stosb
	pop 	di
	
	pop 	ax
	
	call 	Save_Entry
ret
	
	
	
	
; ALTERAR ENTRADAS/PROPRIEDADES DO ARQUIVO
; ROTINA QUE PODE ALTERAR QUAISQUER VALORES
ChangeEntry:
	add 	di, dx
	cmp 	dx, 0
	jz 		ChangeName
	cmp 	dx, 11
	jz 		ChangeAttrib
	cmp 	dx, 12
	jz 		ChangePermission
	jmp 	Ret.ChEntry
	
ChangeName:
	mov 	si, bx
	push 	di
	mov 	cx, 11
	rep 	movsb
	pop 	di
	jmp 	Save_Entry
	
ChangeAttrib:
	mov 	byte[es:di], bl
	sub 	di, 11
	jmp 	Save_Entry
	
ChangePermission:
	push 	bx
	and 	bx, 0x003F
	mov 	byte[es:di], bl
	add 	di, 8
	pop 	bx
	mov 	word[es:di], bx
	sub 	di, 20

Save_Entry:
	mov 	es, ax		  ; ES = SEGMENTO ATUAL
	xor 	bx, bx		  ; ZERAR BX EM AMBOS OS CASOS (OFFSET 0)
	cmp 	ax, 0x0200
	jne 	Search_Entry
	
; 	ESCREVER NO DISCO A ENTRADA RAIZ
	mov 	ax, 499				; Setor inicial do diretório raíz
	xor  	cx, cx				; Zera cx
    mov  	cl, 2				; Setores Sequenciais do deslocamento de CD -> 0x40 = 0x400
	add 	eax, [PARTITION]
    call  	WriteLogicalSectors	; Escreve ES:BX (Dir. Raíz Adaptado) no setor 499 e 500
	jmp 	Ret.ChEntry			; 
	
; 	ESCREVER NO DISCO A ENTRADA DE FOLDER
Search_Entry:					; Procurar entrada com cluster da pasta atual
	sub 	di, 32				; Volta uma entrada
	cmp 	WORD[es:di], ". "	; Compare com o diretório atual
	jne 	Search_Entry		; Enquanto não for, continue procurando
	
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]	; Quando encontrado, armazene o cluster do dir. atual em dx
	
Write_Entry:
	; escrever es:bx no setor lógico ax, convertido do cluster dx
	; salvar no disco o diretório atualizado
	mov 	[ClusterFile], dx
	mov  	ax, [ClusterFile]   
    call  	ClusterLBA
	xor  	cx, cx
    mov  	cl, SECTORS_PER_CLUSTER    ; 1 Setor para escrever
	add 	eax, [PARTITION]
    call  	WriteLogicalSectors
	
	push 	bx						  ; bx = bx + 512

    mov 	ax, [ClusterFile]    	  ; Restaure o Cluster atual salvo
    add 	ax, ax                	  ; Converta para bytes (ClusterFile * 2)
    mov 	bx, 0x0000                ; Zere BX para a soma
    add 	bx, ax                    ; Índice para o FAT: Some os bytes    
    mov 	dx, WORD [gs:bx]          ; Leia o próximo Cluster do FAT
    mov  	[ClusterFile], dx    	  ; DX está com o próximo Cluster
	
	pop 	bx						  ; bx = bx + 512
	
	cmp  	dx, END_OF_CLUSTER1    ; 0xFFF8
    je  	Ret.ChEntry
	cmp  	dx, END_OF_CLUSTER2    ; 0xFFFF
	je 		Ret.ChEntry
	jmp 	Write_Entry

Ret.ChEntry:
	ret

ClearFATClusters:
	push 	dx
	
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]

	mov 	ax, FAT_SEGMENT
    mov 	gs, ax
	xor 	bx, bx
	xor 	cx, cx
	
Find_Cluster:
	add 	bx, 2
	inc 	cx
	cmp 	bx, 0
	jne 	Compare_Cluster
	mov 	ax, gs
	add 	ax, 0x1000
	mov 	gs, ax
Compare_Cluster:
	cmp 	cx, dx
	jne 	Find_Cluster
Clear_Clusters: 
    mov 	dx, WORD [gs:bx]		; Leia o próximo Cluster do FAT
	mov 	WORD [gs:bx], 0x0000	; Zere o Cluster
	cmp 	dx, END_OF_CLUSTER2
	jne 	Find_Cluster
	
	pop 	dx
ret

; AX = Segmento Diretório
; DX = Flag de escrita
; CX = Quantidade de chars
; DI = Endereço de entrada
; SI = Nome do arquivo
WriteFile:
	push 	bx		; Empilha BufferWrite
	push 	di 		; Empilha endereço da entrada
	push 	ax 		; Empilha segmento de dirs
	push 	cx		; Empilha quantidade de chars
	
; 	ZERAR CLUSTERS NAS DUAS SITUAÇÕES
	call 	ClearFATClusters
	
	pop 	cx
	pop 	ax
	pop 	di
	pop 	bx

; AX = Segmento Diretório
; CX = Quantidade de chars
; DI = Endereço de entrada
; SI = Nome do arquivo	
CreateFile:
	push 	bx		; Empilha BufferWrite
	push 	di 		; Empilha endereço da entrada
	push 	ax 		; Empilha segmento de dirs
	push 	cx		; Empilha quantidade de chars
	
; CRIANDO ENTRADA NA MEMÓRIA
; 	NOME DE ARQUIVO
	mov 	cx, 11
	rep 	movsb   ; Move 11 caracteres de SI para DI
	
; 	ATRIBUINDO TIPO (ARCHIVE)
	mov 	al, 0x20
	cmp 	byte[LoadingDir], 1
	jne 	AttribType
	mov 	al, 0x30
AttribType:
	stosb
	
; 	FLAG RESERVADA (ESPECIAL)
	mov 	al, 00111111b 	; Reservado para permissões futuras
	stosb
	stosb				; SEGUNDO DE CRIAÇÃO (NÃO ESQUECER DE AL)
	
;  	DEFININDO TEMPO E DATA DE CRIAÇÃO E DATA DE ACESSO (LER TEMPO ATUAL)
	call 	GetSystemTimeEntry
	stosw					; Tempo de criação
	push 	ax
	call 	GetSystemDateEntry
	stosw					; Data de criação
	push 	ax
	stosw					; Data de acesso
	
	mov 	ax, 0xFFFF	; Todas as permissões, sendo administrador
	stosw				; permissões de 3 usuários (KFAT Permissions -> HighCluster)
	
; 	DEFININDO TEMPO E DATA DE MODIFICAÇÃO (APENAS EM CASOS DE CRIAÇÃO)
	pop 	ax
	shl 	eax, 16
	pop 	ax
	stosd

; 	APÓS ENCONTRAR O CLUSTER VAZIO, AX VAI VALER O NÚMERO DO CLUSTER
;	E ARMAZENAR NA ENTRADA
	mov 	ax, FAT_SEGMENT
    mov 	gs, ax
	xor 	bx, bx
	xor 	ax, ax
	call 	FreeSpaceCluster
	stosw
	
	call 	CheckIsFolder
	
; 	TAMANHO DO ARQUIVO (CX -> AX)
	xor 	eax, eax
	pop 	ax 			 ; RECUPERA TAMANHO DE CX PARA AX
	mov 	cx, ax
	cmp 	byte[LoadingDir], 1
	jne 	NoClearSize
	xor 	eax, eax
NoClearSize:
	stosd 

; 	RECUPERA SEGMENTO E VERIFICA A CADEIA
	pop 	ax 			  ; RECUPERAR SEGMENTO DE DIRETÓRIO ATUAL
	pop 	di			  ; RECUPERAR ENTRADA INICIAL DO ARQUIVO
	push 	di			  ; Salva entrada inicial
	push 	cx 			  ; Salva tamanho
	mov 	es, ax		  ; ES = SEGMENTO ATUAL
	xor 	bx, bx		  ; ZERAR BX EM AMBOS OS CASOS (OFFSET 0)
	cmp 	ax, 0x0200
	jne 	Search_Cluster
	
; 	ESCREVER NO DISCO A ENTRADA RAIZ
	mov 	ax, 499				; Setor inicial do diretório raíz
	xor  	cx, cx				; Zera cx
    mov  	cl, 2				; Setores Sequenciais do deslocamento de CD -> 0x40 = 0x400
	add 	eax, [PARTITION]
    call  	WriteLogicalSectors	; Escreve ES:BX (Dir. Raíz Adaptado) no setor 499 e 500
	jmp 	WriteFAT			; Salta para escrita do FAT
	
; 	ESCREVER NO DISCO A ENTRADA DE FOLDER
Search_Cluster:					; Procurar entrada com cluster da pasta atual
	sub 	di, 32				; Volta uma entrada
	cmp 	WORD[es:di], ". "	; Compare com o diretório atual
	jne 	Search_Cluster		; Enquanto não for, continue procurando
	
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]	; Quando encontrado, armazene o cluster do dir. atual em dx
	
WriteEntry:
	; escrever es:bx no setor lógico ax, convertido do cluster dx
	; salvar no disco o diretório atualizado
	mov 	[ClusterFile], dx
	mov  	ax, [ClusterFile]   
    call  	ClusterLBA
	xor  	cx, cx
    mov  	cl, SECTORS_PER_CLUSTER    ; 1 Setor para escrever
	add 	eax, [PARTITION]
    call  	WriteLogicalSectors
	
	push 	bx						  ; bx = bx + 512

    mov 	ax, [ClusterFile]    	  ; Restaure o Cluster atual salvo
    add 	ax, ax                	  ; Converta para bytes (ClusterFile * 2)
    mov 	bx, 0x0000                ; Zere BX para a soma
    add 	bx, ax                    ; Índice para o FAT: Some os bytes    
    mov 	dx, WORD [gs:bx]          ; Leia o próximo Cluster do FAT
    mov  	[ClusterFile], dx    	  ; DX está com o próximo Cluster
	
	pop 	bx						  ; bx = bx + 512
	
	cmp  	dx, END_OF_CLUSTER1    ; 0xFFF8
    je  	WriteFAT
	cmp  	dx, END_OF_CLUSTER2    ; 0xFFFF
	je 		WriteFAT
	jmp 	WriteEntry
	
WriteFAT:
; 	CALCULA SETOR INICIAL DO FAT DO ARQUIVO E ENDEREÇO INICIAL
	mov 	ax, [FreeCluster]		; Recupera número de cluster livre
	shl 	ax, 1					; Multiplica por 2
	mov 	bx, 512					; Define denominador 512 pra divisão
	xor 	dx, dx					; Zera dx pra não causar conflitos
	div 	bx						; Divide (FreeCluster * 2) por 512
	add 	ax, 7					; Soma setor inicial do FAT mais resultado
	mov 	[InitialFAT], ax		; Setor inicial do FAT do novo arquivo
	mov 	ax, WORD [AddrCluster+2]	; Segmento do FAT Salvo
	
	xor 	ecx, ecx
	pop 	cx 							; Recupera tamanho do arquivo
	pop 	di 							; Recupera entrada inicial
	push 	di 							; Salva novamente a entrada inicial
	push 	ax							; Salva o segmento atual do FAT na pilha
	
; 	CALCULA QUANTIDADE DE SETORES DE DADOS DO ARQUIVO
	xor 	edx, edx							; Zera EDX pra não causar conflitos
	mov 	eax, ecx							; Recupera em EAX o tamanho do arquivo
	xor 	ecx, ecx							; Zera ECX pra não causar discrepâncias
	mov 	ebx, 512							; Move denominador 512 pra EBX
	div 	ebx									; Divide tamanho do arquivo por 512
	cmp 	edx, 0								; Compare o resto com 0
	setne 	cl									; Se não for, Defina CL para 1
	add 	eax, ecx							; Adicione o resultado da div. por 1 ou 0
	mov 	ecx, eax							; Coloque esta quantidade de setores de dados em ECX
	

; 	ESCREVER NO FAT OS CLUSTERS DO ARQUIVO
	push 	ecx									; Salve o contador de setores de dados
WriteFatMemory:
	mov 	ax, WORD [AddrCluster+2]
	mov 	gs, ax								; GS = Segmento do FAT Salvo
	mov 	bx, WORD [AddrCluster]				; BX = Offset do Cluster Livre no FAT
	mov 	ax, [FreeCluster]					; AX = Nº de Cluster Livre
	
	cmp 	ecx, 1								; Compare Quantidade de Setores com 1
	je 		FatFileFinish						; Se for igual, finalize
	
	push 	bx									; Salve o offset do cluster livre
	call 	FreeSpaceCluster					; Calcule o próximo cluster livre na cadeia
	pop 	bx									; Recupere o offset do cluster livre
	mov 	WORD [gs:bx], ax					; Escreva o próximo cluster livre no offset
	jmp 	NextFat
	
FatFileFinish:
	mov 	WORD [gs:bx], 0xFFFF				; Escreva END_OF_CLUSTER no Cluster Livre
NextFat:
	loop 	WriteFatMemory
	
	mov 	ax, [FreeCluster]		; Recupera número de cluster livre
	shl 	ax, 1					; Multiplica por 2
	mov 	bx, 512					; Define denominador 512 pra divisão
	xor 	dx, dx					; Zera dx pra não causar conflitos
	div 	bx						; Divide (FreeCluster * 2) por 512
	add 	ax, 7					; Soma setor inicial do FAT mais resultado
	sub 	ax, [InitialFAT]		; Calcule a diferença de setores FAT
	add 	ax, 1					; Some +1 = Quantidade de Setores FAT para Escrever
	
	push 	es						; Salve Segmento Atual
	pop 	fs						; Recupere este Segmento em FS
	pop 	ecx						; Restaure o contador de setores de dados
	pop 	es 						; Restaure o segmento do fat inicial para es
	push 	ecx						; Salve novamente o contador de setores
	
	mov 	cx, [InitialFAT]		; CX é o setor de FAT inicial calculado
	sub 	cx, 7					; Subtrair pelo setor inicial padrão
	xor 	bx, bx					; Zere BX pra começar as somas de Offset
	cmp 	cx, 0					; Compare CX com 0
	jz 		WriteFatFile			; Se for igual, então Offset também será 0
	
SetRealOffset:						; Se for diferente, então BX tem que valer próximos offsets
	add 	bx, 512					; Adicione BX pro próximo offset (próximo setor)
	loop 	SetRealOffset			; Retorne CX vezes
	; a partir daqui ES:BX contém os endereços corretos

WriteFatFile:
	mov 	cx, ax					; CX = Quantidade de setores FAT
	mov 	ax, [InitialFAT]		; AX = Setor do FAT inicial pré-calculado
	add 	eax, [PARTITION]
	call  	WriteLogicalSectors		; Escreva CX setor(es) de ES:BX a partir do Setor AX
	pop 	ecx						; Restaure o contador de setores de dados
	
; 	DEFINIR SEGMENTOS PRINCIPAIS
	mov 	ax, es					; ES = Segmento do FAT do arquivo
    mov 	gs, ax					; GS = Segmento da Tabela FAT
	mov 	ax, word[FileSegments]
    mov 	es, ax					; ES = Segmento de Arquivos
	
	xor 	eax, eax				; Zera EAX pra não causar conflitos
	pop 	di 						; Restaure a entrada inicial do arquivo
	pop 	bx						; Restaure o BufferWrite
	mov 	dx, WORD [fs:di + FCLUSTER_ENTRY]	; Pegue o cluster do arquivo
	
; 	ESCREVER DADOS NO ARQUIVO
WriteDataFile:
	push 	ecx
	
	mov 	[ClusterFile], dx				; Salve o cluster do arquivo
	mov  	ax, [ClusterFile]   			; Mova o Nº Cluster salvo para ax
    call  	ClusterLBA						; Converta Nº Cluster para setor lógico
	xor  	cx, cx							; Zera cx
    mov  	cl, SECTORS_PER_CLUSTER    		; CX = 1 setor para escrever
	add 	eax, [PARTITION]
    call  	WriteLogicalSectors				; Escreva CX setor(es) a partir do setor lógico AX
											; O dado que está em ES:BX = 0x3000:BufferWrite
	
	push 	bx						  ; Salve os próximos 512 bytes

    mov 	ax, [ClusterFile]    	  ; Restaure o Cluster atual salvo
    add 	ax, ax                	  ; Converta para bytes (ClusterFile * 2)
    mov 	bx, 0x0000                ; Zere BX para a soma
    add 	bx, ax                    ; Índice para o FAT: Some os bytes    
    mov 	dx, WORD [gs:bx]          ; Leia o próximo Cluster do FAT
    mov  	[ClusterFile], dx    	  ; DX está com o próximo Cluster
	
	pop 	bx						  ; Restaure os próximos 512 bytes
	
	pop 	ecx
	loop 	WriteDataFile
	
RetCreateFile:
	clc
	ret

InitialFAT dw 0x0000

CheckIsFolder:
	pusha
	push 	es
	cmp 	byte[LoadingDir], 1
	jne 	Ret.CheckIsFolder
	
	push 	ax
	mov 	ax, word[FileSegments]
	mov 	es, ax
	xor 	di, di
	pop 	ax
	mov 	word[es:di + 0x1A], ax
	
	call 	GetSystemTimeEntry
	mov 	word[es:di + 0x0E], ax
	mov 	word[es:di + 0x20 + 0x0E], ax
	push 	ax
	call 	GetSystemDateEntry
	mov 	word[es:di + 0x10], ax
	mov 	word[es:di + 0x20 + 0x10], ax
	push 	ax
	mov 	word[es:di + 0x12], ax
	mov 	word[es:di + 0x20 + 0x12], ax
	
	pop 	ax
	shl 	eax, 16
	pop 	ax
	mov 	dword[es:di + 0x16], eax
	mov 	dword[es:di + 0x20 + 0x16], eax
	
Ret.CheckIsFolder:
	pop 	es
	popa
ret

GetSystemTimeEntry:
	mov 	ah, 02h
	int 	1Ah
	mov 	[hour], ch
	mov 	[min],  cl
	mov 	[sec], 	dh
	
	mov 	bx, 10
	xor 	dx, dx
	xor 	ax, ax
	mov 	al, ch
	shr 	al, 4
	mul 	bx
	and 	byte[hour], 0x0F
	add 	al, [hour]
	shl 	ax, 11
	
	push 	ax
	
	xor 	ax, ax
	xor 	dx, dx
	mov 	al, [min]
	shr 	al, 4
	mul 	bx
	and 	byte[min], 0x0F
	add 	al, [min]
	shl 	ax, 5
	
	pop 	cx
	or 		cx, ax
	
	xor 	ax, ax
	xor 	dx, dx
	mov 	al, [sec]
	shr 	al, 4
	mul 	bx
	and 	byte[sec], 0x0F
	add 	al, [sec]
	
	or 		ax, cx
ret
hour db 0
min  db 0
sec  db 0

GetSystemDateEntry:
	mov 	ah, 04h
	int 	1Ah
	mov 	[day], 	 dl
	mov 	[month], dh
	mov 	[year],  cl
	
	mov 	bx, 10
	xor 	ax, ax
	mov 	al, [year]
	shr 	al, 4
	mul 	bx
	and 	byte[year], 0x0F
	add 	al, [year]
	add 	al, 20
	shl 	ax, 9
	
	push 	ax
	
	xor 	ax, ax
	mov 	al, [month]
	shr 	al, 4
	mul 	bx
	and 	byte[month], 0x0F
	add 	al, [month]
	shl 	ax, 5
	
	pop 	cx
	or 		cx, ax
	
	xor 	ax, ax
	mov 	al, [day]
	shr 	al, 4
	mul 	bx
	and 	byte[day], 0x0F
	add 	al, [day]
	or 		ax, cx
ret
year  db 0
month db 0
day   db 0

FreeSpaceCluster:
	add 	bx, 2
	inc 	ax
	cmp 	bx, 0
	jne 	Check_Cluster
	mov 	dx, gs
	add 	dx, 0x1000			; Incrementa segmento +1
	mov 	gs, dx
Check_Cluster:
	cmp 	WORD[gs:bx], 0x0000
	jne 	FreeSpaceCluster
	mov 	WORD [AddrCluster+2], gs
	mov 	WORD [AddrCluster],   bx
	mov 	WORD [FreeCluster],   ax
ret
FreeCluster 	dw 0x0000
AddrCluster 	dd 0x00000000

WriteLogicalSectors:
    mov 	[DAPBuffer]   ,bx
    mov 	[DAPBuffer+2] ,es  ; ES:BX de onde os dados serão lidos pra escrever
    mov 	[DAPStart]    ,eax  ; Setor lógico inicial para escrever
_MAIN_WRITE:
    mov 	di, 0x0005	  ; 5 tentativas de leitura
_SECTORWRITE:
    push  	eax
    push  	bx
    push  	cx

    push 	si
    mov 	ah, 0x43
    mov 	dl, 0x80
    mov 	si, DAPSizeOfPacket
    int 	0x13
    pop 	si
    jnc  	_SUCCESS_WRITE
    xor  	ax, ax
    int  	0x13 
    dec  	di
    
    pop  	cx
    pop  	bx
    pop  	eax
	
    jnz  	_SECTORWRITE   
	jmp 	BOOT_FAILED
	
_SUCCESS_WRITE:
    pop  	cx
    pop  	bx
    pop  	eax
	
    ; Queue next buffer.
    add 	bx, BYTES_PER_SECTOR
    cmp 	bx, 0x0000
    jne 	_NEXTSECTORWRITE

    ; Trocando de segmento.
    push 	eax
    mov  	ax, es
    add  	ax, 0x1000
    mov  	es, ax
    pop  	eax
	
_NEXTSECTORWRITE:
    inc  	eax                     	; Incrementa 1 setor
    mov 	[DAPBuffer], bx
	mov 	[DAPBuffer+2],es   ; ES:BX para onde os dados vão
    mov 	[DAPStart], eax
    loop  	_MAIN_WRITE             ; Write next sector.
	xor 	eax, eax
ret

; TODO:
	; Criar entrada de diretórios na memória
	; Procurar Cluster da entrada atual (Ponto .) se não for RAIZ
	; Converter Cluster pra LBA (Área de dados)
	; Escrever entrada de diretórios no LBA do Disco
	

; BX = Handler
; DX = Buffer de Dados
; CX = Quantidade de Dados	
LoadFile:
	mov 	[HandlerReaded], bx
	call 	CheckBufferLoaded
	
	push 	di		; kernel_call = 0? DI = Handler
	push 	bx		; kernel_call = 0? BX = DataBuffer
	push 	dx		; kernel_call = 0? DX = Buffer_DOS
	push 	cx		; kernel_call = 0? CX = Bytes Amount
	
	mov 	byte[FileFound], 1
	mov 	byte[LoadDriver], 0
	
	cmp 	byte[LoadingDir], 1
	jne 	IsLoadingFile
	
IsLoadingDir:
	cmp 	byte[es:di + 11], 0x30
	jne	 	IsNotADir
	jmp 	ContinueLoad
IsLoadingFile:
	cmp 	byte[es:di + 11], 0x20
	jne	 	IsNotAFile
	jmp 	ContinueLoad
IsNotADir:
	cmp 	byte[es:di + 11], 0x10
	je 		ContinueLoad
	mov 	byte[SHELL.ErrorDir], 1
	mov 	ax, 0x04
	jmp 	RetLoadFile
IsNotAFile:
	cmp 	byte[es:di + 11], 0x04
	je 		ContinueLoad
	cmp 	byte[es:di + 11], 0x02
	je 		ContinueLoad
	cmp 	byte[es:di + 11], 0x01
	je 		ContinueLoad
	mov 	byte[SHELL.ErrorFile], 1
	mov 	ax, 0x03
	jmp 	RetLoadFile
	
ContinueLoad:
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov 	WORD [ClusterFile], dx
	
	mov 	ax, word[FileSegments]  ;FILE_SEGMENT
    mov 	es, ax
	jmp 	SetOtherSegments

	
LoadBinaryFile:
	push 	di
	push 	bx
	push 	dx
	push 	cx
	
	mov 	byte[FileFound], 1
	mov 	byte[LoadDriver], 1
	
	sub 	di, NAME_LENGTH
	mov 	dx, WORD [es:di + FCLUSTER_ENTRY]  ; Cluster do arquivo no FAT
    mov 	WORD [ClusterFile], dx
	
    mov 	ax, KERNEL_SEGMENT
    mov 	es, ax
	
SetOtherSegments:
	
	mov 	byte[sectors_count], 0
	
	mov 	ax, ROOT_SEGMENT
    mov 	fs, ax
	
    mov 	ax, FAT_SEGMENT
    mov 	gs, ax
	
ReadDataFile:

    mov  	ax, WORD [ClusterFile]   
    call  	ClusterLBA          		 ; Conversão de Cluster para LBA.
    xor  	cx, cx
    mov  	cl, SECTORS_PER_CLUSTER    ; 1 Setores para ler
	add 	eax, [PARTITION]
    call  	ReadLogicalSectors
	
	inc 	word[sectors_count]
	
	cmp 	byte[kernel_call], 1
	jz 		no_ret_read
	
	pop 	cx
	pop 	dx
	pop 	bx
	pop 	di

	call 	CheckBufferLoaded
	
	push 	di
	push 	bx
	push 	dx
	push 	cx
	
	mov 	ax, [FileSegments]
	mov 	es, ax
	
	jmp 	ReadDataFile
	
no_ret_read:
    push 	bx	 ; Buffer do arquivo 
    
	; Calculando o deslocamento do próximo Cluster do arquivo
    mov 	ax, WORD [ClusterFile]    ; identify current cluster
    add 	ax, ax                	  ; 16 bit(2 byte) FAT entry
    mov 	bx, 0x0000                ; location of FAT in memory
    add 	bx, ax                    ; index into FAT    
    mov 	dx, WORD [gs:bx]          ; read two bytes from FAT
    mov  	WORD [ClusterFile], dx   ; DX está com o próximo Cluster
	
	pop		bx    ; Buffer do arquivo 
	 
    cmp  	dx, END_OF_CLUSTER1    ; 0xFFF8
    je  	EndOfFile
	cmp  	dx, END_OF_CLUSTER2    ; 0xFFFF
	je 		EndOfFile
	
	jmp 	ReadDataFile
	
	
EndOfFile:
	pop 	cx
	pop 	dx
	pop 	bx
	pop 	di
	
	mov 	ax, word[DirSegments]
	mov 	es, ax
	mov 	edx, DWORD[es:di + FSIZE_ENTRY]
	
	cmp 	byte[LoadDriver], 0
	jz  	SaveNextOffset
	
	; Imprimir carregamento de drivers
	; Observações: Existirá uma aplicação que fará isso
	;push 	di
	;push 	si
	;mov 	si, StringID
	;call 	Print_String
	;sub 	di, NAME_LENGTH
	;call 	PrintNameFile
	;mov 	si, StringDvr
	;call 	Print_String
	;mov 	ax, bx
	;call 	Print_Hexa_Value16
	;call 	Break_Line
	;pop 	si
	;pop 	di
	
	mov 	edx, DWORD[es:di + (FSIZE_ENTRY - NAME_LENGTH)]
	
SaveNextOffset:
	cmp 	byte[LoadingDir], 1
	jz 		RetCountEntries	
	add 	bx, dx
	add 	bx, 2
	ret
RetCountEntries:
	mov 	ax, [sectors_count]
	mov 	bx, 16
	xor 	dx, dx
	mul 	bx
	mov 	bx, ax
	ret
	
RetLoadFile:
	pop 	cx
	pop 	dx
	pop 	bx
	pop 	di
ret
HandlerReaded	dw 0x0000
sectors_count 	dw 0x0000

CheckBufferLoaded:
	cmp 	byte[kernel_call], 1
	jz 		Ret.CheckOF
	
	add 	sp, 2
	mov 	di, [HandlerReaded]
	
	cmp 	word[di], 0x0000
	jz 		Ret.ErrHandler
	cmp 	di, OpenBuffer
	jb 		Ret.ErrHandler
	cmp 	di, OpenBuffer+512
	jae 	Ret.ErrHandler
	mov 	ax, di
	sub 	ax, OpenBuffer
	cmp 	ax, 0
	jz 		nochecknexterr
	
	
	sub 	sp, 2
	push 	dx
	xor 	dx, dx
	mov 	bx, 32
	div 	bx
	mov 	bx, dx
	pop 	dx
	add 	sp, 2
	cmp 	bx, 0
	jnz 	Ret.ErrHandler
	
nochecknexterr:
	mov 	al, [di + ACCESS_MODE]
	and 	al, 0x01
	cmp 	al, 0
	jnz 	Ret.ErrAccess
	mov 	ax, [di + CLUSTER_CHG]
	cmp 	ax, END_OF_CLUSTER2
	jz 		Ret.EndCluster
	sub 	sp, 2
	
	mov 	bx, [di + ID_FILE]
	shl 	bx, 9
	
	; ---- TEMPORARY ------------------------------
	;mov 	byte[di + SAVE_LOADED], 1	
	; ---------------------------------------------
	
	; DESCOBRE A QUANTIDADE DE BYTES RESTANTES DE DATA BUFFER
	mov 	eax, DWORD[di + POINTER_FILE] ; alterado
	shr 	eax, 9		; Quick divide to 512
	inc 	eax	 		; ax = ax + 1
	
	cmp 	ax, [di + SAVE_LOADED]
	jnz 	save_buffer_load
	
	shl 	eax, 9		; Quick multiply to 512
	sub 	eax, DWORD[di + POINTER_FILE]	; alterado
	mov 	[Q1], ax
	
	cmp 	cx, ax
	ja 		nochangeq1
	
	; DESCOBRE DESLOCAMENTO DO BUFFER BASEADO EM PONTEIRO DO ARQUIVO
	; E MOVE OS BYTES DO BUFFER JÁ CARREGADO
	mov 	[Q1], cx		; se quantidade solicitada for menor que calculada
	mov 	cx, 512
	sub 	cx, ax
	add 	bx, cx
	mov 	cx, [Q1]
	push 	ds
	push 	es
	mov 	ax, [DirSegments]
	mov 	es, ax
	mov 	ax, [FileSegments]
	mov 	ds, ax
	mov 	si, bx
	push 	di
	mov 	di, dx
	rep 	movsb
	pop 	di
	pop 	es
	pop 	ds
	
	add 	sp, 2
	mov 	ax, [Q1]
	add 	DWORD[di + POINTER_FILE], eax		;alterado
	
	
	add 	[CounterReaded], ax
	mov 	ax, [CounterReaded]
	jmp 	Ret.CheckOF_Kernel
	
nochangeq1:
	;mov 	byte[di + FLAGS_AUX], 1
	push 	cx
	mov 	cx, 512
	sub 	cx, ax
	add 	bx, cx
	mov 	si, bx
	mov 	cx, [Q1]
	push 	ds
	push 	es
	mov 	ax, [DirSegments]
	mov 	es, ax
	mov 	ax, [FileSegments]
	mov 	ds, ax
	push 	di
	mov 	di, dx
	rep 	movsb
	pop 	di
	pop 	es
	pop 	ds
	pop 	cx
	mov 	ax, [Q1]
	sub 	cx, ax
	add 	DWORD[di + POINTER_FILE], eax 	; alterado
	
	;int3
	
	add 	dx, ax
	add 	[CounterReaded], ax
	
	mov 	bx, [di + ID_FILE]		; ERA DATA_BUFFER
	shl 	bx, 9
	
	mov 	eax, DWORD[di + POINTER_FILE]  ; alterado
	shr 	eax, 9		; Quick divide to 512
	inc 	eax
	cmp 	ax, [di + SAVE_LOADED]
	jz 		clusterdiscover
	
save_buffer_load:
	mov 	[di + SAVE_LOADED], ax
clusterdiscover:
	push 	bx
    push 	dx
	push 	cx
	
	mov 	ax, FAT_SEGMENT
    mov 	gs, ax
	
	;mov 	byte[di + FLAGS_AUX], 1
	mov 	eax, DWORD[di + POINTER_FILE]  ; alterado
	shr 	eax, 9
	mov 	cx, ax
	cmp 	cx, 0
	jz 		restorereg
	
	mov 	dx, [di + CLUSTER_INI]
loop_discover:	
    mov 	ax, dx
    add 	ax, ax                	  ; 16 bit(2 byte) FAT entry
    mov 	bx, 0x0000                ; location of FAT in memory
    add 	bx, ax                    ; index into FAT    
    mov 	dx, WORD [gs:bx]          ; read two bytes from FAT
    mov  	[di + CLUSTER_CHG], dx   ; DX está com o próximo Cluster
	mov 	[ClusterFile], dx
	
	cmp 	dx, END_OF_CLUSTER2
	jz 		restore_endfile
	
	loop 	loop_discover
	
restorereg:
	pop 	cx
	pop 	dx
	pop		bx
	
	push 	ds
	pop 	es
	
Ret.CheckOF:
	clc
	ret
	
Ret.CheckOF_Kernel:
	mov 	word[CounterReaded], 0
	clc
	ret
	
Ret.ErrHandler:
	mov 	ax, 06h 		; Manipulador ilegal ou arquivo não aberto
	stc
	ret
	
Ret.ErrAccess:
	mov 	word[CounterReaded], 0
	mov 	ax, 05h 		; Acesso negado
	stc
	ret
	
; CASO SEJA FINAL DE ARQUIVO
restore_endfile:
	pop 	cx
	pop 	dx
	pop		bx
	add 	sp, 2
	
Ret.EndCluster:
	mov 	word[CounterCluster], 0
	mov 	word[CounterReaded], 0
	mov 	ax, 0
	ret
	
Loaded	db 0
Q1 		dw 0
CounterCluster dw 0
CounterReaded  dw 0

SetSeekFile:
	mov 	di, bx
	cmp 	word[di], 0x0000
	jz 		Ret.ErrHandler
	cmp 	di, OpenBuffer
	jb 		Ret.ErrHandler
	cmp 	di, OpenBuffer+512
	jae 	Ret.ErrHandler
	sub 	bx, OpenBuffer
	cmp 	bx, 0
	jz 		nextcheckseek
	
	push 	dx
	push 	ax
	xor 	dx, dx
	mov 	ax, bx
	mov 	bx, 32
	div 	bx
	mov 	bx, dx
	pop 	ax
	pop 	dx
	cmp 	bx, 0
	jnz 	Ret.ErrHandler
	
nextcheckseek:
	xor 	ebx, ebx
	mov 	bx, cx
	shl 	ebx, 16
	mov 	bx, dx
	cmp 	al, 00h
	jz 		start_origin
	cmp 	al, 01h
	jz 		current_origin
	cmp 	al, 02h
	jz 		end_origin
	jmp 	ret.errseekorigin

start_origin:
	mov 	[di + POINTER_FILE], ebx
	jmp 	ret.seeksuccess
current_origin:
	add 	[di + POINTER_FILE], ebx
	jmp 	ret.seeksuccess
end_origin:
	mov 	eax, [di + SIZE_BYTES]
	;dec 	eax
	add 	eax, ebx
	mov 	[di + POINTER_FILE], eax
	or 		byte[di + OPS_FLAG], 00000010b
ret.seeksuccess:
	or 		byte[di + OPS_FLAG], 00000001b
	mov 	dx, [di + POINTER_FILE + 2]
	mov 	ax, [di + POINTER_FILE]
	clc
	ret

ret.errseekorigin:
	mov 	ax, 01h 	; function number invalid
	stc
	ret
	
CloseFile:
	mov 	di, bx
	cmp 	word[di], 0x0000
	jz 		Ret.ErrHandler
	cmp 	di, OpenBuffer
	jb 		Ret.ErrHandler
	cmp 	di, OpenBuffer+512
	jae 	Ret.ErrHandler
	sub 	bx, OpenBuffer
	cmp 	bx, 0
	jz 		nextcheckclose
	
	xor 	dx, dx
	mov 	ax, bx
	mov 	bx, 32
	div 	bx
	mov 	bx, dx
	cmp 	bx, 0
	jnz 	Ret.ErrHandler
	
nextcheckclose:
	mov 	bx, [di + ID_FILE]
	shl 	bx, 9
	push 	es
	push 	di
	
	mov 	di, bx
	mov 	ax, [FileSegments]
	mov 	es, ax
	mov 	cx, 512 / 4
	xor 	eax, eax
	rep 	stosd
	
	pop 	di
	mov 	ax, ds
	mov 	es, ax
	mov 	cx, 32 / 4
	xor 	eax, eax
	rep 	stosd
	pop 	es
	
ret.closesuccess:
	xor 	ax, ax
	clc
	ret
	
	
; Converter cluster FAT em eschema de Endereçamento LBA
; LBA = ((ClusterFile - 2) * SectorsPerCluster) + DATASTART 
ClusterLBA:
    sub 	ax, 0x0002
    xor 	cx, cx
    mov 	cl, SECTORS_PER_CLUSTER
    mul 	cx
    add 	ax, WORD [DATASTART]
ret

	
ReadLogicalSectors:
    mov 	[DAPBuffer]   ,bx
    mov 	[DAPBuffer+2] ,es  ; ES:BX para onde os dados vão
    mov 	[DAPStart]   ,eax  ; Setor lógico inicial para ler
	push 	di
_MAIN:
    mov 	di, 0x0005	  ; 5 tentativas de leitura
_SECTORLOOP:
    push  	eax
    push  	bx
    push  	cx

    push 	si
    mov 	ah, 0x42
    mov 	dl, 0x80
    mov 	si, DAPSizeOfPacket
    int 	0x13
    pop 	si
    jnc  	_SUCCESS      ; Test for read error.
    xor  	ax, ax        ; BIOS reset disk.
    int  	0x13          ; Invoke BIOS.    
    dec  	di            ; Decrement error counter.
    
    pop  	cx
    pop  	bx
    pop  	eax
	
    jnz  	_SECTORLOOP    
	jmp 	BOOT_FAILED
	
_SUCCESS:
    pop  	cx
    pop  	bx
    pop  	eax
	
    ; Queue next buffer.
    add 	bx, BYTES_PER_SECTOR
    cmp 	bx, 0x0000
    jne 	_NEXTSECTOR

    ; Trocando de segmento.
    push 	eax
    mov  	ax, es
    add  	ax, 0x1000
    mov  	es, ax
    pop  	eax
	
_NEXTSECTOR:
    inc  	eax                     	; Queue next sector.
    mov 	[DAPBuffer], bx
	mov 	[DAPBuffer+2],es  ; ES:BX para onde os dados vão
    mov 	[DAPStart], eax
    loop  	_MAIN                 	; Read next sector.
	xor 	eax, eax
	pop 	di
ret

	
BOOT_FAILED:
    int  	0x18

OpenBuffer times 512 db 0
DataBuffer: times 512 db 0
