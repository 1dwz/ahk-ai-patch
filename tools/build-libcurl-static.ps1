#requires -Version 5.1
<#
Build a static libcurl (MSVC, x64, Schannel) from source.

Why this exists: HttpRequest is statically linked, so the repo needs a real
static library (object code), not an import library. The .def file shipped in
tools/curl can only produce an import library, which still depends on the DLL.

The build is deliberately minimal so the dependency chain stays inside Windows
itself (no OpenSSL, no zlib, no brotli, no zstd, no nghttp2):

  * TLS      : Schannel (Windows native) -- also avoids shipping a CA bundle
  * HTTP/2   : off   (would need nghttp2)
  * compress : off   (would need zlib/brotli/zstd)
  * Protocols: HTTP and HTTPS only

That keeps libcurl.lib small and makes the resulting exe depend only on
libraries that already ship with Windows.

Output: third_party/curl-static/lib/libcurl.lib  (+ include/ headers)

Usage:
  pwsh -NoProfile -File tools/build-libcurl-static.ps1
  pwsh -NoProfile -File tools/build-libcurl-static.ps1 -Force     # rebuild
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CurlVersion = '8.22.0',
    [ValidateSet('x64', 'x86', 'both')]
    [string]$Platform = 'both',
    [switch]$Force,
    [switch]$KeepBuild
)

$ErrorActionPreference = 'Stop'

$srcRoot    = Join-Path $RepoRoot 'third_party\src'
$srcDir     = Join-Path $srcRoot "curl-$CurlVersion"
$tarball    = Join-Path $srcRoot "curl-$CurlVersion.tar.gz"
$outDir     = Join-Path $RepoRoot 'third_party\curl-static'
$outInclude = Join-Path $outDir 'include'

# The interpreter compiles http_builtin.cpp for both x86 and x64, so both
# static libraries are needed.
$targets = switch ($Platform) {
    'x64'  { @('x64') }
    'x86'  { @('x86') }
    default { @('x64', 'x86') }
}

function Get-OutLib([string]$arch) {
    $sub = if ($arch -eq 'x64') { 'lib-x64' } else { 'lib-x86' }
    return Join-Path $outDir "$sub\libcurl.lib"
}

$pending = @($targets | Where-Object { $Force -or -not (Test-Path (Get-OutLib $_)) })
if (-not $pending) {
    Write-Output "static libcurl already built for: $($targets -join ', ')"
    Write-Output 'pass -Force to rebuild.'
    exit 0
}
Write-Output "building for : $($pending -join ', ')"

# --- locate a build toolchain --------------------------------------------
function Find-Tool([string]$name, [string[]]$extra) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in $extra) { if (Test-Path $p) { return $p } }
    return $null
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) { throw "vswhere not found at $vswhere" }
$vsPath = (& $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath) -join ''
if (-not $vsPath) { throw "no MSVC toolchain found via vswhere" }
Write-Output "MSVC        : $vsPath"

