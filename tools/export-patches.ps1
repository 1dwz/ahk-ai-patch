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

# Diff against HEAD rather than the index, so the series captures both staged
# and unstaged edits.  Using a bare `git diff` only reports unstaged changes:
# after a `git add -A` it silently exports almost nothing (it once emitted a
# single patch and renumbered it 0001), even though the tree was full of work.
$files = @(git -C $ForkRepo diff HEAD --name-only)
if (-not $files) { Write-Output 'No changes to export.'; exit 0 }

# Upstream ships "* text=auto"; make sure the diff has no CRLF noise.
$ac = (git -C $ForkRepo config core.autocrlf)
if ($ac -ne 'false') {
    Write-Warning "core.autocrlf is '$ac' in $ForkRepo; set it to false for stable patches."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Record the number each existing patch already uses, keyed by file slug, BEFORE
# clearing the directory.  Reusing them keeps the series stable when a new file
# is added, instead of renumbering every patch after it.
$knownNumbers = @{}
foreach ($p in @(Get-ChildItem $OutDir -Filter '*.patch' -ErrorAction SilentlyContinue)) {
    $stem = $p.Name -replace '\.patch$', ''
    $parts = $stem -split '-', 2
    if ($parts.Count -eq 2 -and $parts[0] -match '^\d+$') {
        $slug = $parts[1]
        if (-not $knownNumbers.ContainsKey($slug)) {
            $knownNumbers[$slug] = [int]$parts[0]
        }
    }
}
Get-ChildItem $OutDir -Filter '*.patch' -ErrorAction SilentlyContinue | Remove-Item -Force

# Next free number, above anything already handed out.
$nextNew = 1
if ($knownNumbers.Count) {
    $nextNew = ([int[]]$knownNumbers.Values | Measure-Object -Maximum).Maximum + 1
}

$assigned = @{}
foreach ($f in $files) {
    $slug = ($f -replace '[\\/]', '_' -replace '^source_', '')
    $key = "$slug$Suffix"
    if ($assigned.ContainsKey($key)) {
        $num = $assigned[$key]
    } elseif ($knownNumbers.ContainsKey($key)) {
        $num = $knownNumbers[$key]
    } else {
        $num = $nextNew
        $nextNew++
    }
    $assigned[$key] = $num
    $name = '{0:0000}-{1}.patch' -f $num, $key
    $dest = Join-Path $OutDir $name
    $d = @(git -C $ForkRepo diff HEAD -- $f)
    # New files need --binary-free full content; git diff already emits a
    # /dev/null -> b/... hunk that git apply recreates.
    # git diff output already uses LF; write it without any translation.
    [System.IO.File]::WriteAllText($dest, ($d -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
    Write-Output ("{0}  <- {1}  ({2} lines)" -f $name, $f, $d.Count)
}

# A file that no longer differs leaves its old patch unstaged; report it so the
# stale entry is not mistaken for a live part of the series.
$expected = @($assigned.Keys | ForEach-Object { '{0:0000}-{1}.patch' -f $assigned[$_], $_ })
$present = @(Get-ChildItem $OutDir -Filter '*.patch' | ForEach-Object { $_.Name })
$stale = @($present | Where-Object { $expected -notcontains $_ })
if ($stale) {
    Write-Warning ("stale patch(es) for files that no longer differ: {0}" -f ($stale -join ', '))
    $stale | ForEach-Object { Remove-Item (Join-Path $OutDir $_) -Force }
}

Write-Output ''
Write-Output ("Exported {0} patch file(s) to {1}" -f $assigned.Count, $OutDir)
