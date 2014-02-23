System Time Adjustment

A commandline and a GUI application to provide a means of manipulating the speed of the system clock. 
Some Microsoft documentation is available from the winapi functions SetSystemTimeAdjustment; http://msdn.microsoft.com/en-us/library/windows/desktop/ms724943(v=vs.85).aspx and GetSystemTimeAdjustment; http://msdn.microsoft.com/en-us/library/windows/desktop/ms724394(v=vs.85).aspx

Only some strange and fun stuff..


TimeAdjustmentCMD
Has 2 switches:
-g Dump current values
-s Set new values. The -s switch also needs 2 parameters, the new Adjustment value and the new Disable value

Example to dump current config:
TimeAdjustmentCMD.exe -g

Example to revert to systems own internal timesynchronization mechanism:
TimeAdjustmentCMD.exe -s 0 1

Example to set TimeAdjustment value to 10 (veery slow):
TimeAdjustmentCMD.exe -s 10 0

Example to set TimeAdjustment value to 1000000000 (extremely fast):
TimeAdjustmentCMD.exe -s 1000000000 0


TimeAdjustmentGUI
Has 4 main functionalities.
1. Displays current values for TimeIncrement, TimeAdjustment and Disable when program is started.
2. Use slider to configure new values from very slow to very fast system clock. Use button "Set new TimeAdjustment" to activate new values.
3. Restore initial values when program was started, by clicking the button "Restore initial values".
4. Manually set new TimeAdjustment values by filling in the input field at the bottom, and clicking the button "Set value manually".

All new values will be displayed in the field after "New adjusted value:".


The system clock can be frozen by a value of 1. A very high value will make the system clock go grazy.
	

