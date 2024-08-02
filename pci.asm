; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                    DRIVER DE COMUNICAÇÃO PCI
;
;                     Kernel em Assembly x86
;                    Criado por Wender Francis
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE 	"Hardware/memory.lib"
%INCLUDE 	"Hardware/kernel.lib"

;[BITS 32]
;[ORG PCI]

;%IFDEF 	_PROTECTED_MODE
;	ALIGN	4
;	BITS 	32
;	SECTION protectedmode vstart=0x150000, valign=4
;%ELSE
;	[BITS 16]  ; Definir pra 32
;	[ORG  PCI]
;%ENDIF

ALIGN	4
BITS 	32
SECTION protectedmode vstart=0x150000, valign=4

%IFNDEF		__CONFPCI_ASM__
%DEFINE 	__CONFPCI_ASM__

PCI_ADDRESS		EQU	0x0CF8
PCI_DATA		EQU	0x0CFC
PCI_READ 		EQU 0x00
PCI_WRITE 		EQU 0x01

jmp 	Init_PCI
jmp 	Get_Class_Name
jmp 	Get_SubClass_Name
jmp 	Get_Interface_Name
jmp 	Get_Device_Name
jmp 	Get_Vendor_Name
jmp 	Get_Classes_Number
jmp 	PCI_Read_Word
jmp 	PCI_Write_Word
jmp 	PCI_Read_Dword
jmp 	PCI_Get_VendorID
jmp 	PCI_Get_DeviceID
jmp 	PCI_Check_All_Buses

Vendor 	dw 	0x0000
Device 	dw 	0x0000
pdata 	dd  0x00000000
PCI_bus db 	0x00
PCI_dev db 	0x00
PCI_fun db 	0x00

HeaderMain:  ; Main Header for all Devices, Size=16 bytes + 4
	.VendorID    dw 0
	.DeviceID    dw 0
	.Command     dw 0
	.Status      dw 0
	.RevisionID  db 0
	.ProgIF      db 0
	.SubClass    db 0
	.ClassCode   db 0
	.CacheLSize  db 0
	.LatTimer    db 0
	.HeadType    db 0
	.Bist        db 0
	.HeadAddress dd 0
	
HeaderType0:  ; (Common Header), size=48 bytes
	.BaseBAR0   dd 0
	.BaseBAR1   dd 0
	.BaseBAR2   dd 0
	.BaseBAR3   dd 0
	.BaseBAR4   dd 0
	.BaseBAR5   dd 0
	.CardBusCS  dd 0
	.SubSysVID  dw 0
	.SubSysID   dw 0
	.ExpROM     dd 0
	.CapPointer db 0
	.Reserved0  dw 0
	.Reserved1  db 0
	.Reserved2  dd 0
	.IntLine    db 0
	.IntPIN     db 0
	.MinGrant   db 0
	.MaxLatency db 0

HeaderType1:   ;  (PCI-to-PCI Bridge Header), Size=48 bytes
	.BaseBAR0       dd 0
	.BaseBAR1       dd 0
	.PrimaryBus     db 0
	.SecondaryBus   db 0
	.SubordinaryBus db 0
	.SecondLatency  db 0
	.IOBase         db 0
	.IOLimit        db 0
	.SecondStatus   dw 0
	.MemoryBase     dw 0
	.MemoryLimit    dw 0
    .PrefMemBase    dw 0
	.PrefMemLimit   dw 0
	.PrefMemBase32  dd 0
	.PrefMemLimit32 dd 0
	.IOBase16       dw 0
	.IOLimit16      dw 0
	.CapPointer     db 0
	.Reserved0      dw 0
	.Reserved1      db 0
	.ExpROMAddr     dd 0
	.IntLine        db 0
	.IntPIN         db 0
	.BridgeControl  dw 0
	
HeaderType2:  ; (PCI-to-CardBus Bridge Header), size=56 bytes
	.CardBusSocket   dd 0
	.OffsetCapList   db 0
	.Reserved        db 0
	.SecondaryStatus dw 0
	.PCIBusNumber    db 0
	.CardBusNumber   db 0
	.SubordBusNumber db 0
	.CardBusLatTimer db 0
	.MemoryBase0     dd 0
	.MemoryLimit0    dd 0
	.MemoryBase1     dd 0
	.MemoryLimit1    dd 0
	.IOBase0         dd 0
	.IOLimit0        dd 0
	.IOBase1         dd 0
	.IOLimit1        dd 0
	.InterruptLine   db 0
	.InterruptPIN    db 0
	.BridgeControl   dw 0
	.SubSysDeviceID  dw 0
	.SubSysVendorID  dw 0
	.CardLegacy16    dd 0
	

