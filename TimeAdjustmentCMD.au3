#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Tool to manipulate the update speed (TimeAdjustment) of the system clock
#AutoIt3Wrapper_Res_Description=Tool to manipulate the update speed (TimeAdjustment) of the system clock
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Sample by Joakim Schicht
Global $SystemTimeAdjustment = 28
Global Const $__WINAPICONSTANT_FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x100
Global Const $__WINAPICONSTANT_FORMAT_MESSAGE_FROM_SYSTEM = 0x1000
Global $tagSYSTEM_TIME_ADJUST_INFORMATION_QUERY = "ulong TimeAdjustment;ulong TimeIncrement;boolean Disable"
Global $tagSYSTEM_TIME_ADJUST_INFORMATION_SET = "ulong TimeAdjustment;boolean Disable"
If $cmdline[0] = 0 Then
	ConsoleWrite("Error: No parameters supplied" & @CRLF)
	Exit
EndIf
If $cmdline[1] = "-g" Then ; switch get information
	$NtSystemInformation = _NtQuerySystemInformation($SystemTimeAdjustment,$tagSYSTEM_TIME_ADJUST_INFORMATION_QUERY)
	If @error then Exit
	$TimeAdjustment = DllStructGetData($NtSystemInformation,"TimeAdjustment")
	$TimeIncrement = DllStructGetData($NtSystemInformation,"TimeIncrement")
	$Disable = DllStructGetData($NtSystemInformation,"Disable")
	ConsoleWrite("TimeAdjustment: " & $TimeAdjustment & @CRLF)
	ConsoleWrite("TimeIncrement: " & $TimeIncrement & @CRLF)
	ConsoleWrite("Adjustment Disabled: " & $Disable & @CRLF)
	Exit
EndIf
If $cmdline[1] = "-s" Then ; switch set information
	If $cmdline[0] <> 3 Then
		ConsoleWrite("Error: Wrong parameters supplied" & @CRLF)
		Exit
	EndIf
	If Not StringIsDigit($cmdline[2]) Then ; AdjustmentVal
		ConsoleWrite("Error: Param 2 must be digit" & @CRLF)
		Exit
	EndIf
	If Not StringIsDigit($cmdline[3]) Then ; AdjustmentDisable
		ConsoleWrite("Error: Param 3 must be digit" & @CRLF)
		Exit
	EndIf
	$AdjustmentVal = $cmdline[2]
	$AdjustmentDisable = $cmdline[3]
	_SetPrivilege("SeSystemtimePrivilege")
	$NtSystemInformation = _NtSetSystemInformation($SystemTimeAdjustment,$tagSYSTEM_TIME_ADJUST_INFORMATION_SET,$AdjustmentVal,$AdjustmentDisable)
	If @error then exit
	ConsoleWrite("Success in setting Time Adjustment" & @CRLF)
	Exit
EndIf

Func _NtSetSystemInformation($SystemInformation,$structure,$val,$config)
	$SystemStruct = DllStructCreate($structure)
	DllStructSetData($SystemStruct,"TimeAdjustment",$val)
	DllStructSetData($SystemStruct,"Disable",$config)
	Local $aCall = DllCall("ntdll.dll", "long", "NtSetSystemInformation", _
			"dword", $SystemInformation, _
			"ptr", DllStructGetPtr($SystemStruct), _
			"dword", DllStructGetSize($SystemStruct))
	If Not NT_SUCCESS($aCall[0]) Then
		ConsoleWrite("Error in NtSetSystemInformation : 0x"&Hex($aCall[0],8) &" -> "& _TranslateErrorCode(_RtlNtStatusToDosError("0x"&Hex($aCall[0],8))) & @CRLF)
		Return SetError(1,0,$aCall[0])
	EndIf
	Return $aCall[0]
EndFunc

Func _NtQuerySystemInformation($SystemInformation,$structure)
	Local $aCall = DllCall("ntdll.dll", "long", "NtQuerySystemInformation", "dword", $SystemInformation, "ptr", 0, "ulong", 0, "ulong*", 0)
	If @error Then Return SetError(1, 0, "")
	Local $iSize = $aCall[4]
	Local $tBufferRaw = DllStructCreate("byte[" & $iSize & "]")
	Local $pBuffer = DllStructGetPtr($tBufferRaw)
;	Local $pBuffer = DllStructCreate("byte[" & $iSize & "]")
	$aCall = DllCall("ntdll.dll", "long", "NtQuerySystemInformation", "dword", $SystemInformation, "ptr", $pBuffer, "dword", $iSize, "dword*", 0)
	If Not NT_SUCCESS($aCall[0]) Then
		ConsoleWrite("Error in NtQuerySystemInformation2 : 0x"&Hex($aCall[0],8) &" -> "& _TranslateErrorCode(_RtlNtStatusToDosError("0x"&Hex($aCall[0],8))) & @CRLF)
		Return SetError(1,0,$aCall[0])
	EndIf
	Local $RetStruct = DllStructCreate($structure, $pBuffer)
	Return $RetStruct
