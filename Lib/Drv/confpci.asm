; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                    DRIVER DE COMUNICAÇÃO PCI
;
;                     Kernel em Assembly x86
;                    Criado por Wender Francis
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%IFNDEF		__CONFPCI_ASM__
%DEFINE 	__CONFPCI_ASM__

PCI_ADDRESS		EQU	0x0CF8
PCI_DATA		EQU	0x0CFC
PCI_READ 		EQU 0x00
PCI_WRITE 		EQU 0x01

bus 	db 0
slot 	db 0
func 	db 0
offs 	db 0
pdata 	dd 0

os_PCIEnabled  db 0


Init_PCI:
	mov 	eax, 0x80000000		; Bit 31 set for 'Enabled'
	mov 	ebx, eax
	mov 	dx, PCI_ADDRESS
	out 	dx, eax
	in 		eax, dx
	xor 	edx, edx
	cmp 	eax, ebx
	sete 	dl				; Set byte if equal, otherwise clear
	mov 	byte [os_PCIEnabled], dl
ret


	
; -----------------------------------------------------------------------------
; PCI_Read_Word - Ler de um registro um dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
;		CL  = Function number
; 		DL  = Offset number
; OUT:	EAX = Register information
PCI_Read_Word:
	push 	ebx
	push 	ecx
	push 	edx
	
	shl 	eax, 16
	shl 	ebx, 11
	or 		eax, ebx
	shl 	ecx, 8
	or 		eax, ecx
	and 	edx, 0xFC
	or 	 	eax, edx
	and 	eax, 0x00FFFFFF
	or 		eax, 0x80000000
	mov 	dx, PCI_ADDRESS
	out 	dx, eax
	mov 	dx, PCI_DATA
    in 		eax, dx
	mov 	[PCI_Reg], eax
	
	pop 	edx
	and 	edx, 0x02
	shl 	edx, 3          ; multiplique por 8
	mov 	ecx, edx
	shr 	eax, cl
	and 	eax, 0xFFFF
	
    pop 	ecx
	pop 	ebx
ret
PCI_Reg 	dd 0x00000000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Write_Word - Escreve para um registro um dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
;		CL  = Function number
; 		DL  = Offset number
; OUT:	None.
PCI_Write_Word:
	push 	ebx
	push 	ecx
	push 	edx
	
	shl 	eax, 16
	shl 	ebx, 11
	or 		eax, ebx
	shl 	ecx, 8
	or 		eax, ecx
	and 	edx, 0xFC
	or 	 	eax, edx
	and 	eax, 0x00FFFFFF
	or 		eax, 0x80000000
	mov 	dx, PCI_ADDRESS
	out 	dx, eax
	mov 	dx, PCI_DATA
	mov 	eax, [pdata]
	out 	dx, eax
	
	pop 	edx
    pop 	ecx
	pop 	ebx
ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PCI_Check_Device - Verifica um Dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; OUT:	None.
;	Registradores preservados
PCI_Check_Device:
	pushad
	
	mov 	cl, 0          ; Função 0
	call 	PCI_Get_VendorID
	cmp 	word[Vendor], 0xFFFF
	je 		DeviceNoExist
	
	; EXIBIR INFORMAÇÕES ----------------
	call 	PCI_Show_Parcial
	; -----------------------------------
		
	call 	PCI_Check_Function
	call 	PCI_Get_HeaderType
	and 	byte[Header], 0x80  
	cmp 	byte[Header], 0        ; Se bit 7 não estiver setado então
	jz  	ReturnDevice           ; Então não É um dispositivo multi-função
Multi_Func_Dev:                    ; Se tiver, É um dev multifunção
	mov 	cl, 1
	Loop_Check_Functions:
		cmp 	cl, 8
		jnb 	ReturnDevice
		
		call 	PCI_Get_VendorID
		cmp 	word[Vendor], 0xFFFF
		jne 	CheckFunction
	
		inc 	cl
		jmp 	Loop_Check_Functions
	CheckFunction:
		call 	PCI_Check_Function
		
		; EXIBIR INFORMAÇÕES ----------------
		call 	PCI_Show_Parcial
		; -----------------------------------
	
		inc 	cl
		jmp 	Loop_Check_Functions
	
DeviceNoExist:
	;stc
	;mov 	si, MsgNoDev
	;call 	Print_String
ReturnDevice:
	popad
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Check_Function - Verifica aquela função do barramento
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	None.
PCI_Check_Function:
	push 	ax
	
	call 	PCI_Get_ClassCode
	call 	PCI_Get_SubClass
	cmp 	byte[ClassCode], 0x06
	jne 	ret_check_func
	cmp 	byte[SubClass], 0x04
	jne 	ret_check_func
	
	call 	PCI_Get_SecondaryBus
	mov 	al, [SecondaryBus]
	call 	PCI_Check_Bus
	
