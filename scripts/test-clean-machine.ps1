# Runs the FULL installer end-to-end suite in a state that matches a GitHub
# runner: no AutoHotkeyScript key at all.
#
# This machine has AutoHotkey installed, so the suite passes locally for reasons
# a CI runner does not have.  Verified twice now that this difference hides real
# bugs: first a StrictMode throw on a missing key, then the uninstaller refusing
# to restore an association that never existed.
#
# The AutoHotkeyScript subtree is exported, removed, the suite is run, and the
# subtree is restored from the export.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path 'C:\Program Files\AHK-v2')) { } # informational only

$key = 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript'
$hadKey = Test-Path $key
$backup = Join-Path $env:TEMP ('ahkassoc-bk-' + [guid]::NewGuid().ToString('n') + '.reg')

if ($hadKey) {
    & reg.exe export 'HKLM\SOFTWARE\Classes\AutoHotkeyScript' $backup /y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "reg export failed ($LASTEXITCODE)" }
    Remove-Item $key -Recurse -Force
    Write-Host "removed AutoHotkeyScript (backed up to $backup)`n"
}

try {
    Write-Host '=== running test-installer.ps1 as a clean machine would ===' -ForegroundColor Cyan
    & pwsh -NoProfile -File 'C:\ProgramData\Autohotkey\ahk-patch\tools\test-installer.ps1'
    $rc = $LASTEXITCODE
    Write-Host "`ntest-installer.ps1 exit=$rc" -ForegroundColor $(if ($rc) { 'Red' } else { 'Green' })
    if ($rc -ne 0) { exit 1 }
}
finally {
    if ($hadKey -and (Test-Path $backup)) {
        & reg.exe import $backup | Out-Null
        Write-Host "restored AutoHotkeyScript: $(Test-Path $key)"
        Remove-Item $backup -Force -EA SilentlyContinue
    }
}
