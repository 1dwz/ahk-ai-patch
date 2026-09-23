#requires -Version 5.1
<#
Assemble the release zip from CI artifacts and (optionally) publish it.

The release is built from CI output, never from a local build: a local dist/
can be stale, and "the artifact came out of a green run" is the only claim
worth shipping.  This script therefore downloads the artifacts of one run,
lays them out, hashes them, and zips the result.

Layout produced -- the entire product of this repository:

  <out>/AutoHotkey64.exe   x64 interpreter, /AI + OutputDebug console mirror
  <out>/AutoHotkey32.exe   Win32 interpreter, same
  <out>/SHA256SUMS.txt     the two hashes, so a download can be verified

SHA256SUMS.txt is the only non-executable file shipped, and it is not part of
the product: it exists so a caller can prove the two bytes it downloaded are
the two bytes CI produced.  Docs, an installer and a Debug build used to be
laid out here too; they were removed on purpose, and reappearing is a
regression this script should surface rather than accommodate.

Usage:
  # assemble from a specific run (recommended: the run for the release tag)
  pwsh -NoProfile -File tools/pack-release.ps1 -RunId 35441148375

  # use the newest successful run of a tag/branch
  pwsh -NoProfile -File tools/pack-release.ps1 -Ref v2-ai-20260919-cb73253

  # assemble and publish a GitHub release
  pwsh -NoProfile -File tools/pack-release.ps1 -RunId <id> -Publish `
       -Tag v2-ai-20260923-abcdef1 -Title "AutoHotkey v2 + /AI" -NotesFile notes.md
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Repo     = '1dwz/ahk-ai-patch',

    # Which CI run to assemble from.  Supply exactly one of -RunId / -Ref.
    [string]$RunId,
    [string]$Ref,

    [string]$OutDir = 'release',
    [string]$ZipName = 'ahk-ai-patch-v2-latest.zip',

    # Publish a GitHub release for the assembled zip.
    [switch]$Publish,
    [string]$Tag,
    [string]$Title = 'AutoHotkey v2 + /AI',
    [string]$NotesFile
)

$ErrorActionPreference = 'Stop'

# CI artifact name -> the single file it must contain.  Flat: no per-arch
# subdirectories, because there is nothing beside the interpreter any more.
$layout = [ordered]@{
    'AutoHotkey64-x64-Release'   = 'AutoHotkey64.exe'
    'AutoHotkey32-Win32-Release' = 'AutoHotkey32.exe'
}

function Invoke-Gh {
    param([string[]]$GhArgs)
    $out = & gh @GhArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "gh $($GhArgs -join ' ') failed ($LASTEXITCODE):`n$($out -join "`n")" }
    return $out
}

# ---------------------------------------------------------------- pick the run

if ($RunId -and $Ref) { throw 'Pass -RunId or -Ref, not both.' }

if (-not $RunId) {
    if (-not $Ref) { throw 'Pass -RunId <id> or -Ref <tag-or-branch>.' }
    Write-Output "Looking for the newest successful run of '$Ref'..."
    $runs = (Invoke-Gh @('run','list','-R',$Repo,'--branch',$Ref,'--status','success',
                         '--limit','1','--json','databaseId,headSha,conclusion,event')) | ConvertFrom-Json
    if (-not $runs -or @($runs).Count -eq 0) { throw "no successful run found for '$Ref'" }
    $RunId = $runs[0].databaseId
    Write-Output "  run $RunId (head $($runs[0].headSha.Substring(0,7)))"
}

Write-Output "Assembling from run $RunId"

# The run must be green before its output is shipped.
$runInfo = (Invoke-Gh @('run','view',$RunId,'-R',$Repo,'--json','conclusion,headSha,displayTitle,headBranch')) | ConvertFrom-Json
if ($runInfo.conclusion -ne 'success') {
    throw "run $RunId is '$($runInfo.conclusion)', not 'success'; refusing to ship it"
}
Write-Output "  title : $($runInfo.displayTitle)"
Write-Output "  head  : $($runInfo.headSha)"

# ------------------------------------------------------------ download + lay out