ret_check_func:
	pop 	ax
ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PCI_Show_Full - Exibe informações do dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	None.
PCI_Show_Full:
	push 	ax
	call 	Print_Dec_Value32
	call 	OffsetSpacesDec
	mov 	ax, bx
	call 	Print_Dec_Value32
	call 	OffsetSpacesDec
	mov 	ax, cx
	call 	Print_Dec_Value32
	call 	OffsetSpacesDec
	pop 	ax
	push 	ax
	call 	PCI_Get_DeviceID
	call 	PCI_Get_Classes
	mov 	ax, word[Vendor]
	call 	Print_Hexa_Value16
	call 	OffsetSpacesHex
	mov 	ax, word[Device]
	call 	Print_Hexa_Value16
	call 	OffsetSpacesHex
	
	call 	Show_Name_Devices
	
	pop 	ax
ret

PCI_Show_Parcial:
	push 	ax
	
	call 	PCI_Get_DeviceID
	call 	PCI_Get_Classes
	call 	PCI_Get_ProgIF
	mov 	ax, word[Vendor]
	call 	Print_Hexa_Value16
	call 	OffsetSpacesHex
	mov 	ax, word[Device]
	call 	Print_Hexa_Value16
	call 	OffsetSpacesHex
	
	call 	Show_Name_Devices
	
	pop 	ax
ret

Show_Name_Devices:
	push 	bx
	push 	si
	
	mov 	si, ADDRCL
	mov 	bl, byte[ClassCode]
	shl 	bx, 1
	mov 	si, word[si + bx]
	call 	Print_String
	
	cmp 	byte[SubClass], 0x80
	je 		ShowOther
	
	push 	bx
	mov 	si, SUBVEC
	mov 	si, word[si + bx]
	mov 	bl, byte[SubClass]
	shl 	bx, 1
	mov 	si, word[si + bx]
	call 	Print_String
	pop 	bx
	
	mov 	si, PROGCL
	mov 	si, word[si + bx]   ; SI = SUBPIFx
	cmp 	si, 0x0000
	jz 		Ret_Names
	mov 	bl, byte[SubClass]   
	shl 	bx, 1
	mov 	si, word[si + bx]   ; SI = PCISBx
	cmp 	si, 0x0000
	jz 		Ret_Names
	mov 	bl, byte[ProgIF]
	shl 	bx, 1
	mov 	si, word[si + bx]   ; SI = PROGIFx.x_x
	
	jmp 	ShowDevice
ShowOther:
	mov 	si, OTHER
ShowDevice:
	call 	Print_String
	
	; Acesso das Strings de Interface -----------
; PROGCL  -> Índice das classes
; SUBPIFx -> Índice das subclasses
; PCISBx  -> Índice das Interfaces
; PROGIFx.x_x -> Endereço da String
;
; Acesso das Strings de SubClasses
; SUBVEC  -> Índice das Classes com vetor de SubClasses
; PCICLx  -> Índice das SubClasses dentro de uma Classe

Ret_Names:
	call 	Break_Line
	
	pop 	si
	pop 	bx
ret


OffsetSpacesDec:
	pushad
	mov 	cx, 7
	mov 	bx, 10
OffSpace1:
	xor 	dx, dx
	div 	bx
	cmp 	ax, 0
	je 	    RetOff	
IncVar:
	dec 	cx
	jmp 	OffSpace1
RetOff:
	mov 	ax, 0x0E20
	int 	0x10
	loop 	RetOff
	mov 	ah, 0x0E
	mov 	al, "|"
	int 	0x10
	popad
ret

OffsetSpacesHex:
	pushad
	mov 	cx, 4
Loop_Off:
	mov 	ax, 0x0E20
	int 	0x10
	loop 	Loop_Off
	mov 	ah, 0x0E
	mov 	al, "|"
	int 	0x10
	popad
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Check_All_Buses - Brute Force Scan - All bus, All Slots & All Possibly funcs
; IN:   None.
; OUT:	None.
;	Registradores preservados
PCI_Check_All_Buses:
	pushad
	xor 	eax, eax
	xor 	ebx, ebx
	xor 	ecx, ecx
	xor 	edx, edx
	; EXIBIR INFORMAÇÕES ----------------
	mov 	si, PCIListStr1
	call 	Print_String
	; -----------------------------------
	mov 	al, 0
	loop_all_buses1:
		cmp 	al, 255        ; Ler os primeiros 4 barramentos
		jb  	init_loop_bus
		jmp 	return_checkb
		
	init_loop_bus:
		mov 	bl, 0
	loop_all_buses2:
		cmp 	bl, 32
		jnb 	return_all_buses
		call 	PCI_Check_Device
		inc 	bl
		jmp 	loop_all_buses2
		
	return_all_buses:
		inc 	al
		jmp 	loop_all_buses1
