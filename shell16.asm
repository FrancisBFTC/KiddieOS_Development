%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG SHELL16]


jmp Os_Shell_Setup
jmp Os_Inter_Shell


%DEFINE FAT16.LoadDirectory (FAT16+3)
%DEFINE FAT16.LoadFAT       (FAT16+6)
%DEFINE FAT16.LoadThisFile  (FAT16+9)

FAT16.FileSegments    EQU   (FAT16+15)
FAT16.DirSegments 	  EQU   (FAT16+17)
FAT16.LoadingDir      EQU   (FAT16+19)

%DEFINE A3_TONE  1355
%DEFINE F3_TONE  1715
%DEFINE B3_TONE  1207

Shell.CounterFName db 0
ErrorDir           db 0
ErrorFile          db 0
IsFile             db 0
IsHexa             db 0


BufferKeys 	       times 60 db 0
BufferArgs         times 60 db 0
FolderAccess:
	db '\'
	times 150 db 0
CounterAccess      dw 0x0001
CmdCounter 	       db 0
ExtCounter         db 0
Quant              db 0
CursorRaw          db 5
CursorCol          db 12
LimitCursorBeginX  db 0
LimitCursorFinalY  db 22
QuantDirs          db 1
StatusArg     db 0
CounterChars  db 0
CounterChars1 db 0
CounterList   db 0
Selection db 0
CmdWrite  db 0
SaveAddressString dw 0x0000
SavePositionLeft  dw 0x0000
SavePositionRight dw 0x0000
Background_Color  db 0001_1111b
Borderpanel_Color db 0010_1111b
Backeditor_Color  db 0000_1111b 
Backpanel_Color   db 0111_0000b

PointerBuffer     dd 0x00000000
SavePointerArgs   dw 0x0000

OffsetNextFile    dw 0x0000
CD_SEGMENT        dw 0x07C0   ; start in root directory

; Buffer to Disk Drive Parameters (Pointer = DS:SI)
; ------------------------------------------------
SizeBuffer        dw 0x001E
InfoFlags         dw 0x0000
NumberCylinders   dd 0x00000000
NumberHeads       dd 0x00000000
SectorsPerTrack   dd 0x00000000
AbsoluteSectors   dq 0x0000000000000000
BytesPerSector    dw 0x0000
EDDParameters     dd 0x00000000
; ------------------------------------------------
	
; Create_Panel Routine :
; 		CH -> First Line ; CL -> First Column ; DH -> Last Line ; DL -> Last Column
Os_Shell_Setup:
	
	Back_Blue_Screen:
		mov     bh, [Background_Color]     
		mov     cx, 0x0000         ; CH = 0, CL = 0     
		mov     dx, 0x1950         ; DH = 25, DL = 80
		call    Create_Panel
	Back_Black_Editor:
		mov     bh, [Backeditor_Color]     
		mov     cx, 0x050C         ; CH = 5, CL = 12              
		mov     dx, 0x1643         ; DH = 22, DL = 67          
		call    Create_Panel
	Back_Green_Left:
		mov     bh, [Borderpanel_Color]     
		mov     cx, 0x0400         ; CH = 4, CL = 0               
		mov     dx, 0x160B         ; DH = 22, DL = 11
		call    Create_Panel
	Back_Green_Right:
		mov     bh, [Borderpanel_Color]       
		mov     cx, 0x0444         ; CH = 4, CL = 68               
		mov     dx, 0x164F         ; DH = 22, DL = 80
		call    Create_Panel
	Back_White_Left:
		mov     bh, [Backpanel_Color]      
		mov     cx, 0x0500         ; CH = 5, CL = 0                          
		mov     dx, 0x160A         ; DH = 22, DL = 10
		call    Create_Panel
	List_Commands_Panel:
		mov 	word[SavePositionLeft], cx
		mov 	dx, cx
		mov 	byte[CounterList], 0
		mov 	byte[Selection], ch
		mov 	cx, COUNT_COMMANDS
		mov 	si, Vector.CMD_Names
		call 	Write_Info
	Back_White_Right:
		mov     bh, [Backpanel_Color]
		mov     cx, 0x0545         ; CH = 5, CL = 69               
		mov     dx, 0x164F         ; DH = 22, DL = 79
		call    Create_Panel
		mov 	word[SavePositionRight], cx
	Back_Bottom_Green:
		mov     bh, [Background_Color]      
		mov     cx, 0x1800         ; CH = 24, CL = 0         
		mov     dx, 0x1950         ; DH = 25, DL = 80
		call    Create_Panel
	
; Print_Labels Routine :
;         DH -> Line Cursor ; DL -> Column Cursor
Print_Labels:
	
	mov     dx, 0x011E          ; DH = 1, DL = 30
	call    Move_Cursor
	mov si, NameSystem
	call Print_String
	Prt_Cmd:
		mov 	dx, 0x0400      ; DH = 4, DL = 0
		call 	Move_Cursor
		mov 	si, CommandsStr
		call 	Print_String
	Prt_Info:
		mov 	dx, 0x0445      ; DH = 4, DL = 69
		call 	Move_Cursor
		mov 	si, InfoStr
		call 	Print_String
	Prt_Help1:
		mov 	dx, 0x1701      ; DH = 23, DL = 1
		call	Move_Cursor
		mov 	si, helptext1
		call 	Print_String
	Prt_Help2:
		mov 	dx, 0x1801      ; DH = 24, DL = 1
		call 	Move_Cursor
		mov 	si, helptext2
		call 	Print_String 
	Cursor_Commands:
		call	Cursor.CheckToRollEditor
		mov 	bx, word[CounterAccess]
		add 	dl, bl
		add 	dl, 3   ;2
		cmp 	byte[Quant], 0
		jna 	PrintAccess
		inc 	dl
	PrintAccess:
		mov 	byte[LimitCursorBeginX], dl
		mov     si, LetterDisk
		call    Print_String
		mov 	si, FolderAccess
		call 	Print_String
		mov     si, SimbolCommands
		call    Print_String
		
		; Set Cursor Shape Full-Block
		call 	Show_Cursor
		call 	VerifyToWrite
		cmp 	byte[CmdWrite], 1
		je 		Shell_Editor2
		
