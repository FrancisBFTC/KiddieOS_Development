strWaveFile           	db "coin.wav", 0					; coin.wav
strFileNotFound       	db "File not found!", 24h
strFileError          	db "Error while reading WAV file!", 24h

fileHandle            	dw 0

sampleRate				dw 0
samplingBuffer			dw 0 

strErrorBuffer   db "Cannot allocate or find a buffer for the samplings :(", 24h
strPressAnyKey   db "Press any key to exit", 13, 10, 24h
strBye           db "Sound should stop now", 13, 10, 24h

;This is the buffer
buffer            db BUFFER_SIZE DUP(0)
bufferOffset      dw buffer
bufferSegment     dw 0x0000

 ;This is a pointer to the ISR we will install 
nextISR         dw Sb16Isr
                dw 0x0000	; code_seg
;This is the internal status managed by the ISR
BlockNumber     dw 0
BlockMask       dw 0
 
