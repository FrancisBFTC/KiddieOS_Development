[BITS 16]


FAT_SECTORS EQU 245
ENTRY_SIZE  EQU 32
SECTOR_SIZE EQU 512
RESERVED    EQU 63
	
Boot_MBR: 

FAT1: 
	_FirstSector1:
		db 0xf8, 0xff, 0xff, 0xff
		times (SECTOR_SIZE) - (4) db 0
	_RestSector1:
		times (FAT_SECTORS*SECTOR_SIZE) db 0  ;245
	

FAT2:
	_FirstSector2:
		db 0xf8, 0xff, 0xff, 0xff
		times (SECTOR_SIZE) - (4) db 0
	_RestSector2:
		times (FAT_SECTORS*SECTOR_SIZE) db 0  ;245
	
FAT_ROOTDIRECTORY:
    ;; ## Volume1 entry ##
    
     ;; Label (KIDDIEOS)
    db '.' , 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20 
    db 0x20, 0x20, 0x20, 0x10, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7B
    db 0x1B, 0x4B, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00

    ; Metafile (BRAMADO)
    db '.' , '.' , 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
    db 0x20, 0x20, 0x20, 0x10, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7B
    db 0x1B, 0x4B, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00
	
	;
    times (SECTOR_SIZE * ENTRY_SIZE) - (ENTRY_SIZE * 2) db 0 
	
Data_Area:                                                                                         
    times  (1024 * 1024 * ENTRY_SIZE) - (Data_Area - Boot_MBR) - (512) - (4) db 0 

.end_of_disk:   
	;times (63*512) - (512) db '0' ; setores reservados
	;times (4*512) db 0            ; setores escondidos
	
    db '*EOD'    ;; ## END OF DISK ##
	;%INCLUDE "FATMBR/footervhd.asm"