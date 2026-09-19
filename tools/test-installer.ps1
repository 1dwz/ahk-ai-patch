#Requires -Version 5.1
<#
.SYNOPSIS
    End-to-end test of AHK-v2-Setup.exe: install, verify, uninstall, verify rollback.

.DESCRIPTION
    Runs the real installer and the real uninstaller against the real machine,
    then asserts the observable consequences rather than just "it exited 0":

      before : captures PATH, the .ahk association and the install dir
      install: runs the installer, asserts PATH + association + /dump-api
      remove : runs uninstall.exe, asserts PATH and association were restored
      after  : diffs against the "before" snapshot

    Requires elevation.  Leaves the machine in the state it started in.

.PARAMETER Setup
    The installer to test.

.PARAMETER Keep
    Skip the uninstall step, leaving the install in place for manual inspection.
#>
[CmdletBinding()]
param(
    [string] $Setup = (Join-Path $PSScriptRoot '..\dist\AHK-v2-Setup.exe'),
    [string] $InstallDir = 'C:\Program Files\AHK-v2',
    [switch] $Keep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:fail = 0
$script:pass = 0

function Check([string] $name, [bool] $ok, [string] $detail = '') {
    if ($ok) { $script:pass++; Write-Host ("  PASS  {0}" -f $name) -ForegroundColor Green }
    else { $script:fail++; Write-Host ("  FAIL  {0}  {1}" -f $name, $detail) -ForegroundColor Red }
}

function Get-MachinePath {
    (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path).Path
}

function Get-AhkAssoc {
    $v = (Get-ItemProperty 'HKLM:\SOFTWARE\Classes\.ahk' -EA SilentlyContinue).'(default)'
    $c = (Get-ItemProperty 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript\shell\open\command' -EA SilentlyContinue).'(default)'
    [pscustomobject]@{ ProgId = $v; Command = $c }
}

$isAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'this test must run elevated' }
if (-not (Test-Path $Setup)) { throw "installer not found: $Setup" }

$Setup = (Resolve-Path $Setup).Path
Write-Host ''
Write-Host "Testing $Setup" -ForegroundColor Cyan
Write-Host ("size {0:N0} bytes" -f (Get-Item $Setup).Length)
Write-Host ''

# ------------------------------------------------------------------ snapshot

Write-Host 'Snapshot before install' -ForegroundColor Cyan
$beforePath = Get-MachinePath
$beforeAssoc = Get-AhkAssoc
$beforeExists = Test-Path $InstallDir
Write-Host ("  install dir : {0}" -f $(if ($beforeExists) { 'EXISTS' } else { 'absent' }))
Write-Host ("  .ahk progid : {0}" -f $beforeAssoc.ProgId)
Write-Host ("  open cmd    : {0}" -f $beforeAssoc.Command)
Write-Host ("  PATH has dir: {0}" -f ($beforePath -split ';' -contains $InstallDir))
Write-Host ''

if ($beforeExists) {
    Write-Host 'NOTE: an install already exists; uninstalling first so the test starts clean.' -ForegroundColor Yellow
    $pre = Join-Path $InstallDir 'uninstall.exe'
    if (Test-Path $pre) { & $pre '/quiet' | Out-Null }
    # Wait out the detached self-delete before deciding what is there.
    for ($i = 0; $i -lt 20; $i++) {
        if (-not (Test-Path $InstallDir)) { break }
        Start-Sleep -Milliseconds 500
    }
    if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force -EA SilentlyContinue }

    # Re-snapshot: the pre-clean just changed exactly the state we are about to
    # compare the rollback against, so the earlier values are already stale.
    $beforePath = Get-MachinePath
    $beforeAssoc = Get-AhkAssoc
    Write-Host '  re-snapshotted after the pre-clean.'
}

# ------------------------------------------------------------------- install

