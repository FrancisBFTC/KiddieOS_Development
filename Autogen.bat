ECHO OFF
cls

cd /
cd Users\USER\Desktop\D.S.O.S\KiddieOS

setlocal enabledelayedexpansion

set QuantFile=10

set Drive=6

set file1=kernel
set file2=fwriter
set file3=fat16
set file4=shell16
set file5=winmng
set file6=syscmng
set file7=keyboard
set file8=serial
set file9=pci
set file10=memx86

set filedir1=Src\Kernel\%file1%
set filedir2=Src\Kernel\%file2%
set filedir3=Src\Kernel\%file3%
set filedir4=Src\Kernel\%file4%
set filedir5=Src\Kernel\%file5%
set filedir6=Src\Kernel\%file6%
set filedir7=Src\Drv\%file7%
set filedir8=Src\Drv\%file8%
set filedir9=Src\Drv\%file9%
set filedir10=Src\Drv\%file10%

set filebin1=Bin\Kernel\kernel.osf
set filebin2=Bin\Kernel\fwriter.osf
set filebin3=Bin\Kernel\fat16.osf
set filebin4=Bin\Kernel\shell16.osf
set filebin5=Bin\Kernel\winmng.osf
set filebin6=Bin\Kernel\syscmng.osf
set filebin7=Bin\Drv\keyboard.drv
set filebin8=Bin\Drv\serial.drv
set filebin9=Bin\Drv\pci.drv
set filebin10=Bin\Drv\memx86.drv

set NameSystem=KiddieOS
set LibFile=Hardware\memory.lib
set ImageVHD=ISO\%NameSystem%.vhd
set ImageISO=ISO\%NameSystem%.iso
set OffsetPartition=0
::set OffsetPartition=61173

del %ImageVHD%


set /A nasm=0
set SizeSector=512

	set /p Choose="Do you want to reassemble the FAT16 and MBR?(S\N)"
	if %Choose% EQU S CALL :ReassembleFAT
	if %Choose% EQU s CALL :ReassembleFAT
	
	call ::SendFatToVHD
	
cecho {\n}

