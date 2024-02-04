%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
%INCLUDE "Hardware/info.lib"
[BITS SYSTEM]
[ORG SHELL16]

; Pending Fixes:
; 1. Run Zero_Buffer after finish a command! (In case of Strings is below the preview)
;		1.1. Examples: DATA    KXEa -b -c, or DATA    KXEe -a -b -c on SI register, because
;		we should skip till the zero to find/insert "KXE" extension.
;		1.2. Examples: type before "cd kiddieos\programs\sources" and type later "cd KiddieOS",
;		The first String is great than second String, it will have "trash" after 'S', e.g.: "\programs..
; 	1.3. Solved!
; 2. Break line on Command Line interface when to pass on the limitCursorFinalX, when the command
;    pass the limit size CLI.
; 	2.1. Solved!
; 3. Fix the folder RAW readings with READ command when is inserted 'K:' in begin (Unknown bug yet)
; 	3.1. Solved!
; 4. New Bug Error => Data dirs replacement on the dirs returns in a same address.
;   4.1. Half Solved! Need to free allocation!
; 5. Change Address Addictions/Subtractions on Dirs Loading to below number, e.g.: 0x400 => 0x40
; 	5.1. Solved!

;; CD_SEGMENT = 0x1edc = 0x0A00
	; erro bug => em 0xA00 os dados são substituídos quando entramos
	; numa mesma hierarquia retornando diretórios em disco, Exemplos:
	; Se está em kiddieos\users\, 0xA00 = dados de 'users', mas se
	; lemos dados em kiddieos\programs\, 0xA00 = dados de 'programs'.
	; Se desempilharmos CD_SEGMENT, ainda teremos dados de programs.
; OBS.: ESTE BUG JÁ FOI CORRIGIDO, PORÉM NA 2ª VEZ QUE É EXECUTADO, O VIRTUALBOX SE REINICIA!
;		Erro de Reiniciação Resolvido temporariamente! Motivo: A rotina _Free tem algum problema! 


; Done fixes:
; 1. The BufferKeys is no more used! We have zeroed the BufferKeys in programs args and backspaces.
; 2. Bug fixes of the lower case letter disk and Uppercase commands. 
;    Now, the user can type in lower/uppercase, drive letter and commands. Following the news formats.
; 3. Folder RAW readings bug solved! we have a new condition on fat16 when is loading file to check
; 	 if is file attribute 0x10 (Directory).
; 4. Break line on command line interface solved! at SaveChar SubRoutine and the CheckBackSpace SubRoutine,
; 	 We have verifications of the cursor limit in positions Begin X, Final X, Begin Y and Final Y.
; 5. Other bugs fixes was worked, such as:
;	 5.1. Insert DS in ES not in 'SaveChar' no more, but before of Shell_Editor.
; 	 5.2. We had some problems with commands processing on left panel but it´s solved now.
; 	 5.3. No more conflits between Error processing Calls in file/dir reading commands.
; 	 	5.3.1. Function separation of the error processing and paths loading.
; 6. Bugs of crashing in running file errors solved!
;	 6.1. Reset the variables Browsing_files, error_files, etc... after finish Load_File_Path, similar to READ command.
;	 7.2. Remove the pushes and popes of the CD_SEGMENT and Store/Restore dirs of Load_File_Path routines,
;	  	  Because we inserts this instructions inside to new routines! (Exec.SearchToFileExec, CMD.READ, etc...)
;	 8.3. Exec.SearchToFileExec run now directory browsing before to run programs!

jmp 	Os_Shell_Setup	; SHELL16+0
jmp 	Os_Inter_Shell	; SHELL16+3

jmp 	Format_Command_Line	; SHELL16+6
jmp 	PrintData			; SHELL16+9
jmp 	Copy_Buffers		; SHELL16+12
jmp 	Load_File_Path 		; SHELL16+15
jmp 	Store_Dir 			; SHELL16+18
jmp 	Restore_Dir 		; SHELL16+21

Shell.CounterFName db 0		; SHELL16+24
ErrorDir           db 0		; SHELL16+25
ErrorFile          db 0		; SHELL16+26
IsCommand 		   db 0		; SHELL16+27

CD_SEGMENT         dw 0x0200	; SHELL16+28

; -- VALORES DE PROGRAMAS MZ EM EXECUÇÃO -----------------
DOS_HEADER_BYTES   dw 0x0000	; SHELL16+30

; --------------------------------------------------------

BufferAux 		   times 120 db 0	;SHELL16+32
BufferAux2 		   times 120 db 0	;SHELL16+152
BufferArgs         times 120 db 0	;SHELL16+272
BufferKeys 	       times 120 db 0	;SHELL16+392

CursorRaw          db 0	;5 			SHELL16+512
CursorCol          db 0	;12			SHELL16+513

DOS_EXTRA_BYTES 	dw 0x0000

%DEFINE FAT16.LoadDirectory (FAT16+3)
%DEFINE FAT16.LoadFAT       (FAT16+6)
%DEFINE FAT16.LoadThisFile  (FAT16+9)
%DEFINE FAT16.WriteThisFile (FAT16+12)
%DEFINE FAT16.WriteThisEntry (FAT16+18)
%DEFINE FAT16.DeleteThisFile (FAT16+21)
%DEFINE FAT16.OpenThisFile 	 (FAT16+24)
%DEFINE FAT16.LoadFile 		 (FAT16+27)
%DEFINE FAT16.SetSeek 		 (FAT16+30)
%DEFINE FAT16.CloseFile 	 (FAT16+33)


FAT16.FileSegments    EQU   (FAT16+36)
FAT16.DirSegments 	  EQU   (FAT16+38)
FAT16.LoadingDir      EQU   (FAT16+40)

%DEFINE A3_TONE  1355
%DEFINE F3_TONE  1715
%DEFINE B3_TONE  1207


IsFile             db 0
IsHexa             db 0

WriteEnable  db 1
ArgFile 	 db 0
ArgData 	 db 0
ArgHidd		 db 0
WriteCounter dw 0


InitB 			   dd 0x0D0D0D0D
BufferWrite 	   times 100 db 0
FolderAccess:
	db '\'
	times 150 db 0
AddressArgs 	times 20 dd 0
CounterAccess      dw 0x0001
CmdCounter 	       db 0
ExtCounter         db 0
Quant              db 0
LimitCursorBeginX  db 0
LimitCursorBeginY  db 0
LimitCursorFinalX  db 68
LimitCursorFinalY  db 22
CursorRaw_Out      db 0
CursorCol_Out      db 0
LimitCursorBeginX_Out  db 0
LimitCursorFinalY_Out  db 22
QuantDirs          db 0
CounterChars  db 0
CounterChars1 db 0
CounterList   db 0
Selection db 0
CmdWrite  db 0
SaveAddressString dw 0x0000
SavePositionLeft  dw 0x0000
SavePositionRight dw 0x0000
Background_Color  db 0010_1111b		;0001_1111b
Borderpanel_Color db 0010_1111b		;0010_1111b
Backeditor_Color  db 0000_0010b 	;0000_1111b
Backpanel_Color   db 0000_1111b		;0111_0000b

PointerBuffer     dd 0x00000000
SavePointerArgs   dw 0x0000

OffsetNextFile    dw 0x0000

Out_Of_Shell 	  db 0


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
	cmp 	ax, 0x4C02
	jz 		Back_Blue_Screen
	mov 	byte[CursorRaw], 5
	mov 	byte[CursorCol], 12
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
		mov 	cx, 18  ;COUNT_COMMANDS
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
		mov 	byte[CursorRaw], 5
		dec 	byte[CursorRaw]
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
		mov 	byte[LimitCursorBeginY], dh
		call 	AssignDriveLetter
		
		mov 	al, byte[WriteEnable]
		cmp 	al, 0
		je 		NoPrintAccess
		mov     si, LetterDisk
		call    Print_String
		mov 	si, FolderAccess
		call 	Print_String
		mov     si, SimbolCommands
		call    Print_String
		jmp 	SetCursorShape
		
	NoPrintAccess:
		mov 	byte[LimitCursorBeginX], 12
	SetCursorShape:
		; Set Cursor Shape Full-Block
		call 	Show_Cursor
		call 	VerifyToWrite
		
		push 	ds
		pop 	es
		
		cmp 	byte[CmdWrite], 1
		jne 	Shell_Editor2
	
Shell_Editor:
	mov 	byte[CmdWrite], 0
	mov 	di, BufferKeys
	mov 	cx, 120
	call 	Zero_Buffer
	mov 	di, BufferArgs
	mov 	si, Vector.CMD_Names
	push 	di
	mov 	di, word[SavePointerArgs]
	jmp 	Start
  Shell_Editor2:
	mov 	di, BufferKeys
	mov 	cx, 120
	call 	Zero_Buffer
	mov 	di, BufferArgs
	mov 	cx, 120
	call 	Zero_Buffer
	mov 	word[SavePointerArgs], di
	mov 	si, Vector.CMD_Names
	push 	di
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
	SaveChar:
		call 	Get_Cursor
		push 	PrintChar
		cmp 	dl, byte[LimitCursorFinalX]
		je		Cursor.CheckToRollEditor
		pop 	cx
	PrintChar:
		mov 	ah, 0Eh
		int 	10h
		push 	di
		mov 	di, word[SavePointerArgs]
		stosb
		mov 	word[SavePointerArgs], di
		pop 	di
		jmp 	Start
			
	CheckBackspace:
		call 	Get_Cursor
		cmp 	dh, byte[LimitCursorBeginY]
		jna 	CheckLimitCLIX
		push 	SkipCheckLimit
		cmp 	dl, 12
		je		BackCursorToCLI
		pop 	bx
		jmp 	SkipCheckLimit
	CheckLimitCLIX:
		cmp 	dl, byte[LimitCursorBeginX]
		je		Start
	SkipCheckLimit:
		push 	di
		mov 	di, word[SavePointerArgs]
		dec 	di
		mov 	word[SavePointerArgs], di
		mov 	al, 0x08
		int 	10h
		mov 	al, 0
		mov 	[di], al
		int 	10h
		mov 	al, 0x08
		int 	10h
		pop 	di
		jmp 	Start
	RollEditorToUp:
		mov 	ah, 06h
		call 	RollingEditor
		jmp 	Start
	RollEditorToDown:
		mov 	ah, 07h
		call 	RollingEditor
		jmp 	Start
	BackCursorToCLI:
		push 	dx
		call 	Get_Cursor
		dec 	dh
		mov 	byte[CursorRaw], dh
		mov 	dl, byte[LimitCursorFinalX]
		call 	Move_Cursor
		pop 	dx
		ret
		
Copy_Buffers:
	push 	di
	push 	si
	Copy_Data:
		movsb
		cmp 	byte[si],0
		jne 	Copy_Data
	pop 	si
	pop 	di
ret

AssignDriveLetter:
	push 	si
	push 	es
	push 	ds
	pop 	es
	push 	ds
	mov 	ax, 0x200
	mov 	ds, ax
	mov 	si, 0x20
	mov 	di, LetterDisk
	movsb
	pop 	ds
	pop 	es
	pop 	si
ret

ConvCommandToLower:
	push 	si
	push 	di
	mov 	si, di
	mov 	cl, byte[LetterDisk]
	add 	cl, 0x20
	StartConv:
		lodsb
		xor 	bx, bx
		cmp 	al, byte[LetterDisk]
		sete 	bh
		cmp 	al, cl
		sete 	bh
		cmp 	byte[si], ':'
		sete 	bl
		cmp 	bx, 0x101
		je 		Skip2Dots
		call 	ToLowerCase
		stosb
		jmp 	CheckEndCmd
	Skip2Dots:
		inc 	si
		call 	ToUpperCase
		stosb
		inc 	di
		jmp 	StartConv
	CheckEndCmd:
		cmp 	al, 0
		je 		RetConv
		cmp 	al, 0x20
		jne 	StartConv
RetConv:
	pop 	di
	pop 	si
ret
	
Os_Inter_Shell:
	push 	es
	push 	ds
	mov 	ax, 0x3000
	mov 	es, ax
	cmp 	byte[es:si], 0
	jz 		Error_Zero
	mov 	byte[es:Out_Of_Shell], 1
	call 	AssignDriveLetter
	mov 	di, BufferArgs
	mov 	cx, 120
	call 	Zero_Buffer
	call 	Copy_Buffers
	push 	di
	mov 	si, Vector.CMD_Names
	mov 	ax, es
	mov 	ds, ax
	jmp 	Os_Inter_Shell1
