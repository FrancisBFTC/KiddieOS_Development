ECHO OFF
cls

cd /
cd Users\USER\Desktop\D.S.O.S\KiddieOS

set VHD=KiddieOS
set ImageFile=DiskImage\%VHD%.vhd
set Drive=6
::33.553.920

cecho {0B}Escrevendo Sistema Operacional No Pendrive ...{\n}
rmpartusb drive=%Drive% filetousb file="%ImageFile%" filestart=0 length=2.215.936 usbstart=0
cecho {0A}O Sistema Foi Escrito Com Sucesso!{\n\n}
cecho {0F}