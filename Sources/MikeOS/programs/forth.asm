; *****************************************************************************
; *
; *           Forth operating system for an IBM Compatible PC (ver 1.53)
; *                       Copyright (C) 1993-2013 W Nagel
; *         Copyright (C) 2014-2020 MikeOS Developers -- see doc/LICENSE.TXT
; *
; * For the most part it follows the FIG model, Forth-79 standard
; * There are differences, however
; *
; *****************************************************************************
; Some assemblers have trouble with [BP]; always use offset, e.g. [BP+0]
; *****************************************************************************
; Some machines use subroutine threading (use SP for R stack) - this is 
;   considered Forth-like, and not true Forth.  Also, the 8086 does not support 
;   [SP] and there are many more PUSH (1 byte) than RPUSH (4 bytes) instructions.
;   This would be a poor choice for this processor.
;
; CFA = Compilation (or Code) Field Address.
; A Forth header =
;		LFA	address of previous word in chain, last one = 0
;		NFA	count(b4-0)/flags(b7=immediate, b5=smudge) + name
;		CFA	points to executable code for this definition
;		PFA	may contain Forth threads, machine code or parameters
; *****************************************************************************
; source previously converted to nasm's macro processor

	cr	equ  13		; carriage return
	lf	equ  10		; line feed
	bell	equ   7		; bell (sort of)
	spc	equ  32		; space
	bs	equ   8		; back space
	del	equ 127		; 'delete' character

; Compile for PC DOS, .com or boot load, or MikeOS (0/1)
MikeOS equ 1
Def_Com equ 0

; A vocabulary is specified by a number between 1 and 15. See 'vocabulary' for a short
; discussion. A minimum of (2* highest vocabulary) dictionary threads are needed to 
; prevent 'collisions' among the vocabularies. Initial compilation is entirely in the
; 'FORTH' vocabulary.
  VOC EQU 1				; specify FORTH part of Dictionary for this build

  size		EQU 65536

; Setup for NAsm
;-------------------------------------------------------------------
  bits	16			; nasm, 8086
  cpu   286

  first		EQU size & 0xffff	; 65536 or memory end for single segment 8086
  stack0	EQU size - 128		; R Stack & text input buffer

%macro NEXT 0			; mov di,[si] + inc si (twice) => couple extra bytes & many cycles
	lodsw
	xchg ax,di		; less bytes than mov, just as fast
	jmp [di]		; 4 bytes
%endmacro

%macro RPUSH 1
	dec bp
	dec bp
	mov word [bp+0],%1
%endmacro

%macro RPOP 1
	mov word %1,[bp+0]
	inc bp
	inc bp
%endmacro

%assign IMM 0			; next word is not IMMEDIATE
%macro IMMEDIATE 0		; the following word is immediate
	%assign IMM 080h
%endmacro

%assign defn 0			; definition counter to create unique label
%define @def0 0			; no definitions yet, mark as end of chain

%macro HEADING 1
	%assign t1 defn		; unique label for chaining definitions
	%assign defn defn+1	; increment label

	%strlen lenstrng %1	; get length of name

	@def %+ defn: dw @def %+ t1	; temporary LFA -- first startup rearranges into chains
	db IMM+lenstrng, %1		; turn name into counted string with immediate indicator

	%assign IMM 0		; next word is not immediate, by default
%endmacro

				; One memory segment for .com, 1/2 segment for MikeOS
				; future - consider separate stack and/or disk buffer seg
%if MikeOS
	%include "mikedev.inc"
	org	0x8000
%else
%if Def_Com
	org	0x0100			; .com
%else
	org	0			; boot loader or Flex86
%endif
%endif
;-------------------------------------------------------------------

	jmp     do_startup	; code that changes is mostly at end
				; first heading is not a offset zero of program

; Nucleus / Core -- ground 0

; Single precision (16-bit) Arithmetic operators
; CODE used extensively for speed in core

HEADING '*'			; ( n1 n2 -- n ) creates link and name fields
  mult:		dw $ + 2	; code field
	pop di			; parameter field -> code
	pop ax
	mul di
	push ax
	NEXT

HEADING '*/'			; ( n1 n2 n3 -- n )
		dw $ + 2
	pop di
	pop dx
	pop ax
	imul dx
	idiv di
	push ax
	NEXT

HEADING '*/MOD'			; ( u1 u2 u3 -- r q )
		dw $ + 2
	pop di
	pop dx
	pop ax
	mul dx
	div di
	push dx
	push ax
	NEXT

HEADING '+'			; ( n1 n2 -- n )
  plus:		dw $ + 2
	pop dx
	pop ax
	add ax,dx
	push ax
	NEXT

HEADING '-'			; ( n1 n2 -- n )
  minus:        dw $ + 2
	pop dx
	pop ax
	sub ax,dx
	push ax
	NEXT

HEADING '/'			; ( n1 n2 -- n )
  divide:       dw $ + 2
	pop di
	pop ax
	CWD
	idiv di         ; use di register for all divisions
	push ax         ; so that div_0 interrupt will work
	NEXT

HEADING '/MOD'			; ( u1 u2 -- r q )
		dw $ + 2
	pop di
	pop ax
	sub dx,dx	; zero extend word
	div di
	push dx
	push ax
	NEXT

HEADING '1+'			; ( n -- n+1 )
  one_plus:     dw $ + 2
	pop ax
	inc ax
	push ax
	NEXT

HEADING '1+!'			; ( a -- )
  one_plus_store: dw $ + 2
	pop di
	inc word [di]
	NEXT

HEADING '1-'			; ( n -- n-1 )
  one_minus:	dw $ + 2
	pop ax
	dec ax
	push ax
	NEXT

HEADING '1-!'			; ( a -- )
		dw $ + 2
	pop di
	dec word [di]
	NEXT

HEADING '2*'			; ( n -- 2n )
  two_times:    dw $ + 2
	pop ax
	shl ax,1
	push ax
	NEXT

HEADING '2**'			; ( n -- 2**N )
		dw $ + 2
	mov ax,1
	pop cx
	and cx,0Fh
	shl ax,cl
	push ax
	NEXT

HEADING '2+'			; ( n -- n+2 )
  two_plus:     dw $ + 2
	pop ax
	inc ax
	inc ax
	push ax
	NEXT

HEADING '2-'			; ( n -- n-2 )
  two_minus:    dw $ + 2
	pop ax
	dec ax
	dec ax
	push ax
	NEXT

HEADING '2/'			; ( n -- n/2 )
		dw $ + 2
	pop ax
	sar ax,1
	push ax
	NEXT

HEADING '4*'			; ( n -- 4n )
		dw $ + 2
	pop ax
	shl ax,1
	shl ax,1
	push ax
	NEXT

HEADING '4/'			; ( n -- n/4 )
		dw $ + 2
	pop ax
	sar ax,1	; shift and sign extend
	sar ax,1
	push ax
	NEXT

HEADING 'MOD'			; ( u1 u2 -- r )
		dw $ + 2
	pop di
	pop ax
	sub dx,dx	; zero extend word
	div di
	push dx
	NEXT

