#requires -Version 5.1
<#
Verify that docs/BUILTIN_HTTP_JSON.md tells the truth about this build.

The guide is a deliverable that ships beside the executable, and it makes many
concrete claims (type mapping, error model, arity, escaping).  A doc that drifts
from the binary is worse than no doc, and nothing else checks it: the generated
API index only covers signatures, and only for the 354 upstream functions.

Each assertion here was written by reading a claim in the guide and encoding it.
If a claim changes, this fails and names it.

Usage:
  pwsh -NoProfile -File tools/test-doc-claims.ps1 -Exe dist\AutoHotkey64.exe
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Exe,
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$Exe = (Resolve-Path $Exe).Path

# The probe is kept as a file so the guide and the assertions stay reviewable
# side by side, and so AutoHotkey reports line numbers on failure.
$probe = Join-Path $RepoRoot 'tools\doc-claims.ahk'
if (-not (Test-Path $probe)) { throw "missing $probe" }

Import-Module (Join-Path $RepoRoot 'tools\AhkAi.psm1') -Force
$r = Invoke-AhkAi -Exe $Exe -Arguments @('/AI', $probe) -TimeoutMs 60000 -WorkingDirectory $RepoRoot

$out = $r.StdOut
$fail = @($out -split "`r?`n" | Where-Object { $_ -match '^\s*FAIL' })
$pass = @($out -split "`r?`n" | Where-Object { $_ -match '^\s*OK' })

Write-Output "interpreter : $Exe"
Write-Output "guide       : docs/BUILTIN_HTTP_JSON.md"
Write-Output "claims      : $($pass.Count) ok, $($fail.Count) failed"

if ($r.StdErr.Trim()) {
    # A load-time or runtime error means the probe did not finish, so the claim
    # results cannot be trusted even if some OK lines were printed.
    Write-Output '::error::the probe did not run to completion:'
    $r.StdErr.Trim() -split "`r?`n" | ForEach-Object { Write-Output "  $_" }
    exit 1
}
if ($r.ExitCode -ne 0) {
    Write-Output "::error::probe exited $($r.ExitCode)"
    exit 1
}
if ($fail.Count) {
    Write-Output '::error::documented behaviour does not match this build:'
    $fail | ForEach-Object { Write-Output "  $($_ -replace '^\s+', '')" }
    exit 1
}
if ($pass.Count -lt 25) {
    Write-Output "::error::only $($pass.Count) claims checked; expected at least 25, so the probe was truncated"
    exit 1
}

Write-Output 'OK: every documented claim matches the built interpreter'
exit 0