bus 	db 0
slot 	db 0
func 	db 0
offs 	db 0

PCIEnabled  db 0


Init_PCI:
	mov 	eax, 0x80000000		; Bit 31 set for 'Enabled'
	mov 	ebx, eax
	mov 	dx, PCI_ADDRESS
	out 	dx, eax
	in 		eax, dx
	xor 	edx, edx
	cmp 	eax, ebx
	sete 	dl				; Set byte if equal, otherwise clear
	mov 	byte [PCIEnabled], dl
	;call 	PCI_Check_All_Buses
	;call 	Scan_PCI_Devices
ret


Scan_PCI_Devices:
	mov 	ax, 0
	mov 	bx, 0
	mov 	dx, 0
	mov 	ecx, 255
scan_bus:
	push 	ecx
	
	mov 	bx, 0
	mov 	ecx, 32
	scan_dev:
		push 	ecx
		
		mov 	dx, 0
		mov 	ecx, 8
		scan_func:
			push	ecx
			
			push 	ax
	
			call 	Get_Classes_Number
			cmp 	ax, WORD [SaveClasses]
			je 		Skip_Store
			cmp 	ax, 0xFFFF
			je 		Skip_Store
			
			mov 	[SaveClasses], ax
		
			pop 	ax
			
			mov 	si, PCI_NAME
			call 	Print_String
			
			call 	Get_Class_Name
			call 	Print_String

			call 	Get_SubClass_Name
			call 	Print_String
			
			call 	Get_Device_Name
			call 	Print_String
			
			push 	ax
			call 	Break_Line
			pop 	ax
			
			jmp 	Jump_Skip
			
		Skip_Store:
			pop 	ax

		Jump_Skip:
			inc 	edx
			pop 	ecx
			dec 	ecx
			cmp 	ecx, 0
			jnz 	scan_func
		inc 	ebx
		pop 	ecx
		dec 	ecx
		cmp 	ecx, 0
		jnz 	scan_dev
	inc 	eax
	pop 	ecx
	dec 	ecx
	cmp 	ecx, 0
	jnz 	scan_bus
ret
SaveClasses  dw 0xFFFF
	
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
	
	and 	eax, 0xFF
	and 	ebx, 0xFF
	and 	ecx, 0xFF
	
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
	push 	edx
	and 	edx, 0x02
	shl 	edx, 3          ; multiplique por 8
	mov 	ecx, edx
	shr 	eax, cl
	and 	eax, 0xFFFF
	
	pop 	edx
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
	push 	eax
	push 	ebx
	push 	ecx
	push 	edx
	
	and 	eax, 0xFF
	and 	ebx, 0xFF
	and 	ecx, 0xFF
	
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
	pop 	eax
ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PCI_Read_Dword - Ler de um registro um dispositivo PCI
; IN:   AL  = Bus number
;		BL  = Device/Slot number
;		CL  = Function number
; 		DL  = Offset number
; OUT:	EAX = Register information
PCI_Read_Dword:
	push 	ebx
	push 	ecx
	push 	edx
	
	and 	eax, 0xFF
	and 	ebx, 0xFF
	and 	ecx, 0xFF
	
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
	je 		ReturnDevice
	
	cmp 	byte[PCIEnabled], 0
	jz 		Check_Mult_Func1
	
	; EXIBIR INFORMAÇÕES ----------------
	;call 	PCI_Show_Full
	;call 	Show_Name_Devices
	;call 	PCI_Get_Info
	; -----------------------------------
	
Check_Mult_Func1:
		
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
	
		cmp 	byte[PCIEnabled], 0
		jz 		Check_Mult_Func2
	
		; EXIBIR INFORMAÇÕES ----------------
		;call 	PCI_Show_Full
		;call 	Show_Name_Devices
		;call 	PCI_Get_Info
		; -----------------------------------
	
