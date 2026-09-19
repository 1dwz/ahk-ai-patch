# Runs the FULL installer suite in a state that matches a GitHub runner.
#
# Two earlier CI failures were invisible locally, for the same reason both
# times: this machine is not like a runner.
#
#   1. A missing AutoHotkeyScript key made a '(default)' read throw under
#      StrictMode.
#   2. The uninstaller left the .ahk association pointing at a program it had
#      just deleted, because there was no upstream launcher to restore.  A
#      first attempt at this simulation MISSED it: it deleted the registry key
#      but left C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe on disk, so the
#      uninstaller happily found an upstream to restore.
#
# So this now hides BOTH: it exports and deletes the registry subtree AND
# temporarily moves the UX launcher out of the way.  That combination is what a
# runner actually looks like.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$progId = 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript'
$ux     = 'C:\Program Files\AutoHotkey\UX'
$v2     = 'C:\Program Files\AutoHotkey\v2'
$stash  = Join-Path $env:TEMP ('ahkux-' + [guid]::NewGuid().ToString('n'))
$regBk  = Join-Path $env:TEMP ('ahkassoc-bk-' + [guid]::NewGuid().ToString('n') + '.reg')

$hadKey = Test-Path $progId
$hadUx  = Test-Path $ux
$hadV2  = Test-Path $v2

New-Item -ItemType Directory -Path $stash -Force | Out-Null

try {
    if ($hadKey) {
        & reg.exe export 'HKLM\SOFTWARE\Classes\AutoHotkeyScript' $regBk /y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "reg export failed ($LASTEXITCODE)" }
        Remove-Item $progId -Recurse -Force
        Write-Host 'removed the AutoHotkeyScript key'
    }

    # Move the candidate upstream launchers out of the way.  A runner has never
    # had these, and their presence is exactly what hid the dangling-association
    # bug the first time.
    if ($hadUx) { Move-Item $ux (Join-Path $stash 'UX') -Force; Write-Host 'hid UX\' }
    if ($hadV2) { Move-Item $v2 (Join-Path $stash 'v2') -Force; Write-Host 'hid v2\' }

    Write-Host ''
    Write-Host '=== running test-installer.ps1 as a runner would ===' -ForegroundColor Cyan
    & pwsh -NoProfile -File 'C:\ProgramData\Autohotkey\ahk-patch\tools\test-installer.ps1'
    $rc = $LASTEXITCODE
    Write-Host ''
    Write-Host "test-installer.ps1 exit=$rc" -ForegroundColor $(if ($rc) { 'Red' } else { 'Green' })
    if ($rc -ne 0) { exit 1 }
}
finally {
    # Restore in the reverse order, and never leave the machine missing paths.
    if (Test-Path (Join-Path $stash 'UX')) { Move-Item (Join-Path $stash 'UX') $ux -Force }
    if (Test-Path (Join-Path $stash 'v2')) { Move-Item (Join-Path $stash 'v2') $v2 -Force }
    if ($hadKey -and (Test-Path $regBk)) {
        & reg.exe import $regBk | Out-Null
    }
    Remove-Item $stash -Recurse -Force -EA SilentlyContinue
    Remove-Item $regBk -Force -EA SilentlyContinue

    Write-Host ''
    Write-Host ("restored: UX={0} v2={1} key={2}" -f (Test-Path $ux), (Test-Path $v2), (Test-Path $progId))
}