Shell_Interpreter:
	;add 	byte[CursorRaw], 1
	call	Cursor.CheckToRollEditor
	Os_Inter_Shell1:
		mov 	cx, COUNT_COMMANDS   				; ler até 2 comandos
		mov 	byte[CmdCounter], 0
		pop 	di
		cmp 	byte[es:di], 0
		jz 		Cursor_Commands
		push	si
		push 	di
		call 	ConvCommandToLower
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
		mov 	byte[IsCommand], 1
		call 	bx
		mov 	byte[IsFile], 0
		mov 	byte[IsCommand], 0
		mov 	ax, 0
		cmp 	byte[Out_Of_Shell], 1
		je 		Ret_OutOfShell
		jmp 	Cursor_Commands
	No_Return_Jump:
		mov 	cx, 120
		call 	Zero_Buffer
		mov 	byte[CmdCounter], 0
		mov 	byte[CounterList], 0
		mov 	byte[Selection], 0
		mov 	byte[CursorRaw], 5
		xor 	ax, ax
		xor 	cx, cx
		xor 	dx, dx
		jmp 	bx
	NoFounded:
		pop 	si
		pop 	di
		mov 	byte[IsCommand], 0
		call 	Exec.SearchFileToExec     ; Tentar encontrar programa operável
		cmp 	byte[Out_Of_Shell], 1
		je 		Ret_OutOfShell0
		cmp 	ax, 0x4C02
		jz 		Os_Shell_Setup
		jmp 	Cursor_Commands
	Ret_OutOfShell0:
		call 	Cursor.CheckToRollEditor
		mov 	ax, 0
	Ret_OutOfShell:
		mov 	byte[Out_Of_Shell], 0
		pop 	ds
		pop 	es
	ret
	Error_Zero:
		mov 	ax, 0xFF
		jmp 	Ret_OutOfShell
			
		
		
List_Commands:
	call 	Hide_Cursor
	mov 	cx, word[SavePositionLeft]
	mov 	byte[CounterList], 0
	mov 	byte[LimitPanel], 0
	mov 	byte[SaveCountBelow], 0
	mov 	byte[SaveCountAbove], 0
	mov 	byte[Selection], ch
	mov 	dx, word[SavePositionLeft]
	call	Focus_Select
	call 	Show_Information
	WriteOp:
		push 	cx
		mov 	dx, word[SavePositionLeft]
		mov 	cx, 18 ;COUNT_COMMANDS
		mov 	si, Vector.CMD_Addrs
		xor 	ax, ax
		mov 	al, byte[LimitPanel]
		shl 	al, 1
		add 	si, ax
		mov 	si, [si]
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
		mov 	byte[LimitPanel], 0
		mov 	byte[SaveCountBelow], 0
		mov 	byte[SaveCountAbove], 0
		push 	cx
		push 	dx
		mov     bh, [Backpanel_Color]      
		mov     cx, 0x0500         ; CH = 5, CL = 0                          
		mov     dx, 0x160A         ; DH = 22, DL = 10
		call    Create_Panel
		pop 	dx
		pop 	cx
		call 	Erase_Select
		sub		ch, 17  ;COUNT_COMMANDS-1
		call	Focus_Select
		call 	Show_Information
		jmp 	WriteOp
		IncNow:
			inc 	byte[CounterList]
			cmp 	byte[CounterList], 18
			jb		SelectOpInc
			mov 	al, [CounterList]
			cmp 	byte[SaveCountBelow], al
			jae 	SelectOpInc
			
			mov 	[SaveCountBelow], al
			inc 	byte[LimitPanel]
			call 	Erase_Select
			call 	RollPanelToUp
			call	Focus_Select
			call 	Show_Information
			jmp 	WriteOp
			
		SelectOpInc:
			call 	Erase_Select
			inc 	ch
			call	Focus_Select
			call 	Show_Information
			jmp 	WriteOp
	DecSelection:
		cmp		byte[CounterList], 0
		jne		DecNow
		mov 	byte[CounterList], COUNT_COMMANDS-1
		mov 	byte[LimitPanel], COUNT_COMMANDS-18
		mov 	byte[SaveCountBelow], COUNT_COMMANDS-1
		mov 	byte[SaveCountAbove], 0
		push 	cx
		push 	dx
		mov     bh, [Backpanel_Color]      
		mov     cx, 0x0500         ; CH = 5, CL = 0                          
		mov     dx, 0x160A         ; DH = 22, DL = 10
		call    Create_Panel
		pop 	dx
		pop 	cx
		call 	Erase_Select
		add		ch, 17 ;COUNT_COMMANDS-1
		call	Focus_Select
		call 	Show_Information
		jmp 	WriteOp
		DecNow:
			dec 	byte[CounterList]
			mov 	al, byte[LimitPanel]
			sub 	al, 1
			cmp 	byte[CounterList], al  ;2
			ja		SelectOpDec
			cmp 	byte[LimitPanel], 0
			je 		SelectOpDec
			mov 	al, [CounterList]
			cmp 	byte[SaveCountAbove], al
			je	 	SelectOpDec
			
			mov 	[SaveCountAbove], al
		
			dec 	byte[LimitPanel]
			call 	Erase_Select
			call 	RollPanelToDown
			call	Focus_Select
			call 	Show_Information
			jmp 	WriteOp
			
		SelectOpDec:
			call 	Erase_Select
			dec 	ch
			call	Focus_Select
			call 	Show_Information
			jmp 	WriteOp
	UnSelectExit:
		call 	Erase_Select
		mov     bh, [Backpanel_Color]      
		mov     cx, 0x0500         ; CH = 5, CL = 0                          
		mov     dx, 0x160A         ; DH = 22, DL = 10
		call    Create_Panel
		mov 	dx, word[SavePositionLeft]
		mov 	cx, 18 ;COUNT_COMMANDS
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
		mov 	di, BufferArgs
		mov 	cx, 120
		call 	Zero_Buffer
		mov 	si, Vector.CMD_Names
		xor 	cx, cx
		mov 	cl, byte[CounterList]
		cmp 	cl, 0
		jz 		JumpFinder
		FindCommand:
			push 	ax
			mov 	al, 0
			call 	NextInfoSI
			pop 	ax
			loop 	FindCommand
		JumpFinder:
			mov 	word[SaveAddressString], si
			cld
		SaveCommand:
			movsb
			cmp 	byte[si], 0
			jnz 	SaveCommand
			mov 	word[SavePointerArgs], di
			
			mov 	ax, B3_TONE
			call 	Play_Sound
			
			jmp 	UnSelectExit
			
	VerifyToWrite:
		cmp 	byte[CmdWrite], 1
		jne 	RetWrite
		mov 	si, word[SaveAddressString]
		call 	Print_String
	RetWrite:
		ret
			
	LimitPanel db 0
	SaveCountBelow db 0
	SaveCountAbove db 0
	
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
	Zero:
		mov 	byte[di],0
		inc 	di
		loop 	Zero
	popa
ret


PrintData:
	pusha
	mov 	[ascii_dolar], al
	mov 	ah, 0x0E
	dec 	byte[LimitCursorFinalY]
	xor		bl, bl
Display:
	mov 	al, byte[es:di]
	cmp 	byte[ascii_dolar], 1
	jne 	JumpCheckDolar
	cmp 	al, '$'
	je 		DONE
JumpCheckDolar:
	cmp 	byte[IsHexa], 1
	je      DisplayHex
DisplayText:
	cmp		al, 0x0D
	je 		IsEnter
	cmp 	al, 0x0A
	je 		IsEnter2
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
	ja 		IsEnter2
	inc 	di
	jmp 	Continue
	IsEnter:
		call 	PutZeroTextMemory
		mov 	dh, byte[CursorRaw]
		mov 	dl, byte[CursorCol]
		call 	Move_Cursor
		inc 	di
		jmp 	Continue
	IsEnter2:
		;call 	PutZeroTextMemory			; verificar se precisa
		inc 	bl
		cmp 	bl, 17
		jne 	LineBreak
		call 	Wait_Key
		xor 	bl, bl
		LineBreak:
			call 	Cursor.CheckToRollEditor
			inc 	di
	Continue:
		cmp 	byte[ascii_dolar], 1
		je 		Display
		loop 	Display
DONE:
	inc 	byte[LimitCursorFinalY]
	mov 	byte[ascii_dolar], 0
	popa
RET
ascii_dolar db 0

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
			;inc 	byte[CursorRaw]
			call 	Cursor.CheckToRollEditor
			add 	di, 2
	Continue1:
		loop 	Display1
DONE1:
	inc 	byte[LimitCursorFinalY]
	popa
RET

Cursor.CheckToRollEditor:
	cmp 	byte[Out_Of_Shell], 1
	je 		Execute_Out
	pusha
	inc 	byte[CursorRaw]
	mov 	dh, byte[CursorRaw]
	cmp 	dh, byte[LimitCursorFinalY]
	ja   	RollEditor
	mov 	dl, byte[CursorCol]
	call 	Move_Cursor
	jmp 	RetCheck
RollEditor:
	mov 	ah, 06h
	call 	RollingEditor
	dec 	byte[LimitCursorBeginY]
	mov 	dh, byte[LimitCursorFinalY]
	mov 	byte[CursorRaw], dh
	mov 	dl, byte[CursorCol]
	call 	Move_Cursor
RetCheck:
	popa
	mov 	dl, byte[CursorCol]
	mov 	dh, byte[CursorRaw]
ret
Execute_Out:
	pusha
	call 	Get_Cursor
	mov 	byte[CursorRaw_Out], dh
	inc 	byte[CursorRaw_Out]
	mov 	dh, byte[CursorRaw_Out]
	cmp 	dh, byte[LimitCursorFinalY_Out]
	ja   	RollEditorOut
	mov 	dl, byte[CursorCol_Out]
	call 	Move_Cursor
	jmp 	RetCheck_Out
RollEditorOut:
	mov 	ah, 06h
	call 	RollingEditor_Out
	mov 	dh, byte[LimitCursorFinalY_Out]
	mov 	byte[CursorRaw_Out], dh
	mov 	dl, byte[CursorCol_Out]
	call 	Move_Cursor
RetCheck_Out:
	popa
	mov 	dl, byte[CursorCol_Out]
	mov 	dh, byte[CursorRaw_Out]
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

RollingEditor_Out:
	pusha
	mov 	al, 1
	mov     bh, [ds:Backeditor_Color] 
	mov     cx, 0x0000             
	mov     dx, 0x164F
	int 	10h
	popa
ret

RollPanelToUp:
	pusha
	mov 	ah, 06h
	mov 	al, 1
	mov 	bh, [ds:Backpanel_Color]
	mov     cx, 0x0500                         
	mov     dx, 0x160A
	int 	10h
	popa
ret

RollPanelToDown:
	pusha
	mov 	ah, 07h
	mov 	al, 1
	mov 	bh, [ds:Backpanel_Color]
	mov     cx, 0x0500                         
	mov     dx, 0x160A
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
	inc 	byte[QuantChars]
	inc 	si
	cmp 	byte[si], al
	jne 	NextInfo
	inc 	si
ret

NextInfoSI:
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
	pusha
	mov 	byte[QuantChars], 0
	call 	NextInfo
	dec 	si
	mov 	bl, byte[QuantChars]
	cmp 	bl, 10
	ja 		NotFill	
	mov 	cl, 11
	sub 	cl, bl
	xor 	ch, ch
	FillBuffer:
		mov 	byte[si], " "
		inc 	si
		loop 	FillBuffer
	NotFill:
		mov 	byte[si], al
		popa
ret
QuantChars db 0

EraseSpaces:
	pusha
	mov 	bl, byte[QuantChars]
	;dec 	bl
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
	popa
ret

CountExec db 0

; MZ EXECUTABLE HEADER OFFSETS
SIGNATURE		EQU 0x00
EXTRA_BYTES		EQU 0x02		; Byte baixo da quantidade de bytes do programa
PAGES			EQU 0x04		; Byte alto da quantidade de bytes do programa
RELOC_ITEMS		EQU 0x06
HEADER_SIZE		EQU 0x08
MIN_ALLOC 		EQU 0x0A
MAX_ALLOC		EQU 0x0C
INITIAL_SS		EQU 0x0E
INITIAL_SP		EQU 0x10
CHECKSUM		EQU 0x12
INITIAL_IP		EQU 0x14
INITIAL_CS		EQU 0x16
RELOC_TABLE 	EQU 0x18
OVERLAY			EQU 0x1A
OVERLAY_INF 	EQU 0x1C

SIZE_DATA_PROG 	dw 0x0000

Exec:

.SearchFileToExec:
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	; -- provisory -------------------
	push 	word[CD_SEGMENT]
	call 	Store_Dir
	; --------------------------------
	
	mov 	cx, 1 	   ; Status
	call 	Load_File_Path
	
	;inc 	byte[CountExec]
	
	push 	di				; Nome do arquivo na CLI não-formatado, Ex.: prog.exe
	
	;mov  	ax, word[CD_SEGMENT]
	mov 	ax, word[BROWSING_EX]
	mov 	es, ax
	xor 	di, di
	
	push 	si		; DS:SI = NOME DO ARQUIVO FORMATADO
	push 	di		; ES:DI = PRIMEIRA ENTRADA NO DIRETÓRIO
	
	
	TryFind:
		cmp 	byte[es:di + 11], 0x0F   ; LFN ATTRIB
		je 		TryNextFile
		
		pop 	di
		pop 	si
		push 	si
		push 	di
		
		mov 	cx, 8
		repe 	cmpsb
		jne 	TryNextFile
		
		cmp 	byte[si], 0x20
		je 		JumpCheck2
		
		; Segunda verificação pra ter absolutamente certeza
		; que a extensão é a mesma (Se não houver ext. esta etapa é ignorada)
		mov 	cx, 3
		repe 	cmpsb
		jne 	TryNextFile
			
	JumpCheck2:
		pop 	di
		pop 	si
		push 	si			; Nome formatado na CLI, Ex.: PROG    EXE
		push 	di			; Nome do arquivo encontrado na Entrada FAT, Ex.: PROG    EXE
		
			
		add 	di, 8
		mov 	si, ProgExtension
		mov 	cx, EXTENSIONS_COUNT
	FindExtension:
		push 	cx
		mov 	cx, 3
		repe 	cmpsb
		je 		ExtensionFound
		mov 	bx, 3
		sub 	bx, cx
		sub 	di, bx
		sub 	si, bx
		add 	si, 3
		pop 	cx
		loop 	FindExtension
		
	TryNextFile:
		pop 	di
		pop 	si
		add 	di, 32
		
		cmp 	byte[es:di], 0
		jz 		ShowErrorFound
		
		push 	si
		push 	di
		
		jmp 	TryFind
		
	ExtensionFound:
		pop 	cx
		sub 	si, 3
		;call 	Cursor.CheckToRollEditor
		
	ExtensionInsert:
		; SI aponta para a extensão encontrada
		; Conversão de argumento para nome de arquivo na entrada
		; EXEMPLO: PROG       => PROG    KXE | PROG    EXE
		; ======================================================
		mov 	bx, si    		; BX = Endereço da Extensão KXE,EXE,...
		pop 	di				; ENTRADA FAT
		pop 	si       		; NOME FORMATADO
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
		
		
	LoadProgInMemory:
		mov 	ax, 0x5000 ; segmento de processos 0x5000
		mov 	word[FAT16.FileSegments], ax
		mov 	ax, word[CD_SEGMENT]
		mov 	word[FAT16.DirSegments], ax
		mov 	byte[FAT16.LoadingDir], 0
		mov 	bx, 0x0000
		push 	di
		call 	FAT16.LoadThisFile
		pop 	di
		jnc 	Detect_MZ
		call 	CheckErrorFile
		
		pop 	di
		; -- provisory ------------------
		pop 	word[CD_SEGMENT]
		call 	Restore_Dir
		; -------------------------------
		jmp 	RetSFTE
		
	; ------------------------------------------------------------
	; TODO detectar executáveis MZ checando os primeiros 2 caracteres
	; do endereço carregado e efetuar o procedimento para execução
	; do programa MZ em modo real
	
	Detect_MZ:
		mov 	[SIZE_DATA_PROG], dx
		
		mov 	ax, 0x5000		; 0x5000
		mov 	es, ax
		
		cmp 	WORD[es:0x0], "MZ"
		jne 	Run_32BIT_Prog
		
		pop 	di
		
		; -- provisory ------------------
		pop 	word[CD_SEGMENT]
		call 	Restore_Dir
		; -------------------------------
		
		call 	Count_Ammount_Args		; RETURN: ECX, EDI
		
		push 	ds
		pop 	es
		push 	ecx
		push 	edi
		
		call 	Transfer_Args			; ENTRY: ESI
		
		pop 	esi
		pop 	ecx
		add 	esi, 0x30000
		
		; Carrega dados de 5000 para 4000 para programas DOS
		; 5000 -> Endereço para programas 32-bit
		; 4000 -> Endereço para programas 16-bit
		pusha
		push 	ds
		mov 	cx, [SIZE_DATA_PROG]
		mov 	ax, 0x5000
		mov 	ds, ax
		xor 	si, si
		mov 	ax, 0x4000
		mov 	es, ax
		xor 	di, di
		rep 	movsb
		pop 	ds
		popa
		
		call 	Exec_DOS
		jmp 	RetSFTE
		
	Exec_DOS:
		push 	ebp
		mov 	bp, ss
		shl 	ebp, 16
		mov 	bp, sp
		
		;	ENDEREÇO DE PILHA DO DOS SERÁ: 0x6xxxx -> Máximo STACK 8000H
		mov 	ax, 0x0006
		mov 	ss, ax
		mov 	ax, WORD [es:0 + INITIAL_SP]
		mov 	sp, ax
		push 	ebp
		
		xor 	dx, dx
		mov 	ax, 16
		mov 	bx, word[es:0x0 + HEADER_SIZE]
		mul 	bx
		mov 	bx, ax
		mov 	[DOS_HEADER_BYTES], ax
		
		mov 	ax, word[es:0x0 + EXTRA_BYTES]
		mov 	[DOS_EXTRA_BYTES], ax
		
		push 	ecx
		mov 	bx, word[es:0x0 + RELOC_TABLE]		; Valor Absoluto da tabela de realocação
		mov 	cx, WORD [es:0x0 + RELOC_ITEMS]		; Quantidade de entradas de realocação
		cmp 	cx, 0x0000
		jz 		no_realloc_table
		
		push 	di
		mov 	dx, es
		mov 	ax, [DOS_HEADER_BYTES]
		shr 	ax, 4
		add 	ax, dx
	addic_entry_offset:
		push 	bx
		mov 	di, word[es:0x0 + bx]		; OFFSET
		mov 	bx, [DOS_HEADER_BYTES]
		add 	word[es:di + bx], ax
		pop 	bx
		add 	bx, 4
		loop 	addic_entry_offset
		pop 	di
		
	no_realloc_table:
		pop 	ecx
		mov 	ax, 0x3000
		mov 	ds, ax
		
		push 	ds
		push 	esi			; EBP + 12
		push 	ecx			; EBP + 8
		
		mov 	ax, [DOS_HEADER_BYTES]
		shr 	ax, 4
		mov 	bx, es
		add 	ax, bx
		push 	ax		; ENDEREÇO 0x5002
		mov 	bx, word[es:0x0 + INITIAL_CS]
		shl 	bx, 4
		add 	bx, word[es:0x0 + INITIAL_IP]
		push	bx		; ENDEREÇO (CS << 4 + IP)
		mov 	bp, sp
		
		mov 	ax, es
		mov 	ds, ax
		
		call 	WORD FAR[bp]		; CHAMA 0x5002:(CS << 4 + IP)
		
		add 	sp, 12 		; 4 + 4 + 4 (CS:IP + ESI + ECX on STACK)
		pop 	ds
		
	clear_program:
		push 	ax
		xor 	di, di
		mov 	cx, [SIZE_DATA_PROG]
		xor 	ax, ax
		rep 	stosb
		pop 	ax
		
		pop 	ebp
		mov 	sp, bp
		shr 	ebp, 16
		mov 	ss, bp
		pop 	ebp
	ret
	
	Run_32BIT_Prog:
	; ----------------------------------------------------------
	; MANIPULANDO ARGUMENTOS DA CLI
		mov 	ax, 0x3000
		mov 	es, ax
		
		pop 	di
		
		; -- provisory ------------------
		pop 	word[CD_SEGMENT]
		call 	Restore_Dir
		; -------------------------------
		
		call 	Count_Ammount_Args		; RETURN: ECX, EDI
		
		push 	ds
		pop 	es
		push 	ecx
		push 	edi
		
		call 	Transfer_Args			; ENTRY: ESI
			
	; ----------------------------------------------------------	

	Load_Program:
		pop 	esi
		add 	esi, 0x30000
		pop 	ecx
		
		
		cmp 	byte[Out_Of_Shell], 1
		je 		Insert_Out
		mov 	dh, byte[CursorRaw]
		mov 	dl, byte[CursorCol]
		xor 	bx, bx	; Limpo se chamada de processos é dentro do Shell16
		jmp 	Call_Prog
	Insert_Out:
		call 	Get_Cursor
		mov 	byte[CursorRaw_Out], dh
		mov 	byte[CursorCol_Out], dl
		mov 	bl, 1 		; Definido se chamada de processos é fora do Shell16
		
	Call_Prog:
		call 	SYSCMNG     ; <- Chama o programa pelo gerenciador da SysCall
		
		mov 	dx, si
		
		cmp 	byte[Out_Of_Shell], 1
		je 		Restore_Out
		
		mov 	byte[CursorRaw], dh
		mov 	byte[CursorCol], dl
		jmp 	Skip_Restore
	Restore_Out:
		mov 	byte[CursorRaw_Out], dh
		mov 	byte[CursorCol_Out], dl
	Skip_Restore:	
		mov 	ax, word[SYSCMNG + 3]
		mov 	byte[ReturnByte], al
		
		call 	Move_Cursor
		jmp 	RetSFTE
			
ShowErrorFound:
	pop 	di	
	; -- provisory ------------------
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	; -------------------------------
	
	;call 	Cursor.CheckToRollEditor
		
	mov 	ax, ds
	mov 	es, ax
	mov 	al, 0
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
	mov 	al, 0
	mov 	di, ErrorProg
	mov 	cx, word[ErrorProg.LenghtError1]
	call 	PrintData
		
RetSFTE:
	;call 	Cursor.CheckToRollEditor
		
	push 	ds
	pop 	es
	ret
	
Count_Ammount_Args:
	int3
	xor 	esi, esi
	mov 	si, di  	; Recupera arquivo do BufferArgs
	RetentionSI:
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
		mov 	eax, AddressArgs
		mov 	edi, eax
		;mov 	ebx, 4
		;call 	Calloc
		;mov 	dword[PointerBuffer], eax
		;mov 	edi, dword[PointerBuffer]
Ret.CountAmountArgs:
	ret
	
Transfer_Args:
		int3
		mov 	eax, esi
		add 	eax, 0x30000	; 0xC000
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
		jmp 	Transfer_Args
	
	ReplaceSpaceToZero:
		mov 	si, BufferArgs
		ReplaceSpace:
			lodsb
			cmp 	al, 0
			je 		Ret.Transfer_Args
			cmp 	al, 0x20
			jne 	ReplaceSpace
			dec 	si
			mov 	byte[si], 0
			inc 	si
			jmp 	ReplaceSpace
Ret.Transfer_Args:
	ret
		

Cmd.EXIT   : jmp	Kernel_Menu
Cmd.REBOOT : jmp 	Reboot_System
Cmd.START  : jmp    Wmanager_Start
	
Cmd.BPB:
	mov 	ax, 0x0000
	mov 	es, ax
	mov 	di, 0x0600
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
	
	;call 	Wait_Key
	
	call	Cursor.CheckToRollEditor
	
	mov 	si, Str_VolumeLabel
	call	Print_String
	xor 	ax, ax
	add 	di, 43
	mov 	cx, 11
	call 	PrintData
	
	call	Cursor.CheckToRollEditor
	
	mov 	si, Str_SystemID
	call	Print_String
	xor 	ax, ax
	add 	di, 11
	mov 	cx, 8
	call 	PrintData
	
	;add 	byte[CursorRaw], 1
	;call	Cursor.CheckToRollEditor
ret

Cmd.LF:
	call 	Reload_Directory
	
	mov 	ax, word[CD_SEGMENT]
	mov 	es, ax
	mov 	di, 0x0000
	
	;inc 	byte[CursorRaw]
	call 	Cursor.CheckToRollEditor
	
	mov 	si, MetaData
	call	Print_String
	
	mov 	byte[Shell.CounterFName], 0
	
	ShowFiles:
		cmp 	byte[es:di + 11], 0x0F   ; LFN ATTRIB
		je 		NextFile
		cmp 	byte[es:di + 11], 0x02   ; HIDDEN
		je 		NextFile
		
		;inc 	byte[CursorRaw]
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
		cmp 	al, 0x04  ; SYSTEM ATTRIB
		je 		TypeSys
		cmp 	al, 0x01  ; READ-ONLY ATTRIB
		je 		TypeRon
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
		jmp 	CheckDateTime
	TypeSys:
		mov 	si, MetaData.Sys
		call 	Print_String
		jmp 	CheckDateTime
	TypeRon:
		mov 	si, MetaData.Ron
		call 	Print_String
		
	CheckDateTime:
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		mov 	ax, word[es:di + 16]
		;call	Print_Hexa_Value16
		call 	Print_Fat_Date
		
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		
		mov 	ax, word[es:di + 14]
		;call	Print_Hexa_Value16
		call 	Print_Fat_Time
		
	CheckSize:
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		mov 	al, ' '
		int 	10h
		mov 	eax, dword[es:di + 28]
		;push 	ax
		;shr 	eax, 16
		;call	Print_Hexa_Value16
		;pop 	ax
		;call 	Print_Hexa_Value16
		call 	Print_Dec_Value32
		
		mov 	ah, 0Eh
		mov 	al, ' '
		int 	10h
		mov 	al, ' '
		int 	10h
		
	CheckCluster:
		;mov 	ax, word[es:di + 26]
		;call 	Print_Hexa_Value16
		
	NextFile:
		add 	di, 32
	
		cmp 	byte[es:di], 0
		jz 		RetLF
	
		jmp 	ShowFiles
RetLF:
	;call 	Cursor.CheckToRollEditor
	;add 	byte[CursorRaw], 2    ;1
ret

ThisDirRoot db "KDS.VOLUME ",0
ThisDir 	db ".          ",0

Cmd.CLEAN:
	mov     bh, [Backeditor_Color]
	mov     cx, 0x050C         ; CH = 5, CL = 12              
	mov     dx, 0x1643         ; DH = 22, DL = 67          
	call    Create_Panel
	mov 	byte[CursorRaw], 4