return_checkb:
	popad
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Check_Mult_Buses - Recursive Scan - Verificar se há multiplos PCIs 
; PCI_Check_All_Buses EXHANCED!
; IN:   None.
; OUT:	None.
;	Registradores preservados
PCI_Check_Mult_Buses:
	pushad
	xor 	eax, eax
	xor 	ebx, ebx
	xor 	ecx, ecx
	xor 	edx, edx
	
	; EXIBIR INFORMAÇÕES ----------------
	mov 	si, PCIListStr
	call 	Print_String
	; -----------------------------------
	
	call 	PCI_Get_HeaderType
	and 	byte[Header], 0x80
	cmp 	byte[Header], 0
	jnz 	Check_Multiple_PCI
	call 	PCI_Check_Bus
	jmp 	ret_mult_buses
	
Check_Multiple_PCI:
	cmp 	cl, 8
	jnb 	ret_mult_buses
	mov 	al, 0
	call 	PCI_Get_VendorID
	cmp 	word[Vendor], 0xFFFF
	je 		ret_mult_buses
	
	mov 	al, cl
	call 	PCI_Check_Bus
	inc 	cl
	jmp 	Check_Multiple_PCI
	
ret_mult_buses:
	popad
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Check_Bus - Recursive Scan
; IN:   AL = Bus number.
; OUT:	None.
PCI_Check_Bus:
	push 	bx
	push 	cx
	
	mov 	bx, 0
	mov 	cx, 32
	loop_bus:
		call 	PCI_Check_Device
		inc 	bx
		loop 	loop_bus
		
	pop 	cx
	pop 	bx
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_VendorID - Retorna o ID do fabricante do dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AX = ID do Fabricante
PCI_Get_VendorID:
	push 	eax

	mov 	dl, 0                  ; Offset 0 -> Fabricante
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	word[Vendor], ax       ; Armazene o retorno em Vendor
	
	pop 	eax
ret
Vendor 	dw 	0x0000
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PCI_Get_DeviceID - Retorna o ID do dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
;       CL  = Função
; OUT:	AX = ID do Dispositivo
PCI_Get_DeviceID:
	push 	eax
	
	mov 	dl, 2                  ; Offset 2 -> Dispositivo
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	word[Device], ax       ; Armazene o retorno em Device

	pop 	eax
ret
Device 	dw 	0x0000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_Command - Retorna o valor de Comando
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AX = Comando
PCI_Get_Command:
	push 	eax

	mov 	dl, 4                   ; Offset 4 -> Command
	call 	PCI_Read_Word           ; Efetua a leitura PCI
	mov 	word[Command], ax       ; Armazene o retorno em Command

	pop 	eax
ret
Command 	dw 	0x0000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_Status - Retorna o Status
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AX = Status
PCI_Get_Status:
	push 	eax

	mov 	dl, 6                  ; Offset 6 -> Status
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	word[Status], ax       ; Armazene o retorno em Status

	pop 	eax
ret
Status 	dw 	0x0000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_RevisionID - Retorna o ID de Revisão
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AL = ID de Revisão
PCI_Get_RevisionID:
	push 	eax

	mov 	dl, 8                  ; Offset 8 -> RevisionID
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	byte[Revision], al     ; Armazene o retorno em Revision

	pop 	eax
ret
Revision  	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_ProgIF - Retorna o ProgIF
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AH = ProgIF
PCI_Get_ProgIF:
	push 	eax

	mov 	dl, 8                  ; Offset 8 -> ProgIF
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	byte[ProgIF], ah       ; Armazene o retorno em ProgIF

	pop 	eax
ret
ProgIF  	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_SubClass - Retorna a SubClasse
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AL  = SubClass
PCI_Get_SubClass:
	push 	eax

	mov 	dl, 10                  ; Offset 10 -> SubClasse
	call 	PCI_Read_Word           ; Efetua a leitura PCI
	mov 	byte[SubClass], al      ; Armazene o retorno em SubClass

	pop 	eax
ret
SubClass  	db 	0x00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PCI_Get_ClassCode - Retorna o código de Classe
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AH = Código de Classe
PCI_Get_ClassCode:
	push 	eax

	mov 	dl, 10                   ; Offset 10 -> Código de Classe
	call 	PCI_Read_Word            ; Efetua a leitura PCI
	mov 	byte[ClassCode], ah      ; Armazene o retorno em ClassCode

	pop 	eax
ret
ClassCode  	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_CacheSize - Retorna o tamanho de linha de Cache
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AL = Cache Line Size
PCI_Get_CacheSize:
	push 	eax

	mov 	dl, 12                   ; Offset 12 -> Cache Line Size
	call 	PCI_Read_Word            ; Efetua a leitura PCI
	mov 	byte[CacheSize], al      ; Armazene o retorno em CacheSize

	pop 	eax
ret
CacheSize  	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_Latency - Retorna o Timer de latência
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AH = Timer de Latência
PCI_Get_Latency:
	push 	eax

	mov 	dl, 12                   ; Offset 12 -> Timer de Latência
	call 	PCI_Read_Word            ; Efetua a leitura PCI
	mov 	byte[Latency], ah        ; Armazene o retorno em Latency

	pop 	eax