Check_Mult_Func2:
		call 	PCI_Check_Function
		
		inc 	cl
		jmp 	Loop_Check_Functions
	

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
	call 	PCI_Get_VendorID
	call 	PCI_Get_DeviceID
	call 	PCI_Get_Classes
	mov 	ax, word[Vendor]
	call 	Print_Hexa_Value16
	call 	OffsetSpacesHex
	mov 	ax, word[Device]
	call 	Print_Hexa_Value16
	call 	OffsetSpacesHex

	pop 	ax
	
	call 	Show_Name_Devices

ret

; -----------------------------------------------------------------------------
; PCI_Show_Full - Exibe Nomes de dispositivos na inicialização
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	None.
Show_Name_Devices:
	push 	bx
	push 	si
	
	mov 	[bus], al
	mov 	[slot], bl
	mov 	[func], cl
	
	call 	PCI_Get_Classes
	call 	PCI_Get_ProgIF
	
	mov 	esi, StrPCI
	call 	Print_String
	
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
	cmp 	si, 0
	jz 		Ret_Names
	mov 	bl, byte[SubClass]   
	shl 	bx, 1
	mov 	si, word[si + bx]   ; SI = PCISBx
	cmp 	si, 0
	jz 		Ret_Names
	mov 	bl, byte[ProgIF]
	shl 	bx, 1
	mov 	si, word[si + bx]   ; SI = PROGIFx.x_x
	
	call 	Print_String
	jmp 	Return_Name_Device
ShowOther:
	mov 	esi, OTHER
	call 	Print_String
Ret_Names:
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	call 	Get_Device_Name
	jc 		Return_Name_Device

	call 	Print_String
	
Return_Name_Device:
	mov 	esi, PCIChecked
	call 	Print_String
	
	call 	Break_Line
	
	;push 	ax
	;xor 	ax, ax
	;int 	0x16
	;pop 	ax
	
	pop 	si
	pop 	bx
ret

; ROTINAS DO USUÁRIO +++++++++
; -----------------------------------------------------------------------------
; Get_Device_Name - Retorna o nome do dispositivo baseado no ID
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	ESI = Endereço da String do Dispositivo.
Get_Device_Name:
	pushad
	call 	PCI_Get_VendorID
	mov 	eax, DWORD [PCI_Reg]
	mov 	esi, DevIDs
	xor 	ebx, ebx
	xor 	ecx, ecx
	mov 	cx, WORD [SizeDevID]
	shr 	cx, 2
Loop_DevID:
	cmp 	DWORD [esi], eax
	je 		Get_NameDev
	add 	esi, 4
	inc 	ebx
	loop 	Loop_DevID
	stc
	jmp 	Ret_GetDev
Get_NameDev:
	shl 	ebx, 2
	mov 	esi, Array_DevID
	mov 	esi, DWORD [esi + ebx]
	mov 	DWORD [AddrStr], esi
Ret_GetDev:
	popad
	mov 	esi, DWORD [AddrStr]
ret
AddrStr dd 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Get_Class_Name - Retorna o nome de Classe do dispositivo
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	ESI = Endereço da String do Dispositivo.

Get_Class_Name:
	pushad
	call 	PCI_Get_Classes
	xor 	ebx, ebx
	mov 	bl, BYTE [ClassCode]
	shl 	ebx, 1
	mov 	esi, ADDRCL
	mov 	si, WORD [esi + ebx]
	mov 	DWORD [AddrStr1], esi
	popad
	mov 	esi, DWORD [AddrStr1]
ret
AddrStr1  dd 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Get_SubClass_Name - Retorna o nome de SubClasse do dispositivo
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	ESI = Endereço da String do Dispositivo.

Get_SubClass_Name:
	pushad
	call 	PCI_Get_ClassCode
	call 	PCI_Get_SubClass
	xor 	ebx, ebx
	mov 	bl, BYTE [ClassCode]
	shl 	ebx, 1
	mov 	esi, SUBVEC
	mov 	si, WORD [esi + ebx]
	mov 	bl, BYTE [SubClass]
	cmp 	bl, 0x80
	je 		MoveOther
	shl 	ebx, 1
	mov 	si, WORD [esi + ebx]
	jmp 	ReturnSubClass
