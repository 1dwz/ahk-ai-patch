#Requires -Version 5.1
<#
.SYNOPSIS
    Builds AHK-v2-Setup.exe: a single self-extracting installer.

.DESCRIPTION
    Produces one exe that carries AutoHotkey64.exe, AutoHotkey32.exe and the
    documentation set, then installs them to C:\Program Files\AHK-v2.

    The payload is deflate-compressed and appended to the compiled installer,
    followed by a trailer (magic + index offset/length + blob offset).  The
    installer reads its own file to find the payload, so nothing is extracted
    at build time and only one file ships.

    Layout inside the exe:

        [ AhkSetup.exe bytes ]
        [ deflate-compressed file blobs ]
        [ UTF-8 index: name \t offset \t length \n ... ]
        [ magic "AHKSETUP1" | indexOffset | indexLength | blobOffset ]

.PARAMETER Dist
    Directory holding AutoHotkey64.exe / AutoHotkey32.exe and the docs.

.PARAMETER OutFile
    Destination for the finished installer.

.PARAMETER DocFiles
    Which documentation files to bundle.  Defaults to the AI-facing doc set;
    the point of the installer is that an agent can read the function
    signatures straight out of the install directory.
#>
[CmdletBinding()]
param(
    [string] $Dist    = (Join-Path $PSScriptRoot '..\dist'),
    [string] $OutFile = (Join-Path $PSScriptRoot '..\dist\AHK-v2-Setup.exe'),
    [string[]] $DocFiles = @('BUILTIN_API.md', 'builtin-api.json', 'v2-gotchas.md', 'debugging.md', 'README-AI.md'),
    [string[]] $ExtraDoc = @()   # resolved relative to $Dist; missing files warn, not fail
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step([string] $msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$Dist = (Resolve-Path $Dist).Path

# ---------------------------------------------------------------- 1) validate

Write-Step 'Checking the payload'

$required = @('AutoHotkey64.exe', 'AutoHotkey32.exe')
foreach ($name in $required) {
    $p = Join-Path $Dist $name
    if (-not (Test-Path $p)) { throw "missing $name in $Dist -- run tools\build.ps1 first" }
}

$docSet = @()
foreach ($name in ($DocFiles + $ExtraDoc)) {
    $p = Join-Path $Dist $name

    # README-AI.md is authored in docs/ rather than copied into dist/, because it
    # describes the install layout rather than the build output.
    if (-not (Test-Path $p)) {
        $alt = Join-Path $root "docs\$name"
        if (Test-Path $alt) {
            Copy-Item $alt $p -Force
            Write-Host "    staged $name from docs\"
        }
    }

    if (Test-Path $p) {
        $docSet += $p
    }
    elseif ($DocFiles -contains $name) {
        throw "missing documentation $name in $Dist -- run tools\build.ps1 first"
    }
    else {
        Write-Warning "optional doc not found, skipping: $name"
    }
}

# Refuse to build an installer around a stock binary: /dump-api is the identity
# check, and a stock interpreter answers 0 functions (or blocks on a dialog).
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force
foreach ($name in $required) {
    $r = Invoke-AhkAi -Exe (Join-Path $Dist $name) -Arguments @('/dump-api') -TimeoutMs 60000
    if ($r.ExitCode -ne 0) { throw "$name failed /dump-api (exit $($r.ExitCode)): $($r.StdErr)" }
    $n = ([regex]::Matches($r.StdOut, '(?m)^\w+\t')).Count
    if ($n -lt 300) { throw "$name reports only $n functions -- not a patched build" }
    Write-Host "    $name : $n functions"
}

# --------------------------------------------------------------- 2) compile

Write-Step 'Compiling the installer'

$csc = Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) {
    $csc = Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path $csc)) {
    # Fall back to a Roslyn csc if the framework one is absent.
    $csc = (Get-ChildItem "$env:ProgramFiles\dotnet\sdk" -Filter csc.exe -Recurse -EA SilentlyContinue |
            Select-Object -First 1).FullName
}
if (-not $csc) { throw 'no C# compiler found (need .NET Framework 4.x or dotnet SDK)' }
Write-Host "    compiler: $csc"