ret
Latency  	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_HeaderType - Retorna o Tipo de Cabeçalho (Header)
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AL = Tipo de Cabeçalho
PCI_Get_HeaderType:
	push 	eax

	mov 	dl, 14                 ; Offset 14 -> Tipo De Cabeçalho
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	byte[Header], al       ; Armazene o retorno em Header

	pop 	eax
ret
Header 	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_BIST - Retorna o Valor BIST
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AH = valor BIST
PCI_Get_BIST:
	push 	eax

	mov 	dl, 14                 ; Offset 14 -> BIST
	call 	PCI_Read_Word          ; Efetua a leitura PCI
	mov 	byte[BIST], ah         ; Armazene o retorno em BIST

	pop 	eax
ret
BIST 	db 	0x00
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_Classes - Retorna a Classe base & subClasse
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AX  = Classe Base e SubClasse
PCI_Get_Classes:
	push 	eax
	
	mov 	dl, 10                   ; Offset 10 -> Base e SubClasse
	call 	PCI_Read_Word            ; Efetua a leitura PCI
	mov 	word[Classes], ax        ; Armazene o retorno em Classes
	mov 	byte[ClassCode], ah
	mov 	byte[SubClass], al
	
	pop 	eax
ret
Classes  	dw 	0x0000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; PCI_Get_SecondaryBus - Retorna o Barramento Secundário
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AX  = Barramento Secundário
PCI_Get_SecondaryBus:
	push 	eax
	
	mov 	dl, 0x18                      ; Offset 24 -> Barramento Secundário
	call 	PCI_Read_Word                 ; Efetua a leitura PCI
	mov 	byte[SecondaryBus], ah        ; Armazene o retorno em SecondaryBus
	mov 	byte[PrimaryBus], al
	
	pop 	eax
ret
SecondaryBus  	db 	0x00
PrimaryBus 		db  0x00

; -----------------------------------------------------------------------------
; PCI_Get_Cardbus - Retorna Ponteiro pra informações do dispositivo
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	AX  = CardBus CIS Pointer
PCI_Get_Cardbus:
	push 	eax
	
	mov 	dl, 0x28                   ; Offset 0x28 -> CardBus CIS Pointer 
	call 	PCI_Read_Word              ; Efetua a leitura PCI
	mov 	eax, [PCI_Reg]			   ; Pega o valor de 32 bits do ponteiro
	mov 	[CardPointer], eax         ; Armazene o retorno em CardPointer
	
	pop 	eax
ret
CardPointer  	dd 	0x00000000
; -----------------------------------------------------------------------------
	
; Acesso das Strings de Interface -----------
; PROGCL  -> Índice das classes
; SUBPIFx -> Índice das subclasses
; PCISBx  -> Índice das Interfaces
;
; Acesso das Strings de SubClasses
; SUBVEC  -> Índice das Classes com vetor de SubClasses
; PCICLx  -> Índice das SubClasses dentro de uma Classe
	
PCIListStr:
		db "KiddieOS PCI List",13,10,13,10
		db "BUS     |DEV     |FUNC    |VENDOR  |DEVICE  |DEVICE CLASS NAME   ",13,10,0
		
PCIListStr1:
		db "KiddieOS PCI List",13,10,13,10
		db "|VENDOR |DEVICE  |DEVICE CLASS NAME   ",13,10,0
		
		
SUBVEC  dw PCICL0, PCICL1, PCICL2, PCICL3, PCICL4, PCICL5, PCICL6, PCICL7, PCICL8
        dw PCICL9, PCICLA, PCICLB, PCICLC, PCICLD, PCICLE, PCICLF, PCICL10, PCICL11
		

ADDRCL  dw CLASS0,  CLASS1,  CLASS2,  CLASS3,  CLASS4, CLASS5, CLASS6, CLASS7 
        dw CLASS8,  CLASS9,  CLASSA,  CLASSB,  CLASSC, CLASSD, CLASSE, CLASSF
		dw CLASS10, CLASS11, CLASS12, CLASS13
		TIMES (0x3F - 0x14) dw 0x0000
		dw CLASS40
		TIMES (0xFE - 0x41) dw 0x0000
		dw CLASSFF	
		
SUBPIF1  dw 0,PCISB0,0,0,0,PCISB1,PCISB2,PCISB3,PCISB4,0           ; Para SubClasses da Classe 1
SUBPIF3  dw PCISB5,0,0,0                                           ; Para SubClasses da Classe 3
SUBPIF6  dw 0,0,0,0,PCISB6,0,0,0,PCISB7,PCISB8,0,0                 ; Para SubClasses da Classe 6
SUBPIF7  dw PCISB9,PCISB10,0,PCISB11,0,0,0                         ; Para SubClasses da Classe 7
SUBPIF8  dw PCISB12,PCISB13,PCISB14,PCISB15,0,0,0,0                ; Para SubClasses da Classe 8
SUBPIF9  dw 0,0,0,0,PCISB16,0                                      ; Para SubClasses da Classe 9
SUBPIFC  dw PCISB17,0,0,PCISB18,0,0,0,PCISB19,0,0,0                ; Para SubClasses da Classe 12

