; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; Realtek 8169 NIC. http://wiki.osdev.org/RTL81XX
; =============================================================================

%INCLUDE "Hardware/iodevice.lib"

; ------------------------------------------------------------------------------------------
; PCI Driver Address Functions
PCI_ADDR 		 	equ  0x150000		; PCI Driver base

Init_PCI			equ PCI_ADDR+(5*0)
Get_Class_Name		equ PCI_ADDR+(5*1)
Get_SubClass_Name	equ PCI_ADDR+(5*2)
Get_Interface_Name	equ PCI_ADDR+(5*3)
Get_Device_Name		equ PCI_ADDR+(5*4)
Get_Vendor_Name		equ PCI_ADDR+(5*5)
Get_Classes_Number	equ PCI_ADDR+(5*6)
PCI_Read_Word		equ PCI_ADDR+(5*7)
PCI_Write_Word		equ PCI_ADDR+(5*8)
PCI_Read_Dword		equ PCI_ADDR+(5*9)
PCI_Get_VendorID	equ PCI_ADDR+(5*10)
PCI_Get_DeviceID	equ PCI_ADDR+(5*11)
PCI_Check_Buses		equ PCI_ADDR+(5*12)

; PCI Device Structs & Variables offset
VendorID 			equ PCI_ADDR+(5*13)
DeviceID 			equ VendorID+2
PCIDataWrite 		equ DeviceID+2
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Realtek Registers Address & flag bits
RTL81XX_REG_IDR0		equ 0x00	; ID Register 0
RTL81XX_REG_IDR1		equ 0x01	; ID Register 1
RTL81XX_REG_IDR2		equ 0x02	; ID Register 2
RTL81XX_REG_IDR3		equ 0x03	; ID Register 3
RTL81XX_REG_IDR4		equ 0x04	; ID Register 4
RTL81XX_REG_IDR5		equ 0x05	; ID Register 5
RTL81XX_REG_MAR0		equ 0x08	; Multicast Register 0
RTL81XX_REG_MAR1		equ 0x09	; Multicast Register 1
RTL81XX_REG_MAR2		equ 0x0A	; Multicast Register 2
RTL81XX_REG_MAR3		equ 0x0B	; Multicast Register 3
RTL81XX_REG_MAR4		equ 0x0C	; Multicast Register 4
RTL81XX_REG_MAR5		equ 0x0D	; Multicast Register 5
RTL81XX_REG_MAR6		equ 0x0E	; Multicast Register 6
RTL81XX_REG_MAR7		equ 0x0F	; Multicast Register 7
RTL81XX_REG_TNPDS		equ 0x20	; Transmit Normal Priority Descriptors: Start address (64-bit). (256-byte alignment) 
RTL81XX_REG_COMMAND		equ 0x37	; Command Register
RTL81XX_REG_TPPOLL		equ 0x38	; Transmit Priority Polling Register
RTL81XX_REG_IMR			equ 0x3C	; Interrupt Mask Register
RTL81XX_REG_ISR			equ 0x3E	; Interrupt Status Register
RTL81XX_REG_TCR			equ 0x40	; Transmit (Tx) Configuration Register
RTL81XX_REG_RCR			equ 0x44	; Receive (Rx) Configuration Register
RTL81XX_REG_9346CR		equ 0x50	; 93C46 (93C56) Command Register
RTL81XX_REG_CONFIG0		equ 0x51	; Configuration Register 0
RTL81XX_REG_CONFIG1		equ 0x52	; Configuration Register 1
RTL81XX_REG_CONFIG2		equ 0x53	; Configuration Register 2
RTL81XX_REG_CONFIG3		equ 0x54	; Configuration Register 3
RTL81XX_REG_CONFIG4		equ 0x55	; Configuration Register 4
RTL81XX_REG_CONFIG5		equ 0x56	; Configuration Register 5
RTL81XX_REG_PHYAR		equ 0x60	; PHY Access Register 
RTL81XX_REG_PHYStatus	equ 0x6C	; PHY(GMII, MII, or TBI) Status Register 
RTL81XX_REG_MAXRX		equ 0xDA	; Mac Receive Packet Size Register
RTL81XX_REG_CCR			equ 0xE0	; C+ Command Register
RTL81XX_REG_RDSAR		equ 0xE4	; Receive Descriptor Start Address Register (256-byte alignment)
RTL81XX_REG_MAXTX		equ 0xEC	; Max Transmit Packet Size Register
RTL81XX_REG_MPC 		equ 0x4C 	; RX Missed Packet Counter 
RTL81XX_REG_NERI 		equ 0x5C 	; NERI - No Early Rx Interrupts
RTL81XX_REG_TMRI		equ 0x58	; Timer Out Interruption