Shell_Editor:
	mov 	di, BufferKeys
	mov 	word[SaveAddressString], di
	call 	Zero_Buffer
  Shell_Editor2:
	mov 	byte[CmdWrite], 0
	mov 	di, BufferArgs
	mov 	word[SavePointerArgs], di
	call 	Zero_Buffer
	mov 	di, BufferKeys
	mov 	si, Vector.CMD_Names
	push 	di
	mov 	di, word[SaveAddressString]
	Start:
		mov 	ah, 00h
		int 	16h
		cmp 	al, 0x08
		je 		CheckBackspace
		cmp 	al, 0x0D
		je		Shell_Interpreter
		cmp 	al, 0x1B
		je 		List_Commands
		cmp 	ah, 0x3B
		je 		ChangeLayout1
		cmp 	ah, 0x3C
		je 		ChangeLayout2
		cmp 	ah, 0x3D
		je 		ChangeLayout3
		cmp 	ah, 0x3E
		je 		ChangeLayout4
		cmp 	ah, 0x3F
		je 		ChangeLayout5
		cmp 	ah, 0x40
		je 		ChangeLayout3
		cmp 	ah, 0x50
		je 		RollEditorToUp
		cmp 	ah, 0x48
		je 		RollEditorToDown
		cmp 	al, 0x20
		je		AltStatusArg
		jmp 	SaveChar
	AltStatusArg:
		mov 	byte[StatusArg], 1
		mov 	ah, 0Eh
		int 	10h
		push 	di
		push 	ds
		pop 	es
		mov 	di, word[SavePointerArgs]
		stosb
		mov 	word[SavePointerArgs], di
		pop 	di
		jmp 	SaveAndShow
	SaveChar:
		mov 	ah, 0Eh
		int 	10h
		push 	di
		push 	ds
		pop 	es
		mov 	di, word[SavePointerArgs]
		stosb
		mov 	word[SavePointerArgs], di
		pop 	di
		mov 	bl, al
		cmp 	bl, "."
		je 		CreateSpaceFile
		cmp 	bl, '/'
		je 		IncQuantDirs
		cmp 	bl, 0x60
		ja  	Conversion2
		cmp 	bl, 0x40
		ja 		Conversion1
		cmp 	bl, 0x29
		ja 		ConvertNumber
		jmp 	SaveAndShow
		
		IncQuantDirs:
			inc 	byte[QuantDirs]
			jmp 	SaveAndShow
			
		Conversion1:
			cmp 	byte[StatusArg], 1
			je	 	SaveAndShow
			cmp 	bl, 0x5B
			jnb		SaveAndShow
			sub 	bl, 0x41
			mov 	al, byte[VetorCharsLower + bx]
			jmp 	SaveAndShow
		Conversion2:
			cmp 	byte[StatusArg], 0
			je	 	SaveAndShow
			cmp 	bl, 0x7B
			jnb 	SaveAndShow
			sub 	bl, 0x61
			mov 	al, byte[VetorCharsUpper + bx]
			jmp 	SaveAndShow
		ConvertNumber:
			cmp 	bl, 0x40
			jnb 	SaveAndShow
			sub 	bl, 0x30
			mov 	al, byte[VetorHexa + bx]
			jmp 	SaveAndShow
			
	CreateSpaceFile:
		cmp 	byte[di - 1], "."
		je 		IsDirectory
		cmp 	byte[di - 1], " "
		je 		IsDirectory
		mov 	byte[IsFile], 1
		cmp 	byte[CounterChars], 9
		je 		Start
		mov 	bl, byte[CounterChars]
		dec 	bl
		mov 	byte[CounterChars1], bl
		mov 	cl, 8
		sub 	cl, bl
		xor 	ch, ch
		FillSpaceFile:
			mov 	byte[di], " "
			inc 	di
			loop 	FillSpaceFile
		jmp 	Start
			
	EraseSpaceFile:
		cmp 	byte[IsFile], 1
		jne 	CheckSpaceArg
		inc 	byte[ExtCounter]
		cmp 	byte[di], " "
		jne 	Possible8Chars
		;jne 	CheckSpaceArg
		BackLastChar:
			dec 	di
			cmp 	byte[di], " "
			je		BackLastChar
			xor 	cx, cx
			mov 	bl, byte[CounterChars1]
			mov 	cl, 8
			sub 	cl, bl
			push 	di
		EraseSpaceDot:
			inc 	di
			mov 	byte[di], 0
			loop 	EraseSpaceDot
			pop 	di
		ChangeAttrib:
			inc 	di
			inc 	byte[CounterChars]
			mov 	byte[IsFile], 0
			mov 	byte[ExtCounter], 0
		CheckSpaceArg:
			cmp 	byte[di], " "
			jne 	RetEraseSpaces
			mov 	byte[StatusArg], 0
			mov 	byte[CounterChars], 0
			jmp 	RetEraseSpaces
		Possible8Chars:
			cmp 	byte[ExtCounter], 4
			je 		ChangeAttrib
	RetEraseSpaces:
		ret	
			
	IsDirectory:
		mov 	byte[IsFile], 0
	SaveAndShow:
		mov 	[di], al
		inc 	di
		cmp 	byte[StatusArg], 1
		jne 	Start
		inc 	byte[CounterChars]
		jmp 	Start		
	CheckBackspace:
		call 	Get_Cursor
		cmp 	dl, byte[LimitCursorBeginX]
		je		Start
		dec 	word[SavePointerArgs]
		dec		di
		call 	EraseSpaceFile
		mov 	byte[di], 0
		mov 	ah, 0Eh
		int 	10h
		mov 	al, byte[di]
		int 	10h
		mov 	al, 0x08
		int 	10h
		cmp 	byte[StatusArg], 1
		jne 	Start
		dec 	byte[CounterChars]
		jmp 	Start
	RollEditorToUp:
		mov 	ah, 06h
		call 	RollingEditor
		jmp 	Start
	RollEditorToDown:
		mov 	ah, 07h
		call 	RollingEditor
		jmp 	Start
		
	
	
Shell_Interpreter:
	add 	byte[CursorRaw], 1
	call	Cursor.CheckToRollEditor
	Os_Inter_Shell:
		mov 	cx, COUNT_COMMANDS   				; ler até 2 comandos
		mov 	byte[CmdCounter], 0
		pop 	di
		push	si
		push 	di
	SearchCommand:
		mov 	al, [si]
		cmp 	al, [di]
		jne 	NextCommand
		inc 	si
		inc 	di
		cmp 	byte[di], " "     ; Se último caracter for espaço é porque tem argumentos
		je 		Founded
		cmp 	al, 0             ; Se for 0 é porque não tem argumentos
		je 		Founded
		jmp 	SearchCommand
	NextCommand:
		cmp 	al, 0
		je 		Next
		inc 	si
		mov 	al, [si]
		jmp 	NextCommand
	Next:
		inc 	byte[CmdCounter]
		inc 	si
		pop 	di
		push 	di
		loop 	SearchCommand
		jmp 	NoFounded
	Founded:
		push 	di
		pop		si
		pop		di
		pop 	bx
		xor 	bx, bx
		mov 	bl, byte[CmdCounter]
		shl		bx, 1
		mov 	bx, word[Vector.CMD_Funcs + bx]
		cmp 	byte[CmdCounter], 3
		jb 		No_Return_Jump
		call 	bx
		mov 	byte[StatusArg], 0
		mov 	byte[CounterChars], 0
		mov 	byte[IsFile], 0
		jmp 	Cursor_Commands
	No_Return_Jump:
		call 	Zero_Buffer
		mov 	byte[CmdCounter], 0
		mov 	byte[CounterList], 0
		mov 	byte[StatusArg], 0
		mov 	byte[CounterChars], 0
		mov 	byte[Selection], 0
		mov 	byte[CursorRaw], 5
		xor 	ax, ax
		xor 	cx, cx
		xor 	dx, dx
		jmp 	bx
	NoFounded:
		pop 	si
		pop 	di	
		call 	Exec.SearchFileToExec     ; Tentar encontrar programa operável
		add 	byte[CursorRaw], 1
		mov 	byte[StatusArg], 0
		mov 	byte[CounterChars], 0
		jmp 	Cursor_Commands
			
		
		