PROGCL   dw 0,SUBPIF1,0,SUBPIF3,0,0,SUBPIF6,SUBPIF7,SUBPIF8        ; Acessada por Classes
         dw SUBPIF9,0,0,SUBPIFC,0,0,0,0,0,0                                          
	
PCI_Names:
CLASS0: db "Unclassified: ",0
	
	SBCLASS0_0 db "Non-VGA-Compatible Unclassified Device",0
	SBCLASS0_1 db "VGA-Compatible Unclassified Device",0
	
	PCICL0  dw SBCLASS0_0, SBCLASS0_1

CLASS1: db  "Mass Storage: ",0
	
	SBCLASS1_0  db "SCSI Bus Controller ",0	
	SBCLASS1_1  db "IDE Controller",0
		
		PROGIF1.1_0   db " [ISA Compatibility mode-only controller]",0
		PROGIF1.1_5   db " [PCI native mode-only controller]",0
		PROGIF1.1_A   db " [ISA Compatibility mode controller, channels to PCI native mode]",0
		PROGIF1.1_F   db " [PCI native mode controller, channels to ISA compatibility mode]",0
		PROGIF1.1_80  db " [ISA Compatibility mode-only controller, bus mastering]",0
		PROGIF1.1_85  db " [PCI native mode-only controller, bus mastering]",0
		PROGIF1.1_8A  db " [ISA Compatibility mode controller, channels to PCI native mode, bus mastering]",0
		PROGIF1.1_8F  db " [PCI native mode controller, channels to ISA compatibility mode, bus mastering]",0
		
		PCISB0  dw PROGIF1.1_0,0,0,0,0,PROGIF1.1_5,0,0,0,0,PROGIF1.1_A,0,0,0,0,PROGIF1.1_F
				TIMES (0x80 - 0xF - 1) dw 0x0000
				dw PROGIF1.1_80,0,0,0,0,PROGIF1.1_85,0,0,0,0,PROGIF1.1_8A,0,0,0,0,PROGIF1.1_8F
				
	SBCLASS1_2  db "Floppy Disk Controller",0
	SBCLASS1_3  db "IPI Bus Controller",0
	SBCLASS1_4  db "RAID Controller",0
	SBCLASS1_5  db "ATA Controller",0
		
		PROGIF1.5_20  db " [Single DMA]",0
		PROGIF1.5_30  db " [Chained DMA]",0
		
		PCISB1: TIMES (0x20 - 1) dw 0x0000
				dw PROGIF1.5_20
				TIMES (0x10 - 1) dw 0x0000
				dw PROGIF1.5_30
		
	SBCLASS1_6  db "Serial ATA Controller",0
		
		PROGIF1.6_0 db " [Vendor Specific Interface]",0
		PROGIF1.6_1 db " [AHCI 1.0]",0
		PROGIF1.6_2 db " [Serial Storage Bus]",0
		
		PCISB2  dw PROGIF1.6_0,PROGIF1.6_1,PROGIF1.6_2
		
	SBCLASS1_7  db "Serial Attached SCSI Controller",0
	
		PROGIF1.7_0 db " [SAS]",0
		PROGIF1.7_1 db " [Serial Storage Bus]",0
		
		PCISB3  dw PROGIF1.7_0,PROGIF1.7_1
		
	SBCLASS1_8  db "Non-Volatile Memory Controller ",0
	
		PROGIF1.8_1 db " [NVMHCI]",0
		PROGIF1.8_2 db " [NVM Express]",0
		
		PCISB4  dw 0,PROGIF1.8_1,PROGIF1.8_2
		
	PCICL1 	dw SBCLASS1_0,SBCLASS1_1,SBCLASS1_2,SBCLASS1_3,SBCLASS1_4,SBCLASS1_5,SBCLASS1_6,SBCLASS1_7,SBCLASS1_8
	
CLASS2: db "Network: ",0

	SBCLASS2_0  db "Ethernet Controller",0
	SBCLASS2_1  db "Token Ring Controller",0
	SBCLASS2_2  db "FDDI Controller",0
	SBCLASS2_3  db "ATM Controller",0
	SBCLASS2_4  db "ISDN Controller",0
	SBCLASS2_5  db "WorldFip Controller",0
	SBCLASS2_6  db "PICMG 2.14 Multi Computing Controller",0
	SBCLASS2_7  db "Infiniband Controller",0
	SBCLASS2_8  db "Fabric Controller",0

	PCICL2 	dw SBCLASS2_0,SBCLASS2_1,SBCLASS2_2,SBCLASS2_3,SBCLASS2_4,SBCLASS2_5,SBCLASS2_6,SBCLASS2_7,SBCLASS2_8
	