MoveOther:
	mov 	esi, OTHER
ReturnSubClass:
	mov 	DWORD [AddrStr2], esi
	popad
	mov 	esi, DWORD [AddrStr2]
ret
AddrStr2  dd 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Get_Interface_Name - Retorna o nome de Interface do dispositivo
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	ESI = Endereço da String do Dispositivo.

Get_Interface_Name:
	pushad
	call 	PCI_Get_ClassCode
	call 	PCI_Get_SubClass
	call 	PCI_Get_ProgIF
	xor 	ebx, ebx
	mov 	bl, BYTE [ClassCode]
	shl 	ebx, 1
	mov 	esi, PROGCL
	mov 	si, WORD [esi + ebx]   ; SI = SUBPIFx
	cmp 	si, 0xFFFF
	jz 		Ret_Intr_Error
	mov 	bl, BYTE [SubClass]   
	shl 	ebx, 1
	mov 	si, word[esi + ebx]      ; SI = PCISBx
	cmp 	si, 0xFFFF
	jz 		Ret_Intr_Error
	mov 	bl, BYTE [ProgIF]
	shl 	ebx, 1
	mov 	si, word[esi + ebx]      ; SI = PROGIFx.x_x
	jmp 	Ret_Intr_Name
Ret_Intr_Error:
	mov 	esi, 0xFFFFFFFF
Ret_Intr_Name:
	mov 	DWORD [AddrStr3], esi
	popad
	mov 	esi, DWORD [AddrStr3]
ret
AddrStr3  dd 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Get_Vendor_Name - Retorna o nome de fabricante do dispositivo
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	ESI = Endereço da String do Fabricante.

Get_Vendor_Name:
	pushad
	
	; TODO primeiro fazer todos os nomes de fabricantes,
	; Depois vir para esta rotina, igual as rotinas acima.
	
	popad
ret

; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Get_Classes_Number - Retorna o número de Classe e SubClasse
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Function
; OUT:	AX = Número de Classe e SubClasse
Get_Classes_Number:
	pushad
	
	call 	PCI_Get_Classes
	
	popad
	mov 	ax, WORD [Classes]
ret
; -----------------------------------------------------------------------------

	; Acesso das Strings de Interface -----------
; PROGCL  -> Índice das classes
; SUBPIFx -> Índice das subclasses
; PCISBx  -> Índice das Interfaces
; PROGIFx.x_x -> Endereço da String
;
; Acesso das Strings de SubClasses
; SUBVEC  -> Índice das Classes com vetor de SubClasses
; PCICLx  -> Índice das SubClasses dentro de uma Classe

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
; IN:   AX = DeviceID/Driver Model/Version
; OUT:	ESI = String device name
;		AL = bus
;		BL = device
;		CL = function
;	Registradores preservados
PCI_Check_All_Buses:
	pushad
	mov 	[DriverID], ax
	xor 	eax, eax
	xor 	ebx, ebx
	xor 	ecx, ecx
	xor 	edx, edx
	; EXIBIR INFORMAÇÕES ----------------
	;mov 	si, PCIListStr
	;call 	Print_String
	; -----------------------------------
	mov 	al, 0
	loop_all_buses1:
		cmp 	al, 255
		jb  	init_loop_bus
		jmp 	return_checkb
		
	init_loop_bus:
		mov 	bl, 0
	loop_all_buses2:
		cmp 	bl, 32
		jnb 	return_all_buses
	
		call 	PCI_Get_DeviceID
		push 	ax
		mov 	ax, [DriverID]
		cmp 	[Device], ax
		jz 		found_driver
		pop 	ax
		
		inc 	bl
		jmp 	loop_all_buses2
	
	found_driver:
		pop 	ax
		mov 	[PCI_bus], al
		mov 	[PCI_dev], bl
		mov 	[PCI_fun], cl
		call 	Get_Device_Name
		cmp 	esi, 0
		jz 		return_unknown
		jmp 	return_found
	return_all_buses:
		inc 	al
		jmp 	loop_all_buses1
		
return_unknown:
	popad
	mov 	esi, unknown_dev
	mov 	al, [PCI_bus]
	mov 	bl, [PCI_dev]
	mov 	cl, [PCI_fun]
	clc