; Command Register (Offset 0037h, R/W)
RTL81XX_BIT_RST			equ (1 << 4)		; Reset
RTL81XX_BIT_RE			equ (1 << 3)		; Receiver Enable
RTL81XX_BIT_TE			equ (1 << 2)		; Transmitter Enable

; Receive Configuration (Offset 0044h-0047h, R/W)
BIT_AAP			equ (1 << 0)		; Accept All Packets with Destination Address
BIT_APM 		equ (1 << 1)		; Accept Physical Match Packets
BIT_AM			equ (1 << 2)		; Accept Multicast Packets
BIT_AB	 		equ (1 << 3)		; Accept Broadcast Packets
BIT_AR			equ (1 << 4)		; Accept Runt
BIT_AER			equ (1 << 5)		; Accept Error
MAX_DMA_SIZE 	equ (111b << 8)		; 1024 bytes max DMA size  era 110b
NO_RX_THRESHOLD equ (111b << 13)	; No FIFO limit

; Transmit Configuration (Offset 0040h-0043h, R/W)
INTERFRAME_GAP 	equ (011b << 24) 	; 96ns for 1000Mbps, 960ns for 100Mbps, 9.6ns for 10Mbps
	
; RX Descriptor Flags
OWN 			equ (1 << 31) 		; Ownership - card own this descriptor
EOR				equ (1 << 30) 		; End of Rx Descriptor Ring
RTL_FS 			equ (1 << 29)		; First packet received
RTL_LS 			equ (1 << 28)		; Last packet received
RTL_IPCS 		equ (1 << 18)

; Interrupt Mask (Offset 003Ch-003Dh, R/W)
RX_OK 			equ (1 << 0)  		; Reception interrupt
RX_ERROR 		equ (1 << 1)		; Rx Error Interrupt
TX_OK 			equ (1 << 2)  		; transmission interrupt
TX_ERROR 		equ (1 << 3)		; Tx Error Interrupt
RX_UNAVAILABLE 	equ (1 << 4)		; Rx Descriptor Unavailable Interrupt
LINK_CHANGE 	equ (1 << 5)		; Link Change Interrupt
RX_OVERFLOW 	equ (1 << 6)		; Rx FIFO Overflow Interrupt
TX_UNAVAILABLE 	equ (1 << 7)		; Tx Descriptor Unavailable Interrupt
SOFTWARE_INTR 	equ (1 << 8)		; Software Interrupt
TIME_OUT 		equ (1 << 14)		; Time Out Interrupt
SYSTEM_ERROR 	equ (1 << 15) 		; System error interrupt
ALL_INTRS 		equ	SYSTEM_ERROR | TIME_OUT | SOFTWARE_INTR | RX_OVERFLOW | LINK_CHANGE | RX_UNAVAILABLE | TX_ERROR | TX_OK | RX_ERROR | RX_OK

; Descriptors Buffer Sizes & Base Address
RTL81XX_RX_SIZE 	equ 0x2000		; SIZE = 8192 = 8k
RTL81XX_TX_SIZE		equ 0x40		; SIZE = 64 bytes
RX_BASE_ADDR 		equ 0x300000
TX_BASE_ADDR 		equ RX_BASE_ADDR+(RTL81XX_RX_SIZE*(RX_DESCRIPTOR_COUNT+1))

; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Others constants (Print Colors)
COLOR_GREEN 		equ 0x02
COLOR_BLUE  		equ 0x03
COLOR_RED 			equ 0x04
COLOR_PINK 			equ 0x05
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Realtek Versions Compatibility
driver_support_table:
	dw 0x8169
	dw 0x8168
	dw 0x8161
	dw 0x8136
	dw 0x4300
driver_support.size equ ($-driver_support_table)
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Realtek Chipset Versions
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
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Realtek RX/TX Descriptors
	
; 1024 descriptores RX máximos (16384 bytes = 0x3FFF)
align 256
RX_DESCRIPTOR:
	.flags			dd 0x00000000
	.vlan			dd 0
	.low_buffer		dd 0
	.high_buffer	dd 0
RX_DESCRIPTOR_SIZE 	equ ($-RX_DESCRIPTOR)
RX_DESCRIPTOR_COUNT equ 5
	times (RX_DESCRIPTOR_SIZE*(RX_DESCRIPTOR_COUNT - 1)) DB 0
	
; 1024 descriptores TX máximos (16384 bytes = 0x3FFF) - Normal Priority
align 256
TX_DESCRIPTOR:
	.flags			dd 0x00000000
	.vlan			dd 0
	.low_buffer		dd 0
	.high_buffer	dd 0