Write-Host 'Install' -ForegroundColor Cyan
$sw = [Diagnostics.Stopwatch]::StartNew()
& $Setup '/quiet'
$installRc = $LASTEXITCODE
$sw.Stop()
Write-Host ("  exit {0} in {1:N1}s" -f $installRc, $sw.Elapsed.TotalSeconds)
Check 'installer exits 0' ($installRc -eq 0) "exit=$installRc"

if ($installRc -ne 0) {
    Write-Host "installer failed; stopping." -ForegroundColor Red
    exit 1
}

# -------------------------------------------------------------- post-install

Write-Host ''
Write-Host 'Post-install state' -ForegroundColor Cyan

foreach ($f in 'AutoHotkey64.exe', 'AutoHotkey32.exe', 'uninstall.exe') {
    $p = Join-Path $InstallDir $f
    Check "$f installed" (Test-Path $p) $p
}

foreach ($f in 'BUILTIN_API.md', 'builtin-api.json', 'BUILTIN_HTTP_JSON.md', 'v2-gotchas.md', 'debugging.md') {
    $p = Join-Path $InstallDir "doc\$f"
    Check "doc\$f installed" (Test-Path $p) $p
}

# Sizes must match dist/, i.e. the extraction is byte-exact, not truncated.
foreach ($f in 'AutoHotkey64.exe', 'AutoHotkey32.exe') {
    $src = Join-Path (Split-Path $Setup -Parent) $f
    if (Test-Path $src) {
        $a = (Get-FileHash $src -Algorithm SHA256).Hash
        $b = (Get-FileHash (Join-Path $InstallDir $f) -Algorithm SHA256).Hash
        Check "$f extracted byte-exact" ($a -eq $b) "src=$a got=$b"
    }
}

