ECHO OFF
cls

setlocal enabledelayedexpansion

set QuantFile=4

set Drive=6

set file1=bootloader
set file2=kernel
set file3=window
set file4=keyboard

set filebin1=Binary\%file1%.bin
set filebin2=Binary\%file2%.bin
set filebin3=Binary\%file3%.bin
set filebin4=Driver\%file4%.sys

set IMG=KiddieOS
set Local=C:\Users\BFTC\Desktop\KiddieOS
set LibFile=Hardware\memorys.lib
set ImageFile=DiskImage\%IMG%.img


set /A nasm=0
set SizeSector=512

:Assembler
	set /a i=i+1
	set "NameVar=filebin%i%"
	set "NameVar1=file%i%"
	call set FileOut=%%%NameVar%%%
	call set MyFile=%%%NameVar1%%%
	cecho {0C}
	if NOT EXIST %MyFile%.asm goto NoExistFile 
	nasm -f bin %MyFile%.asm -o %FileOut%
	if %ERRORLEVEL% EQU 1 goto BugCode
	cecho {#}
	if %nasm% NEQ 1 (cecho {0B}"%MyFile%" file Mounted successfully!{\n}) else ( cecho {0B}.)
	if %i% NEQ %QuantFile% goto Assembler
	if %nasm% NEQ 0 GOTO:EOF
	
	set i=0
	set Sector=1
	set Segment=0x0800   rem Segmento do kernel
	set Boot=0x7C00      rem Offset do Inicial Bootloader
	set Kernel=0x0000    rem Offset Inicial Do Kernel
	call :AutoGenerator
	
:ReadFile
	set /a i=i+1
	set "NameVar=filebin%i%"
	set "NameVar1=file%i%"
	call set FileOut=%%%NameVar%%%
	call set MyFile=%%%NameVar1%%%
	
	for %%a in (dir "%FileOut%") do set size=%%~za
	cecho {0A}Processing '%MyFile%'

	set /A Counter=1
	set /A NumSectors=1
	::set /A Bytes=1
::loop
	for /l %%g in (1, 1, %size%) do (

::set /A Bytes+=1
		if !Counter! == 512 ( 
			set /A Counter=1
			if %i% NEQ 1 set /A NumSectors+=1
			cecho {0A}.
		)
		set /A Counter=Counter+1
	)
::if %Bytes% NEQ %size% goto loop
set /A "W=0"
	echo.
	
	if %i% == 1 set /A StartAddr=Boot
	if %i% == 2 set /A StartAddr=Kernel
	if %i% GEQ 3 set /A StartAddr=FinalAddr+2
	set /A FinalAddr=StartAddr+size
	call :ToHex
	call :WriteDefLib
	
	cecho {0F} SIZE BYTES     = {0D}%size%{#}{\n}
	cecho {0F} INIT SECTOR    = {0D}%Sector%{#}{\n}
	cecho {0F} QUANT. SECTORS = {0D}%NumSectors%{#}{\n}
	cecho {0F} START ADDRESS  = {0D}%StartAddr%{#}{\n}
	cecho {0F} FINAL ADDRESS  = {0D}%FinalAddr%{#}{\n}
	
	set /A Sector+=NumSectors
	set /A "seek%i%=Sector-1"
	
	if %i% NEQ %QuantFile% goto ReadFile
	
	call :WriteEndDef
	call :ReAssembler
	call :ImgCreate
	call :BootFlashDrive
	
	cecho {\n}
	set /p Choose="Do you want to run the VirtualBox?(S\N)"
	if %Choose% EQU S VirtualBox\%IMG%.lnk
	if %Choose% EQU s VirtualBox\%IMG%.lnk
	
	cecho {\n}
	goto END
	
:ToHex
set "hex="
set "map=0123456789ABCDEF"
for /L %%N in (1,1,4) do (
   set /a "d=StartAddr&15,StartAddr>>=4"
   for /f %%D in ("!d!") do (
      set "hex=!map:~%%D,1!!hex!"
   )
)
set "StartAddr=0x%hex%"
set "hex="
for /L %%N in (1,1,4) do (
   set /a "d=FinalAddr&15,FinalAddr>>=4"
   for /f %%D in ("!d!") do (
      set "hex=!map:~%%D,1!!hex!"
   )
)
set "FinalAddr=0x%hex%"
GOTO:EOF

:BugCode
	echo.
	echo Fix the Error in the file!
	cecho {0F}
	echo.
	goto END
	
:NoExistFile
	echo.
	echo The '%MyFile%.asm' File not exist!
	cecho {0F}
	echo.
	goto END
	
:AutoGenerator
	echo ; =============================================== > %LibFile%
	echo ; AUTO GENERATED FILE - NOT CHANGE! >> %LibFile%
	echo ; >> %LibFile%
	echo ; KiddieOS - Memory Library Routines >> %LibFile%
	echo ; Created by Autogen >> %LibFile%
	echo ; Version 1.0.0 >> %LibFile%
	echo ; =============================================== >> %LibFile%
	echo. >> %LibFile%
	echo %%IFNDEF _MEMORY_LIB_ >> %LibFile%
	echo %%DEFINE _MEMORY_LIB_ >> %LibFile%
	echo. >> %LibFile%
	echo %%DEFINE SYSTEM 16 >> %LibFile%
	echo. >> %LibFile%
	GOTO:EOF
	
:WriteDefLib
	CALL :UpCase MyFile
	echo %%DEFINE !MyFile!             !StartAddr! >> %LibFile%
	echo %%DEFINE !MyFile!_SECTOR      !Sector! >> %LibFile%
	echo %%DEFINE !MyFile!_NUM_SECTORS !NumSectors! >> %LibFile%
	GOTO:EOF
	
:WriteEndDef
	echo. >> %LibFile%
	echo %%ENDIF >> %LibFile%
	echo. >> %LibFile%
	cecho {\n}New "%LibFile%" LIB File Generated{\n}
	GOTO:EOF
		
:UpCase
SET %~1=!%~1:a=A!
SET %~1=!%~1:b=B!
SET %~1=!%~1:c=C!
SET %~1=!%~1:d=D!
SET %~1=!%~1:e=E!
SET %~1=!%~1:f=F!
SET %~1=!%~1:g=G!
SET %~1=!%~1:h=H!
SET %~1=!%~1:i=I!
SET %~1=!%~1:j=J!
SET %~1=!%~1:k=K!
SET %~1=!%~1:l=L!
SET %~1=!%~1:m=M!
SET %~1=!%~1:n=N!
SET %~1=!%~1:o=O!
SET %~1=!%~1:p=P!
SET %~1=!%~1:q=Q!
SET %~1=!%~1:r=R!
SET %~1=!%~1:s=S!
SET %~1=!%~1:t=T!
SET %~1=!%~1:u=U!
SET %~1=!%~1:v=V!
SET %~1=!%~1:w=W!
SET %~1=!%~1:x=X!
SET %~1=!%~1:y=Y!
SET %~1=!%~1:z=Z!
GOTO:EOF

:ReAssembler
	set i=0
	set /A nasm=1
	echo.
	cecho {0B}Remounting Binary Files.
	call :Assembler
	cecho {\n}
	cecho {0A}%i% Binary Files remounted successfully{\n\n}
	cecho {0F}
	GOTO:EOF

:ImgCreate
	cecho {0B}Creating IMG Floppy file{\n}
	dd if=/dev/zero of=%ImageFile% bs=1024 count=1440
	
	
	::conv=notrunc
	cecho {0B}Adding '%file1%' to the IMG file{\n}
	dd if=%filebin1% of=%ImageFile%
	
	set i=0
	set /A QuantFile-=1
	
	:Creating
		set /a i=i+1
		set /a j=i+1
		set "Var1=filebin%j%"
		set "Var2=seek%i%"
		set "Var3=file%j%"
		call set BinFile=%%%Var1%%%
		call set Seek=%%%Var2%%%
		call set Bin=%%%Var3%%%
		
		::conv=notrunc
		cecho {0B}Adding '%Bin%' to the IMG file{\n}
		dd if=%BinFile% of=%ImageFile% bs=%SizeSector% seek=%Seek%
		
		if %i% NEQ %QuantFile% goto Creating
		
		cecho {0A}{\n}The '%IMG%.img' was created successfully!{\n\n}

GOTO:EOF

:BootFlashDrive
	
	cecho {0B}Writing system in Disk (Drive %Drive%) ...{\n}
	rmpartusb drive=%Drive% filetousb file="%ImageFile%" filestart=0 length=1.474.560 usbstart=0
	cecho {0A}The System was written successfully{\n\n}
	cecho {0F}
GOTO:EOF

:END
	pause