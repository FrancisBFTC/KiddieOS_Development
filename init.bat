ECHO OFF
CLS

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
	if %Choose% EQU 3 qemu-system-i386 -drive format=raw,file=C:\Users\USER\Desktop\D.S.O.S\KiddieOS\DiskImage\KiddieOS.vhd -m 1000 -boot order=dc -cpu core2duo -vga std -accel tcg,thread=single -smp 1 -audiodev id=sdl,driver=sdl -machine pcspk-audiodev=sdl
	
	cecho {\n}