ret
return_checkb:
	popad
	mov 	ax, 0xFFFF
	stc
ret
return_found:
	mov 	[addr_save], esi
	popad
	mov 	esi, [addr_save]
	mov 	al, [PCI_bus]
	mov 	bl, [PCI_dev]
	mov 	cl, [PCI_fun]
	clc
ret
addr_save 	 dd 0x00000000
DriverID	 dw 0x0000
unknown_dev  db "Unknown Device not implemented!",0
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
	;mov 	si, PCIListStr
	;call 	Print_String
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


; -----------------------------------------------------------------------------
; PCI_Get_Info - Retorna Todas as informações dos dispositivos
; IN:   AL  = Bus number
;		BL  = Device/Slot number
; 		CL  = Função
; OUT:	ESI  = Ponteiro para estrutura Header do dispositivo
PCI_Get_Info:
	pushad
	
	mov 	[bus], al
	mov 	[slot], bl
	mov 	[func], cl
	mov 	edi, HeaderMain
	xor 	edx, edx
	mov 	ecx, 4
	Get_Header1:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		mov 	WORD [edi + ebx], ax
		pop 	cx
		pop 	bx
		add 	dl, 2
		loop 	Get_Header1
	mov 	ecx, 4
	Get_Header2:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		mov 	BYTE [edi + ebx], al
		mov 	BYTE [edi + ebx + 1], ah
		pop 	bx
		pop 	cx
		add 	dl, 2
		loop 	Get_Header2
	
	cmp 	WORD[HeaderMain.VendorID], 0xFFFF
	je 		DeviceNoExist
		
	mov 	al, BYTE [HeaderMain.HeadType]
	and 	al, 0x03
	cmp 	al, 0x00
	je 		Get_Info1
	cmp 	al, 0x01
	je 		Get_Info2
	cmp 	al, 0x02
	je 		Get_Info3
	jmp 	DeviceNoExist

Get_Info1:
	mov 	edi, HeaderType0
	mov 	DWORD [HeaderMain.HeadAddress], edi
	mov 	ecx, 7
	mov 	edx, 0x10
	
	loop_get_info1:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	eax, DWORD [PCI_Reg]
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	DWORD [edi + ebx], eax
		pop 	bx
		pop 	cx
		add 	dl, 4
		loop 	loop_get_info1
		
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	eax, DWORD [PCI_Reg]
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	WORD [edi + ebx], ax
		shl 	eax, 16
		add 	ebx, 2
		mov 	WORD [edi + ebx], ax
		
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		add 	dl, 4
		call 	PCI_Read_Word
		mov 	eax, DWORD [PCI_Reg]
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	DWORD [edi + ebx], eax
		
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		add 	dl, 4
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	BYTE [edi + ebx], al
		
		add 	dl, 8
		mov 	ecx, 2
	loop_get_info1.1:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	BYTE [edi + ebx], al
		mov 	BYTE [edi + ebx + 1], ah
		pop 	bx
		pop 	cx
		add 	dl, 2
		loop 	loop_get_info1.1
		
		jmp 	RetGetInfo

Get_Info2:
	mov 	edi, HeaderType1
	mov 	DWORD [HeaderMain.HeadAddress], edi
	mov 	ecx, 2
	mov 	edx, 0x10
	
	loop_get_info2:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	eax, DWORD [PCI_Reg]
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	DWORD [edi + ebx], eax
		pop 	bx
		pop 	cx
		add 	dl, 4
		loop 	loop_get_info2
		
		mov 	ecx, 3
	loop_get_info2.1:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	BYTE [edi + ebx], al
		mov 	BYTE [edi + ebx + 1], ah
		pop 	bx
		pop 	cx
		add 	dl, 2
		loop 	loop_get_info2.1
		
		mov 	ecx, 5
	loop_get_info2.2:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	WORD [edi + ebx], ax
		pop 	bx
		pop 	cx
		add 	dl, 2
		loop 	loop_get_info2.2
		
		mov 	ecx, 2
	loop_get_info2.3:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	eax, DWORD [PCI_Reg]
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	DWORD [edi + ebx], eax
		pop 	bx
		pop 	cx
		add 	dl, 4
		loop 	loop_get_info2.3
		
		mov 	ecx, 2
	loop_get_info2.4:
		push 	cx
		push 	bx
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	WORD [edi + ebx], ax
		pop 	bx
		pop 	cx
		add 	dl, 2
		loop 	loop_get_info2.4
		
		mov 	al, [bus]
		mov 	bl, [slot]
		mov 	cl, [func]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	BYTE [edi + ebx], al
		
		add 	dl, 4
		mov 	al, [bus]
		mov 	bl, [slot]
		call 	PCI_Read_Word
		mov 	eax, DWORD [PCI_Reg]
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	DWORD [edi + ebx], eax
		
		add 	dl, 4
		mov 	al, [bus]
		mov 	bl, [slot]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	BYTE [edi + ebx], al
		mov 	BYTE [edi + ebx + 1], ah
		
		add 	dl, 2
		mov 	al, [bus]
		mov 	bl, [slot]
		call 	PCI_Read_Word
		mov 	ebx, edx
		sub 	ebx, 0x10
		mov 	WORD [edi + ebx], ax
		
		jmp 	RetGetInfo
		