HEADING 'NEGATE'		; ( n -- -n >> two's complement )
		dw $ + 2
	pop ax
  negate1:
	neg ax
	push ax
	NEXT

; not alphabetical, allow short jump
HEADING 'ABS'			; ( n -- |n| )
		dw $ + 2
	pop ax
	or ax,ax
	jl negate1
	push ax
	NEXT


; Bit and Logical operators

HEADING 'AND'			; ( n1 n2 -- n )
  cfa_and:	dw $ + 2
	pop dx
	pop ax
	and ax,dx
	push ax
	NEXT

HEADING 'COM'			; ( n -- !n >> one's complement )
		dw $ + 2
	pop ax
	not ax
	push ax
	NEXT

HEADING 'LSHIFT'		; ( n c -- n<<c )
		dw $ + 2
	pop cx
	pop ax
	and cx,0Fh              ; 16-bit word => max of 15 shifts
	shl ax,cl
	push ax
	NEXT

; similar to an alias for 0=
HEADING 'NOT'			; ( f -- !f )
  cfa_not:	dw zero_eq + 2

HEADING 'OR'			; ( n1 n2 -- n )
  cfa_or:	dw $ + 2
	pop dx
	pop ax
	or ax,dx
	push ax
	NEXT

HEADING 'RSHIFT'		; ( n c -- n>>c )
		dw $ + 2
	pop cx
	pop ax
	and cx,0Fh
	sar ax,cl
	push ax
	NEXT

HEADING 'XOR'			; ( n1 n2 -- n )
  cfa_xor:	dw $ + 2
	pop dx
	pop ax
	xor ax,dx
	push ax
	NEXT


; Number comparison

HEADING '0<'			; ( n -- f )
  zero_less:    dw $ + 2
	pop cx
	or cx,cx
  do_less:
	mov ax,0
	jge dl1
	inc ax			; '79 true = 1
;	dec ax			; '83 true = -1
  dl1:
	push ax
	NEXT

HEADING '<'			; ( n1 n2 -- f )
  less:         dw $ + 2
	pop dx
	pop cx
	cmp cx,dx
	JMP do_less

HEADING '>'			; ( n1 n2 -- f )
  greater:      dw      $ + 2
	pop cx
	pop dx
	cmp cx,dx
	JMP do_less

HEADING '0='			; ( n -- f )
  zero_eq:      dw      $ + 2
	pop cx
  test0:
	mov ax,1		; '79 true
	jcxz z2
	dec ax			; 1-1 = 0 = FALSE
  z2:
	push ax
	NEXT

HEADING '='			; ( n1 n2 -- f )
  cfa_eq:	dw	$ + 2
	pop dx
	pop cx
	sub cx,dx
	JMP test0

HEADING 'MAX'			; ( n1 n2 -- n )
		dw      $ + 2
	pop ax
	pop dx
	CMP dx,ax
	jge max1
	xchg ax,dx
  max1:
	push dx
	NEXT

HEADING 'MIN'			; ( n1 n2 -- n )
  cfa_min:	dw	$ + 2
	pop ax
	pop dx
	CMP ax,dx
	jge min1
	xchg ax,dx
  min1:
	push dx
	NEXT

HEADING 'U<'			; ( u1 u2 -- f )
  u_less:       dw      $ + 2
	sub cx,cx
	pop dx
	pop ax
	cmp ax,dx
	jnc ul1
	inc cx
  ul1:
	push cx
	NEXT

; Note: Forth 83 definition
HEADING 'WITHIN'		; ( n n2 n3 -- f >> true if n2 <= n < n3 )
  WITHIN:	dw $ + 2
	sub cx,cx	; flag, default is false
	pop dx		; high limit
	pop di		; low limit
	pop ax		; variable
	cmp ax,dx	; less than (lt) high, continue
	jge w1
	cmp ax,di	; ge low
	jl w1
	inc cx
  w1:
	push cx
	NEXT


; Normal (16-bit address) 8 and 16-bit memory reference

HEADING '!'			; ( n a -- )
  w_store:	dw $ + 2
	pop di
	pop ax
	stosw		; less bytes and just as fast as move
	NEXT

HEADING '+!'			; ( n a -- )
  plus_store:   dw $ + 2
	pop di
	pop ax
	add [di],ax
	NEXT

HEADING '@'			; ( a -- n )
  fetch:        dw $ + 2
	pop di
	push word [di]
	NEXT

HEADING 'C!'			; ( c a -- )
  c_store:      dw $ + 2
	pop di
	pop ax
	stosb		; less bytes and just as fast as move
	NEXT

HEADING 'C+!'			; ( c a -- )
		dw $ + 2
	pop di
	pop ax
	add [di],al
	NEXT

HEADING 'C@'			; ( a -- zxc >> zero extend )
  c_fetch:      dw $ + 2
	pop di
	sub ax,ax
	mov al,[di]
	push ax
	NEXT

HEADING 'FALSE!'		; ( a -- >> stores 0 in address )
  false_store:  dw $ + 2
	sub ax,ax
	pop di
	stosw
	NEXT

HEADING 'XFER'			; ( a1 a2 -- >> transfers contents of 1 to 2 )
  XFER:         dw $ + 2
	pop dx
	pop di
	mov ax,[di]
	mov di,dx
	stosw
	NEXT


; 16-bit Parameter Stack operators

HEADING '-ROT'			; ( n1 n2 n3 -- n3 n1 n2 )
  m_ROT:	dw $ + 2
	pop di
	pop dx
	pop ax
	push di
	push ax
	push dx
	NEXT

HEADING '?DUP'			; ( n -- 0, n n )
  q_DUP: 	dw $ + 2
	pop ax
	or ax,ax
	jz qdu1
	push ax
  qdu1:
	push ax
	NEXT

HEADING 'DROP'			; ( n -- )
  DROP:         dw $ + 2
	pop ax
	NEXT

HEADING 'DUP'			; ( n -- n n )
  cfa_dup:	dw $ + 2
	pop ax
	push ax
	push ax
	NEXT

HEADING 'OVER'			; ( n1 n2 -- n1 n2 n1 )
  OVER: 	dw $ + 2
	mov di,sp
	push word [di+2]
	NEXT

HEADING 'PICK'			; ( ... n1 c -- ... nc )
  PICK: 	dw $ + 2
	pop di
	dec di
	shl di,1
	add di,sp
	push word [di]
	NEXT

HEADING 'ROT'			; ( n1 n2 n3 -- n2 n3 n1 )
  ROT:          dw $ + 2
	pop di
	pop dx
	pop ax
	push dx
	push di
	push ax
	NEXT

; Note: 'push sp' results vary by processor (family and generation)
HEADING 'SP@'			; ( -- a )
  sp_fetch:     dw $ + 2
	mov ax,sp
	push ax
	NEXT

HEADING 'SWAP'			; ( n1 n2 -- n2 n1 )
  SWAP:         dw $ + 2
	pop dx
	pop ax
	push dx
	push ax
	NEXT


; Return stack manipulation

HEADING 'I'			; ( -- n >> [RP] )
  eye:  	dw $ + 2
	mov ax,[bp+0]
	push ax
	NEXT

HEADING "I'"			; ( -- n >> [RP+2] )
  eye_prime:    dw $ + 2
	mov ax,[bp+2]
	push ax
	NEXT

HEADING 'J'			; ( -- n >> [RP+4] )
		dw $ + 2
	mov ax,[bp+4]
	push ax
	NEXT

HEADING "J'"			; ( -- n >> [RP+6] )
		dw $ + 2
	mov ax,[bp+6]
	push ax
	NEXT

HEADING 'K'			; ( -- n >> [RP+8] )
		dw $ + 2
	mov ax,[bp+8]
	push ax
	NEXT

HEADING '>R'			; ( n -- >> S stack to R stack )
  to_r:         dw $ + 2
	pop ax
	RPUSH ax
	NEXT

HEADING 'R>'			; ( -- n >> R stack to S stack )
  r_from:       dw $ + 2
	RPOP ax
	push ax
	NEXT


; Constant replacements for common numbers
; CONSTANT takes 66 cycles (8086) to execute

HEADING '0'			; ( -- 0 )
  zero:         dw $ + 2
	xor ax,ax
	push ax
	NEXT

HEADING '1'			; ( -- 1 )
  one:          dw $ + 2
	mov ax,1
	push ax
	NEXT

HEADING 'BL'			; ( -- 32 )
  blnk:          dw $ + 2
	mov ax,32		; <space> or blank
	push ax
	NEXT

; Uses equivalent of 'alias'
HEADING 'FALSE'			; ( -- 0 )
	dw	zero + 2

HEADING 'TRUE'			; ( -- t )
  truu:		dw $ + 2
	mov ax,1	; '79 value
	push ax
	NEXT


; 32-bit (double cell) - standard option

HEADING '2!'			; ( d a -- )
  two_store:    dw $ + 2
	pop di
	pop dx		; TOS = high word
	pop ax		; variable low address => low word
	stosw
	mov ax,dx
	stosw
	NEXT

HEADING '2>R'			; ( n n -- >> transfer to R stack )
  two_to_r:     dw $ + 2
	pop ax
	pop dx
	RPUSH dx
	RPUSH ax
	NEXT

HEADING '2@'			; ( a -- d )
  two_fetch:    dw $ + 2
	pop di
	push word [di]		;low variable address => low word
	push word [di+2]	; low param stack address (TOS) => high word
	NEXT

HEADING '2DROP'			; ( d -- )
  two_drop:     dw $ + 2
	pop ax
	pop ax
	NEXT

HEADING '2DUP'			; ( d -- d d )
  two_dup:      dw $ + 2
	pop dx
	pop ax
	push ax
	push dx
	push ax
	push dx
	NEXT

HEADING '2OVER'			; ( d1 d2 -- d1 d2 d1 )
  two_over:     dw $ + 2
	mov di,sp
	push word [di+6]
	push word [di+4]
	NEXT

HEADING '2R>'			; ( -- n1 n2 )
  two_r_from:   dw $ + 2
	RPOP ax
	RPOP dx
	push dx
	push ax
	NEXT

HEADING '2SWAP'			; ( d1 d2 -- d2 d1 )
  two_swap:     dw $ + 2
	pop dx
	pop di
	pop ax
	pop cx
	push di
	push dx
	push cx
	push ax
	NEXT

HEADING 'D+'			; ( d1 d2 -- d )
  d_plus:       dw $ + 2
	pop dx
	pop ax
  dplus:		; used by M+
	mov di,sp
	add [di+2],ax
	adc [di],dx
	NEXT

HEADING 'D+!'			; ( d a -- )
		dw $ + 2
	pop di
	pop dx
	pop ax
	add [di+2],ax
	adc [di],dx
	NEXT

HEADING 'D-'			; ( d1 d2 -- d )
  d_minus:      dw $ + 2
	pop cx
	pop di
	pop ax
	pop dx
	sub dx,di
	sbb ax,cx
	push dx
	push ax
	NEXT

HEADING 'D0='			; ( d -- f )
  d_zero_eq:    dw $ + 2
	pop ax
	pop dx
	sub cx,cx
	or ax,dx
	jnz dz1
	inc cx		; 1, F79
;	dec cx		; -1, F83
  dz1:
	push cx
	NEXT

HEADING 'DNEGATE'		; ( d -- -d )
  DNEGATE:      dw $ + 2
	pop dx
	pop ax
	neg ax
	adc dx,0
	neg dx
	push ax
	push dx
	NEXT

; Sign extend single to double
HEADING 'S>D'			; ( n -- d )
  s_to_d:       dw $ + 2
	pop ax
	CWD
	push ax
	push dx
	NEXT

HEADING 'M*'			; ( n1 n2 -- d )
		dw $ + 2
	pop ax
	pop dx
	imul dx
	push ax
	push dx
	NEXT

HEADING 'M+'			; ( d1 n -- d )
		dw $ + 2
	pop ax
	CWD
	jmp dplus

HEADING 'M/'			; ( d n1 -- n )
		dw $ + 2
	pop di
	pop dx
	pop ax
	idiv di
	push ax
	NEXT

HEADING 'U*'			; ( u1 u2 -- d )
		dw $ + 2
	pop ax
	pop dx
	mul dx
	push ax
	push dx
	NEXT

HEADING 'U/MOD'			; ( d u -- r q )
		dw $ + 2
	pop di
	pop dx
	pop ax
	div di
	push dx
	push ax
	NEXT


; Long Structures - more efficient code, but extra byte
; These use a stored as destination address rather than a byte or word offset
; Headerless: only called through compiler definitions

do_branch:	dw $ + 2
  branch:
	lodsw		; ax = goto address
	mov si,ax	; set thread pointer = goto
	NEXT

; jump on opposite condition, ie 'NE IF' compiles JE equivalent
q_branch:	dw $ + 2	; ( f -- )
	pop ax
	or ax,ax
	je branch	; ignore conditional execution if flag false
  no_branch:
	inc si		; bypass jump address
	inc si
	NEXT		;   and then execute conditional words

do_loop:	dw $ + 2
	mov cx,1	; normal increment
  lp1:
	add cx,[bp+0]	; update counter
	mov [bp+0],cx	; save for next round
	cmp cx,[bp+2]	; (signed, Forth-79) compare counter to limit
	jl branch	; not at end of loop count, go again
  lp2:
	add bp,4	; at end, drop cntr & limit from R stack
	inc si		; skip jump/loop address & continue
	inc si
	NEXT

plus_loop:	dw $ + 2	; ( n -- )
	pop cx
	JMP lp1

slant_loop:	dw $ + 2	; ( n -- )
	pop dx
	add [bp+0],dx	; (Forth-83) crossed boundary from below?
	mov ax,[bp+0]
	sub ax,[bp+2]
	xor ax,dx
	jge lp2		; end of loop, exit

	jmp branch	; no, branch back to loop beginning

; Special version of SWITCH that compiles address instead of byte to test
; Designed to be used with a table similar to 'termcap')
; C@ byte to compare with character on stack
c_switch:	dw $ + 2	; ( xx c.input -- xx | xx c.input )
	pop dx
	RPUSH si
	ADD si,4
	sub cx,cx
  c_s1:			; BEGIN
	lodsw			; inc si, get address of byte
	mov di,ax
	MOV cl,[di]		; byte to match
	lodsw			; inc si, get possible link
	CMP dl,cl
	je c_s3			; input match this entry ?
	CMP ax,0	; WHILE not last link = 0
	jz c_s2
	mov si,ax
	JMP c_s1	; REPEAT, try next entry
  c_s2:
	push dx 		; no matches
  c_s3:
  	NEXT

; Execution code for a normal SWITCH construct - similar to C 'switch'
do_switch:	dw $ + 2	; ( xx n.input -- xx | xx n.input )
	pop dx			; switch input
	RPUSH si
	ADD si,4		; skip forth branch
  sw1:
	lodsw
	MOV cx,ax		; number to match
	lodsw			; increment I; get possible link
	CMP dx,cx
	je sw3			; input match this entry
	CMP ax,0
	je sw2
	mov si,ax
	JMP sw1			; try next entry
  sw2:
	push dx			; no matches
  sw3:
  	NEXT


; Runtime for literals (8, 16, double 8 and 32-bit)

bite:   	dw $ + 2
	lodsb                   ; get data byte
	cbw                     ; sign extend to word
	push ax
	NEXT

cell:		dw $ + 2	; code def with no header/ only cfa.
	lodsw                   ; used by literal
	push ax                 ; push data word on param stack
	NEXT

; Normally used with literal loop constants
dclit:		dw $ + 2	; ( -- sxc1 sxc2 )
	lodsb           ; get first byte
	cbw
	push ax
	lodsb           ; get second byte
	cbw
	push ax
	NEXT

dblwd:		dw $ + 2	; ( -- d )
	lodsw
	mov dx,ax	; low address => high word when inline
	lodsw
	push ax
	push dx		; lower stack address (TOS) => high word
	NEXT


; Program execution

HEADING 'EXECUTE'
  EXECUTE:      dw $ + 2
	pop di                  ; ( cfa -- )
  exec1:
	or di,di
	jz e001			; no address was given, cannot be 0
	jmp near [di]
  e001:
	NEXT

HEADING '@EXECUTE'
  @EXECUTE:     dw $ + 2
	pop di                  ; ( a -- >> runtime )
	mov di,[di]
	JMP exec1

HEADING 'EXIT'
  EXIT:         dw $ + 2
  exit1:                        ; R = BP, return stack pointer >>
	RPOP si			;   go back to previous thread
	NEXT

; Select leave or 2-leave based on depth of actual nesting
; Selecting inappropriate level will 'crash' system
HEADING 'LEAVE-EXIT'
  leave_exit:   dw $ + 2
	add bp,4		; 2-RDROP - count & limit
	jmp exit1

HEADING '2LEAVE-EXIT'
		dw $ + 2
	add bp,8		; 4-RDROP - both counts & limits
	jmp exit1

HEADING 'LEAVE'
  leave_lp:	dw $ + 2
	mov ax,[bp+0]		; next test will => done, count = limit
	mov [bp+2],ax
	NEXT

; Equivalent of 'NOT IF EXIT THEN'
HEADING 'STAY'			; ( f -- >> exit if false )
  STAY:         dw $ + 2
	pop ax
	or ax,ax
	jz exit1
	NEXT


; Dictionary defining words -- compile and runtime

HEADING ':'
		dw colon		; ( -- )
	dw      cfa_create, r_bracket
	dw      sem_cod			; sets CFA of daughter to 'colon'
  colon:
	inc di			; cfa -> pfa
	inc di
	RPUSH si		; rpush si = execute ptr => current pfa
	mov si,di		; exec ptr = new pfa
	NEXT

; Note - word copies input to here + 2, in case of a new definition
HEADING 'CREATE'
  cfa_create:	dw colon		; ( -- )
	dw      blnk, cfa_word, cfa_dup		; word adr = string adr = na
	dw      c_fetch, cfa_dup		; ( na count count )
	dw      zero_eq, abortq
	db      ct001 - $ - 1
	db      'No name'
  ct001:
	dw      bite				; ( na count )
	db      31
	dw      greater, abortq
	db      ct002 - $ - 1
	db      'Name too long!'
  ct002:
	dw      CURRENT, c_fetch, HASH, FIND_WD	; ( na v -- na lfa,0 )
	dw      q_DUP, q_branch			; IF name exists in current vocab,
	dw      ct005				;  print redefinition 'warning'
	dw      CR, OVER, COUNT, cfa_type
	dw      dotq
	db      ct003 - $ - 1
	db      ' Redefinition of: '
  ct003:
	dw      cfa_dup, id_dot, dotq
	db      ct004 - $ - 1
	db      'at '
  ct004:
	dw      u_dot
  ct005:					; THEN
	dw      CURRENT, c_fetch, HASH		; ( na link )
	dw      HEADS, plus, HERE		; ( nfa hdx lfa=here )
	dw      cfa_dup, LAST, w_store		; ( nfa hdx lfa )
	dw      OVER, fetch, comma		; set link field
	dw      SWAP, w_store			; update heads
	dw      c_fetch				; ( count )
	dw	one_plus, ALLOT			; allot name and count/flags
	dw	SMUDGE
	dw      zero, comma			; code field = 0, ;code will update
	dw      sem_cod
create:				; ( -- pfa )
	inc di                  ; cfa -> pfa
	inc di
	push di                 ; standard def => leave pfa on stack
	NEXT

; Runtime for DOES>
does:
	RPUSH si		; rpush current (word uses parent) execute ptr
	pop si			; get new (parent) execute ptr
	inc di			; daughter cfa -> pfa
	inc di
	push di			; leave daughter pfa on stack
	NEXT

HEADING 'CONSTANT'
  cfa_constant:	dw colon		; ( n -- >> compile time )
		dw      cfa_create, comma
		dw	UNSMUDGE, sem_cod
  constant:				; ( -- n >> run time )
	push word [di+2]
	NEXT

; Note: Forth is 'oposite' of Intel -- high word is top of stack (lower address)
HEADING '2CONSTANT'
		dw colon		; ( d -- )
	dw      SWAP, cfa_constant
	dw	comma, sem_cod
  two_con:				; ( -- d )
	push word [di+2]
	push word [di+4]
	NEXT


; System-wide constants

HEADING '0.'			; ( -- 0 0 >> code def is an alternative )
  zero_dot:	dw two_con
	dw      0, 0

HEADING '1.'
	dw      two_con
	dw      1, 0

HEADING '2'
  two:		dw constant, 2

B_HDR:		dw constant	; bytes in header, ie, hash lists * 2
	dw      32		; see HEADS and FENCE

L_WIDTH:	dw      constant
		dw      80

HEADING 'S0'
  SP0:		dw constant, stack0


; String, text operators

HEADING '-TEXT'			; ( a1 n a2 -- f,t=different )
	dw      $ + 2
	pop di
	pop cx
	pop ax
	xchg ax,si
	REP CMPSB
	je txt1
	mov cx,1
	jnc txt1
	neg cx
  txt1:
	push cx
	mov si,ax
	NEXT

HEADING '-TRAILING'		; ( a n -- a n' )
  m_TRAILING:   dw      $ + 2
	pop cx
	pop di
	push di
	jcxz trl1
	mov al,' '
	add di,cx
	dec di
	STD
	REP scasb
	cld
	je trl1
	inc cx
  trl1:
	push cx
	NEXT

; Prevents corruption when destination is above start, but inside source
HEADING '<CMOVE'		; ( s d n -- )
  backwards_cmove: dw $ + 2
	pop cx
	pop di
	pop ax
	jcxz bmv1
	xchg ax,si
	add di,cx
	dec di
	add si,cx
	dec si
	STD
	REP movsb
	cld
	mov si,ax
  bmv1:
	NEXT

HEADING 'CMOVE'			; ( s d n -- )
  front_cmove:	dw $ + 2
	pop cx          ; count
	pop di
	pop ax
	xchg ax,si
	rep movsb
	mov si,ax
	NEXT

HEADING 'COUNT'			; ( a -- a+1 n )
  COUNT:	dw $ + 2
	pop di
	sub ax,ax
	mov al,[di]
	inc di
	push di
	push ax
	NEXT

; Memory fills

HEADING 'FILL'			; ( a n c -- )
		dw $ + 2
	pop ax
  mem_fill:
	pop cx
	pop di
	REP stosb
	NEXT

HEADING 'BLANK'			; ( a n -- )
  BLANK:	dw $ + 2
	mov al,' '
	JMP mem_fill

HEADING 'ERASE'			; ( a n -- )
  ERASE:        dw $ + 2
	sub ax,ax
	JMP mem_fill


; Intersegment (long) data moves

HEADING 'L!'			; ( n seg off -- )
		dw $ + 2
	pop di
	pop ds
	pop ax
	mov [di],ax
	mov dx,cs
	mov ds,dx
	NEXT

HEADING 'L@'			; ( seg off -- n )
		dw $ + 2
	pop di
	pop ds
	mov ax,[di]
	mov dx,cs
	mov ds,dx
	push ax
	NEXT

HEADING 'LC!'			; ( c seg off -- )
		dw $ + 2
	pop di
	pop ds
	pop ax
	mov [di],al
	mov dx,cs
	mov ds,dx
	NEXT

HEADING 'LC@'			; ( seg off -- c >> zero extended byte )
		dw $ + 2
	pop di
	pop ds
	sub ax,ax
	mov al,[di]
	mov dx,cs
	mov ds,dx
	push ax
	NEXT

HEADING 'FORTHSEG'		; ( -- seg )
  FORTHSEG:	dw $ + 2	; not a constant in a PC-DOS system
	push cs                 ; changes each time the program is run
	NEXT

%if 0
; Segment definitions for future experimentation
HEADING 'STACKSEG'		; ( -- seg )
		dw $ + 2
	mov ax,cs		; 64K (4K segs) above FORTHSEG
	add ax,4096
	push ax
	NEXT

HEADING 'FIRSTSEG'		; ( -- seg )
		dw $ + 2
	mov ax,cs	; 128K (8K segs) above FORTHSEG, 64k above stack/buffer seg
	add ax,8192
	push ax
	NEXT
%else
HEADING 'STACKSEG'		; ( -- seg )
		dw FORTHSEG + 2	; currently dictionary and stacks are in same segment

; Code definition to be correct for any .com load
HEADING 'FIRSTSEG'		; ( -- seg )
		dw $ + 2
	mov ax,cs		; 64K (4K segs) above FORTHSEG
	add ax,4096
	push ax
	NEXT
%endif

HEADING 'SEGMOVE'		; ( fs fa ts ta #byte -- )
		dw $ + 2
	pop cx
	pop di
	pop es
	pop ax
	pop ds
	xchg ax,si
	shr cx,1
	jcxz segmv1
	REP MOVSw
  segmv1:
	jnc segmv2
	movsb
  segmv2:
	mov dx,cs
	mov ds,dx
	mov es,dx
	mov si,ax
	NEXT


; Miscellaneous definitions

HEADING '><'			; ( n -- n' >> bytes interchanged )
		dw      $ + 2
	pop ax
	xchg al,ah
	push ax
	NEXT

HEADING '+@'			; ( a1 a2 -- n )
  plus_fetch:   dw      $ + 2
	pop ax
	pop di
	add di,ax
	push word [di]
	NEXT

HEADING '@+'			; ( n1 a -- n )
  fetch_plus:   dw      $ + 2
	pop di
	pop ax
	add ax,[di]
	push ax
	NEXT

HEADING '@-'			; ( n1 a -- n )
  fetch_minus:  dw      $ + 2
	pop di
	pop ax
	sub ax,[di]
	push ax
	NEXT

HEADING 'CFA'				; ( pfa -- cfa )
  CFA:		dw two_minus + 2	; similar to an alias for 2-

HEADING '>BODY'				; ( cfa -- pfa )
  to_body:	dw two_plus + 2		; similar to an alias for 2+

HEADING 'L>CFA'			; ( lfa -- cfa )
  l_to_cfa:     dw $ + 2
	pop di			; LFA
	inc di
	inc di			; NFA
	mov al,[di]
	AND ax,1Fh		; count only, no flags such as immediate
	add di,ax
	inc di
	push di
	NEXT

HEADING 'L>NFA'				; ( lfa -- nfa )
  l_to_nfa:	dw two_plus + 2		; similar to an alias for 2+

HEADING 'L>PFA'			; ( lfa -- pfa )
	dw	colon
	dw	l_to_cfa, to_body, EXIT

; 15-bit Square Root of a 31-bit integer (must be positive)
HEADING 'SQRT'			; ( d -- n )
		dw $ + 2
	pop dx
	pop ax
	push si
	sub di,di
	mov si,di
	mov cx,16
  lr1:
	shl ax,1
	rcl dx,1
	rcl si,1
	shl ax,1
	rcl dx,1
	rcl si,1
	shl di,1
	shl di,1
	inc di
	CMP si,di
	jc lr2
	sub si,di
	inc di
  lr2:
	shr di,1
	LOOP lr1
	pop si
	push di
	NEXT


; Start Colon Definitions -- non-defining words
; Best for FORTH compiler to create defining words first -- minimizes forward references
; Most of these are used in the base dictionary

HEADING 'D<'			; ( d1 d2 -- f )
  d_less:	dw colon		; CFA
	dw      d_minus			; PFA
	dw	zero_less, SWAP, DROP
	dw      EXIT			; semicolon

HEADING 'D='			; ( d1 d2 -- f )
		dw colon
	dw      d_minus
	dw      d_zero_eq
	dw      EXIT

HEADING 'DABS'			; ( d -- |d| )
  DABS:		dw colon
	dw      cfa_dup, zero_less, q_branch	; IF <0 THEN NEGATE
	dw      dab1
	dw      DNEGATE
  dab1:
	dw      EXIT

HEADING 'DMAX'			; ( d1 d2 -- d )
		dw colon
	dw      two_over, two_over, d_less
	dw      q_branch				; IF 1st < THEN SWAP
	dw      dmax1
	dw      two_swap
  dmax1:
	dw      two_drop
	dw      EXIT

HEADING 'DMIN'			; ( d1 d2 -- d )
  DMIN:		dw colon

	dw      two_over, two_over, d_less
	dw	zero_eq, q_branch			; IF 1st >= THEN SWAP
	dw      dmin1
	dw      two_swap
  dmin1:
	dw      two_drop
	dw      EXIT

HEADING '-LEADING'		; ( addr cnt -- addr' cnt' )
  m_LEADING:	dw colon
	dw      cfa_dup, zero, two_to_r
  mld1:
	dw      OVER, c_fetch, blnk
	dw      cfa_eq, q_branch		; IF leading = space
	dw      mld2
	dw      SWAP, one_plus
	dw      SWAP, one_minus, do_branch
	dw      mld3
  mld2:
	dw      leave_lp
  mld3:
	dw      do_loop
	dw      mld1
	dw      EXIT

HEADING '0>'			; ( n -- f )
 zero_greater:	dw colon
	dw	zero, greater
	dw	EXIT

HEADING '3DUP'			; ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
  three_dup:	dw colon
	dw	cfa_dup, two_over, ROT
	dw	EXIT

; Expects parameter stack in FORTHSEG
HEADING 'ROLL'			; ( ... c -- ... )
		dw colon
	dw      two_times, to_r, sp_fetch
	dw      eye, two_minus, plus_fetch
	dw      sp_fetch, cfa_dup, two_plus
	dw      r_from, backwards_cmove, DROP
	dw      EXIT

HEADING 'T*'			; ( d n -- t )
  tr_times:     dw $ + 2
	mov [bp-2],si		; save thread pointer above 'R' (almost RPUSH)
	pop bx                  ; n
	pop si                  ; d hi
	pop di                  ; d lo
	mov ax,di
	mul bx          ; n * lo
	push ax                 ; bottom (lo) of tripple result
	mov cx,dx
	mov ax,si
	mul bx          ; n * hi
	add cx,ax               ; middle terms
	adc dx,0
	or si,si
	jge tt1         ; correct unsigned mul by n
	sub dx,bx
  tt1:
	or bx,bx
	jge tt2         ; correct unsigned mul by d
	sub cx,di
	sbb dx,si
  tt2:
	push cx			; result mid
	push dx			; result hi
	mov si,[bp-2]
	NEXT

HEADING 'T/'			; ( t n -- d )
  tr_div:        dw $ + 2
	pop di                  ; n
	pop dx                  ; hi
	pop ax                  ; med
	pop cx                  ; lo
	push si
	sub si,si
	or di,di
	jge td11
	neg di                  ; |n|
	inc si
  td11:
	or dx,dx
	jge td12
	dec si                 ; poor man's negate
	neg cx                 ; |t|
	adc ax,0
	adc dx,0
	neg ax
	adc dx,0
	neg dx
  td12:
	div di
	xchg ax,cx
	div di
	or si,si               ; sign of results
	jz td13                ; 0 or 2 negatives => positive
	neg ax                 ; dnegate
	adc cx,0
	neg cx
  td13:
	pop si
	push ax
	push cx
	NEXT

HEADING 'M*/'			; ( d1 n1 n2 -- d )
		dw colon
	dw      to_r, tr_times, r_from, tr_div
	dw      EXIT

; Core definitions are complete
; Single User / System variables => No User variables -- all treated as 'normal'

HEADING 'SPAN'			; actual # chrs rcvd.
  SPAN:		dw create	; Normal variable
  span1:	dw	0

; Text input starts at bottom of parameter stack
; Disk input can start anywhere (MikeOS) or Buf0 (DOS)
HEADING 'TIB'			; ( -- tib )
  TIB:		dw create
  tib1:		dw stack0

; #TIB => total number characters in the buffer (DOS file I/O adjusts 'on the fly')
HEADING '#TIB'
  num_tib:	dw create
  n_tib1:	dw      0

; Current offset into TIB
HEADING '>IN'
  tin:          dw create
  tin1:         dw      0

; Flags used primarily for X-ON/X-OFF serial hanshaking
HEADING 'T_FLG'			; serial transmit flags
		dw create	; cvariable
  tflg1:	db	0

HEADING 'R_FLG'			; serial receive flags
  rcv_flg:	dw create	; cvariable
  rflg1:	db	0

; Start with CONTEXT = CURRENT = FORTH
HEADING 'CONTEXT'		; ( -- a >> 2variable )
  CONTEXT:      dw create
		dw      VOC, 0

HEADING 'CURRENT'		; ( -- a >> 2variable )
  CURRENT:      dw create
		dw      VOC, 0

; Kept variable storage together to make PROTECT and EMPTY easier
; 16 hash chains --> 32 bytes
HEADING 'HEADS'
  HEADS:	dw create			; ARRAY => Links to dictionary hash chains
  hds:          times 16 dw 0
  h1:		dw	very_end		; temporary 'HERE' after system start
  last1:	dw      NORM_LAST		; LFA of last word defined (with header)

HEADING 'FENCE'
  FENCE:        dw create			; GOLDEN (protected dictionary)
  links: 	times 16 dw 0
  goldh:	dw      GOLDEN_HERE		; PROTECTed dictionary end

; Now setup access to array elements as a variable (HERE = H @, or equivalent)
HEADING 'H'
  H:		dw constant
		dw h1      

HEADING 'LAST'
  LAST:		dw constant
		dw last1

; Vectored ABORT - behavior may be changed by user
HEADING "'ABORT"
		dw create
  abrt_ptr:     dw      QUT1

HEADING 'BASE'
  BASE:         dw create
  base1:        dw      10		; decimal

T_BASE:         dw create		; headerless variable
  t_ba:         dw      10		; temporary base for next number input

; Stream input or compiling
HEADING 'STATE'
  STATE:        dw create
  state1:       dw      0

; Current address - used by number conversion (and by assembler)
HEADING 'HLD'
  HLD:		dw create
  hld1:		dw      0

HEADING 'ROWS'
		dw create
  max_rows:     dw      0

; Include stored video info and some interrupt vector(s) for convenience
HEADING 'LINES'
		dw create
  max_col:      dw      0
  _mode:        dw      0	; video setup information
  _page:        dw      0
  d_off:        dw      0       ; save divide 0 vector here
  d_seg:        dw      0
%if MikeOS
  c_off		dw	0	; save ^C vector for restore
  c_seg		dw	0
  sp_save	dw	0	; save MikeOS SS:SP
  ss_save	dw	0
%endif

HEADING 'ABORT'
  ABORT:        dw $ + 2	; ( x ... x -- )
  abrt:
	cli
	MOV sp,stack0		; clear parameter stack
	sti
	mov [tib1],sp		; normal TIB
	mov ax,[base1]		; reset temporary base to current
	mov [t_ba],ax
	sub ax,ax		; mark disk file as ended
	mov [qend1],ax
	push ax			; for parameter stack underflow
	MOV si,[abrt_ptr]	; goto 'quit' (abort vector)
	NEXT

; DOS automatically restores the original stack pointer and ^C vector
; DOS will also restore the critical error vector (when necessary)
HEADING 'SYSTEM'
  SYSTEM:       dw $ + 2
	push es
	mov cx,[d_seg]		; restore the div 0 vector
	mov dx,[d_off]
	xor ax,ax		; interrupt segment and address of vector 0 = 0:0
	mov es,ax
	mov di,ax
	mov [es:di],dx
	mov [es:di+2],cx
%if MikeOS
	mov di,0x8c		; interrupt segment = 0 and offset = 4 * 23h
	mov cx,[c_seg]		; restore the [ctrl]C vector
	mov dx,[c_off]
	mov [es:di],dx
	mov [es:di+2],cx
	pop es

	mov ax,[ss_save]
	cli
	mov sp,[sp_save]
	mov ss,ax
	sti
	ret
%else
	pop es
	mov ax,4c00h		; DOS terminate program (will restore stack and
	int 21h			;   ctrl-c vector)
%endif


HEADING '!CURSOR'		; ( row col -- )
		dw $ + 2
	pop dx
	pop ax
	mov ah,02		; BIOS set cursor
	mov dh,al
	mov bh,[_page]
	int 10h
	NEXT

HEADING '@CURSOR'		; ( -- row col )
  get_cursor:   dw $ + 2
	mov ah,03		; BIOS get cursor
	mov bh,[_page]
	int 10h
	sub ax,ax
	mov al,dh
	push ax
	mov al,dl
	push ax
	NEXT

HEADING 'CLS'			; ( -- )
  CLS:		dw $ + 2
	mov ax,0600h            ; BIOS clear current page
	sub cx,cx		; start 0,0
	mov dh,[max_rows]	; end (normally 24,79)
	dec dh
	mov dl,[max_col]
	dec dl
	mov bh,07		; white
	int 10h
	mov ah,02		; BIOS set cursor
	sub dx,dx		; 0,0 - upper, left
	mov bh,[_page]
	int 10h
	NEXT


; Polled 'type'
; Bits 0-3 of T_FLG control transmission; Bit 0 => XON

HEADING 'TYPE'			; ( a n -- )
  cfa_type:	dw $ + 2
	pop cx			; character count
	pop di			; ds:di = data pointer
	push bp			; some BIOS destroy BX, DX and/or BP
	or cx,cx		; normally 1 to 255 characters, always < 1025
	jle short ty2		; bad data or nothing to print
  ty1:
	test byte [tflg1],0Fh	; output allowed? XON-XOFF
	jne ty1
	mov al,[di]		; get character
	inc di
	mov ah,0x0E		; print to screen, TTY mode
	mov bh,[_page]		; ignored on newer BIOSs
	mov bl,7		; foreground, usually ignored
	int 10h
	loop ty1		; do for input count
  ty2:
	pop bp
	NEXT

HEADING 'EMIT'			; ( c -- )
  EMIT:		dw $ + 2
	pop ax
	push bp			; some BIOS destroy BX, DX and/or BP
	mov ah,0x0E
	mov bh,[_page]		; ignored on newer BIOSs
	mov bl,7		; foreground, usually ignored
	int 10h
	pop bp
	NEXT

; TERMINAL -- NON-VECTORED
; LF echoed as space, CR echoed as space and terminates input
; Special keys set bit 7 or the receive flag
; Note: buffer must be able to contain one more than expected characters.
HEADING 'EXPECT'		; ( a n -- )
  EXPECT:       dw $ + 2
	pop cx                  ; max count
	pop di                  ; buffer address
	push bp			; some BIOS destroy BX, DX and/or BP
	sub ax,ax
	MOV [span1],ax		; no characters, so far
	or cx,cx                ; > 0, normally <= 80
	jg exp_loop
	jmp exp_end
  exp_loop:
	and byte [rflg1],7Fh	; clear special, b7
	xor ax,ax		; BIOS input, no echo
	int 16h
	cmp al,0		; extended/special ?
	je exp1			; yes
	cmp al,0xE0
	jne exp2
  exp1:
	or byte [rflg1],80h	; set special
	mov al,1		; get extended scan code in al
	xchg al,ah
	jmp short exp_store	; special cannot be a control
  exp2:				; normal input, limited control processing
	TEST byte [rflg1],1	; (b0=raw) skip test specials ?
	jnz exp_store

	CMP al,bs		; <back space> ?
	je exp5
	CMP al,del              ; <delete> ?
	jne exp7
  exp5:
	TEST word [span1],7FFFh	; any chr in buffer ?
	jnz exp6
	mov dl,bell		; echo (warning) bell
	jmp short exp_echo
  exp6:
	DEC word [span1]
	INC cx
	dec di
	test byte [rflg1],10h	; b4, echo allowed ?
	jnz exp10
	mov bh,[_page]		; ignored on newer BIOSs
	mov bl,7		; foreground, usually ignored
	mov ax,0x0E08		; BS
	int 10h
	mov ax,0x0E20		; space
	int 10h
	mov ax,0x0E08		; BS
	int 10h
	jmp short exp10
  exp7:
	CMP al,cr		; <cr> ?
	jne exp9
	sub cx,cx               ; no more needed
	mov dl,' '		; echo space, don't store
	jmp short exp_echo
  exp9:
	cmp al,lf		; <lf> ?
	jne exp_store
	mov al,' '		; echo & store space
  exp_store:
	mov dl,al               ; echo input
	stosb
	INC word [span1]
	DEC cx
  exp_echo:
	test byte [rflg1],10h	; b4, echo allowed ?
	jnz exp10
	mov al,dl
	mov bh,[_page]		; ignored on newer BIOSs
	mov bl,7		; foreground, usually ignored
	mov ah,0x0E		; send to monitor
	int 10h
  exp10:
	jcxz exp_end
	jmp exp_loop
  exp_end:
	sub ax,ax		; end of input marker
	stosb
	pop bp
	NEXT

HEADING 'KEY'			; ( -- c >> high byte = end marker = 0 )
  KEY:  dw      colon
	dw      rcv_flg, c_fetch, cfa_dup, one, cfa_or, rcv_flg, c_store  ; set special
	dw      zero, sp_fetch, one, EXPECT                     ; ( rflg c )
	dw      rcv_flg, c_fetch, bite
	db      80h
	dw      cfa_and, ROT, cfa_or	; extended receive &
	dw      rcv_flg, c_store	; echo flag maintained
	dw      EXIT

; 'DOES> COUNT TYPE ;'
msg:
	db      232			; call pushes PFA (return) on parameter stack
	dw      does - $ - 2
	dw      COUNT, cfa_type
	dw      EXIT

; Generic CRT Terminal

HEADING 'BELL'
  BELL:		dw      msg
	db      1, bell

HEADING 'CR'
  CR:		dw      msg
	db      2, cr, lf

HEADING 'OK'
  OK:		dw      msg
	db      2, 'ok'

HEADING 'SPACE'
  SPACE:	dw      msg
	db      1, ' '

HEADING 'SPACES'		; ( n -- >> n=0 to 32767 )
  SPACES:       dw colon
	dw      cfa_dup, zero_greater, q_branch	; IF number positive
	dw      sp2
	dw      cfa_dup, zero, two_to_r			; DO
  sp1:
	dw      SPACE, do_loop
	dw      sp1					; LOOP
  sp2:						; THEN
	dw      DROP
	dw      EXIT

HEADING 'HERE'			; ( -- h )
  HERE:         dw $ + 2
	PUSH word [h1]
	NEXT

h_p_2:          dw colon	; ( -- h+2 )
	dw      HERE, two_plus
	dw      EXIT

HEADING 'PAD'			; ( -- a >> a=here+34, assumes full header )
  PAD:          dw $ + 2
	mov ax,[h1]
	ADD ax,34		; LFA + max NFA size
	push ax
	NEXT

; Pictured Number output

HEADING 'HOLD'			; ( C -- )
  HOLD:         dw $ + 2
	DEC word [hld1]
	MOV di,[hld1]
	pop ax
	stosb
	NEXT

dgt1:		dw $ + 2	; ( d -- d' c )
	pop ax
	pop cx
	sub dx,dx
	mov di,[base1]		; no overflow should be possible
	DIV di                  ; just in case base cleared
	xchg ax,cx
	DIV di
	push ax
	push cx
	CMP dl,10               ; dx = Rmd: 0 to Base
	jc dgt2                 ; U<
	add dl,7                ; 'A' - '9'
  dgt2:
	add dl,'0'		; to ASCII
	push dx
	NEXT

HEADING '<#'			; ( d -- d )
  st_num:       dw colon
	dw      PAD, HLD, w_store
	dw      EXIT

HEADING '#'			; ( d -- d' )
  add_num:      dw colon
	dw      dgt1, HOLD
	dw      EXIT

HEADING '#>'			; ( d -- a n )
  nd_num:       dw colon
	dw      two_drop, HLD, fetch
	dw      PAD, OVER, minus
	dw      EXIT

HEADING 'SIGN'			; ( n d -- d )
  SIGN:		dw colon
	dw      ROT, zero_less, q_branch		; IF negative
	dw      si1
	dw      bite
	db      '-'
	dw      HOLD
  si1:
	dw      EXIT

HEADING '#S'			; ( d -- 0 0 )
  nums:		dw colon
  nums1:
	dw      add_num, two_dup, d_zero_eq
	dw      q_branch				; UNTIL nothing left
	dw      nums1
	dw      EXIT

HEADING '(D.)'			; ( d -- a n )
  paren_d:      dw colon
	dw      SWAP, OVER, DABS
	dw      st_num, nums
	dw      SIGN, nd_num
	dw      EXIT

HEADING 'D.R'			; ( d n -- )
  d_dot_r:      dw colon
	dw      to_r, paren_d, r_from, OVER, minus, SPACES, cfa_type
	dw      EXIT

HEADING 'U.R'			; ( u n -- )
  u_dot_r:      dw colon
	dw      zero, SWAP, d_dot_r
	dw      EXIT

HEADING '.R'			; ( n n -- )
		dw colon
	dw      to_r, s_to_d, r_from, d_dot_r
	dw      EXIT

HEADING 'D.'			; ( d -- )
  d_dot:        dw colon
	dw      paren_d, cfa_type, SPACE
	dw      EXIT

HEADING 'U.'			; ( u -- )
  u_dot:        dw colon
	dw      zero, d_dot
	dw      EXIT

HEADING '.'			; ( n -- )
  dot:		dw colon
	dw      s_to_d, d_dot
	dw      EXIT

; 32-bit Number input

q_DIGIT:	dw $ + 2	; ( d a -- d a' n f )
	sub dx,dx
	pop di          ; get addr
	inc di          ; next chr
	push di         ; save
	mov al,[di]     ; get this chr
	cmp al,58       ; chr U< '9'+ 1
	jc dgt4
	cmp al,65
	jc bad_dgt
	SUB al,7        ; 'A' - '9'
  dgt4:
	SUB al,'0'
	jc bad_dgt
	CMP al,[t_ba]
	jnc bad_dgt
	cbw
	push ax
	INC dx
  bad_dgt:
	push dx
	NEXT

D_SUM:		dw $ + 2	;  ( d a n -- d' a )
	pop di
	pop dx
	pop ax
	pop cx
	push dx
	MUL word [t_ba]
	xchg ax,cx
	MUL word [t_ba]
	ADD ax,di
	ADC cx,dx
	pop dx
	push ax
	push cx
	push dx
	NEXT

HEADING 'CONVERT'		; ( d a -- d' a' )
  CONVERT:      dw colon
  dgt8:					; BEGIN
	dw      q_DIGIT, q_branch	; WHILE
	dw      dgt9
	dw      D_SUM, HLD, one_plus_store
	dw      do_branch
	dw      dgt8			; REPEAT
  dgt9:
	dw      EXIT

HEADING 'NUMBER'		; ( a -- n, d )
  NUMBER:       dw colon
	dw      cell, -129, HLD, w_store		; max length * -1
	dw      cfa_dup, one_plus, c_fetch, bite	; 1st chr '-' ?
	db      '-'
	dw      cfa_eq, cfa_dup, to_r, q_branch	; IF, save sign & pass up
	dw      num1
	dw	one_plus
  num1:
	dw      zero, cfa_dup, ROT			; ( 0. a' )
  num2:
	dw      CONVERT, cfa_dup, c_fetch, cfa_dup    ; ( d end chr[end] )
	dw      dclit
	db      43, 48                          ; chr[end] '+' to '/'
	dw      WITHIN, SWAP, bite
	db      58                              ;       or ':' ?
	dw      cfa_eq, cfa_or, q_branch
	dw      num3
	dw      HLD, false_store, do_branch	; yes = double
	dw      num2
  num3:
	dw      c_fetch, abortq			; word ends zero
	db      1,'?'
	dw      r_from, q_branch		; IF negative, NEGATE
	dw      num4
	dw      DNEGATE
  num4:
	dw      HLD, fetch, zero_less, q_branch
	dw      num5
	dw      DROP				; single = drop high cell
  num5:
	dw      BASE, T_BASE, XFER
	dw      EXIT

; String output

; ( f -- a n >> return to caller for TYPE if true, leave caller if false )
; in either case, bump thread pointer past text
q_COUNT:	dw $ + 2
	MOV di,[bp+0]		; get pointer to forth thread ('I')
	xor ax,ax
	mov al,[di]		; ('C@') AX = string count (0 to 255)
	inc ax			; ('1+')
	ADD [bp+0],ax		; bump pointer past string ('I +!')
	pop dx
	test dx,0xFFFF
	jnz cnt_1
	JMP exit1		; leave parent
  cnt_1:
	dec ax          ; ('COUNT') restore character count
	inc di          ; address of beginning of string characters
	push di
	push ax
	NEXT			; return to parent

; ( f --     >> return to caller if false )
abortq:		dw colon
	dw      q_COUNT, h_p_2, COUNT, cfa_type
	dw      SPACE, cfa_type, CR
	dw      ABORT

; ?COUNT to 'jump' over literal string
dotq:		dw colon
	dw      one, q_COUNT, cfa_type
	dw      EXIT


; Disk access variables
; These routines are setup to access _only one_ file at a time!

; These do NOT support DOS functions: Delete or Rename

HEADING '?END'
  q_END:	dw create
  qend1:        dw      0		; end of file flag (for loading)
  hndl1:        dw      0		; DOS file handle, if one is open

; This construct turns a memory location into a "variable" that works in other definitions
HEADING 'HNDL'
  HNDL:		dw constant
		dw hndl1		; file handle

HEADING 'FDSTAT'
  FDSTAT:       dw create
  fdst1:        dw      0		; error flag, may be extended later

HEADING 'FNAME'
  FNAME:        dw create
  fname1:       times 31 db 0		; file name (DOS: 12 characters, max)
		db      0		; final terminator

HEADING 'PATH'
  PATH:         dw create
  path1:        db      'a:\'		; drive
%if MikeOS = 0
  path2:        times 126 db 0		; short path
%endif
		db      0

HEADING 'FDWORK'
  FDWORK:       dw create
  fdwk1:	dw      0       ; error, handle, or count low word
%if MikeOS = 0
  fdwk2:        dw      0       ; high word of count when applicable (.com)

HEADING 'BUF0'			; only 1 disk, 2-part, buffer for now
  BUF0:  dw      create
  buf0a: times 1025 db spc	; currently in FORTH seg
                                ;  extra in case file is exact multiple of 512

HEADING 'BUF1'			; break buffer into 2 pieces for DOS
	dw      constant
	dw      buf0a + 512
%endif

; DOS read cnt (multiple of sector size until end) bytes of open file to address
; MikeOS will read whole file; make sure it will fit!
HEADING 'FREAD'
FREAD:		dw $ + 2	; ( adr cnt -- f >> t=error )
%if MikeOS
        pop cx                  ; discard count
        pop cx                  ; load address
        pusha
        mov ax,fname1           ; get name string
        call os_load_file
        mov [fdwk1],bx          ; # bytes read (0 if error)
        popa                    ; 8 GP registers
        mov ax,0
        jnc frd01
        inc ax
  frd01:
        mov [fdst1],ax          ; error flag in FDSTAT
	push ax
	NEXT
%else
	mov ah,3Fh
  fwrt1:
	pop cx			; read or write
	pop dx
	mov bx,[hndl1]
	int 21h
  diskend:
	mov [fdwk1],ax    	; old error code, handle, or # bytes
	mov [fdwk2],dx    	; high count (to be thorough, but not needed)
	mov ax,0
	jnc fr001
	inc ax
  fr001:
	mov [fdst1],ax		; error flag in FDSTAT (future = more specific)
	push ax			; and returned on stack
	NEXT

; Use DOS to "open" a file (handle)
; HEADING 'FOPEN'
FOPEN:		dw $ + 2	; ( mode -- f >> t=error )
	pop ax			;  mode: 0=read, 1=write, 2=both=default on create
	mov ah,3Dh
  fcrt1:
	mov dx,fname1
	int 21h
	jmp diskend

; HEADING 'FCREATE'
FCREATE:	dw $ + 2	; ( att -- f >> t=error )
	pop cx			; att = 0 = normal, 1 = read only, 2 = hidden
	mov ah,3Ch		; 4 = system, 8 = volume label, 16 = subdirectory
	jmp fcrt1		; 32 = archive, 64 & 128 = not defined.

; HEADING 'FCLOSE'
FCLOSE:		dw $ + 2	; ( -- f >> t=error )
	mov bx,[hndl1]
	mov ah,3Eh
	int 21h
	xor bx,bx
	mov [hndl1],bx		; show handle as closed
	jmp diskend
%endif

; Headerless code definition to write file (usually the system) to disk
; MikeOS will not overwrite an existing file
HEADING 'FWRITE'
FWRITE:		dw $ + 2	; ( adr cnt -- f >> t=error )
%if MikeOS
	pop cx			; byte count
	pop bx			; start address
	pusha
	mov ax,fname1		; ASCII-Z name pointer
	call os_write_file
	popa
	mov ax,0
	jnc fwr01
	inc ax
  fwr01:
	mov [fdst1],ax		; error flag to FDSTAT
	push ax			; copy on stack
	NEXT
%else
	mov ah,40h		; DOS write to opened file
	jmp fwrt1
%endif

%if MikeOS
; MikeOS get file size to ensure it will fit in available memory
HEADING 'F_SIZE'
F_SIZE:		dw $ + 2	; ( -- u >> file size in bytes )
	pusha
	mov ax,fname1
	call os_get_file_size
        mov [fdwk1],bx          ; size in bytes (0 if error)
	popa
	mov ax,0
	jnc fsz01
	inc ax
  fsz01:
	mov [fdst1],ax		; error flag in FDSTAT
	mov bx,[fdwk1]    	; size in bytes
	push bx			; size
	NEXT
%else
LSEEK:		dw $ + 2	; ( d.dist.start f.relative -- f >> t=error )
	pop ax          ; flag >> 0 = absolute, 1 = relative, 2 = relative to end
	mov ah,42h
	jmp fwrt1       ; note current pointer returned

get_dir:        dw $ + 2	; ( -- f )
  gdir:
	mov ah,47h      ; get current directory
	sub dx,dx
	push si
	mov si, path2
	int 21h
	pop si
	jmp diskend

fsel1:		dw $ + 2	; ( drive# -- f )
	pop dx			; 0 = A = FDD 0, 1 = B = FDD 1, 2 = C = HDD 0.
	mov ax,dx
	add al,'a'
	mov [path1],al		; set drive and path
	mov ah,0Eh
	int 21h
	jmp gdir

chdir:		dw $ + 2	; ( -- f >> t=error )
	mov ah,3Bh
	jmp fcrt1
%endif

%if MikeOS = 0
%if 1
DOS_ERROR:      dw colon	; ( f -- >> true = print error in fdwork )
	dw	STAY, dotq
	db	12,'Disk Error: '
	dw	FDWORK, question
	dw	SPACE, ABORT
%else
	dw      STAY, FDWORK, fetch
	dw      do_switch, do_branch, dker999
	dw      0, dker1, dotq
	db      8,'No error'
	dw      EXIT
  dker1:
	dw      1, dker2, dotq
	db      23,'Invalid Function Number'
	dw      EXIT
  dker2:
	dw      2, dker3, dotq
	db      14,'File Not Found'
	dw      EXIT
  dker3:
	dw      3, dker4, dotq
	db      14,'Path Not Found'
	dw      EXIT
  dker4:
	dw      4, dker5, dotq
	db      19,'Too Many Open Files'
	dw      EXIT
  dker5:
	dw      5, dker6, dotq
	db      13,'Access Defied'
	dw      EXIT
  dker6:
	dw      6, dker7, dotq
	db      14,'Invalid Handle'
	dw      EXIT
  dker7:
	dw      7, dker8, dotq
	db      31,'Memory Control Blocks Destroyed'
	dw      EXIT
  dker8:
	dw      8, dker9, dotq
	db      19,'Insufficient Memory'
	dw      EXIT
  dker9:
	dw      9, dker10, dotq
	db      28,'Invalid Memory Block Address'
	dw      EXIT
  dker10:
	dw      10, dker11, dotq
	db      19,'Invalid Environment'
	dw      EXIT
  dker11:
	dw      11, dker12, dotq
	db      14,'Invalid Format'
	dw      EXIT
  dker12:
	dw      12, dker13, dotq
	db      19,'Invalid Access Code'
	dw      EXIT
  dker13:
	dw      13, dker14, dotq
	db      12,'Invalid Data'
	dw      EXIT
  dker14:
	dw      15, dker16, dotq
	db      23,'Invalid Drive Specified'
	dw      EXIT
  dker16:
	dw      16, dker17, dotq
	db      31,'Cannot Remove Current Directory'
	dw      EXIT
  dker17:
	dw      17, dker18, dotq
	db      15,'Not Same Device'
	dw      EXIT
  dker18:
	dw      18, dker19, dotq
	db      13,'No More Files'
	dw      EXIT
  dker19:
	dw      19, dker20, dotq
	db      20,'Disk Write Protected'
	dw      EXIT
  dker20:
	dw      20, dker21, dotq
	db      12,'Unknown Unit'
	dw      EXIT
  dker21:
	dw      21, dker22, dotq
	db      15,'Drive Not Ready'
	dw      EXIT
  dker22:
	dw      22, dker23, dotq
	db      15,'Unknown Command'
	dw      EXIT
  dker23:
	dw      23, dker24, dotq
	db      9,'CRC Error'
	dw      EXIT
  dker24:
	dw      24, dker25, dotq
	db      28,'Bad Request Structure Length'
	dw      EXIT
  dker25:
	dw      25, dker26, dotq
	db      10,'Seek Error'
	dw      EXIT
  dker26:
	dw      26, dker27, dotq
	db      18,'Unknown Media Type'
	dw      EXIT
  dker27:
	dw      27, dker28, dotq
	db      16,'Sector Not Found'
	dw      EXIT
  dker28:
	dw      28, dker29, dotq
	db      20,'Printer Out Of Paper'
	dw      EXIT
  dker29:
	dw      29, dker30, dotq
	db      11,'Write Fault'
	dw      EXIT
  dker30:
	dw      30, dker31, dotq
	db      10,'Read Fault'
	dw      EXIT
  dker31:
	dw      31, dker32, dotq
	db      15,'General Failure'
	dw      EXIT
  dker32:
	dw      32, dker33, dotq
	db      17,'Sharing Violation'
	dw      EXIT
  dker33:
	dw      33, dker34, dotq
	db      14,'Lock Violation'
	dw      EXIT
  dker34:
	dw      34, dker35, dotq
	db      19,'Invalid Disk Change'
	dw      EXIT
  dker35:
	dw      35, dker36, dotq
	db      15,'FCB Unavailable'
	dw      EXIT
  dker36:
	dw      36, dker37, dotq
	db      23,'Sharing Buffer Overflow'
	dw      EXIT
  dker37:
	dw      66, dker67, dotq
	db      29,'Network Request Not Supported'
	dw      EXIT
  dker67:
	dw      67, dker68, dotq
	db      29,'Remote Computer Not Listening'
	dw      EXIT
  dker68:
	dw      81, dker82, dotq
	db      13,'Access Denied'
	dw      EXIT
  dker82:
	dw      96, dker97, dotq
	db      10,'File Exits'
	dw      EXIT
  dker97:
	dw      99, dker100, dotq
	db      15,'Int 24h Failure'
	dw      EXIT
  dker100:
	dw      100, dker101, dotq
	db      17,'Out Of Structures'
	dw      EXIT
  dker101:
	dw      999, 0, dot, dotq
	db      13,'Error Unknown'
	dw      EXIT
  dker999:
	dw      SPACE, ABORT
%endif
%endif

; HEADING "TEST_CHR"		; ( c -- f ), temporary header for testing
  test_chr:     dw $ + 2
	pop ax
	mov cx,1        ; default = bad
	cmp al,33       ; <= space, control characters & space
	jl tc_end
	cmp al,'~'      ; > '~', no <delete> or graphics
	jg tc_end
	cmp al,34       ; = '"', double quote
	je tc_end
	cmp al,124      ; = '|', pipe symbol
	je tc_end
	cmp al,93       ; > ']' <= '~', ^ _ ` and a through z
	jg tc_ok
	cmp al,92       ; = '\', directory divider
	je tc_ok
	cmp al,42       ; = '!' OR >= '#' < '*'
	jl tc_ok
	cmp al,45       ; < '-' >= '*'
	jl tc_end
	cmp al,90       ; > 'Z' <= ']', ] and [
	jg tc_end
	cmp al,63       ; > '?' <= 'Z', @ and A through Z
	jg tc_ok
	cmp al,57       ; > '9' <= '?'
	jg tc_end
	cmp al,47       ; = '/'
	je tc_end       ; left is '.' OR >= '0' <= '9'
  tc_ok:
	dec cx
  tc_end:
	push cx
	NEXT

HEADING ".AZ"			; ( a -- )
  dot_az:       dw colon	; print ASCII-Z string
	dw      dclit
	db      64, 0
	dw      two_to_r		; DO
  dp1:
	dw      cfa_dup, c_fetch, q_DUP
	dw      q_branch, dp2			; IF
	dw      EMIT, one_plus
	dw      do_branch, dp3			; ELSE
  dp2:
	dw      leave_lp
  dp3:						; THEN
	dw      do_loop, dp1		; LOOP
	dw      DROP
	dw      EXIT

; Improper file name -> abort
err35:		dw colon	; ( f -- )
	dw      abortq
	db      14,"Improper name!"
	dw      EXIT

; Check for valid DOS name. If ok transfer to FNAME
; HEADING 'T_CHRS'		; ( n a -- ), temporary header for testing
  T_CHRS:       dw colon
	dw      OVER, zero, two_to_r
  tc001:
	dw      cfa_dup, eye, plus, c_fetch, test_chr, err35
	dw      do_loop
	dw      tc001
	dw      FNAME, ROT, one_plus, cfa_dup, bite
	db      65
	dw      greater, abortq
	db      tc002 - $ - 1,' Too long.'
  tc002:
	dw      front_cmove
	dw      EXIT

; Get name for read or write in FNAME - null terminated (ASCII-Z)
HEADING "G_NAME"		; ( -- )
  G_NAME:       dw colon
	dw	blnk, cfa_word, COUNT
	dw	m_LEADING, m_TRAILING, SWAP
	dw	OVER, zero_eq, err35
	dw      T_CHRS			; test characters in name, may abort
	dw      EXIT

%if MikeOS = 0
FSEL:		dw colon		; ( drive# -- )
	dw      fsel1, DOS_ERROR        ; will abort if error
	dw      EXIT

; Change directory >> Note: NO wild cards
HEADING "CD"			; ( -- )
		dw colon
	dw      blnk, cfa_word, cfa_dup, c_fetch, zero_eq
	dw      OVER, fetch, cell, 2E01h, cfa_eq, cfa_or, zero_eq, q_branch
	dw      cd001
	dw      cfa_dup, COUNT, SWAP, T_CHRS, chdir, DOS_ERROR
	dw      get_dir, DOS_ERROR
  cd001:
	dw      DROP, PATH, dot_az
	dw      EXIT

HEADING 'A:'			; ( -- )
		dw colon
	dw      zero, FSEL
	dw      EXIT

HEADING 'B:'			; ( -- )
		dw colon
	dw      one, FSEL
	dw      EXIT

HEADING 'C:'			; ( -- )
		dw colon
	dw      two, FSEL
	dw      EXIT
%endif

; Remove extraneous characters (CR, HT & ^Z) from text files
; HEADING 'del_cr'              ; temporary header for troubleshooting
del_cr:		dw $ + 2	; ( a n -- )
	pop cx
	pop di
	mov dx,di
	jcxz dlf3
	inc cx          ; results of last comparison not checked
	push cx
	mov ax,200Dh    ; ah = replacement = space, al = search = CarriageReturn
  dl001:
	repne scasb
	jcxz dlf1
	mov [di-1],ah
	jmp dl001		; find next
  dlf1:
	pop cx
	mov di,dx
	mov al,09		; replace tab characters
  dl002:
	repne scasb
	jcxz dlf2
	mov [di-1],ah
	jmp dl002		; find next
  dlf2:				; at end of buffer
	cmp byte [di-1],26	; eof marker (not always there)
	jne dlf3
	mov [di-1],ah
  dlf3:
	NEXT

; Get input from the disk file >> DOS 1st read is usually 1024 bytes, after that
;  move end of buffer down and get next 512 bytes at end.
; MikeOS read entire file - it must fit in memory without hurting MikeOS or Forth
GET_FILE:       dw colon		; ( a n -- )
	dw      two_dup, ERASE, two_dup, FREAD			; ( a n f )
%if MikeOS
	dw      abortq
	db      19,"Error reading file!"
%else
	dw	DOS_ERROR
%endif
	dw      FDWORK, fetch, cfa_dup, num_tib, plus_store
	dw      OVER, less, cfa_not, q_branch
	dw      gdsk01
        dw      one, q_END, w_store, DROP, FDWORK, fetch	; end of file
        dw      zero, TIB, fetch, num_tib, fetch_plus, c_store	; add ending null
  gdsk01:
	dw      del_cr		; ( a n -- ) replace CR and other unnecessary white space
	dw      EXIT

; Interpreter

; Put next word in input stream at here+2 and return the address
; Formatted as counted string, count = 0 if no input left
STREAM:		dw $ + 2	; ( c -- a ), when exits leaves here+2
  strm1:
	MOV cx,[n_tib1]		; total number of characters in TIB (last line input)
	mov ax,[tin1]		; offset into TIB
	MOV di,[tib1]		; text input buffer address [TIB], 'normal' or disk buffer
%if MikeOS = 0
	test word [hndl1],0xFFFF	; disk stream ?
	jz do_wrd02			; no, continue normally
	test byte [qend1],0xff		; already at end of file ?
	jne do_wrd02			; yes, continue
	cmp ax,512		; still in buf0 ?
	jge strm2		; no, try to get more
%endif
; Separate the next complete word from the input stream, 'c' is delimiter
; Ignore 'c' characters at beginning of the string
; DI points to beginning of string to search
; CX = maximum number of characters [left] in the string to check
do_wrd02:		; Entry with just ( c -- a )
	pop dx          ; DL = chr, DH = 0 = found flag (not yet)
	push dx
	push si         ; thread pointer
	ADD di,ax	; start search after previous 'word' delimiter
	mov si,di	; SI set to read input stream
	mov [tin1],cx	; set pointer to end of input (already there if CX = AX)
	SUB cx,ax	; number of chrs left = total - current offset
	jz wrd05	;   none left, process end of stream (DI = SI, CX = 0)
  wrd_lp1:		; -LEADING
	lodsb		; loop is similar to 'repe scasb' with multiple tests
	cmp al,dl
	je wrd01
	cmp dl,' '	; looking for space ?
	jne wrd02	;   no, continue normally
	cmp al,lf	; treat <LF> (only found in disk stream) same as space
	jne wrd02
  wrd01:
	dec cx
	jnz wrd_lp1
	mov di,si       ; at end of stream, start = finish, DI = SI (don't need reverse)
	jmp short wrd04	;   CX = 0
  wrd02:
	mov al,dl
	dec si		; backup to 1st non-delimiter = start (SI)
	mov di,si       ; start search at non-delimiter (DI), first NE to get CX right
	REPne scasb	; scan for delimiter between words
	jne wrd04	; stream ended, pointing one past last significant character
	dec di		; past delimiter, back up to one past last significant character
  wrd04:
	SUB [tin1],cx	; back >IN to beginning of the next word
  wrd05:		; end of stream jumps directly here
	SUB di,si       ; number significant chr in this word = finish - start
	MOV cx,di
	MOV di,[h1]	; [here] will be set to LFA or string CFA
	inc di
	inc di
	mov dx,di       ; save adr = here + 2 (for definition headers and inline text)
	push cx         ; save count (most cases < 81, must be < 256)
	MOV ax,cx
	stosb           ; counted string format
	REP movsb       ; count = 0 -> do not move anything
	xor ax,ax       ; for building headers, terminate with bytes 0, 0 (space for CFA)
	stosw
	pop cx
	pop si          ; retrieve Forth thread pointer
%if MikeOS = 0
	test cx,0x7FFF		; any chrs (word) found ?
	jnz wrd06		; yes, process normally
	test word [hndl1],0xFFFF	; disk stream ?
	jz wrd06			; no, end of stream, continue
	test byte [qend1],0xff	; already at end of file ?
	je strm2		; no, try to get more
  wrd06:
%endif
	pop ax          ; remove test chr
	push dx         ; a = here+2 -> current string
	JMP exit1	; leave parent definition (WORD)
  strm2:
%if MikeOS = 0
	mov cx,512      ; update counts
	sub [tin1],cx		; >IN
	sub [n_tib1],cx		; #TIB
	MOV di,[tib1]		; text input buffer address [tib] = BUF0
	mov ax,di
	add ax,cx		; buf1 = buf0 + 512
	push ax         ; BUF1
	push cx         ;   and count = 512 for GET_FILE
	xchg ax,si
	shr cx,1	; bytes -> words
	rep movsw       ; move 256 words (512 bytes) from buf1 to buf0
	mov si,ax       ; restore FORTH thread pointer to middle of WORD
			; ( c a=buf1 cnt=512 ) >> GET_FILE to fill buf1
%endif
	NEXT

HEADING 'WORD'			; ( c -- a >> see STREAM )
  cfa_word:	dw colon
  doword01:			; BEGIN
	dw      STREAM		; load registers and go to do_wrd02
%if MikeOS
				; STREAM is code extension with parent exit
	dw      SPACE, ABORT	; should not return, if does quit gracefully
%else
				; only returns here if .com and need more input
	dw      GET_FILE		; ( c a1 512 ) may abort ( c )
	dw	do_branch, doword01	; AGAIN - EXIT not needed
%endif

; Dictionary search

; Very simple hashing function, but separates vocabularies
HASH:                           ; ( na v -- na offset )
		dw $ + 2
	pop ax
	AND ax,0Fh      ; must have a vocabulary (1-15) to search, v <> 0
	shl ax,1	; 2* vocab, different chains for each
	pop di
	push di		; hash = 2 * vocab + 1st char of word
	ADD al,[di+1]	; 1st char (not count)
	AND al,1Eh	; (B_HDR - 2) even, mod 32 => 16 chains
	push ax
	NEXT

; Note - no address can be less than 0100h (.com) or 8000h (MikeOS)
FIND_WD:                        ; ( na offset -- na lfa,0 )
                dw $ + 2
        mov dx,si               ; temporary save (thread) execution pointer
	pop di			; chain offset
	pop ax			; address of counted string to match
	push ax
	ADD di,hds		; address of beginning of hash chain
	push di
  fnd1:
	pop di			;
	mov di,[di]		; get next link
	push di			; last link in chain = 0
	or di,di
	jz fnd2         ; end of chain, not found
	inc di		; goto count/flags byte
	inc di
	MOV cx,[di]
	AND cx,3Fh      ; count (1F) + smudge (20)
	mov si,ax
	CMP cl,[si]
	jne fnd1        ; wrong count, try next word
	inc di		; to beginning of text
	inc si
	REP CMPSB	; compare the two strings
	jne fnd1        ; not matched, try next word
  fnd2:				; exit - found or chain exhausted
	mov si,dx		; restore execution pointer
	NEXT

; LFA since > 0100h (DOS) or 0x8000 (MikeOS), can be used as "found" flag
; Temporary header for testing. Headerless because differences with standards
; HEADING 'FIND'		; ( na -- cfa lfa/f if found || na 0 if not )
  FIND:		dw colon
	dw      CONTEXT, two_fetch	; ( na v.d )
  find1:						; BEGIN
	dw	two_dup, d_zero_eq, cfa_not, q_branch	; WHILE, still vocab to search
	dw	find3
	dw	two_dup, zero, bite
	db	16
	dw	tr_div, two_to_r, DROP, HASH, FIND_WD 
	dw	two_r_from, ROT, q_DUP
	dw	q_branch, find2			; IF found
	dw	m_ROT, two_drop, SWAP, DROP
	dw	cfa_dup, l_to_cfa, SWAP, EXIT
  find2:					; THEN
	dw	do_branch				; REPEAT, not found yet
	dw	find1
  find3:
	dw      two_drop, zero, EXIT			; not found anywhere

HEADING 'DEPTH'			; ( -- n )
  DEPTH:        dw $ + 2
	mov ax,stack0
	SUB ax,sp
	sar ax,1
	dec ax			; 0 for underflow protection
	push ax
	NEXT

q_STACK:	dw colon
	dw      DEPTH, zero_less, abortq
	db      qsk2 - $ - 1
	db      'Stack Empty'
  qsk2:
	dw      EXIT


; Interpreter control - notice that this is not reentrant
;  uses variables - #TIB, >IN & HNDL - to manipulate input (text or disk)
; It will process an entire STREAM before returning to the terminal input (or ABORT)
HEADING 'INTERPRET'
  INTERPRET:    dw colon
  ntrp1:					; BEGIN
	dw	blnk, cfa_word
	dw	cfa_dup, c_fetch, q_branch	; WHILE - text left in input buffer
	dw	ntrp6
	dw	FIND, q_DUP, q_branch	; IF found in context vocabulary, process it
	dw	ntrp3
	dw	one_plus, fetch, zero_less	; Immediate flag in high byte for test
	dw	STATE, fetch, cfa_not, cfa_or
	dw	q_branch, nrtp2		; IF Immediate or not compiling ( cfa )
	dw      EXECUTE, q_STACK, do_branch
	dw	ntrp5			; ELSE compiling => put into current word
  nrtp2:
	dw      comma, do_branch
	dw      ntrp5			; THEN
  ntrp3:				; ELSE try a number - may abort ( na )
	dw      NUMBER
	dw	STATE, fetch, q_branch		; IF compiling => put into current word
	dw      ntrp5
	dw	HLD, fetch, zero_less			; IF single precision (includes byte)
	dw      q_branch
	dw      ntrp4
	dw      LITERAL, do_branch			; ELSE double precision
	dw      ntrp5
  ntrp4:
        dw      cell, dblwd, comma, comma, comma        ; COMPILE dblwd
						; THEN	; THEN
  ntrp5:				; THEN
	dw      do_branch, ntrp1			; REPEAT until stream exhausted
  ntrp6:
	dw	DROP, EXIT			; Exit and get more input

HEADING 'QUERY'			; ( -- )
  QUERY:        dw colon		; get input from keyboard or disk stream
	dw      TIB, fetch, L_WIDTH
	dw	EXPECT
	dw      SPAN, num_tib, XFER	; Forth-83 compatibility
	dw      zero, tin, w_store	; TIB starting offset
	dw      EXIT

R_RESET:        dw $ + 2
	mov bp,first
	NEXT

; QUIT is first half of definition (ends inside QUERY). Normal input etc. follows.
HEADING 'QUIT'			; ( -- )
  QUIT:		dw colon
  QUT1: dw      STATE, false_store		; start by interpreting user input
  qt02:						; BEGIN
	dw	R_RESET, QUERY, INTERPRET
	dw	OK, CR
	dw	do_branch, qt02			; AGAIN => Endless loop
						; Note no Exit needed


; Compiler directives
; Need to use 'cell' to keep bytes from being sign extended

HEADING 'IMMEDIATE'
		dw colon
	dw      LAST, fetch, l_to_nfa
	dw      cfa_dup, c_fetch, cell, 80h	; set bit 7 of the count-flag byte
	dw      cfa_or, SWAP, c_store
	dw      EXIT

HEADING 'ALLOT'			; ( n -- )
  ALLOT:        dw colon
	dw	SP0, OVER, HERE, plus, bite
	db	178				; full head(34) + pad(80) + min stack(64)
	dw	plus, u_less, abortq
	db	alt3 - $ - 1
	db	'Dictionary full'
  alt3:
	dw	H, plus_store, EXIT

HEADING 'C,'			; ( uc -- )
  c_comma:      dw colon
	dw      HERE, c_store, one, ALLOT
	dw      EXIT

HEADING ','			; ( u -- )
  comma:        dw colon
	dw      HERE, w_store, two, ALLOT
	dw      EXIT

HEADING '?CELL'			; ( n -- n f,t=word )
  q_CELL:	dw colon
	dw      cfa_dup, bite
	db      -128
	dw      cell, 128
	dw      WITHIN, zero_eq
	dw      EXIT

IMMEDIATE
HEADING 'LITERAL'		; ( n -- )
  LITERAL:      dw colon
	dw      q_CELL, q_branch, lit1		; IF
        dw      cell, cell, comma, comma        ; COMPILE cell
	dw      do_branch, lit2			; ELSE
  lit1:
        dw      cell, bite, comma, c_comma      ; COMPILE byte
  lit2:						; THEN
	dw      EXIT

IMMEDIATE
HEADING 'COMPILE'
		dw colon
	dw	blnk, cfa_word, FIND	; (cfa t || na 0)
	dw	cfa_not, abortq
	db	cmp1 - $ - 1
	db	'?'
  cmp1:
	dw	LITERAL, sem_cod
  COMPILE:
	db      232			; DOES> ( cfa ) ,
	dw      does - $ - 2
	dw      comma			; puts CFA of next word into dictionary
	dw      EXIT

IMMEDIATE
HEADING "'"			; ( return or compile CFA as literal )
  tic:		dw colon
	dw	blnk, cfa_word, FIND		; ( na 0 || cfa lfa )
        dw	cfa_not, abortq
	db      1,'?'
	dw      STATE, fetch, STAY
	dw      LITERAL, EXIT			; ( compiling => put in-line )

HEADING ']'			; ( -- >> set STATE for compiling )
  r_bracket:	dw $ + 2
	mov ax,1  
	mov [state1],ax		; compiling
	NEXT

IMMEDIATE
HEADING '['			; ( -- )
  l_bracket:	dw $ + 2
	sub ax,ax  
	mov [state1],ax		; interpreting
	NEXT
 
HEADING 'SMUDGE'
  SMUDGE:       dw colon
        dw      LAST, fetch, l_to_nfa, cfa_dup
        dw      c_fetch, blnk			; set bit 5
        dw      cfa_or, SWAP, c_store
        dw      EXIT
 
HEADING 'UNSMUDGE'
  UNSMUDGE:	dw colon
	dw	LAST, fetch, l_to_nfa, cfa_dup
	dw	c_fetch, bite			; clear bit 5
	db	0DFh
	dw	cfa_and, SWAP, c_store
	dw	EXIT

IMMEDIATE
HEADING ';'
		dw colon
	dw      cell, EXIT, comma		; COMPILE EXIT 
	dw	l_bracket, UNSMUDGE
	dw      EXIT

; Chains increase speed of compilation and
;  allow multiple vocabularies without special code.
; User vocabularies can also have separate chains to keep definitions separate.
; 4 chains would be sufficient for a minimum kernel,
;  but vocabularies would be limited to max. of 4
; 8 chains => maximum of 8 vocabularies, good for small systems
;  16 chains best choice for medium to large systems and for cross compiling
;  32 chains are marginally better for larger systems, but more is not better
; nibble in cell => maximum search path of 4 vocabularies
;  dword => 8 nibbles => 8 search vocabularies
; Each vocabulary must have different offset => maximum of 7 vocabularies (8 chains),
;  15 (16 chains), etc. Nibble = null = 0 -> no vocabulary or end of search sequence.
; Note: can "seal" portion of dictionary by eliminating FORTH from search string

HEADING 'VOCABULARY'		; ( d -- )
		dw colon
	dw      cfa_create, SWAP, comma, comma, UNSMUDGE, sem_cod
  vocabulary:
	db      232                     ; call does = DOES>
	dw      does - $ - 2		; return address is PFA of daughter
	dw      two_fetch, CONTEXT, two_store
	dw      EXIT

HEADING 'ASSEMBLER'
  ASSEMBLER:	dw vocabulary, 0012h, 0	; search order is low adr lsb to high adr msb

HEADING 'EDITOR'
		dw vocabulary, 0013h, 0

HEADING 'FORTH'
		dw vocabulary, VOC, 0	; VOC = 00000001

HEADING 'DEFINITIONS'
		dw colon
	dw      CONTEXT, two_fetch, CURRENT, two_store
	dw      EXIT

HEADING ';code'
  sem_cod:      dw colon
	dw      r_from
	dw      LAST, fetch, l_to_cfa, w_store
	dw      EXIT

IMMEDIATE
HEADING ';CODE'
		dw colon
	dw      cell, sem_cod, comma		; COMPILE ;code
	dw	r_from, DROP, ASSEMBLER
	dw      l_bracket, UNSMUDGE
	dw      EXIT

HEADING 'CVARIABLE'
		dw colon
	dw	cfa_create, zero, c_comma, UNSMUDGE
	dw	EXIT

HEADING 'VARIABLE'
  VARIABLE:     dw colon
	dw      cfa_create, zero, comma, UNSMUDGE
	dw      EXIT

HEADING '2VARIABLE'
		dw colon
	dw      VARIABLE, zero, comma
	dw      EXIT

IMMEDIATE
HEADING 'DCLIT'	; ( c1 c2 -- )
		dw colon
	dw      cell, dclit, comma	; COMPILE dclit
	dw      SWAP, c_comma, c_comma  ; reverse bytes here instead of
	dw      EXIT                    ;  execution time!

HEADING 'ARRAY'			; ( #bytes -- )
		dw colon
	dw      cfa_create, HERE, OVER
	dw      ERASE, ALLOT, UNSMUDGE
	dw      EXIT


; Compiler directives - conditionals

; Absolute [long] structures
; Short structures did not save that much space, longer execution time
; Note: the code contains 47 Forth ?branch (IF) statements
;       19 do_branch -- other conditionals such as THEN and REPEAT
;       9 normal loops, 3 /loops and 1 +loop

IMMEDIATE
HEADING 'IF'			; ( -- a )
  cfa_if:	dw colon
	dw	cell, q_branch, comma	; COMPILE ?branch
	dw      HERE, zero, comma
	dw      EXIT

IMMEDIATE
HEADING 'THEN'			; ( a -- )
  THEN:		dw colon
	dw      HERE, SWAP, w_store
	dw      EXIT

IMMEDIATE
HEADING 'ELSE'			; ( a1 -- a2 )
		dw colon
	dw	cell, do_branch, comma	;  COMPILE branch
	dw      HERE, zero, comma 
	dw      SWAP, THEN, EXIT

IMMEDIATE
HEADING 'BEGIN'			; ( -- a )
		dw colon
	dw      HERE
	dw      EXIT

IMMEDIATE
HEADING 'UNTIL'			; ( a -- | f -- )
		dw colon
	dw      cell, q_branch, comma	; COMPILE ?branch
	dw      comma, EXIT

IMMEDIATE
HEADING 'AGAIN'			; ( a -- )
  AGAIN:	dw colon
	dw      cell, do_branch, comma	; COMPILE branch
	dw      comma, EXIT

IMMEDIATE
HEADING 'WHILE'
		dw colon
	dw      cfa_if, SWAP
	dw      EXIT

IMMEDIATE
HEADING 'REPEAT'
		dw colon
	dw      AGAIN, THEN
	dw      EXIT

; Switch Support - part 2 (compiling)

IMMEDIATE
HEADING 'SWITCH'
		dw colon
	dw      cell, do_switch, comma	; COMPILE switch
	dw      cell, do_branch, comma	; COMPILE branch
	dw      HERE, cfa_dup, zero, comma
	dw      EXIT

IMMEDIATE
HEADING 'C@SWITCH'
		dw colon
	dw      cell, c_switch, comma	; COMPILE c_switch
	dw      cell, do_branch, comma	; COMPILE branch
	dw      HERE, cfa_dup, zero, comma
	dw      EXIT

IMMEDIATE
HEADING '{'			; ( a1 a2 n -- a1 h[0] )
		dw colon
	dw      comma, HERE, zero
	dw      comma, cfa_dup, two_minus, ROT
	dw      w_store, r_bracket
	dw      EXIT

IMMEDIATE
HEADING '}'
		dw colon
	dw      cell, EXIT, comma	; COMPILE EXIT
	dw      EXIT

IMMEDIATE
HEADING 'ENDSWITCH'
		dw colon
	dw      DROP, THEN
	dw      EXIT

; Compiler directives - looping

IMMEDIATE
HEADING 'DO'			; ( -- a )
		dw colon
	dw      cell, two_to_r, comma	; COMPILE 2>R
	dw      HERE, EXIT

IMMEDIATE
HEADING 'LOOP'			; ( a -- )
		dw colon
	dw      cell, do_loop, comma	; COMPILE loop
	dw      comma, EXIT

IMMEDIATE
HEADING '+LOOP'			; ( a -- )
		dw colon
	dw      cell, plus_loop, comma	; COMPILE +loop
	dw      comma, EXIT

IMMEDIATE
HEADING '/LOOP'			; ( a -- )
		dw colon
	dw      cell, slant_loop, comma	; COMPILE /loop
	dw      comma, EXIT


; Miscellaneous

IMMEDIATE
HEADING 'DOES>'
		dw colon
	dw      cell, sem_cod, comma	; COMPILE ;code runtime
	dw      cell, 232, c_comma	; CALL does - leaves PFA on stack
	dw      cell, does - 2, HERE
	dw      minus, comma		; compile offset
	dw      EXIT

HEADING 'EMPTY'			; ( -- )
  EMPTY:        dw colon
	dw      FENCE, HEADS, bite
	db      34
	dw      front_cmove
	dw      EXIT

; Updates HERE and HEADS, but not LAST
HEADING 'FORGET'
		dw colon
	dw      blnk, cfa_word, CURRENT, c_fetch, HASH, FIND_WD	; ( na v -- na lfa,0 )
	dw      q_DUP, cfa_not, abortq
	db      1,'?'
	dw      SWAP, DROP, cfa_dup			; (lfa lfa)
	dw      cell, goldh, fetch
	dw      u_less					; ( protected from deletion )
	dw      abortq
	db      5,"Can't"
	dw      H, w_store				; new HERE = LFA
	dw      H, HEADS, two_to_r			; DO for 16 chains
  fgt1:
	dw      eye, fetch
  fgt2:						; BEGIN
	dw      cfa_dup, HERE, u_less
	dw      cfa_not, q_branch, fgt3		; WHILE defined after this word, go down chain
	dw      fetch, do_branch, fgt2		; REPEAT
  fgt3:
	dw      eye, w_store, two, slant_loop, fgt1	; /LOOP update top of chain, do next
	dw      EXIT

HEADING 'PROTECT'		; ( -- )
  PROTECT:      dw colon
	dw      HEADS, FENCE, bite	; 16 hash links, here and last
	db      34
	dw      front_cmove
	dw      EXIT

; IMMEDIATE
; HEADING 'STRING'		; ( -- )
  STRING:       dw colon
	dw      bite
	db      '"'
	dw      cfa_word, c_fetch, two_plus	; allot string length, calling routine,
	dw      one_plus, ALLOT			;   and count
	dw      EXIT

IMMEDIATE
HEADING 'ABORT"'
		dw colon
	dw      STATE, fetch, q_branch, abtq1	; IF ( -- ) compiling
	dw      cell, abortq, HERE, STRING, w_store	; COMPILE abort" and put string into dictionary
	dw      do_branch, abtq3
  abtq1:
	dw      bite				; ELSE ( f -- ), interpret must have flag
	db      '"'
	dw      cfa_word, SWAP, q_branch, abtq2		; IF flag is true, print string and abort
	dw      COUNT, cfa_type, ABORT
	dw      do_branch, abtq3
  abtq2:						; ELSE drop string address
	dw      DROP
  abtq3:					; THEN	THEN
	dw      EXIT

IMMEDIATE
HEADING '."'
		dw colon
	dw      STATE, fetch, q_branch, dq1		; IF compiling
	dw	cell, dotq, HERE, STRING, w_store	; COMPILE ." and put string into dictionary
	dw      do_branch, dq2
  dq1:						; ELSE print following string
	dw      bite
	db      '"'
	dw      cfa_word, COUNT, cfa_type
  dq2:						; THEN
	dw      EXIT

HEADING '?'			; ( a -- )
  question:     dw colon
	dw      fetch, dot
	dw      EXIT


; Set operating bases

HEADING 'BASE!'			; ( n -- )
  base_store:   dw colon
	dw      cfa_dup, BASE, w_store
	dw      T_BASE, w_store
	dw      EXIT

HEADING '.BASE'			; ( -- >> print current base in decimal )
		dw colon
	dw      BASE, fetch, cfa_dup, bite
	db      10
	dw      BASE, w_store, dot
	dw      BASE, w_store
	dw      EXIT

HEADING 'DECIMAL'
  DECIMAL:      dw colon
	dw      bite
	db      10
	dw      base_store
	dw      EXIT

HEADING 'HEX'
  HEX:		dw colon
	dw      bite
	db      16
	dw      base_store
	dw      EXIT

HEADING 'OCTAL'
		dw colon
	dw      bite
	db      8
	dw      base_store
	dw      EXIT

HEADING 'BINARY'
		dw colon
	dw      bite
	db      2
	dw      base_store
	dw      EXIT

HEADING 'd'
		dw colon
	dw      bite
	db      10
	dw      T_BASE, w_store
	dw      EXIT

HEADING '$'
		dw colon
	dw      bite
	db      16
	dw      T_BASE, w_store
	dw      EXIT

HEADING 'Q'
		dw colon
	dw      bite
	db      8
	dw      T_BASE, w_store
	dw      EXIT

HEADING '%'
		dw colon
	dw      bite
	db      2
	dw      T_BASE, w_store
	dw      EXIT

; Inline comment
IMMEDIATE
HEADING '('
		dw colon
	dw      bite
	db      ')'
	dw      cfa_word, DROP
	dw      EXIT

; ^C interrutpt for BIOS >> allows break out of wayward definition (usually)
; HEADING 'CC'			; heading for old 'generate'. updated forth.com
;		dw $ + 2
  ctrl_c:                       ; control C interrupt routine
	cli
	mov ax,cs
	mov ss,ax
	sti
	mov ds,ax
	mov es,ax
	sub ax,ax
	mov [span1],ax		; nothing yet
	mov [tin1],ax		; input from keyboard,
	mov [hndl1],ax		; not disk drive
	mov [state1],ax		; not compiling
	mov [tflg1],ax		; normal t & r _flg
	jmp abrt

; Divide by 0 processor interrupt
; HEADING '/0'			; heading for old generate
;		dw $ + 2
  div_0:                        ; divide zero interrupt
	sub ax,ax
	cwd
	mov di,1		; on return, 80286 will repeat division !
	iret

; Comment from \ to end of this (current) line
; DOS terminator <cr><lf> or Linux terminator <lf>
IMMEDIATE
HEADING '\'
		dw colon
	dw      bite
	db      lf
	dw      cfa_word, DROP
	dw      EXIT


; Vocabulary lists

HEADING 'ID.'			; ( lfa -- >> prints name of word at link addr )
  id_dot:       dw colon
	dw      l_to_nfa, cfa_dup, c_fetch, bite
	db      1Fh
	dw      cfa_and, zero
	dw      two_to_r		; DO for len of word (some versions do not store whole word)
  id1:
	dw      one_plus, cfa_dup, c_fetch	; ( adr chr )
	dw      cfa_dup, blnk, less, q_branch	; IF control character, print caret
	dw      id2
	dw      dotq
	db      1,'^'
	dw      bite
	db      64
	dw      plus
  id2:						; THEN
	dw      EMIT
	dw      do_loop
	dw      id1			; LOOP
	dw      DROP, SPACE, SPACE
	dw      EXIT

HEADING 'H-LIST'		; ( n -- >> n = chain number, 0 to 15)
  hlist:	dw colon
	dw      two_times, HEADS, plus_fetch    ; ( list head )
	dw      CR
  hlst1:					; BEGIN
	dw      q_DUP, q_branch, hlst3		; WHILE
	dw      cfa_dup, id_dot, fetch
	dw      get_cursor, bite		; test column
	db      64
	dw      greater, q_branch, hlst2 ; IF
	dw      CR
  hlst2:				 ; THEN
	dw      DROP 				; drop row/line
	dw      do_branch, hlst1		; REPEAT
  hlst3:
	dw      EXIT

; Headerless, only used by WORDS below
; returns highest lfa contained in copy of HEADS at PAD
MAX_HEADER:     dw colon			; ( -- index max.lfa )
	dw      zero_dot
	dw      B_HDR, zero, two_to_r
  mh1:
	dw      cfa_dup, PAD, eye, plus_fetch
	dw      u_less, q_branch		; ( new max lfa )
	dw      mh2
	dw      two_drop, eye, PAD
	dw      eye, plus_fetch
  mh2:
	dw      two, slant_loop
	dw      mh1
	dw      EXIT

HEADING 'VLIST'			; ( -- >> lists the words in the context vocabulary )
		dw colon
	dw      HEADS, PAD, B_HDR		; copy HEADS to PAD
	dw      front_cmove, CR
  wds1:						; BEGIN
	dw      MAX_HEADER, cfa_dup, q_branch	; WHILE a valid lfa exists at PAD
	dw      wds4
	dw      two_dup, two_plus		; ( index lfa index nfa )
	dw      CONTEXT, fetch, HASH		; just first vocab
	dw      SWAP, DROP			; ( index lfa index index' )
	dw      cfa_eq, q_branch		; IF in this vocab, display name
	dw      wds2
	dw      cfa_dup, id_dot
  wds2:					; THEN
	dw      fetch, SWAP, PAD
	dw      plus, w_store			; update PAD, working header
	dw      get_cursor, bite
	db      64
	dw      greater, q_branch		; IF near end of line, send new line
	dw      wds3
	dw      CR
  wds3:					; THEN
	dw      DROP, do_branch
	dw      wds1
  wds4:						; REPEAT
	dw      two_drop
	dw      EXIT


; Miscellaneous extensions

HEADING '.S'
  dot_s:        dw colon
	dw      q_STACK, DEPTH, CR, q_branch	; IF
	dw      dots2
	dw      sp_fetch, cell, stack0 - 4, two_to_r
  dots1:
	dw      eye, fetch, u_dot, bite
	db      -2
	dw      slant_loop
	dw      dots1
  dots2:
	dw      dotq
	db      dots3 - $ - 1
	db      ' <--Top '
  dots3:
	dw      EXIT

; Checking lower case and changing to upper might be a little more complicated
;   with UTF fonts
HEADING 'LOWER>UPPER'		; ( c -- c' )
		dw colon
	dw      cfa_dup, dclit
	db      'a', 'z'+1
	dw      WITHIN, q_branch
	dw      l_u1
	dw      blnk, minus		; if lower case ASCII clear bit 5
  l_u1:
	dw      EXIT

HEADING '?MEM'			; ( -- left )
		dw colon
	dw      sp_fetch, PAD
	dw      two_plus, minus
	dw      EXIT

; Read BIOS timer, wait here until decrements by 2300+ counts (about 1 ms)
msec:		dw $ + 2
	mov al,06	; latch counter 0
	out 43h,al
	in al,40h
	mov dl,al
	in al,40h
	mov dh,al
	sub dx,2366	; (1193.2 - 10 setup)*2/msec
  ms1:
	mov al,06	; latch counter 0
	out 43h,al
	in al,40h
	mov cl,al
	in al,40h
	mov ch,al
	sub cx,dx
	cmp cx,12       ; uncertainty
	ja ms1          ; U>

HEADING 'MS'			; ( n -- )
		dw colon
	dw      zero, two_to_r
  ms01:
	dw      msec, do_loop
	dw      ms01
	dw      EXIT
	NEXT

; As written there may be a problem with reentrant programs (nesting), ie,
;   coming back to a file with an INCLUDE -- needs more testing.
; MikeOS is not a good fit for nesting.
HEADING "INCLUDE"		; ( -- )
		dw colon
	dw      G_NAME					; aborts if not 8.3 name
	dw      q_END, two_fetch, two_to_r	; save previous ?END and HNDL
	dw      TIB, fetch, to_r		; current stream pointer,
	dw      num_tib, fetch, to_r		;   length
	dw	tin, fetch, to_r		;   and place in it
%if MikeOS
	dw	PAD, cell, 1200, plus, sp_fetch	; start = pad + 1200, max = SP - 612, avail = max - start
	dw	OVER, minus, cell, 612, minus	; available (about 20k) will be < 32768
	dw	F_SIZE, cfa_dup, to_r, u_less	; problem if available < file size
	dw	FDSTAT, fetch, cfa_or		;   or OS error
	dw      abortq
	db      11,"Size Error!"
	dw	r_from				; ( load-adr size -- )
	dw	OVER, TIB, w_store		; address to interpret from
%else
	dw      zero, FOPEN, DOS_ERROR  	; open for reading - may abort
	dw      FDWORK, HNDL, XFER		; open worked, set active handle
%endif
	dw      num_tib, false_store		; set at beginning of stream
	dw	q_END, false_store		;   and not at file end, yet
%if MikeOS
	dw	one, HNDL, w_store		; now streaming from disk file
	dw	GET_FILE			; get entire file, may abort, update #TIB
%else
	dw      BUF0, cell, 1024, GET_FILE      ; may abort
	dw	BUF0, TIB, w_store		; set TIB to disk buffer
%endif
	dw      tin, false_store		; start at the beginning of the stream
	dw	INTERPRET			; process disk file data (stream)
%if MikeOS = 0
	dw      FCLOSE, DOS_ERROR               ; may abort
%endif
	dw	r_from, tin, w_store		; restore previous stream position,
	dw      r_from, num_tib, w_store		;   size
	dw      r_from, TIB, w_store		;   and pointer
	dw      two_r_from, q_END, two_store	; restore previous ?END and HNDL
%if MikeOS = 0
	dw      HNDL, fetch, q_branch		; IF nested INCLUDE, go back to previous
	dw      inc1
	dw      num_tib, fetch, s_to_d, DNEGATE	; add get previous disk contents
	dw      one, LSEEK, DOS_ERROR
	dw	num_tib, false_store
	dw      BUF0, cell, 1024, GET_FILE
  inc1:						; THEN
%endif
	dw      EXIT

; High level word for generating a new .com file with new hash lists in place
; Forth is case sensitive; notice lower case name to prevent unwanted writes
HEADING 'write_exec'
		dw colon
	dw	HNDL, fetch			; if write was in INCLUDEd file
	dw      G_NAME
%if MikeOS
	dw	cell, 8000h
%else
	dw	zero, FCREATE, DOS_ERROR	; create a DOS file (handle) - may abort
	dw      FDWORK, HNDL, XFER		; worked, save it
	dw      cell, 100h
%endif
	dw	HERE, OVER, minus, FWRITE
%if MikeOS
	dw	abortq
	db	12, "Write Error!"
%else
	dw	DOS_ERROR
	dw      FCLOSE, DOS_ERROR		; always clears handle
%endif
	dw	HNDL, w_store
	dw      EXIT

GOLDEN_HERE:		; Used for setting FENCE 'HERE'

IMMEDIATE
HEADING 'ASCII'			; ( -- c )
		dw colon
	dw      blnk, cfa_word, one_plus
	dw      c_fetch                  ; ( ASCII value of 1st character of next word )
	dw      STATE, fetch
	dw      STAY, LITERAL
	dw      EXIT

HEADING 'D_VER'			; DOS or MikeOS API version - display purposes
  D_VER:        dw create
  dver1:        dw      0

; Miscellaneous definitions, not currently used by kernel

; Dump a series of bytes from given address, 16 numbers per line
; Switch to HEX if bytes are >= 100 (64h)
HEADING 'DUMP'			; ( a n -- )
  DUMP:		dw colon
	dw      zero, two_to_r			; DO
  du1:
	dw      eye, bite
	db      15
	dw      cfa_and, cfa_not, q_branch		; IF, new line
	dw      du2
	dw      CR, cfa_dup, eye, plus, bite
	db      5
	dw      u_dot_r
  du2:							; THEN
	dw      eye, bite
	db      7
	dw      cfa_and, cfa_not, q_branch		; IF 0 or 8, 2 more spaces
	dw      du3
	dw      SPACE, SPACE
  du3:							; THEN
	dw	cfa_dup, eye
	dw      plus, c_fetch, bite
	db      4
	dw      u_dot_r, do_loop
	dw      du1				; LOOP
	dw      CR, DROP
	dw      EXIT

HEADING 'R-DEPTH'
	dw      $ + 2
	MOV ax,first
	SUB ax,bp
	SHR ax,1
	push ax
	NEXT

HEADING 'WDUMP'			; ( a n -- )
	dw      colon
	dw      zero, two_to_r
  wdp1:
	dw      eye, bite
	db      7
	dw      cfa_and, cfa_not, q_branch
	dw      wdp2
	dw      CR, cfa_dup, eye, two_times, plus, bite
	db      5
	dw      u_dot_r, SPACE
  wdp2:
	dw      cfa_dup, eye, two_times
	dw      plus_fetch, bite
	db      7
	dw      u_dot_r, do_loop
	dw      wdp1
	dw      CR, DROP
	dw      EXIT

HEADING 'R>S'
	dw      $ + 2
	MOV cx,first
	SUB cx,bp
	shr cx,1
	MOV ax,cx
  rs1:
	MOV di,cx
	shl di,1
	NEG di
	ADD di,first
	push word [di]
	LOOP rs1
	push ax
	NEXT

HEADING '?PRINTABLE'		; ( c -- f,t=printable )
  q_PRINTABLE:   dw      colon
	dw      dclit
	db      spc, '~'+1
	dw      WITHIN
	dw      EXIT

HEADING '.LINE'			; ( adr n -- )
  dot_line:     dw      colon
	dw      to_r, PAD, eye, front_cmove
	dw      PAD, eye, zero, two_to_r
  dln1:
	dw      cfa_dup, eye, plus, c_fetch, q_PRINTABLE
	dw      cfa_not, q_branch
	dw      dln2
	dw      bite
	db      94
	dw      OVER, eye, plus, c_store
  dln2:
	dw      do_loop
	dw      dln1
	dw      r_from, cfa_type
	dw      EXIT

HEADING 'A-DUMP'		; ( a n -- )
  a_dump:       dw      colon
	dw      zero, two_to_r
  ad1:
	dw      eye, bite
	db      63
	dw      cfa_and, cfa_not, q_branch
	dw      ad2
	dw      CR, cfa_dup, eye, plus, bite
	db      5
	dw      u_dot_r, bite
	db      3
	dw      SPACES
  ad2:
	dw      cfa_dup, eye, plus, bite
	db      64
	dw      eye_prime, cfa_min, dot_line, bite
	db      64
	dw      slant_loop
	dw      ad1
	dw      CR, DROP
	dw      EXIT

; Initial program entry and start up code
; No header, but still needs to be PROTECTed
; If here to end of program modified, check/modify the GEN.4th script
do_startup:
	mov ax,cs		; init segments
	mov ds,ax
	mov es,ax
	cli
%if MikeOS
	mov dx,ss
	mov [sp_save],sp
	mov [ss_save],dx
%endif
	mov ss,ax       	; init stack
	mov sp,stack0
	sti

	mov ah,0Fh      	; get current display mode from BIOS
	int 10h
	sub dx,dx
	mov dl,ah
	mov [max_col],dx
	mov dl,al
	mov [_mode],dx
	mov dl,bh
	mov [_page],dx

	push ds
	mov ax,40h		; BIOS data segment, ah = 0
	mov ds,ax
	mov si,84h      	; rows - 1
	lodsb
	inc ax
	mov [es:max_rows],ax
	mov si,17h      	; caps lock on (most BIOS)
	mov al,[si]
	or al,40h
	mov [si],al
	pop ds

%if MikeOS
	call os_get_api_version
	mov ah,al
	xor al,al
%else
	mov ah,30h              ; get dos version
	int 21h
%endif
	mov [dver1],ax

%if MikeOS
	mov dl,'a'
%else
	MOV ah,19h              ; get/save current disk
	int 21h
	MOV dl,al
	add dl,'a'
%endif
	mov [path1],dl

%if MikeOS = 0
	mov ah,47h              ; get current directory
	sub dx,dx
	mov si, path2
	int 21h
%endif

	push es
	xor ax,ax		; get current, set new div 0 vector
	mov es,ax		; interrupt segment and offset = 0
	mov di,ax
	mov bx,[es:di]
	mov dx,[es:di+2]
	mov [d_off],bx
	mov [d_seg],dx
	mov bx,div_0
	mov dx,ds
	mov [es:di],bx
	mov [es:di+2],dx

	mov di,0x8c		; interrupt segment = 0 and offset = 4 * 23h
%if MikeOS
	mov bx,[es:di]		; get/save current [ctrl]C vector
	mov dx,[es:di+2]
	mov [c_off],bx
	mov [c_seg],dx
%endif
	mov bx,ctrl_c            ; set new [ctrl]C vector
	mov dx,ds
	mov [es:di],bx
	mov [es:di+2],dx
	pop es

	mov bp,first            ; R at end of mem - see r_reset
	sub ax,ax		; Top of parameter stack (for underflow)
	push ax
	MOV si, start_forth	; forward reference, may be modified when new GEN.4th
	NEXT			; goto FORTH start, begin following pointers

; For GEN.4TH startup must immediately preceed VERSION to set new start address
; When generating a new file, VERSION may be FORGOTTEN and a new one created
NORM_LAST:		; LFA of last definition with a header

HEADING 'VERSION'
  VERSION:      dw colon
	dw      dotq
	db      vr01 - $ - 1
	db      'V1.5.3 2020/11/23 '
  vr01:
	dw      EXIT

; High level Start-up
; Headerless. May be FORGOTTEN. GEN.4th usually creates a replacement
; If forgotten, the address of a new start_forth must be set in the above startup code
; If retained, the forward reference to N_HASH must be removed before re-saving
; Moves h1 because PAD shifts with HERE
start_forth:
	dw      CR, CR, dotq
	db      sf01 - $ - 1
%if MikeOS
	db      'Copyright (C) 2014-2020 MikeOS Developers -- see doc/LICENSE.TXT'
%else
	db      'Copyright 1993-2013, all rights reserved.'
%endif
  sf01:
	dw      CR, dotq
	db      sf02 - $ - 1
	db      'FORTH version '
  sf02:
	dw      VERSION
	dw      CR, dotq
	db      sf03 - $ - 1
%if MikeOS
	db      'MikeOS API version '
%else
	db      'DOS version '
%endif
  sf03:
	dw      D_VER, one_plus, c_fetch, zero, st_num
	dw      add_num, add_num, bite 
	db	46
	dw	HOLD, two_drop
	dw      D_VER, c_fetch, zero, nums, nd_num, cfa_type
	dw      CR, PATH, dot_az
	dw      CR, OK, CR			; no print on following ABORT
	dw	N_HASH
; End of dictionary after start, next definition goes here (unless EMPTY)
; move HERE to eliminate re-HASH and change HASH to ABORT (allow saving as is)
NORM_HERE:
	dw	cell, NORM_HERE, H, w_store
	dw	cell, ABORT, cell, NORM_HERE, two_minus, w_store
	dw      ABORT

; Break a long, single chain of definitions into separate hash lists
; Generate can save modified dictionary for faster startup
N_HASH:		dw colon		; create hash lists from one long chain
	dw	PAD, B_HDR, ERASE		; temporary buffer for pointers
	dw	cell, NORM_LAST, cfa_dup	; set last link field to VERSION
	dw	LAST, w_store
  nh1:					; BEGIN ( lfa )
	dw	q_DUP, q_branch, nh05	; WHILE not start of dictionary
	dw	cfa_dup, fetch, SWAP
	dw	zero, OVER, w_store		; set chain end, just in case
	dw	cfa_dup, l_to_nfa, bite
	db	VOC				; ( lfa' lfa nfa v )
	dw	HASH, SWAP, DROP		; ( lfa' lfa lnk ) 
	dw	cfa_dup, HEADS, plus_fetch
	dw	cfa_not, q_branch, nh2		; set end of normal chain IF not already
	dw	two_dup, HEADS, plus, w_store
  nh2:						; THEN
	dw	two_dup, FENCE, plus_fetch, cfa_not
	dw	SWAP, cell, goldh, fetch, one, plus
	dw	u_less, cfa_and
	dw	q_branch, nh03			; set end of GOLDEN chain IF not already
	dw	two_dup, FENCE, plus, w_store
  nh03:						; THEN
	dw	PAD, plus, cfa_dup, fetch	; update individual chains
	dw      q_branch, nh04		 	; IF not first, update chain
						; ( lfa' lfa padx )
	dw      two_dup, fetch, w_store
  nh04:						; THEN
	dw      w_store				; update pad buffer
	dw      do_branch, nh1		; REPEAT
  nh05:
	dw      EXIT

; HERE until first start is completed (N_HASH uses PAD -> the area after HERE)
very_end:
	dw	0, 0

; END
