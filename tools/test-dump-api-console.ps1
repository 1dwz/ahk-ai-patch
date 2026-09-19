#requires -Version 5.1
<#
Verify that `AutoHotkey.exe /dump-api` actually prints to a REAL console.

This is the case a user hits by typing the command, and it is the one that
silently broke: AutoHotkey.exe is a Windows-GUI-subsystem binary, so started
from a console without redirection it never inherits that console,
GetStdHandle(STD_OUTPUT_HANDLE) is NULL, and DumpBuiltinApi() returned early --
dropping the whole dump while still exiting 0.  Piping or `> file` always worked,
which is why every automated check was green.

A plain `cmd /c` or PowerShell pipe cannot test this, because those redirect the
child's stdout and hand it a real pipe -- which makes the output visible and
hides the bug.  So the child is launched under a console this script owns, and
the console buffer is read back afterwards.

The probe also self-checks its read-back (sentinels) and runs a positive control
(`/AI` on a bad script, which does call AttachConsole) so that "nothing printed"
can never be confused with "the reader is broken".

One more trap, learned from CI: the dump is ~354 lines but a runner's console
buffer is far shorter, so the output scrolls and only the tail survives -- the
header is gone, and the reader sees the typed-registry section instead.  That is
indistinguishable from "the dump was dropped" and it does NOT reproduce on a
roomy local console.  The probe therefore grows the buffer before the child runs,
and this test forces the cramped case on every machine so the fix is exercised
everywhere rather than only where the screen happens to be small.

Usage:
  pwsh -NoProfile -File tools/test-dump-api-console.ps1 -Exe dist\AutoHotkey64.exe

Exit code 0 when the table appears on a bare console, 1 otherwise.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Exe,
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$Exe = (Resolve-Path $Exe).Path
if (-not (Test-Path $Exe)) { throw "interpreter not found: $Exe" }

# --- build the console-owning launcher -------------------------------------
$probeSrc = Join-Path $RepoRoot 'tools\DumpApiConsoleProbe.cs'
if (-not (Test-Path $probeSrc)) { throw "missing $probeSrc" }
$probeExe = Join-Path $env:TEMP ('ahk-dumpapi-probe-{0}.exe' -f ([guid]::NewGuid().ToString('N')))

$csc = @(
    'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) { throw 'csc.exe not found; cannot build the console probe' }

& $csc /nologo /utf8output "/out:$probeExe" $probeSrc | Out-Null
if (-not (Test-Path $probeExe)) { throw 'failed to compile the console probe' }

# --- the script the positive control uses ----------------------------------
# Loadable, then an unassigned-variable error, so /AI must emit a diagnostic.
$work = Join-Path $env:TEMP ('ahk-dumpapi-{0}' -f ([guid]::NewGuid().ToString('N')))
New-Item -ItemType Directory -Force -Path $work | Out-Null
$badScript = Join-Path $work 'bad.ahk'
[System.IO.File]::WriteAllText($badScript,
    "#Requires AutoHotkey v2.0`nxxx`n",
    (New-Object System.Text.UTF8Encoding($false)))

$capture = Join-Path $work 'report.txt'

try {
    # Do NOT pipe or redirect the probe: piping gives it a redirected stdout and
    # a console-owning launcher cannot be observed through a pipe -- exactly the
    # condition that hides the bug under test.  It writes its findings to
    # $capture and carries the verdict in its exit code.
    # Run the probe with a deliberately CRAMPED console.
    #
    # Emulating a small console is the point, not an accident: CI reported the fix
    # as still-broken on a healthy local machine, because a runner's console is
    # far shorter than the ~354-line dump.  The child's output then scrolls and
    # only the tail remains, so the reader finds the typed-registry section and
    # misses the "# AutoHotkey built-in functions" header -- indistinguishable
    # from "the dump was dropped".
    #
    # Passing the emulate height forces that condition on every machine, so the
    # grow-the-buffer fix is exercised here and a regression fails locally too
    # rather than only on CI.
    & $probeExe $Exe $capture $badScript 4000 30
    $exit = $LASTEXITCODE
    $text = if (Test-Path $capture) { [System.IO.File]::ReadAllText($capture) } else { '' }

    Write-Output "interpreter : $Exe"
    Write-Output ''
    ($text.Trim() -split "`r?`n") | Where-Object { $_ } | ForEach-Object { Write-Output "  $_" }
    Write-Output ''

    $ok = $true
    if ($text -notmatch 'read-back reliable\s*:\s*True') {
        Write-Output '::error::the console read-back is unreliable; this run proves nothing'
        $ok = $false
    }
    if ($text -match 'console buffer rows\s*:\s*(\d+)' -and [int]$Matches[1] -lt 4000) {
        Write-Output "::error::the console buffer was not grown (rows=$($Matches[1])); the dump can scroll out of it"
        $ok = $false
    }
    if ($text -notmatch 'case 1 prints the table\s*:\s*True') {
        Write-Output '::error::/dump-api printed NOTHING to a bare console (the dump was dropped)'
        $ok = $false
    }
    if ($text -notmatch 'case 3 /AI reaches console\s*:\s*True') {
        Write-Output '::error::the positive control failed: /AI output is also invisible, so the console is unusable'
        $ok = $false
    }
    if ($exit -ne 0 -and $ok) {
        Write-Output "::error::probe exited $exit despite the checks above passing"
        $ok = $false
    }

    if ($ok) { Write-Output 'OK: /dump-api output is visible on an unredirected console' }
    exit ($ok ? 0 : 1)
}
finally {
    Remove-Item $probeExe -Force -ErrorAction SilentlyContinue
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}
