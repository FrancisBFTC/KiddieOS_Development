%INCLUDE "Hardware\memory.lib"
[BITS SYSTEM]
[ORG SERIAL]

jmp 	Init_Serial
jmp 	SerialMain

%include "Hardware/iodevice.lib"
%include "Hardware/serial.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"

SerialMain:
	mov cl, byte[SERIAL_DATA]
	call Write_Serial
	cmp byte[StopRead], '$'
	je RetSerial
	call Read_Serial
	mov byte[SerialData], al
	mov byte[StopRead], al
	__FontsWriter KEY
RetSerial:	
	ret


Init_Serial:
	__WritePort IRQ_PORT1, IRQ_DISABLE
	__WritePort LCR_PORT,  BAUD_RATE
	__WritePort DIV_PORT1, DIVISOR
	__WritePort DIV_PORT,  0x00
	__WritePort LCR_PORT,  NO_PARITY
	__WritePort FIFO_PORT, FIFO_Config
	__WritePort IRQ_PORT,  IRQ_ENABLE
ret

Serial_Received:
	xor ax, ax
	__ReadPort LSR_PORT
	and ax, DR
	cmp ax, 0
	je Serial_Received
ret

Read_Serial:
	call Serial_Received
	__ReadPort SERIAL_PORT
ret


Is_Transmit_Empty:
	xor ax, ax
	__ReadPort LSR_PORT
	and ax, THRE
	cmp ax, 0
	je Is_Transmit_Empty
ret

Write_Serial:
	call Is_Transmit_Empty
	__WritePort SERIAL_PORT, cl
ret