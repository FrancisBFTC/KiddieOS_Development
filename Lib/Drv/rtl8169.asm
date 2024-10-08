; =============================================================================
; Realtek Driver

; =============================================================================


; TODO: Wender, essa funcao do do codigo C para setar o Hander no IDT
;extern fnvetors_handler
;extern printHex
;extern puts

%INCLUDE "Hardware/iodevice.lib"

re_interrupt_string db 10,"[RTL81XX] Interrupt 0x",0
hexa_buffer db "    ",0x0D,0


; Command Register (Offset 0037h, R/W)
RTL8169_BIT_RST		equ (1 << 4)		; Reset
RTL8169_BIT_RE		equ (1 << 3)		; Receiver Enable
RTL8169_BIT_TE		equ (1 << 2)		; Transmitter Enable


;TX_DESCRIPTOR		equ 0x300000
;RX_DESCRIPTOR		equ 0x301000
;TX_DESCRIPTOR_COUNT equ 4
;RX_DESCRIPTOR_COUNT equ 32
;RX_BASE_ADDR 		equ 0x302000
;TX_BASE_ADDR 		equ RX_BASE_ADDR+(8192*(RX_DESCRIPTOR_COUNT+1))

RX_BASE_ADDR 		equ 0x300000
TX_BASE_ADDR 		equ RX_BASE_ADDR+(8192*(RX_DESCRIPTOR_COUNT+1))

NetIOAddress	dd 0x00000000
NetIRQ			db 0x00
NetMAC			dq 0x0000000000000000
; TODO: Aqui vamos acrescentar algumas variaveis
ReVendorID		dw 0
ReDeviceID		dw 0
RePCIBus		db 0
RePCISlot		db 0
RePCIFunc		db 0
ReChipset		db 0
ReIntStatus		dw 0

ReRxCur 		dd 0
ReTxCur 		dd 0

driver_support_table:
	dw 0x00
	dw 0x8169
	dw 0x8168
	dw 0x8161
	dw 0x8136
	dw 0x4300
driver_support.size equ ($-driver_support_table)

; 1024 descriptores TX máximos (16384 bytes = 0x3FFF) - Normal Priority
; Aqui vamos alinhar o codigo em 4-Kilobytes essa estrutura
align 4096
TX_DESCRIPTOR:
	.flags			dd 0x00000000
	.vlan			dd 0
	.low_buffer		dd 0 ;Buffer Low
	.high_buffer	dd 0 ;Buffer Upper
TX_DESCRIPTOR_SIZE 	equ ($-TX_DESCRIPTOR) ; TODO: Wender, aqui deve ser TX_DESCRIPTOR
TX_DESCRIPTOR_COUNT equ 4
	times (TX_DESCRIPTOR_SIZE*(TX_DESCRIPTOR_COUNT - 1)) DB 0
	
; 1024 descriptores RX máximos (16384 bytes = 0x3FFF)
; Aqui tambem alinhamos em 4-Kilobytes essa estrutura
align 4096
RX_DESCRIPTOR:
	.flags			dd 0x00000000
	.vlan			dd 0
	.low_buffer		dd 0 ;Buffer Low
	.high_buffer	dd 0 ;Buffer Upper
RX_DESCRIPTOR_SIZE 	equ ($-RX_DESCRIPTOR)
RX_DESCRIPTOR_COUNT equ 32
	times (RX_DESCRIPTOR_SIZE*(RX_DESCRIPTOR_COUNT - 1)) DB 0

