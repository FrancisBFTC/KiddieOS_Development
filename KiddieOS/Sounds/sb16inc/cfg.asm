 ;These are the only configurable constants

 ;IO Base
 SB16_BASE   EQU 220h

 ;16-bit DMA channel (must be between 5-7)
 SB16_HDMA   EQU 5

 ;IRQ Number
 SB16_IRQ    EQU 7

 ;These a computed values, don't touch them if you don't know what
 ;you are doing

 ;REGISTER NAMES

 REG_DSP_RESET      EQU SB16_BASE + 6		; 226h
 REG_DSP_READ       EQU SB16_BASE + 0ah		; 22ah
 REG_DSP_WRITE_BS   EQU SB16_BASE + 0ch		; 22ch
 REG_DSP_WRITE_CMD  EQU SB16_BASE + 0ch		; 22ch
 REG_DSP_WRITE_DATA EQU SB16_BASE + 0ch		; 22ch
 REG_DSP_READ_BS    EQU SB16_BASE + 0eh		; 22eh
 REG_DSP_ACK        EQU SB16_BASE + 0eh		; 22eh
 REG_DSP_ACK_16     EQU SB16_BASE + 0fh		; 22fh

 ;DSP COMMANDS

 DSP_SET_SAMPLING_OUTPUT   EQU 41h
 DSP_SET_CONSTANT_TIME     EQU 40h
 DSP_DMA_16_OUTPUT_AUTO    EQU 0b0h
 DSP_STOP_DMA_16           EQU 0d5h

 ;DMA REGISTERS

 REG_DMA_ADDRESS    EQU 0c0h + (SB16_HDMA - 4) * 4	; C4h
 REG_DMA_COUNT      EQU REG_DMA_ADDRESS + 02h		; C6h

 REG_DMA_MASK       EQU 0d4h
 REG_DMA_MODE       EQU 0d6h
 REG_DMA_CLEAR_FF   EQU 0d8h

 IF SB16_HDMA - 5
    REG_DMA_PAGE		EQU 8bh      
 ELSE
    IF SB16_HDMA - 6
       REG_DMA_PAGE       EQU 89h
    ELSE
       REG_DMA_PAGE       EQU 8ah
    END IF
 END IF

 ;ISR vector
 ISR_VECTOR		EQU ((SB16_IRQ SHR 3) * (70h - 08h) + (SB16_IRQ AND 7) + 08h) * 4

 PIC_DATA		EQU (SB16_IRQ AND 8) + 21h
 PIC_MASK		EQU 1 SHL (SB16_IRQ AND 7)
 
 FORMAT_MONO     EQU 00h
 FORMAT_STEREO   EQU 20h
 FORMAT_SIGNED   EQU 10h
 FORMAT_UNSIGNED EQU 00h
 
 ;Block size is 1/100 of a second at 44100 samplings per seconds
 BLOCK_SIZE      EQU 44100 / 100 * 2

 ;Buffer size allocated, it is twice the BLOCK_SIZE because there are two blocks.
 ;Size is doubled again so that we are sure to find an area that doesn't cross a
 ;64KiB boundary
 ;Total buffer size is about 3.5 KiB

 BUFFER_SIZE     EQU  BLOCK_SIZE * 2 * 2