$cmake = Find-Tool 'cmake' @(
    (Join-Path $vsPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe')
)
if (-not $cmake) { throw "cmake not found" }
# Prefer the CMake bundled with VS so the generator and toolset agree.
$vsCmake = Join-Path $vsPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
if (Test-Path $vsCmake) { $cmake = $vsCmake }

$ninja = Find-Tool 'ninja' @(
    (Join-Path $vsPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe')
)
if (-not $ninja) { throw "ninja not found" }
$vsNinja = Join-Path $vsPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe'
if (Test-Path $vsNinja) { $ninja = $vsNinja }

Write-Output "cmake       : $cmake"
Write-Output "ninja       : $ninja"

# --- fetch the source ----------------------------------------------------
New-Item -ItemType Directory -Force -Path $srcRoot | Out-Null
if (-not (Test-Path $srcDir)) {
    if (-not (Test-Path $tarball)) {
        $url = "https://curl.se/download/curl-$CurlVersion.tar.gz"
        Write-Output "downloading : $url"
        Invoke-WebRequest $url -OutFile $tarball -UseBasicParsing -TimeoutSec 600
    }
    Write-Output "extracting  : curl-$CurlVersion"
    Push-Location $srcRoot
    try { tar -xzf $tarball } finally { Pop-Location }
}
if (-not (Test-Path (Join-Path $srcDir 'CMakeLists.txt'))) {
    throw "curl source not found at $srcDir"
}

# --- import the MSVC environment ----------------------------------------
function Import-MsvcEnv([string]$arch) {
    $bat = if ($arch -eq 'x64') { 'vcvars64.bat' } else { 'vcvars32.bat' }
    $vcvars = Join-Path $vsPath "VC\Auxiliary\Build\$bat"
    if (-not (Test-Path $vcvars)) { throw "$bat not found at $vcvars" }
    Write-Output "vcvars      : $vcvars"
    $envDump = & cmd.exe /c "`"$vcvars`" >nul 2>&1 && set"
    foreach ($line in $envDump) {
        $i = $line.IndexOf('=')
        if ($i -gt 0) {
            $k = $line.Substring(0, $i)
            $v = $line.Substring($i + 1)
            [System.Environment]::SetEnvironmentVariable($k, $v, 'Process')
        }
    }
}

# --- build one architecture ---------------------------------------------
function Build-Arch([string]$arch) {
    $buildDir = Join-Path $srcRoot "build-static-$CurlVersion-$arch"
    $outLib   = Get-OutLib $arch
    $libDir   = Split-Path -Parent $outLib
    $gen      = if ($arch -eq 'x64') { 'x64' } else { 'Win32' }

    Write-Output ''
    Write-Output "=== $arch ==="
    Import-MsvcEnv $arch

    # Static build, Schannel TLS, no external deps, HTTP(S) only.
    $cmakeArgs = @(
        '-S', $srcDir,
        '-B', $buildDir,
        '-G', 'Ninja',
        "-DCMAKE_MAKE_PROGRAM=$ninja",
        '-DCMAKE_BUILD_TYPE=Release',
        "-DCMAKE_SYSTEM_PROCESSOR=$gen",
        '-DBUILD_SHARED_LIBS=OFF',
        '-DBUILD_STATIC_LIBS=ON',
        '-DBUILD_CURL_EXE=OFF',
        '-DBUILD_EXAMPLES=OFF',
        '-DBUILD_TESTING=OFF',
        '-DBUILD_LIBCURL_DOCS=OFF',
        '-DBUILD_MISC_DOCS=OFF',
        '-DENABLE_CURL_MANUAL=OFF',
        '-DCURL_USE_SCHANNEL=ON',
        '-DCURL_USE_OPENSSL=OFF',
        '-DCURL_USE_LIBSSH2=OFF',
        '-DCURL_USE_LIBPSL=OFF',
        '-DUSE_NGHTTP2=OFF',
        '-DUSE_NGTCP2=OFF',
        '-DUSE_LIBIDN2=OFF',
        '-DCURL_ZLIB=OFF',
        '-DCURL_BROTLI=OFF',
        '-DCURL_ZSTD=OFF',
        '-DHTTP_ONLY=ON',
        '-DCURL_DISABLE_LDAP=ON',
        '-DCURL_DISABLE_LDAPS=ON',
        '-DCURL_DISABLE_FTP=ON',
        '-DCURL_DISABLE_FILE=ON',
        '-DCURL_DISABLE_TELNET=ON',
        '-DCURL_DISABLE_DICT=ON',
        '-DCURL_DISABLE_TFTP=ON',
        '-DCURL_DISABLE_RTSP=ON',
        '-DCURL_DISABLE_POP3=ON',
        '-DCURL_DISABLE_IMAP=ON',
        '-DCURL_DISABLE_SMTP=ON',
        '-DCURL_DISABLE_MQTT=ON',
        '-DCURL_DISABLE_GOPHER=ON',
        '-DCURL_DISABLE_SMB=ON',
        '-DCURL_DISABLE_WEBSOCKETS=ON',
        '-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded'
    )
    Write-Output 'configuring ...'
    & $cmake @cmakeArgs
    if ($LASTEXITCODE -ne 0) { throw "cmake configure failed for $arch ($LASTEXITCODE)" }

    Write-Output 'building ...'
    & $cmake --build $buildDir --config Release --parallel
    if ($LASTEXITCODE -ne 0) { throw "cmake build failed for $arch ($LASTEXITCODE)" }

    $builtLib = Get-ChildItem $buildDir -Recurse -Filter 'libcurl*.lib' -EA SilentlyContinue |
        Where-Object { $_.Name -notmatch 'imp' } |
        Sort-Object Length -Descending | Select-Object -First 1
    if (-not $builtLib) { throw "libcurl.lib not found under $buildDir" }

    New-Item -ItemType Directory -Force -Path $libDir | Out-Null
    New-Item -ItemType Directory -Force -Path $outInclude | Out-Null
    Copy-Item $builtLib.FullName $outLib -Force

    # Public headers (curl/curl.h etc.); identical for both architectures.
    $incSrc = Join-Path $buildDir 'include'
    if (Test-Path $incSrc) { Copy-Item (Join-Path $incSrc '*') $outInclude -Recurse -Force }
    Copy-Item (Join-Path $srcDir 'include\*') $outInclude -Recurse -Force

    if (-not $KeepBuild) { Remove-Item $buildDir -Recurse -Force -EA SilentlyContinue }

    Write-Output ("built  : {0}  ({1:N0} bytes)" -f $outLib, (Get-Item $outLib).Length)
}

foreach ($arch in $targets) { Build-Arch $arch }

Write-Output ''
Write-Output ("headers: {0}" -f $outInclude)
Write-Output ("source : {0}" -f $srcDir)