Get_Info3:
	mov 	edi, HeaderType2
	mov 	DWORD [HeaderMain.HeadAddress], edi
	
	mov 	edx, 0x10
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	call 	PCI_Read_Word
	mov 	eax, DWORD [PCI_Reg]
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	DWORD [edi + ebx], eax
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	add 	dl, 4
	call 	PCI_Read_Word
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	BYTE [edi + ebx], al
	mov 	BYTE [edi + ebx + 1], ah
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	add 	dl, 2
	call 	PCI_Read_Word
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	WORD [edi + ebx], ax
	
	mov 	ecx, 2
loop_get_info3:
	push 	cx
	push 	bx
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	add 	dl, 2
	call 	PCI_Read_Word
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	BYTE [edi + ebx], al
	mov 	BYTE [edi + ebx + 1], ah
	pop 	bx
	pop 	cx
	loop 	loop_get_info3
	
	add 	dl, 2
	mov 	ecx, 8
loop_get_info3.1:
	push 	cx
	push 	bx
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	call 	PCI_Read_Word
	mov 	eax, DWORD [PCI_Reg]
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	DWORD [edi + ebx], eax
	pop 	bx
	pop 	cx
	add 	dl, 4
	loop 	loop_get_info3.1
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	call 	PCI_Read_Word
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	BYTE [edi + ebx], al
	mov 	BYTE [edi + ebx + 1], ah
	add 	dl, 2
	
	mov 	ecx, 3
loop_get_info3.2:
	push 	cx
	push 	bx
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	call 	PCI_Read_Word
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	WORD [edi + ebx], ax
	pop 	bx
	pop 	cx
	add 	dl, 2
	loop 	loop_get_info3.2
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	call 	PCI_Read_Word
	mov 	eax, DWORD [PCI_Reg]
	mov 	ebx, edx
	sub 	ebx, 0x10
	mov 	DWORD [edi + ebx], eax
	
	jmp 	RetGetInfo

DeviceNoExist:
	stc
	mov 	si, MsgNoDevice
	call 	Print_String
RetGetInfo:
	popad
	mov 	esi, DWORD [HeaderMain.HeadAddress]
ret

MsgNoDevice  db "This PCI Device dont Exist!",0
PCI_NAME 	 db "PCI: ",0

; -----------------------------------------------------------------------------

	
; Acesso das Strings de Interface -----------
; PROGCL  -> Índice das classes
; SUBPIFx -> Índice das subclasses
; PCISBx  -> Índice das Interfaces
;
; Acesso das Strings de SubClasses
; SUBVEC  -> Índice das Classes com vetor de SubClasses
; PCICLx  -> Índice das SubClasses dentro de uma Classe
		
	 
; ----------------------------------------
; IDs de Dispositivos
DevIDs:  
	; Oracle VirtualBox
	; ----------------------------------------------------------------------------------------
	dd 0x12378086, 0x70008086, 0x71118086, 0xBEEF80EE, 0x20001022, 0xCAFE80EE, 0x003F106B, 0x71138086, 0x28298086, 0x00301000, 0x00541000
	; ----------------------------------------------------------------------------------------
	
	; Real Hardware on Computer
	; ----------------------------------------------------------------------------------------
	dd 0x03641106, 0x13641106, 0x23641106, 0x33641106, 0x43641106, 0x53641106, 0x63641106, 0x73641106, 0xB1981106, 0x33711106, 0xA3641106
	dd 0xC3641106, 0x05911106, 0x05711106, 0x30381106, 0x31041106, 0x33371106, 0x287E1106, 0x30651106, 0x337B1106, 0x337A1106, 0x32881106
	dd 0x816910EC, 0x816810EC, 0x816110EC, 0x813610EC, 0x43001186 
	; ----------------------------------------------------------------------------------------