align 4	
chipset_mac_versions:
	dd	0x00800000, 3
	dd	0x04000000, 3
	dd	0x10000000, 4
	dd	0x18000000, 5
	dd	0x98000000, 6
	dd	0x34000000, 11
	dd	0xB4000000, 11
	dd	0x34200000, 12
	dd	0xB4200000, 12
	dd	0x34300000, 13
	dd	0xB4300000, 13
	dd	0x34900000, 14
	dd	0x24900000, 14
	dd	0x34A00000, 15
	dd	0x24A00000, 15
	dd	0x34B00000, 16
	dd	0x24B00000, 16
	dd	0x34C00000, 17
	dd	0x24C00000, 17
	dd	0x34D00000, 18
	dd	0x24D00000, 18
	dd	0x34E00000, 19
	dd	0x24E00000, 19
	dd	0x30000000, 21
	dd	0x38000000, 22
	dd	0x38500000, 23
	dd	0xB8500000, 23
	dd	0x38700000, 23
	dd	0xB8700000, 23
	dd	0x3C000000, 24
	dd	0x3C200000, 25
	dd	0x3C400000, 26
	dd	0x3C900000, 27
	dd	0x3CB00000, 28
	dd	0x28100000, 31
	dd	0x28200000, 32
	dd	0x28300000, 33
	dd	0x2C100000, 36
	dd	0x2C200000, 37
	dd	0x2C800000, 38
	dd	0x2C900000, 39
	dd	0x24000000, 41
	dd	0x40900000, 42
	dd	0x40A00000, 43
	dd	0x40B00000, 43
	dd	0x40C00000, 43
	dd	0x48000000, 50
	dd	0x48100000, 51
	dd	0x48800000, 52
	dd	0x48800000, 52
	dd	0x44000000, 53
	dd	0x44800000, 54
	dd	0x44900000, 55
	dd	0x4C000000, 56
	dd	0x4C100000, 57
	dd	0x50800000, 58
	dd	0x50900000, 59
	dd	0x5C800000, 60
	dd	0x50000000, 61
	dd	0x50100000, 62
	dd	0x50200000, 67
	dd	0x28800000, 63
	dd	0x28900000, 64
	dd	0x28A00000, 65
	dd	0x28B00000, 66
	dd	0x54000000, 68
	dd	0x54100000, 69
chipset_mac_versions.size equ ($-chipset_mac_versions)


; -----------------------------------------------------------------------------
;	Realtek PCI
;	IN:	
;		EAX = Offset
; 		EBX = Value
;	OUT:
;		EAX

RePCIReadDoword:
	xor 	ecx, ecx
	mov 	cl, byte[RePCIBus]
	shl		ecx, 16
	mov		ch, byte[RePCISlot]
	shl		ch, 11
	or		ch, byte[RePCIFunc]
	mov		cl, al ; Offset
	mov		eax, ecx
	or 		eax, 0x80000000
	mov 	dx, 0x0CF8
	out 	dx, eax
	mov 	dx, 0x0CFC
    in 		eax, dx
ret

RePCIWriteDoword:
	xor 	ecx, ecx
	mov 	cl, byte[RePCIBus]
	shl		ecx, 16
	mov		ch, byte[RePCISlot]
	shl		ch, 11
	or		ch, byte[RePCIFunc]
	mov		cl, al ; Offset
	mov		eax, ecx
	or 		eax, 0x80000000
	mov 	dx, 0x0CF8
	out 	dx, eax
	mov 	dx, 0x0CFC
	mov 	eax, ebx ; Value
    out 	dx, eax
ret

; -----------------------------------------------------------------------------
;	Realtek Command
;	IN:	
;		EAX = Offset
; 		EBX = Value
;	OUT:
;		EAX
ReWriteCommandByte:
	mov 	edi, dword[NetIOAddress]
	mov 	byte[edi + eax], bl 
ret
ReWriteCommandWord:
	mov 	edi, dword[NetIOAddress]
	mov 	word[edi + eax], bx 
ret
ReWriteCommandDword:
	mov 	edi, dword[NetIOAddress]
	mov 	dword[edi + eax], ebx 
ret
ReReadCommandByte:
	mov		ebx, eax
	xor 	eax, eax
	mov 	edi, dword[NetIOAddress]
	mov 	al, byte[edi + ebx] 
ret
ReReadCommandWord:
	mov		ebx, eax 
	xor 	eax, eax
	mov 	edi, dword[NetIOAddress]
	mov 	ax, word[edi + ebx] 
ret
ReReadCommandDword:
	mov		ebx, eax 
	xor 	eax, eax
	mov 	edi, dword[NetIOAddress]
	mov 	eax, dword[edi + ebx] 
ret