# PATH
$nowPath = Get-MachinePath
$onPath = @(($nowPath -split ';') | Where-Object { $_.Trim().TrimEnd('\') -eq $InstallDir.TrimEnd('\') })
Check 'install dir on machine PATH' ($onPath.Count -ge 1) ("count=" + $onPath.Count)
$firstPathEntry = ($nowPath -split ';')[0].Trim()
Check 'PATH entry is first (so it wins name resolution)' ($firstPathEntry -eq $InstallDir) "first=$firstPathEntry"
Check 'PATH has no duplicate of the install dir' ($onPath.Count -eq 1) ("count=" + $onPath.Count)

# Association
$afterAssoc = Get-AhkAssoc
Check '.ahk still maps to AutoHotkeyScript' ($afterAssoc.ProgId -eq 'AutoHotkeyScript') $afterAssoc.ProgId
$wantExe = if ([Environment]::Is64BitOperatingSystem) { 'AutoHotkey64.exe' } else { 'AutoHotkey32.exe' }
Check "association points at $wantExe" ($afterAssoc.Command -like "*$wantExe*") $afterAssoc.Command
Check 'association path is inside the install dir' ($afterAssoc.Command -like "*$InstallDir*") $afterAssoc.Command

# The double-click path must NOT carry /AI: that flag suppresses the
# interpreter's dialogs, which would hide errors from humans who run a script by
# double-clicking it.  AI is expected to pass /AI itself on the command line.
Check 'Open verb does not carry /AI (errors stay visible to humans)' `
    ($afterAssoc.Command -notmatch '/AI') $afterAssoc.Command

# No stray extra verb should exist either.
$verbs = @()
$sh = 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript\shell'
if (Test-Path $sh) { $verbs = @(Get-ChildItem $sh | ForEach-Object { $_.PSChildName }) }
Check 'no invented shell verbs were added' ($verbs -notcontains 'runasai') ($verbs -join ',')

# The association must resolve to a real, runnable file.
$assocExe = [regex]::Match($afterAssoc.Command, '"([^"]+\.exe)"').Groups[1].Value
Check 'association target exists' (Test-Path $assocExe) $assocExe

# Real execution through the installed binary.
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force
foreach ($arch in '64', '32') {
    $exe = Join-Path $InstallDir "AutoHotkey$arch.exe"
    $r = Invoke-AhkAi -Exe $exe -Arguments @('/dump-api') -TimeoutMs 60000
    $n = ([regex]::Matches($r.StdOut, '(?m)^\w+\t')).Count
    Check "AutoHotkey$arch.exe /dump-api -> 357" ($r.ExitCode -eq 0 -and $n -eq 357) "exit=$($r.ExitCode) n=$n"
}

# The patched-only functions must be reachable from the installed copy.
$r = Invoke-AhkAi -Exe (Join-Path $InstallDir 'AutoHotkey64.exe') -Arguments @('/dump-api') -TimeoutMs 60000
foreach ($fn in 'HttpRequest', 'JsonStringify', 'JsonParse') {
    Check "$fn present in the installed build" ($r.StdOut -match "(?m)^$fn\t")
}

# The install dir must not carry any external DLL dependency.
$dumpbin = (Get-ChildItem 'C:\BuildTools\VC\Tools\MSVC' -Directory -EA SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1)
if ($dumpbin) {
    $dumpbin = Join-Path $dumpbin.FullName 'bin\Hostx64\x64\dumpbin.exe'
    $vcvars = 'C:\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
    if ((Test-Path $dumpbin) -and (Test-Path $vcvars)) {
        $dep = cmd /c "`"$vcvars`" >nul 2>&1 && `"$dumpbin`" /dependents `"$InstallDir\AutoHotkey64.exe`"" 2>&1 | Out-String
        Check 'no libcurl DLL dependency' ($dep -notmatch 'libcurl') 
        Check 'no non-system DLL beyond Windows' ($dep -notmatch '(?i)\b(msvcp|vcruntime|api-ms-win-crt)')
    }
}

# ----------------------------------------------------------------- uninstall

if ($Keep) {
    Write-Host ''
    Write-Host '-Keep given; skipping uninstall.' -ForegroundColor Yellow
}
else {
    Write-Host ''
    Write-Host 'Uninstall' -ForegroundColor Cyan
    $un = Join-Path $InstallDir 'uninstall.exe'
    & $un '/quiet'
    $unRc = $LASTEXITCODE
    Write-Host ("  exit {0}" -f $unRc)
    Check 'uninstaller exits 0' ($unRc -eq 0) "exit=$unRc"

    Write-Host ''
    Write-Host 'Rollback state' -ForegroundColor Cyan

    Check 'AutoHotkey64.exe removed' (-not (Test-Path (Join-Path $InstallDir 'AutoHotkey64.exe')))
    Check 'AutoHotkey32.exe removed' (-not (Test-Path (Join-Path $InstallDir 'AutoHotkey32.exe')))
    Check 'doc\ removed' (-not (Test-Path (Join-Path $InstallDir 'doc')))

    # uninstall.exe deletes itself from a detached process, so give it a moment.
    for ($i = 0; $i -lt 20; $i++) {
        if (-not (Test-Path (Join-Path $InstallDir 'uninstall.exe'))) { break }
        Start-Sleep -Milliseconds 500
    }
    Check 'uninstall.exe self-removed' (-not (Test-Path (Join-Path $InstallDir 'uninstall.exe')))
    Check 'install dir removed' (-not (Test-Path $InstallDir))

    $finalPath = Get-MachinePath
    $stillThere = @(($finalPath -split ';') | Where-Object { $_.Trim().TrimEnd('\') -eq $InstallDir.TrimEnd('\') })
    Check 'install dir removed from PATH' ($stillThere.Count -eq 0) ("count=" + $stillThere.Count)
    Check 'PATH otherwise unchanged' ($finalPath -eq $beforePath) 'PATH differs from the snapshot'

    $finalAssoc = Get-AhkAssoc
    Check 'association command restored' ($finalAssoc.Command -eq $beforeAssoc.Command) "was='$($beforeAssoc.Command)' now='$($finalAssoc.Command)'"
    Check '.ahk ProgID restored' ($finalAssoc.ProgId -eq $beforeAssoc.ProgId)
}

Write-Host ''
Write-Host ("{0} passed, {1} failed" -f $script:pass, $script:fail) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
exit $(if ($script:fail) { 1 } else { 0 })
