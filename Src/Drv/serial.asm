%INCLUDE "Hardware\memory.lib"
[BITS SYSTEM]
[ORG SERIAL]

jmp Init_Serial
jmp SerialMain
jmp Write_Serial
jmp Read_Serial

%INCLUDE "Hardware\iodevice.lib"
%INCLUDE "Hardware\serial.lib"
%INCLUDE "Hardware\keyboard.lib"
%INCLUDE "Hardware\fontswriter.lib"


SerialMain:
	call Write_Serial
	cmp byte[StopRead], '$'
	je RetSerial
	call Read_Serial
RetSerial:
	ret


Init_Serial:
	__WritePort IRQ_PORT1, IRQ_DISABLE  ;desabilita as interrupções
	__WritePort LCR_PORT,  BAUD_RATE    ;DLAB - acesso a divisor de BaudRate
	__WritePort DIV_PORT1, DIVISOR      ;Divisor para o baud rate
	__WritePort DIV_PORT,  HIGH_BYTE    ; Byte mais significante do divisor
	__WritePort LCR_PORT,  NO_PARITY    ; padrão 8N1
	__WritePort FIFO_PORT, FIFO_CONFIG  ; Habilita o acesso FIFO Controller
	__WritePort IRQ_PORT,  IRQ_ENABLE   ; Habilita as IRQs
ret

Serial_Received:
	xor ax, ax
	__ReadPort LSR_PORT
	and ax, DR
	jz Serial_Received
ret

Read_Serial:
	call Serial_Received
	__ReadPort SERIAL_PORT
	mov byte[SerialData], al
	mov byte[StopRead], al
ret

Is_Transmit_Empty:
	xor ax, ax
	__ReadPort LSR_PORT
	and ax, THRE
	jz Is_Transmit_Empty
ret

Write_Serial:
	mov cl, byte[SerialData]
	call Is_Transmit_Empty
	__WritePort SERIAL_PORT, cl
ret