SizeDevID  dw ($-DevIDs)
	
Array_DevID dd ID1, ID2, ID3, ID4, ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14, ID15, ID16, ID17
            dd ID18, ID19, ID20, ID21, ID22, ID23, ID24, ID25, ID26, ID27, ID28, ID29, ID30, ID31, ID32, ID33
			dd ID34, ID35, ID36, ID37, ID38
		
		 
	; Oracle VirtualBox
	; ----------------------------------------------------------------------------------------
ID1		db " (440FX - 82441FX PMC [Natoma])",0                                 ; Intel Corporation
ID2		db " (82371SB PIIX3 ISA [Natoma/Triton II])",0                         ; Intel Corporation
ID3		db " (82371AB/EB/MB PIIX4 IDE)",0                                      ; Intel Corporation
ID4		db " (VirtualBox Graphics Adapter)",0                                  ; InnoTek Systemberatung GmbH
ID5		db " (79c970 [PCnet32 LANCE])",0                                       ; Advanced Micro Devices, Inc. [AMD]
ID6		db " (VirtualBox Guest Service)",0                                     ; InnoTek Systemberatung GmbH
ID7		db " (KeyLargo/Intrepid USB)",0                                        ; Apple Inc.
ID8		db " (82371AB/EB/MB PIIX4 ACPI)",0                                     ; Intel Corporation
ID9		db " (82801HM/HEM (ICH8M/ICH8M-E) SATA Controller [AHCI mode])",0      ; Intel Corporation
ID10	db " (53c1030 PCI-X Fusion-MPT Dual Ultra320 SCSI)",0                  ; Broadcom / LSI
ID11	db " (SAS1068 PCI-X Fusion-MPT SAS)",0                                 ; Broadcom / LSI
	; ----------------------------------------------------------------------------------------
	
	; Real Hardware on Computer
	; ----------------------------------------------------------------------------------------
ID12    db " (CN896/VN896/P4M900)",0                         ; Via Technologies, Inc.
ID13    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID14    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID15    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID16    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID17    db " (CN896/VN896/P4M900 I/O APIC Interrupt)",0     ; Via technologies, Inc.
ID18    db " (CN896/VN896/P4M900 Security Device)",0         ; Via technologies, Inc.
ID19    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID20    db " (VT8237/CX700/VX700-Series)",0                  ; Via technologies, Inc.
ID21    db " (CN896/VN896/P4M900 [Chrome 9 HC])",0           ; Via technologies, Inc.
ID22    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID23    db " (CN896/VN896/P4M900)",0                         ; Via technologies, Inc.
ID24    db " (VT8237A SATA 2-Port)",0                        ; Via technologies, Inc.
ID25    db " (VT82C586A/B/VT82C686/A/B/VT823x/A/C PIPC Bus Master IDE)",0     ; Via technologies, Inc.
ID26    db " (VT82xx/62xx/VX700/8x0/900)",0                  ; Via technologies, Inc.
ID27    db " (EHCI-Compliant Host-Controller)",0             ; Via technologies, Inc.
ID28    db " (VT8237A PCI to ISA Bridge)",0                  ; Via technologies, Inc.
ID29    db " (VT8237/8251 Ultra VLINK Controller)",0         ; Via technologies, Inc.
ID30    db " (VT6102/VT6103 [Rhine-II])",0                   ; Via technologies, Inc.
ID31    db " (VT8237A Host Bridge)",0                        ; Via technologies, Inc.
ID32    db " (VT8237A PCI to PCI Bridge)",0                  ; Via technologies, Inc.
ID33    db " (VX900/VT8xxx High Definition Audio)",0         ; Via technologies, Inc.

