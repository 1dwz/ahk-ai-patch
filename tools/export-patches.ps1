#requires -Version 5.1
<#
Regenerate patches/ from a working tree that has the changes uncommitted.

NOTE: run this against a checkout whose core.autocrlf is false, otherwise the
exported patch will carry CRLF context and fail to apply on a LF checkout.

Usage:
  pwsh -NoProfile -File tools/export-patches.ps1 -ForkRepo <worktree> -OutDir patches
#>
[CmdletBinding()]
param(
    [string]$ForkRepo = (Join-Path (Split-Path -Parent $PSScriptRoot) 'upstream'),
    [string]$OutDir   = (Join-Path (Split-Path -Parent $PSScriptRoot) 'patches'),
    [string]$Suffix   = ''
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path (Join-Path $ForkRepo '.git'))) { throw "not a git work tree: $ForkRepo" }

# `git add -N` marks new files as intent-to-add so they show up in
# `git diff`; without it, newly added sources would be silently dropped from
# the exported series and the series would not reproduce the build.
$untracked = @(git -C $ForkRepo ls-files --others --exclude-standard)
foreach ($u in $untracked) { git -C $ForkRepo add -N -- $u | Out-Null }

$files = @(git -C $ForkRepo diff --name-only)
if (-not $files) { Write-Output 'No changes to export.'; exit 0 }

# Upstream ships "* text=auto"; make sure the diff has no CRLF noise.
$ac = (git -C $ForkRepo config core.autocrlf)
if ($ac -ne 'false') {
    Write-Warning "core.autocrlf is '$ac' in $ForkRepo; set it to false for stable patches."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Get-ChildItem $OutDir -Filter '*.patch' -ErrorAction SilentlyContinue | Remove-Item -Force

$i = 1
foreach ($f in $files) {
    $slug = ($f -replace '[\\/]', '_' -replace '^source_', '')
    $name = '000{0}-{1}{2}.patch' -f $i, $slug, $Suffix
    $dest = Join-Path $OutDir $name
    $d = @(git -C $ForkRepo diff -- $f)
    # New files need --binary-free full content; git diff already emits a
    # /dev/null -> b/... hunk that git apply recreates.
    # git diff output already uses LF; write it without any translation.
    [System.IO.File]::WriteAllText($dest, ($d -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
    Write-Output ("{0}  <- {1}  ({2} lines)" -f $name, $f, $d.Count)
    $i++
}

Write-Output ''
Write-Output ("Exported {0} patch file(s) to {1}" -f $files.Count, $OutDir)
