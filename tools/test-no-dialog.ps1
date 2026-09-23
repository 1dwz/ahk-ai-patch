#requires -Version 5.1
<#
Assert the first customisation's negative half: under /AI the interpreter must
never raise a window.

The /AI contract has two halves and the suite used to check only one of them.
  * diagnostics reach stderr  -> tools/test-noninteractive.ps1
  * nothing else appears      -> this file
"Nothing else appears" is the half an agent actually depends on: a load error
that also prints to stderr is still fatal to an unattended run, because the
process then sits in a nested message loop until a human clicks it.  Byte-level
assertions cannot see that at all -- a MsgBox is a window, not console output, and
redirecting both streams does not suppress it.

How it can be checked without spamming the operator's screen: the interpreter is
started on a PRIVATE desktop of the current window station, so any dialog it
raises is rendered where nobody can see it, and a companion process enumerates
that desktop and reports the class, title and control text of every window the
child owns (tools/DesktopProbe.cs).

Every negative assertion here is paired with a positive one: the same erroring
script is run WITHOUT a switch and MUST produce a dialog.  Without that case a
broken watcher -- a desktop it cannot read, a probe that failed to compile --
would report "no dialog" for a product that was in fact popping them, which is
exactly how this suite would have passed while /AI was still leaking windows.

Usage:
  pwsh -NoProfile -File tools/test-no-dialog.ps1
  pwsh -NoProfile -File tools/test-no-dialog.ps1 -Exe dist\AutoHotkey64.exe
  pwsh -NoProfile -File tools/test-no-dialog.ps1 -Exe dist\AutoHotkey64.exe,dist\AutoHotkey32.exe
  pwsh -NoProfile -File tools/test-no-dialog.ps1 -Exe dist\AutoHotkey64.exe -Pristine pristine-dist\AutoHotkey64.exe
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [string[]]$Exe = @(),
    # A stock interpreter built from the same pin.  Optional, but when present it
    # turns this file from "the patch looks fine" into "the patch is doing the
    # work": the same argv is fed to a build that has no /AI, and it MUST leak a
    # dialog.
    [string]$Pristine,
    [int]$TimeoutMs = 20000
)
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

# `-File script.ps1 -Exe a,b` hands PowerShell one literal string (array splitting
# is a `-Command` feature), so normalise both shell forms here.
$Exe = @($Exe | ForEach-Object { $_ -split '[,;]' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if (-not $Exe.Count) {
    foreach ($c in @(
        (Join-Path $RepoRoot 'dist\AutoHotkey64.exe'),
        (Join-Path $RepoRoot 'upstream\bin\AutoHotkey64.exe')
    )) { if (Test-Path $c) { $Exe = @($c); break } }
}
if (-not $Exe.Count) { throw 'No interpreter found. Pass -Exe <path>.' }
foreach ($e in $Exe) { if (-not (Test-Path -LiteralPath $e)) { throw "not found: $e" } }

$probe = Build-DesktopProbe -RepoRoot $RepoRoot

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-nodialog-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$enc = New-Object System.Text.UTF8Encoding($false)

function New-Case([string]$name, [string]$body) {
    $p = Join-Path $tmp "$name.ahk"
    [System.IO.File]::WriteAllText($p, $body, $enc)
    return $p
}

# Each of these is a script the interpreter would report through a dialog in
# stock mode.  Exit codes follow the documented policy in README.md.
$run  = New-Case 'runtime' "#NoTrayIcon`nf()`nf() {`n    localVarNeverAssigned`n}`nf()"
$syn  = New-Case 'syntax'  "x := ("
$thr  = New-Case 'throw'   "#NoTrayIcon`nthrow Error(`"boom`", `"detail`")"
$warn = New-Case 'warning' "#Warn LocalSameAsGlobal`n#NoTrayIcon`nglobal gProbe := 1`nf()`nf() {`n    gProbe := 2`n}`nf()"
$ok   = New-Case 'ok'      "#NoTrayIcon`nFileAppend(`"ok`", `"*`")`nExitApp 0"
# Runs forever without ever raising a window, so a watcher has to sit in its full
# polling window before giving up -- which is what makes it killable mid-run.
$persist = New-Case 'persist' "#NoTrayIcon`nLoop`n    Sleep 200"
$miss = Join-Path $tmp 'definitely-not-here.ahk'
# A second instance of a #SingleInstance script is the one diagnostic upstream
# resolves by asking the user, so it cannot be exercised by a single process: the
# probe runs two children on one private desktop (see --then in DesktopProbe.cs).
# The PRIOR instance is deliberately given no switch -- /AI suppresses the main
# window, and CheckPriorInstance decides by FindWindow on that window, so a
# switched first instance would leave the second with nothing to prompt about and
# the case would pass for the wrong reason.
$si = New-Case 'single' "#Requires AutoHotkey v2.0`n#NoTrayIcon`n#SingleInstance Prompt`nLoop`n    Sleep 200"