:Assembler
	set /a i=i+1
	set "NameVar=filebin%i%"
	set "NameVar1=file%i%"
	set "NameVar2=filedir%i%"
	call set FileOut=%%%NameVar%%%
	call set MyFile=%%%NameVar1%%%
	call set MyFile2=%%%NameVar2%%%
	cecho {0C}
	if NOT EXIST %MyFile2%.asm goto NoExistFile 
	nasm -O0 -f bin %MyFile2%.asm -o %FileOut%
	if %ERRORLEVEL% EQU 1 goto BugCode
	cecho {#}
	if %nasm% NEQ 1 (cecho {0B}"%MyFile%" file Mounted successfully!{\n}) else ( cecho {0B}.)
	if %i% NEQ %QuantFile% goto Assembler
	if %nasm% NEQ 0 GOTO:EOF
	
	set i=0
	set Sector=531
	set Segment=0x3000   rem Segmento do kernel
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

	for /l %%g in (1, 1, %size%) do (

		if !Counter! == 512 ( 
			set /A Counter=1
			set /A NumSectors+=1
			cecho {0A}.
		)
		set /A Counter=Counter+1
	)

set /A "W=0"
	echo.
	
	if %i% == 1 set /A StartAddr=Kernel
	if %i% GEQ 2 set /A StartAddr=FinalAddr+2
	set /A FinalAddr=StartAddr+size
	call :ToHex
	call :WriteDefLib
	
	cecho {0F} SIZE BYTES     = {0D}%size%{#}{\n}
	cecho {0F} INIT SECTOR    = {0D}%Sector%{#}{\n}
	cecho {0F} QUANT. SECTORS = {0D}%NumSectors%{#}{\n}
	cecho {0F} START ADDRESS  = {0D}%StartAddr%{#}{\n}
	cecho {0F} FINAL ADDRESS  = {0D}%FinalAddr%{#}{\n}
	
	set /A Sector+=NumSectors
	
	if %i% NEQ %QuantFile% goto ReadFile
	
	call :WriteEndDef
	call :ReAssembler
	call :VHDCreate
	call :BootFlashDrive
	
	cecho {\n}
	echo Which virtual machine do you want to run?
	echo.
	echo 1. KiddieOSUSB - VirtualBox
	echo 2. KiddieOSVHD - VirtualBox
	echo 3. KiddieOS.VHD - QEMU
	echo 0. Nothing
	echo.
	set /p Choose=
	if %Choose% EQU 1 VBoxManage.exe startvm  --putenv VBOX_GUI_DBG_ENABLED=true KiddieOS_USB
	if %Choose% EQU 2 VBoxManage.exe startvm  --putenv VBOX_GUI_DBG_ENABLED=true KiddieOS_VHD
	if %Choose% EQU 3 qemu-system-i386 -drive format=raw,file=C:\Users\USER\Desktop\D.S.O.S\KiddieOS\ISO\KiddieOS.vhd -m 2000M -boot order=dc -cpu core2duo -vga std -accel tcg,thread=single -smp 1 -audiodev id=sdl,driver=sdl -machine pcspk-audiodev=sdl
	
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
	pause
	goto END
	
:NoExistFile
	echo.
	echo The '%MyFile%.asm' File not exist!
	cecho {0F}
	echo.
	pause
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
	call :AssemblingPrograms
	call :CopyBinaries
	
	cecho {\n}
	cecho {0A}%i% Binary Files remounted successfully{\n\n}
	cecho {0F}
GOTO:EOF

:AssemblingPrograms

	:: Compilação de APIs do sistema & Aplicações
	cd Lib\MikeOS\
	nasm -O0 -f bin -o ..\..\Bin\API\MikeOS.api MikeOS.asm

	cd ..\..\

	:: Compilação de gerenciadores
	cd Src/Mgrs/
	nasm -O0 -f bin -o ..\..\KiddieOS/Programs/winmgr32.kxe winmgr32.asm
	nasm -O0 -f bin -o ..\..\KiddieOS\Programs\filemgr.osf filemgr.asm
	cd ..\..\


	:: Compilação de aplicações usando NASM
	cd Apps\
	nasm -O0 -f bin -o ..\KiddieOS\Programs\Program.kxe Program.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\Devmgr.kxe 	Devmgr.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\netapp.kxe 	netapp.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\Prog1.kxe 	Prog1.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\area.kxe 	area.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\Args.kxe 	args.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\Data.kxe 	data.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\Calc.kxe 	Calc.asm
	nasm -O0 -f bin -o ..\KiddieOS\Programs\basic.bin 	basic.asm
	cd ..\

	:: Compilação de aplicações usando FASM
	cd Apps\
	fasm prog.asm ..\KiddieOS\Programs\dos.exe
	fasm code.asm ..\KiddieOS\Programs\code.exe
	fasm fruitfly.asm ..\KiddieOS\Programs\fruitfly.exe
	fasm test.asm ..\KiddieOS\Programs\test.sxe
	cd ..\

	::fasm Library\FASM\DOS\fasm.asm KiddieOS\Programs\Init\fasm.exe
	::fasm kiddieos\sounds\player.asm
	::fasm kiddieos\sounds\sb16.asm kiddieos\sounds\play.exe
	::fasm winsetup.asm KiddieOS\Users\winsetup.exe
	::fasm birth.asm KiddieOS\Users\birth.exe
	::copy kiddieos\sounds\play.exe C:\dosprogs\play.exe
	::copy kiddieos\sounds\player.exe C:\dosprogs\player.exe
GOTO:EOF

:CopyBinaries
	copy Bin\Kernel\*.* KiddieOS\System16\
	copy Bin\Boot\*.* KiddieOS\System16\BootMGR\
	copy Bin\Drv\*.* KiddieOS\Drivers\
	copy Bin\API\*.* KiddieOS\Library\
	del KiddieOS\System16\BootMGR\bootfat.osf
GOTO:EOF
	
::32769K
:VHDCreate	
	cecho {0A}Mounting VHD file...{\n}
	cecho {0B}
	imdisk -a -f %ImageVHD% -s 33553920 -m Z:  
	set i=0
	:Creating
		set /a i=i+1
		set "Var1=filebin%i%"
		set "Var3=file%i%"
		call set BinFile=%%%Var1%%%
		call set Bin=%%%Var3%%%
		
		cecho {0B}Adding '%Bin%' to the VHD file{\n}
		copy %BinFile% Z:
		
		if %i% NEQ %QuantFile% goto Creating
		
		xcopy /I /E KiddieOS Z:\KiddieOS
		
		copy Bin\API\*.* Z:
		
		cecho {0A}Dismounting VHD file...{\n}
		cecho {0B}
		cecho {0A}{\n}Creating VHD file...{\n}
		cecho {0A}{\n}Creating ISO file...{\n}
		mkisofs -o %ImageISO% Z:
		imdisk -D -m Z:
		
		cecho {0A}{\n}The '%VHD%.vhd' was created successfully!{\n\n}
GOTO:EOF

:ReassembleFAT
cecho {0B} Assembling FAT16 and MBR...{\n}
cd Src\Boot\FAT16\
nasm -O0 -f bin -o ..\..\..\Bin\Boot\bootmbr.osf bootmbr.asm
nasm -O0 -f bin -o ..\..\..\Bin\Boot\bootvbr.osf bootvbr.asm
nasm -O0 -f bin -o ..\..\..\Bin\Boot\bootlib.osf bootlib.asm
nasm -O0 -f bin -o ..\..\..\Bin\Boot\bootfat.osf bootfat.asm
nasm -O0 -f bin -o ..\..\..\Bin\Boot\volume.osf  volume.asm
nasm -O0 -f bin -o ..\..\..\Bin\Boot\footvhd.osf footvhd.asm
cd ..\..\..\
GOTO:EOF

:SendFatToVHD
cecho {0B}Sending FAT16 and MBR into VHD...{\n}
dd count=2 seek=0 bs=512 if=Bin\Boot\bootmbr.osf of=%ImageVHD%
dd count=2 seek=1 bs=512 if=Bin\Boot\bootlib.osf of=%ImageVHD%
dd count=2 seek=3 bs=512 if=Bin\Boot\bootvbr.osf of=%ImageVHD%
dd count=2 seek=7 bs=512 if=Bin\Boot\bootfat.osf of=%ImageVHD%
dd count=2 seek=499 bs=512 if=Bin\Boot\volume.osf of=%ImageVHD%
dd count=2 seek=65534 bs=512 if=Bin\Boot\footvhd.osf of=%ImageVHD%
cecho {0A}Done!{\n}

cls
GOTO:EOF
	

:BootFlashDrive
	cecho {0B}Writing system in Disk (Drive %Drive%) ...{\n}
	rmpartusb drive=%Drive% filetousb file="%ImageVHD%" filestart=0 length=33.553.920 usbstart=0
	cecho {0A}The System was written successfully{\n\n}
	cecho {0F}
GOTO:EOF


:END
	