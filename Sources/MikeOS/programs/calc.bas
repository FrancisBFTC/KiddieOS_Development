rem Calculator Application (CALC.BAS)
rem A simple calculator application.
rem Version 2.1.0
rem Made by Joshua Beck
rem Released under the GNU General Public Licence version 3
rem Send any bugs, ideas or comments to zerokelvinkeyboard@gmail.com

rem Uses the MB++ Library version 4.0
rem Avaliable at code.google.com/p/mikebasic-applications
INCLUDE "MBPP.BAS"

START:
  CLS
  REM MB++ initialise function
  GOSUB STARTPRG
  REM set the text colour and highlight (for the menu)
  C = 3
  H = 11
  REM set the box colour
  T = 2
  MOVE 30 13
  PRINT "Calculating..."
GOTO MAIN

MAIN:
  REM main menu
  $5 = "Calculator"
  $6 = "Simple Calculations|Advanced Maths|Change Colour Scheme|About|Exit"
  GOSUB MENUBOX
  IF V = 1 THEN GOSUB BASEMATH
  IF V = 2 THEN GOSUB ADVMATH
  IF V = 3 THEN GOSUB COLCHANGE
  IF V = 4 THEN GOSUB ABOUT
  IF V = 5 THEN GOSUB ENDPROG
GOTO MAIN

COLCHANGE:
  $5 = "Change Colour Scheme"
  $6 = "Input a new colour for outline, 1-255"
  $7 = "Input a new text colour, 1-15"
  V = 0
  GOSUB DINBOX
  $8 = "Invalid colour"
  IF A < 1 THEN GOTO ERRBOX
  IF A > 255 THEN GOTO ERRBOX
  IF B < 1 THEN GOTO ERRBOX
  IF B > 15 THEN GOTO ERRBOX
  T = A
  C = B
  $6 = "Input a new highlight colour, 1-15"
  V = 0
  GOSUB INPBOX
  $8 = "Invalid colour"
  IF V < 1 THEN GOTO ERRBOX
  IF V > 15 THEN GOTO ERRBOX
  H = V
RETURN
  
BASEMATH:
  REM start the menu loop
  DO
    REM set the menu title
    $5 = "Simple Calculations"
    REM set items in the menu
    $6 = "Addition|Subtraction|Multiplication|Division|Back"
    REM call a menu
    GOSUB MENUBOX
    REM find out what they selected and gosub there
    IF V = 1 THEN GOSUB ADD
    IF V = 2 THEN GOSUB SUB
    IF V = 3 THEN GOSUB MUL
    IF V = 4 THEN GOSUB DIV
  REM present the menu again unless 'back' was selected
  LOOP UNTIL V = 5
  V = 0
RETURN

ADD:
  REM INPBOX and DINBOX use V to choose between text and numerical input
  REM we want numerical
  V = 0
  REM set the title
  $5 = "Addition"
  REM first input prompt
  $6 = "Input first number..."
  REM second input prompt
  $7 = "Input second number..."
  REM DINBOX is similar to INPBOX (Print text and asks for input) but
  REM it asks for two inputs rather than just one.
  GOSUB DINBOX
  REM do the actual calculation
  REM the first input is A and the second is B
  a = a + b
  REM prompt above first number
  $6 = "Answer is:"
  REM prompt about second
  REM this is set to a blank string so it won't print it (we only need one)
  $7 = ""
  REM call a number box to print our answer
  GOSUB NUMBOX
  REM back to main menu
RETURN

SUB:
  V = 0
  $5 = "Subtraction"
  $6 = "Input number to subtract from..."
  $7 = "Input number to subtract..."
  GOSUB DINBOX
  A = A - B
  $6 = "Answer is:"
  $7 = ""
  GOSUB NUMBOX
RETURN

MUL:
  V = 0
  $5 = "Multiplication"
  $6 = "Input first number..."
  $7 = "Input second number..."
  GOSUB DINBOX
  A = A * B
  $6 = "Answer is:"
  $7 = ""
  GOSUB NUMBOX
RETURN

DIV:
  V = 0
  $5 = "Division"
  $6 = "Input number to be divided..."
  $7 = "Input number to divide by..."
  GOSUB DINBOX
  REM define error message
  REM if the divisor is zero then present this error
  $8 = "Attempted to divide by zero!"
  IF B = 0 THEN GOTO ERRBOX
  D = A / B
  E = A % B
  A = D
  B = E
  $6 = "Answer is:"
  $7 = "Reminder is:"
  GOSUB NUMBOX
RETURN

ADVMATH:
  DO
    $5 = "Advanced Maths"
    $6 = "Square/Cube Number|Power|Mass Addition|Mass Subtraction|Back"
    GOSUB MENUBOX
    IF V = 1 THEN GOSUB SQUARE
    IF V = 2 THEN GOSUB POWER
    IF V = 3 THEN GOSUB MASSADD
    IF V = 4 THEN GOSUB MASSTAKE
  LOOP UNTIL V = 5
  V = 0
RETURN

SQUARE:
  $5 = "Square/Cube Number"
  $6 = "|Input a number to square and cube"
  V = 0
  GOSUB INPBOX
  A = V
  D = A
  A = A * D
  B = A * D
  $5 = "Square/Cube Number"
  $6 = "Number Squared is:"
  $7 = "Number Cubed is:"
  GOSUB NUMBOX
RETURN

POWER:
  $5 = "Power"
  $6 = "Input a number"
  $7 = "Input power to raise to"
  V = 0
  GOSUB DINBOX
  D = A
  IF B = 0 THEN A = 1
  IF B = 0 THEN GOTO POWERSKIP
  IF B = 1 THEN GOTO POWERSKIP
  DO
    A = A * D
    B = B - 1
  LOOP UNTIL B = 1
  POWERSKIP:
  $5 = "Power"
  $6 = "Answer is:"
  $7 = ""
  GOSUB NUMBOX
RETURN

MASSADD:
  $5 = "Mass Add"
  $6 = "Enter the base number"
  $7 = "Enter the first number to add"
  V = 0
  GOSUB DINBOX
  N = A
  N = N + B
ADDMORE:
  $5 = "Mass Add"
  $6 = "Enter another number to add|or zero to finish the sum"
  V = 0
  GOSUB INPBOX
  N = N + V
  IF V > 0 THEN GOTO ADDMORE
  $6 = "The base number was: "
  $7 = "The total was: "
  B = N
  GOSUB NUMBOX
RETURN

MASSTAKE:
  $5 = "Mass Subtract"
  $6 = "Enter the base number"
  $7 = "Enter the first number to take"
  V = 0
  GOSUB DINBOX
  N = A
  N = N - B
TAKEMORE:
  $5 = "Mass Subtract"
  $6 = "Enter another number to take|or zero to finish the sum"
  V = 0
  GOSUB INPBOX
  N = N - V
  IF V > 0 THEN GOTO TAKEMORE
  $6 = "The base number was: "
  $7 = "The total was: "
  B = N
  GOSUB NUMBOX
RETURN 

ABOUT:
  REM About message (strings have an 128 character limit)
  MOVE 0 0
  $5 = "About"
       $6 = "Calculator, version 2.1.0|"
  $6 = $6 + "An advanced calculator application|"
  $6 = $6 + "Released under the GNU GPL v3|\7"
       $7 = "Written in MikeOS BASIC|"
  $7 = $7 + "Uses the MB++ Library, version 4.0"
  GOSUB MESBOX
RETURN
