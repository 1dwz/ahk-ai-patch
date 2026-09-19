#requires -Version 5.1
<#
Verify that the system interpreters are the patched ones, and that libcurl is
really linked in.

Two things this exists to catch, both of which were real:

  1. A stock interpreter installed alongside a patched one.  install-patched.ps1
     originally replaced only AutoHotkey64.exe, so any 32-bit script silently ran
     on the stock binary -- no /AI, no HttpRequest, no JsonParse -- and nothing
     reported it, because the size difference is easy to miss and the stdout of a
     passing script looks identical.

  2. A patched binary whose libcurl was accidentally dropped.  /dump-api still
     succeeds in that case, because the function is registered either way, so
     only an actual transfer proves curl is present.

Usage:
  pwsh -NoProfile -File tools/test-system-interpreter.ps1
  pwsh -NoProfile -File tools/test-system-interpreter.ps1 -Offline   # skip network
#>
[CmdletBinding()]
param(
    [string]$TargetDir      = 'C:\Program Files\AutoHotkey\v2',
    [int]$ExpectedFunctions = 357,
    [switch]$Offline
)

$ErrorActionPreference = 'Stop'

# Stock v2.0.28 x64 is 1,284,608 bytes and has no /dump-api at all, so function
# count is the reliable signal; size is reported only as context.
$problems = [System.Collections.Generic.List[string]]::new()

$candidates = @('AutoHotkey64.exe', 'AutoHotkey32.exe')
foreach ($name in $candidates) {
    $path = Join-Path $TargetDir $name
    if (-not (Test-Path $path)) {
        # Absent is not a problem; a stock one present is.
        Write-Output ("{0,-20} : absent (skipped)" -f $name)
        continue
    }
    $size = (Get-Item $path).Length
    if ($size -eq 0) {
        # AutoHotkey.exe is a symlink to the 64-bit binary in some installs.
        Write-Output ("{0,-20} : {1,10:N0} B  (0-byte symlink, skipped)" -f $name, $size)
        continue
    }

    # /dump-api must be invoked through the timeout-aware helper.  A stock
    # binary does not recognise the switch, treats it as a script path, and
    # blocks on a "Script file not found." dialog -- which made this test hang
    # for 5 minutes instead of reporting a problem when pointed at a stock build.
    Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force
    $dump = Invoke-AhkAi -Exe (Resolve-Path $path).Path -Arguments @('/dump-api') -TimeoutMs 15000
    $out = $dump.StdOut
    $exit = $dump.ExitCode
    $blocked = $dump.Blocked
    $names = @([regex]::Matches($out, '(?m)^([A-Za-z_][A-Za-z0-9_]*)\t') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)

    $line = "{0,-20} : {1,10:N0} B  exit={2}  functions={3}" -f $name, $size, $exit, $names.Count

    if ($blocked -or $exit -ne 0 -or $names.Count -ne $ExpectedFunctions) {
        $why = if ($blocked) { 'blocked on a dialog' } else { "exit=$exit, functions=$($names.Count)" }
        $problems.Add("$name is not the patched build ($why; expected $ExpectedFunctions functions). Stock binaries block on a dialog or answer exit 2 / 0 functions. Re-run tools/install-patched.ps1.")
        Write-Output ($line + '  <-- STOCK')
        continue
    }
    foreach ($fn in 'HttpRequest', 'JsonParse', 'JsonStringify') {
        if ($names -notcontains $fn) {
            $problems.Add("$name is patched but missing $fn")
        }
    }
    Write-Output ($line + '  ok')
}

if ($problems.Count) {
    Write-Output ''
    $problems | ForEach-Object { Write-Output "::error::$_" }
    exit 1
}

# A transfer is the only thing that proves the static libcurl is present and
# working; /dump-api would pass even if JSON/HTTP were stubbed out.
if (-not $Offline) {
    $exe = Join-Path $TargetDir 'AutoHotkey64.exe'
    $probe = Join-Path $env:TEMP ('ahk-curl-probe-' + [guid]::NewGuid().ToString('N') + '.ahk')
    $src = @'
#Requires AutoHotkey v2.0
r := HttpRequest("https://example.com/")
s := "status=" r["Status"] " bytes=" r["BodyBytes"] " hasError=" (r.Has("Error") ? 1 : 0)
FileAppend s, "*"
'@
    [System.IO.File]::WriteAllText($probe, $src, (New-Object System.Text.UTF8Encoding($false)))

    # Run from an empty directory so a stray DLL or CA bundle cannot help.
    $iso = Join-Path $env:TEMP ('ahk-curl-iso-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $iso | Out-Null
    Copy-Item $exe (Join-Path $iso 'AutoHotkey64.exe')
    Copy-Item $probe (Join-Path $iso 'probe.ahk')

    try {
        Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force
        $r = Invoke-AhkAi -Exe (Join-Path $iso 'AutoHotkey64.exe') `
            -Arguments @('/AI', (Join-Path $iso 'probe.ahk')) `
            -TimeoutMs 60000 -WorkingDirectory $iso
        $text = $r.StdOut.Trim()
        Write-Output ''
        Write-Output "libcurl (isolated dir, no DLLs) : $text"
        if ($text -notmatch 'status=200' -or $text -notmatch 'hasError=0') {
            Write-Output '::error::the system interpreter could not complete an HTTPS request; libcurl may not be linked in'
            exit 1
        }
        Write-Output 'OK: patched interpreters present and libcurl is linked in'
    } finally {
        Remove-Item $probe -Force -EA SilentlyContinue
        Remove-Item $iso -Recurse -Force -EA SilentlyContinue
    }
}
else {
    Write-Output ''
    Write-Output 'OK: patched interpreters present (network check skipped)'
}

exit 0
