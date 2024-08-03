REM >>>MIKEBASIC-PLUS-PLUS-LIBRARY<<<
REM Library Version 4.1.0
REM Copyright (C) Joshua Beck.
REM Email: zerokelvinkeyboard@gmail.com
REM Licenced under the GNU General Public Licence revision 3.
REM Requires MikeOS version 4.5 or later.

REM Wiki: https://github.com/ZeroKelvinKeyboard/MikeOS-Apps/wiki/mbppdoc

PRINT "MB++ Library version 4.1.0"
END

ANCITEXT:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  ink c
  W = X
  POKE Y 65430
  CURSPOS X Y
  POKE X 65431
  DO
    IF X > W THEN X = 79
    if x > 78 then y = y + 1
    if x > 78 then peek x 65431
    PEEK J 65430
    IF Y > J THEN J = 0
    IF Y > 23 THEN J = 0
    move x y
    IF J > 0 THEN PEEK J V
    IF J = 0 THEN W = J + 1
    IF J < 20 THEN GOSUB ANCITXTS
    IF J > 0 THEN PRINT CHR J
    x = x + 1
    v = v + 1
  LOOP UNTIL W > J
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN
  
ANCITXTS:
  IF J = 0 THEN RETURN
  IF J = 1 THEN V = V + 1
  IF J = 1 THEN J = 255
  IF J = 7 THEN J = 255
  IF J = 10 THEN Y = Y + 1
  IF J = 10 THEN PEEK X 65431
  IF J = 10 THEN V = V + 1
  IF J = 10 THEN GOTO ANCITEX2
RETURN

ARRAYGET:
  POKEINT J 65418
  IF X > 99 THEN $8 = "ARRAYGET: Array over maximum"
  IF X > 99 THEN GOTO ERRBOX
  IF X < 0 THEN $8 = "ARRAYGET: Number below zero"
  IF X < 0 THEN GOTO ERRBOX
  J = X
  J = J * 2
  J = J + 65000
  PEEKINT V J
  PEEKINT J 65418
RETURN

ARRAYPUT:
  POKEINT J 65418
  IF X > 99 THEN $8 = "ARRAYGET: Array over maximum"
  IF X > 99 THEN GOTO ERRBOX
  IF X < 0 THEN $8 = "ARRAYGET: Number below zero"
  IF X < 0 THEN GOTO ERRBOX
  J = X
  J = J * 2
  J = J + 65000
  POKEINT V J
  PEEKINT J 65418
RETURN

ASKBOX:
  GOSUB OPENBOX
  MOVE 22 11
  GOSUB BOXPRINT
  move 27 16
  print "--Yes--        --No--"
  poke 1 65420
  V = 1
  gosub askdraw
  askloop:
    waitkey j
    if j = 3 then gosub swleft
    if j = 4 then gosub swright
    if j = 13 then goto askend
  goto askloop
askend:
  peek v 65420
  j = v
  if j = 0 then v = 1
  if j = 1 then v = 0
  GOSUB CLOSEBOX
  return
swleft:
  peek v 65420
  if v = 0 then return
  if v = 1 then v = 0
  poke v 65420
  gosub askdraw
  return
swright:
  peek v 65420
  if v = 1 then return
  if v = 0 then v = 1
  poke v 65420
  gosub askdraw
  return
askdraw:
  move 27 16
  if v = 0 then ink h
  if v = 1 then ink c
  print "--Yes--"
  move 42 16
  if v = 0 then ink c
  if v = 1 then ink h
  print "--No--"
return

BOXPRINT:
  GOSUB SAVEVAR
  X = 64146
  Y = 64151
  FOR W = 1 TO 5
    POKE 0 X
    POKE 22 Y
    X = X + 1
    Y = Y + 1
  NEXT W
  X = & $6
  W = 36
  Y = 0
  DO
    PEEK V X
    X = X + 1
    IF V = '|' THEN GOTO BOXNEWLN
    IF V = '\' THEN GOTO BOXOPT
    PRINT CHR V ;
    W = W - 1
    IF W < 1 THEN GOTO BOXNEWLN
    IF Y = 0 AND Y > 32 THEN GOSUB BOXPOFFS
    IF Y = 0 AND Y < 32 THEN GOSUB BOXPOFFS
    BOXPRNT2:
  LOOP UNTIL V = 0
  IF V > 15 THEN GOTO BOXPRNT3
  CURSPOS J V
  J = J - 22
  W = V - 11 + 64151
  POKE J W
  BOXPRNT3:
  GOSUB LOADVAR
  RETURN

BOXPOFFS: 
  CURSPOS J V
  V = V - 11 + 64146
  POKE J V
  Y = 1
  RETURN
  
