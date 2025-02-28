; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;        	 Math 32-bit ELF/KXE Library
;			 Specific High-level Library
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; Implement functions like:
;	Sum
;	Subtract
;	Divide
;	Multiply
;	Exp
;	Pow
;	Sqrt
;	Average
;	AverageVector
;	Percent
;	BooleanAlgebra
;	LinearAlgebra
;	Cos
;	Sin
;	Tan
;	Sec
; 	Sort
;	... More available functions

align 4
ops_table:
	db '*', '/', '+', '-', '%', '&', '|'
ops_table.size equ ($-ops_table)
funcs_table:
	dd expr_mul
	dd expr_div
	dd expr_add
	dd expr_sub
	dd expr_mod
	dd expr_and
	dd expr_or
funcs_table_float:
	dd expr_fmul
	dd expr_fdiv
	dd expr_fadd
	dd expr_fsub
	; TODO: implement the AND, OR and MOD to float
	
parenthesis db 0
size_expr 	dd 0
stack_base 	dd 0
mul_found 	db 0
div_found	db 0
add_found	db 0
sub_found	db 0
is_float 	db 0
decimals 	db 0

format_buffer 	times 100 db 0

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Build the result through the expression
; IN : ESI = Expression string
; OUT: EAX = Operations result
expr_parse:
	call 	expr_format
	mov 	esi, eax
	mov 	[stack_base], esp
parse_digits:
	xor 	eax, eax
	call 	get_digits_count
	call 	str_to_int
push_values:
	push 	eax		; store the number
	cmp 	byte[parenthesis], 0
	jz 		ret_result
	call 	skip_space
	call 	get_operation
	jc 		pop_values
	push 	eax		; store the operation
	inc 	esi
	call 	skip_space
	jmp 	parse_digits
pop_values:
	call 	get_calc	; restore and calc all the currently numbers
	jc 		push_values2
	add 	esp, 12
	jmp 	push_values
push_values2:
	add 	esp, 4
	jmp 	push_values
ret_result:
	pop 	eax
	ret
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ---------------------------------------------------------
; Get digits amount and increment parenthesis counter
; IN : ESI = Expression String
; OUT: EAX = digits amount
;	   ESI = Next numeric term end
;	   parenthesis = opened amount
get_digits_count:
	cmp 	byte[esi], '('
	jz 		inc_parenthesis
	cmp 	byte[esi], '0'
	jb 		ret.get_digits
	cmp 	byte[esi], '9'
	ja 		ret.get_digits
	inc 	eax
	inc 	esi
	jmp 	get_digits_count
inc_parenthesis:
	inc 	byte[parenthesis]
	inc 	esi
	jmp 	get_digits_count
ret.get_digits:
	ret
; ---------------------------------------------------------

; ---------------------------------------------------------
; Convert/Parse String to Integer
; IN : EAX = Digits ammount
;      ESI = Numeric term end
; OUT: EAX = Converted value number
str_to_int:
	push 	esi
	movzx 	ebx, byte[esi]
	mov 	byte[esi], 0
	sub 	esi, eax
	push 	ebx
	STR.ToInt(esi)
	pop 	ebx
	pop 	esi
	mov 	[esi], bl
ret
; ---------------------------------------------------------

copy_float:
	push 	edi
	mov 	edi, float_buf
start_copy:
	cmp 	byte[esi], '('
	jz 		inc_parenthesis_1
	cmp 	byte[esi], '0'
	jb 		check_digit
	cmp 	byte[esi], '9'
	ja 		check_digit
	movsb
	jmp 	start_copy
inc_parenthesis_1:
	inc 	byte[parenthesis]
	inc 	esi
	jmp 	start_copy
check_digit:
	cmp 	byte[esi], '.'
	jnz 	ret.copy_float
	inc 	esi
	call 	copy_decimals
ret.copy_float:
	call 	str_to_float
	mov 	byte[decimals], 0
	mov 	edi, float_buf
	call 	clear_buffer
	pop 	edi
ret

float_buf 	times 20 db 0

clear_buffer:
	push 	eax
	xor 	eax, eax
	mov 	ecx, 20
	rep 	stosb
	pop 	eax
ret

copy_decimals:
	cmp 	byte[esi], '0'
	jb 		ret.copy_decimals
	cmp 	byte[esi], '9'
	ja 		ret.copy_decimals
	inc 	byte[decimals]
	movsb
	jmp 	copy_decimals
ret.copy_decimals:
	ret
	
