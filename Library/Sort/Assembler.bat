ECHO OFF
cls

echo Assembling Program...
nasm -O0 -f bin -o Program.bin Program.asm

