#requires -Version 5.1
<#
Build the patched AutoHotkey.

Needs MSVC (VS 2022 Build Tools or VS) with the "Desktop development with C++"
workload. vswhere is used to locate the installation, then vcvarsall.bat is
sourced so that cl.exe / link.exe / the Windows SDK are on PATH.

Usage:
  pwsh -NoProfile -File tools/build.ps1
  pwsh -NoProfile -File tools/build.ps1 -Configuration Debug -Platform Win32
#>
[CmdletBinding()]
param(
    [string]$RepoRoot      = '',
    [string]$UpstreamDir,
    [ValidateSet('Release','Debug','Self-contained','Release(mbcs)','Debug(mbcs)','Self-contained(mbcs)')]
    [string]$Configuration = 'Release',
    [ValidateSet('x64','Win32')]
    [string]$Platform      = 'x64',
    [string]$OutDir
)
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }

$ErrorActionPreference = 'Stop'

if (-not $UpstreamDir) { $UpstreamDir = Join-Path $RepoRoot 'upstream' }
$solution = Join-Path $UpstreamDir 'AutoHotkeyx.sln'
if (-not (Test-Path $solution)) {
    throw "solution not found: $solution`nRun tools/apply-patches.ps1 first."
}

# --- locate MSVC ----------------------------------------------------------
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) {
    throw "vswhere.exe not found. Install VS 2022 Build Tools (Desktop development with C++)."
}

$vsPath = (& $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath) -join ''
if (-not $vsPath) {
    throw "No VS installation with the C++ toolset was found by vswhere."
}
Write-Output "VS install : $vsPath"

$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvarsall.bat'
if (-not (Test-Path $vcvars)) { throw "vcvarsall.bat not found under $vsPath" }

$msbuild = Join-Path $vsPath 'MSBuild\Current\Bin\amd64\MSBuild.exe'
if (-not (Test-Path $msbuild)) { $msbuild = Join-Path $vsPath 'MSBuild\Current\Bin\MSBuild.exe' }
if (-not (Test-Path $msbuild)) { throw "MSBuild.exe not found under $vsPath" }

Write-Output "msbuild    : $msbuild"
Write-Output "build      : $Configuration|$Platform"
Write-Output ''

