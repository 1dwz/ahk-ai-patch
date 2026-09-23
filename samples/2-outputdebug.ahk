#Requires AutoHotkey v2.0
#NoTrayIcon

; OutputDebug() reaches the debugger AND the command line in this build.
; Run it either way -- the mirror does not depend on the switch:
;   AutoHotkey64.exe /AI samples\2-outputdebug.ahk
;   AutoHotkey64.exe samples\2-outputdebug.ahk
;
; Debug text goes to stderr, FileAppend "*" goes to stdout, so a caller can tell
; the two apart instead of parsing one mixed stream.

value := 6 * 7
OutputDebug 'checkpoint 1: about to compute, value=' value
FileAppend 'result=' value "`n", '*'
OutputDebug 'checkpoint 2: done'
