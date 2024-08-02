[BITS 16]


FAT_SECTORS EQU 245   ; 245
ENTRY_SIZE  EQU 32
SECTOR_SIZE EQU 512  ;512
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
		times (FAT_SECTORS*SECTOR_SIZE) db 0  ;243
	
FAT_ROOTDIRECTORY:
    ;; ## Volume1 entry ##
    
    ;; Label (Metafile)
    db 0x20, "V",  "O",  "L",  "U",  "M",  "Y",  0x20
    db 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, "Š",  "=" 
    db "Ô",  "R",  0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    ;times (1024 - 32) db 0
	
	;
    times (SECTOR_SIZE * ENTRY_SIZE) - (ENTRY_SIZE * 1) db 0 
	
Data_Area:                                                                                         
    times  (1024 * 1024 * ENTRY_SIZE) - (Data_Area - Boot_MBR) - (512) - (4) db 0 

.end_of_disk:   
    db '*EOD'    ;; ## END OF DISK ##
