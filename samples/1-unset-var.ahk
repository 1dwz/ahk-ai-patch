#Requires AutoHotkey v2.0
#NoTrayIcon

; Reading a variable that was never assigned is a runtime error.  Under /AI it is
; written to stderr and the process exits 1; stock AutoHotkey raises a dialog
; instead and does not return until someone dismisses it.

UnsetVarDemo()

UnsetVarDemo() {
    FileAppend(neverAssignedVar, "*")
}
