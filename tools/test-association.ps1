#Requires -Version 5.1
<#
.SYNOPSIS
    Proves the .ahk association launches a script.

.DESCRIPTION
    test-installer.ps1 checks the association's registry value, which is not the
    same as the association working: ShellExecute resolves .ahk through the
    ProgID, and a plausible-looking command string can still fail to run.

    So this installs, writes a script, then launches it the way Explorer does --
    through .ahk, not through the interpreter -- and waits for evidence.

    IMPORTANT, and the reason this file is fussy about how it writes the script:
    a double-clicked .ahk runs WITHOUT /AI, because /AI is an interpreter flag
    and the registry open command cannot carry one.  A malformed script therefore
    raises a modal error dialog instead of printing to stderr.  So the script is
    validated with /AI first, by running the very same file through the
    interpreter, and only then handed to the association.  That way a failure
    here means the association is broken, not that the script was bad.

    The script writes a file rather than exiting with a code, because
    ShellExecute gives us no access to the child's exit code.
#>
[CmdletBinding()]
param(
    [string] $Setup = (Join-Path $PSScriptRoot '..\dist\AHK-v2-Setup.exe'),
    [string] $InstallDir = 'C:\Program Files\AHK-v2'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:fail = 0
$script:pass = 0
function Check([string] $n, [bool] $ok, [string] $d = '') {
    if ($ok) { $script:pass++; Write-Host "  PASS  $n" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  FAIL  $n  $d" -ForegroundColor Red }
}

$isAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'run elevated' }

$Setup = (Resolve-Path $Setup).Path
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

$work = Join-Path $env:TEMP ('ahkassoc-' + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Path $work -Force | Out-Null

# A script is written by concatenating lines in an array, never with a
# here-string: PowerShell treats `n inside "..." as a real newline, which
# silently splits an AHK string literal across two lines and makes the script
# unloadable.  Building the body line by line keeps every line intact.
function New-Probe([string] $name, [string] $marker, [string] $tag) {
    $path = Join-Path $work $name
    $esc = $marker.Replace('\', '\\')   # AHK needs the backslashes doubled
    # The separator is a pipe rather than an escape sequence: AHK v2 string
    # escapes are `t/`n, not \t/\n, so a literal "\t" would land in the file.
    $lines = @(
        'FileAppend("' + $tag + '|" . A_PtrSize*8 . "|ver=" . A_AhkVersion . "`n", "' + $esc + '")'
        'ExitApp(0)'
    )
    Set-Content -Path $path -Value $lines -Encoding UTF8
    return $path
}

try {
    Write-Host ''
    Write-Host 'Association launch test' -ForegroundColor Cyan

    & $Setup '/quiet' | Out-Null
    Check 'installer exits 0' ($LASTEXITCODE -eq 0) "exit=$LASTEXITCODE"

    $interp = Join-Path $InstallDir 'AutoHotkey64.exe'
    $marker = Join-Path $work 'ran.txt'
    $probe = New-Probe 'probe.ahk' $marker 'ran'

    Write-Host "  probe script:"
    Get-Content $probe | ForEach-Object { "    $_" }

    # Validate the script BEFORE blaming the association.  Run it with /AI so a
    # syntax error surfaces here as text rather than as a modal dialog later.
    $pre = Invoke-AhkAi -Exe $interp -Arguments @('/AI', $probe) -TimeoutMs 30000
    Check 'probe script is valid (validated with /AI)' ($pre.ExitCode -eq 0) "exit=$($pre.ExitCode) err=$($pre.StdErr)"
    if ($pre.ExitCode -ne 0) { throw "probe script is broken; fix the test, not the installer: $($pre.StdErr)" }
    Check 'probe script writes its marker when run directly' (Test-Path $marker)
    Remove-Item $marker -Force -EA SilentlyContinue

    # Now hand the *same* file to the association, exactly as Explorer would.
    $openCmd = (Get-ItemProperty 'HKLM:\SOFTWARE\Classes\AutoHotkeyScript\shell\open\command' -EA SilentlyContinue).'(default)'
    Write-Host "  open command: $openCmd"

    Check '.ahk maps to AutoHotkeyScript' `
        ((Get-ItemProperty 'HKLM:\SOFTWARE\Classes\.ahk' -EA SilentlyContinue).'(default)' -eq 'AutoHotkeyScript')

    Start-Process -FilePath $probe
    $ran = $false
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-Path $marker) { $ran = $true; break }
        Start-Sleep -Milliseconds 250
    }
    Check 'launching a .ahk through the association runs it' $ran 'no marker after 10s'

    if ($ran) {
        $line = (Get-Content $marker -Raw).Trim()
        Write-Host "  marker: $line"
        $wantArch = if ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }
        Check "ran under the ${wantArch}-bit interpreter" ($line -match ('\|\s*' + $wantArch + '\s*\|')) $line
        Check 'interpreter reports a v2 version' ($line -match 'ver=2\.') $line
    }

    # A second run proves it is not a one-off.
    $m2 = Join-Path $work 'ran2.txt'
    $probe2 = New-Probe 'probe2.ahk' $m2 'ran2'
    $pre2 = Invoke-AhkAi -Exe $interp -Arguments @('/AI', $probe2) -TimeoutMs 30000
    Check 'second probe is valid' ($pre2.ExitCode -eq 0) "exit=$($pre2.ExitCode)"
    Remove-Item $m2 -Force -EA SilentlyContinue

    Start-Process -FilePath $probe2
    $ran2 = $false
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-Path $m2) { $ran2 = $true; break }
        Start-Sleep -Milliseconds 250
    }
    Check 'a second .ahk also runs' $ran2
}
finally {
    # Always remove the install, even if an assertion threw.
    $un = Join-Path $InstallDir 'uninstall.exe'
    if (Test-Path $un) { & $un '/quiet' | Out-Null }
    for ($i = 0; $i -lt 24; $i++) {
        if (-not (Test-Path $InstallDir)) { break }
        Start-Sleep -Milliseconds 500
    }
    Remove-Item $work -Recurse -Force -EA SilentlyContinue
}

Write-Host ''
Write-Host ("{0} passed, {1} failed" -f $script:pass, $script:fail) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
exit $(if ($script:fail) { 1 } else { 0 })
