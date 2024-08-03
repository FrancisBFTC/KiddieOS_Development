\ Add to running system by executing INCLUDE <filename>

." Generating a new system." CR

FORGET VERSION			\ Only if providing new one (below)

\ May modify version and protect definitions, if desired
: VERSION ( -- )
	." V1.53a 2021/05/01 " ;

\ VERSION must be last definition before using this 'work around'
\ VERSION LFA - NEXT (4) - address size (2)
LAST @ 6 - DUP U.		\ Address to replace with START - print for diagnostic

HERE SWAP !			\ set START PFA for first NEXT in 'do_startup'
				\ Initial program entry and start up
\ : START ( -- )		\ Headerless colon definition, less CFA
]
	CR CR ." FORTH version " VERSION
	CR ." MikeOS API version " D_VER 1+ C@ 0
	<# # # 46 HOLD 2DROP D_VER C@ 0 #S #> TYPE
	CR PATH .AZ
	CR OK CR
	ABORT [

\ write the completed system with start up routine (above)
write_exec FORTH_01.BIN
