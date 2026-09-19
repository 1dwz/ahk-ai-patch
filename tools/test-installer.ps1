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
    # Built-in function count of the build under test.  The default matches this
    # patch set, which does not add or remove any built-in.
    [int]    $ExpectedFunctions = 354,
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
    $v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path -EA SilentlyContinue).Path
    if ($null -eq $v) { return '' }
    return $v
}

# Every read here is tolerant on purpose: on a clean CI runner AutoHotkey has
# never been installed, so these keys legitimately do not exist.  Under
# Set-StrictMode a missing property throws, which would fail the test for
# "nothing was installed yet" rather than for a real problem.
function Get-AhkAssoc {
    $progId = $null
    $cmd = $null
    $k = Get-ItemProperty 'HKLM:\SOFTWARE\Classes\.ahk' -EA SilentlyContinue
    if ($null -ne $k) { $progId = $k.PSObject.Properties['(default)'].Value }

    $c = Get-ItemProperty 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript\shell\open\command' -EA SilentlyContinue
    if ($null -ne $c) { $cmd = $c.PSObject.Properties['(default)'].Value }

    [pscustomobject]@{ ProgId = $progId; Command = $cmd }
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

foreach ($f in 'BUILTIN_API.md', 'builtin-api.json', 'v2-gotchas.md', 'debugging.md') {
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
Check '.ahk maps to AutoHotkeyScript' ($afterAssoc.ProgId -eq 'AutoHotkeyScript') $afterAssoc.ProgId
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
    Check "AutoHotkey$arch.exe /dump-api -> $ExpectedFunctions" ($r.ExitCode -eq 0 -and $n -eq $ExpectedFunctions) "exit=$($r.ExitCode) n=$n"
}

# The install dir must not carry any external DLL dependency.
$dumpbin = (Get-ChildItem 'C:\BuildTools\VC\Tools\MSVC' -Directory -EA SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1)
if ($dumpbin) {
    $dumpbin = Join-Path $dumpbin.FullName 'bin\Hostx64\x64\dumpbin.exe'
    $vcvars = 'C:\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
    if ((Test-Path $dumpbin) -and (Test-Path $vcvars)) {
        $dep = cmd /c "`"$vcvars`" >nul 2>&1 && `"$dumpbin`" /dependents `"$InstallDir\AutoHotkey64.exe`"" 2>&1 | Out-String
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

    # There are two legitimate environments and the invariant differs:
    #
    #   before had a command  -> rollback must put it back, character for
    #                            character, because the user had a working
    #                            association before we touched it.
    #   before had none       -> a clean machine (a CI runner).  There is no
    #                            upstream launcher to restore, so "restored"
    #                            means the association no longer points at us.
    #                            Asserting equality here would demand we invent
    #                            a command pointing at a file that does not
    #                            exist, which is worse than leaving it unset.
    if ($beforeAssoc.Command) {
        Check 'association command restored' ($finalAssoc.Command -eq $beforeAssoc.Command) "was='$($beforeAssoc.Command)' now='$($finalAssoc.Command)'"
        Check '.ahk ProgID restored' ($finalAssoc.ProgId -eq $beforeAssoc.ProgId)
    }
    else {
        if ($finalAssoc.Command) {
            Check 'association no longer points at the install dir' ($finalAssoc.Command -notlike "*$InstallDir*") $finalAssoc.Command
            Check '.ahk ProgID restored' ($finalAssoc.ProgId -eq $beforeAssoc.ProgId)
        }
        else {
            Write-Host '  (clean machine: no prior association, nothing to restore)'
            Check 'association left unset rather than pointing at a dead path' $true
        }
    }
}

Write-Host ''
Write-Host ("{0} passed, {1} failed" -f $script:pass, $script:fail) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
exit $(if ($script:fail) { 1 } else { 0 })
