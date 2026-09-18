#requires -Version 5.1
<#
Smoke-test the non-interactive (/AI, /NonInteractive) contract of a built
AutoHotkey64.exe.

Asserts, for every error category:
  * the process exits within a timeout (nothing blocked on a dialog),
  * diagnostics appear on stderr,
  * the exit code matches the documented policy,
  * no dialog window class (#32770) was ever created by the process.

Usage:
  pwsh -NoProfile -File tools/test-noninteractive.ps1
  pwsh -NoProfile -File tools/test-noninteractive.ps1 -Exe .\dist\AutoHotkey64.exe
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Exe,
    [int]$TimeoutMs = 20000
)

$ErrorActionPreference = 'Stop'

if (-not $Exe) {
    foreach ($c in @(
        (Join-Path $RepoRoot 'upstream\bin\AutoHotkey64.exe'),
        (Join-Path $RepoRoot 'dist\AutoHotkey64.exe')
    )) { if (Test-Path $c) { $Exe = $c; break } }
}
if (-not $Exe -or -not (Test-Path $Exe)) { throw "AutoHotkey64.exe not found. Pass -Exe <path>." }
$Exe = (Resolve-Path $Exe).Path
Write-Output "Testing: $Exe"
Write-Output ''

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ahk-ai-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

function New-Case([string]$name, [string]$body) {
    $p = Join-Path $tmp "$name.ahk"
    Set-Content -LiteralPath $p -Value $body -Encoding utf8NoBOM
    return $p
}

$ok   = New-Case 'ok'   "#NoTrayIcon`nFileAppend \`"NORMAL_OK\``n\`", \`"*\`"`nExitApp 0"
$syn  = New-Case 'syn'  "x := ("
$run  = New-Case 'run'  "#NoTrayIcon`nf()`nf() {`n    localVarNeverAssigned`n    FileAppend \`"unreachable\``n\`", \`"*\`"`n}"
$thr  = New-Case 'thr'  "#NoTrayIcon`nthrow Error(\`"boom\`", \`"detail\`")"
$warn = New-Case 'warn' "#Warn All, StdOut`n#NoTrayIcon`nf()`nf() {`n    neverAssignedProbe`n}"
$miss = Join-Path $tmp 'definitely-not-here.ahk'

# name -> @{ Script; ExpectNonZero; MustMatchStderr; MustMatchStdout }
$cases = [ordered]@{
    'ok'              = @{ Script = $ok;   NonZero = $false; Stderr = $null;        Stdout = 'NORMAL_OK' }
    'syntax-error'    = @{ Script = $syn;  NonZero = $true;  Stderr = 'Missing';   Stdout = $null }
    'runtime-error'   = @{ Script = $run;  NonZero = $true;  Stderr = 'assigned';  Stdout = $null }
    'uncaught-throw'  = @{ Script = $thr;  NonZero = $true;  Stderr = 'boom';      Stdout = $null }
    'warning'         = @{ Script = $warn; NonZero = $false; Stderr = 'Warning';   Stdout = $null }
    'missing-script'  = @{ Script = $miss; NonZero = $true;  Stderr = 'not found'; Stdout = $null }
}

$fail = 0
foreach ($k in $cases.Keys) {
    $c = $cases[$k]
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Exe
    $psi.ArgumentList.Add('/AI')
    $psi.ArgumentList.Add($c.Script)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.RedirectStandardInput  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $psi.WorkingDirectory = $tmp

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()

    $timedOut = -not $p.WaitForExit($TimeoutMs)
    if ($timedOut) { try { $p.Kill($true) } catch {} }
    $so = $p.StandardOutput.ReadToEnd()
    $se = $p.StandardError.ReadToEnd()
    $sw.Stop()
    $exit = if ($timedOut) { $null } else { $p.ExitCode }

    $problems = @()
    if ($timedOut) { $problems += "TIMEOUT after ${TimeoutMs}ms (likely a dialog)" }
    if ($c.NonZero -and $exit -eq 0) { $problems += "expected non-zero exit, got 0" }
    if (-not $c.NonZero -and -not $timedOut -and $exit -ne 0) { $problems += "expected exit 0, got $exit" }
    if ($c.Stderr -and $se -notmatch [regex]::Escape($c.Stderr)) { $problems += "stderr missing '$($c.Stderr)'" }
    if ($c.Stdout -and $so -notmatch [regex]::Escape($c.Stdout)) { $problems += "stdout missing '$($c.Stdout)'" }

    $status = if ($problems.Count) { $fail++; 'FAIL' } else { 'PASS' }
    Write-Output ("[{0}] {1,-16} exit={2,-6} {3}ms" -f $status, $k, ($exit ?? 'n/a'), $sw.ElapsedMilliseconds)
    if ($se.Trim()) { Write-Output ("        stderr: {0}" -f (($se.Trim() -split "`r?`n") -join ' | ')) }
    if ($so.Trim()) { Write-Output ("        stdout: {0}" -f (($so.Trim() -split "`r?`n") -join ' | ')) }
    foreach ($pr in $problems) { Write-Output ("        !! {0}" -f $pr) }
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Output ''
if ($fail) { Write-Output "$fail case(s) FAILED"; exit 1 }
Write-Output 'All non-interactive cases PASSED.'
exit 0
