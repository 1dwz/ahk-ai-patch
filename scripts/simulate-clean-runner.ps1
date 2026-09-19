# Verifies test-installer.ps1 survives a clean machine, by actually removing the
# AutoHotkey association keys and running the test's snapshot logic.
#
# The CI runner has never had AutoHotkey installed, so
#   HKLM:\SOFTWARE\Classes\AutoHotkeyScript\shell\open\command
# does not exist.  Reading '(default)' from a missing key throws under
# Set-StrictMode -Version Latest, which is exactly how the first CI run failed.
#
# This machine HAS those keys, so the only honest check is to back them up,
# delete them, exercise the code, and restore them.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$key = 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript'
if (-not (Test-Path $key)) { throw 'precondition: no AutoHotkeyScript key to remove' }

$backup = Join-Path $env:TEMP ('ahkassoc-backup-' + [guid]::NewGuid().ToString('n') + '.reg')
# Export the whole subtree so the restore is exact, including every verb.
& reg.exe export 'HKLM\SOFTWARE\Classes\AutoHotkeyScript' $backup /y | Out-Null
if ($LASTEXITCODE -ne 0) { throw "reg export failed ($LASTEXITCODE)" }
Write-Host "backed up to $backup"

try {
    Remove-Item $key -Recurse -Force
    Write-Host ("key removed; still present: {0}" -f (Test-Path $key))

    # Now run the helper as the test does.  Under StrictMode a missing property
    # must not throw.
    $src = Get-Content 'C:\ProgramData\Autohotkey\ahk-patch\tools\test-installer.ps1' -Raw
    $s = $src.IndexOf('function Get-MachinePath')
    $e = $src.IndexOf('$isAdmin =')
    Invoke-Expression $src.Substring($s, $e - $s)

    $assoc = Get-AhkAssoc
    if ($null -ne $assoc.Command) { throw "expected null Command, got '$($assoc.Command)'" }
    Write-Host '  Get-AhkAssoc returned null Command without throwing'
    Write-Host ("  ProgId = {0}" -f $(if ($null -eq $assoc.ProgId) { '<null>' } else { $assoc.ProgId }))

    # The rollback assertion compares before/after.  Both being null must be a
    # PASS (nothing was there, so nothing should be restored), not a throw.
    $before = $assoc
    $after  = Get-AhkAssoc
    $same = ($after.Command -eq $before.Command)
    if (-not $same) { throw 'null-to-null comparison reported different' }
    Write-Host '  null-to-null rollback comparison reports equal (PASS)'

    $p = Get-MachinePath
    if ($p.Length -lt 10) { throw "Get-MachinePath returned '$p'" }
    Write-Host ("  Get-MachinePath ok ({0} chars)" -f $p.Length)

    Write-Host ''
    Write-Host 'clean-machine simulation: OK'
}
finally {
    if (Test-Path $backup) {
        & reg.exe import $backup | Out-Null
        Write-Host ("restored key: {0}" -f (Test-Path $key))
        Remove-Item $backup -Force -EA SilentlyContinue
    }
}
