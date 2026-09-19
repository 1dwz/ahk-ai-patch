#requires -Version 5.1
<#
Install the patched AutoHotkey build as the system default interpreter,
replacing the stock v2 binaries. Keeps a restorable backup.

Usage:
  pwsh -NoProfile -File tools/install-patched.ps1            # install
  pwsh -NoProfile -File tools/install-patched.ps1 -Revert    # restore stock
  pwsh -NoProfile -File tools/install-patched.ps1 -WhatIfCheck  # verify only

Requires an elevated shell (writes under C:\Program Files).
#>
[CmdletBinding()]
param(
    [string]$RepoRoot  = (Split-Path -Parent $PSScriptRoot),
    [string]$Source,
    [string]$Source32,
    [string]$TargetDir = 'C:\Program Files\AutoHotkey\v2',
    [string]$BackupDir,
    [switch]$Revert,
    [switch]$WhatIfCheck
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

if (-not $Source)    { $Source    = Join-Path $RepoRoot 'dist\AutoHotkey64.exe' }
if (-not $Source32)  { $Source32  = Join-Path $RepoRoot 'dist\AutoHotkey32.exe' }
if (-not $BackupDir) { $BackupDir = Join-Path $RepoRoot 'backup-stock' }

# --- probe helper: does a given exe honour /AI? ---------------------------
function Test-AiBuild([string]$exe) {
    if (-not (Test-Path $exe)) { return @{ Ok = $false; Why = 'missing' } }
    $probe = Join-Path $env:TEMP ('ahk-probe-' + [guid]::NewGuid().ToString('N') + '.ahk')
    [System.IO.File]::WriteAllText($probe, 'x := (', (New-Object System.Text.UTF8Encoding($false)))
    $r = Invoke-AhkAi -Exe (Resolve-Path $exe).Path -Arguments @('/AI', $probe) -TimeoutMs 10000
    Remove-Item $probe -Force -EA SilentlyContinue
    if ($r.Blocked)   { return @{ Ok = $false; Why = 'blocked on a dialog' } }
    if (-not $r.StdErr.Trim()) { return @{ Ok = $false; Why = 'no stderr diagnostic' } }
    return @{ Ok = $true; Exit = $r.ExitCode; First = ($r.StdErr.Trim() -split "`r?`n")[0] }
}

# --- revert ---------------------------------------------------------------
if ($Revert) {
    if (-not (Test-Path $BackupDir)) { throw "no backup found at $BackupDir" }
    $n = 0
    Get-ChildItem $BackupDir -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $TargetDir $_.Name) -Force
        Write-Output ("restored {0}" -f $_.Name)
        $n++
    }
    if (-not $n) { throw "backup dir is empty: $BackupDir" }
    Write-Output ''
    Write-Output 'Stock AutoHotkey v2 restored.'
    exit 0
}

# --- verify the candidate -------------------------------------------------
if (-not (Test-Path $Source)) { throw "patched build not found: $Source`nRun tools/build.ps1 first." }
$src = (Resolve-Path $Source).Path
Write-Output "candidate : $src"
$v = Test-AiBuild $src
if (-not $v.Ok) {
    throw "candidate is NOT the /AI build ($($v.Why)). Refusing to install it over the system interpreter."
}
Write-Output ("verified  : /AI honoured (exit={0})" -f $v.Exit)
Write-Output ("            {0}" -f $v.First)

if ($WhatIfCheck) { Write-Output ''; Write-Output 'Check only; nothing installed.'; exit 0 }

if (-not (Test-Path $TargetDir)) { throw "target dir not found: $TargetDir" }

# --- back up the stock binaries once -------------------------------------
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null }
foreach ($n in 'AutoHotkey64.exe','AutoHotkey.exe','AutoHotkey32.exe','AutoHotkey64_UIA.exe','AutoHotkey32_UIA.exe') {
    $s = Join-Path $TargetDir $n
    $b = Join-Path $BackupDir $n
    if ((Test-Path $s) -and -not (Test-Path $b)) {
        Copy-Item $s $b -Force
        Write-Output ("backed up : {0}" -f $n)
    }
}

# --- install --------------------------------------------------------------
# AutoHotkey.exe is a copy of the 64-bit build (that is how the stock install
# lays it out; it is a symlink in some versions).
$installPlan = @(
    @{ From = $src;   To = 'AutoHotkey64.exe' }
    @{ From = $src;   To = 'AutoHotkey.exe' }
)

# The 32-bit interpreter must be patched too.  Installing only x64 leaves any
# 32-bit script on the stock binary, silently without /AI and without the
# built-in HTTP/JSON -- which is exactly how it was missed the first time.
if (Test-Path $Source32) {
    $src32 = (Resolve-Path $Source32).Path
    Write-Output "candidate : $src32"
    $v32 = Test-AiBuild $src32
    if ($v32.Ok) {
        Write-Output ("verified  : /AI honoured (exit={0})" -f $v32.Exit)
        $installPlan += @{ From = $src32; To = 'AutoHotkey32.exe' }
    } else {
        Write-Warning "32-bit candidate is NOT the /AI build ($($v32.Why)); leaving AutoHotkey32.exe alone."
    }
} else {
    Write-Warning "no 32-bit build at $Source32; AutoHotkey32.exe will stay stock (no /AI, no HTTP/JSON in 32-bit scripts)."
}

foreach ($step in $installPlan) {
    $dest = Join-Path $TargetDir $step.To
    try {
        Copy-Item $step.From $dest -Force
        Write-Output ("installed : {0}" -f $dest)
    } catch {
        Write-Warning ("could not replace {0}: {1}" -f $dest, $_.Exception.Message)
    }
}

# --- verify the installed copies ------------------------------------------
Write-Output ''
$allOk = $true
foreach ($n in 'AutoHotkey64.exe', 'AutoHotkey32.exe') {
    $p = Join-Path $TargetDir $n
    if (-not (Test-Path $p)) { continue }
    $one = Test-AiBuild $p
    if ($one.Ok) {
        Write-Output ("OK  {0} honours /AI (exit={1})" -f $n, $one.Exit)
        Write-Output ("    {0}" -f $one.First)
    } else {
        # Not fatal for the 32-bit binary if it was deliberately left stock, but
        # it must be visible: the silent version of this was the original bug.
        Write-Warning ("{0} does NOT honour /AI ({1})" -f $n, $one.Why)
        if ($n -eq 'AutoHotkey64.exe') { $allOk = $false }
    }
}

if ($allOk) {
    Write-Output ''
    Write-Output ("backup : {0}" -f $BackupDir)
    Write-Output ("revert : pwsh -NoProfile -File tools/install-patched.ps1 -Revert")
} else {
    Write-Error "installed x64 interpreter did NOT honour /AI. Restore with -Revert."
    exit 1
}
