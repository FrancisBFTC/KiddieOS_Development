; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  DEVMGR.KXE API
;             APPLICATION DATA & FUNCTIONS
;
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%IFNDEF 	__LIBDVMGR_INC__
%DEFINE 	__LIBDVMGR_INC__

%INCLUDE 	"RadixSort.inc"

Colc1       db " [",0
Colc2       db "]",0
Buffer      db "0000",0
Buffer1     db 0,0,0,0,0,0,0,0,0,0
Connect1    db "|___",0
Connect2    db 0x0D,"|___",0
Space       db 0x0D,"|   ",0 
PCI         db "PCI:",0
StrScan     db 0x0D,"Scanning Devices...",0x0D,0
StrFound    db " Devices Was Found!",0x0D,0
StrTree     db "Building tree structure...",0x0D,0x0D,0

countstore  dd 0
countstack  dd 1
stack 		dd 0
stackm 		dd 0
highid      db 0
lowid 		db 0


__build_sequential_struct:
	mov 	DWORD[stack], esp
	sub 	DWORD[stack], 300
	mov 	DWORD[stackm], esp
	sub 	DWORD[stackm], 200
	
	Printz(0x0F, StrScan)
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
			Get_Class_Number(ax, bx, dx)
			cmp 	ax, 0xFFFF
			je 		Skip_Store
			
			inc 	DWORD [countstore]
			
			mov 	ebx, 2
			mov 	ecx, DWORD[countstack]
			mov 	esi, DWORD[stackm]
			cmp 	DWORD[countstore], 1
			ja 		Comp_Class
			mov 	al, byte[highid]
			mov 	ebp, esp
			mov 	esp, DWORD[stackm]
			push 	ax
			mov 	esp, ebp
			mov 	ebp, esp
			mov 	esp, DWORD[stack]
			xor 	ecx, ecx
			push 	ecx
			mov 	DWORD[stack], esp
			mov 	esp, ebp
			jmp 	Skip_Store
			
		Comp_Class:
			sub 	esi, 2
			cmp 	BYTE[esi + 1], ah
			je 		Inc_Low_ID
			add 	ebx, 2
			loop 	Comp_Class
			mov 	ebp, esp
			mov 	esp, DWORD[stackm]
			sub 	esp, ebx
			add 	esp, 2
			add 	byte[highid], 0x10
			mov 	al, byte[highid]
			push 	ax
			mov 	esp, ebp
			inc 	DWORD[countstack]
			Restore_Args(ax, bx, dx)
		Inc_High_ID:	
			; Incrementar ID Alto & Salva parâmetros PCI
			mov 	ebp, esp
			mov 	esp, DWORD[stack]
			xor 	ecx, ecx
			mov 	cl, byte[highid]
			shl 	ecx, 8
			mov 	cl, al
			shl 	ecx, 8
			mov 	cl, bl
			shl 	ecx, 8
			mov 	cl, dl
			push 	ecx
			mov 	DWORD[stack], esp
			mov 	esp, ebp
			inc 	edx
			pop 	ecx
			dec 	ecx
			cmp 	ecx, 0
			jnz 	scan_func

		Inc_Low_ID:
			; Incrementar ID Baixo
			mov 	ax, WORD[esi]
			inc 	al
			mov 	WORD[esi], ax
			mov 	BYTE[lowid], al
			Restore_Args(ax, bx, dx)
			mov 	ebp, esp
			mov 	esp, DWORD[stack]
			xor 	ecx, ecx
			mov 	cl, byte[lowid]
			shl 	ecx, 8
			mov 	cl, al
			shl 	ecx, 8
			mov 	cl, bl
			shl 	ecx, 8
			mov 	cl, dl
			push 	ecx
			mov 	DWORD[stack], esp
			mov 	esp, ebp
			inc 	edx
			pop 	ecx
			dec 	ecx
			cmp 	ecx, 0
			jnz 	scan_func
			
		Skip_Store:	
			Restore_Args(ax, bx, dx)
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

__show_amount_devices:
	Get_Dec32([countstore], Buffer1)
	pop		eax
	pop 	esi
	Printz(0x02, esi)
	Printz(0x0F, StrFound)	
	Printz(0x0F, StrTree)
	Printz(0x03, PCI)
ret

__show_hierarchical_visual:
	mov 	ecx, [countstore]
	mov 	esi, [stack]
	call 	RadixSort
Loop_Tree:
	push 	ecx
	push 	esi
	
	mov 	eax, DWORD[esi]
	and 	eax, 0x00FF0000
	shr 	eax, 16
	mov 	ebx, DWORD[esi]
	and 	ebx, 0x0000FF00
	shr 	ebx, 8
	mov 	edx, DWORD[esi]
	and 	edx, 0x000000FF
	mov 	ecx, DWORD[esi]
	and 	ecx, 0x0F000000
	shr 	ecx, 24
	push 	eax
	push 	ebx
	push 	edx
	
	cmp 	ecx, 0
	jz 		Print_Class_Name
	
	Printz(0x0F, Space)
	Printz(0x0F, Connect1)
	pop 	edx
	pop 	ebx
	pop 	eax
	Get_SubClass_Name(ax, bx, dx)
	Printz(0x06, esi)
	Restore_Args(ax, bx, dx)
	Get_Class_Number(ax, bx, dx)
	Get_Hexa16(ax, Buffer)
	Printz(0x06, Colc1)
	pop  ax
	pop  esi
	Printz(0x05, esi)
	Printz(0x06, Colc2)
	Restore_Args(ax, bx, dx)
	jmp 	Return_Loop_Tree
	
Print_Class_Name:
	Printz(0x0F, Space)
	Printz(0x0F, Connect2)
	pop 	edx
	pop 	ebx
	pop 	eax
	Get_Class_Name(ax, bx, dx)
	Printz(0x07, esi)
	Printz(0x0F, Space)
	Printz(0x0F, Connect1)
	Restore_Args(ax, bx, dx)
	Get_SubClass_Name(ax, bx, dx)
	Printz(0x06, esi)
			
	Restore_Args(ax, bx, dx)
	Get_Class_Number(ax, bx, dx)
	Get_Hexa16(ax, Buffer)
	Printz(0x06, Colc1)
	pop  ax
	pop  esi
	Printz(0x05, esi)
	Printz(0x06, Colc2)
	Restore_Args(ax, bx, dx)
	
Return_Loop_Tree:
	pop 	esi
	add 	esi, 4
	pop 	ecx
	dec 	ecx
	cmp 	ecx, 0
	jnz  	Loop_Tree
	
	Printz(0x0F, Connect2)
ret

%ENDIF 