ADDRESS EQU 0x100000 + 0x4000

ALIGN 4
Code_32Bit:
BITS 32

%IFNDEF PM_MODE_VSTART
SECTION protectedmode vstart=ADDRESS, valign=4
%ENDIF

%DEFINE EQ ,

%IFNDEF PM_MODE_VSTART
%DEFINE Main(ARG1, ARG2) .Main ARG1, ARG2
%DEFINE _ENTRY(FUNC) (FUNC - SIZE_PROG)

; ---------------------------------------------------------
; Estrutura de Executável KiddieOS

START_PROG:
	OPCODE:     db 0xE9
	ENTRY:      dd _ENTRY(_MAIN)
	SIZE_PROG: 	dd (END_PROG - START_PROG)
	ADDR_PROG:	dd ADDRESS
	DATA_PROG:  dd (END_PROG+0x20)
%ENDIF
; ---------------------------------------------------------


; ============================================
; Entry & End of program

%MACRO .Main 2
	%1 dd 0
	%2 dd 0
	_MAIN:
		push 	ebp
		mov 	ebp, esp
		mov 	esi, DWORD[ebp + 12]           
		mov 	DWORD[ %2 ], esi			    ; Transfira endereço dos argumentos para ARGV
		mov 	ecx, DWORD[ebp + 16]
		mov 	DWORD[ %1 ], ecx                ; Transfira endereço do count de args para ARGC
		pop 	ebp
		pushad
		;cli
%ENDMACRO 

%MACRO .EndMain 0
	_END:
		popad
		mov 	ax, 0
		retf
	END_PROG:
		;nop
%ENDMACRO
; ============================================

; ============================================
; Primitive Types

 
%MACRO INT8 2
	%1 db %2,0
%ENDMACRO

%MACRO INT16 2
	%1 dw %2,0
%ENDMACRO

%MACRO INT32 2
	%1 dd %2,0
%ENDMACRO

%MACRO INT64 2
	%1 dq %2,0
%ENDMACRO

%MACRO CHAR 2
	%1 db %2,0
%ENDMACRO

%MACRO CHARS 2
	%1: db %2,0
	%1.Length dw ($ - %1)
%ENDMACRO

%MACRO STRING 3
	Restore_Args(ax, ax, ax)
	push 	esi
	add 	%2, %3
	mov 	DWORD[%1], %2
	jmp 	%%skipaddr
	%1 dd 0x00000000
	%%skipaddr:
	pop 	esi
%ENDMACRO

%MACRO UINT32 3
	;Restore_Args(ax, ax, ax)
	push 	esi
	mov 	ebx, %3
	shl 	ebx, 2
	add 	%2, ebx
	mov 	DWORD[%1], %2
	jmp 	%%skipaddr
	%1 dd 0x00000000
	%%skipaddr:
	pop 	esi
%ENDMACRO

%MACRO VINT32 3
	mov 	esi, %2        ; Endereço de Vector para ESI
	UINT32 %1 EQ RETURN( %3 )    ; índice 1 de Vector para Var
	mov 	esi, [%1]         ; Endereço do Índice 1 para ESI
	mov 	ebx, [esi]         ; Valor de ESI para EBX
	mov 	[%1], ebx         ; Valor de EBX para Var
%ENDMACRO

; ============================================

; =====================================================================
; Macro Functions Library