List_Commands:
	call 	Hide_Cursor
	mov 	cx, word[SavePositionLeft]
	mov 	byte[CounterList], 0
	mov 	byte[Selection], ch
	mov 	dx, word[SavePositionLeft]
	call	Focus_Select
	call 	Show_Information
	WriteOp:
		push 	cx
		mov 	dx, word[SavePositionLeft]
		mov 	cx, COUNT_COMMANDS
		mov 	si, Vector.CMD_Names
		call 	Write_Info
		pop 	cx
		mov 	ax, A3_TONE
		call 	Play_Sound
		
	Select_Options:
		mov 	ah, 00h
		int 	16h
		cmp 	ah, 0x50
		je 		IncSelection
		cmp 	ah, 0x48
		je 		DecSelection
		cmp 	al, 0x0D
		je 		WriteCommand
		cmp 	al, 0x1B
		je 		UnSelectExit
		jmp 	Select_Options
		
	IncSelection:
		cmp		byte[CounterList], COUNT_COMMANDS-1
		jne		IncNow
		mov 	byte[CounterList], 0
		call 	Erase_Select
		sub		ch, COUNT_COMMANDS-1
		call	Focus_Select
		call 	Show_Information
		jmp 	WriteOp
		IncNow:
			inc 	byte[CounterList]
			call 	Erase_Select
			inc 	ch
			call	Focus_Select
			call 	Show_Information
			jmp 	WriteOp
	DecSelection:
		cmp		byte[CounterList], 0
		jne		DecNow
		mov 	byte[CounterList], COUNT_COMMANDS-1
		call 	Erase_Select
		add		ch, COUNT_COMMANDS-1
		call	Focus_Select
		call 	Show_Information
		jmp 	WriteOp
		DecNow:
			dec 	byte[CounterList]
			call 	Erase_Select
			dec 	ch
			call	Focus_Select
			call 	Show_Information
			jmp 	WriteOp
	UnSelectExit:
		call 	Erase_Select
		mov 	dx, word[SavePositionLeft]
		mov 	cx, COUNT_COMMANDS
		mov 	si, Vector.CMD_Names
		call 	Write_Info
		mov     bh, [Backpanel_Color]      
		mov 	cx, word[SavePositionRight]             
		mov     dx, 0x164F         ; DH = 22, DL = 80
		call    Create_Panel
		mov 	ax, F3_TONE
		call 	Play_Sound
		jmp 	Cursor_Commands
	WriteCommand:
		mov 	byte[CmdWrite], 1
		mov 	di, BufferKeys
		mov 	si, Vector.CMD_Names
		xor 	cx, cx
		mov 	cl, byte[CounterList]
		cmp 	cl, 0
		jz 		JumpFinder
		FindCommand:
			push 	ax
			mov 	al, 0
			call 	NextInfo
			pop 	ax
			loop 	FindCommand
		JumpFinder:
			mov 	word[SaveAddressString], si
		SaveCommand:
			mov 	al, [si]
			mov 	[di], al
			inc 	si
			inc 	di
			cmp 	byte[si], 0
			jnz 	SaveCommand
			mov 	ax, B3_TONE
			call 	Play_Sound
			jmp 	UnSelectExit
			
	VerifyToWrite:
		cmp 	byte[CmdWrite], 1
		jne 	RetWrite
		mov 	si, word[SaveAddressString]
		call 	Print_String
		mov 	word[SaveAddressString], di
	RetWrite:
		ret
			

Erase_Select:
	mov  	ch, byte[Selection]
	mov 	dh, ch
	mov     bh, [Backpanel_Color]     ; Black_White
	call 	Select_Event
	mov  	ch, byte[Selection]
ret
	
Focus_Select:
	mov 	dh, ch
	mov 	byte[Selection], ch
	mov     bh, [Borderpanel_Color]    ; Green_White
	call 	Select_Event
ret	
	
Select_Event:
	push  	dx
	add		dl, 9
	call	Create_Panel
	pop 	dx
ret
			

ChangeLayout1:
	mov 	bh, [Background_Color]
	call 	UpdateLayout
	mov 	[Background_Color], bh
	jmp Back_Blue_Screen

ChangeLayout2:
	mov 	bh, [Borderpanel_Color]
	call 	UpdateLayout
	mov 	[Borderpanel_Color], bh
	jmp Back_Green_Left


ChangeLayout3:
	mov 	bh, [Backeditor_Color]
	call 	UpdateLayout
	mov 	[Backeditor_Color], bh
jmp Back_Black_Editor


ChangeLayout4:
	mov 	bh, [Backpanel_Color]
	call 	UpdateLayout
	mov 	[Backpanel_Color], bh
	jmp Back_White_Left
	
ChangeLayout5:
	mov 	bh, [Background_Color]
	call 	UpdateLayout
	mov 	[Background_Color], bh
	mov 	bh, [Backpanel_Color]
	call 	UpdateLayout
	mov 	[Backpanel_Color], bh
	jmp Back_Blue_Screen


UpdateLayout:
	mov 	bl, bh
	and 	bx, 0xF00F
	shr		bh, 4
	shl 	bl, 4
	cmp 	ah, 0x3F
	jb 		ChangeBackColor
	shr 	bl, 4
	inc 	bl
	shl 	bl, 4
	jmp 	RetUpdate
ChangeBackColor:
	inc 	bh
RetUpdate:
	shl 	bx, 4 
ret
			
			
Zero_Buffer:
	pusha
	mov 	cx, 30
	Zero:
		mov 	byte[di],0
		inc 	di
		loop 	Zero
	popa
ret
	
PrintData:
	pusha
	mov 	ah, 0x0E
	dec 	byte[LimitCursorFinalY]
	xor		bl, bl
Display:
	mov 	al, byte[es:di]
	cmp 	byte[IsHexa], 1
	je      DisplayHex
DisplayText:
	cmp		al, 0x0D
	je 		IsEnter
	cmp 	al, 0x09
	je 		DisplayTab
	int 	0x10
	jmp 	JumpDisplayHex
	DisplayTab:
		mov 	al, 0x20
		int 	0x10
		int 	0x10
		int 	0x10
		int 	0x10
		jmp 	JumpDisplayHex
DisplayHex:
	call 	Print_Hexa_Value8
	mov 	ah, 0eh
	mov 	al, " "
	int 	10h
JumpDisplayHex:
	call 	Get_Cursor
	cmp 	dl, 67
	ja 		IsEnter
	inc 	di
	jmp 	Continue
	IsEnter: 
		inc 	bl
		cmp 	bl, 17
		jne 	LineBreak
		call 	Wait_Key
		xor 	bl, bl
		LineBreak:
			inc 	byte[CursorRaw]
			call 	Cursor.CheckToRollEditor
			inc 	di
	Continue:
		loop 	Display
