%INCLUDE "Hardware\memory.lib"
[BITS SYSTEM]
[ORG FONTSWRITER]

cmp bx, 1
je ProcChars
jmp Return

%INCLUDE "Hardware\win16.lib"
%INCLUDE "Hardware\keyboard.lib"
%INCLUDE "Hardware\fontswriter.lib"
%INCLUDE "Hardware\fonts.lib"

ProcChars:


Return:
	ret