BOXOPT:
  PEEK V X
  X = X + 1
  IF V = '1' THEN X = & $1
  IF V = '2' THEN X = & $2
  IF V = '3' THEN X = & $3
  IF V = '4' THEN X = & $4
  IF V = '5' THEN X = & $5
  IF V = '7' THEN X = & $7
  IF V = 't' THEN GOTO BOXTAB
  GOTO BOXPRNT2
  
BOXTAB:
  CURSPOS J V
  J = J / 8 + 1 * 8
  MOVE J V
  W = 58 - J
  V = 1
  GOTO BOXPRNT2

BOXNEWLN:
  CURSPOS J V
  J = J - 22
  W = V - 11 + 64151
  POKE J W
  J = 22
  V = V + 1
  MOVE J V
  W = 36
  IF V > 15 THEN GOTO BOXLIMIT
  Y = 0
  GOTO BOXPRNT2
  
BOXLIMIT:
  V = 0
  GOTO BOXPRNT2

BORDER:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  INK Z
  FOR Y = 0 TO 24
    IF Y = 0 THEN PEEK V 64160
    ELSE IF Y = 2 THEN PEEK V 64162
    ELSE IF Y = 24 THEN PEEK V 64164
    ELSE PEEK V 64166
    MOVE 0 Y
    PRINT CHR V ;
    IF Y = 0 THEN PEEK V 64161
    ELSE IF Y = 2 THEN PEEK V 64163
    ELSE IF Y = 24 THEN PEEK V 64165
    ELSE PEEK V 64166
    MOVE 79 Y
    PRINT CHR V ;
  NEXT Y
  PEEK V 64167
  FOR X = 1 TO 78
    MOVE X 0
    PRINT CHR V ;
    MOVE X 2
    PRINT CHR V ;
    MOVE X 24
    PRINT CHR V ;
  NEXT X
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN

BORDERDATA:
218 191 195 180 192 217 179 196

BOX:
  INK T
  FOR Y = 8 TO 17
    IF Y = 8 THEN PEEK V 65400
    ELSE IF Y = 10 THEN PEEK V 65402
    ELSE IF Y = 17 THEN PEEK V 65404
    ELSE PEEK V 65406
    MOVE 20 Y
    PRINT CHR V ;
    IF Y = 8 THEN PEEK V 65401
    ELSE IF Y = 10 THEN PEEK V 65403
    ELSE IF Y = 17 THEN PEEK V 65405
    ELSE PEEK V 65406
    MOVE 59 Y
    PRINT CHR V ;
  NEXT Y
  PEEK V 65407
  FOR X = 21 TO 58
    MOVE X 8
    PRINT CHR V ;
    MOVE X 10
    PRINT CHR V ;
    MOVE X 17
    PRINT CHR V ;
  NEXT X
  INK C
  move 21 9
  print "                                      "
  for x = 11 to 16
    move 21 x
    print "                                      "
  next x
RETURN

BOXDATA:
  201 187 204 185 200 188 186 205

BOXSAVE:
  INK 0
  V = 64200
  j = 64600
  for y = 8 to 17
    move 20 y
    for x = 20 to 59
      curschar w
      poke w j
      CURSCOL W
      POKE W V
      print " ";
      j = j + 1
      V = V + 1
    next x
  next y
return

BOXREST:
  V = 64200
  j = 64600
  for y = 8 to 17
    MOVE 20 Y
    for x = 20 to 59
      PEEK W V
      INK W
      peek w j
      print chr w ;
      j = j + 1
      V = V + 1
    next x
  next y
return

CLOSEBOX:
  POKE V 65418
  CURSOR OFF
  INK 7
  H = H / 16
  GOSUB BOXREST
  GOSUB LOADLOC
  GOSUB LOADVAR
  PEEK V 65418
RETURN

CONTENT:
RETURN

cserial:
  gosub savevar
  v = 0
  serial rec x
  if x = 4 then v = 1
  if x = 5 then v = 2
  if v > 0 then goto cserialc
  serial send 5
  serial rec x
  if x > 31 then x = 5
  if x = 6 then x = 3
  if x = 0 then v = 6
  if v > 0 then goto cserialc
  v = 4
  cserialc:
  poke v 65418
  gosub loadvar
  peek v 65418
return

