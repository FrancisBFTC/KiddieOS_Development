echo OFF
cls

cd /
cd Users\CIDA\Desktop\KiddieOS

set ImageFile=DiskImage\KiddieOS.vhd

del %ImageFile%

echo Assembling binaries...
nasm -O0 -f bin -o Binary\bootmbr.bin bootmbr.asm
nasm -O0 -f bin -o Binary\bootvbr.bin bootvbr.asm
nasm -O0 -f bin -o FAT.bin FAT.asm
nasm -O0 -f bin -o Binary\footervhd.bin footervhd.asm
nasm -O0 -f bin -o Binary\kernel.bin kernel.asm
nasm -O0 -f bin -o Binary\fwriter.bin fwriter.asm
nasm -O0 -f bin -o Binary\fat16.bin fat16.asm
nasm -O0 -f bin -o Binary\window.bin window.asm
nasm -O0 -f bin -o Driver\keyboard.sys keyboard.asm

echo format image file with mbr and fat16...
dd count=2 seek=0 bs=512 if=Binary\bootmbr.bin of=%ImageFile%
dd count=2 seek=1 bs=512 if=Binary\bootvbr.bin of=%ImageFile%
dd count=2 seek=2 bs=512 if=FAT.bin of=%ImageFile%
dd count=2 seek=65537 bs=512 if=Binary\footervhd.bin of=%ImageFile%

echo Mounting disk image...
imdisk -a -f %ImageFile% -s 32769K -m B:

echo Copying kernel and applications to disk image...
::mkdir B:\Binary\
::xcopy /S /E Binary\kernel.bin B:\Binary
::xcopy /S /E Binary\fwriter.bin B:\Binary
copy Binary\kernel.bin B:
copy Binary\fwriter.bin B:
copy Binary\window.bin B:
copy Binary\fat16.bin B:
copy Driver\keyboard.sys B:

echo Dismounting disk image...
imdisk -D -m B:

cecho {0B}Send image file to the Drive 1{\n}
rmpartusb drive=1 filetousb file="%ImageFile%" filestart=0 length=33.558.528 usbstart=0
cecho {0A}Done!{\n}

set /p Choose="Do you want to run the VirtualBox?(S\N)"
if %Choose% EQU S VirtualBox\KiddieOSVHD.lnk
if %Choose% EQU s VirtualBox\KiddieOSVHD.lnk

echo Done!