str_to_float:
	push 	esi
	
	movzx 	ecx, byte[decimals]
	mov 	eax, 10
	call 	fexp
	
	;pushad
	;FLOAT.ToString(0, [num1],temp, 2)
	;Printz(0x05, temp)
	;popad
	;jmp 	$
	
	push 	eax
	mov 	esi, float_buf
	STR.ToInt(esi)
	pop 	ebx
	
	mov 	[num2], ebx
	mov 	[num1], eax
	fld 	dword[num1]
	fdiv 	dword[num2]
	fistp 	dword[num1]
	mov 	eax, [num1]
	
	pop 	esi
ret

VCHAR temp @ 5  EQ 0

fexp:
	fld 	dword[cons]
	fst 	dword[num1]
	dec 	ecx
	cmp 	ecx, 0
	jz 		no_loop_exp
	cmp 	ecx, -1
	jz 		move_1.0
loop_exp:
	fmul 	dword[num1]
	loop 	loop_exp
no_loop_exp:
	fstp 	dword[num1]
	mov 	eax, [num1]
	jmp		ret.fexp
move_1.0:
	fld 	dword[cons1]
	fstp 	dword[num1]
	mov 	eax, [num1]
ret.fexp:
	ret
	
is_float_val:
	movzx 	eax, byte[is_float]
ret
num1 dd 0
num2 dd 0
cons dd 10.0
cons1 dd 1.0
; ---------------------------------------------------------
; Skip the space on the expression if any
; IN : ESI = Expression Currently String
; OUT: ESI = Next char after spaces
skip_space:
	cmp 	byte[esi], 0x20
	jnz 	ret_skip_space
	inc 	esi
	jmp 	skip_space
ret_skip_space:
	xor 	eax, eax
	ret
; ---------------------------------------------------------
	
; ---------------------------------------------------------
; Get the operation char
; IN : ESI = Expression Currently String
; OUT: AL = Operation char (+,-,*,...)
;	   CF  = clear if it's not closed parentheses, set if is it.
get_operation:
	cmp 	byte[esi], ')'
	jz 		is_parenthesis
	movzx 	eax, byte[esi]
	clc
	ret
is_parenthesis:
	stc
	ret
; ---------------------------------------------------------

; ---------------------------------------------------------
; Restore and calc currently values from the stack
; IN : 3 PUSHES = Num1, Op, Num2
; OUT: EAX = Currently operation result
;	   CF  = clear if calculated, set if not
; Note: If CF is set, ESP += 4, otherwise, ESP += 12, afterward!
get_calc:
	dec 	byte[parenthesis]
	inc 	esi
	add 	esp, 4
	mov 	eax, esp
	add 	eax, 4
	cmp 	eax, [stack_base]
	jz 		ret.calc_ignore
	pop 	edx
	pop 	ebx
	pop 	eax
	sub 	esp, 16
	
	push 	esi
	mov 	esi, ops_table
	mov 	ecx, ops_table.size
scan_operation:
	cmp 	[esi], bl
	jz 		operation_found
	inc 	esi
	loop 	scan_operation
	pop 	esi
	clc
	ret

operation_found:
	sub 	ecx, ops_table.size
	not 	ecx
	inc 	ecx
	shl 	ecx, 2
	mov 	esi, funcs_table
	add 	ecx, esi
	;push 	eax
	;push 	edx
	;xor 	edx, edx
	;mov 	eax, funcs_table_float-funcs_table
	;movzx 	ebx, byte[is_float]
	;mul 	ebx
	;add 	ecx, eax
	;pop 	edx
	;pop 	eax
	pop 	esi
	call 	[ecx]
	clc
	ret
ret.calc_ignore:
	cld
	pop 	eax
	sub 	esp, 8
	stc
ret
; ---------------------------------------------------------
	
; ---------------------------------------------------------
; Standard arithmetic operations (CPU)
; IN : EAX = Num1, EDX = Num2
; OUT: EAX = Result
expr_add:
	add 	eax, edx
	ret
expr_sub:
	sub 	eax, edx
	ret
expr_mul:
	mov 	ebx, edx
	xor 	edx, edx
	mul 	ebx
	ret
expr_div:
	mov 	ebx, edx
	xor 	edx, edx
	div 	ebx
	ret
expr_mod:
	mov 	ebx, edx
	xor 	edx, edx
	div 	ebx
	mov 	eax, edx
	ret
expr_and:
	and 	eax, edx
	ret