ret


Cmd.READ:
	;call 	Reload_Directory
	
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	push 	word[CD_SEGMENT]
	call 	Store_Dir

	
	mov 	ax, 0x6800 ; segmento de arquivos
	mov 	bx, 0x0000 ; offset do arquivo
	mov 	cx, 0 	   ; Status
	call 	Load_File_Path
	jc 		RetRead
	
	ShowDataFile:
		mov 	word[OffsetNextFile], bx
		sub 	bx, 2
	
		mov 	cx, dx
		mov 	ax, 0x6800
		mov 	es, ax
		mov 	al, 0
		xor 	di, di
		call	PrintData
		
RetRead:
	clc
	; -- provisory ------------------
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	; -------------------------------
	;inc 	byte[CursorRaw]
	;call 	Cursor.CheckToRollEditor
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
ret
Browse_Count db 0

; Rotina para pesquisa e carregamento de diretórios e arquivos (Open)
; 	ENTRADAS => SI: Ponteiro para buffer onde contém o caminho de arquivo pré-formatado
; 			    AX: Segmento para carregamento dos dados
; 			    BX: Offset para carregamento dos dados
;				CX: 0 - Carrega o arquivo do caminho; 1 - Não carrega o arquivo
; 	SAÍDAS 	 => Carry: Definido quando há algum erro de leitura
Load_File_Path:
	;push 	word[CD_SEGMENT]
	push 	ax
	push 	bx
	push 	cx
	;call 	Store_Dir
	
	cmp 	byte[Dirs_Count], 0
	jz 		ProcessFile
	cmp 	byte[Flag_File], 0
	jz 		ProcessFile
	
	; Flag_File = 1
	; Tem exploração de diretórios e é um arquivo
	
Explore_Dirs:	
	cmp 	word[CD_SEGMENT], 0x0200
	je 		CheckIfDirPrev
	cmp 	word[si], ".."
	je 		Sub_Segment
	jmp 	Add_Segment
	
CheckIfDirPrev:
	cmp 	word[si], ".."
	jne 	Add_Segment
	mov 	al, 0x02
	call 	CheckErrorFile
	jmp 	Ret.ErrorPath
	
Add_Segment:
	mov		ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0000
	push 	ax
	add 	ax, 0x40
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	pop 	ax
	push 	di
	call 	FAT16.LoadThisFile
	pop 	di
	jnc 	Success_Add
	call 	CheckErrorFile
	jmp 	Ret.ErrorPath

Success_Add:
	add 	word[CD_SEGMENT], 0x40
	mov 	cx, 0x000B
	NextDirRead:
		inc 	si
		loop 	NextDirRead
	NextDirRead2:
		inc 	di
		cmp 	byte[di], '\'
		jne 	NextDirRead2
		inc 	di
		inc 	byte[Browse_Count]
		mov 	al, byte[Browse_Count]
		cmp 	byte[Dirs_Count], al
		je 		ProcessFile
		jmp 	Explore_Dirs
		
Sub_Segment:
	mov		ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0000
	push 	ax
	sub 	ax, 0x40
	cmp 	ax, 0x0200
	je 		Back_Segment
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	pop 	ax
	push 	di
	call 	FAT16.LoadThisFile
	pop 	di
	jnc 	Success_Sub
	call 	CheckErrorFile
	jmp 	Ret.ErrorPath

Success_Sub:
	sub 	word[CD_SEGMENT], 0x40
	mov 	cx, 0x000B
	PrevDirRead:
		inc 	si
		loop 	PrevDirRead
	PrevDirRead0:
		inc 	di
		cmp 	byte[di], '\'
		jne 	PrevDirRead0
		inc 	di
		inc 	byte[Browse_Count]
		mov 	al, byte[Browse_Count]
		cmp 	byte[Dirs_Count], al
		je 		ProcessFile
		jmp 	Explore_Dirs

Back_Segment:
	pop 	ax
	mov 	word[CD_SEGMENT], 0x0200
	mov 	cx, 0x000B
	PrevDirRead1:
		inc 	si
		loop 	PrevDirRead1
	PrevDirRead2:
		inc 	di
		cmp 	byte[di], '\'
		jne 	PrevDirRead2
		inc 	di
		inc 	byte[Browse_Count]
		mov 	al, byte[Browse_Count]
		cmp 	byte[Dirs_Count], al
		je 		ProcessFile
		jmp 	Explore_Dirs
		
ProcessFile:
	pop 	cx 		; status
	pop 	bx		; Offset para carregar
	pop 	ax		; Segmento para carregar
	push 	ax
	push 	bx
	push 	cx
	
	call 	Reload_Directory
	
	cmp 	cx, 1
	je 		Ret.LoadPath
	mov 	word[FAT16.FileSegments], ax
	mov 	ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	push 	di
	call 	FAT16.LoadThisFile
	pop 	di
	jnc 	Ret.LoadPath
	call 	CheckErrorFile
	
	Ret.ErrorPath:
		pop 	cx
		pop 	bx
		pop 	ax
		;pop 	word[CD_SEGMENT]
		;call 	Restore_Dir
		mov 	byte[ErrorFile], 0
		mov 	byte[ErrorDir], 0
		mov 	byte[IsFile], 0
		mov 	byte[Dirs_Count], 0
		mov 	byte[Browse_Count], 0
		mov 	byte[Flag_File], 0
		stc
		ret
Ret.LoadPath:
	pop 	cx
	pop 	bx
	pop 	ax
	mov 	ax, word[CD_SEGMENT]
	mov 	word[BROWSING_EX], ax
	;pop 	word[CD_SEGMENT]
	;call 	Restore_Dir
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
	clc
	ret

BROWSING_EX dw 0x0000