TX_DESCRIPTOR_SIZE 	equ ($-TX_DESCRIPTOR)
TX_DESCRIPTOR_COUNT equ 1
	times (TX_DESCRIPTOR_SIZE*(TX_DESCRIPTOR_COUNT - 1)) DB 0
	
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Device information/interruption Data
align 4
INTRXTX:
	.rx_ptrc		dd 0
	.tx_ptrc		dd 0
	.irq_status	  	db 0
	.isrstatus 	   	dw 0
	.mpc_counter 	dd 0

DEVICE:
	.chipset 		dd 0
	.name_addr 		dd 0
	.net_mac		dq 0
	.net_io_addr	dd 0
	.net_irq 		db 0
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Auxiliar Variables
mac_addr times 6 db 0

; ------------------------------------------------------------------------------------------
; Initialize a Realtek 8169 NIC
; IN:	Nothing
; OUT:	Nothing, all registers preserved
rtl81xx_init_config:
	pushad

	call 	rtl81xx_check_support
	jc 		abort_driver

	call 	rtl81xx_get_dev_address
	call 	rtl81xx_get_irq_device
	call 	rtl81xx_bus_mastering
	call 	rtl81xx_set_irq_device

	call 	rtl81xx_get_vendor_dev
	call 	rtl81xx_get_mac_address
	
	call 	rtl81xx_reset_config
	

	popad
	mov 	eax, [eax_saved]
	mov 	dx, [dx_saved]
	clc
	ret

abort_driver:
	popad
	stc
	ret
eax_saved dd 0
dx_saved  dw 0
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; rtl8136_reset_config - Reset & config a Realtek 8169 NIC
; IN:	Nothing
; OUT:	Nothing, all registers preserved
rtl81xx_reset_config:
	pushad

	call 	rtl81xx_reset
	call 	rtl81xx_check_mac_version
	call 	rtl81xx_unlock_config
	
	call 	rtl81xx_enable_rxtx_cmd_prev
	call 	rtl81xx_setup_txmax_size
	call 	rtl81xx_setup_rxmax_size
	call 	rtl81xx_receive_config
	;call 	rtl81xx_setup_tcr
	call 	rtl81xx_setup_tx_desc
	call 	rtl81xx_setup_tx_addr
	call 	rtl81xx_setup_rx_desc
	call 	rtl81xx_setup_rx_addr
	call 	rtl81xx_enable_rxtx_cmd_last
	call 	rtl81xx_setup_tcr		; TCR só é alterado se TE de 0x37 for setado (chipset 37)
	call 	rtl81xx_reset_mpc
	call 	rtl81xx_disable_timerint
	call 	rtl81xx_print_init_info
	call 	rtl81xx_enable_rxtx_int
	call 	rtl81xx_lock_config

	popad
	ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; IN:	Nothing
; OUT:	Nothing
rtl81xx_check_support:
	mov 	esi, driver_support_table
	mov 	ecx, driver_support.size
	shr 	ecx, 1
	cld
loop_check:
	push 	ecx
	lodsw
	call 	PCI_Check_Buses
	jnc 	found_supported
	pop 	ecx
	loop 	loop_check
	jmp 	not_supported
found_supported:
	pop 	ecx
	xor 	ecx, ecx
	mov 	[DEVICE.name_addr], esi
	clc
ret
not_supported:
	Printz(COLOR_RED, msg_not_supported)
	stc
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Enable Bus Mastering DMA
; IN:	Nothing
; OUT:	Nothing, all registers preserved
rtl81xx_bus_mastering:
	pushad
	
	mov 	al, 2
	mov 	bl, 0
	mov 	cl, 0
	mov 	dl, 4
	call 	PCI_Read_Dword
	or 		eax, 00000110b
	mov 	DWORD[PCIDataWrite], eax
	mov 	al, 2
	mov 	dl, 4
	call 	PCI_Write_Word
	call 	PCI_Read_Dword
	
	test 	eax, 0x04
	jnz 	jump_bus_err
	Printz(COLOR_RED, bus_master_err)
jump_bus_err:
	popad
ret
; ------------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------------
; Input/Output Commands Functions

rtl_write_command_byte:
	mov 	edi, [DEVICE.net_io_addr]
	mov 	[edi + ebx], al 
ret

rtl_write_command_word:
	mov 	edi, [DEVICE.net_io_addr]
	mov 	[edi + ebx], ax 
ret

rtl_write_command_dword:
	mov 	edi, [DEVICE.net_io_addr]
	mov 	[edi + ebx], eax 
ret

rtl_read_command_byte:
	xor 	eax, eax
	mov 	edi, [DEVICE.net_io_addr]
	mov 	al, [edi + ebx] 
