#requires -Version 5.1
<#
Verify that /AI diagnostics reach a REAL console with no redirection.

This is the case the whole switch exists for -- `AutoHotkey.exe /AI script.ahk`
typed into a terminal -- and it is the one that silently broke, because
AutoHotkey.exe is a Windows-GUI-subsystem binary: started from a console without
redirection it has no attached console, so GetStdHandle(STD_ERROR_HANDLE) led
nowhere and every diagnostic was discarded.  The stock interpreter reproduced it
perfectly (nothing printed, and it did not even exit).

A plain `cmd /c` or PowerShell pipe cannot test this, because those redirect the
child's stderr and hand it a pipe -- which makes the diagnostic visible and hides
the bug.  So the child is launched under a console this script owns, and the
console buffer is read back afterwards (tools/ConsoleProbe.cs via AhkAi.psm1).

Usage:
  pwsh -NoProfile -File tools/test-console-visibility.ps1 -Exe dist\AutoHotkey64.exe

Exit code 0 when the diagnostic appears on a bare console, 1 otherwise.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Exe,
    [string]$RepoRoot = ''
)
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

# -Exe a,b, as in the other multi-target suites.
$subjects = @($Exe -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($subjects.Count -gt 1) {
    $rc = 0
    foreach ($s in $subjects) {
        & $PSCommandPath -RepoRoot $RepoRoot -Exe $s
        if ($LASTEXITCODE) { $rc = $LASTEXITCODE }
    }
    exit $rc
}
$Exe = $subjects[0]

$Exe = (Resolve-Path $Exe).Path
if (-not (Test-Path $Exe)) { throw "interpreter not found: $Exe" }

$probe = Build-ConsoleProbe -RepoRoot $RepoRoot

# --- the script under test --------------------------------------------------
# Two lines: the first is loadable, the second is an unassigned-variable error,
# so /AI must emit a diagnostic and exit 1.  No BOM, LF only.
$work = Join-Path $env:TEMP ('ahk-console-{0}' -f ([guid]::NewGuid().ToString('N')))
New-Item -ItemType Directory -Force -Path $work | Out-Null
$script = Join-Path $work 'probe case.ahk'   # a space, so quoting is exercised
[System.IO.File]::WriteAllText($script,
    "#Requires AutoHotkey v2.0`nxxx`n",
    (New-Object System.Text.UTF8Encoding($false)))

try {
    # Do NOT pipe or redirect anything: that hands the child a pipe, which makes
    # the diagnostic visible and hides the bug.  The probe writes the console
    # contents to a file instead, so the verdict does not depend on stdout.
    $r = Invoke-AhkInConsole -Probe $probe -Exe $Exe -Arguments @('/AI', $script)
    $exit = $r.ExitCode
    $text = $r.Console
    $trimmed = $text.Trim()

    Write-Output "interpreter : $Exe"
    Write-Output "script      : $script"
    Write-Output "exit code   : $exit"
    Write-Output "console out : $($trimmed.Length) char(s)"
    if ($trimmed) {
        Write-Output '--- captured console text ---'
        $trimmed -split "`n" | ForEach-Object { Write-Output "  $_" }
        Write-Output '--- end ---'
    }

    $ok = $true
    if ($r.Blocked) {
        Write-Output '::error::the interpreter never exited -- a modal dialog is up, so /AI did not suppress it'
        $ok = $false
    }
    if ($trimmed.Length -eq 0) {
        Write-Output '::error::/AI printed NOTHING to a bare console; AttachConsole probably regressed'
        $ok = $false
    }
    if ($text -notmatch 'has not been assigned a value') {
        Write-Output '::error::the expected diagnostic text is missing from the console output'
        $ok = $false
    }
    if ($text -notmatch 'probe case\.ahk \(\d+\)') {
        Write-Output '::error::diagnostic does not name the script and line'
        $ok = $false
    }
    if ($exit -ne 1) {
        Write-Output "::error::expected exit 1 for an unhandled error, got $exit"
        $ok = $false
    }

    if ($ok) { Write-Output 'OK: /AI diagnostics are visible on an unredirected console' }
    exit $(if ($ok) { 0 } else { 1 })
}
finally {
    Remove-Item $probe -Force -ErrorAction SilentlyContinue
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}
