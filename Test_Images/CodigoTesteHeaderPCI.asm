call 	Init_PCI
	
	;call 	PCI_Check_All_Buses
	
	mov 	al, 0
	mov 	bl, 3
	mov 	cl, 0
	call 	PCI_Get_Info
	
	mov 	[bus], al
	mov 	[slot], bl
	mov 	[func], cl
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.BaseBAR0]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x10
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.BaseBAR1]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x14
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.PrimaryBus]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x18
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.SecondaryBus]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x19
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.SubordinaryBus]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1A
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.SecondLatency]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1B
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IOBase]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1C
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IOLimit]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1D
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.SecondStatus]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1E
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.MemoryBase]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x20
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.MemoryLimit]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x22
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.PrefMemBase]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x24
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.PrefMemLimit]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x26
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.PrefMemBase32]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x28
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.PrefMemLimit32]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x2C
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.IOBase16]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x30
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.IOLimit16]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x32
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.CapPointer]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x34
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.ExpROMAddr]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x38
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IntLine]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x3C
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IntPIN]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x3D
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.BridgeControl]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x3E
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	si, OtherPCI
	call 	Print_String
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, 0
	mov 	bl, 19
	mov 	cl, 1
	call 	PCI_Get_Info
	
	mov 	[bus], al
	mov 	[slot], bl
	mov 	[func], cl
	
	
	mov 	eax, dword[HeaderType1.BaseBAR0]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x10
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.BaseBAR1]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x14
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.PrimaryBus]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x18
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.SecondaryBus]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x19
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.SubordinaryBus]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1A
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.SecondLatency]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1B
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IOBase]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1C
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IOLimit]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1D
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.SecondStatus]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x1E
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.MemoryBase]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x20
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.MemoryLimit]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x22
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.PrefMemBase]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x24
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.PrefMemLimit]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x26
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.PrefMemBase32]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x28
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.PrefMemLimit32]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x2C
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.IOBase16]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x30
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.IOLimit16]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x32
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.CapPointer]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x34
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	eax, dword[HeaderType1.ExpROMAddr]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x38
	call 	PCI_Read_Word
	mov 	eax, dword[PCI_Reg]
	call 	Print_Hexa_Value32
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IntLine]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x3C
	call 	PCI_Read_Word
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	al, byte[HeaderType1.IntPIN]
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x3D
	call 	PCI_Read_Word
	shr 	ax, 8
	call 	Print_Hexa_Value8
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	
	mov 	ax, word[HeaderType1.BridgeControl]
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E20
	int 	0x10
	
	mov 	al, [bus]
	mov 	bl, [slot]
	mov 	cl, [func]
	mov 	dl, 0x3E
	call 	PCI_Read_Word
	call 	Print_Hexa_Value16
	
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	xor 	ax, ax
	int 	0x16
	; -------------------------------------------
	
	OtherPCI db "Next PCI Informations",0