#requires -Version 5.1
<#
Verify that the system interpreters are the patched ones, and that /AI really
works in them.

Two things this exists to catch, both of which were real:

  1. A stock interpreter installed alongside a patched one.  install-patched.ps1
     originally replaced only AutoHotkey64.exe, so any 32-bit script silently ran
     on the stock binary -- no /AI -- and nothing reported it, because the size
     difference is easy to miss and the stdout of a passing script looks
     identical.

  2. A build that carries the patch but does not actually honour /AI.  Identity
     alone cannot tell you that: the switch has to be exercised.

Identity is decided by a STATIC byte scan, not by running the binary.  Asking a
stock interpreter about a switch it does not know makes it treat the switch as
the script path, fail to find that file, and raise a MODAL DIALOG -- i.e.
executing an unknown binary in order to identify it is itself the thing that
hangs an unattended run.  See Test-AhkPatchedBuild in tools/AhkAi.psm1.

Usage:
  pwsh -NoProfile -File tools/test-system-interpreter.ps1
  pwsh -NoProfile -File tools/test-system-interpreter.ps1 -Offline   # skip the /AI probe
#>
[CmdletBinding()]
param(
    [string]$TargetDir      = 'C:\Program Files\AutoHotkey\v2',
    [switch]$Offline
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

$problems = [System.Collections.Generic.List[string]]::new()

$candidates = @('AutoHotkey64.exe', 'AutoHotkey32.exe')
foreach ($name in $candidates) {
    $path = Join-Path $TargetDir $name
    if (-not (Test-Path $path)) {
        # Absent is not a problem; a stock one present is.
        Write-Output ("{0,-20} : absent (skipped)" -f $name)
        continue
    }
    $size = (Get-Item $path).Length
    if ($size -eq 0) {
        # AutoHotkey.exe is a symlink to the 64-bit binary in some installs.
        Write-Output ("{0,-20} : {1,10:N0} B  (0-byte symlink, skipped)" -f $name, $size)
        continue
    }

    $id = Test-AhkPatchedBuild -Path (Resolve-Path $path).Path
    $line = "{0,-20} : {1,10:N0} B  patched={2}  marker-hits={3}" -f $name, $size, $id.Patched, $id.Needle

    if (-not $id.Patched) {
        $problems.Add("$name is not the patched build ($($id.Reason)). Re-run tools/install-patched.ps1.")
        Write-Output ($line + '  <-- STOCK')
        continue
    }
    Write-Output ($line + '  ok')
}

if ($problems.Count) {
    Write-Output ''
    $problems | ForEach-Object { Write-Output "::error::$_" }
    exit 1
}

# Identity alone would pass on a build that carries the patch but does not honour
# /AI, so exercise the switch: a script with an unhandled error must report it on
# stderr and exit non-zero, and must NOT block on a dialog.
if (-not $Offline) {
    $exe = Join-Path $TargetDir 'AutoHotkey64.exe'
    $probe = Join-Path $env:TEMP ('ahk-ai-probe-' + [guid]::NewGuid().ToString('N') + '.ahk')
    $src = @'
#Requires AutoHotkey v2.0
x := NoSuchFunctionAnywhere(1)
'@
    [System.IO.File]::WriteAllText($probe, $src, (New-Object System.Text.UTF8Encoding($false)))

    # Run from an empty directory so nothing beside the exe can help.
    $iso = Join-Path $env:TEMP ('ahk-ai-iso-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $iso | Out-Null
    Copy-Item $exe (Join-Path $iso 'AutoHotkey64.exe')
    Copy-Item $probe (Join-Path $iso 'probe.ahk')

    try {
        $r = Invoke-AhkAi -Exe (Join-Path $iso 'AutoHotkey64.exe') `
            -Arguments @('/AI', (Join-Path $iso 'probe.ahk')) `
            -TimeoutMs 60000 -WorkingDirectory $iso
        Write-Output ''
        Write-Output ("/AI probe (isolated dir) : exit={0} blocked={1} stderr={2} byte(s)" -f
            $r.ExitCode, $r.Blocked, $r.StdErr.Length)
        if ($r.Blocked) {
            Write-Output '::error::the system interpreter blocked on a dialog; /AI is not honoured'
            exit 1
        }
        if ($r.ExitCode -eq 0) {
            Write-Output '::error::a script with an unhandled error exited 0; /AI exit-code policy is not in effect'
            exit 1
        }
        if (-not $r.StdErr.Trim()) {
            Write-Output '::error::nothing was written to stderr; /AI diagnostics are not reaching the caller'
            exit 1
        }
        Write-Output 'OK: patched interpreters present and /AI is honoured'
    } finally {
        Remove-Item $probe -Force -EA SilentlyContinue
        Remove-Item $iso -Recurse -Force -EA SilentlyContinue
    }
}
else {
    Write-Output ''
    Write-Output 'OK: patched interpreters present (/AI probe skipped)'
}

exit 0