DONE:
	inc 	byte[LimitCursorFinalY]
	popa
RET

PrintDataHex16:
	pusha
	mov 	ah, 0x0E
	dec 	byte[LimitCursorFinalY]
	xor		bl, bl
Display1:
	mov 	ax, word[es:di]
	call 	Print_Hexa_Value16
	mov 	ah, 0eh
	mov 	al, " "
	int 	10h
	call 	Get_Cursor
	cmp 	dl, 65
	ja 		IsEnter1
	add 	di, 2
	jmp 	Continue1
	IsEnter1: 
		inc 	bl
		cmp 	bl, 17
		jne 	LineBreak1
		call 	Wait_Key
		xor 	bl, bl
		LineBreak1:
			inc 	byte[CursorRaw]
			call 	Cursor.CheckToRollEditor
			add 	di, 2
	Continue1:
		loop 	Display1
DONE1:
	inc 	byte[LimitCursorFinalY]
	popa
RET

Cursor.CheckToRollEditor:
	pusha
	mov 	dh, byte[CursorRaw]
	cmp 	dh, byte[LimitCursorFinalY]
	ja   	RollEditor
	mov 	dl, byte[CursorCol]
	call 	Move_Cursor
	jmp 	RetCheck
RollEditor:
	mov 	ah, 06h
	call 	RollingEditor
	mov 	dh, byte[LimitCursorFinalY]
	mov 	byte[CursorRaw], dh
	mov 	dl, byte[CursorCol]
	call 	Move_Cursor
RetCheck:
	popa
	mov 	dl, byte[CursorCol]
ret
	
RollingEditor:
	pusha
	mov 	al, 1
	mov     bh, [ds:Backeditor_Color] 
	mov     cx, 0x050C             
	mov     dx, 0x1643
	int 	10h
	popa
ret

Show_Information:
	pusha
	mov     bh, [Backpanel_Color]      
	mov 	cx, word[SavePositionRight]             
	mov     dx, 0x164F         ; DH = 22, DL = 80
	call    Create_Panel
	mov 	dx, cx
	xor 	bx, bx
	mov 	bl, byte[CounterList]
	shl		bx, 1
	mov 	si, word[Vector.CMD_Infos + bx]
	xor 	cx, cx
	mov 	cl, [si]
	inc 	si
	call 	Write_Info
	popa
ret


NextInfo:
	inc 	si
	cmp 	byte[si], al
	jne 	NextInfo
	inc 	si
ret

Wait_Key:
	push 	ax
	xor 	ax, ax
	int 	16h
	pop 	ax
ret

FillWithSpaces:
	push 	si
	push 	ax
	;mov 	al, 0    ; ==== analyse =====
	call 	NextInfo
	pop 	ax
	dec 	si
	mov 	bl, byte[CounterChars]
	dec 	bl
	mov 	cl, 11
	sub 	cl, bl
	xor 	ch, ch
	FillBuffer:
		mov 	byte[si], " "
		inc 	si
		loop 	FillBuffer
	pop 	si
ret

EraseSpaces:
	push 	si
	mov 	bl, byte[CounterChars]
	dec 	bl
	mov 	cl, 11
	sub 	cl, bl
	xor 	ch, ch
	cmp 	cl, 0
	jz 		RetErase
	push 	ax
	mov 	al, " "
	call 	NextInfo
	pop 	ax
	dec 	si
	EraseBufferSpaces:
		mov 	byte[si], 0
		inc 	si
		loop 	EraseBufferSpaces
RetErase:
	pop 	si
ret

Exec:

.SearchFileToExec:
	mov  	ax, word[CD_SEGMENT]
	mov 	es, ax
	mov 	di, 0x0200
	
	;inc 	byte[CursorRaw]
	;call 	Cursor.CheckToRollEditor
	
	push 	si
	mov 	al, 0
	call 	FillWithSpaces
	pop 	si
	
	mov 	byte[Shell.CounterFName], 0
	
	push 	si
	push 	di
	
	mov 	cx, 11
	call 	ToUpper
	
	TryFind:
		cmp 	byte[es:di + 11], 0x0F   ; LFN ATTRIB
		je 		TryNextFile
		
		pop 	di
		pop 	si
		push 	si
		push 	di
		
		mov 	cx, 7
	Check1:	
		mov 	al, byte[es:di]
		cmp 	al, byte[ds:si]
		jne  	TryNextFile
		inc 	di
		inc 	si
		inc 	byte[Shell.CounterFName]
		loop 	Check1
		
		pop 	di
		pop 	si
		push 	si
		push 	di
		
		mov 	cx, 3
		add 	di, 8
		mov 	si, ProgExtension
	Check2:	
		mov 	al, byte[es:di]
		cmp 	al, byte[ds:si]
		jne  	TryNextExtension
		inc 	di
		inc 	si
		loop 	Check2
		jmp 	NextStep
	
	TryNextExtension:
		pop 	di
		pop 	si
		push 	si
		push 	di
		
		mov 	cx, 3
		add 	di, 8
		mov 	si, ProgExtension
		add 	si, cx
	Check3:	
		mov 	al, byte[es:di]
		cmp 	al, byte[ds:si]
		jne  	TryNextFile
		inc 	di
		inc 	si
		loop 	Check3
		
		inc 	byte[CursorRaw]
		call 	Cursor.CheckToRollEditor
			
		jmp 	NextStep
		
	TryNextFile:
		pop 	di
		pop 	si
		
		add 	di, 32
		
		cmp 	byte[es:di], 0
		jz 		ShowErrorFound
		
		push 	si
		push 	di
	
		jmp 	TryFind
		
	NextStep:
		; Conversão de argumento para nome de arquivo na entrada 
		; ======================================================
		sub 	si, 3
		mov 	bx, si    		; BX = Endereço da Extensão KXE
		pop 	di
		pop 	si       		; Nome do arquivo com espaços
		push 	si
		push 	di
		mov 	di, si    		; DI = Nome de arquivo com espaços
		add 	di, 8     		; Desloca até posição da extensão
		mov 	si, bx    		; SI = Extensão
		mov 	ax, ds
		mov 	es, ax          ; Define ES = DS
		cld                     ; Limpa a Flag de direção (incremento)
		mov 	cx, 3
		rep  	movsb	        ; move CX bytes de DS:SI para ES:DI 
		xor 	ax, ax
		stosb			        ; Após a extensão será 0
		pop 	di
		pop 	si              ; Recupera endereço de SI para leitura
		; ======================================================
		
		mov 	ax, 0x9000 ; segmento de processos
		mov 	word[FAT16.FileSegments], ax
		mov 	ax, word[CD_SEGMENT]
		mov 	word[FAT16.DirSegments], ax
		mov 	byte[FAT16.LoadingDir], 0
		mov 	bx, 0x0000
		call 	FAT16.LoadThisFile
		cmp 	cx, 0
		jz 		NoFoundError
		cmp 	byte[ErrorFile], 0
		jnz 	PrintErrorFile
	
	; ------------------------------------------------------------
	; TODO detectar executáveis MZ checando os primeiros 2 caracteres
	; do endereço carregado e efetuar o procedimento para execução
	; do programa MZ em modo real
	
		
		mov 	ax, 0x9000
		mov 	es, ax
		
		cmp 	WORD[es:0x0], "MZ"
		jne 	Run_32BIT_Prog
		
		mov 	cx, WORD [es:0x0 + 0x06]  ; Numero de entradas na tabela de realocação
		mov 	bx, WORD [es:0x0 + 0x18] ; Deslocamento para tabela de realocação
		
	addic_entry_offset:
		mov 	dx, [es:bx]
		mov 	ax, [es:bx + 2]
		shl 	ax, 4
		add 	ax, dx
		push 	bx
		mov 	bx, ax
		mov 	ax, es
		xor 	dx, dx
		mov 	es, dx
		add 	[es:bx], ax
		mov 	es, ax
		pop 	bx
		add 	bx, 4
		loop 	addic_entry_offset
		
		shl 	bx, 4
		jmp 	0x9000:0x01C0
	; ------------------------------------------------------------
	
		;xor		ah,ah
		;int		1Ah
		;mov		ax,cx
		;shl		eax,16
		;mov		ax,dx
		;mov		[StartTime],eax
	
	Run_32BIT_Prog:
	; ----------------------------------------------------------
	; MANIPULANDO ARGUMENTOS DA CLI
	
		mov 	si, BufferArgs
	    mov 	ecx, 1
		push 	si
	CheckCountArgs:
		lodsb
		cmp 	al, 0
		je 		CountSuccess
		cmp 	al, 0x20
		jne 	CheckCountArgs
	SkipSpace:
		lodsb
		cmp 	al, 0
		je 		CountSuccess
		cmp 	al, 0x20
		je 		SkipSpace
		inc 	ecx
		dec 	si
		jmp 	CheckCountArgs

	CountSuccess:
		pop 	si
		mov 	ebx, 4
		call 	Calloc
		mov 	dword[PointerBuffer], eax
		mov 	edi, dword[PointerBuffer]
		push 	ds
		pop 	es
		push 	ecx
		push 	edi
		
	TransferArgs:
		mov 	eax, esi
		add 	eax, 0xC000
		stosd
	OffsetToSpace:
		lodsb
		cmp 	al, 0
		je 		ReplaceSpaceToZero
		cmp 	al, 0x20
		jne 	OffsetToSpace
	OffsetToExitSpace:
		lodsb
		cmp 	al, 0
		je 		ReplaceSpaceToZero
		cmp 	al, 0x20
		je 		OffsetToExitSpace
		dec 	esi
		jmp 	TransferArgs
	
	ReplaceSpaceToZero:
		mov 	si, BufferArgs
		ReplaceSpace:
			lodsb
			cmp 	al, 0
			je 		Load_Program
			cmp 	al, 0x20
			jne 	ReplaceSpace
			dec 	si
			mov 	byte[si], 0
			inc 	si
			jmp 	ReplaceSpace
			
	
	; ----------------------------------------------------------	

	Load_Program:
		pop 	esi
		add 	esi, 0xC000
		pop 	ecx
		
		mov 	dh, byte[CursorRaw]
		mov 	dl, byte[CursorCol]
		
		call 	SYSCMNG     ; <- Chama o programa pelo gerenciador da SysCall
		
		mov 	dx, si
		mov 	byte[CursorRaw], dh
		mov 	byte[CursorCol], dl
		
		mov 	ax, word[SYSCMNG + 3]
		mov 	byte[ReturnByte], al
		
		;xor	ah,ah
		;int	1Ah
		;mov	ax,cx
		;shl	eax,16
		;mov	ax,dx
		;sub	eax,[StartTime]
		;mov [StartTime], eax
		
		
		inc 	byte[CursorRaw]
		call 	Cursor.CheckToRollEditor
		
		push 	ds
		pop 	es
		;mov 	di, ProgTerminate1
		;mov 	cx, word[ProgTerminate1.SizeTerm1]
		;call 	PrintData
		
		;mov 	ax, word[StartTime]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[StartTime+2]
		;call	Print_Hexa_Value16
		
		;mov 	di, ProgTerminate2
		;mov 	cx, word[ProgTerminate2.SizeTerm2]
		;call 	PrintData
		
		;mov 	al, byte[ReturnByte]
		;call 	Print_Hexa_Value8
		
		jmp 	RetSFTE
			
ShowErrorFound:
	inc 	byte[CursorRaw]
	call 	Cursor.CheckToRollEditor
		
	mov 	ax, ds
	mov 	es, ax
	mov 	di, ErrorFound
	mov 	cx, word[ErrorFound.LenghtError0]
	call 	PrintData
	push 	si
	mov 	al, " "
	call 	NextInfo
	dec 	si
	mov 	byte[si], 0
	pop 	si
	call 	Print_String
	mov 	di, ErrorProg
	mov 	cx, word[ErrorProg.LenghtError1]
	call 	PrintData
		
RetSFTE:
	;inc 	byte[CursorRaw]
ret

ToUpper:
	mov 	al, [ds:si]
	mov 	bl, al
	Case:
		cmp 	bl, 0x60
		ja 		ChangeToUpper
		jmp 	BackTheLoop
	ChangeToUpper:
		cmp 	bl, 0x7B
		jae		BackTheLoop
		sub 	bl, 0x61
		mov 	al, byte[VetorCharsUpper + bx]
		mov 	byte[ds:si], al
	BackTheLoop:
		inc 	si
		loop 	ToUpper
ret
		

Cmd.EXIT   : jmp	Kernel_Menu
Cmd.REBOOT : jmp 	Reboot_System
Cmd.START  : jmp    Wmanager_Start
	
Cmd.BPB:
	mov 	ax, 0x07C0
	mov 	es, ax
	xor 	di, di
	mov 	si, Str_Buffername
	call	Print_String
	mov 	bx, BPB_Index
	mov 	si, Str_BytesPerSector
	mov 	cx, 10
Loop_Print:
	push 	cx
	push 	bx
	inc 	bx
	mov 	al, [bx]
	dec 	bx
	mov 	bl, [bx]
	sub 	al, bl
	push 	ax
	
	inc 	byte[CursorRaw]
	call	Cursor.CheckToRollEditor
	
	xor 	bh, bh
	call	Print_String
	pop 	ax
	cmp 	al, 2
	jb 		MovByte
	xor 	ax, ax
	mov 	ax, word[es:di + bx]
	call 	Print_Hexa_Value16
	jmp 	Restore
MovByte:
	xor 	ax, ax
	mov 	al, byte[es:di + bx]
	call 	Print_Hexa_Value16
Restore:	
	pop 	bx
	pop 	cx
	inc 	bx
	
	push 	ax
	mov 	al, 0
	call 	NextInfo
	pop 	ax
	loop 	Loop_Print
	mov 	cx, 3