ret

rtl_read_command_word:
	xor 	eax, eax
	mov 	edi, [DEVICE.net_io_addr]
	mov 	ax, [edi + ebx] 
ret

rtl_read_command_dword:
	xor 	eax, eax
	mov 	edi, [DEVICE.net_io_addr]
	mov 	eax, [edi + ebx] 
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Initial PCI Configuration Functions

; Grab the Base I/O Address of the device
rtl81xx_get_dev_address:
	pushad
	mov 	dl, 0x18
	call 	PCI_Read_Dword
	and 	eax, 0xFFFFFFF0
	mov 	[DEVICE.net_io_addr], eax
	
	call 	rtl81xx_print_addr
	
	popad
ret

; Grab the IRQ of the device
rtl81xx_get_irq_device:
	pushad
	
	mov 	dl, 0x3C
	call 	PCI_Read_Dword
	and 	eax, 0x000000FF
	mov 	[DEVICE.net_irq], al
	
	call 	rtl81xx_print_irq
	
	popad
ret

; Register Handler on the IRQ Device
rtl81xx_set_irq_device:
	pushad
	xor 	eax, eax
	mov 	al, [DEVICE.net_irq]
	Handler_Register(eax, rtl81xx_handler)
	popad
ret

; Get the manufacturer ID and DeviceID
rtl81xx_get_vendor_dev:
	pushad
	
	call 	PCI_Get_VendorID
	call 	PCI_Get_DeviceID

	call 	rtl81xx_print_device
	
	popad
ret

; Get/Fill the MAC address
rtl81xx_get_mac_address:
	pushad
	cld
	mov 	esi, [DEVICE.net_io_addr]
	mov 	ecx, 6
	mov 	edi, DEVICE.net_mac
	rep 	movsb
	mov 	ecx, 6
	mov 	esi, DEVICE.net_mac
	mov 	edi, mac_addr+5
get_mac_addr2:
	cld
	lodsb
	std
	stosb
	loop 	get_mac_addr2
	cld
	mov 	eax, [mac_addr+2]
	xor 	edx, edx
	mov 	dx, [mac_addr]
	mov 	[eax_saved], eax
	mov 	[dx_saved], dx
	
	call 	rtl81xx_print_mac
	
	popad
ret

; Verify the mac/chipset version
rtl81xx_check_mac_version:
	pushad
	
	mov 	ebx, RTL81XX_REG_TCR
	call 	rtl_read_command_dword
	and 	eax, 0xFCF00000
	
	mov 	esi, chipset_mac_versions
	mov 	ecx, chipset_mac_versions.size
	shr 	ecx, 3
check_mac:
	cmp 	eax, [esi]
	jz 		set_chipset
	add 	esi, 8
	loop 	check_mac
	Printz(COLOR_RED, unk_err)
	mov 	byte[DEVICE.chipset], 0x69
	popad
	stc
	ret
	
; Define the chipset number
set_chipset:
	mov 	eax, [esi+4]
	mov 	[DEVICE.chipset], eax
	call 	rtl81xx_print_chipset
	popad
	clc
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; RTL81XX Configuration Functions

; reset the device
rtl81xx_reset:
	mov 	ebx, RTL81XX_REG_COMMAND
	mov 	al, RTL81XX_BIT_RST
	call 	rtl_write_command_byte
	mov 	cx, 1000				; Wait no longer for the reset to complete
	wait_for_81XX_reset:
		call 	rtl_read_command_byte
		test 	al, RTL81XX_BIT_RST
		jz 		reset_81XX_completed	; RST remains 1 during reset, Reset complete when 0
		loop 	wait_for_81XX_reset
reset_81XX_completed:
	ret

; Unlock config registers
rtl81xx_unlock_config:
	mov 	ebx, RTL81XX_REG_9346CR
	mov 	al, 0xC0
	call 	rtl_write_command_byte
ret

; Receive configuration
; Set DMA burst size
rtl81xx_receive_config:
	mov 	ebx, RTL81XX_REG_RCR
	call 	rtl_read_command_dword
	and 	eax, 0xFF7E1880
	or 		eax, NO_RX_THRESHOLD | MAX_DMA_SIZE | BIT_AAP | BIT_APM | BIT_AM | BIT_AB
	call 	rtl_write_command_dword
ret

; Transmission Configuration
; Set DMA burst size and Interframe Gap Time 
rtl81xx_setup_tcr:
	mov 	ebx, RTL81XX_REG_TCR
	mov 	eax, INTERFRAME_GAP | MAX_DMA_SIZE
	call 	rtl_write_command_dword
ret