expr_or:
	or 		eax, edx
	ret
expr_fadd:
	mov 	[num1], eax
	mov 	[num2], edx
	fld 	dword[num1]
	fadd 	dword[num2]
	fstp 	dword[num1]
	mov 	eax, [num1]
	ret
expr_fsub:
	mov 	[num1], eax
	mov 	[num2], edx
	fld 	dword[num1]
	fsub 	dword[num2]
	fstp 	dword[num1]
	mov 	eax, [num1]
	ret
expr_fmul:
	mov 	[num1], eax
	mov 	[num2], edx
	fld 	dword[num1]
	fmul 	dword[num2]
	fstp 	dword[num1]
	mov 	eax, [num1]
	ret
expr_fdiv:
	mov 	[num1], eax
	mov 	[num2], edx
	fld 	dword[num1]
	fdiv 	dword[num2]
	fstp 	dword[num1]
	mov 	eax, [num1]
	ret
	
; ---------------------------------------------------------

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Copy and Format expression
; IN : ESI = Expression currently string
; OUT: EAX = New Buffer String Address
expr_format:
	call 	skip_space
	mov 	edi, format_buffer
	call 	strlen
	mov 	[size_expr], eax
	mov 	ecx, [size_expr]
	call 	copy_expr
	xor 	ebx, ebx
	mov 	ecx, ops_table.size
format_expr:
	mov 	al, [ops_table + ebx]
	call 	find_ops_char
	inc 	ebx
	loop 	format_expr
	mov 	eax, format_buffer
ret
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ---------------------------------------------------------
; Copy string from src to dest and change orders
; IN : ESI = String source
;      EDI = String destiny
;	   ECX = String size
; OUT: EDI = With new string
copy_expr:
	push 	edi
copy_loop:
	;call 	check_if_float
	call 	check_1st_order
	movsb
	loop 	copy_loop
	call 	order_exchange
	pop 	edi
ret
; ---------------------------------------------------------

check_if_float:
	cmp 	byte[esi], '.'
	jz 		set_float
	cmp 	byte[esi], '/'
	jz 		set_float
	ret
set_float:
	mov 	byte[is_float], 1
	ret

; ---------------------------------------------------------
; Check the order of precendence and set states
; IN : ESI = Expression currently string
; OUT: Nothing (only variables set)
check_1st_order:
	cmp 	byte[mul_found], 0
	jnz 	check_2nd_order
	cmp 	byte[div_found], 0
	jnz 	check_2nd_order
	cmp 	byte[esi], '*'
	sete 	byte[mul_found]
	cmp 	byte[esi], '/'
	sete 	byte[div_found]
check_2nd_order:
	cmp 	byte[add_found], 0
	jnz 	no_set_order
	cmp 	byte[sub_found], 0
	jnz 	no_set_order
	cmp 	byte[esi], '+'
	sete 	byte[add_found]
	cmp 	byte[esi], '-'
	sete 	byte[sub_found]
no_set_order:
	ret
; ---------------------------------------------------------
	
; ---------------------------------------------------------
; Exchange the operations from operations
; IN : Nothing (only exchanges)
; OUT: Nothing (only variables set)
order_exchange:
	cmp 	byte[div_found], 1
	jnz 	xchg_add
	mov 	bx, [ops_table]
	mov 	[ops_table], bh
	mov 	[ops_table + 1], bl
	mov 	ebx, [funcs_table]
	mov 	ecx, [funcs_table + (1 << 2)]
	mov 	[funcs_table], ecx
	mov 	[funcs_table + (1 << 2)], ebx
xchg_add:
	cmp 	byte[sub_found], 1
	jnz 	xchg_ret
	mov 	bx, [ops_table + 2]
	mov 	[ops_table + 2], bh
	mov 	[ops_table + 3], bl
	mov 	ebx, [funcs_table + (2 << 2)]
	mov 	ecx, [funcs_table + (3 << 2)]
	mov 	[funcs_table + (2 << 2)], ecx
	mov 	[funcs_table + (3 << 2)], ebx
xchg_ret:
	ret
; ---------------------------------------------------------

; ---------------------------------------------------------
; Scan the currently operation char and format
; IN : AL = Currently operation char
;      EDI = New Expression String Copied
; OUT: Nothing - All registers preserved
find_ops_char:
	pushad
	mov 	ecx, [size_expr]
loop_ops:
	cld
	repnz 	scasb
	jnz 	ret.find_ops_char
	
	dec 	edi
	call 	build_expr_func
	inc 	edi
	inc 	ecx
	
	jmp 	loop_ops
