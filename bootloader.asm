%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG BOOTLOADER]

; ================================================

; POR ENQUANTO O BOOTLOADER CARREGA UM ARQUIVO GRUB 
; TESTE NÃO NECESSARIAMENTE UM GRUB. ESTE ARQUIVO
; DEVE CARREGAR O KERNEL POIS O BOOTLOADER NÃO TERÁ
; ESPAÇO O SUFICIENTE PRA FAZER ISSO.

; ================================================

; READING DIRECTORIES

; RootDirStart = DataStart - RootDirSectors

; StartSectorCluster = (_SectorPerCluster * (Cluster - 2)) + DataStart

%DEFINE DIRECTORY_SIZE   32
%DEFINE TRACKS_PER_HEAD  1024
%DEFINE FAT12_SIZE       4096
%DEFINE FAT16_SIZE       65535
%DEFINE FAT32_SIZE       268435445

jmp SHORT Boot_Begin
; ----- BIOS Parameter Block (BPB) -----
OemIdentifier     db "MSWIN4.1"
BytesPerSector    dw 512        ; ok
SectorsPerCluster db 0x04       ; ok
ReservedSectors   dw 0x0003     ; ok
NumberFats        db 2          ; ok
NumberRootEntry   dw 0x0000     ; ok
TotalSectors16    dw 0x0000     ; ok
MediaType         db 0xF8       ; ok
SectorsPerFat16   dw 0x0000     ; ok
SectorsPerTrack   dw 63         ; ok
NumberHeads       dw 256        ; ok
NumberHidSec32    dd 0x00000000
TotalSectors32    dd 0x00FC0000 ; ok

; ----- Extended BIOS parameter Block (EBPB) -----

SectorsPerFat32     dd 0x0000      ; ok
ExtendedFlags       dw 0x0000
FatVersion          dw 0x0000
RootClusterNumber32 dd 0x00000000  ; ok
FSInfoSectorNumber  dw 0x0002      ; ok
BackupSectorNumber  dw 0x0000      ; ok
Reserved0           times 12 db 0  ; ok
DriveNumber         db 0x80        ; ok
Reserved1           db 0x00        ; ok
BootSignature       db 0x28 ; 0x29 ; ok
VolumeIDSerial      dd 0x00000000
VolumeLabel         db "           "
FatTypeLabel        db "FAT32   "  ; ok
; ----- End of General BPB -----

Boot_Begin:
	xor AX, AX
	xor SI, SI
	xor DI, DI
	cld
	mov DS, AX
	mov ES, AX
	mov FS, AX
	mov GS, AX
	cli
	mov ax, 7D00h
	mov ss, ax
	mov sp, 3000h
	sti
	mov ah, 00h
	mov al, 03h
	int 10h

; O Tamanho do FAT em Setores é definido aqui
SetFatParams:
	; SectorsPerFat16 = ((TotalSectors32 / (BytesPerSector x SectorsPerCluster)) x SectorsPerCluster)
	; FatSize = SectorsPerFat16
	; FatStart = ReservedSectors
	
	mov ax, word[BytesPerSector]
	mov cl, byte[SectorsPerCluster]
	mul cx
	push cx
	
	mov cx, ax
	mov eax, dword[TotalSectors32]
	push ax
	and eax, 0xFFFF0000
	shr eax, 16
	mov dx, ax
	pop ax
	div cx
	
	pop cx
	mul cx
	mov word[SectorsPerFat16], ax
	mov word[FatSize], ax
	mov word[BackupSectorNumber], ax
	
	mov ax, word[ReservedSectors]
	mov word[FatStart], ax
	
; O Offset do diretório raiz em setor lógico é definido aqui (Metadados)
SetDirectoryParams:
	 ; RootClusterNumber32 = FatStart + (NumberFats * SectorsPerFat16)
	 ; EntryPerCluster = ((BytesPerSector / DIRECTORY_SIZE) x SectorPerCluster)
	 ; NumberRootEntry = ((TotalSectors32 - RootNumberCluster32) / SectorsPerCluster) / EntryPerCluster
	 ; CountDirEntry32 = ((NumberRootEntry + 1) x EntryPerCluster) - 1
	 ; CountDirSectors32 = (CountDirEntry32 * SectorsPerCluster) + 1
	 ; CountDirSectors32 = CountDirEntry32 / (BytesPerSector / DIRECTORY_SIZE)
	 
	 xor cx, cx
	 xor dx, dx
	 mov ax, word[SectorsPerFat16]
	 mov cl, byte[NumberFats]
	 mul ecx
	 mov cx, word[FatStart]
	 add eax, ecx
	 mov dword[RootClusterNumber32], eax
	 mov ebx, eax
	 
	 xor dx, dx
	 mov cl, DIRECTORY_SIZE
	 mov ax, word[BytesPerSector]
	 div cl
	 mov cl, byte[SectorsPerCluster]
	 mul cl
	 mov byte[EntryPerCluster], al
	 
	 push ax
	 mov eax, dword[TotalSectors32]
	 sub eax, ebx
	 div ecx
	 mov dword[CountDirEntry32], eax
	 pop cx
	 div ecx
	 and eax, 0x0000FFFF
	 mov word[NumberRootEntry], ax
	 xor ecx, ecx
	 xor edx, edx
     mov eax, dword[CountDirEntry32]
	 mov cl, 16   ; (BytesPerSector / DIRECTORY_SIZE)
	 div ecx
	 mov dword[CountDirSectors32], eax
	
; O tamanho da área de dados e o setor inicial é definido aqui	
SetDataParams:
	; DataStart32 = RootClusterNumber32 + CountDirSectors32
	; TotalDataSectors32 = TotalSectors32 - DataStart32
	; TotalDataClusters32 = TotalDataSectors32 / SectorsPerCluster
	; SE TotalDataClusters < FAT12_SIZE  FatTypeLabel = FAT12;
	; SE TotalDataClusters < FAT16_SIZE  FatTypeLabel = FAT16;
	; SE TotalDataClusters < FAT32_SIZE  FatTypeLabel = FAT32;
	
	mov eax, dword[RootClusterNumber32]
	mov ebx, dword[CountDirSectors32]
	add eax, ebx
	mov dword[DataStart32], eax
	mov ebx, dword[TotalSectors32]
	sub ebx, eax
	mov dword[TotalDataSectors32], ebx
	xor edx, edx
	mov eax, ebx
	mov cl, byte[SectorsPerCluster]
	div ecx
	mov dword[TotalDataClusters32], eax
	
LoadGrub:
	mov ah, 02h
	mov al, GRUB_SECTOR  ; numero de setores
	mov ch, 0
	mov cl, GRUB_NUM_SECTORS  ; número do setor
	mov dh, 0
	mov dl, 80h
	mov bx, 0800h
	mov es, bx
	mov bx, GRUB
	int 13h
	
	jmp 0800h:GRUB
	 
jmp $
	
	
EntryPerCluster     db 0x00
FatSize             dw 0x0000
FatStart            dw 0x0000
DataStart32         dd 0x00000000
CountDirSectors32   dd 0x00000000
CountDirEntry32     dd 0x00000000
TotalDataSectors32  dd 0x00000000
TotalDataClusters32 dd 0x00000000
FAT12  db "FAT12",0
FAT16  db "FAT16",0
FAT32  db "FAT32",0
EXFAT  db "EXFAT",0

times 510-($-$$) db 0
dw 0xAA55