; Setup max RX descriptor size
rtl81xx_setup_rxmax_size:
	mov 	ebx, RTL81XX_REG_MAXRX
	mov 	ax, RTL81XX_RX_SIZE-1
	call 	rtl_write_command_word
ret

; Setup max TX descriptor size
rtl81xx_setup_txmax_size:
	mov 	ebx, RTL81XX_REG_MAXTX
	mov 	ax, RTL81XX_TX_SIZE-1
	call 	rtl_write_command_byte
ret

; Set the Flags on the TNPD
rtl81xx_setup_tx_desc:
	pushad
	mov 	ecx, TX_DESCRIPTOR_COUNT
	mov 	edi, TX_DESCRIPTOR
	mov 	eax, RTL_FS
	mov 	ebx, TX_BASE_ADDR
setup_tx_desc:
	
	or 		eax, OWN | RTL_IPCS | RTL81XX_TX_SIZE
	cmp 	ecx, 1
	jnz 	non_set_eor_tx
	or 		eax, RTL_LS | EOR
	non_set_eor_tx:
		mov	 	dword[edi], eax
		mov		dword[edi + 4], 0
		mov 	dword[edi + 8], ebx
		mov		dword[edi + 12], 0
		
		xor 	eax, eax
		add 	ebx, RTL81XX_TX_SIZE
		add 	edi, TX_DESCRIPTOR_SIZE
		loop 	setup_tx_desc
	popad
ret

; Set the Transmit Normal Priority Descriptor Start Address
rtl81xx_setup_tx_addr:
	mov 	ebx, RTL81XX_REG_TNPDS
	mov 	eax, TX_DESCRIPTOR
	call 	rtl_write_command_dword
	add 	ebx, 4
	mov 	eax, 0
	call 	rtl_write_command_dword
ret

; Set the flags on the RCS
rtl81xx_setup_rx_desc:
	mov 	ecx, RX_DESCRIPTOR_COUNT
	mov 	edi, RX_DESCRIPTOR
	mov 	ebx, RX_BASE_ADDR
setup_rx_desc:
	mov 	eax, OWN | RTL81XX_RX_SIZE
	cmp 	ecx, 1
	jnz 	non_set_eor_rx
	or 		eax, EOR
	non_set_eor_rx:
		mov	 	dword[edi], eax
		mov		dword[edi + 4], 0
		mov 	dword[edi + 8], ebx
		mov		dword[edi + 12], 0
	
		add 	ebx, RTL81XX_RX_SIZE
		add 	edi, RX_DESCRIPTOR_SIZE
		loop 	setup_rx_desc
ret


; Set the Receive Descriptor Start Address
rtl81xx_setup_rx_addr:
	mov 	ebx, RTL81XX_REG_RDSAR
	mov 	eax, RX_DESCRIPTOR
	call 	rtl_write_command_dword
	add 	ebx, 4
	mov 	eax, 0
	call 	rtl_write_command_dword
ret


; Enable Rx/Tx in the Command register for previous version
rtl81xx_enable_rxtx_cmd_prev:
	cmp 	dword[DEVICE.chipset], 5
	ja 		no_config_rxtx_prev
	call 	rtl81xx_enable_rxtx_cmd
no_config_rxtx_prev:
	ret
	
; Enable Rx/Tx in the Command register for lastest version
rtl81xx_enable_rxtx_cmd_last:
	cmp 	dword[DEVICE.chipset], 5
	jna 	no_config_rxtx_last	
	call 	rtl81xx_enable_rxtx_cmd
no_config_rxtx_last:
	ret
	
; Enable RX/TX
rtl81xx_enable_rxtx_cmd:
	mov 	ebx, RTL81XX_REG_COMMAND
	mov 	al, RTL81XX_BIT_RE | RTL81XX_BIT_TE
	call 	rtl_write_command_byte
ret

; Reset de Rx Missed Packet Counter
rtl81xx_reset_mpc:
	mov 	ebx, RTL81XX_REG_MPC
	mov 	eax, 0
	call 	rtl_write_command_dword
ret

; No Early Rx Interruption
rtl81xx_noearly_rx_intr:
	mov 	ebx, RTL81XX_REG_NERI
	call 	rtl_read_command_word
	and 	ax, 0xF000
	call 	rtl_write_command_word
ret

; Disable Timerint
rtl81xx_disable_timerint:
	mov 	ebx, RTL81XX_REG_TMRI
	mov 	eax, 0
	call 	rtl_write_command_dword
ret

; Enable Receive and Transmit interrupts
rtl81xx_enable_rxtx_int:
	mov 	ebx, RTL81XX_REG_IMR
	mov 	ax, ALL_INTRS	;0x8000 | 0x4000 | 0x2000 | 0x0040 | 0x0020 | 0x0010 | 0x0008 | 0x0002 | 0x0001
	call 	rtl_write_command_word
