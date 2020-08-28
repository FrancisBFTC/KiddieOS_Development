!macro CustomCodePostInstall
	${If} ${FileExists} "$INSTDIR\Data\settings\rufus.reg"
	${AndIfNot} ${FileExists} "$INSTDIR\Data\settings\rufus.ini"
		CopyFiles /SILENT "$INSTDIR\App\DefaultData\settings\rufus.ini" "$INSTDIR\Data\settings"
	${EndIf}
!macroend