Cmd.REN:
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	push 	word[CD_SEGMENT]
	call 	Store_Dir
	
	mov 	cx, 1
	call 	Load_File_Path
	jc 		Ret.REN
	
	call 	SkipDI_To_Arguments
	
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
	mov 	byte[IsCommand], 0
	
	push 	si
	add 	si, (11 + 1) 		; +11 caracteres + 1 espaço
	xchg 	si, di
	call 	Format_Command_Line
	mov 	bx, si 				; Endereço do dado a renomear
	pop 	si
	
	mov 	ax, [CD_SEGMENT]
	mov 	[FAT16.DirSegments], ax		; AX = Segmento de Diretório
	mov 	[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	
	mov 	dx, 0					; Offset 0 para nome de arquivo			
	push 	di						; SI = Nome do Arquivo Formatado; DI = ... Não-Formatado
	call 	FAT16.WriteThisEntry
	pop 	di

Ret.REN:
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
ret

Cmd.ATTRIB:
	push 	word[CD_SEGMENT]
	call 	Store_Dir
	
	mov 	si, BufferArgs
	call 	SkipSI_To_Arguments
	
	cmp 	dword[si], "-ro "
	je 		Read_Only_Attr
	cmp 	dword[si], "-hi "
	je 		Hidden_Attr
	cmp 	dword[si], "-sy "
	je 		System_Attr
	cmp 	dword[si], "-vo "
	je 		Volume_Attr
	cmp 	dword[si], "-di "
	je 		Dir_Attr
	cmp 	dword[si], "-ar "
	je 		Archive_Attr
	cmp 	dword[si], "-fo "
	je 		Folder_Attr
	jmp 	Ret.ATTR
	
Read_Only_Attr:
	mov 	bx, 0x01
	jmp 	Get_File
Hidden_Attr:
	mov 	bx, 0x02
	jmp 	Get_File
System_Attr:
	mov 	bx, 0x04
	jmp 	Get_File
Volume_Attr:
	mov 	bx, 0x08
	jmp 	Get_File
Dir_Attr:
	mov 	bx, 0x10
	jmp 	Get_File
Archive_Attr:
	mov 	bx, 0x20
	jmp 	Get_File
Folder_Attr:
	mov 	bx, 0x30
	
Get_File:
	push 	bx
	add 	si, 4
	mov 	di, BufferKeys
	mov 	byte[IsCommand], 0
	call 	Format_Command_Line
	
	mov 	cx, 1
	call 	Load_File_Path
	pop 	bx
	jc 		Ret.ATTR
	
	mov 	ax, [CD_SEGMENT]
	mov 	[FAT16.DirSegments], ax		; AX = Segmento de Diretório
	mov 	[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	
	mov 	dx, 11					; Offset 11 para attributo de arquivo			
	push 	di						; SI = Nome do Arquivo Formatado; DI = ... Não-Formatado
	call 	FAT16.WriteThisEntry
	pop 	di
	
Ret.ATTR:
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
ret

Cmd.CHMOD:
	push 	word[CD_SEGMENT]
	call 	Store_Dir
	
	mov 	si, BufferArgs
	call 	SkipSI_To_Arguments
	
	xor 	bx, bx
	xor 	cx, cx
	xor 	ax, ax
	
NextFlags:
	cmp 	word[si], "u="
	je 		UsersAndAdmin
	cmp 	word[si], "a="
	je 		Admins
	cmp 	word[si], "g="
	je 		Groups
	cmp 	word[si], "o="
	je 		Others
	cmp 	word[si], "-O"
	je 		Octal
CheckToFile:
	cmp 	byte[si], 0
	jz 		Err.CHMOD2
	cmp 	byte[HasPermission], 0
	jz 		Err.CHMOD3
	jmp 	AttribFile
	
UsersAndAdmin:
	inc 	si
	or 		bx, (1 << 5)
	mov 	cx, 0
	mov 	byte[HasPermission], 1
CheckFlags:
	inc 	si
	cmp 	byte[si], "m"
	je 		AttribModify
	cmp 	byte[si], "d"
	je 		AttribDelete
	cmp 	byte[si], "x"
	je 		AttribExec
	cmp 	byte[si], "r"
	je 		AttribRead
	cmp 	byte[si], "w"
	je 		AttribWrite
	cmp 	byte[si], ","
	je	 	CheckNextUser
	cmp 	byte[si], " "
	je 		CheckNextUser
	jmp 	Err.CHMOD
	
Octal:
	add 	si, 2
	mov 	byte[HasPermission], 1
CheckOctal:
	inc 	si
	xor 	ax, ax
	cmp 	byte[si], " "
	je 		CheckTheFile
	cmp 	byte[si], 0
	jz 		Err.CHMOD2
	cmp 	byte[si], 0x30
	jb 		Err.CHMOD
	cmp 	byte[si], 0x37
	ja 		Err.CHMOD
	mov 	al, byte[si]
	sub 	al, 0x30
	inc 	cx
	cmp 	cx, 1
	je 		OctalUserMD
	cmp 	cx, 2
	je 		OctalUserXRW
	cmp 	cx, 3
	je 		OctalGroupMD
	cmp 	cx, 4
	je 		OctalGroupXRW
	cmp 	cx, 5
	je 		OctalOtherMD
	cmp 	cx, 6
	je 		OctalOtherXRW
	jmp 	Err.CHMOD
	
OctalUserMD:
	cmp 	ax, 7
	ja 		Err.CHMOD
	shl 	ax, 3
	or 		bx, ax
	jmp 	CheckOctal
OctalUserXRW:
	cmp 	ax, 7
	ja 		Err.CHMOD
	or 		bx, ax
	jmp 	CheckOctal
OctalGroupMD:
	cmp 	ax, 3
	ja 		Err.CHMOD
	shl 	ax, 9
	or 		bx, ax
	jmp 	CheckOctal
OctalGroupXRW:
	cmp 	ax, 7
	ja 		Err.CHMOD
	shl 	ax, 6
	or 		bx, ax
	jmp 	CheckOctal
OctalOtherMD:
	cmp 	ax, 3
	ja 		Err.CHMOD
	shl 	ax, 14
	or 		bx, ax
	jmp 	CheckOctal
OctalOtherXRW:
	cmp 	ax, 7
	ja 		Err.CHMOD
	shl 	ax, 11
	or 		bx, ax
	jmp 	CheckOctal
	
Admins:
	mov 	byte[HasPermission], 1
	inc 	si
	and 	bx, 0xFFDF 	; 1111111111011111b = Only ADMIN
	mov 	cx, 0
	jmp 	CheckFlags
	
Groups:
	mov 	byte[HasPermission], 1
	inc 	si
	mov 	cx, 6
	jmp 	CheckFlags
	
Others:
	mov 	byte[HasPermission], 1
	inc 	si
	mov 	cx, 11
	jmp 	CheckFlags
	
AttribModify:
	add 	cx, 4
	mov 	ax, 1
	shl		ax, cl
	sub 	cx, 4
	or 		bx, ax
	jmp 	CheckFlags
AttribDelete:
	add 	cx, 3
	mov 	ax, 1
	shl		ax, cl
	sub 	cx, 3
	or 		bx, ax
	jmp 	CheckFlags
AttribExec:
	add 	cx, 2
	mov 	ax, 1
	shl		ax, cl
	sub 	cx, 2
	or 		bx, ax
	jmp 	CheckFlags
AttribRead:
	add 	cx, 1
	mov 	ax, 1
	shl		ax, cl
	sub 	cx, 1
	or 		bx, ax
	jmp 	CheckFlags
AttribWrite:
	mov 	ax, 1
	shl		ax, cl			; CX = 0
	or 		bx, ax
	jmp 	CheckFlags
CheckNextUser:
	inc 	si
	jmp 	NextFlags
CheckTheFile:
	cmp 	cx, 6
	jb 		Err.CHMOD
	inc 	si
	jmp 	CheckToFile
	
Err.CHMOD:
	mov 	si, ErrorChmod
	call 	Print_String
	jmp 	Ret.CHMOD
	
Err.CHMOD2:
	mov 	si, ErrorChmod2
	call 	Print_String
	jmp 	Ret.CHMOD
	
Err.CHMOD3:
	mov 	si, ErrorChmod3
	call 	Print_String
	jmp 	Ret.CHMOD
	
AttribFile:
	push 	bx
	mov 	di, BufferKeys
	mov 	byte[IsCommand], 0
	call 	Format_Command_Line
	
	mov 	cx, 1
	call 	Load_File_Path
	pop 	bx
	jc 		Ret.CHMOD
	
	mov 	ax, [CD_SEGMENT]
	mov 	[FAT16.DirSegments], ax		; AX = Segmento de Diretório
	mov 	[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	
	mov 	dx, 12					; Offset 12 para attributo para permissão			
	push 	di						; SI = Nome do Arquivo Formatado; DI = ... Não-Formatado
	call 	FAT16.WriteThisEntry
	pop 	di
	
Ret.CHMOD:
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	
	mov 	byte[HasPermission], 0
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
ret

ErrorChmod 	db "Erro: Formato de permissao invalida!",0
ErrorChmod2 db "Erro: Nenhum arquivo especificado!",0
ErrorChmod3 db "Erro: Nenhuma permissao especificada!",0
HasPermission db 0

Cmd.DEL:
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	push 	WORD[CD_SEGMENT]
	call 	Store_Dir
	
	mov 	cx, 1
	call 	Load_File_Path
	jc 	 	Ret.DEL
	
	mov 	ax, [CD_SEGMENT]
	mov 	[FAT16.DirSegments], ax		; AX = Segmento de Diretório
	mov 	[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	
	push 	di
	call 	FAT16.DeleteThisFile
	pop 	di
	
	
Ret.DEL:
	clc
	pop 	WORD[CD_SEGMENT]
	call 	Restore_Dir
	
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
ret

Cmd.MKDIR:
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	push 	word[CD_SEGMENT]
	call 	Store_Dir

	push 	si
	push 	di
	push 	es
	
	mov 	ax, word[CD_SEGMENT]
	mov 	es, ax
	cmp 	ax, 0x0200
	je 		ClearClusterFolder
	
	xor 	di, di
	mov 	ax, word[es:di + 0x1A]
	jmp 	ClusterFolder
	
ClearClusterFolder:
	mov 	ax, 0

ClusterFolder:
	push 	ax

	mov 	si, Folder_Struct
	mov 	ax, 0x6800
	mov 	es, ax
	xor 	di, di
	pop 	ax
	mov 	word[si + 0x3A], ax		; 0x20(32) + 0x1A(cluster)
	mov 	cx, 64
	rep 	movsb
	
	pop 	es
	pop 	di
	pop 	si
	
	mov 	cx, 1 	   ; Status
	call 	Load_File_Path
	
	mov 	cx, 64
	mov 	ax, 0x6800
	mov 	[FAT16.FileSegments], ax
	mov 	ax, [CD_SEGMENT]
	mov 	[FAT16.DirSegments], ax		; AX = Segmento de Diretório
	mov 	byte[FAT16.LoadingDir], 1
	xor 	bx, bx						; BX = Buffer com Dados para Escrever
	push 	di							; SI = Nome do Arquivo Formatado; DI = ... Não-Formatado
	call 	FAT16.WriteThisFile
	pop 	di
	
Ret.MKDIR:
	clc
	pop 	WORD[CD_SEGMENT]
	call 	Restore_Dir
	
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
	mov 	byte[Dirs_Count], 0
	mov 	byte[Browse_Count], 0
	mov 	byte[Flag_File], 0
ret

Folder_Struct:
	db ".          ",0x10
	times 32 - 12 db 0
	db "..         ",0x10
	times 32 - 12 db 0

Store_Dir:
	pusha
	mov 	ecx, 256
	mov 	ebx, 4
	call 	Calloc
	mov 	si, word[CD_SEGMENT]
	shl 	si, 4
	push 	ax
	push 	ds
	xor 	ax, ax
	mov 	ds, ax
	pop 	es
	pop 	ax
	mov 	edi, eax
	rep 	movsd
	mov 	bx, es
	mov 	ds, bx
	mov 	[SaveADDR], eax
	popa
ret
SaveADDR  dd 0

Restore_Dir:
	pusha
	mov 	di, [CD_SEGMENT]
	shl 	di, 4
	push 	ds
	xor 	ax, ax
	mov 	es, ax
	mov 	esi, [SaveADDR]
	mov 	ecx, 256
	rep 	movsd
	pop 	es
	;mov 	ebx, [SaveADDR]
	;call 	_Free			; existe algum erro nesta rotina _Free
	popa
ret

Cmd.FAT:
	mov 	ax, 0x1000
	mov 	es, ax
	mov 	al, 0
	mov 	di, 0x0000
	mov 	cx, 1024
	call 	PrintDataHex16
	;inc 	byte[CursorRaw]
ret

Cmd.HEX:
	xor 	byte[IsHexa], 1
	mov 	si, DisabledMsg
	cmp 	byte[IsHexa], 1
	jnz 	RetHex
	mov 	si, EnabledMsg
RetHex:
	call 	Print_String
	;inc 	byte[CursorRaw]
ret
	
	

ToUpperCase:
	xor 	bx, bx
	cmp 	al, 0x61
	setae 	bh
	cmp 	al, 0x7A
	setbe 	bl
	cmp 	bx, 0x101
	jne 	Ret_ToUpperCase
	sub 	al, 0x20 							
Ret_ToUpperCase:
	ret
	
ToLowerCase:
	xor 	bx, bx
	cmp 	al, 0x41
	setae 	bh
	cmp 	al, 0x5A
	setbe 	bl
	cmp 	bx, 0x101
	jne 	Ret_ToLowerCase
	add 	al, 0x20 							
Ret_ToLowerCase:
	ret
	

Store_Restricting_Chars:
	cmp 	al, 0x2E
	je 		CheckDot
	cmp 	al, 0x5C
	je 		Ret_Restrict
	cmp 	al, 0x2F
	je 		Ret_Restrict
YesStore:
	inc 	byte[CharsCount]
	stosb					; Store from AL to ES:DI and inc di
	jmp 	Ret_Restrict		
CheckDot:
	cmp 	byte[si], 0x2E
	je 		YesStore
	cmp 	byte[si-2], 0x2E
	je 		YesStore
Ret_Restrict:
	ret


SkipDI_To_Arguments:
	inc 	di
	cmp 	byte[di], 0x20
	jne 	SkipDI_To_Arguments
	inc 	di
ret

SkipSI_To_Arguments:
	inc 	si
	cmp 	byte[si], 0x20
	jne 	SkipSI_To_Arguments
	inc 	si
ret

Count_Chars_Limit:
	inc 	byte[CharsCount]
	dec 	si
	cmp 	byte[si], 0x5C
	je 		Return_Count_Chars
	cmp 	byte[si], 0x20
	je 		Return_Count_Chars
	jmp 	Count_Chars_Limit
Return_Count_Chars:
	ret
CharsCount db 0
Flag_File  db 0
Dirs_Count db 0

Check_Chars_Count:
	push 	si
	sub 	si, 2 				; SI was incremented by the lodsb instruction before
	mov 	byte[CharsCount], 0
	call 	Count_Chars_Limit	; Perform character count
	pop 	si
ret


Check_Special_Chars:
	push 	si
	xor 	bx, bx
	cmp 	al, 0x2E			; if al is dot, bh = 1
	sete 	bh
	cmp 	byte[si], 0x2E		; if SI is not dot, bl = 1
	setne 	bl
	cmp 	bx, 0x101 			; if BX is 0x101, then is a file
	je 		Create_Spaces 		; Create Spaces for dot
	cmp 	al, 0x5C 			; if al is bar, then have more folders
	je 		Space_Folders
	cmp 	byte[si], 0
	je 		Space_Final_Folders
	cmp 	byte[si], 0x20
	je 		Space_Final_Folders
	
	jmp 	Ret_CheckSpecial
Space_Final_Folders:
	cmp 	byte[Flag_File], 1
	je 		Ret_CheckSpecial
	inc 	si
Space_Folders:
	;call 	Check_Chars_Count
	mov 	bl, byte[CharsCount]
	mov 	byte[CharsCount], 0
	cmp 	bl, 10
	ja 		Ret_CheckSpecial
	mov 	cl, 11
	sub 	cl, bl
	xor 	ch, ch
	mov 	al, 0x20
	rep 	stosb
	inc 	byte[Dirs_Count]
	jmp 	Ret_CheckSpecial
Create_Spaces:	
	cmp 	byte[si-2], 0x2E
	je 		Ret_CheckSpecial
	mov 	byte[Flag_File], 1
	;call 	Check_Chars_Count
	mov 	bl, byte[CharsCount]
	mov 	byte[CharsCount], 0
	cmp 	bl, 8
	ja 		Ret_CheckSpecial
	mov 	cl, 8
	sub 	cl, bl
	xor 	ch, ch
	mov 	al, 0x20
	rep 	stosb
Ret_CheckSpecial:
	pop 	si
	ret
	
Check_Drive_Letter:
	push 	di
	push 	si
	mov 	byte[Flag_File], 0	; Zerar aqui pois o ocorre uma única vez a cada execução
	mov 	di, LetterDisk
	cmpsw
	je 		ContinueConv
	sub 	si, 2
	mov 	ch, byte[LetterDisk]
	add 	ch, 0x20
	mov 	cl, ':'
	lodsw
	xchg 	ah, al
	cmp 	ax, cx
	jne 	Ret_CheckDrive
ContinueConv:
	inc 	si				; Incrementa barra do BufferArgs
	cmp 	byte[QuantDirs], 0
	jz 		NoRestoreSI
	mov 	di, BufferAux
	mov 	cx, 120
	call 	Zero_Buffer
	call 	Copy_Buffers
	sub 	si, 3
	pop 	di
	push 	di
	mov 	eax, "..\ "
	xor 	ecx, ecx
	mov 	cl, byte[QuantDirs]
ReplaceLetter:
	stosd
	dec 	di
	loop 	ReplaceLetter
	mov 	byte[di], 0
	mov 	si, BufferAux
	call 	Copy_Buffers
	jmp 	Ret_CheckDrive
NoRestoreSI:
	add 	sp, 2
	pop 	di
	ret
Ret_CheckDrive:
	pop 	si
	pop 	di
ret
	
	
Format_Command_Line:
	cmp 	byte[IsCommand], 0		; If the source isn´t a 'command', e.g.: read, cd,...
	jz 		Skip_Skippings			; no skip SI & DI to args, but read in the begin
	call 	SkipSI_To_Arguments		; Skip till the 1st byte in BufferArgs
	;call 	SkipDI_To_Arguments		; Skip till the 2nd byte in BufferKeys
Skip_Skippings:
	call 	Check_Drive_Letter		; Check if is drive letter to replace
	push 	si
	push 	di
Format_Loop:
	lodsb							; Load from DS:SI to AL and inc si
	call 	ToUpperCase				; Convert to Upper Case if char is "a-z"
	call 	Store_Restricting_Chars ; Store in ES:DI restricting some chars
	call 	Check_Special_Chars 	; Checkin Special chars, such as: dot,bar,etc.
	cmp 	byte[si], 0x20
	je 		.Ret_Format
	cmp 	byte[si], 0				; If not at the end of string
	jne 	Format_Loop				; Back to the loop
.Ret_Format:
	pop 	si						; Troca os valores de SI para DI
	pop 	di						; e de DI para SI, durante o desempilhamento
	mov 	byte[CharsCount], 0
	ret

Cmd.CD:
	call 	Reload_Directory
	
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	mov 	byte[Dirs_Count], 0
	
ContinuePaths:
	cmp 	word[CD_SEGMENT], 0x0200
	je 		VerifyArg
	cmp 	word[si], ".."
	je 		SubSegment
	jmp 	AddSegment
SubSegment:
	mov		ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0000
	push 	ax
	sub 	ax, 0x40
	cmp 	ax, 0x0200
	je 		BackSegment
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	pop 	ax
	push 	di
	call 	FAT16.LoadThisFile
	pop 	di
	jnc 	SuccessSub
	call 	CheckErrorFile
	jmp 	RetCd

SuccessSub:
	
	call 	SaveFolderPreview
	
	sub 	word[CD_SEGMENT], 0x40
	
	mov cx, 0x000B
	PrevDir:
		inc 	si
		cmp 	byte[si], 0
		je 		RetCd
		loop 	PrevDir
	PrevDir0:
		inc 	di
		cmp 	byte[di], '\'
		jne 	PrevDir0
		inc 	di
		jmp 	ContinuePaths
		

BackSegment:
	pop 	ax
	mov 	word[CD_SEGMENT], 0x0200

	call 	SaveFolderPreview

	mov cx, 0x000B
	PrevDir1:
		inc 	si
		cmp 	byte[si], 0
		je 		RetCd
		loop 	PrevDir1
	PrevDir2:
		inc 	di
		cmp 	byte[di], '\'
		jne 	PrevDir2
		inc 	di
		jmp 	ContinuePaths

VerifyArg:
	cmp 	word[si], ".."
	jne 	AddSegment
	mov 	al, 0x02
	call 	CheckErrorFile
	jmp 	RetCd
AddSegment:
	mov		ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0000
	push 	ax
	add 	ax, 0x40
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	pop 	ax
	push 	di
	call 	FAT16.LoadThisFile
	pop 	di
	jnc 	SuccessAdd
	call 	CheckErrorFile
	jmp 	RetCd

SuccessAdd:
	
	; SI = Buffer formatado
	; DI = Buffer do usuário
	call 	SaveFolderNext
	
	add 	word[CD_SEGMENT], 0x40
	
	mov cx, 0x000B
	NextDir:
		inc 	si
		cmp 	byte[si], 0
		je 		RetCd
		loop 	NextDir
	NextDir2:
		inc 	di
		cmp 	byte[di], '\'
		jne 	NextDir2
		inc 	di
		
		jmp 	ContinuePaths
		
RetCd:
	;inc 	byte[CursorRaw]
	;call 	Cursor.CheckToRollEditor
	mov 	byte[ErrorFile], 0
	mov 	byte[ErrorDir], 0
	mov 	byte[IsFile], 0
ret

; Rotina de verificação de erros em arquivos/diretórios
CheckErrorFile:
	cmp 	al, 0x01
	je 		NoFoundFileError
	cmp 	al, 0x02
	je 		NoFoundDirError
	cmp 	al, 0x03
	je 		ErrorDirIsntFile
	cmp 	al, 0x04
	je 		ErrorFileIsntDir
	jmp 	RetERROR
	NoFoundFileError:
		mov 	si, MsgFileError1
		call 	Print_String
		mov 	si, di
		call 	Print_String
		mov 	si, MsgFileError2
		call 	Print_String
		jmp 	RetERROR
	NoFoundDirError:
		mov 	si, MsgDirError1
		call 	Print_String
		mov 	si, di
		call 	Print_String
		mov 	si, MsgFileError2
		call 	Print_String
		jmp 	RetERROR
	ErrorDirIsntFile:
		mov 	si, MsgDirError1
		call 	Print_String
		mov 	si, di
		call 	Print_String
		mov 	si, ErrIsNotFile1
		call 	Print_String
		jmp 	RetERROR
	ErrorFileIsntDir:
		mov 	si, MsgFileError1
		call 	Print_String
		mov 	si, di
		call 	Print_String
		mov 	si, ErrIsNotDir1
		call 	Print_String
RetERROR:
	ret

; Move the User buffer (SI) to the Access Folder Pointer (DI)
SaveFolderNext:
	push 	di
	push 	si
	mov 	si, di
	mov 	di, word[DI_Addr_Folder]
SaveFolder:
	movsb
	inc 	word[CounterAccess]
	cmp 	byte[si], 0
	je 		Add_Bar
	cmp 	byte[si], '\'
	jne 	SaveFolder
Add_Bar:
	inc 	word[CounterAccess]
	mov 	al, '\'
	stosb
Ret_SaveFolder:
	mov 	word[DI_Addr_Folder], di
	inc 	byte[QuantDirs]
	pop 	si
	pop 	di
ret

DI_Addr_Folder dw FolderAccess+1

SaveFolderPreview:
	pusha
	mov 	di, word[DI_Addr_Folder]
	dec 	di
	mov 	al, 0
	std
EraseFolder:
	stosb
	dec 	word[CounterAccess]
	cmp 	byte[di], '\'
	jne 	EraseFolder
	cld
	mov 	al, '\'
	stosb
RetPreview:
	dec 	byte[QuantDirs]
	mov 	word[DI_Addr_Folder], di
	popa
ret	

Cmd.ASSIGN:
	inc 	si
	
	mov 	ax, 0x200
	mov 	es, ax
	xor 	di, di
	add 	di, 32
	movsb

	mov 	cx, 5
Assig_Write:
	push 	si
	mov 	ah, 0x43
	mov 	al, 0x02
	mov 	si, PacketWrite
	mov 	dl, 0x80
	int 	0x13
	pop 	si
	jnc 	Assig_Success
	
	xor 	ax, ax
	int 	0x13
	
	loop 	Assig_Write
	
Assig_Success:
	;mov 	byte[LetterDisk], al
	;inc 	byte[CursorRaw]
ret
PacketWrite:
	db 16 			; Size of Packet
	db 0			; Reserved
	dw 1			; Number of sectors/block to transfer
	dd 0x02000000	; Transfer buffer
	dq 0x1F3		; Start absolute block/sector number

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
		
		;inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.NumberOfHeads
		call 	Print_String
		;mov 	ax, word[NumberHeads+2]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[NumberHeads]
		;call 	Print_Hexa_Value16
		mov 	al, dh
		call	Print_Hexa_Value8
		
		;inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.NumberOfCylinders
		call 	Print_String
		;mov 	ax, word[NumberCylinders+2]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[NumberCylinders]
		;call 	Print_Hexa_Value16
		mov 	al, ch
		call	Print_Hexa_Value8
		
		;inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		mov 	si, DiskParameter.SectorsPerTracks
		call 	Print_String
		;mov 	ax, word[SectorsPerTrack+2]
		;call 	Print_Hexa_Value16
		;mov 	ax, word[SectorsPerTrack]
		;call 	Print_Hexa_Value16
		mov 	al, cl
		call	Print_Hexa_Value8
		
		;inc 	byte[CursorRaw]
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
		
		;inc 	byte[CursorRaw]
		call	Cursor.CheckToRollEditor
		
		jmp 	RetDiskReader
	_ReadError:
		mov 	si, ReadMsgError
		call 	Print_String
	
RetDiskReader:
	;inc 	byte[CursorRaw]
	popa
ret

; THIS IS THE WRITE COMMAND 
Cmd.WRITE:
	;call	Reload_Directory
	mov 	word[WriteCounter], 0x0000
	
SkipToLetter:					; Caso há espaços antes do 1ª argumento
	inc 	si					; Ponteiro para argumento
	cmp 	byte[si], 0x20
	jz 		SkipToLetter
	
	mov 	byte[IsCommand], 0
	cmp		dword[si], 0x006e6f2d	; si == "-on"?
	je	 	WriteON
	cmp 	dword[si], 0x206e6f2d  	; si == "-on "?
	je 		WriteON
	cmp 	dword[si], 0x66666f2d  	; si == "-off"?
	je 		WriteOFF
	jmp 	CheckArgs
WriteON:
	mov 	byte[WriteEnable], 1
	jmp 	Ret.WRITE
WriteOFF:
	mov 	byte[WriteEnable], 0
	jmp 	Ret.WRITE
WriteHidden:
	mov 	byte[ArgHidd], 1
	add 	si, 3
	jmp 	SkipToLetter
CheckArgs:
	xor 	ax, ax
	cmp 	dword[si], 0x2063662d 	; si == "-fc "?
	sete 	ah
	cmp 	dword[si], 0x2061662d 	; si == "-fa "?
	sete	al
	cmp 	ax, 0
	jnz 	FileWrite
	cmp 	dword[si], 0x2069682d	; si == "-hi "?
	jz 		WriteHidden
	cmp 	byte[si], 0
	jz 		Ret.WRITE
	cmp 	byte[si], '"'			; Se esta condição for verdadeira,
	jnz 	ArgsError				; Então há um erro de argumentos
	
	; Só executa daqui pra baixo caso o 1ª argumento tenha aspas
	; (sendo um dado a ter sua saída na tela ou arquivos)
	mov 	ax, 0x6800
	mov 	es, ax
	xor 	di, di
	mov 	eax, 0x0A0A0A0A
	stosd
	
	push 	si
SkipToParam:
	inc 	si
	cmp 	byte[si], 0
	je 		IsNotData
	cmp 	byte[si], '-'
	jne 	SkipToParam
	inc 	si
	cmp 	word[si], "fa"
	jne 	IsNotData
	
	mov 	ax, 0x3000
	mov 	es, ax
	mov 	di, BufferWrite
	mov 	cx, 100
	call 	Zero_Buffer
	jmp 	IsData
	
IsNotData:
	
; 	ZERAR BUFFER DE MEMÓRIA
	push 	di
	xor 	eax, eax
	mov 	cx, 1250
	rep 	stosd
	pop 	di
	
IsData:
	pop 	si
	
; CÓPIA DE DADOS PARA BUFFER DE IMPRESSÃO/ESCRITA
DataCopy:
	mov 	byte[ArgData], 1
	xor 	cx, cx
	cmp 	byte[si], '"'
	jne 	TransferData
	inc 	si
TransferData:
	inc 	cx
	cmp 	word[si], "\n"
	je 		MoveBreak
	cmp 	word[si], "\t"
	je 		MoveTab
	cmp 	byte[si], '"'
	je 		EndTransfer
	cmp 	byte[si], 0
	je 		EndTransfer2
	movsb
	inc 	word[WriteCounter]
	jmp 	TransferData
MoveBreak:
	mov 	al, 0x0A
	stosb
	mov 	al, 0x0D
	stosb
	add 	word[WriteCounter], 2
	add		si, 2
	jmp 	TransferData
MoveTab:
	mov 	al, 0x09
	stosb
	inc 	word[WriteCounter]
	add		si, 2
	jmp 	TransferData
EndTransfer:
	inc 	si
	cmp 	byte[si], 0
	je 		EndTransfer2
	cmp 	byte[si], 0x20
	je 		EndTransfer
	jmp 	CheckArgs
EndTransfer2:
	cmp 	byte[ArgFile], 1
	je 		WriteFile
	
	mov 	al, 0
	mov 	di, 0x0004
	dec 	cx
	call 	PrintData
	jmp 	Ret.WRITE
	
FileWrite:
	mov 	byte[ArgFile], 1
	push 	word[CD_SEGMENT]
	push 	ax
	add 	si, 4
	push 	ds
	pop 	es
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	call 	Store_Dir
	
	mov 	cx, 1
	call 	Load_File_Path
	
	xor 	dx, dx
	pop 	ax
	push 	ax
	cmp 	al, 1
	jne 	NoFile
	
; 	SE PARÂMETRO FOR -FA (AL = 1), ESTE CÓDIGO LER O ARQUIVO
	mov 	ax, 0x6800
	mov 	word[FAT16.FileSegments], ax
	mov 	ax, word[CD_SEGMENT]
	mov 	word[FAT16.DirSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	mov 	bx, 0x0004
	push 	di
	push 	si
	call 	FAT16.LoadThisFile
	pop 	si
	pop 	di
	jc 		CheckArgData
	
	cmp 	byte[ArgData], 1
	je 		CopyBufferToMem
	jmp 	NoCopy
	
CopyBufferToMem:
	mov 	cx, [WriteCounter]
	push 	si
	push 	di
	
	mov 	ax, 0x6800
	mov 	es, ax
	mov 	di, 0x0004
	add 	di, dx
	mov 	si, BufferWrite
	rep 	movsb
	
	pop 	di
	pop 	si
	add 	[WriteCounter], dx
	jmp 	NoFile
	
CheckArgData:
	cmp 	byte[ArgData], 1
	je 		CopyBufferToMem
	jmp 	NoFile
	
NoCopy:
	mov 	[WriteCounter], dx	; Inicie o contador a partir deste ponto do arquivo
	
	push 	di
FindSpaceZero2:
	inc 	di
	cmp 	byte[di], '"'
	je 		RestoreDI
	cmp 	byte[di], 0
	jne 	FindSpaceZero2
	pop 	di
	
; 	CASO O ARQUIVO EXISTA, IMPRIMIR OS SEUS CARACTERES
; 	OBS.: NÃO IMPRIMIR SE NÃO FOR UM EDITOR (CONTROLADO PELO CÓDIGO ACIMA)
	cmp 	byte[ArgHidd], 1
	jz 		NoFile
	
	push 	di
	mov 	ax, 0x6800
	mov 	es, ax
	mov 	al, 0
	mov 	di, 0x0004
	mov 	cx, dx 				; Tamanho do arquivo lido
	call 	PrintData
	
RestoreDI:
	pop 	di
	
NoFile:
	push 	dx
	call 	Get_Cursor
	mov 	[AtualRaw], dh
	pop 	dx
	
	pop 	ax				; Desempilha a Flag de AX
	push 	di
	push 	si
	push 	ax
	
	; DEFINIR ROTA PARA FILECREATE OU FILEAPPEND POR AX
	cmp 	byte[ArgData], 1
	je 		WriteFile
	
FindSpaceZero:
	inc 	di
	cmp 	byte[di], 0
	je 		WriteEditor
	cmp 	byte[di], 0x20
	jne 	FindSpaceZero
FindNextChar:
	inc 	di
	cmp 	byte[di], 0x20
	je 		FindNextChar
	cmp 	byte[di], 0
	je 		WriteEditor
	mov 	si, di
	
	mov 	ax, 0x6800
	mov 	es, ax

	xor 	di, di
	mov 	eax, 0x0A0A0A0A
	stosd
	add 	di, dx
	
	; ZERAR BUFFER DE MEMÓRIA
	push 	di
	xor 	eax, eax
	mov 	cx, 1250
	rep 	stosd
	pop 	di
	
	jmp 	DataCopy		; QUANDO O PARÂMETRO TEM -FC/FA ANTES DO DADO NA CLI
	
; THIS IS THE MINI-EDITOR OF THE WRITE COMMAND
; CRIAR FUNÇÕES DE ANÁLISE DE CARACTERES, ARMAZENAMENTO E A ROTA- MINI-EDITOR
WriteEditor:
	mov 	ax, 0x6800
	mov 	es, ax

	xor 	di, di
	mov 	eax, 0x0A0A0A0A
	stosd
	add 	di, dx
	
	; ZERAR BUFFER DE MEMÓRIA
	push 	di
	xor 	eax, eax
	mov 	cx, 1250
	rep 	stosd
	pop 	di
	
FileEditor:
	xor 	ax, ax
	int 	0x16
	cmp 	al, 0x08
	je 		WriteEditor.BackSpace
	cmp 	al, 0x0D
	je		WriteEditor.Enter
	cmp 	al, 0x09
	je 		WriteEditor.TAB
	cmp 	ax, 0x4B00 		; Arrow Left
	je 		WriteEditor.ArrowLeft
	cmp 	ax, 0x4D00 		; Arrow Right
	je 		WriteEditor.ArrowRight
	cmp 	ax, 0x4800 		; Arrow Up
	je 		WriteEditor.ArrowUp
	cmp 	ax, 0x5000 		; ArrowDown
	je 		WriteEditor.ArrowDown
	cmp 	al, 0x13		; CTRL + S = Salvar
	je 		WriteFile
	cmp 	al, 0x18 		; CTRL + X = Cancelar
	je 		ExitEditor
	StoreChar:
		call 	CheckToOffsetChars
		stosb
		call 	Get_Cursor
		inc 	word[WriteCounter]
		cmp 	dl, byte[LimitCursorFinalX]
		jne		ShowChar
		call 	Cursor.CheckToRollEditor
		inc 	byte[AtualRaw]
		mov 	ah, 0Eh
		int 	10h
		jmp 	FileEditor
	ShowChar:
		mov 	ah, 0Eh
		int 	10h
		jmp 	FileEditor

CheckToOffsetChars:
	pusha
	cmp 	byte[es:di], 0
	jz 		ret.CTOC

	push 	di
	mov 	cx, [WriteCounter]
	sub 	cx, di
	add 	cx, 4
	add 	di, cx
	
	push 	ax
	mov 	bx, 1
	cmp 	al, 0x0D
	jnz 	offsetconf
	
	inc 	di
	mov 	bx, 2
	
offsetconf:
	push 	cx
	std
offsetfront:
	sub 	di, bx
	mov 	al, [es:di]
	add 	di, bx
	stosb
	loop 	offsetfront
	cld
	pop 	cx
	pop 	ax
	pop 	di
	
	inc 	cx
	cmp 	al, 0x0D
	jnz 	Show_Data
	
	mov 	al, 0x0A
	mov 	[es:di+1], al
	mov 	al, 0x0D
	inc 	cx
	
	call 	FillZeroTextMemory
	
Show_Data:
	mov 	[es:di], al
	call 	Get_Cursor
	call 	Hide_Cursor
	mov 	bl, [CursorRaw]
	mov 	al, 0
	call 	PrintData
	mov 	[CursorRaw], bl
	call 	Move_Cursor
	call 	Show_Cursor
	
ret.CTOC:
	popa
	ret
	
WriteFile:
	pop 	ax
	pop 	si
	pop 	di
	
	mov 	dx, ax						; DX = Flag de Criação/Acréscimo
	mov 	cx, word[WriteCounter]		; CX = Quantidade de Caracteres
	mov 	ax, 0x6800
	mov 	[FAT16.FileSegments], ax
	mov 	ax, [CD_SEGMENT]
	mov 	[FAT16.DirSegments], ax		; AX = Segmento de Diretório
	mov 	byte[FAT16.LoadingDir], 0
	mov 	bx, 0x0004					; BX = Buffer com Dados para Escrever
	push 	di							; SI = Nome do Arquivo Formatado; DI = ... Não-Formatado
	call 	FAT16.WriteThisFile
	pop 	di
	
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	
	mov 	dh, [AtualRaw]
	mov 	[CursorRaw], dh
	jmp 	Ret.WRITE
	
ExitEditor:
	pop 	ax
	pop 	si
	pop 	di
	
	mov 	dh, [AtualRaw]
	mov 	[CursorRaw], dh
	call 	Cursor.CheckToRollEditor
	mov 	si, WriteCanceled
	call 	Print_String
	
	pop 	word[CD_SEGMENT]
	call 	Restore_Dir
	jmp 	Ret.WRITE
	
ArgsError:
	mov 	si, args_error
	call 	Print_String
	
Ret.WRITE:
	push 	es
	mov 	ax, 0x6800
	mov 	es, ax
	xor 	di, di
	xor 	eax, eax
	mov 	cx, 1250
	rep 	stosd
	pop 	es
	call 	Reload_Directory
	mov 	byte[ArgFile], 0
	mov 	byte[ArgData], 0
	mov 	byte[ArgHidd], 0
	ret

; Dois últimos erros pra resolver:
; 1. Checar o ultimo caractere apagado quando volta pra ultima coluna;
; 2. Em PrintData para o -fa, colocar PutZeroTextMemory para as quebras;
WriteEditor.BackSpace:
		call 	Get_Cursor
		mov 	bh, byte[LimitCursorBeginY]
		inc 	bh
		cmp 	dh, bh					; Verifica se o cursor é menor ou igual ao limite Y do ecrã
		jbe 	CheckLimitX	  			; se for, verifica a coluna X
		
		cmp 	byte[es:di-1], 0x0A		; Verifica se o caractere anterior em memória foi um ENTER
		je 		FindColumn				; Se sim, então encontrar coluna
		
	CursorToLast:						; Se cursor é maior e o char anterior não for ENTER, então...
		cmp 	dl, 12					; Ou primeiramente o cursor volta pra última coluna da linha anterior
		je		BackLastColumn			; (se a coluna for 12) e apaga o caractere, ou, ele só apaga o caractere
		jmp 	EraseCharBack
		
	FindColumn:
		push 	di
		sub 	di, 2
		mov 	cx, 56+3
		FindEnter:
			std
			mov 	al, 0x0A
			repne 	scasb
			cld
			pop 	di
			cmp 	cx, 1
			je 		CursorToLast
			cmp 	cx, 0
			je 		CheckTextMemory
			sub 	cx, 56+3
			not 	cx
			inc 	cx
			add 	cx, 12-1
			jmp 	BackSpecificColumn
			
	CheckTextMemory:
		call 	SearchPositionBack
	
	BackSpecificColumn:			; retorna cursor para coluna específica da linha anterior
		push 	dx
		call 	Get_Cursor
		dec 	dh
		mov 	byte[CursorRaw], dh
		mov 	dl, cl
		call 	Move_Cursor
		pop 	dx
		dec 	byte[AtualRaw]
		jmp 	CheckCharBack
		
	BackLastColumn:				; retorna cursor pra última coluna da linha anterior
		push 	dx
		call 	Get_Cursor
		dec 	dh
		mov 	byte[CursorRaw], dh
		mov 	dl, byte[LimitCursorFinalX]
		call 	Move_Cursor
		pop 	dx
		dec 	byte[AtualRaw]
		jmp 	FileEditor
			
	CheckLimitX:			  	; Verificar o limite de coluna
		cmp 	dl, 12			; Se X inicial for 12, então chegamos no início do ecrã e não faz nada
		je		FileEditor
	
	CheckCharBack:							; apaga caractere e desloca cursor
		cmp 	byte[es:di-1], 0x0A
		jnz 	EraseCharBack
		dec 	di
		mov 	al, 0
		mov 	[es:di], al
		dec 	word[WriteCounter]
	EraseCharBack:
		dec 	di
		mov 	ah, 0x0E
		mov 	al, 0x08
		int 	10h
		mov 	al, 0
		mov 	[es:di], al
		int 	10h
		mov 	al, 0x08
		int 	10h
		dec 	word[WriteCounter]
		jmp 	FileEditor
		
		
SearchPositionBack:
	push 	es
	push 	dx
	push 	di
		
	; Encontrar posição do 1ª char da linha anterior na memória de texto
	mov 	ax, 0xB800
	mov 	es, ax
	xor 	cx, cx
	xor 	dx, dx
	mov 	bx, (12*2)
	mov 	ax, (80*2)
	mov 	cl, [CursorRaw]
	mul 	cx
	add 	ax, bx
	sub 	ax, 160
	mov 	di, ax		; DI = posição do 1ª char
		
	; Procurar o byte 0x00 na memória de texto a partir do 1ª char
	cld
	mov 	cx, 112
	mov 	al, 0x00
	repne 	scasb		; CX = Diferença de bytes entre (56*2) e o 1ª char
		
	; Calcular a coordenada da coluna da linha anterior a partir da diferença
	mov 	ax, 112
	sub 	ax, cx
	shr 	ax, 1
	inc 	al
	mov 	cl, al
	add 	cl, 12

	pop 	di
	pop 	dx
	pop 	es
ret

WriteEditor.Enter:
	call 	CheckToOffsetChars
	stosb
	mov 	al, 0x0A
	stosb
	
	call 	PutZeroTextMemory			; Necessário para o backspace identificar a coluna
	
	call 	Cursor.CheckToRollEditor
	inc 	byte[AtualRaw]
	add 	word[WriteCounter], 2
	jmp 	FileEditor
	
WriteEditor.TAB:
	stosb
	mov 	al, " "
	mov 	ah, 0x0E
	int 	0x10
	int 	0x10
	int 	0x10
	int 	0x10
	inc 	word[WriteCounter]
	jmp 	FileEditor
	
; Processamento de seta esquerda
WriteEditor.ArrowLeft:
	call 	Get_Cursor
	dec 	di
	cmp 	byte[es:di], 0x0A
	jnz 	ProcessCursor0
	dec 	di
ProcessCursor0:
	cmp 	dl, 12
	jz 		ProcessBack
	dec 	dl
	call 	Move_Cursor
	jmp 	FileEditor
ProcessBack:
	call 	SearchPositionBack
	push 	dx
	call 	Get_Cursor
	dec 	dh
	mov 	byte[CursorRaw], dh
	mov 	dl, cl
	dec 	dl
	call 	Move_Cursor
	pop 	dx
	jmp 	FileEditor

; Processamento de seta direita
WriteEditor.ArrowRight:
	cmp 	byte[es:di], 0
	je 		FileEditor
	inc 	di
	cmp 	byte[es:di], 0x0A
	jnz 	ProcessCursor1
	inc 	di
ProcessCursor1:
	cmp 	dl, 68
	jz 		NextLine
	inc 	dl
	call 	Move_Cursor
	jmp 	FileEditor
NextLine:
	call 	Cursor.CheckToRollEditor
	jmp 	FileEditor
	
WriteEditor.ArrowUp:
	call 	Get_Cursor
	cmp 	dh, byte[LimitCursorBeginY]
	je 		VerifyScrolledAbove
	
	mov 	[LinSaved], dh
	mov 	[ColSaved], dl
	xor 	cx, cx
FindBegin:
	dec 	di
	dec 	dl
	inc 	cx
	cmp 	byte[es:di-1], 0x0A
	jz 		Found0A
	cmp 	dl, 12
	jz 		FoundBeg
	jmp 	FindBegin
	
Found0A:
	sub 	di, 2				; Talvez será preciso alterar
FoundBeg:
	mov 	dh, [LinSaved]
	mov 	dl, 12
	dec 	dh
	mov 	[CursorRaw], dh
	call 	GetZeroTextMemory
	cmp 	cx, ax
	jae 	JmpNegProcess
	
	sub 	cx, ax
	not 	cx
	inc 	cx
	sub 	di, cx				; DI aqui não precisa ser subtraído, já está na posição, ou mudar "sub di, 3" para "sub di, 2" em cima
	mov 	dl, [ColSaved]
	call 	Move_Cursor
	jmp 	FileEditor

JmpNegProcess:
	mov 	dl, 12
	add 	dl, al
	call 	Move_Cursor
	jmp 	FileEditor
	
; Rolar pra cima (descer o texto), salvar os bytes inferiores e recuperar bytes superiores
VerifyScrolledAbove:
	jmp 	FileEditor
	


ColSaved db 0
LinSaved db 0
AtualRaw db 0
	
; TODO: Fazer como o ArrorUp, só que ao inverso
WriteEditor.ArrowDown:
	jmp 	FileEditor
	
; Rolar pra baixo (subir o texto), salvar os bytes superiores e recuperar bytes inferiores
VerifyScrolledBelow:
	jmp 	FileEditor
	
PutZeroTextMemory:
	push	es
	pusha
	mov 	ax, 0xB800
	mov 	es, ax
	call 	Get_Cursor
	mov 	cx, dx
	xor 	bx, bx
	xor 	dx, dx
	mov 	ax, 160
	mov 	bl, ch
	mul 	bx
	shl 	cl, 1
	xor 	ch, ch
	add 	ax, cx
	mov 	di, ax
	mov 	byte[es:di], 0x00
	popa
	pop 	es
ret

GetZeroTextMemory:
	push	es
	pusha
	mov 	ax, 0xB800
	mov 	es, ax
	mov 	cx, dx
	xor 	bx, bx
	xor 	dx, dx
	mov 	ax, 160
	mov 	bl, ch
	mul 	bx
	shl 	cl, 1
	xor 	ch, ch
	add 	ax, cx
	mov 	di, ax
	cld
	mov 	cx, 112
	mov 	al, 0x00
	repne 	scasb
	mov 	ax, 112
	sub 	ax, cx
	shr 	ax, 1
	mov 	[CountToZero], ax
	popa
	pop 	es
	mov 	ax, [CountToZero]
ret

FillZeroTextMemory:
	push	es
	pusha
	mov 	ax, 0xB800
	mov 	es, ax
	call 	Get_Cursor
	push 	dx
	mov 	cx, dx
	xor 	bx, bx
	xor 	dx, dx
	mov 	ax, 160
	mov 	bl, ch
	mul 	bx
	shl 	cl, 1
	xor 	ch, ch
	add 	ax, cx
	mov 	di, ax
	xor 	cx, cx
	pop 	dx
	
	sub 	dh, 5
	mov 	cl, 18
	sub 	cl, dh
	push 	cx
	sub 	dl, 12
	mov 	cl, 56
	sub 	cl, dl
	mov 	al, 0
	cld
	jmp 	putzeros2
putzeros1:
	push 	cx
	mov 	cx, 56
putzeros2:
	stosb
	inc 	di
	loop 	putzeros2
	add 	di, (12*2*2)
	pop 	cx
	loop 	putzeros1
	popa
	pop 	es
ret

CountToZero dw 0
args_error   db "ERROR: parametro invalido - faltam aspas.",0


Cmd.OPEN:
	mov 	si, BufferArgs
	mov 	di, BufferKeys
	call 	Format_Command_Line
	
	push 	WORD[CD_SEGMENT]
	call 	Store_Dir
	
	mov 	cx, 1
	call 	Load_File_Path
	mov 	ax, 03h
	jc 		ErrorOpen
	
	mov 	ax, [CD_SEGMENT]
	mov 	dl, 00000010b
	mov 	dh, 2			; Usuário padrão
	call 	FAT16.OpenThisFile
	jc 		ErrorOpen
	
	mov 	[HandlerF], ax
	mov 	si, OpenSuccess
	call 	Print_String
	call 	Print_Hexa_Value16
	jmp 	Ret.OPEN
	
ErrorOpen:
	cmp 	ax, 01h
	je 		NotAbled
	cmp 	ax, 02h
	je 		NotFound
	cmp 	ax, 03h
	je 		PathNotFound
	cmp 	ax, 04h
	je 		NoHandler
	cmp 	ax, 05h
	je 		DeniedAccess
	cmp 	ax, 0Ch
	je 		NotAllowed
UnknownError:
	mov 	si, UnknownMsg
	call 	Print_String
	clc
	jmp 	Ret.OPEN
NotAllowed:
	mov 	si, NotAllowedMsg
	call 	Print_String
	clc
	jmp 	Ret.OPEN
DeniedAccess:
	mov 	si, DeniedMsg
	call 	Print_String
	clc
	jmp 	Ret.OPEN
NoHandler:
	mov 	si, NoHandlerMsg
	call 	Print_String
	clc
	jmp 	Ret.OPEN
PathNotFound:
	call 	Cursor.CheckToRollEditor
	mov 	si, PathNFMsg
	call 	Print_String
	clc
	jmp 	Ret.OPEN
NotFound:
	mov 	si, NotFoundMsg
	call 	Print_String
	clc
	jmp 	Ret.OPEN
NotAbled:
	mov 	si, NotAbleMsg
	call 	Print_String
	clc
	
Ret.OPEN:
	pop 	WORD[CD_SEGMENT]
	call 	Restore_Dir
	ret
	
UnknownMsg db "Error: Erro desconhecido ao abrir o arquivo!",0
DeniedMsg  db "Error: Acesso Negado!",0
NoHandlerMsg db "Error: Nenhum manipulador disponivel!",0
PathNFMsg 	 db "Error: Caminho nao encontrado!",0
NotFoundMsg	 db "Error: Arquivo nao encontrado!",0
NotAbleMsg	 db "Error: Compartilhamento nao habilitado",0
NotAllowedMsg db "Error: Modo de acesso nao permitido!",0
OpenSuccess   db "O arquivo foi aberto! Handler: ",0

Cmd.DIVS:
	pusha
	
	inc 	si
	push 	si
	xor 	cx, cx
CountSI:
	inc 	cx
	inc 	si
	cmp 	byte[si], 0x20
	jne 	CountSI
	mov 	di, si
	pop 	si
	call 	Parse_Dec_Value
	mov 	[Numerator], eax
	
	mov 	si, di
	xor 	cx, cx
	inc 	si

	push 	si
CountSI2:
	inc 	cx
	inc 	si
	cmp 	byte[si], 0
	je 		StartDIV
	cmp 	byte[si], 0x20
	jne 	CountSI2
StartDIV:
	pop 	si
	call 	Parse_Dec_Value
	mov 	[Denominator], eax

	xor 	ecx, ecx
	mov 	eax, [Numerator]
	mov 	ebx, [Denominator]
	xor 	edx, edx
	div 	ebx
	call 	Print_Dec_Value32
	cmp 	edx, 0
	jz	 	Ret.DIVS
	mov 	ah, 0x0E
	mov 	al, ','
	int 	0x10
Mul10:
	inc 	ecx
	mov 	eax, edx
	mov 	ebx, 10
	xor 	edx, edx
	mul 	ebx
	mov 	ebx, [Denominator]
	xor 	edx, edx
	div 	ebx
	call 	Print_Dec_Value32
	cmp 	ecx, 32
	je 		Ret.DIVS
	cmp 	edx, 0
	jnz 	Mul10
Ret.DIVS:
	popa
	ret
	
Numerator 	dd 0
Denominator dd 0
Decimals    dq 0

Cmd.TEST:
	mov 	ax, 0x3000
	mov 	[FAT16.DirSegments], ax
	mov 	ax, 0x6800
	mov 	[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 0
	
	mov 	bx, [HandlerF]
	mov 	dx, BufferFile
	mov 	cx, SIZE_BUFFER
	call 	FAT16.LoadFile
	call 	Print_Hexa_Value16
	push 	ds
	pop 	es
	mov 	bx, ax
	mov 	byte[BufferFile + bx], '$'
	mov 	al, 1
	mov 	di, BufferFile
	call 	PrintData
	
Ret.TEST:
	ret
	
	BufferFile: times 101 db 0
	SIZE_BUFFER EQU ($ - BufferFile) - 1
	HandlerF 	dw 0x0000

Reload_Directory:
	pusha
	push 	es
	mov		ax, word[CD_SEGMENT]
	cmp 	ax, 0x0200
	je 		ReLoadDir
	
	mov 	si, ThisDir
	mov 	word[FAT16.DirSegments], ax
	mov 	bx, 0x0000
	mov 	word[FAT16.FileSegments], ax
	mov 	byte[FAT16.LoadingDir], 1
	push 	di
	call 	FAT16.LoadThisFile
	pop 	di
	jmp 	Ret.Reload

ReLoadDir:
	call 	FAT16.LoadDirectory
Ret.Reload:
	pop 	es
	popa
	ret

Cmd.HELP:
	mov 	ax, 0x3000
	mov 	es, ax
	mov 	di, Inf
	mov 	si, Vector.CMD_Names
	mov 	cx, COUNT_COMMANDS
	push 	di
ShowInConsole:
	;inc 	byte[CursorRaw]
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
	
	mov 	al, 0
	call 	PrintData
	add 	di, cx
	
	pop 	cx
	push 	di
	
	mov 	al, 0
	call 	NextInfo
	loop 	ShowInConsole
	
	pop 	di
	;inc 	byte[CursorRaw]
ret


NameSystem 	   db "KiddieOS Shell ",VERSION,0
LetterDisk     db " :",0
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
	 db "NAME FILE   | ATTRIB    | DATE/TIME          | SIZE",0
.Dir db " directory  ",0
.Arc db "archive    ",0
.Fol db " folder     ",0
.Vol db " volume ID  ",0
.Ron db "read-only  ",0
.Sys db "system     ",0
.Oth db " other      ",0
	
DiskParameter:
	.NumberOfCylinders   db "Number of Cylinders : 0x",0
	.NumberOfHeads       db "Number Of Heads     : 0x",0
	.SectorsPerTracks    db "Sectors Per Track   : 0x",0
	.NumberOfSectors     db "Number Of Sectors   : 0x",0
	

ProgExtension   db "KXE", "EXE", "APP"
EXTENSIONS_COUNT EQU ($ - ProgExtension) / 3

ProgTerminate1: db "Process exited after 0x"
.SizeTerm1      dw ($-ProgTerminate1)
ProgTerminate2: db " milliseconds with return value 0x"
.SizeTerm2      dw ($-ProgTerminate2)
	
WriteCanceled 	db "canceled by the user.",0
StringSave 	   db "This sequence save the data: ",0

COUNT_COMMANDS    EQU 22  ; <- A cada comando alterar era 21

Vector:

.CMD_Funcs:
	dw Cmd.EXIT, Cmd.REBOOT, Cmd.START, Cmd.BPB, Cmd.LF, Cmd.CLEAN, Cmd.READ
	dw Cmd.CD, Cmd.ASSIGN, Cmd.HELP,  Cmd.FAT, Cmd.HEX, Cmd.DISK, Cmd.WRITE
	dw Cmd.DIVS, Cmd.REN, Cmd.ATTRIB, Cmd.DEL, Cmd.MKDIR, Cmd.OPEN, Cmd.CHMOD
	dw Cmd.TEST
	
.CMD_Infos:
	dw Inf.EXIT, Inf.REBOOT, Inf.START, Inf.BPB, Inf.LF, Inf.CLEAN, Inf.READ
    dw Inf.CD, Inf.ASSIGN, Inf.HELP, Inf.FAT, Inf.HEX, Inf.DISK, Inf.WRITE
	dw Inf.DIVS, Inf.REN, Inf.ATTRIB, Inf.DEL, Inf.MKDIR, Inf.OPEN, Inf.CHMOD
	dw Inf.TEST
	
.CMD_Addrs:
	dw 	ADDR.EXIT
	dw	ADDR.REBOOT
	dw	ADDR.START
	dw 	ADDR.BPB
	dw 	ADDR.LF
	dw 	ADDR.CLEAN
	dw 	ADDR.READ
	dw 	ADDR.CD
	dw 	ADDR.ASSIGN
	dw 	ADDR.HELP
	dw 	ADDR.FAT
	dw 	ADDR.HEX
	dw 	ADDR.DISK
	dw 	ADDR.WRITE
	dw 	ADDR.DIV
	dw 	ADDR.REN
	dw 	ADDR.ATTRIB
	dw 	ADDR.DEL
	dw 	ADDR.MKDIR
	dw 	ADDR.OPEN
	dw 	ADDR.CHMOD
	dw 	ADDR.TEST
	
.CMD_Names:
	ADDR.EXIT 	db "exit",0   
	ADDR.REBOOT db "reboot",0
	ADDR.START  db "start",0
	ADDR.BPB 	db "bpb",0
	ADDR.LF		db "lf",0 
	ADDR.CLEAN	db "clean",0
	ADDR.READ	db "read ",0
	ADDR.CD		db "cd ",0
	ADDR.ASSIGN db "assign ",0
	ADDR.HELP	db "help",0
	ADDR.FAT	db "fat",0
	ADDR.HEX	db "hex",0
	ADDR.DISK 	db "disk",0
	ADDR.WRITE 	db "write",0
	ADDR.DIV 	db "div",0
	ADDR.REN 	db "ren",0
	ADDR.ATTRIB db "attrib",0
	ADDR.DEL 	db "del",0
	ADDR.MKDIR 	db "mkdir",0
	ADDR.OPEN 	db "open",0
	ADDR.CHMOD 	db "chmod",0
	ADDR.TEST 	db "test",0
	
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
.WRITE:
	db 1, "write com",0
.DIVS:
	db 1, "DIV command",0
.REN:
	db 1, "REN command",0
.ATTRIB:
	db 1, "ATT command",0
.DEL:
	db 1, "DEL command",0
.MKDIR:
	db 1, "MKD command",0
.OPEN:
	db 1, "OPN command",0
.CHMOD:
	db 1, "CHM command",0
.TEST:
	db 1, "TST command",0
	
END_OF_FILE:
	db 'EOF'