ret



; Lock config register
rtl81xx_lock_config:
	mov 	ebx, RTL81XX_REG_9346CR
	mov 	al, 0
	call 	rtl_write_command_byte
ret

; Set the C+ Command (não utilizado)
rtl81xx_cplus_cmd:
	mov 	ebx, RTL81XX_REG_CCR
	call 	rtl_read_command_word
	bts 	ax, 3
	bts 	ax, 9
	call 	rtl_write_command_word
ret

; Initialize multicast registers (no filtering)
; (não utilizado)
rtl81xx_init_multicast:
	mov 	ebx, RTL81XX_REG_MAR0
	mov 	eax, 0xFFFFFFFF
	call 	rtl_write_command_dword
	add 	ebx, 4
	call 	rtl_write_command_dword
ret
; ------------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------------
; Funções de impressão de Strings de Configuração
; Print the initialization Info
rtl81xx_print_init_info:
	Printz(COLOR_GREEN, int_msg)
	Printz(COLOR_GREEN, eth_msg)
ret

; Print the chipset number info
rtl81xx_print_chipset:
	Get_Dec32([DEVICE.chipset], chip_buf)
	Printz(COLOR_BLUE, chip_str)
	Printz(COLOR_PINK, chip_buf)
ret

; Print the MAC address info
rtl81xx_print_mac:
	Get_Hexa8([DEVICE.net_mac], BUFFER_MAC)
	Get_Hexa8([DEVICE.net_mac+1], BUFFER_MAC+3)
	Get_Hexa8([DEVICE.net_mac+2], BUFFER_MAC+6)
	Get_Hexa8([DEVICE.net_mac+3], BUFFER_MAC+9)
	Get_Hexa8([DEVICE.net_mac+4], BUFFER_MAC+12)
	Get_Hexa8([DEVICE.net_mac+5], BUFFER_MAC+15)
	
	Printz(COLOR_BLUE, mac_str)
	Printz(COLOR_PINK, BUFFER_MAC)
ret

; Print the vendor and device identification numbers
rtl81xx_print_device:
	Get_Hexa16([VendorID], buf_val2)
	Printz(COLOR_BLUE, data_ven)
	Printz(COLOR_PINK, buf_val2)
	Get_Hexa16([DeviceID], buf_val3)
	Printz(COLOR_BLUE, data_dev)
	Printz(COLOR_PINK, buf_val3)
	Printz(COLOR_BLUE, data_name)
	Printz(0x06, [DEVICE.name_addr])
	Printz(0x06, enter_char)
ret

; Print the network IRQ number
rtl81xx_print_irq:
	xor 	eax, eax
	mov 	al, [DEVICE.net_irq]
	Get_Dec32(eax, buf_val1)
	Printz(COLOR_BLUE, data_irq)
	Printz(COLOR_PINK, buf_val1)
ret

; Print the PCI I/O base address
rtl81xx_print_addr:
	Get_Hexa32([DEVICE.net_io_addr], buf_val)
	Printz(COLOR_BLUE, data_base)
	Printz(COLOR_PINK, buf_val)
ret

; Print the ISR status from Interruption
intr_print_isr_status:
	Get_Hexa16([INTRXTX.isrstatus], buffer16)
	Printz(COLOR_BLUE, statusmsg)
	Printz(COLOR_PINK, buffer16)
ret

; Print the MPC from the Interruption
intr_print_missed_packet:
	Get_Dec32([INTRXTX.mpc_counter], buffer32)
	Printz(COLOR_BLUE, mpc_msg)
	Printz(COLOR_PINK, buffer32)
	Printz(COLOR_BLUE, enter_char)
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
;  RTL81XX_transmit_data - Transmit a packet via a Realtek 8169 NIC
;  IN:	ESI = Location of packet
;		ECX = Length of packet
; OUT:	Nothing
; ToDo:	Check for proper timeout
rtl81xx_transmit_data:
	pushad
	call 	rtl81xx_setup_tx_desc
	mov 	edi, TX_DESCRIPTOR
	and 	DWORD[edi], 0xFFFFC000		; Clear 14 LSB bits
	and 	ecx, 0x3FFF 				; Clear to max size
	or 		DWORD[edi], ecx				; Set the size
	mov 	DWORD[edi+8], esi			; Define the Packet Location
	
no_search_other_desc:
	mov 	esi, edi
	mov 	ebx, RTL81XX_REG_TPPOLL
	mov 	al, 0x40
	call 	rtl_write_command_byte