# Export the vcvars environment into this process so MSBuild inherits a full
# toolchain (the .sln relies on the standard VC integration).
$vcvarsArch = if ($Platform -eq 'x64') { 'x64' } else { 'x86' }
$envDump = & cmd.exe /c "`"$vcvars`" $vcvarsArch >nul 2>&1 && set"
foreach ($line in $envDump) {
    if ($line -match '^([^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

$args = @(
    $solution,
    '/nologo',
    '/m',
    '/v:m',
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform"
)

$buildOut = & $msbuild @args 2>&1
$code = $LASTEXITCODE
$buildOut | Where-Object { $_ -match '->|error|warning' } | ForEach-Object { Write-Output $_ }

Write-Output ''
$errs = @($buildOut | Select-String -Pattern ': error ')
Write-Output ("MSBuild exit code: {0}   errors: {1}" -f $code, $errs.Count)
if ($errs.Count) { $errs | Select-Object -First 40 | ForEach-Object { Write-Output $_.Line.Trim() } }

if ($code -ne 0) { exit $code }

# --- report the produced binaries ----------------------------------------
# Naming follows AutoHotkeyx.vcxproj:
#   normal  -> bin[ _debug]\AutoHotkey{32,64}.exe
#   SC      -> bin[ _debug]\<Unicode|ANSI> <32|64>-bit.bin
$isSC = $Configuration -like 'Self-contained*'
$binDir = if ($Configuration -like 'Debug*' -or $Configuration -like '*\(debug\)*') {
    Join-Path $UpstreamDir 'bin_debug'
} else {
    Join-Path $UpstreamDir 'bin'
}

if ($isSC) {
    $bits = if ($Platform -eq 'x64') { '64' } else { '32' }
    $charSet = if ($Configuration -like '*(mbcs)*') { 'ANSI' } else { 'Unicode' }
    $exeName = "$charSet $bits-bit.bin"
} else {
    $exeName = if ($Platform -eq 'x64') { 'AutoHotkey64.exe' } else { 'AutoHotkey32.exe' }
}

$built = Join-Path $binDir $exeName
if (Test-Path $built) {
    Write-Output ''
    Write-Output ("Built: {0}" -f $built)
    Write-Output ("Size : {0:N0} bytes" -f (Get-Item $built).Length)
    if ($OutDir) {
        New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
        Copy-Item $built (Join-Path $OutDir $exeName) -Force
        Write-Output ("Copied to: {0}" -f (Join-Path $OutDir $exeName))

        # Warn if the output does not match docs/ARTIFACT_CONTENTS.txt, which is
        # the same list the CI verify job enforces.  Warning rather than failing:
        # a local -OutDir holds both architectures, which the single-arch CI
        # artifact never does.
        #
        # The payload is the interpreter and nothing else -- no docs, no
        # installer, no sidecar.  Everything the patch set adds is compiled in.
        $manifest = Join-Path $RepoRoot 'docs\ARTIFACT_CONTENTS.txt'
        if (Test-Path $manifest) {
            $archName = if ($Platform -eq 'Win32') { '32' } else { '64' }
            $expected = @(Get-Content $manifest |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and -not $_.StartsWith('#') } |
                ForEach-Object { $_.Replace('<arch>', $archName) })
            $actual = @(Get-ChildItem $OutDir -File | ForEach-Object { $_.Name })
            $unexpected = @($actual | Where-Object { $expected -notcontains $_ })
            $absent = @($expected | Where-Object { $actual -notcontains $_ })
            if ($absent.Count) {
                Write-Warning "artifact missing from $OutDir : $($absent -join ', ')"
            }
            # Both architectures in one local out dir is the normal case; only
            # flag files that are not an interpreter at all.
            $benign = @($unexpected | Where-Object { $_ -match '^AutoHotkey(32|64)\.exe$' })
            $reallyUnexpected = @($unexpected | Where-Object { $benign -notcontains $_ })
            if ($reallyUnexpected.Count) {
                Write-Warning "unexpected file(s) in $OutDir : $($reallyUnexpected -join ', ')"
            }
            if (-not $absent.Count -and -not $reallyUnexpected.Count) {
                Write-Output 'Artifact: matches docs/ARTIFACT_CONTENTS.txt'
            }
        }

        # /AI is only useful if the diagnostics are actually visible, and
        # AutoHotkey.exe is a GUI-subsystem binary, so that depends on
        # AttachConsole.  Warn (do not fail) if a bare console shows nothing --
        # see tools/test-console-visibility.ps1 for why a plain pipe cannot
        # detect this.
        #
        # The check must NOT have its output captured or piped: doing so gives
        # the console-owning launcher a redirected stdout and it can no longer
        # observe a real console, so it always reports failure.  Redirect it to
        # a temp file instead and read that back, leaving its handles alone.
        $visTest = Join-Path $RepoRoot 'tools\test-console-visibility.ps1'
        if (Test-Path $visTest) {
            $visLog = Join-Path $env:TEMP ('ahk-visibility-{0}.txt' -f ([guid]::NewGuid().ToString('N')))
            try {
                & $visTest -Exe (Join-Path $OutDir $exeName) -RepoRoot $RepoRoot *> $visLog
                $visCode = $LASTEXITCODE
                $visOut = if (Test-Path $visLog) { Get-Content $visLog -Raw } else { '' }
                if ($visCode -eq 0 -and $visOut -match 'OK: /AI diagnostics are visible') {
                    Write-Output 'Console : /AI diagnostics visible on a bare console'
                } else {
                    Write-Warning "/AI diagnostics are NOT visible on a bare console (exit $visCode)"
                    ($visOut -split "`r?`n") | Where-Object { $_ } | ForEach-Object { Write-Warning "  $_" }
                }
            } catch {
                Write-Warning "console visibility check could not run: $($_.Exception.Message)"
            } finally {
                Remove-Item $visLog -Force -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    Write-Warning "Build reported success but $built is missing."
}
exit 0
