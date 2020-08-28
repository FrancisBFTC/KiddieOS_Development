ECHO OFF
cls

move %USERPROFILE%\Desktop\KiddieOS\Autogen\*.exe %USERPROFILE%\AppData\Local\bin\NASM
SETX PATH "%PATH%;C:\Program Files\RMPrepUSB;" -M
pause