transmit_loop_polling:
	mov 	eax, [esi]
	test 	eax, OWN				; Check the ownership bit (BT command instead?)
	jnz 	transmit_loop_polling
	add 	esi, TX_DESCRIPTOR_SIZE
	test 	eax, RTL_LS
	jz 		transmit_loop_polling
	Printz(0x02, sucess_transmit)
	popad
ret
sucess_transmit db "OWN = 0, Packet transmitted!",0x0D,0
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; RTL81XX_receive_data - Search the Realtek 8169 NIC for a received packet
; IN:	EDI = Location to store packet
; OUT:	ECX = Length of packet
;		All registers preserved
rtl81xx_receive_data:
	pushad
	mov 	esi, RX_DESCRIPTOR
search_rx_buffer:
	
	mov 	ebx, [INTRXTX.rx_ptrc]
	shl 	ebx, 4
	add 	esi, ebx
	
	test	dword[esi], OWN
	jnz		return_receive_data
	
	or 		DWORD[esi], OWN
	
	test 	dword[esi], 0x3FFF
	jz 		return_rx_search
	cmp 	edi, 0xFFFFFFFF
	jz 		return_rx_search
	
	call 	rtl81xx_copy_data
	
return_rx_search:
	xor 	edx, edx
	mov		eax, [INTRXTX.rx_ptrc]
	inc 	eax
	mov 	ebx, RX_DESCRIPTOR_COUNT
	div 	ebx
	mov		[INTRXTX.rx_ptrc], edx
	jmp  	search_rx_buffer
	
return_receive_data:
	popad
	ret

; Copy received data from source to destiny buffer
rtl81xx_copy_data:
	push 	esi
	mov 	esi, [esi + 8]
	rep 	movsb
	pop 	esi
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Handler to Process ISR status, Called by IRQ
rtl81xx_handler:
	mov 	ebx, RTL81XX_REG_ISR
	call 	rtl_read_command_word
	and 	ax, 0xFF7F					; Clear TX unavailable, 'cause packet is transmitted anyway
	mov 	[INTRXTX.isrstatus], ax
	call 	rtl_write_command_word

check_rx_ok:
	test 	word[INTRXTX.isrstatus], RX_OK
	jz	 	check_rx_err
	mov 	eax, COLOR_BLUE
	mov 	esi, rx_ok_msg
	call 	print_msg_int
	mov 	edi, 0xFFFFFFFF
	call 	rtl81xx_receive_data
check_rx_err:
	test 	word[INTRXTX.isrstatus], RX_ERROR
	jz	 	check_tx_ok
	mov 	eax, COLOR_RED
	mov 	esi, rx_err_msg
	call 	print_msg_int
check_tx_ok:
	test 	word[INTRXTX.isrstatus], TX_OK
	jz	 	check_tx_err
	mov 	eax, COLOR_BLUE
	mov 	esi, tx_ok_msg
	call 	print_msg_int
check_tx_err:
	test 	word[INTRXTX.isrstatus], TX_ERROR
	jz	 	check_rx_desc
	mov 	eax, COLOR_RED
	mov 	esi, tx_err_msg
	call 	print_msg_int
check_rx_desc:
	test 	word[INTRXTX.isrstatus], RX_UNAVAILABLE
	jz	 	check_link_change
	mov 	eax, COLOR_RED
	mov 	esi, rx_desc_err
	call 	print_msg_int
check_link_change:
	test 	word[INTRXTX.isrstatus], LINK_CHANGE
	jz	 	check_fifo_overflow
	mov 	eax, COLOR_BLUE
	mov 	esi, link_chg_msg
	call 	print_msg_int
check_fifo_overflow:
	test 	word[INTRXTX.isrstatus], RX_OVERFLOW
	jz	 	check_tx_desc
	mov 	eax, COLOR_RED
	mov 	esi, fifo_err_msg
	call 	print_msg_int
check_tx_desc:
	test 	word[INTRXTX.isrstatus], TX_UNAVAILABLE
	jz	 	check_soft_intr
	mov 	eax, COLOR_RED
	mov 	esi, tx_desc_err
	call 	print_msg_int
check_soft_intr:
	test 	word[INTRXTX.isrstatus], SOFTWARE_INTR
	jz	 	check_time_out
	mov 	eax, COLOR_BLUE
	mov 	esi, soft_intr_info
	call 	print_msg_int
check_time_out:
	test 	word[INTRXTX.isrstatus], TIME_OUT
	jz	 	check_system_err
	mov 	eax, COLOR_RED
	mov 	esi, time_out_info
	call 	print_msg_int
check_system_err:
	test 	word[INTRXTX.isrstatus], SYSTEM_ERROR
	jz	 	end_check_bits
	mov 	eax, COLOR_RED
	mov 	esi, system_err_msg
	call 	print_msg_int
