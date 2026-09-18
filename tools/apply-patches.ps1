#requires -Version 5.1
<#
Clone (or update) the upstream AutoHotkey submodule and apply the patch series.

Idempotent: safe to re-run. Use -Reset to hard-discard any local edits in
upstream/ and start from the pinned commit.

-CheckOnly verifies the series applies to a pristine copy of the pinned commit
WITHOUT touching upstream/, so it is safe to run before exporting patches.

Usage:
  pwsh -NoProfile -File tools/apply-patches.ps1
  pwsh -NoProfile -File tools/apply-patches.ps1 -Reset
  pwsh -NoProfile -File tools/apply-patches.ps1 -CheckOnly
#>
[CmdletBinding()]
param(
    [string]$RepoRoot  = (Split-Path -Parent $PSScriptRoot),
    [string]$UpstreamDir,
    [string]$PatchDir,
    [switch]$Reset,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

if (-not $UpstreamDir) { $UpstreamDir = Join-Path $RepoRoot 'upstream' }
if (-not $PatchDir)    { $PatchDir    = Join-Path $RepoRoot 'patches' }

if (-not (Test-Path $PatchDir)) { throw "patch directory not found: $PatchDir" }

$patches = Get-ChildItem $PatchDir -Filter '*.patch' | Sort-Object Name
if (-not $patches) { throw "no *.patch files in $PatchDir" }
Write-Output ("Patch series: {0} file(s)" -f $patches.Count)

# --- ensure the submodule is present --------------------------------------
if (-not (Test-Path (Join-Path $UpstreamDir '.git'))) {
    Write-Output "upstream/ not initialised; running git submodule update --init"
    Push-Location $RepoRoot
    try { git submodule update --init --recursive upstream } finally { Pop-Location }
}

if (-not (Test-Path (Join-Path $UpstreamDir '.git'))) {
    throw "upstream submodule still missing. Run: git submodule update --init --recursive"
}

$pinned = (git -C $UpstreamDir rev-parse HEAD).Trim()
$dirty  = (git -C $UpstreamDir status --porcelain)
Write-Output "upstream HEAD : $pinned"

# --- -CheckOnly: validate against a throwaway copy -------------------------
# This must not touch the working tree. The usual reason to run it is to
# validate freshly edited sources BEFORE exporting the series, and a reset here
# would silently throw that work away (it did exactly that once).
if ($CheckOnly) {
    $probeDir = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-patchcheck-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $probeDir | Out-Null
    $failed = @()
    try {
        # Export the pristine tree from the object database rather than copying
        # the working tree, so local edits cannot make a stale patch look valid.
        $tarPath = Join-Path $probeDir 'src.tar'
        git -C $UpstreamDir archive --format=tar $pinned -o $tarPath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git archive failed for $pinned" }
        tar -xf $tarPath -C $probeDir
        Remove-Item $tarPath -Force

        # The unpacked tree has no repository; create one so `git apply` finds
        # its usual context (index, autocrlf settings, ...).
        git -C $probeDir init -q 2>&1 | Out-Null
        git -C $probeDir config core.autocrlf false
        git -C $probeDir config core.eol lf
        git -C $probeDir add -A 2>&1 | Out-Null
        git -C $probeDir -c user.email=check@local -c user.name=check commit -qm base 2>&1 | Out-Null

        foreach ($p in $patches) {
            $out = git -C $probeDir apply --check $p.FullName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Output ("OK       {0}" -f $p.Name)
                git -C $probeDir apply $p.FullName 2>&1 | Out-Null
            } else {
                $failed += $p.Name
                Write-Output ("CONFLICT {0}" -f $p.Name)
                $out | ForEach-Object { Write-Output ("    {0}" -f $_) }
            }
        }
    } finally {
        Remove-Item $probeDir -Recurse -Force -EA SilentlyContinue
    }

    if ($failed.Count) {
        Write-Output ''
        Write-Error ("{0} patch(es) did not apply: {1}`nThe upstream base probably moved. Rebase the series against {2}." `
            -f $failed.Count, ($failed -join ', '), $pinned)
        exit 1
    }
    Write-Output ''
    Write-Output 'All patches apply cleanly.'
    Write-Output '(checked against a pristine copy; upstream/ was not modified)'
    exit 0
}

# --- discard drift in the working tree ------------------------------------
if ($Reset -or $dirty) {
    if ($dirty -and -not $Reset) {
        Write-Output "upstream has local modifications; resetting to pinned commit"
    }
    git -C $UpstreamDir checkout -- . 2>&1 | Out-Null
    # The export step marks new files with `git add -N` (intent-to-add), which
    # puts them in the index. A plain checkout/clean leaves them behind, and a
    # later `git apply` then fails with "already exists in working directory".
    # Unstage everything first, then remove untracked files.
    git -C $UpstreamDir reset -q 2>&1 | Out-Null
    git -C $UpstreamDir checkout -- . 2>&1 | Out-Null
    # -x as well: new sources added by the series are untracked and must go.
    git -C $UpstreamDir clean -fdx 2>&1 | Out-Null
}

# --- apply the series -----------------------------------------------------
$failed = @()
foreach ($p in $patches) {
    $probe = git -C $UpstreamDir apply --check $p.FullName 2>&1
    if ($LASTEXITCODE -eq 0) {
        git -C $UpstreamDir apply $p.FullName
        if ($LASTEXITCODE -ne 0) {
            $failed += $p.Name
            Write-Output ("FAIL     {0}" -f $p.Name)
        } else {
            Write-Output ("applied  {0}" -f $p.Name)
        }
    } else {
        $failed += $p.Name
        Write-Output ("CONFLICT {0}" -f $p.Name)
        $probe | ForEach-Object { Write-Output ("    {0}" -f $_) }
    }
}

if ($failed.Count) {
    Write-Output ''
    Write-Error ("{0} patch(es) did not apply: {1}`nThe upstream base probably moved. Rebase the series against {2}." `
        -f $failed.Count, ($failed -join ', '), $pinned)
    exit 1
}

Write-Output ''
git -C $UpstreamDir diff --stat
Write-Output 'Patch series applied.'