ID34 	db "Realtek PCI GbE Family Controller",0			 ; Realtek
ID35 	db "Realtek PCIe GbE Family Controller",0			 ; Realtek
ID36 	db "Realtek PCIe GbE Family Controller",0			 ; Realtek
ID37 	db "Realtek PCIe FE Family Controller",0			 ; Realtek
ID38 	db "Realtek PCI GbE Family Controller",0			 ; D-LINK
	; ----------------------------------------------------------------------------------------
   
PCIListStr:
		db "KiddieOS PCI List",13,10,13,10
		db "BUS     |DEV     |FUNC    |VENDOR  |DEVICE  |DEVICE CLASS NAME   ",13,10,0
		
PCIListStr1:
		db "KiddieOS PCI List",13,10,13,10
		db "|VENDOR |DEVICE  |DEVICE CLASS NAME   ",13,10,0		
		
StrPCI  db "[PCI]",0
PCIChecked db " Verified!",0
    
		 
PCI_Names:		
CLASS0 db "Unclassified: ",0
	
	SBCLASS0_0 db "Non-VGA-Compatible Unclassified Device",0
	SBCLASS0_1 db "VGA-Compatible Unclassified Device",0
	
	PCICL0  dw SBCLASS0_0, SBCLASS0_1

CLASS1 db  "Mass Storage: ",0
	
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
	
CLASS2 db "Network: ",0

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
	
CLASS3 db "Display: ",0

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

	SBCLASS10_0    db "Network and Computing Encryption/Decryption",0
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

     

SUBVEC  dw PCICL0, PCICL1, PCICL2, PCICL3, PCICL4, PCICL5, PCICL6, PCICL7, PCICL8
        dw PCICL9, PCICLA, PCICLB, PCICLC, PCICLD, PCICLE, PCICLF, PCICL10, PCICL11
		
ADDRCL  dw CLASS0,CLASS1,CLASS2,CLASS3,CLASS4,CLASS5,CLASS6,CLASS7 
        dw CLASS8,CLASS9,CLASSA,CLASSB,CLASSC,CLASSD,CLASSE,CLASSF
		dw CLASS10, CLASS11, CLASS12, CLASS13
		;TIMES (0x3F - 0x14) dw 0x0000
		dw CLASS40
		;TIMES (0xFE - 0x41) dw 0x0000
		dw CLASSFF		
		
SUBPIF1  dw 0xFFFF,PCISB0,0xFFFF,0xFFFF,0xFFFF,PCISB1,PCISB2,PCISB3,PCISB4,0xFFFF                      ; Para SubClasses da Classe 1
SUBPIF3  dw PCISB5,0xFFFF,0xFFFF,0xFFFF                                                                ; Para SubClasses da Classe 3
SUBPIF6  dw 0xFFFF,0xFFFF,0xFFFF,0xFFFF,PCISB6,0xFFFF,0xFFFF,0xFFFF,PCISB7,PCISB8,0xFFFF,0xFFFF        ; Para SubClasses da Classe 6
SUBPIF7  dw PCISB9,PCISB10,0xFFFF,PCISB11,0xFFFF,0xFFFF,0xFFFF                                         ; Para SubClasses da Classe 7
SUBPIF8  dw PCISB12,PCISB13,PCISB14,PCISB15,0xFFFF,0xFFFF,0xFFFF,0xFFFF                                ; Para SubClasses da Classe 8
SUBPIF9  dw 0xFFFF,0xFFFF,0xFFFF,0xFFFF,PCISB16,0xFFFF                                                 ; Para SubClasses da Classe 9
SUBPIFC  dw PCISB17,0xFFFF,0xFFFF,PCISB18,0xFFFF,0xFFFF,0xFFFF,PCISB19,0xFFFF,0xFFFF,0xFFFF            ; Para SubClasses da Classe 12

PROGCL   dw 0xFFFF,SUBPIF1,0xFFFF,SUBPIF3,0xFFFF,0xFFFF,SUBPIF6,SUBPIF7,SUBPIF8                        ; Acessada por Classes
         dw SUBPIF9,0xFFFF,0xFFFF,SUBPIFC,0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF			 
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

END_OF_FILE:
	db 'EOF'
	
%ENDIF

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++