$cases = [ordered]@{
    'dialog-control'  = @{ A = @($run);               Dialog = $true;  Exit = $null }
    'runtime-error'   = @{ A = @('/AI', $run);        Dialog = $false; Exit = 1 }
    'syntax-error'    = @{ A = @('/AI', $syn);        Dialog = $false; Exit = 2 }
    'uncaught-throw'  = @{ A = @('/AI', $thr);        Dialog = $false; Exit = 1 }
    'missing-script'  = @{ A = @('/AI', $miss);       Dialog = $false; Exit = 2 }
    'warning'         = @{ A = @('/AI', $warn);       Dialog = $false; Exit = 0 }
    'clean-exit'      = @{ A = @('/AI', $ok);         Dialog = $false; Exit = 0 }
    'single-instance' = @{ A = @('/AI', $si); Prior = @($si); Dialog = $false; Exit = 0;
                           Note = 'Another instance of this script is already running' }
    # The same two children with no switch on the second one: the prompt must
    # appear.  Names the dialog text, not just "some window", so it cannot be
    # satisfied by a stray window of the prior instance.
    'si-dialog'       = @{ A = @($si); Prior = @($si); Dialog = $true; Exit = $null;
                           Want = 'older instance of this script is already running' }
}

$fail = 0
function Report([string]$label, [string]$body) { Write-Output ("        !! [{0}] {1}" -f $label, $body) }

