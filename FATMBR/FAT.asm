[ORG 0000h]
[BITS 16]

%INCLUDE "Hardware/memory.lib"

FAT_SECTORS EQU 245
ENTRY_SIZE  EQU 32
SECTOR_SIZE EQU 512
RESERVED    EQU 63

Boot_MBR:
	%INCLUDE "FATMBR/bootmbr.asm"
	
Boot_VBR:
	;times (SECTOR_SIZE * RESERVED) - (Boot_VBR - Boot_MBR) db 'b'
	%INCLUDE "FATMBR/bootvbr.asm"
	
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
    
    ;; Label (GRAMADO)
    db 'K',  'I',  'D',  'D',  'I',  'E',  'O',  'S'
    db 0x20, 0x20, 0x20, 0x08, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7B
    db 0x1B, 0x4B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    ; Metafile (BRAMADO)
    db 0x42, 0x52, 0x41, 0x4D, 0x41, 0x44, 0x4F, 0x20
    db 0x20, 0x20, 0x20, 0x08, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7B
    db 0x1B, 0x4B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	
	
    times (SECTOR_SIZE * ENTRY_SIZE) - (ENTRY_SIZE * 2) db 0 
	
Data_Area:                                                                                         
    times  (1024 * 1024 * ENTRY_SIZE) - ( Data_Area - Boot_MBR ) - (4) db 0 

.end_of_disk:    
    db '*EOD'    ;; ## END OF DISK ##
	%INCLUDE "FATMBR/footervhd.asm"