DINBOX:
  $8 = "INPBOX: Invalid input type."
  IF V > 1 THEN GOTO ERRBOX
  IF V < 0 THEN GOTO ERRBOX
  GOSUB OPENBOX
  if $6 = "" then goto dinboxnf
  move 22 11
  print $6
  move 22 12
  print ">"
  move 23 12
  cursor on
  if v = 0 then input a
  if v = 1 then input $6
  if v = 2 then input a
  if v = 3 then input $6
  dinboxnf:
  if $7 = "" then goto dinboxns
  move 22 13
  print $7
  move 22 14
  print ">"
  move 23 14
  if v = 0 then input b
  if v = 1 then input $7
  if v = 2 then input $7
  if v = 3 then input b
  dinboxns:
  GOSUB CLOSEBOX
return

ENDPROG:
  cls
  cursor on
  FOR X = 64000 TO 65535
    POKE 0 X
  NEXT X
end

ERRBOX:
  $5 = "Error"
  gosub openbox
  pokeint v 65418
  len $8 v
  if v > 38 then $8 = "Error text too long!"
  if v > 38 then goto fatalerr
  peekint v 65418
  move 22 12
  print $8
  move 22 14
  print "Press escape to end program."
  move 22 15
  print "Press any other key to continue."
  cursor on
  move 53 15
  waitkey j
  if j = 27 then gosub endprog
  gosub closebox
return

FATALERR:
  MOVE 2 1
  INK 12
  PRINT "Fatal: " ;
  PRINT $8 ;
  WAITKEY K
GOSUB ENDPROG

INPBOX:
  GOSUB OPENBOX
  $8 = "INPBOX: Invalid input type."
  MOVE 21 11
  GOSUB BOXPRINT
  MOVE 21 15
  PRINT "> " ;
  cursor on
  IF V = 0 THEN INPUT V
  ELSE IF V = 1 THEN INPUT $6
  ELSE GOTO ERRBOX
  GOSUB CLOSEBOX
return

LOADLOC:
  POKEINT X 64156
  POKEINT Y 64158
  PEEK X 65428
  PEEK Y 65429
  MOVE X Y
  PEEK X 65438
  INK X
  PEEKINT X 64156
  PEEKINT Y 64158
RETURN

LOADVAR:
  POKEINT J 65426
  PEEK J 65421
  IF J = 0 THEN $8 = "Can't load variables, none stored!"
  IF J = 0 THEN GOSUB FATALERR
  J = J + 65198
  PEEKINT Y J
  J = J - 2
  PEEKINT X J
  J = J - 2
  PEEKINT V J
  J = J - 2
  PEEKINT W J
  J = J - 65202
  POKE J 65421
  J = J + 65200
  PEEKINT J J
RETURN

MENUBOX:
  GOSUB OPENBOX
  V = 11
  GOSUB MENUDRAW
  MOVE 22 16
  INK C
  PRINT "Press enter to select an option."

  DO
    WAITKEY W
    IF W = 1 AND V > 11 THEN GOSUB MENUBUP
    IF W = 2 AND V < 15 THEN GOSUB MENUBDWN
    IF W = 27 THEN V = 16
    IF W = 13 THEN W = 27
  LOOP UNTIL W = 27 
  GOTO MENUEND
  
  MENUBUP:
    V = V - 1
    GOSUB MENUDRAW
    RETURN
    
  MENUBDWN:
    V = V + 1
    GOSUB MENUDRAW
    RETURN
  
  MENUDRAW:
    INK C
    MOVE 22 11
    GOSUB BOXPRINT
    INK H
    X = V - 11 + 64146
    PEEK J X
    X = V - 11 + 64151
    PEEK Y X
    Y = Y + J - 1
    MOVE 22 V
    FOR X = J TO Y
      CURSCHAR J
      PRINT CHR J ;
    NEXT X
    RETURN
    
  MENUEND:
    W = V
    V = V - 10
  GOSUB CLOSEBOX
RETURN

MESBOX:
  GOSUB OPENBOX
  move 22 11
  gosub boxprint
  move 22 16
  print "Press any key to continue..."
  waitkey j
  GOSUB CLOSEBOX
return

NUMBOX:
  GOSUB OPENBOX
  if $6 = "" then goto numboxa
  move 22 11
  print $6
  move 22 12
  print a
  numboxa:
  if $7 = "" then goto numboxb
  move 22 13
  print $7
  move 22 14
  print b
  numboxb:
  move 22 16
  print "Press any key to continue..."
  waitkey j
  GOSUB CLOSEBOX
return

OPENBOX:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  POKEINT V 65418
  GOSUB BOXSAVE
  IF C < 0 THEN C = 7
  IF C > 15 THEN C = 7
  H = H * 16
  H = H + C
  CURSOR OFF
  INK C
  MOVE 22 9
  PRINT $5
  GOSUB BOX
  MOVE 22 9
  PRINT $5
  PEEKINT V 65418
