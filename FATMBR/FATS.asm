[BITS 16]


FAT_SECTORS EQU 245
ENTRY_SIZE  EQU 32
SECTOR_SIZE EQU 512
RESERVED    EQU 63
	
ORG 0x0600

; Área do MBR - Setor 0
Boot_MBR: 
	%INCLUDE "bootmbr.asm"


; Área de Setores Reservados - +62 Setores	
EOF:                                                      ; 
    times (63*512) - (EOF-Boot_MBR) db 'b'

;ORG 0x0000
	
; Área da VBR - Setor 63
Boot_VBR:
    %INCLUDE "bootvbr.asm"

	
; Área de Setores Ocultos - +3 Setores
Hidden_Sectors:
    times (512) db 'h' ; Setor 64
    times (512) db 'h' ; Setor 65
    times (512) db 'h' ; Setor 66


; Primeiro FAT - Setor 67	Total = 246 Setores
FAT1: 
	_FirstSector1:
		db 0xf8, 0xff, 0xff, 0xff
		times (SECTOR_SIZE) - (4) db 0
	_RestSector1:
		times (FAT_SECTORS*SECTOR_SIZE) db 0  ;245
	

; Segundo FAT - Setor 313  Total = 246 Setores
FAT2:
	_FirstSector2:
		db 0xf8, 0xff, 0xff, 0xff
		times (SECTOR_SIZE) - (4) db 0
	_RestSector2:
		times (FAT_SECTORS*SECTOR_SIZE) db 0  ;245
	
	
; Área do Diretório Raiz - Setor 559	
FAT_ROOTDIRECTORY:
    ;; ## Volume1 entry ##
    
   ;; Label (GRAMADO)
    db 0x47, 0x52, 0x41, 0x4D, 0x41, 0x44, 0x4F, 0x20
    db 0x20, 0x20, 0x20, 0x08, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7B
    db 0x1B, 0x4B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    ; Metafile (BRAMADO)
    db 0x42, 0x52, 0x41, 0x4D, 0x41, 0x44, 0x4F, 0x20
    db 0x20, 0x20, 0x20, 0x08, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7B
    db 0x1B, 0x4B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	
	; Completando a Área de diretório
    times (SECTOR_SIZE * ENTRY_SIZE) - (ENTRY_SIZE * 2) db 0
	
; Área de dados - Setor 591	
Data_Area:                                                                                   
    times  (1024 * 1024 * ENTRY_SIZE) - ( Data_Area - Boot_MBR ) - (4) db 0 


; Área do rodapé do VHD
End_Of_Disk:   
	db '*EOD'    ;; ## Fim do Disco ##
	%INCLUDE "footervhd.asm"
	
; End here