CLASS3: db "Display: ",0

	SBCLASS3_0  db "VGA Compatible Controller",0
		
		PROGIF3.0_0  db " [VGA Controller]",0
		PROGIF3.0_1  db " [8514-Compatible Controller]",0
		
		PCISB5  dw PROGIF3.0_0,PROGIF3.0_1
		
	SBCLASS3_1  db "XGA Controller",0
	SBCLASS3_2  db "3D Controller (Not VGA-Compatible)",0
	
	PCICL3 	dw SBCLASS3_0,SBCLASS3_1,SBCLASS3_2
	
CLASS4: db "Multimedia: ",0
	
	SBCLASS4_0  db "Multimedia Video Controller",0
	SBCLASS4_1  db "Multimedia Audio Controller",0
	SBCLASS4_2  db "Computer Telephony Device",0
	SBCLASS4_3  db "Audio Device",0
	
	PCICL4 	dw SBCLASS4_0,SBCLASS4_1,SBCLASS4_2,SBCLASS4_3
	
CLASS5: db "Memory: ",0

	SBCLASS5_0  db "RAM Controller",0
	SBCLASS5_1  db "Flash Controller",0
	
	PCICL5 	dw SBCLASS5_0,SBCLASS5_1
	
CLASS6: db "Bridge: ",0

	SBCLASS6_0  db "Host Bridge",0
	SBCLASS6_1  db "ISA Bridge",0
	SBCLASS6_2  db "EISA Bridge",0
	SBCLASS6_3  db "MCA Bridge",0
	SBCLASS6_4  db "PCI-to-PCI Bridge",0
		
		PROGIF6.4_0  db " [Normal Decode]",0 
		PROGIF6.4_1  db " [Subtractive Decode]",0 
		
		PCISB6  dw PROGIF6.4_0,PROGIF6.4_1
		
	SBCLASS6_5  db "PCMCIA Bridge",0
	SBCLASS6_6  db "NuBus Bridge",0
	SBCLASS6_7  db "CardBus Bridge",0
	SBCLASS6_8  db "RACEway Bridge",0
		
		PROGIF6.8_0  db " [Transparent Mode]",0
		PROGIF6.8_1  db " [Endpoint Mode]",0
		
		PCISB7  dw PROGIF6.8_0,PROGIF6.8_1
		
	SBCLASS6_9  db "PCI-to-PCI Bridge",0
	
		PROGIF6.9_40  db " [Semi-Transparent, Primary bus towards host CPU]",0
		PROGIF6.9_80  db " [Semi-Transparent, Secondary bus towards host CPU]",0
		
		PCISB8: TIMES (0x40 - 1) dw 0x0000
				dw PROGIF6.9_40
				TIMES (0x40 - 1) dw 0x0000
				dw PROGIF6.9_80
		
	SBCLASS6_A  db "InfiniBand-to-PCI Host Bridge",0
	
	PCICL6 	dw SBCLASS6_0,SBCLASS6_1,SBCLASS6_2,SBCLASS6_3,SBCLASS6_4,SBCLASS6_5,SBCLASS6_6,SBCLASS6_7,SBCLASS6_8,SBCLASS6_9,SBCLASS6_A
	
CLASS7: db "Simple Communication: ",0

	SBCLASS7_0  db "Serial Controller",0
	
		PROGIF7.0_0  db " [8250-Compatible (Generic XT)]",0
		PROGIF7.0_1  db " [16450-Compatible]",0
		PROGIF7.0_2  db " [16550-Compatible]",0
		PROGIF7.0_3  db " [16650-Compatible]",0
		PROGIF7.0_4  db " [16750-Compatible]",0
		PROGIF7.0_5  db " [16850-Compatible]",0
		PROGIF7.0_6  db " [16950-Compatible]",0
		
		PCISB9  dw PROGIF7.0_0,PROGIF7.0_1,PROGIF7.0_2,PROGIF7.0_3,PROGIF7.0_4,PROGIF7.0_5,PROGIF7.0_6
		
	SBCLASS7_1  db "Parallel Controller",0
	
		PROGIF7.1_0   db " [Standard Parallel Port]",0
		PROGIF7.1_1   db " [Bi-Directional Parallel Port]",0
		PROGIF7.1_2   db " [ECP 1.X Compliant Parallel Port]",0
		PROGIF7.1_3   db " [IEEE 1284 Controller]",0
		PROGIF7.1_FE  db " [IEEE 1284 Target Device]",0
		
		PCISB10  dw PROGIF7.1_0,PROGIF7.1_1,PROGIF7.1_2,PROGIF7.1_3
				 TIMES (0xFE - 0x4 - 1) dw 0x0000
				 dw PROGIF7.1_FE
		
	SBCLASS7_2  db "Multiport Serial Controller",0
	SBCLASS7_3  db "Modem",0
	
	    PROGIF7.3_0  db " [Generic Modem]",0
	    PROGIF7.3_1  db " [Hayes 16450-Compatible Interface]",0
	    PROGIF7.3_2  db " [Hayes 16550-Compatible Interface]",0
	    PROGIF7.3_3  db " [Hayes 16650-Compatible Interface]",0
	    PROGIF7.3_4  db " [Hayes 16750-Compatible Interface]",0
		
		PCISB11  dw PROGIF7.3_0,PROGIF7.3_1,PROGIF7.3_2,PROGIF7.3_3,PROGIF7.3_4
		
		
	SBCLASS7_4  db "IEEE 488.1/2 (GPIB) Controller",0
	SBCLASS7_5  db "Smart Card Controller",0
	
	PCICL7 	dw SBCLASS7_0,SBCLASS7_1,SBCLASS7_2,SBCLASS7_3,SBCLASS7_4,SBCLASS7_5
	
