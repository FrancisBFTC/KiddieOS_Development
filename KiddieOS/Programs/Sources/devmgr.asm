; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;               DEVMGR.KXE MAIN APPLICATION
;                  
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%INCLUDE 	"libasm.inc"
%INCLUDE 	"libdvmgr.inc"

Main(ARGC, ARGV)

	cli      ; Disable Interrupts
	
	; Load PCI Driver and Initialize Device
	mov 	eax, 0x14   ; Syscall Init_Device
	int 	0xCE        ; Invoke the Syscall
	
	;Scan and Filter existing devices storing with identifiers using stacking strategy.
	call 	__build_sequential_struct
	
	; Print the number of PCI devices scanned.
	call 	__show_amount_devices
	
	; After the structuring algorithm performed above, sort the vector on the stack using 
	; RadixSort algorithm and present a tree format on the screen.
	call 	__show_hierarchical_visual

	; Close PCI Driver and clean memory
	mov 	eax, 0x15   ; Syscall Close_Device
	int 	0xCE        ; Invoke the Syscall
	
	jmp 	$
	sti      ; Enable Interrupts
.EndMain