Loop_Print1:
	push 	cx
	push 	bx
	mov 	bx, [bx]
	
	inc 	byte[CursorRaw]
	call	Cursor.CheckToRollEditor
	
	xor 	bh, bh
	call	Print_String
	xor 	ax, ax
	mov 	ax, word[es:di + bx]
	call 	Print_Hexa_Value16
	sub 	bx, 2
	mov 	ax, word[es:di + bx]
	call 	Print_Hexa_Value16
	
	pop 	bx
	pop 	cx
	inc 	bx
	
	push 	ax
	mov 	al, 0
	call	NextInfo
	pop 	ax
	loop 	Loop_Print1
	mov 	cx, 3
Loop_Print2:
	push 	cx
	push 	bx
	mov 	bl, [bx]
	
	inc 	byte[CursorRaw]
	call	Cursor.CheckToRollEditor
	
	xor 	bh, bh
	call	Print_String
	xor 	ax, ax
	mov 	al, byte[es:di + bx]
	call 	Print_Hexa_Value16
	
	pop 	bx
	pop 	cx
	inc 	bx
	
	push 	ax
	mov 	al, 0
	call	NextInfo
	pop 	ax
	loop 	Loop_Print2
	
	call 	Wait_Key
	
	inc 	byte[CursorRaw]
	call	Cursor.CheckToRollEditor
	
	mov 	si, Str_VolumeLabel
	call	Print_String
	xor 	ax, ax
	add 	di, 43
	mov 	cx, 11
	call 	PrintData
	
	inc 	byte[CursorRaw]
	call	Cursor.CheckToRollEditor
	
	mov 	si, Str_SystemID
	call	Print_String
	xor 	ax, ax
	add 	di, 11
	mov 	cx, 8
	call 	PrintData
	
	add 	byte[CursorRaw], 1
ret

Cmd.LF:
	mov 	ax, word[CD_SEGMENT]
	mov 	es, ax
	mov 	di, 0x0200
	
	inc 	byte[CursorRaw]
	call 	Cursor.CheckToRollEditor
	
	mov 	si, MetaData
	call	Print_String
	
	mov 	byte[Shell.CounterFName], 0
	
	ShowFiles:
		cmp 	byte[es:di + 11], 0x0F   ; LFN ATTRIB
		je 		NextFile
		
		inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
	
		call 	Print_Name_File
		
		xor 	cx, cx
		mov  	cl, 13
		mov 	bl, byte[Shell.CounterFName]
		sub 	cl, bl
	Spaces1:
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		loop 	Spaces1
		mov 	byte[Shell.CounterFName], 0
	
	CheckAttrib:
		;xor 	ax, ax
		mov 	al, byte[es:di + 11]
		;call 	Print_Hexa_Value16
		;jmp 	CheckDateTime
		cmp 	al, 0x10  ; DIRECTORY ATTRIB
		je 		TypeDir    
		cmp 	al, 0x20  ; ARCHIVE ATTRIB
		je 		TypeArc
		cmp 	al, 0x30  ; FOLDER ATTRIB
		je 		TypeFol
		cmp 	al, 0x08  ; VOLUME ATTRIB
		je 		TypeVol
		mov 	si, MetaData.Oth
		call	Print_String
		jmp 	CheckDateTime
	TypeDir:
		mov		si, MetaData.Dir
		call	Print_String
		jmp 	CheckDateTime
	TypeArc:
		mov 	si, MetaData.Arc
		call	Print_String
		jmp 	CheckDateTime
	TypeFol:
		mov 	si, MetaData.Fol
		call	Print_String
		jmp 	CheckDateTime
	TypeVol:
		mov 	si, MetaData.Vol
		call 	Print_String

		
	CheckDateTime:
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		mov 	ax, word[es:di + 16]
		call	Print_Hexa_Value16
		
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		
		mov 	ax, word[es:di + 14]
		call	Print_Hexa_Value16
		
	CheckSize:
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		mov 	al, ' '
		int 	10h
		mov 	eax, dword[es:di + 28]
		push 	ax
		shr 	eax, 16
		call	Print_Hexa_Value16
		pop 	ax
		call 	Print_Hexa_Value16
		
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		mov 	al, ' '
		int 	10h
		
	CheckCluster:
		mov 	ax, word[es:di + 26]
		call 	Print_Hexa_Value16
		
	NextFile:
		add 	di, 32
	
		cmp 	byte[es:di], 0
		jz 		RetLF
	
		jmp 	ShowFiles
RetLF:
	add 	byte[CursorRaw], 2    ;1
ret

Cmd.CLEAN:
	mov     bh, [Backeditor_Color]
	mov     cx, 0x050C         ; CH = 5, CL = 12              
	mov     dx, 0x1643         ; DH = 22, DL = 67          
	call    Create_Panel
	mov 	byte[CursorRaw], 5
ret


Cmd.READ:
	;inc 	byte[CursorRaw]
	;call	Cursor.CheckToRollEditor
	inc 	si         ; Argumento: ponteiro para nome de arquivo
	mov 	ax, 0x3800 ; segmento de arquivos
	mov 	word[FAT16.FileSegments], ax
	mov 	ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	mov 	bx, 0x0000
	call 	FAT16.LoadThisFile
	cmp 	cx, 0
	jz 		NoFoundError
	cmp 	byte[ErrorFile], 0
	jnz 	PrintErrorFile
	
	ShowDataFile:
		mov 	word[OffsetNextFile], bx
		sub 	bx, 2
	
		mov 	cx, dx
		mov 	ax, 0x3800
		mov 	es, ax
		xor 	di, di
		call	PrintData
		
		jmp 	RetRead
	
	NoFoundError:
		push 	si
		mov 	si, MsgFileError1
		call 	Print_String
		pop 	si
		call 	Print_String
		mov 	si, MsgFileError2
		call 	Print_String
		jmp 	RetRead
	PrintErrorFile:
		push 	si
		mov 	si, MsgDirError1
		call 	Print_String
		pop 	si
		call 	Print_String
		mov 	si, ErrIsNotFile1
		call 	Print_String
RetRead:
	inc 	byte[CursorRaw]
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
ret

Cmd.FAT:
	mov 	ax, 0x17C0
	mov 	es, ax
	mov 	di, 0x0200
	mov 	cx, 100
	call 	PrintDataHex16
	inc 	byte[CursorRaw]
ret

Cmd.HEX:
	xor 	byte[IsHexa], 1
	mov 	si, DisabledMsg
	cmp 	byte[IsHexa], 1
	jnz 	RetHex
	mov 	si, EnabledMsg
RetHex:
	call 	Print_String
	inc 	byte[CursorRaw]
ret
	
	
	

	

Cmd.CD:
	inc 	si         ; Argumento: ponteiro para nome de arquivo
	
	cmp 	byte[IsFile], 1
	je 		NoFillSpaces
	
	; ====================================
	; analyse
	
	cmp 	byte[QuantDirs], 1
	jna 	TillZero
	mov 	al, "/"
	jmp 	FillTillBar
	
TillZero:
	mov 	al, 0