CLASS8: db "Base System Peripheral: ",0

	SBCLASS8_0  db "PIC",0
		
		PROGIF8.0_0   db " [Generic 8259-Compatible]",0
		PROGIF8.0_1   db " [ISA-Compatible]",0
		PROGIF8.0_2   db " [EISA-Compatible]",0
		PROGIF8.0_10  db " [I/O APIC Interrupt Controller]",0
		PROGIF8.0_20  db " [I/O(x) APIC Interrupt Controller]",0
		
		PCISB12  dw PROGIF8.0_0,PROGIF8.0_1,PROGIF8.0_2,0,0,0,0,0,0,0,0,0,0,0,0,0
		dw PROGIF8.0_10
		TIMES (0x10 - 1) dw 0x0000
		dw PROGIF8.0_20
		
	SBCLASS8_1  db "DMA Controller",0
	
		PROGIF8.1_0   db " [Generic 8237-Compatible]",0
		PROGIF8.1_1   db " [ISA-Compatible]",0
		PROGIF8.1_2   db " [EISA-Compatible]",0
		
		PCISB13  dw PROGIF8.1_0,PROGIF8.1_1,PROGIF8.1_2
		
	SBCLASS8_2  db "Timer",0
	
		PROGIF8.2_0   db " [Generic 8254-Compatible]",0
		PROGIF8.2_1   db " [ISA-Compatible]",0
		PROGIF8.2_2   db " [EISA-Compatible]",0
		PROGIF8.2_3   db " [HPET]",0
		
		PCISB14  dw PROGIF8.2_0,PROGIF8.2_1,PROGIF8.2_2,PROGIF8.2_3
		
	SBCLASS8_3  db "RTC Controller",0
		
		PROGIF8.3_0   db " [Generic RTC]",0
		PROGIF8.3_1   db " [ISA-Compatible]",0
		
		PCISB15  dw PROGIF8.3_0,PROGIF8.3_1
		
	SBCLASS8_4  db "PCI Hot-Plug Controller",0
	SBCLASS8_5  db "SD Host controller",0
	SBCLASS8_6  db "IOMMU",0
	
	PCICL8 	dw SBCLASS8_0,SBCLASS8_1,SBCLASS8_2,SBCLASS8_3,SBCLASS8_4,SBCLASS8_5,SBCLASS8_6
	
CLASS9: db "Input Device: ",0
	
	SBCLASS9_0  db "Keyboard Controller",0
	SBCLASS9_1  db "Digitizer Pen",0
	SBCLASS9_2  db "Mouse Controller",0
	SBCLASS9_3  db "Scanner Controller",0
	SBCLASS9_4  db "Gameport Controller",0
		
		PROGIF9.4_0    db " [Generic]",0
		PROGIF9.4_10   db " [Extended]",0
	
		PCISB16  dw PROGIF9.4_0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PROGIF9.4_10
		
	PCICL9 	dw SBCLASS9_0,SBCLASS9_1,SBCLASS9_2,SBCLASS9_3,SBCLASS9_4
	
CLASSA: db "Docking Station: ",0

	SBCLASSA_0  db "Generic",0
	
	PCICLA 	dw SBCLASSA_0
	
CLASSB: db "Processor: ",0
	
	SBCLASSB_0   db "386",0
	SBCLASSB_1   db "486",0
	SBCLASSB_2   db "Pentium",0
	SBCLASSB_3   db "Pentium Pro",0
	SBCLASSB_10  db "Alpha",0
	SBCLASSB_20  db "PowerPC",0
	SBCLASSB_30  db "MIPS",0
	SBCLASSB_40  db "Co-Processor",0
	
	PCICLB 	dw SBCLASSB_0,SBCLASSB_1,SBCLASSB_2,SBCLASSB_3,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASSB_10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	        dw SBCLASSB_20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASSB_30,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASSB_40
	