%DEFINE Prints(ARG1, ARG2, ARG3)  STR.Write ARG1, ARG2, ARG3
%DEFINE Printz(ARG1, ARG2)        STR.Write_Till_Zero ARG1, ARG2
%DEFINE Get_Hexa8(ARG1, ARG2)     STR.Get_Hexa_8  ARG1, ARG2
%DEFINE Get_Hexa16(ARG1, ARG2)    STR.Get_Hexa_16 ARG1, ARG2
%DEFINE Get_Hexa32(ARG1, ARG2)    STR.Get_Hexa_32 ARG1, ARG2
%DEFINE HEX.ToString(ARG1, ARG2)  STR.Get_Hexa_32 ARG1, ARG2
%DEFINE Get_Dec32(ARG1, ARG2)     STR.Get_Dec_32 ARG1, ARG2
%DEFINE INT.ToString(ARG1, ARG2)  STR.Get_Dec_32 ARG1, ARG2
%DEFINE FLOAT.ToString(ARG1, ARG2, ARG3, ARG4)  STR.Get_Float_32 ARG1, ARG2, ARG3, ARG4
%DEFINE Malloc(ARG1, ARG2)        VEC.Malloc_Func ARG1, ARG2
%DEFINE Free(ARG1)                VEC.Free_Func ARG1
%DEFINE Handler_Register(X, Y)	  IRQ.Handler_Register X, Y
%DEFINE STR.ToInt(X)		  	  STR.To_Int X

%DEFINE IF.EQUAL(ARG1, ARG2, ARG3)	JUMP.IF_EQUAL ARG1, ARG2, ARG3

%DEFINE RETURN(OFFS)              ESI, OFFS

%MACRO JUMP.IF_EQUAL 3
	push 	esi
	push 	edi
	push 	ecx
	jmp 	0x08:%%Comparing
	
	%%Const db %2,0
	%%Const.Size dd ($ - %%Const)
	
	%%Comparing:
		mov 	esi, %1
		mov 	edi, %%Const
		mov 	ecx, [%%Const.Size]
		repe 	cmpsb
		pop 	ecx
		pop 	edi
		pop 	esi
		je	 	%3
%ENDMACRO

%MACRO STR.Write 3
	jmp 	0x08:%%String
	%IF %1 == 's'
		%%Data: db %3
		%%Data.Length dd ($ - %%Data)
		%%String:
			mov 	esi, %%Data
			mov 	ecx, dword[ %%Data.Length ]
	%ELIF %1 == 'i'
		%%String:
			mov 	esi, %3
	%ELIF %1 == 'c'
		%%String:
			mov 	esi, %3
			mov 	ecx, 1
	%ELSE
		%%String:
			mov 	esi, %3
			;mov 	ecx, word[ %3.length ]
			mov 	ecx, 1
	%ENDIF
		mov 	dl, %2
		call 	__SYS_WRITE
%ENDMACRO

%MACRO STR.Write_Till_Zero 2
	push 	DWORD %2
	push    DWORD %1
	call 	__SYS_WRITE_TILL_ZERO
	STR.Restore_Args1
%ENDMACRO

%MACRO STR.Restore_Args1 0
	pop 	edx
	pop     esi
%ENDMACRO

%MACRO STR.Get_Hexa_8 2
	push 	DWORD %2
	mov 	bx, %1
	xor 	bh, bh
	push 	bx
	call 	__SYS_GET_HEXA_8
	add 	esp, 6
%ENDMACRO

%MACRO STR.Get_Hexa_16 2
	push 	DWORD %2
	push 	WORD  %1
	call 	__SYS_GET_HEXA_16
	add 	esp, 6
%ENDMACRO

%MACRO STR.Get_Hexa_32 2
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_GET_HEXA_32
	add 	esp, 8
%ENDMACRO

%MACRO STR.Get_Dec_32 2
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_GET_DEC_32
	add 	esp, 8
%ENDMACRO

%MACRO STR.Get_Float_32 4
	push 	DWORD %4
	push 	DWORD %3
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_FLOAT_DEC_32
	pop 	eax
	pop 	eax
	pop 	eax
	pop 	eax
%ENDMACRO

%MACRO STR.To_Int 1
	push 	DWORD %1
	call 	__SYS_STR_TO_INT
	add 	esp, 4
%ENDMACRO

%MACRO VEC.Malloc_Func 2
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_MALLOC_FUNC
	add 	esp, 8
%ENDMACRO

%MACRO VEC.Free_Func 1
	push 	DWORD %1
	call 	__SYS_FREE_FUNC
	add 	esp, 4
%ENDMACRO