$stage = Join-Path $RepoRoot $OutDir
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$tmp = Join-Path $env:TEMP ('ahk-release-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

try {
    foreach ($artifact in $layout.Keys) {
        # Stage under $tmp, never a relative path: gh resolves -D against the
        # process CWD, so a bare name drops the artifact (and its exe) into the
        # repository root.  Every path here must be absolute.
        $dest = Join-Path $tmp $artifact
        Write-Output "Downloading $artifact..."
        $null = Invoke-Gh @('run','download',$RunId,'-R',$Repo,'-n',$artifact,'-D',$dest)

        $want = $layout[$artifact]
        $found = @(Get-ChildItem $dest -Recurse -File)
        if ($found.Count -ne 1 -or $found[0].Name -ne $want) {
            # A green run whose artifact is empty, or carries something besides
            # the interpreter, is exactly what this catches.
            throw "$artifact should be exactly $want, found: $($found.Name -join ', ')"
        }
        Copy-Item $found[0].FullName (Join-Path $stage $want) -Force
        Write-Output ("  -> {0} ({1:N0} bytes)" -f $want, $found[0].Length)
    }

    # ------------------------------------------------------------- sanity + hash

    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($exe in $layout.Values) {
        if (-not (Test-Path (Join-Path $stage $exe))) { $problems.Add("$exe is missing") }
    }
    $extra = @(Get-ChildItem $stage -Recurse -File |
               Where-Object { $layout.Values -notcontains $_.Name })
    foreach ($e in $extra) { $problems.Add("unexpected file in the release: $($e.Name)") }
    if ($problems.Count) {
        $problems | ForEach-Object { Write-Output "::error::$_" }
        throw "$($problems.Count) problem(s) in the assembled release"
    }

    # Both interpreters must carry the patch marker (static scan -- never run a
    # binary to ask what it supports; a stock one answers with a modal dialog).
    Import-Module (Join-Path $RepoRoot 'tools/AhkAi.psm1') -Force
    foreach ($exe in $layout.Values) {
        $id = Test-AhkPatchedBuild -Path (Join-Path $stage $exe)
        if (-not $id.Patched) { throw "$exe is not the patched build ($($id.Reason))" }
    }
    Write-Output '  identity : both interpreters carry the patch marker'

    # SHA256SUMS covers both payload files, relative paths, forward slashes so
    # the same file verifies on any OS.
    $files = Get-ChildItem $stage -Recurse -File |
             Where-Object { $_.Name -ne 'SHA256SUMS.txt' } |
             Sort-Object FullName
    $lines = foreach ($f in $files) {
        $rel = [IO.Path]::GetRelativePath($stage, $f.FullName) -replace '\\', '/'
        '{0}  {1}' -f (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower(), $rel
    }
    [System.IO.File]::WriteAllLines((Join-Path $stage 'SHA256SUMS.txt'), $lines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "  hashes   : $($lines.Count) file(s) in SHA256SUMS.txt"

    # ------------------------------------------------------------------- zip it

    $zipPath = Join-Path $RepoRoot $ZipName
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stage, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    $zip = Get-Item $zipPath
    Write-Output ''
    Write-Output ("zip      : {0} ({1:N0} bytes)" -f $zip.Name, $zip.Length)
    Write-Output ("sha256   : {0}" -f (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower())

    # ----------------------------------------------------------------- publish

    if ($Publish) {
        if (-not $Tag) { throw '-Publish needs -Tag.' }
        $existing = & gh release view $Tag -R $Repo --json tagName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Release $Tag already exists; uploading/replacing the asset."
            $null = Invoke-Gh @('release','upload',$Tag,$zipPath,'-R',$Repo,'--clobber')
        }
        else {
            $ghArgs = @('release','create',$Tag,$zipPath,'-R',$Repo,'--title',$Title)
            if ($NotesFile) {
                if (-not (Test-Path $NotesFile)) { throw "-NotesFile not found: $NotesFile" }
                $ghArgs += @('--notes-file', $NotesFile)
            }
            else {
                $ghArgs += @('--notes', "Built from CI run $RunId (commit $($runInfo.headSha)).")
            }
            # --verify-tag: the tag must already exist, so a release can never
            # invent a tag that does not point at the commit we built from.
            $ghArgs += '--verify-tag'
            $null = Invoke-Gh $ghArgs
        }
        Write-Output "published: https://github.com/$Repo/releases/tag/$Tag"
    }
    else {
        Write-Output ''
        Write-Output 'Not published (pass -Publish -Tag <tag> to create the GitHub release).'
    }
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
