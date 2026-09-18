#requires -Version 5.1
<#
Download a CI-built AutoHotkey from GitHub Actions and optionally smoke-test it.

Usage:
  # latest successful run, x64 Release
  pwsh -NoProfile -File tools/download.ps1

  # specific run / artifact
  pwsh -NoProfile -File tools/download.ps1 -RunId 35368001961 -Artifact AutoHotkey32-Win32-Release

  # download and immediately verify the /AI contract
  pwsh -NoProfile -File tools/download.ps1 -Test
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RunId,
    [string]$Artifact = 'AutoHotkey64-x64-Release',
    [string]$OutDir,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoRoot

if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'download' }

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) not found. Install from https://cli.github.com/"
}

if (-not $RunId) {
    Write-Output "Resolving latest successful 'build' run..."
    $RunId = (gh run list --workflow=build.yml --status=success --limit=1 --json databaseId -q '.[0].databaseId')
    if (-not $RunId) { throw "No successful build run found. Push a commit or run the workflow manually." }
}
Write-Output "Run      : $RunId"
Write-Output "Artifact : $Artifact"

Remove-Item $OutDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

gh run download $RunId -n $Artifact -D $OutDir
if ($LASTEXITCODE -ne 0) { throw "gh run download failed for artifact '$Artifact' in run $RunId" }

Write-Output ''
Write-Output 'Downloaded:'
Get-ChildItem $OutDir -Recurse -File | ForEach-Object {
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    Write-Output ("  {0}  ({1:N0} bytes)" -f $_.FullName, $_.Length)
    Write-Output ("    sha256 {0}" -f $h)
}

if ($Test) {
    $exe = Get-ChildItem $OutDir -Recurse -File -Include 'AutoHotkey*.exe' | Select-Object -First 1
    if (-not $exe) {
        Write-Warning "No AutoHotkey*.exe in the artifact; skipping the smoke test."
    } else {
        Write-Output ''
        & (Join-Path $PSScriptRoot 'test-noninteractive.ps1') -Exe $exe.FullName
        exit $LASTEXITCODE
    }
}