ret.find_ops_char:
	popad
	ret
; ---------------------------------------------------------

; ---------------------------------------------------------
; Build the sub-expression (math function)
; IN : EDI = New Expression String Copied
; OUT: Nothing
build_expr_func:
	push 	eax
	push 	ecx
	
	mov 	bx, 0x2928				; Código para abertura de parentesis
	mov 	eax, -1					; Direção esquerda de atribuição na expressão
	call 	attrib_parenthesis		; Atribua parentesis de abertura
	mov 	bx, 0x2829				; Código para fechadura de parentesis
	mov 	eax, 1					; Direção direita de atribuição na expressão
	call 	attrib_parenthesis		; Atribua parentesis de fechadura
	
	pop 	ecx
	pop 	eax
ret
; ---------------------------------------------------------

; ---------------------------------------------------------
; Attrib parentheses on right and left from operation
; IN : EDI = New Expression String Copied
; 	   EAX = Direction -> 1: right; -1: left;
;      BX  = Parentheses code -> ')(': left; '()': right
; OUT: Nothing
attrib_parenthesis:
	push 	edi					; endereço da operação
	add 	edi, eax
	call 	skip_space_char
	call 	check_parenthesis
	jnc 	store_parenth
	call 	find_num_pos
	call 	pointer_normalize
store_parenth:
	call 	displace_expr
	mov 	byte[edi], bl
	pop 	edi					; endereço da operação
	call 	pointer_normalize
ret_attrib_parenth:
	ret

; Regularize EDI pointer if BL = '('	
pointer_normalize:
	cmp 	bl, '('
	jnz 	ret_point_norm
	inc 	edi
ret_point_norm:
	ret
; ---------------------------------------------------------

; ---------------------------------------------------------
; Skip the space char on the string
; IN : EDI = New Expression String Copied
; 	   EAX = Direction -> 1: right; -1: left;
; OUT: EDI = New position that is not space
skip_space_char:
	cmp 	byte[edi], 0x20
	jnz 	ret_skip_char
	add 	edi, eax
	jmp 	skip_space_char
ret_skip_char:
	ret
; ---------------------------------------------------------
	
; ---------------------------------------------------------
; Check if there are parentheses obstacles and jump them
; IN : EDI = New Expression String Copied
; 	   EAX = Direction -> 1: right; -1: left;
;      BX  = Parentheses code -> ')(': left; '()': right
; OUT: EDI = Correct position to add currently parentheses
;	   CF  = clear if obstacle parentheses found, set if not
check_parenthesis:
	cmp 	byte[edi], bh
	jnz 	ret_parenthesis
inc_par:
	inc 	byte[parenthesis]
inc_par_loop:
	add 	edi, eax
	cmp 	byte[edi], bh
	jz 		inc_par
	cmp 	byte[edi], bl
	jz 		dec_par
	jmp 	inc_par_loop
dec_par:
	dec 	byte[parenthesis]
	cmp 	byte[parenthesis], 0
	jnz 	inc_par_loop
	clc
	ret
ret_parenthesis:
	stc
	ret
; ---------------------------------------------------------
	
; ---------------------------------------------------------
; Find next number position
; IN : EDI = First/last number position
; 	   EAX = Direction -> 1: right; -1: left;
; OUT: EDI = Correct position to add currently parentheses
find_num_pos:
	cmp 	byte[edi], '0'
	jb 		ret_find_pos
	cmp 	byte[edi], '9'
	ja 		ret_find_pos
inc_dec_edi:
	add 	edi, eax
	jmp 	find_num_pos
ret_find_pos:
	cmp 	byte[edi], '.'
	jz 		inc_dec_edi
	ret
; ---------------------------------------------------------
	
; ---------------------------------------------------------
; Displace string forward, opening space for new parentheses
; IN : EDI = New parenthesis position
; OUT: Nothing (only free position space)
displace_expr:
	push 	edi
	std
	mov 	ecx, [size_expr]
	mov 	eax, edi
	sub 	eax, format_buffer
	sub 	ecx, eax
	add 	edi, ecx
	cmp 	ecx, 0
	jz 		ret_disp_expr
displace_str:
	dec 	edi
	mov 	al, [edi]
	inc 	edi
	stosb
	loop 	displace_str
ret_disp_expr:
	inc 	byte[size_expr]
	cld
	pop 	edi
ret
; ---------------------------------------------------------