CLASSC: db "Serial Bus: ",0

	SBCLASSC_0  db "FireWire (IEEE 1394) Controller",0
	
		PROGIFC.0_0    db " [Generic]",0
		PROGIFC.0_10   db " [OHCI]",0
		
		PCISB17  dw PROGIFC.0_0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PROGIFC.0_10
		
	SBCLASSC_1  db "ACCESS Bus Controller",0
	SBCLASSC_2  db "SSA",0
	SBCLASSC_3  db "USB Controller",0
	
		PROGIFC.3_0     db " [USB1.1: UHCI Controller]",0
		PROGIFC.3_10    db " [USB1.1: OHCI Controller]",0
		PROGIFC.3_20    db " [USB2.0: EHCI Controller]",0
		PROGIFC.3_30    db " [USB3.0: XHCI Controller]",0
		PROGIFC.3_80    db " [Unspecified]",0
		PROGIFC.3_FE    db " [USB Device (Not a host controller)]",0
		
		PCISB18  dw PROGIFC.3_0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PROGIFC.3_10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PROGIFC.3_20
		         dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PROGIFC.3_30
		         TIMES (0x80 - 0x30 - 1) dw 0
				 dw PROGIFC.3_80
				 TIMES (0xFE - 0x80 - 1) dw 0
				 dw PROGIFC.3_FE
				 
		
	SBCLASSC_4  db "Fibre Channel",0
	SBCLASSC_5  db "SMBus Controller",0
	SBCLASSC_6  db "InfiniBand Controller",0
	SBCLASSC_7  db "IPMI Interface",0
	
		PROGIFC.7_0  db " [SMIC]",0
		PROGIFC.7_1  db " [Keyboard Controller Style]",0
		PROGIFC.7_2  db " [Block Transfer]",0
		
		PCISB19  dw PROGIFC.7_0,PROGIFC.7_1,PROGIFC.7_2
		
	SBCLASSC_8  db "SERCOS Interface (IEC 61491)",0
	SBCLASSC_9  db "CANbus Controller",0
	
	PCICLC 	dw SBCLASSC_0,SBCLASSC_1,SBCLASSC_2,SBCLASSC_3,SBCLASSC_4,SBCLASSC_5,SBCLASSC_6,SBCLASSC_7,SBCLASSC_8,SBCLASSC_9
	
CLASSD: db "Wireless: ",0

	SBCLASSD_0   db "iRDA Compatible Controller",0
	SBCLASSD_1   db "Consumer IR Controller",0
	SBCLASSD_10  db "RF Controller",0
	SBCLASSD_11  db "Bluetooth Controller",0
	SBCLASSD_12  db "Broadband Controller",0
	SBCLASSD_20  db "Ethernet Controller (802.1a)",0
	SBCLASSD_21  db "Ethernet Controller (802.1b)",0
	
	PCICLD 	dw SBCLASSD_0,SBCLASSD_1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASSD_10,SBCLASSD_11,SBCLASSD_12,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASSD_20,SBCLASSD_21
	
CLASSE: db "Intelligent Controller: ",0

	SBCLASSE_0   db "I20",0
	
	PCICLE 	dw SBCLASSE_0
	
CLASSF: db "Satellite Communication: ",0

	SBCLASSF_0   db "Satellite TV Controller",0
	SBCLASSF_1   db "Satellite Audio Controller",0
	SBCLASSF_2   db "Satellite Voice Controller",0
	SBCLASSF_3   db "Satellite Data Controller",0
	
	PCICLF 	dw SBCLASSF_0,SBCLASSF_1,SBCLASSF_2,SBCLASSF_3
	
CLASS10: db "Encryption: ",0

	SBCLASS10_0    db "Network and Computing Encrpytion/Decryption",0
	SBCLASS10_10   db "Entertainment Encryption/Decryption",0
	
	PCICL10  dw SBCLASS10_0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASS10_10
	
CLASS11: db "Signal Processing: ",0
	
	SBCLASS11_0     db "DPIO Modules",0
	SBCLASS11_1     db "Performance Counters",0
	SBCLASS11_10    db "Communication Synchronizer",0
	SBCLASS11_20    db "Signal Processing Management",0
	
	PCICL11  dw SBCLASS11_0,SBCLASS11_1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASS11_10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SBCLASS11_20
	
CLASS12: db "Processing Accelerator",0

CLASS13: db "Non-Essential Instrumentation",0

;CLASS14_3F: times (0x3F - 0x14) db 0

CLASS40: db "Co-Processor",0

;CLASS41_FE: times (0xFE - 0x41) db 0

CLASSFF: db "Unassigned Class (Vendor specific)",0


OTHER   db "Other",0

; -----------------------------------------------------------------------------
;Configuration Mechanism One has two IO port rages associated with it.
;The address port (0xcf8-0xcfb) and the data port (0xcfc-0xcff).
;A configuration cycle consists of writing to the address port to specify which device and register you want to access and then reading or writing the data to the data port.

;ddress dd 10000000000000000000000000000000b
;          /\     /\      /\   /\ /\    /\
;        E    Res    Bus    Dev  F  Reg   0
; Bits
; 31		Enable bit = set to 1
; 30 - 24	Reserved = set to 0
; 23 - 16	Bus number = 256 options
; 15 - 11	Device/Slot number = 32 options
; 10 - 8	Function number = will leave at 0 (8 options)
; 7 - 2		Register number = will leave at 0 (64 options) 64 x 4 bytes = 256 bytes worth of accessible registers


%ENDIF

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++