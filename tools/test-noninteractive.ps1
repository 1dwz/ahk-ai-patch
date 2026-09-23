#requires -Version 5.1
<#
Smoke-test the /AI (non-interactive) contract of a patched AutoHotkey.

This script runs the real interpreter and asserts, for every error category,
that
  * the process exits within the timeout (i.e. no dialog is blocking),
  * diagnostics arrive on stderr,
  * the exit code matches the documented policy,
  * normal output still goes to stdout.

It is NOT sufficient on its own.  It always redirects stderr into a pipe (via
Invoke-AhkAi), so it proves the diagnostic BYTES exist but cannot tell whether a
human would ever SEE them on a bare console.  AutoHotkey.exe is a
gui-subsystem binary, so that distinction is real and was a genuine bug: /AI
printed nothing at all in a terminal until AttachConsole was added.  Any claim
about output being visible needs tools/test-console-visibility.ps1 as well,
which owns a real console instead of redirecting one.

Usage:
  pwsh -NoProfile -File tools/test-noninteractive.ps1
  pwsh -NoProfile -File tools/test-noninteractive.ps1 -Exe dist\AutoHotkey64.exe
  pwsh -NoProfile -File tools/test-noninteractive.ps1 -Exe "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
  pwsh -NoProfile -File tools/test-console-visibility.ps1 -Exe dist\AutoHotkey64.exe   # visibility
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Exe,
    [int]$TimeoutMs = 15000
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

# The repository ships two interpreters and the multi-target suites accept
# -Exe a,b, so accept it here too rather than leaving one command line that works
# for some tests and silently means "one file named 'a,b'" for this one.
$subjects = @($Exe -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($subjects.Count -gt 1) {
    $rc = 0
    foreach ($s in $subjects) {
        & $PSCommandPath -RepoRoot $RepoRoot -Exe $s -TimeoutMs $TimeoutMs
        if ($LASTEXITCODE) { $rc = $LASTEXITCODE }
    }
    exit $rc
}
if ($subjects.Count) { $Exe = $subjects[0] }

if (-not $Exe) {
    foreach ($c in @(
        (Join-Path $RepoRoot 'dist\AutoHotkey64.exe'),
        (Join-Path $RepoRoot 'upstream\bin\AutoHotkey64.exe'),
        'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
    )) { if (Test-Path $c) { $Exe = $c; break } }
}
if (-not $Exe -or -not (Test-Path $Exe)) { throw "AutoHotkey64.exe not found. Pass -Exe <path>." }
$Exe = (Resolve-Path $Exe).Path
Write-Output "Testing: $Exe"
Write-Output ''

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-ai-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$enc = New-Object System.Text.UTF8Encoding($false)

function New-Case([string]$name, [string]$body) {
    $p = Join-Path $tmp "$name.ahk"
    [System.IO.File]::WriteAllText($p, $body, $enc)
    return $p
}

$ok   = New-Case 'ok'   "#NoTrayIcon`nFileAppend `"NORMAL_OK``n`", `"*`"`nExitApp 0"
$syn  = New-Case 'syn'  "x := ("
$run  = New-Case 'run'  "#NoTrayIcon`nf()`nf() {`n    localVarNeverAssigned`n    FileAppend `"unreachable``n`", `"*`"`n}"
$thr  = New-Case 'thr'  "#NoTrayIcon`nthrow Error(`"boom`", `"detail`")"
$warn = New-Case 'warn' "#Warn LocalSameAsGlobal, StdOut`n#NoTrayIcon`nglobal gWarnProbe := 1`nf()`nf() {`n    gWarnProbe := 2`n}`nExitApp 0"
$miss = Join-Path $tmp 'definitely-not-here.ahk'

# key -> script, expect-nonzero-exit, stderr substring, stdout substring
$cases = [ordered]@{
    'ok'             = @{ S = $ok;   NonZero = $false; ChkErr = $null;       ChkOut = 'NORMAL_OK' }
    'syntax-error'   = @{ S = $syn;  NonZero = $true;  ChkErr = 'Missing';  ChkOut = $null }
    'runtime-error'  = @{ S = $run;  NonZero = $true;  ChkErr = 'assigned'; ChkOut = $null }
    'uncaught-throw' = @{ S = $thr;  NonZero = $true;  ChkErr = 'boom';     ChkOut = $null }
    'warning'        = @{ S = $warn; NonZero = $false; ChkErr = 'Warning';  ChkOut = $null }
    'missing-script' = @{ S = $miss; NonZero = $true;  ChkErr = 'not found';ChkOut = $null }
}

$fail = 0
foreach ($k in $cases.Keys) {
    $c = $cases[$k]
    $r = Invoke-AhkAi -Exe $Exe -Arguments @('/AI', $c.S) -TimeoutMs $TimeoutMs -WorkingDirectory $tmp

    $problems = @()
    if ($r.Blocked) { $problems += "BLOCKED after ${TimeoutMs}ms (a dialog appeared)" }
    if (-not $r.Blocked) {
        if ($c.NonZero -and $r.ExitCode -eq 0) { $problems += "expected non-zero exit, got 0" }
        if (-not $c.NonZero -and $r.ExitCode -ne 0) { $problems += "expected exit 0, got $($r.ExitCode)" }
    }
    if ($c.ChkErr -and $r.StdErr -notmatch [regex]::Escape($c.ChkErr)) { $problems += "stderr missing '$($c.ChkErr)'" }
    if ($c.ChkOut -and $r.StdOut -notmatch [regex]::Escape($c.ChkOut)) { $problems += "stdout missing '$($c.ChkOut)'" }
    if ($r.StdErr.Trim() -and $c.ChkErr -and -not $r.Blocked) { }

    $status = if ($problems.Count) { $fail++; 'FAIL' } else { 'PASS' }
    $exitTxt = if ($r.Blocked) { 'BLOCKED' } else { "$($r.ExitCode)" }
    Write-Output ("[{0}] {1,-15} exit={2,-8} {3}ms  stderr={4}B" -f $status, $k, $exitTxt, $r.ElapsedMs, $r.StdErr.Length)
    if ($r.StdErr.Trim()) { Write-Output ("        stderr: {0}" -f (($r.StdErr.Trim() -split "`r?`n")[0])) }
    if ($r.StdOut.Trim()) { Write-Output ("        stdout: {0}" -f (($r.StdOut.Trim() -split "`r?`n")[0])) }
    foreach ($pr in $problems) { Write-Output ("        !! {0}" -f $pr) }
}

Remove-Item $tmp -Recurse -Force -EA SilentlyContinue

Write-Output ''
if ($fail) { Write-Output "$fail case(s) FAILED"; exit 1 }
Write-Output 'All non-interactive cases PASSED.'
exit 0
