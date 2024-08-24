; ********************************************************
;			 NETWORK SERVICES APPLICATION v1.0.0
;				     Created by Francis
;                      NETAPP.KXE FILE
;
; ********************************************************

; --------------------------------------------------------
; Necessaries inclusions
%INCLUDE "../KiddieOS/library/user32/kxe.inc"
%INCLUDE "../Hardware/memory.lib"
%INCLUDE "../Lib/Drv/net/rtl8169.asm"
; --------------------------------------------------------

; --------------------------------------------------------
; Packets to transmit
CHARS MyDatas EQ "Hello World Realtek"
; --------------------------------------------------------

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Main function macro
; IN:  ARGC = Arguments Counter
;      ARGV = Arguments Vector
; OUT: EAX  = Program return value (normally 0)
Main(ARGC, ARGV)

	;call 	Init_PCI	; Deve ser iniciado antes, porém o devmgr.kxe já fez isso
	
	call 	rtl81xx_init_config
	jc 		Wait_Enter_Key
	
	mov 	esi, MyDatas
	mov 	ecx, MyDatas.Length
	call 	rtl81xx_transmit_data
	
Wait_Enter_Key:
	__ReadPort 	0x60
	cmp 	al, 0x9C
	jnz 	Wait_Enter_Key
	clc
	
.EndMain
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