; -----------------------------------------------------------------------------
; Initialize a Realtek 81XX NIC
;  IN:	BL  = Bus number of the Realtek device
;  		CL  = Device/Slot number of the Realtek device
;		AL  = Function number of the Realtek device
;global os_net_rtl8169_init
os_net_rtl8169_init:
	; TODO: Aqui vamos salvar os valor do espaço de configuracao PCI
	mov byte[RePCIBus], bl
	mov byte[RePCISlot], cl
	shr eax, 16
	mov byte[RePCIFunc], al

	; Get PCI Vendor ID and Device ID
	mov		eax, 0x00
	call 	RePCIReadDoword
	mov 	word[ReVendorID], ax
	shr 	eax, 16
	mov 	word[ReDeviceID], ax
	
	call 	rtl8169_check_support
	cmp		ax, 0
	je 		abort_driver

	; Get PCI Read Memory IO
	mov		eax, 0x18
	call 	RePCIReadDoword
	and		eax, 0xFFFFFFF0
	mov 	dword[NetIOAddress], eax

	; Get PCI Read Interrupt
	mov		eax, 0x3C
	call 	RePCIReadDoword
	mov 	[NetIRQ], al

	; Enable o PCI Busmastering DMA
	mov		eax, 0x04
	call 	RePCIReadDoword
	mov 	ebx, eax
	or		ebx, 0x6
	mov		eax, 0x04
	call 	RePCIWriteDoword

	; Set IRQ Handler
	;mov		edi, fnvetors_handler
	;xor		ebx, ebx
	;mov 	bl, byte[NetIRQ]
	;mov		eax, rtl8169_handler
	;mov		dword[edi + (ebx*4)], eax
	xor 	eax, eax
	mov 	al, [NetIRQ]
	Handler_Register(eax, rtl8169_handler)

	; Soft reset the chip
	mov		eax, 0x37
	mov 	ebx, RTL8169_BIT_RST
	call	ReWriteCommandByte
ReResetLabel:
	mov		eax, 0x37
	call	ReReadCommandByte
	test	al, RTL8169_BIT_RST
	; TODO recomendavel udelay(10)
	jnz ReResetLabel

	; Identify chip attached to board
	call	rtl8169_check_mac_version

	; get mac address
	call 	rtl8169_get_mac_address

	; Realtek unlock
	mov		eax, 0x50
	mov 	ebx, 0xC0
	call	ReWriteCommandByte

	; RTL-8169sb/8110sb or previous version
    ; Enable transmit and receive
	cmp 	byte[ReChipset], 5
	jg	ReNoEnableLabel
	mov		eax, 0x37
	mov 	ebx, (RTL8169_BIT_RE | RTL8169_BIT_TE)
	call	ReWriteCommandByte
ReNoEnableLabel:	

	; EarlyTxThres
    ; TxMaxSize Jumbo
	mov		eax, 0xEC
	mov		ebx, 0x40 -1
	call	ReWriteCommandByte
	
	; RxMaxSize
	mov		eax, 0xDA
	mov		ebx, 8192 -1
	call	ReWriteCommandWord

	; Set Rx Config register
	mov 	eax, 0x44
	call	ReReadCommandDword
	and		eax, 0xff7e1880
	mov 	ebx, (7 << 13 | 6 << 8 | 0xf)
	or		ebx, eax
	mov 	eax, 0x44
	call	ReWriteCommandDword

	; Set the initial TX configuration
    ; Set DMA burst size and Interframe Gap Time 
	mov		ebx, (3 << 24 | 6 << 8)
	mov 	eax, 0x40
	call	ReWriteCommandDword

	; Set TX and RX Buffer
	mov		ebx, TX_DESCRIPTOR
	mov 	eax, 0x20
	call	ReWriteCommandDword
	mov		ebx, 0
	mov 	eax, 0x24
	call	ReWriteCommandDword

	call 	rtl8169_setup_rx_desc
	mov		ebx, RX_DESCRIPTOR
	mov 	eax, 0xE4
	call	ReWriteCommandDword
	mov		ebx, 0
	mov 	eax, 0xE8
	call	ReWriteCommandDword

	; RTL-8169sc/8110sc or later version
	; Enable transmit and receive
	cmp 	byte[ReChipset], 5
	jl	ReIsEnableLabel
	mov		eax, 0x37
	mov 	ebx, (RTL8169_BIT_RE | RTL8169_BIT_TE)
	call	ReWriteCommandByte
ReIsEnableLabel:

	; RxMissed
	mov		ebx, 0
	mov 	eax, 0x4C
	call	ReWriteCommandDword

	; no early-rx interrupts
	mov 	eax, 0x5c
	call	ReReadCommandWord
	and		eax, 0xF000
	mov		ebx, eax
	mov 	eax, 0x5c
	call	ReWriteCommandWord

	; Timerint
	mov		ebx, 0
	mov 	eax, 0x58
	call	ReWriteCommandDword

	; Enable interrupts
	mov 	ebx, (0x8000 | 0x4000 | 0x2000 | 0x0040 | 0x0020 | 0x0010 | 0x0008 | 0x0002 | 0x0001)
	mov 	eax, 0x3C
	call	ReWriteCommandDword


	; Realtek lock
	mov		eax, 0x50
	mov 	ebx, 0x00
	call	ReWriteCommandByte

	; Recomendado udelay(10);
