REM KiddieOS Basic game test
REM Create by Wenderson Francisco

REM INCLUDE "gamelib.bas"
REM INCLUDE "math.bas"

REM GOSUB GET_VERSION
REM GOSUB GET_NAME_FILE

REM A = 5
REM B = 4
REM GOSUB ADD
REM PRINT A

REM B = 2
REM GOSUB SUB
REM PRINT A

REM SIZE "file.txt"
REM PRINT S

REM $2 = "File1,File2,File3,File4"
REM $3 = "Hello"
REM $4 = "Ola"
REM LISTBOX $2 $3 $4 A

SIZE $1
$2 = "O programa '" + $1 + "' tem " + S + " bytes!"

FINISH:
    END