%MACRO IRQ.Handler_Register 2
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_HANDLER_REGISTER
	add 	esp, 8
%ENDMACRO
; Print X Bytes on Screen
; void SYS_WRITE(char *String)
__SYS_WRITE:
	pushad
	mov 	eax, 0x00
	int 	0xCE
	popad
ret

; Print a String on Screen zero-terminated
; void SYS_WRITE_TILL_ZERO(int color, char* String)
; color  = 8
; String = 12
; ebp
__SYS_WRITE_TILL_ZERO:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x01
	mov 	edx, DWORD [ebp + 8]
	mov 	esi, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret

; Fill a buffer with a 8-bit hexadecimal value
; void SYS_GET_HEXA_8(uint8_t number, char* String)
; number  = 8
; String  = 10
; ebp
__SYS_GET_HEXA_8:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x22
	mov 	bx, WORD [ebp + 8]
	mov 	edi, DWORD [ebp + 10]
	int 	0xCE
	
	pop ebp
ret

; Fill a buffer with a 16-bit hexadecimal value
; void SYS_GET_HEXA_16(uint16_t number, char* String)
; number  = 8
; String  = 10
; ebp
__SYS_GET_HEXA_16:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1D
	mov 	bx, WORD [ebp + 8]
	mov 	edi, DWORD [ebp + 10]
	int 	0xCE
	
	pop ebp
ret

; Fill a buffer with a 32-bit hexadecimal value
; void SYS_GET_HEXA_32(int number, char* String)
; number  = 8
; String  = 12
; ebp
__SYS_GET_HEXA_32:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1C
	mov 	ebx, DWORD [ebp + 8]
	mov 	edi, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret


; Fill a buffer with a 32-bit decimal value
; void SYS_GET_DEC_32(int number, char* String)
; number  = 8
; String  = 12
; ebp
__SYS_GET_DEC_32:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1E
	mov 	ebx, DWORD [ebp + 8]
	mov 	edi, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret

; Parse a String value to INT
; int __SYS_STR_TO_INT(char* String)
; String  = 8
; Return  = eax = number
__SYS_STR_TO_INT:
	push 	ebp
    mov 	ebp,esp
	
	mov 	DWORD[sums], 0
	mov 	esi, [ebp + 8]
	call 	strlen
	mov 	ecx, eax
	
	push 	ecx
	xor 	edx, edx
	mov 	eax, 1
	mov 	ebx, 10
	dec 	ecx
	jz 		no_build
build_base:
	mul 	ebx
	loop 	build_base
no_build:
	mov 	ebx, eax
	pop 	ecx
	cld
	
parse_numbs:
	xor 	eax, eax
	lodsb
	sub 	al, '0'
	mul 	ebx
	add 	[sums], eax
	mov 	eax, ebx
	xor 	edx, edx
	div 	DWORD [den]
	mov 	ebx, eax
	loop 	parse_numbs
	
	mov 	eax, [sums]
	pop ebp
ret
den 		dd 10
sums 		dd 0

strlen:
	pushad
	mov 	DWORD [countchars], 0
count_str:
	inc 	esi
	inc 	DWORD [countchars]
	cmp 	byte[esi], 0
	jnz 	count_str
	popad
	mov 	eax, [countchars]
ret
countchars 	dd 0

; Fill a buffer with a 32-bit float value
; void SYS_GET_DEC_32(int number, char* String, int count)
; number  = 8
; String  = 12
; ebp
__SYS_FLOAT_DEC_32:
	push 	ebp
    mov 	ebp,esp
	
	mov 	ecx, [ebp + 20]
	dec 	ecx
	fld 	qword [fconst]
	fst 	qword [inte]
loop_mul:
	fmul 	qword [inte]
	loop 	loop_mul
	
	fst 	qword [inte]
	
	mov 	eax, [ebp + 8]
	mov 	[fvalue], eax
	mov 	eax, [ebp + 12]
	mov 	[fvalue+4], eax
	
	fld 	qword [fvalue]
	fmul 	qword [inte]
	fistp 	qword [fresul]
	
	mov 	eax, 0x21
	mov 	ebx, [fresul]
	mov 	edi, DWORD [ebp + 16]
	mov 	edx, DWORD [ebp + 20]
	int 	0xCE
	
	pop ebp
