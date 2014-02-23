#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Tool to manipulate the update speed (TimeAdjustment) of the system clock
#AutoIt3Wrapper_Res_Description=Tool to manipulate the update speed (TimeAdjustment) of the system clock
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Sample by Joakim Schicht
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <Array.au3>
Global $SystemTimeAdjustment = 28
Global $LowRangeArr[1], $HighRangArr[1], $MergedArray[1]
Global $tagSYSTEM_TIME_ADJUST_INFORMATION_QUERY = "ulong TimeAdjustment;ulong TimeIncrement;boolean Disable"
Global $tagSYSTEM_TIME_ADJUST_INFORMATION_SET = "ulong TimeAdjustment;boolean Disable"
$NtSystemInformation = _NtQuerySystemInformation($SystemTimeAdjustment,$tagSYSTEM_TIME_ADJUST_INFORMATION_QUERY)
If @error then Exit
$TimeAdjustmentOrig = DllStructGetData($NtSystemInformation,"TimeAdjustment")
$TimeIncrement = DllStructGetData($NtSystemInformation,"TimeIncrement")
$Disable = DllStructGetData($NtSystemInformation,"Disable")
$Lowest = $TimeAdjustmentOrig/10
$Low = $Lowest
$Highest = $TimeAdjustmentOrig*10
For $i = 1 To 10
	_ArrayAdd($LowRangeArr,$Low)
	$Low += $Lowest
	_ArrayAdd($HighRangArr,$TimeAdjustmentOrig*$i*$i)
Next
;_ArrayDisplay($LowRangeArr,"$LowRangeArr")
;_ArrayDisplay($HighRangArr,"$HighRangArr")
_ArrayDelete($LowRangeArr,0)
_ArrayDelete($LowRangeArr,10)
_ArrayDelete($HighRangArr,0)
_ArrayConcatenate($MergedArray,$LowRangeArr)
_ArrayConcatenate($MergedArray,$HighRangArr)
_ArrayAdd($MergedArray,$TimeAdjustmentOrig*($i*($i+1)))
$MergedArray[0] = 1
;_ArrayDisplay($MergedArray,"$MergedArray")
$Form = GUICreate("System Time Adjustment", 490, 250, -1, -1)
$Label = GUICtrlCreateLabel("Initial values:",20,20,80,20)
$LabelTimeIncrement = GUICtrlCreateLabel("TimeIncrement:",20,40,80,20)
$TimeIncrementValue = GUICtrlCreateLabel($TimeIncrement,120,40,80,20)
$LabelTimeAdjustment = GUICtrlCreateLabel("TimeAdjustment:",20,60,80,20)
$TimeAdjustmentValue = GUICtrlCreateLabel($TimeAdjustmentOrig,120,60,80,20)
$LabelAdjustmentDisable = GUICtrlCreateLabel("Disable:",20,80,80,20)
$AdjustmentDisableValue = GUICtrlCreateLabel($Disable,120,80,80,20)
$slider1 = GUICtrlCreateSlider(10, 120, 200, 20)
GUICtrlSetLimit(-1, 20, 0) ; change min/max value
GUICtrlSetData($slider1, 10) ; set cursor
$LabelSlow = GUICtrlCreateLabel("Slower:",10,140,80,20)
$LabelFast = GUICtrlCreateLabel("Faster:",200,140,80,20)
$ButtonNewTimeAdjustment = GUICtrlCreateButton("Set new TimeAdjustment", 280, 20, 150, 40)
$LabelAjustedValue = GUICtrlCreateLabel("New adjusted value:",280,80,120,20)
$InputAjustedValue = GUICtrlCreateInput("",390,80,90,20)
GUICtrlSetState($InputAjustedValue,$GUI_Disable)
$ButtonRestore = GUICtrlCreateButton("Restore initial values", 280, 120, 150, 40, 0x2000)
$LabelDummy = GUICtrlCreateLabel("----------------------------------------------------------------------------------------------------------------------------------------------------------",10,180,480,20)
$InputSetValueManually = GUICtrlCreateInput("",140,210,110,20)
$ButtonSetValueManually = GUICtrlCreateButton("Set value manually", 280, 200, 150, 40, 0x2000)
GUISetState(@SW_SHOW)

While 1
$nMsg = GUIGetMsg()
Select
	Case $nMsg = $ButtonNewTimeAdjustment
		_SetPrivilege("SeSystemtimePrivilege")
		If @error then MsgBox(0,"Error","Something went wrong when setting SeSystemtimePrivilege")
		$NewTimeAdjustment = $MergedArray[GUICtrlRead($slider1)]
		ConsoleWrite("$NewTimeAdjustment: " & $NewTimeAdjustment & @CRLF)
		$NtSystemInformation = _NtSetSystemInformation($SystemTimeAdjustment,$tagSYSTEM_TIME_ADJUST_INFORMATION_SET,Round($NewTimeAdjustment,0),0)
		If @error then
			MsgBox(0,"Error","Something went wrong when updating the value")
			ContinueLoop
		EndIf
		GUICtrlSetData($InputAjustedValue, $NewTimeAdjustment)
	Case $nMsg = $ButtonRestore
		_SetPrivilege("SeSystemtimePrivilege")
		If @error then MsgBox(0,"Error","Something went wrong when setting SeSystemtimePrivilege")
		$NtSystemInformation = _NtSetSystemInformation($SystemTimeAdjustment,$tagSYSTEM_TIME_ADJUST_INFORMATION_SET,$TimeAdjustmentOrig,0)
		If @error then
			MsgBox(0,"Error","Something went wrong when updating the value")
			ContinueLoop
		EndIf
		GUICtrlSetData($InputAjustedValue, $TimeAdjustmentOrig)
	Case $nMsg = $ButtonSetValueManually
		_SetPrivilege("SeSystemtimePrivilege")
		If @error then MsgBox(0,"Error","Something went wrong when setting SeSystemtimePrivilege")
		$NewTimeAdjustment = GUICtrlRead($InputSetValueManually)
		$NtSystemInformation = _NtSetSystemInformation($SystemTimeAdjustment,$tagSYSTEM_TIME_ADJUST_INFORMATION_SET,$NewTimeAdjustment,0)
		If @error then
			MsgBox(0,"Error","Something went wrong when updating the value")
			ContinueLoop
		EndIf
		GUICtrlSetData($InputAjustedValue, $NewTimeAdjustment)
	Case $nMsg = $GUI_EVENT_CLOSE
		 Exit
EndSelect
WEnd

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