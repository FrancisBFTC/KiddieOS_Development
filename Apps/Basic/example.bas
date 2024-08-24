rem *** MikeOS BASIC demo ***

cls

$1 = "Hex dumper,MikeTron"
$2 = "Choose a program to run,"
$3 = "Or press Esc to exit"

listbox $1 $2 $3 a

if a = 1 then goto runhex
if a = 2 then goto runmiketron

cls
end


runhex:

rem *** Hex dumper ***

cls

print "Enter a filename to make a hex dump from:"
input $1

x = RAMSTART

load $1 x
if r = 1 then goto hexerror

hexloop:
  peek a x
  print hex a ;
  print "  " ;
  x = x + 1
  s = s - 1
  if s = 0 then goto hexfinish
  goto hexloop

hexfinish:
print ""
end

hexerror:
print "Could not load file! Does it exist?"
end



runmiketron:

rem MikeTron Game (MIKETRON.BAS)
rem A expanded demo game
rem Created by Mike Saunders
rem Extended by Joshua Beck
rem Version 1.1.1
rem Send any bug reports or suggested features to:
rem mikeosdeveloper@gmail.com

cls

print "You control a vehicle leaving a trail behind it."
print ""
print "It is always moving, and if it crosses any part"
print "of the trail or border (+ characters), the game"
print "is over. Use W, A, S, D to change the direction"
print "See how long you can survive! Score at the end."
print ""
print "NOTE: May perform at wrong speed in emulators!"
print ""
print "Hit a key to begin..."

waitkey x


cls
cursor off


rem *** Draw border around screen ***

gosub setupscreen
for o = 1 to 20
  gosub addbonus
next o

rem *** Start in the middle of the screen ***

x = 40
y = 12

move x y


rem *** Movement directions: 1 - 4 = up, down, left, right ***
rem *** We start the game moving right ***

d = 4


rem *** S = score variable ***
s = 0

rem *** E = tail character ***
e = 197

mainloop:
  if p = 0 then print chr e ;

  rem wait once, then again if traveling vertical
  pause 1
  if d = 1 then pause 1
  if d = 2 then pause 1

  rem Apple Bonus
  if a > 0 then move x y
  if a > 0 then print " " ;
  if a > 0 then a = a - 1

  rem Invisible ?Bonus?
  if p > 0 then p = p - 1

  getkey k
  
  rem New keys, WASD
  if k = 'w' then d = 1
  if k = 'W' then d = 1
  if k = 'a' then d = 3
  if k = 'A' then d = 3
  if k = 's' then d = 2
  if k = 'S' then d = 2
  if k = 'd' then d = 4
  if k = 'D' then d = 4

  rem if they press ESC exit game
  if k = 27 then goto finish

  if d = 1 then y = y - 1
  if d = 2 then y = y + 1
  if d = 3 then x = x - 1
  if d = 4 then x = x + 1

  move x y

  curschar c
  rem ***did we collide with wall***
  if c = '+' then gosub sides
  rem ***if we are invisible don't register collisions***
  if p > 0 then goto mainloop
  rem ***did we collide with tail?***
  if c = e then goto finish
  rem ***no trail time set***
  if c = 235 then a = a + 10
  rem ***explode***
  if c = 233 then gosub explode
  rem ***overwrite (?)***
  if c = '?' then print chr e ;
  if c = '?' then move x y 
  rem ***invisible time***
  if c = '?' then p = p + 4
  rem ***stop***
  if c = 'S' then gosub stop
  rem ***bonus spreader***
  if c = 'B' then gosub bonus

  s = s + 1

  rem a bonus for every 100 points but not over 1000
  r = s % 100
  if r > 1000 then goto mainloop
  if r = 0 then gosub bonus
goto mainloop

explode:
  q = 219
  gosub bomb
  pause 2
  q = 178
  gosub bomb
  pause 2
  q = 177
  gosub bomb
  pause 2
  q = 176
  gosub bomb
  pause 2
  q = 32
  gosub bomb
return

bonus:
  print chr e ;
  for o = 1 to 5
    gosub addbonus
  next o
  move x y
return

stop:
  waitkey k
  if k = 'w' then d = 1
  if k = 'W' then d = 1
  if k = 'a' then d = 3
  if k = 'A' then d = 3
  if k = 's' then d = 2
  if k = 'S' then d = 2
  if k = 'd' then d = 4
  if k = 'D' then d = 4
return

bomb:
  v = x - 5
  w = y - 2
  for u = 1 to 5
    if w > 23 then goto noprinta
    if w < 1 then goto noprinta
    for t = 1 to 10
      move v w
      if v < 2 then goto noprintb
      if v > 78 then goto noprintb
      print chr q ;
      noprintb:
      v = v + 1
    next t
    noprinta:
    v = x - 5
    w = w + 1
  next u
  move x y
return

sides:
  if x > 77 then x = 1
  if x < 1 then x = 77
  if y > 23 then y = 1
  if y < 1 then y = 23
  move x y
return

finish:
  cursor on
  cls

  print "Your score was: " ;
  print s
  print "Press Esc to finish"

escloop:
  waitkey x
  if x = 27 then end
goto escloop


setupscreen:

  move 0 0
  for x = 0 to 78
    print "+" ;
  next x

  move 0 24
  for x = 0 to 78
    print "+" ;
  next x

  for y = 0 to 24
    move 0 y
    print "+" ;
  next y

  for y = 0 to 24
    move 78 y
    print "+" ;
  next y

return

addbonus:
  rand q 1 77
  rand r 1 23
  rand g 1 4
  rand f 1 20
  if g = 1 then g = 235
  if g = 2 then g = 233
  if g = 3 then g = 63
  if g = 4 then g = 83
  if f > 19 then g = 66
  move q r
  print chr g
return
