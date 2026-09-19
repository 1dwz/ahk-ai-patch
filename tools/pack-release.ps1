#requires -Version 5.1
<#
Assemble the release zip from CI artifacts and (optionally) publish it.

The release is built from CI output, never from a local build: a local dist/
can be stale, and "the artifact came out of a green run" is the only claim
worth shipping.  This script therefore downloads the artifacts of one run,
lays them out, hashes them, and zips the result.

Layout produced (matches every previous release):

  <out>/x64-Release/       AutoHotkey64.exe + the generated/hand-written docs
  <out>/Win32-Release/     AutoHotkey32.exe + the same docs
  <out>/x64-Debug/         AutoHotkey64.exe (Debug) + the same docs
  <out>/AHK-v2-Setup.exe   the self-extracting installer
  <out>/README.md          the repo README at the released commit
  <out>/README-AI.md       the agent-facing guide
  <out>/SHA256SUMS.txt     every payload file, so a download can be verified

The experimental AutoHotkeySC-x64 artifact is intentionally NOT shipped: it
does not compile at the pinned upstream commit (a pre-existing upstream
breakage, see the matrix comment in build.yml), and shipping a target that is
known to fail would misrepresent the release.

Usage:
  # assemble from a specific run (recommended: the run for the release tag)
  pwsh -NoProfile -File tools/pack-release.ps1 -RunId 35441148375

  # use the newest successful run of a tag/branch
  pwsh -NoProfile -File tools/pack-release.ps1 -Ref v2-ai-20260919-cb73253

  # assemble and publish a GitHub release
  pwsh -NoProfile -File tools/pack-release.ps1 -RunId <id> -Publish `
       -Tag v2-ai-20260919-cb73253 -Title "AutoHotkey v2 + /AI" -NotesFile notes.md
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

# Artifact name -> directory it is laid out under.  The Self-contained target is
# deliberately absent; see the header.
$layout = [ordered]@{
    'AutoHotkey64-x64-Release'   = 'x64-Release'
    'AutoHotkey32-Win32-Release' = 'Win32-Release'
    'AutoHotkey64-x64-Debug'     = 'x64-Debug'
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

        # gh puts the artifact's files under $dest; flatten into the layout dir.
        $target = Join-Path $stage $layout[$artifact]
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Get-ChildItem $dest -Recurse -File | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $target $_.Name) -Force
        }
        $n = (Get-ChildItem $target -File).Count
        Write-Output "  -> $($layout[$artifact])/ ($n file(s))"
    }

    # The installer artifact.
    Write-Output 'Downloading AHK-v2-Setup...'
    $null = Invoke-Gh @('run','download',$RunId,'-R',$Repo,'-n','AHK-v2-Setup','-D',(Join-Path $tmp 'setup'))
    $setup = Get-ChildItem (Join-Path $tmp 'setup') -Recurse -File -Filter '*.exe' | Select-Object -First 1
    if (-not $setup) { throw 'the AHK-v2-Setup artifact contained no .exe' }
    Copy-Item $setup.FullName (Join-Path $stage 'AHK-v2-Setup.exe') -Force

    # Top-level guides, taken from the released commit (not from the working
    # tree, which may have moved on since the tag).  The `?ref=` must stay
    # attached to the path, so build the whole URL as one string.
    foreach ($doc in 'README.md', 'docs/README-AI.md') {
        $name = Split-Path $doc -Leaf
        $url = "repos/$Repo/contents/$($doc)?ref=$($runInfo.headSha)"
        $text = (Invoke-Gh @('api', $url, '-H', 'Accept: application/vnd.github.raw')) -join "`n"
        [System.IO.File]::WriteAllText((Join-Path $stage $name), ($text -replace "`r`n","`n"), (New-Object System.Text.UTF8Encoding($false)))
        Write-Output "  -> $name (from $($runInfo.headSha.Substring(0,7)))"
    }

    # ------------------------------------------------------------- sanity + hash

    # Every layout dir must carry both an exe and the generated API reference;
    # a silently-empty artifact directory is the failure this catches.
    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($dir in $layout.Values) {
        foreach ($need in 'BUILTIN_API.md', 'builtin-api.json') {
            if (-not (Test-Path (Join-Path $stage "$dir/$need"))) { $problems.Add("$dir/$need is missing") }
        }
    }
    foreach ($exe in 'x64-Release/AutoHotkey64.exe', 'Win32-Release/AutoHotkey32.exe', 'x64-Debug/AutoHotkey64.exe', 'AHK-v2-Setup.exe') {
        if (-not (Test-Path (Join-Path $stage $exe))) { $problems.Add("$exe is missing") }
    }
    if ($problems.Count) {
        $problems | ForEach-Object { Write-Output "::error::$_" }
        throw "$($problems.Count) problem(s) in the assembled release"
    }

    # The reference must be source-derived, i.e. it must NOT carry parameter
    # placeholders and must say how many entries lack declared names.  This is
    # the same contract CI asserts, re-checked on the shipped bytes.
    $apiJson = Get-Content (Join-Path $stage 'x64-Release/builtin-api.json') -Raw | ConvertFrom-Json
    if ($apiJson.count -ne 354) { throw "x64-Release/builtin-api.json reports $($apiJson.count) functions, expected 354" }
    if (@($apiJson.functions | ForEach-Object { $_.params } | Where-Object { $_.name -match '^arg\d+$' }).Count -gt 0) {
        throw 'the shipped API reference contains invented argN placeholders'
    }
    Write-Output "  api      : $($apiJson.count) functions ($($apiJson.parameter_names_declared) named, $($apiJson.parameter_names_absent) arity-only)"

    # Every shipped exe must carry the patch marker (static scan -- never run a
    # binary to ask what it supports; a stock one answers with a modal dialog).
    Import-Module (Join-Path $RepoRoot 'tools/AhkAi.psm1') -Force
    foreach ($exe in 'x64-Release/AutoHotkey64.exe', 'Win32-Release/AutoHotkey32.exe', 'x64-Debug/AutoHotkey64.exe') {
        $id = Test-AhkPatchedBuild -Path (Join-Path $stage $exe)
        if (-not $id.Patched) { throw "$exe is not the patched build ($($id.Reason))" }
    }
    Write-Output '  identity : all three interpreters carry the patch marker'

    # SHA256SUMS covers every payload file, relative paths, forward slashes so
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
