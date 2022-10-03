ECHO OFF
cls

move %USERPROFILE%\Desktop\KiddieOS\Autogen\*.exe %USERPROFILE%\AppData\Local\bin\NASM
SETX PATH "%PATH%;C:\Program Files (x86)\RMPrepUSB;" -M
pause