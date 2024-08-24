%IFNDEF __KERNELDAT__
%DEFINE __KERNELDAT__

NameSystem db "KiddieOS",0		; System Identification

; --------------------------------------------------------
; Chars Vectors
VetorHexa  		db "0123456789ABCDEF",0
VetorCharsLower db "abcdefghijklmnopqrstuvwxyz",0
VetorCharsUpper db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0
VetorDec 		db "0123456789",0
; --------------------------------------------------------

; --------------------------------------------------------
; Extensions & datas
Extension  db "DRV"

; Check_Volumes Datas
format_types:
	db 0x06, "FAT16   "
	db 0x0B, "FAT32   "
	db 0x0C, "FAT32   "
	db 0x07, "NTFS    "
	db 0x07, "EXFAT   "
COUNT_FORMAT_TYPES 	EQU ($-format_types)/9

VolumeLetters db 'K'

; Services Initialization Datas
pci_program db "K:\KiddieOS\Programs\devmgr.kxe",0
rtl_program db "K:\KiddieOS\Programs\netapp.kxe",0
; --------------------------------------------------------

; --------------------------------------------------------
; Screen Impressions
PressKey   db "Press any key to continue...",0
; --------------------------------------------------------

; --------------------------------------------------------
; Global Variables
Zero 		        db 0

; Check_Volumes Variables
lba_size_extended 	dd 0
lba_begin_extended 	dd 0
lba_begin_logical	dd 0
isLogical 			db 0
label_offset 		dw 0
save_value_si 		dw 0
EBR_buffer: 		times 512 db 0
VBR_buffer: 		times 512 db 0

ntfs_label 	db "NO NAME    "
; --------------------------------------------------------

%ENDIF