ret
inte: 	dq 0
fvalue: dq 0
fresul: dq 0
fconst: dq 10.0

; Allocation of Memory Buffer
; void* SYS_MALLOC_FUNC(int size, int sizeof)
; size  = 8 (ECX)
; sizeof  = 12 (EBX)
; ebp
__SYS_MALLOC_FUNC:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1F
	mov 	ecx, DWORD [ebp + 8]
	mov 	ebx, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret

; Unallocation of buffer
; void SYS_FREE_FUNC(int *addr)
; addr  = 8
; ebp
__SYS_FREE_FUNC:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x20
	mov 	ebx, DWORD [ebp + 8]
	int 	0xCE
	
	pop ebp
ret

; Fill a buffer with a 32-bit decimal value
; void SYS_HANDLER_REGISTER(int irq, int* address)
; irq  = 8
; address = 12
__SYS_HANDLER_REGISTER:
	push 	ebp
	mov 	ebp, esp
	
	mov 	eax, 0x23
	mov 	ebx, DWORD [ebp + 8]
	mov 	esi, DWORD [ebp + 12]
	int 	0xCE
	
	pop 	ebp
ret


; =====================================================================


; =====================================================================
; PCI Macros & Functions

%DEFINE Get_Class_Number(X, Y, Z)  PCI.Get_Device_Number X, Y, Z
%DEFINE Get_Class_Name(X, Y, Z)    PCI.Get_Class_Name X, Y, Z
%DEFINE Get_SubClass_Name(X, Y, Z) PCI.Get_SubClass_Name X, Y, Z
%DEFINE Restore_Args(X, Y, Z)      PCI.Restore_Args X, Y, Z


%MACRO PCI.Get_Device_Number 3
	push 	WORD %3
	push    WORD %2
	push  	WORD %1
	call 	__Get_Class_Device
%ENDMACRO

%MACRO PCI.Get_Class_Name 3
	push 	WORD %3
	push    WORD %2
	push  	WORD %1
	call 	__Get_Class_Name
%ENDMACRO

%MACRO PCI.Get_SubClass_Name 3
	push 	WORD %3
	push    WORD %2
	push  	WORD %1
	call 	__Get_SubClass_Name
%ENDMACRO

%MACRO PCI.Restore_Args 3
	pop 	WORD %1
	pop     WORD %2
	pop  	WORD %3
%ENDMACRO

%MACRO PCI.Restore_Args1 0
	pop 	ax
	pop     bx
	pop  	dx
%ENDMACRO

; Return a Device Class Number
; unsigned short Get_Class_Device(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
__Get_Class_Device:
    push 	ebp
    mov 	ebp,esp

    mov 	eax,0x1B
    mov 	bx, word [ebp + 8]
	shl 	bx, 8
    or  	bx, word [ebp + 10]
    mov 	cx, word [ebp + 12]
    int 	0xCE

    pop ebp
    ret
	
;
; Return a Class Name Device
; char* Get_Class_Name(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
__Get_Class_Name:
    push 	ebp
    mov 	ebp,esp

    mov 	eax,0x16
    mov 	bx, word [ebp + 8]
	shl 	bx, 8
    or  	bx, word [ebp + 10]
    mov 	cx, word [ebp + 12]
    int 	0xCE

    pop ebp
    ret
	
;
; Return a SubClass Name Device
; char* Get_SubClass_Name(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
__Get_SubClass_Name:
    push 	ebp
    mov 	ebp,esp

    mov 	eax,0x17
    mov 	bx, word [ebp + 8]
	shl 	bx, 8
    or  	bx, word [ebp + 10]
    mov 	cx, word [ebp + 12]
    int 	0xCE

    pop ebp
    ret
; =====================================================================