FillTillBar:

	; end analyse
	; =====================================
	
	call 	FillWithSpaces
	
NoFillSpaces:

	cmp 	word[CD_SEGMENT], 0x07C0
	je 		VerifyArg
	cmp 	word[si], ".."
	je 		SubSegment
	jmp 	AddSegment
SubSegment:
	mov		ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0200
	push 	ax
	sub 	ax, 0x500
	cmp 	ax, 0x07C0
	je 		BackSegment
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	pop 	ax
	call 	FAT16.LoadThisFile
	cmp 	cx, 0
	jz 		NoFoundError1
	cmp 	byte[ErrorDir], 0
	jnz 	PrintErrorDir
	
	call 	EraseSpaces
	call 	SaveFolderPreview
	jmp 	RetCd
BackSegment:
	pop 	ax
	mov 	word[CD_SEGMENT], 0x07C0
	call 	EraseSpaces
	call 	SaveFolderPreview
	jmp 	RetCd

VerifyArg:
	cmp 	word[si], ".."
	je 		NoFoundError1
AddSegment:
	mov		ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0200
	push 	ax
	add 	ax, 0x500
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	pop 	ax
	call 	FAT16.LoadThisFile
	cmp 	byte[ErrorDir], 0
	jnz 	PrintErrorDir
	cmp 	cx, 0
	jz 		NoFoundError1
	
	call 	EraseSpaces
	call 	SaveFolderNext
	
	; ====================================
	; analyse
	
	mov cx, 0x000B
	NextDir:
		inc 	si
		cmp 	byte[si], 0
		je 		RetCd
		loop 	NextDir
		
		dec 	byte[QuantDirs]
		
		jmp 	Cmd.CD
		
	; end analyse
	; ====================================
		;jmp 	RetCd
	
	NoFoundError1:
		push 	si
		mov 	si, MsgDirError1
		call 	Print_String
		pop 	si
		call 	EraseSpaces
		call 	Print_String
		mov 	si, MsgFileError2
		call 	Print_String
		jmp 	RetCd
	PrintErrorDir:
		push 	si
		mov 	si, MsgFileError1
		call 	Print_String
		pop 	si
		call 	EraseSpaces
		call 	Print_String
		mov 	si, ErrIsNotDir1
		call 	Print_String
RetCd:
	inc 	byte[CursorRaw]
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
ret

SaveFolderNext:
	pusha
	mov 	di, FolderAccess
	add 	di, word[CounterAccess]
	cmp 	byte[Quant], 0
	ja  	IncAccess
	inc 	byte[Quant]
	jmp 	SaveFolder
IncAccess:
	inc 	word[CounterAccess]
	add 	di, 1
	inc 	byte[Quant]
SaveFolder:
	mov 	al, [si]
	mov 	[di], al
	inc 	di
	inc 	si
	inc 	word[CounterAccess]
	cmp 	byte[si], 0
	jnz 	SaveFolder
	mov 	al, '\'
	mov 	[di], al
	add 	word[CD_SEGMENT], 0x500
	popa
ret
	
SaveFolderPreview:
	pusha
	mov 	di, FolderAccess
	add 	di, word[CounterAccess]
EraseFolder:
	mov 	al, 0
	mov 	[di], al
	dec 	di
	dec 	word[CounterAccess]
	cmp 	byte[di], '\'
	jne 	EraseFolder
	mov 	al, '\'
	mov 	[di], al
	;dec 	word[CounterAccess]
	cmp 	word[CD_SEGMENT], 0x07C0
	je 		BackSegment1
	sub 	word[CD_SEGMENT], 0x500
	jmp 	RetPreview
BackSegment1:
	mov 	word[CD_SEGMENT], 0x07C0
RetPreview:
	popa
ret	

Cmd.ASSIGN:
	inc 	si
	
	mov 	al, [si]
	mov 	byte[LetterDisk], al
	inc 	byte[CursorRaw]
ret

Cmd.DISK:
	pusha
_MainDisk:
	mov 	di, 0x0005
	mov 	si, SizeBuffer
	_ReadLoop:
		mov 	ah, 0x48
		mov 	dl, 0x80
		int 	0x13
		jnc 	 _ReadSuccess 
	_TryAgain:
		xor 	 ax, ax        
		int 	 0x13            
		dec 	 di          
    
	
		jnz 	 _ReadLoop  
		jmp 	_ReadError
		
	_ReadSuccess:
		mov 	ah, 0x08
		mov 	dl, 0x80
		int 	0x13
		jc 		_TryAgain
		
		mov 	si, ReadMsgSuccess
		call 	Print_String
		
		inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.NumberOfHeads
		call 	Print_String
		;mov 	ax, word[NumberHeads+2]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[NumberHeads]
		;call 	Print_Hexa_Value16
		mov 	al, dh
		call	Print_Hexa_Value8
		
		inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.NumberOfCylinders
		call 	Print_String
		;mov 	ax, word[NumberCylinders+2]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[NumberCylinders]
		;call 	Print_Hexa_Value16
		mov 	al, ch
		call	Print_Hexa_Value8
		
		inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.SectorsPerTracks
		call 	Print_String
		;mov 	ax, word[SectorsPerTrack+2]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[SectorsPerTrack]
		;call 	Print_Hexa_Value16
		mov 	al, cl
		call	Print_Hexa_Value8
		
		inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.NumberOfSectors
		call 	Print_String
		mov 	ax, word[AbsoluteSectors+6]
		call 	Print_Hexa_Value16
		mov 	ax, word[AbsoluteSectors+4]
		call 	Print_Hexa_Value16
		mov 	ax, word[AbsoluteSectors+2]
		call 	Print_Hexa_Value16
		mov 	ax, word[AbsoluteSectors]
		call 	Print_Hexa_Value16
		
		inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		jmp 	RetDiskReader
	_ReadError:
		mov 	si, ReadMsgError
		call 	Print_String
	
RetDiskReader:
	inc 	byte[CursorRaw]
	popa
ret


Cmd.HELP:
	mov 	ax, 0x0C00
	mov 	es, ax
	mov 	di, Inf
	mov 	si, Vector.CMD_Names
	mov 	cx, COUNT_COMMANDS
	push 	di
ShowInConsole:
	inc 	byte[CursorRaw]
	call	Cursor.CheckToRollEditor
	call 	Print_String
	mov 	ah, 0Eh
	mov 	al, ' '
	int 	10h
	mov 	al, '-'
	int 	10h
	mov 	al, ' '
	int 	10h
	
	pop 	di
	push 	cx
	xor 	dx, dx
	xor 	cx, cx
	mov  	cl, [di] 
	mov 	ax, 11
	mul 	cx
	add 	ax, cx
	mov 	cx, ax
	inc 	di
	
	call 	PrintData
	add 	di, cx
	
	pop 	cx
	push 	di
	
	mov 	al, 0
	call 	NextInfo
	loop 	ShowInConsole
	
	pop 	di
	inc 	byte[CursorRaw]
ret
		