RETURN

pictotxt:
  GOSUB SAVEVAR	
  for x = 0 to 19
    for y = 0 to 76
      peek w v
      if w = 0 then w = 32
      poke w v
      v = v + 1
    next y
    poke 10 v
    v = v + 1
    poke 1 v
    v = v + 1
    poke 1 v
    v = v + 1
  next x
  GOSUB LOADVAR
return

REFRESH:
  GOSUB SAVEVAR
  cls
  gosub border
  gosub title
  GOSUB LOADVAR
  gosub content
return

rserial:
  gosub savevar
  do
    serial rec w
    if w = 5 then serial send 6
  loop until w = 4
  serial send 6
  do
    serial rec w
    if w > 32 then w = 0
  loop until w > 0
  if w = 20 then goto rserialc
  gosub loadvar
  $8 = "Serial: Invalid protocol!"
  goto errbox
  rserialc:
  serial rec w
  poke w 65418
  v = w + x
  v = v - 1
  for w = x to v
    serial rec j
    poke j w
  next w
  gosub loadvar
  peek v 65418
return

SAVELOC:
  POKEINT X 64156
  POKEINT Y 64158
  CURSPOS X Y
  POKE X 65428
  POKE Y 65429
  X = INK
  POKE X 65438
  PEEKINT X 64156
  PEEKINT Y 64158
RETURN

SAVEVAR:
  POKEINT Y 65426
  PEEK Y 65421
  IF Y > 198 THEN $8 = "Variable storage area full!"
  IF Y > 198 THEN GOSUB FATALERR
  Y = Y + 65200
  POKEINT J Y
  Y = Y + 2
  POKEINT W Y
  Y = Y + 2
  POKEINT V Y
  Y = Y + 2
  POKEINT X Y
  Y = Y + 2
  Y = Y - 65200
  POKE Y 65421
  PEEKINT Y 65426
  POKEINT X 65426
  PEEK X 65421
  X = X + 65200
  POKEINT Y X
  X = X + 2
  X = X - 65200
  POKE X 65421
  PEEKINT X 65426
RETURN

SETTITLE:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  LEN $5 J
  IF J = 0 THEN RETURN
  IF J > 78 THEN RETURN
  POKE Z 65439
  INK Z
  MOVE 1 1
  PRINT " " ;
  PRINT $5 ;
  FOR X = J TO 76
    PRINT " " ;
  NEXT X
  Y = & $5
  J = J + 65441
  FOR X = 65440 TO J
    PEEK W Y
    POKE W X
    Y = Y + 1
  NEXT X
  FOR X = X TO 65514
    POKE 0 X
  NEXT X
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN

sserial:
  if v > 255 then $8 = "Serial: Packet size too big!"
  if v > 255 then goto errbox
  gosub savevar
  do
    serial send 4
    serial rec w
    if w > 32 then w = 0
  loop until w = 6
  serial send 20
  serial send v
  v = v + x
  v = v - 1
  for w = x to v
    peek j w
    serial send j
  next w
  gosub loadvar
return

STARTPRG:
  FOR X = 64000 TO 65535
    POKE 0 X
  NEXT X
  GOSUB SAVEVAR
  Y = 64168
  J = 64160
  V = 65400
  FOR X = 1 TO 32
    READ XMEMASM X W
    POKE W Y
    Y = Y + 1
  NEXT X
  FOR X = 1 TO 8
    READ BORDERDATA X W
    POKE W J
    J = J + 1
    READ BOXDATA X W
    POKE W V
    V = V + 1
  NEXT X
  V = 12288
  GOSUB XMEM
  POKE 7 65439
  X = 65400
  C = 7
  H = 14
  T = 7
  Z = 7
  INK 7
  GOSUB LOADVAR
RETURN

TITLE:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  PEEK J 65439
  INK J
  MOVE 2 1
  X = 65440
  DO
    PEEK J X
    IF J < 32 AND J > 0 THEN J = 32
    PRINT CHR J ;
    X = X + 1
  LOOP UNTIL J = 0
  CURSPOS X Y
  FOR X = X TO 78
    PRINT " " ;
  NEXT X
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN

XMEM:
  GOSUB SAVEVAR
  POKEINT V 65436
  GOSUB LOADVAR
RETURN  

XMEMASM:
6 161 156 255 142 192 160 142 255 139 62 144 255 170 7 195
30 139 54 144 255 161 156 255 142 216 172 31 162 142 255 195
    
XGET:
  POKEINT X 65424
  CALL 65184
  PEEK V 65422
RETURN

XPUT:
  POKEINT X 65424
  POKE V 65422
  CALL 65168
RETURN