ret

abort_driver:
ret

rtl8169_check_support:
	mov 	esi, driver_support_table
	mov 	eax, driver_support.size  ; TODO: Wender, aqui é necessario dividir por 2bytes 
	mov		ecx, 2
	xor		edx, edx
	div		ecx
	mov		ecx, eax
loop_check:
	mov		ax, word[esi]
	cmp 	ax, word[ReDeviceID]
	je 		found_supported
	add		esi, 2
	loop 	loop_check
	xor 	eax, eax
found_supported:
ret

rtl8169_get_mac_address:
	mov 	eax, 0x00
	call	ReReadCommandDword
	mov 	dword[NetMAC], eax
	mov 	eax, 0x04
	call	ReReadCommandWord
	mov 	word[NetMAC + 4], ax
ret

rtl8169_check_mac_version:
	mov		eax, 0x40
	call	ReReadCommandDword
	and 	eax, 0xFCF00000
	
	push 	eax
	mov 	esi, chipset_mac_versions
	mov 	eax, chipset_mac_versions.size ; TODO: Wender, aqui é necessario dividir por 8bytes
	mov		ecx, 8
	xor		edx, edx
	div		ecx
	mov		ecx, eax
	pop 	eax
check_mac:
	cmp 	eax, [esi]
	je 		set_chipset
	add 	esi, 8
	loop 	check_mac
	mov 	byte[ReChipset], 0x69
	ret
	
set_chipset:
	mov 	eax, [esi+4]
	mov 	[ReChipset], eax
ret


; Set the flags on the RCS
rtl8169_setup_rx_desc:
	mov 	ecx, RX_DESCRIPTOR_COUNT
	mov 	edi, RX_DESCRIPTOR
	mov 	ebx, RX_BASE_ADDR
setup_rx_desc:
	mov		dword[edi], ( 1 << 31 | 8192) ; OWN
	mov		dword[edi + 4], 0
	mov		dword[edi + 8], ebx
	mov		dword[edi + 12], 0
	add		edi, 16
	add		ebx, 8192
	loop 	setup_rx_desc
	sub		edi, 16
	mov		eax, dword[edi]
	or		eax, 1 << 30		; EOR
	mov		dword[edi], eax
ret


ReRecievePackage:
	mov 	edi, RX_DESCRIPTOR
	mov		eax, dword[ReRxCur]
	mov		ebx, 16
	mul		ebx
	add		edi, eax

	test	dword[edi], (1 << 31)	; OWN
	jnz		ReNoOWN

	;-------------------------
	; TODO: Wender, aqui podemos ler os dados no Buffer do RX
	; Outra opção é copiar os dados do Buffer noutra área
	;-------------------------

	mov		eax, dword[edi]
	or		eax, (1 << 31)  ; Set OWN
	mov		dword[edi], eax

	mov		eax, dword[ReRxCur]
	add		eax, 1
	xor 	edx, edx
	mov		ecx, RX_DESCRIPTOR_COUNT
	div		ecx
	mov		dword[ReRxCur], edx
	jmp ReRecievePackage
ReNoOWN:
ret

; Handler IRQ
rtl8169_handler:
	mov		eax, 0x3E
	call	ReReadCommandWord
	mov		[ReIntStatus], ax

	;----------------------------------
	;mov		esi, re_interrupt_string
	;push	esi
	;call 	puts
	;pop 	esi

	;mov		esi, dword[ReIntStatus]
	;push	esi
	;call 	printHex
	;pop 	esi
	;--------------------------------
	mov		esi, re_interrupt_string
	Printz(0x02, esi)
	Get_Hexa16([ReIntStatus], hexa_buffer)
	Printz(0x05, hexa_buffer)

	test	word[ReIntStatus], 0x20
	jnz		ReIntLinkChange

	test	word[ReIntStatus], 0x01
	jnz		ReIntReceive

	test	word[ReIntStatus], 0x04
	jnz		ReIntTransmit

	; Link Change
ReIntLinkChange:
	jmp EndInt

	; Receive
ReIntReceive:
	call	ReRecievePackage
	jmp EndInt

	; Transmit
ReIntTransmit:
	jmp EndInt
EndInt:
	mov 	bx, [ReIntStatus]
	mov		eax, 0x3E
	call	ReWriteCommandWord
ret