%IFNDEF __FAT_INC__
%DEFINE __FAT_INC__

%DEFINE FAT16.LoadAllFiles    FAT16
%DEFINE FAT16.LoadThisFile    FAT16+9
%DEFINE FAT16.LoadFatVbrData  FAT16+15
%DEFINE FAT16.OpenThisFile 	  FAT16+24
%DEFINE FAT16.LoadFile 		  FAT16+27
%DEFINE FAT16.SetSeek 		  FAT16+30
%DEFINE FAT16.CloseFile 	  FAT16+33
FAT16.FileSegments    EQU   (FAT16+39)
FAT16.DirSegments 	  EQU   (FAT16+41)
FAT16.LoadingDir      EQU   (FAT16+43)
FAT16.ReadSectors  	  EQU	(FAT16+36)

%ENDIF