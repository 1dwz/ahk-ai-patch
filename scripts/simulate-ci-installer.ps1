# Simulates the CI `installer` job locally, using the real dist/ as the two
# downloaded artifacts.  The point is to catch path/naming mistakes in the
# workflow before pushing, because a cloud run takes minutes to fail.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = 'C:\ProgramData\Autohotkey\ahk-patch'
$sim  = Join-Path $env:TEMP ('ahkci-' + [guid]::NewGuid().ToString('n'))

try {
    # Reproduce the workflow's directory shape: separate per-arch downloads,
    # then flatten.
    New-Item -ItemType Directory -Path "$sim/dist/x64"   -Force | Out-Null
    New-Item -ItemType Directory -Path "$sim/dist/win32" -Force | Out-Null
    New-Item -ItemType Directory -Path "$sim/dist/flat"  -Force | Out-Null

    # x64 artifact = exe + generated docs; win32 artifact = exe + its docs.
    Copy-Item (Join-Path $root 'dist/AutoHotkey64.exe') "$sim/dist/x64/" -Force
    Copy-Item (Join-Path $root 'dist/AutoHotkey32.exe') "$sim/dist/win32/" -Force
    foreach ($d in 'BUILTIN_API.md', 'builtin-api.json',
                   'debugging.md', 'v2-gotchas.md', 'README-AI.md') {
        Copy-Item (Join-Path $root "dist/$d") "$sim/dist/x64/" -Force
    }

    "--- flattened payload the packer will see ---"
    Copy-Item "$sim/dist/x64/*"   "$sim/dist/flat" -Force -Recurse
    Copy-Item "$sim/dist/win32/*" "$sim/dist/flat" -Force -Recurse

    $need = 'AutoHotkey64.exe', 'AutoHotkey32.exe'
    foreach ($n in $need) {
        if (-not (Test-Path "$sim/dist/flat/$n")) { throw "dist/flat/$n missing" }
    }
    Get-ChildItem "$sim/dist/flat" | ForEach-Object { "  {0,-28} {1,9}" -f $_.Name, $_.Length }

    "`n--- pack (as the workflow does) ---"
    & (Join-Path $root 'tools/pack-installer.ps1') -Dist "$sim/dist/flat" -OutFile "$sim/dist/AHK-v2-Setup.exe" |
        Select-Object -Last 4
    if ($LASTEXITCODE -ne 0) { throw "pack-installer.ps1 exited $LASTEXITCODE" }

    $setup = "$sim/dist/AHK-v2-Setup.exe"
    if (-not (Test-Path $setup)) { throw 'installer was not produced' }
    "`n  installer: {0:N0} bytes" -f (Get-Item $setup).Length

    "`n--- e2e (as the workflow does) ---"
    & (Join-Path $root 'tools/test-installer.ps1') -Setup $setup | Select-Object -Last 4
    if ($LASTEXITCODE -ne 0) { throw "test-installer.ps1 exited $LASTEXITCODE" }

    "`n--- association (as the workflow does) ---"
    & (Join-Path $root 'tools/test-association.ps1') -Setup $setup | Select-Object -Last 4
    if ($LASTEXITCODE -ne 0) { throw "test-association.ps1 exited $LASTEXITCODE" }

    "`nCI installer job simulation: OK"
}
finally {
    Remove-Item $sim -Recurse -Force -EA SilentlyContinue
}