end_check_bits:
	mov 	ax, [INTRXTX.isrstatus]
	mov 	byte[INTRXTX.irq_status], 0
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Print each interrupt information
print_msg_int:
	pusha
	cmp 	byte[INTRXTX.irq_status], 1
	jz 		non_print_status
	push 	esi
	push 	eax
	call 	intr_print_isr_status
	pop 	eax
	pop 	esi
	mov 	byte[INTRXTX.irq_status], 1
non_print_status:
	Printz(eax, esi)
	test 	word[INTRXTX.isrstatus], RX_OVERFLOW | RX_UNAVAILABLE
	jz 		non_print_mpc
	call 	print_msg_mpc
non_print_mpc:
	popa
ret.print_msg:
	ret
	
; Get the MPC and Print
print_msg_mpc:
	pusha
	mov 	ebx, RTL81XX_REG_MPC
	call 	rtl_read_command_dword
	and 	eax, 0x00FFFFFF
	mov 	[INTRXTX.mpc_counter], eax
	call 	rtl81xx_reset_mpc
	call 	intr_print_missed_packet
	popa
ret
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Debug Code Descriptor
debug_data:
	pushad
	push 	esi
	Get_Hexa32([esi], buf_val7)
	Printz(0x03, buf_val7)
	pop 	esi
	push 	esi
	Get_Hexa32([esi+4], buf_val7)
	Printz(0x04, buf_val7)
	pop 	esi
	push 	esi
	Get_Hexa32([esi+8], buf_val7)
	Printz(0x05, buf_val7)
	pop 	esi
	push 	esi
	Get_Hexa32([esi+12], buf_val7)
	Printz(0x06, buf_val7)
	pop 	esi
	push 	esi
	Printz(0x03, enter_char)
	pop 	esi
	popad
ret
addr_temp 	dd 0
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; Network Interruption Strings
statusmsg 	  	db "[INT] ISR STATUS = ",0
rx_ok_msg 	  	db "[INT] Successful completion of a packet reception.",0x0D, 0
rx_err_msg 	  	db "[INT] ERR: a packet has either a CRC or FAE error.",0x0D, 0
tx_ok_msg 	  	db "[INT] Successful completion of a packet transmission.",0x0D, 0
tx_err_msg 	  	db "[INT] ERR: Transmission was aborted due excessive collisions.",0x0D, 0
rx_desc_err   	db "[INT] ERR: the RX descriptor is unavailable.",0x0D, 0
tx_desc_err   	db "[INT] ERR: the TX descriptor is unavailable.",0x0D, 0
link_chg_msg  	db "[INT] link status is changed.",0x0D, 0
fifo_err_msg  	db "[INT] RX FIFO overflow occured, packets discarded = ",0x0D, 0
soft_intr_info 	db "[INT] TX Forced Software Interruption.",0x0D, 0
time_out_info  	db "[INT] Time out reached on TCTR register.",0x0D, 0
system_err_msg 	db "[INT] A system error occured on the PCI bus.",0x0D, 0
mpc_msg 	   	db "[INT] MPC = ",0
; ------------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------------
; RTL81XX Configuration Strings
data_base 	db "[RTL81] Base Addr = ",0
data_irq 	db "[RTL81] IRQ = ",0
data_ven 	db "[RTL81] Vendor = ",0
data_dev 	db ", Device = ",0
data_name 	db "[RTL81] Device Name = ",0
mac_str  	db "[RTL81] MAC = ",0
chip_str 	db "[RTL81] chipset = ",0
int_msg 	db "[RTL81] Enable reception interrupts ...",0x0D,0
eth_msg 	db "[RTL81] RTL81xx driver initialized!",0x0D,0
enter_char 	db 0x0D,0
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; RTL81XX Configuration Error Strings
unk_err 	db "[RTL81] Unknown mac device!",0x0D,0
msg_not_supported 	db "[RTL81] This driver is not supported on this machine!",0
bus_master_err 	db "[RTL81] Busmastering was not enabled!",0x0D,0
; ------------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------------
; INT-to-String Conversions Buffers
buf_val 	db "        ",0x0D,0
buf_val7 	db "        ",0
buf_val8 	db "         ",0
buf_val1 	db "  ",0x0D,0
buf_val2 	db "    ",0
buf_val3 	db "    ",0x0D,0
chip_buf 	db "    ",0x0D,0
BUFFER_MAC 	db "  -  -  -  -  -  ",0x0D,0
buffer16 	  	db "    ",0x0D,0
buffer32 	  	times 20 db 0
; ------------------------------------------------------------------------------------------