foreach ($target in $Exe) {
    $target = (Resolve-Path -LiteralPath $target).Path
    $label = Split-Path -Leaf $target
    Write-Output ''
    Write-Output "=== $label ==="

    $id = Test-AhkPatchedBuild -Path $target
    if (-not $id.Patched) {
        $fail++
        Report 'FAIL' "$label identity: static /NonInteractive marker absent -- $($id.Reason)"
        continue
    }

    foreach ($k in $cases.Keys) {
        $c = $cases[$k]
        $r = Invoke-AhkDialogWatch -Probe $probe -Exe $target -Arguments $c.A `
             -PriorArguments $c.Prior -AllowDialogRisk

        $problems = @()
        if (-not $r.Watched) {
            # The watcher produced no verdict, so it observed nothing: that is not
            # the same as having observed an empty desktop.
            $problems += "watcher produced no verdict (probe exit $($r.ExitCode)): $(($r.Detail -split "`r?`n")[0])"
        }
        else {
            if ($c.Dialog -and -not $r.Dialog) {
                $problems += "expected a DIALOG (this case is what proves the watcher can see one) -- saw none"
            }
            if (-not $c.Dialog -and $r.Dialog) {
                $problems += "a window appeared under /AI"
                foreach ($line in ($r.Detail -split "`r?`n")) { if ($line.Trim()) { $problems += "  $line" } }
            }
            if ($null -ne $c.Exit -and -not $r.Dialog) {
                if ($r.ExitCode -ne $c.Exit) { $problems += "expected exit $($c.Exit), got $($r.ExitCode)" }
            }
        }
        # Two-child cases are worthless unless the collision they describe really
        # happened: a prior instance that never won a window leaves the watched
        # child nothing to notice, and "no dialog" then means nothing.
        if ($c.Prior -and $r.Watched) {
            if (-not $r.PriorReady) { $problems += 'the prior instance never registered a window, so there was no second-instance situation to test' }
            if (-not $r.Captured)   { $problems += "the watched child's stderr was not captured, so its diagnostic cannot be read: $(($r.Detail -split "`r?`n")[0])" }
        }
        if ($c.Note -and $r.Watched) {
            if ($r.StdErr -notmatch [regex]::Escape($c.Note)) {
                $problems += "expected the diagnostic on stderr: $($c.Note)"
                foreach ($line in ($r.StdErr -split "`r?`n")) { if ($line.Trim()) { $problems += "  | $line" } }
            }
        }
        if ($c.Want -and $r.Dialog) {
            if ($r.Detail -notmatch [regex]::Escape($c.Want)) {
                $problems += "a window appeared, but not the one this case is about: $($c.Want)"
            }
        }

        $status = if ($problems.Count) { $fail++; 'FAIL' } else { 'PASS' }
        $saw = if ($r.Dialog) { 'DIALOG' } else { 'no-window' }
        Write-Output ("[{0}] {1,-16} argv={2,-22} {3,-10} exit={4}" -f $status, $k, ($c.A[0] -replace '.*\\', ''), $saw, $r.ExitCode)
        foreach ($pr in $problems) { Report $k $pr }
    }
}

if ($Pristine) {
    if (-not (Test-Path -LiteralPath $Pristine)) { throw "pristine control not found: $Pristine" }
    Write-Output ''
    Write-Output '=== control: a build WITHOUT /AI, same argv ==='

    # Deliberately a script that cannot error.  A stock interpreter does not know
    # /AI, so it reads it as the script path, fails to find a file called "AI", and
    # raises its not-found dialog: the dialog below is proof that this watcher is
    # looking at a build where the suppression is absent -- i.e. that the PASSes
    # above came from the patch and not from a watcher that cannot see windows.
    $r = Invoke-AhkDialogWatch -Probe $probe -Exe $Pristine -Arguments @('/AI', $ok) -AllowDialogRisk
    $problems = @()
    if (-not $r.Watched) { $problems += "watcher produced no verdict: $(($r.Detail -split "`r?`n")[0])" }
    elseif (-not $r.Dialog) { $problems += "stock build raised no dialog, so this watcher cannot see dialogs at all" }
    $status = if ($problems.Count) { $fail++; 'FAIL' } else { 'PASS' }
    Write-Output ("[{0}] {1,-16} argv=/AI <clean script>  {2}" -f $status, 'stock-dialog', $(if ($r.Dialog) { 'DIALOG (expected)' } else { 'no-window' }))
    foreach ($pr in $problems) { Report 'stock-dialog' $pr }
}

# --- the watcher must not leak the process it watches ---------------------------
# On the orderly path DesktopProbe terminates its own child, which needs no test.
# What actually leaked was the other path: an automated run hitting its timeout
# kills the probe outright, no cleanup code runs, and the interpreter -- parked in
# a modal dialog on a desktop nobody can see -- stays alive, holding the exe it was
# started from locked so the next build cannot overwrite it.  Only a kill-on-close
# job object covers that, and only killing the probe mid-run proves it works.
# The child is the windowless long-running script, not the erroring one: a dialog
# is reaped by the watcher the instant it is seen, which would leave nothing here
# to observe -- exactly the vacuous pass the first version of this case produced.
Write-Output ''
Write-Output '=== watcher killed mid-run: no interpreter may survive it ==='
$subject = (Resolve-Path -LiteralPath $Exe[0]).Path
$cap = Join-Path $tmp 'interrupt.capture'
$watch = Start-Process -FilePath $probe -ArgumentList "`"$cap`" `"$subject`" `"$persist`"" -PassThru -WindowStyle Hidden
Start-Sleep -Milliseconds 1500   # inside the watcher's ~8 s polling window
$tag = Split-Path -Leaf $tmp
$alive = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" -EA SilentlyContinue |
    Where-Object { $_.CommandLine -like "*$tag*" })
Stop-Process -Id $watch.Id -Force -EA SilentlyContinue
Start-Sleep -Milliseconds 1500   # give the kernel time to reap the job
$orphan = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" -EA SilentlyContinue |
    Where-Object { $_.CommandLine -like "*$tag*" })

$problems = @()
if (-not $alive.Count) {
    # Sentinel: a child that had already exited would make the assertions below
    # pass while proving nothing about reaping.
    $problems += 'the watched child had already exited, so this case observed nothing'
}
elseif ($orphan.Count) {
    $problems += "$($orphan.Count) interpreter process(es) survived the watcher: pids $(($orphan | ForEach-Object { $_.ProcessId }) -join ', ')"
    $problems += 'the watcher does not reap its child, so an interrupted run leaks a windowed AutoHotkey and locks the exe'
    foreach ($o in $orphan) { Stop-Process -Id $o.ProcessId -Force -EA SilentlyContinue }
}
$status = if ($problems.Count) { $fail++; 'FAIL' } else { 'PASS' }
Write-Output ("[{0}] {1,-16} killed the probe with the child alive (pid {2})" -f $status, 'no-orphan',
    $(if ($alive.Count) { ($alive | ForEach-Object { $_.ProcessId }) -join ', ' } else { '-' }))
foreach ($pr in $problems) { Report 'no-orphan' $pr }

Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
Remove-Item $probe -Force -EA SilentlyContinue

Write-Output ''
if ($fail) { Write-Output "$fail assertion(s) FAILED"; exit 1 }
Write-Output 'All dialog-suppression cases PASSED (and the watcher proved it can see one).'
exit 0