NameSystem     db "KiddieOS Shell v1.2.2",0
LetterDisk     db "K:",0
SimbolCommands db ">",0
CommandsStr    db "Commands",0
InfoStr        db "Information",0
helptext1      db "KEY Commands -> ESC : Goto Commands/Editor  |  UP/DOWN : Select Command |",0
helptext2      db "ENTER : Choose Command  |  F1, F2, F3, F4, F5, F6 : Update Layouts",0
MsgFileError1  db "The file '",0
MsgFileError2  db "' wasn't found!",0
MsgDirError1   db "The directory '",0

ErrIsNotFile1  db "' is not a file!",0
ErrIsNotDir1   db "' is not a folder!",0  
EnabledMsg     db "Hexa displayer was enabled!",0
DisabledMsg     db "Hexa displayer was disabled!",0
ReadMsgSuccess  db "Disk was read successfully!",0
ReadMsgError    db "Disk found a problem! sorry me!",0

ErrorFound:     
	db "Sorry! Command not Found... "
    db "The name '"
	.LenghtError0 dw ($-ErrorFound)
ErrorProg:
	db "' is not an internal or external command or operable program."
	.LenghtError1 dw ($-ErrorProg)
ReturnByte 	db 0
StartTime   dd 0

VetorHexa  db "0123456789ABCDEF",0
VetorCharsLower db "abcdefghijklmnopqrstuvwxyz",0
VetorCharsUpper db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0

BPB_Informations:
	Str_Buffername 	      db "BUFFER_NAME         : MSDOS5.0",0
	Str_BytesPerSector    db "BYTES_PER_SECTOR    : 0x",0
	Str_SectorsPerCluster db "SECTORS_PER_CLUSTER : 0x",0
	Str_ReservedSectors   db "RESERVED_SECTORS    : 0x",0
	Str_TotalFats         db "TOTAL_FATS          : 0x",0
	Str_MaxRootEntries    db "MAX_ROOT_ENTRIES    : 0x",0
	Str_TotalSectorsSmall db "TOTAL_SECTORS_SMALL : 0x",0
	Str_MediaDescriptor   db "MEDIA_DESCRIPTOR    : 0x",0
	Str_SectorsPerFat 	  db "SECTORS_PER_FAT     : 0x",0
	Str_SectorsPerTrack   db "SECTORS_PER_TRACK   : 0x",0
	Str_NumberHeads       db "NUMBER_OF_HEADS     : 0x",0
	Str_HiddenSectors     db "HIDDEN_SECTORS      : 0x",0
	Str_TotalSectorsLarge db "TOTAL_SECTORS_LARGE : 0x",0
	Str_VolumeID          db "VOLUME_ID           : 0x",0
	Str_DriveNumber       db "DRIVE_NUMBER        : 0x",0
	Str_Flags             db "FLAGS               : 0x",0
	Str_Signature         db "SIGNATURE           : 0x",0
	Str_VolumeLabel       db "VOLUME_LABEL        : ",0
	Str_SystemID          db "SYSTEM_ID           : ",0
BPB_Index: 
	db 11,13,14,16,17,19,21,22,24,26,30,33,41,36,37,38

MetaData:
	 db "NAME FILE   | ATTRIB    | DATE/TIME | SIZE   | CLUSTER",0
.Dir db " directory  ",0
.Arc db "archive    ",0
.Fol db " folder     ",0
.Vol db " volume ID  ",0
.Oth db " other      ",0
	
DiskParameter:
	.NumberOfCylinders   db "Number of Cylinders : 0x",0
	.NumberOfHeads       db "Number Of Heads     : 0x",0
	.SectorsPerTracks    db "Sectors Per Track   : 0x",0
	.NumberOfSectors     db "Number Of Sectors   : 0x",0
	

ProgExtension  db "KXE", "EXE",0   ; Adicionar .APP
ProgTerminate1: db "Process exited after 0x"
.SizeTerm1      dw ($-ProgTerminate1)
ProgTerminate2: db " milliseconds with return value 0x"
.SizeTerm2      dw ($-ProgTerminate2)
	
COUNT_COMMANDS    EQU 13  ; <- A cada comando alterar

Vector:

.CMD_Names:
	db "exit"  ,0,   "reboot"  ,0,  "start"   ,0,  "bpb"    ,0,  "lf"  ,0 
	db "clean" ,0,   "read "   ,0,  "cd "     ,0,  "assign ",0, "help" ,0
	db "fat"   ,0,   "hex"     ,0,  "disk"    ,0,
	
.CMD_Funcs:
	dw Cmd.EXIT, Cmd.REBOOT, Cmd.START, Cmd.BPB, Cmd.LF, Cmd.CLEAN, Cmd.READ
	dw Cmd.CD, Cmd.ASSIGN, Cmd.HELP,  Cmd.FAT, Cmd.HEX, Cmd.DISK
	
.CMD_Infos:
	dw Inf.EXIT, Inf.REBOOT, Inf.START, Inf.BPB, Inf.LF, Inf.CLEAN, Inf.READ
    dw Inf.CD, Inf.ASSIGN, Inf.HELP, Inf.FAT, Inf.HEX, Inf.DISK
	
	
	
Inf:
   
.EXIT:
	db 5,"Exits the",0,"shell and",0,"returns to",0,"the kernel",0,"home menu.",0,0,0,0,0,0,0,0
.REBOOT:
	db 2,"Reboot the",0,"system.",0,0,0,0,0,0
.START:
	db 3,"Start",0,"the window",0,"manager.",0,0,0,0,0,0,0,0,0,0,0
.BPB:
	db 4,"Displays",0,"the boot",0,"record BPB",0,"Structure.",0,0,0,0,0,0,0,0,0
.LF:
	db 4,"Displays",0,"files from",0,"the root",0,"directory.",0,0,0,0,0,0,0,0,0
.CLEAN:
	db 3,"Clear the",0,"editor",0,"Screen.",0,0,0,0,0,0,0,0,0,0,0,0
.READ:
	db 8,"Read data",0,"files and",0,"print in",0,"the screen.",0,"Require 1 ",0,"parameter ;",0,"Ex.: Read",0,"File.txt",0,0,0,0,0,0,0,0,0,0,0,0,0,0
.CD:
	db 7,"Access the",0,"folders",0,"directory.",0,"Require 1",0,"parameter ;",0,"Ex.: cd",0,"Folder",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.ASSIGN:
	db 7,"Assign a",0,"letter to",0,"the unity.",0,"Require 1",0,"parameter ;",0,"Ex.: assign",0,"D",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.HELP:
	db 4,"show this",0,"commands",0,"infos and",0,"params.",0,0,0,0,0,0,0,0,0,0,0,0
.FAT:	
	db 4,"Display the",0,"File Alloca",0,"tion Table ",0,"Memory.",0,0,0,0,0
.HEX:
	db 5,"Enable or",0,"Disable",0,"hexadecimal",0,"values Dis",0,"player.",0,0,0,0,0,0,0,0,0,0,0,0
.DISK:
	db 2,"Disk Geomet",0,"ry Reader.",0,0