EndFunc

Func _SetPrivilege($Privilege)
    Local $tagLUIDANDATTRIB = "int64 Luid;dword Attributes"
    Local $count = 1
    Local $tagTOKENPRIVILEGES = "dword PrivilegeCount;byte LUIDandATTRIB[" & $count * 12 & "]" ; count of LUID structs * sizeof LUID struct
    Local $TOKEN_ADJUST_PRIVILEGES = 0x20
    Local $SE_PRIVILEGE_ENABLED = 0x2

    Local $curProc = DllCall("kernel32.dll", "ptr", "GetCurrentProcess")
    Local $call = DllCall("advapi32.dll", "int", "OpenProcessToken", "ptr", $curProc[0], "dword", $TOKEN_ADJUST_PRIVILEGES, "ptr*", "")
    If Not $call[0] Then Return False
    Local $hToken = $call[3]

    $call = DllCall("advapi32.dll", "int", "LookupPrivilegeValue", "str", "", "str", $Privilege, "int64*", "")
    Local $iLuid = $call[3]

    Local $TP = DllStructCreate($tagTOKENPRIVILEGES)
    Local $LUID = DllStructCreate($tagLUIDANDATTRIB, DllStructGetPtr($TP, "LUIDandATTRIB"))

    DllStructSetData($TP, "PrivilegeCount", $count)
    DllStructSetData($LUID, "Luid", $iLuid)
    DllStructSetData($LUID, "Attributes", $SE_PRIVILEGE_ENABLED)

    $call = DllCall("advapi32.dll", "int", "AdjustTokenPrivileges", "ptr", $hToken, "int", 0, "ptr", DllStructGetPtr($TP), "dword", 0, "ptr", 0, "ptr", 0)
    DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
    Return ($call[0] <> 0)
EndFunc

Func _RtlNtStatusToDosError($Status)
    Local $aCall = DllCall("ntdll.dll", "ulong", "RtlNtStatusToDosError", "dword", $Status)
    If Not NT_SUCCESS($aCall[0]) Then
        ConsoleWrite("Error in RtlNtStatusToDosError: " & Hex($aCall[0], 8) & @CRLF)
        Return SetError(1, 0, $aCall[0])
    Else
        Return $aCall[0]
    EndIf
EndFunc

Func _TranslateErrorCode($ErrCode)
	Local $tBufferPtr = DllStructCreate("ptr")

	Local $nCount = _FormatMessage(BitOR($__WINAPICONSTANT_FORMAT_MESSAGE_ALLOCATE_BUFFER, $__WINAPICONSTANT_FORMAT_MESSAGE_FROM_SYSTEM), _
			0, $ErrCode, 0, $tBufferPtr, 0, 0)
	If @error Then Return SetError(@error, 0, "")

	Local $sText = ""
	Local $pBuffer = DllStructGetData($tBufferPtr, 1)
	If $pBuffer Then
		If $nCount > 0 Then
			Local $tBuffer = DllStructCreate("wchar[" & ($nCount + 1) & "]", $pBuffer)
			$sText = DllStructGetData($tBuffer, 1)
		EndIf
		_LocalFree($pBuffer)
	EndIf

	Return $sText
EndFunc

Func _FormatMessage($iFlags, $pSource, $iMessageID, $iLanguageID, ByRef $pBuffer, $iSize, $vArguments)
	Local $sBufferType = "struct*"
	If IsString($pBuffer) Then $sBufferType = "wstr"
	Local $aResult = DllCall("Kernel32.dll", "dword", "FormatMessageW", "dword", $iFlags, "ptr", $pSource, "dword", $iMessageID, "dword", $iLanguageID, _
			$sBufferType, $pBuffer, "dword", $iSize, "ptr", $vArguments)
	If @error Then Return SetError(@error, @extended, 0)
	If $sBufferType = "wstr" Then $pBuffer = $aResult[5]
	Return $aResult[0]
EndFunc

Func _LocalFree($hMem)
	Local $aResult = DllCall("kernel32.dll", "handle", "LocalFree", "handle", $hMem)
	If @error Then Return SetError(@error, @extended, False)
	Return $aResult[0]
EndFunc

Func NT_SUCCESS($status)
    If 0 <= $status And $status <= 0x7FFFFFFF Then
        Return True
    Else
        Return False
    EndIf
EndFunc