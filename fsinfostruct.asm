; ===================================================
;      File System Information Structure
;                 FAT32 Only
;              KiddieOS V.1.2.0
; ===================================================

%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG FSINFOSTRUCT]

LEAD_SIGNATURE_H       dw 0x4161
LEAD_SIGNATURE_L       dw 0x5252
RESERVED_1             times 480 db 0
ANOTHER_SIGNATURE_H    dw 0x6141
ANOTHER_SIGNATURE_L    dw 0x7272
FREE_CLUSTER_COUNT_H   dw 0xFFFF
FREE_CLUSTER_COUNT_L   dw 0xFFFF
START_SEARCH_CLUSTER_H dw 0xFFFF
START_SEARCH_CLUSTER_L dw 0xFFFF
RESERVED_2             times 12 db 0
TRAIL_SIGNATURE_H      dw 0xAA55
TRAIL_SIGNATURE_L      dw 0x0000