$srcDir = Join-Path $PSScriptRoot 'installer'
$stage  = Join-Path $env:TEMP ('ahksetup-' + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

$probeOut = ''
$probeRc = 1

try {
    $stub = Join-Path $stage 'AhkSetup.exe'
    $cscArgs = @(
        '/nologo'
        '/target:exe'
        '/platform:anycpu'
        '/optimize+'
        "/out:$stub"
        "/win32manifest:$(Join-Path $srcDir 'AhkSetup.manifest')"
        '/reference:System.dll'
        '/reference:System.Core.dll'
        (Join-Path $srcDir 'AhkSetup.cs')
    )

    # The icon is cosmetic; a missing one must not break the build.
    $ico = Join-Path $srcDir 'AhkSetup.ico'
    if (Test-Path $ico) { $cscArgs = @("/win32icon:$ico") + $cscArgs }

    & $csc @cscArgs
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $stub)) { throw "csc failed ($LASTEXITCODE)" }
    Write-Host "    stub: $([math]::Round((Get-Item $stub).Length/1KB,1)) KB"

    # The uninstaller ships inside the payload so the install directory is
    # self-contained: no second download, and uninstall.exe is always the
    # version that matches what was installed.
    $uninstStub = Join-Path $stage 'AhkUninstall.exe'
    $uninstArgs = @(
        '/nologo'
        '/target:exe'
        '/platform:anycpu'
        '/optimize+'
        "/out:$uninstStub"
        "/win32manifest:$(Join-Path $srcDir 'AhkSetup.manifest')"
        '/reference:System.dll'
        '/reference:System.Core.dll'
        (Join-Path $srcDir 'AhkUninstall.cs')
    )
    if (Test-Path $ico) { $uninstArgs = @("/win32icon:$ico") + $uninstArgs }

    & $csc @uninstArgs
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $uninstStub)) { throw "csc failed for the uninstaller ($LASTEXITCODE)" }
    Write-Host "    uninstaller: $([math]::Round((Get-Item $uninstStub).Length/1KB,1)) KB"

    # ------------------------------------------------------------ 3) payload

    Write-Step 'Building the payload'

    # Deterministic order so the same inputs give the same installer bytes.
    $items = @()
    foreach ($name in $required) { $items += , @($name, (Join-Path $Dist $name)) }
    $items += , @('uninstall.exe', $uninstStub)
    foreach ($p in ($docSet | Sort-Object)) { $items += , @(('doc/' + (Split-Path $p -Leaf)), $p) }

    $index = New-Object System.Text.StringBuilder
    $offset = 0L

    $blobPath = Join-Path $stage 'payload.bin'
    $blob = [System.IO.File]::Create($blobPath)
    try {
        foreach ($pair in $items) {
            $relName = $pair[0]
            $srcPath = $pair[1]
            $raw = [System.IO.File]::ReadAllBytes($srcPath)

            $ms = New-Object System.IO.MemoryStream
            try {
                # OptimalLevel: this runs once at build time, and a smaller
                # installer is worth a few extra seconds.
                $ds = New-Object System.IO.Compression.DeflateStream(
                    $ms, [System.IO.Compression.CompressionLevel]::Optimal, $true)
                try { $ds.Write($raw, 0, $raw.Length) } finally { $ds.Dispose() }
                $comp = $ms.ToArray()
            }
            finally { $ms.Dispose() }

            $blob.Write($comp, 0, $comp.Length)
            [void]$index.AppendLine("$relName`t$offset`t$($comp.Length)")

            $ratio = if ($raw.Length -gt 0) { '{0:P0}' -f ($comp.Length / $raw.Length) } else { 'n/a' }
            Write-Host ("    {0,-28} {1,9} -> {2,9}  ({3})" -f $relName, $raw.Length, $comp.Length, $ratio)
            $offset += $comp.Length
        }
    }
    finally { $blob.Dispose() }

    $indexBytes = [System.Text.Encoding]::UTF8.GetBytes($index.ToString())

    # ---------------------------------------------------------------- 4) link

    Write-Step 'Assembling AHK-v2-Setup.exe'

    $outDir = Split-Path $OutFile -Parent
    if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $fs = [System.IO.File]::Create($OutFile)
    try {
        # Stub first, so the exe header stays at offset 0 and Windows can run it.
        $stubBytes = [System.IO.File]::ReadAllBytes($stub)
        $fs.Write($stubBytes, 0, $stubBytes.Length)

        $blobOffset = $fs.Position
        $blobBytes = [System.IO.File]::ReadAllBytes($blobPath)
        $fs.Write($blobBytes, 0, $blobBytes.Length)

        $indexOffset = $fs.Position
        $fs.Write($indexBytes, 0, $indexBytes.Length)

        # Trailer: magic + indexOffset + indexLength + blobOffset, little-endian.
        $magic = [System.Text.Encoding]::ASCII.GetBytes('AHKSETUP1')
        $fs.Write($magic, 0, $magic.Length)
        foreach ($v in @($indexOffset, [int64]$indexBytes.Length, $blobOffset)) {
            $b = [System.BitConverter]::GetBytes([int64]$v)
            $fs.Write($b, 0, $b.Length)
        }
    }
    finally { $fs.Dispose() }

    $final = Get-Item $OutFile
    Write-Host ''
    Write-Host ("    {0}  {1:N0} bytes ({2:N1} MB)" -f $final.Name, $final.Length, ($final.Length / 1MB)) -ForegroundColor Green
    Write-Host ("    sha256 {0}" -f (Get-FileHash $OutFile -Algorithm SHA256).Hash)

    # ------------------------------------------------------------ 5) selftest

    Write-Step 'Self-test: does the installer read its own payload?'

    # A dry run reads the trailer, decompresses every entry and reports what it
    # found, touching neither Program Files nor the registry.  This is the only
    # cheap way to catch a payload-format mistake before shipping.
    $probe = Join-Path $stage 'probe.exe'
    Copy-Item $OutFile $probe -Force
    $probeOut = (& $probe '/dry-run' 2>&1 | Out-String)
    $probeRc = $LASTEXITCODE
    Write-Host $probeOut.TrimEnd()
    if ($probeRc -ne 0) {
        throw "/dry-run failed (exit $probeRc) -- the payload is unreadable"
    }
}
finally {
    Remove-Item $stage -Recurse -Force -EA SilentlyContinue
}

Write-Host ''
Write-Host 'Installer built.' -ForegroundColor Green
