#requires -Version 5.1
<#
Assert, without running anything, that every window the INTERPRETER can raise as a
diagnostic is gated behind mNonInteractive.

Why a static check: /AI's "no dialog" half is asserted at runtime by
tools/test-no-dialog.ps1, but that suite can only exercise paths a script can
reach from the outside.  The hotkey throttle, the hook-activation failure, a key
missing from the keyboard layout, Edit() failing to launch an editor and the
debugger's connect retries all need machine state this box does not have (a
layout without the key, a game holding the hook, a debugger client to refuse).
Reproducing them is out of reach; regressing them is not, so the guarantee is
pinned to the source text instead.

The rule it applies: a call to MsgBox(), MessageBox(), MessageBoxIndirect() or
DialogBoxParam() is accounted for when
  * mNonInteractive appears within the 24 lines above it (a statement-level gate), or
  * it sits in a function whose own opening does test mNonInteractive before the
    call (Script::ShowError returns early, so its dialog is unreachable under /AI), or
  * it is in this file's explicit exception list, each with a stated reason.

Anything else FAILs -- including a dialog a future upstream bump introduces, which
is the case that cannot be reviewed by hand in time.

Those names are the whole API surface, not a guess: searching upstream for
TaskDialog*, CreateDialog* and MessageBoxIndirect leaves exactly one hit the scan
does not cover, GuiType::CreateTabDialog in script_gui.cpp, which creates a
WS_CHILD dialog inside a Gui the script itself asked for -- outside /AI's boundary
(the switch suppresses what the interpreter reports, never what the script draws).

The pristine tree is run through the same rule and MUST report ungated sites:
without that, this check would pass on an unpatched interpreter too, which is how a
guard test ends up guarding nothing.

Usage:
  pwsh -NoProfile -File tools/test-dialog-guards.ps1
  pwsh -NoProfile -File tools/test-dialog-guards.ps1 -PristineSource pristine-test
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [string]$SourceDir = '',
    [string]$PristineSource = ''
)
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }

$ErrorActionPreference = 'Stop'
if (-not $SourceDir) { $SourceDir = Join-Path $RepoRoot 'upstream\source' }
foreach ($d in @($SourceDir) + $(if ($PristineSource) { @(Join-Path $PristineSource 'source') } else { @() })) {
    if (-not (Test-Path -LiteralPath $d)) { throw "source tree not found: $d" }
}

# Dialog calls this file deliberately does NOT gate, each with why.  Count is the
# number of ungated sites that excuse covers, asserted exactly: matching by file
# alone would also excuse the NEXT dialog someone adds to that file, which is the
# one case this guard exists for.  An entry whose sites disappear is reported too,
# so neither direction of drift can rot silently.
$Exceptions = @(
    @{ File = 'window.cpp'; Count = 4; Why = 'the MsgBox() helper itself; gating it would change the built-in MsgBox() function' }
    @{ File = 'window.h'; Count = 2; Why = 'declarations of that helper' }
    @{ File = 'InputBox.cpp'; Count = 1; Why = 'the built-in InputBox() prompt: a window the script asked for, not a diagnostic' }
    @{ File = 'script2.cpp'; Count = 5; Why = 'the built-in MsgBox() implementation, and diagnostics raised from LaunchAutoHotkeyUtil/HandleMenuItem (Help, Window Spy, Edit, Reload) -- they run only when a menu is clicked, and an unattended /AI run has no tray menu to click' }
)

function Get-CodePart {
    # Everything before a // that is not inside a string or char literal: a trailing
    # comment naming MsgBox() is documentation, not a call.
    param([string]$Line)
    $inStr = $false
    $inChr = $false
    for ($k = 0; $k -lt $Line.Length; $k++) {
        $c = $Line[$k]
        if ($inStr) { if ($c -eq '"' -and $Line[$k - 1] -ne '\') { $inStr = $false }; continue }
        if ($inChr) { if ($c -eq "'" -and $Line[$k - 1] -ne '\') { $inChr = $false }; continue }
        if ($c -eq '"') { $inStr = $true; continue }
        if ($c -eq "'") { $inChr = $true; continue }
        if ($c -eq '/' -and $k + 1 -lt $Line.Length -and $Line[$k + 1] -eq '/') { return $Line.Substring(0, $k) }
    }
    return $Line
}

function Get-DialogSites {
    <#
      Returns one object per dialog-capable call in the tree: line number, text, and
      whether mNonInteractive dominates it.  Comment lines, block comments and
      #ifdef _DEBUG regions are filtered out, because a call the compiler never
      sees cannot pop a window.
    #>
    [CmdletBinding()]
    param([string]$Dir)

    $re = '\b(MsgBox|MessageBox|DialogBoxParam|MessageBoxIndirect)\s*\('
    foreach ($file in (Get-ChildItem $Dir -File -Include *.cpp,*.h -Recurse)) {
        $lines = @(Get-Content -LiteralPath $file.FullName)
        $inBlock = $false
        $debugDepth = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $t = $lines[$i]
            if ($t -match '^\s*#ifn?def\s+(_DEBUG|DEBUG)\b') { $debugDepth++ }
            elseif ($t -match '^\s*#endif' -and $debugDepth) { $debugDepth-- }
            if ($inBlock) { if ($t -match '\*/') { $inBlock = $false }; continue }
            if ($t -match '/\*' -and $t -notmatch '\*/') { $inBlock = $true; continue }
            if ($t -match '^\s*//') { continue }
            $code = (Get-CodePart $t).Trim()
            if (-not $code) { continue }
            if ($code -notmatch $re) { continue }
            if ($debugDepth) { continue }

            # Statement-level gate: mNonInteractive anywhere just above.
            $gated = $false
            for ($j = [Math]::Max(0, $i - 24); $j -lt $i; $j++) {
                if ($lines[$j] -match 'mNonInteractive') { $gated = $true; break }
            }
            # Function-level gate: the enclosing function tests it before reaching here.
            if (-not $gated) {
                for ($j = $i - 1; $j -ge 0; $j--) {
                    if ($lines[$j] -match '^[A-Za-z_][\w:<>\*\s&]*::[A-Za-z_~]\w*\s*\(') {
                        for ($k = $j; $k -lt $i; $k++) {
                            if ($lines[$k] -match 'mNonInteractive') { $gated = $true; break }
                        }
                        break
                    }
                }
            }
            [pscustomobject]@{
                Name  = $file.Name
                Line  = $i + 1
                Text  = $code
                Gated = $gated
            }
        }
    }
}

function Test-Tree {
    [CmdletBinding()]
    param([string]$Label, [string]$Dir, [switch]$ExpectGated)

    # Write-Host rather than Write-Output: this function's return value is a count,
    # and anything on the success stream would be collected into it.
    Write-Host ''
    Write-Host "=== $Label  ($Dir) ==="
    $sites = @(Get-DialogSites -Dir $Dir)
    if (-not $sites.Count) { throw "${Label}: found no dialog call sites at all -- the scan is broken, not the tree" }

    $bad = @()
    $exc = 0
    $ungatedByFile = @{}
    foreach ($s in $sites) {
        $listed = @($Exceptions | Where-Object { $_.File -eq $s.Name }).Count -gt 0
        if ($ExpectGated) {
            if (-not $s.Gated) {
                if ($listed) {
                    $exc++
                    $ungatedByFile[$s.Name] = 1 + [int]$ungatedByFile[$s.Name]
                } else { $bad += $s }
            }
        }
        else {
            # Pristine control: the same scan must find work for the patch to do.
            if ($s.Gated) { $bad += $s }
        }
    }

    $ungated = @($sites | Where-Object { -not $_.Gated }).Count
    Write-Host ("      {0} dialog call site(s), {1} ungated, {2} covered by an exception entry" -f $sites.Count, $ungated, $exc)

    if ($ExpectGated) {
        # An excuse is scoped to the exact number of sites it was written for.
        foreach ($x in $Exceptions) {
            $actual = [int]$ungatedByFile[$x.File]
            if ($actual -ne [int]$x.Count) {
                Write-Host ("      !! {0}: exception entry allows {1} ungated site(s), scan finds {2}" -f `
                    $x.File, [int]$x.Count, $actual) -ForegroundColor Red
                $bad += [pscustomobject]@{ Name = $x.File; Line = 0; Text = 'exception count drift' }
            }
        }
        $seen = @($sites | ForEach-Object { $_.Name } | Select-Object -Unique)
        foreach ($x in $Exceptions) {
            if ($seen -notcontains $x.File) {
                Write-Host ("      note: the {0} exception matches no site any more -- {1}" -f $x.File, $x.Why)
            }
        }
    }

    if ($ExpectGated) {
        if ($bad.Count) {
            foreach ($s in $bad) { Write-Host ("        !! {0}:{1} ungated dialog: {2}" -f $s.Name, $s.Line, $s.Text) }
            return $bad.Count
        }
        Write-Host '      every interpreter diagnostic is gated'
        return 0
    }
    if ($ungated -eq 0) {
        Write-Host '        !! nothing was ungated here, so the patched-tree assertion above proves nothing'
        return 1
    }
    Write-Host "      control OK: $ungated site(s) have no guard without the patch"
    return 0
}

$fail = 0
$fail += Test-Tree -Label 'patched source' -Dir $SourceDir -ExpectGated

# PrintNote is what the gates redirect to; if it disappeared the gates would be
# calling nothing.
$err0 = Join-Path $SourceDir 'error.cpp'
$hdr = Join-Path $SourceDir 'script.h'
if (-not (Select-String -LiteralPath $err0 -Pattern 'void Script::PrintNote\(' -Quiet)) {
    $fail++; Write-Output '  !! error.cpp lost Script::PrintNote'
}
if (-not (Select-String -LiteralPath $hdr -Pattern 'void PrintNote\(LPCTSTR' -Quiet)) {
    $fail++; Write-Output '  !! script.h lost the PrintNote declaration'
}

if ($PristineSource) {
    $fail += Test-Tree -Label 'control: pristine source, no patch applied' -Dir (Join-Path $PristineSource 'source')
    $perr = Join-Path $PristineSource 'source\error.cpp'
    if (Select-String -LiteralPath $perr -Pattern 'void Script::PrintNote\(' -Quiet) {
        $fail++; Write-Output '  !! pristine control unexpectedly HAS PrintNote -- is -PristineSource really unpatched?'
    }
}
else {
    Write-Warning '-PristineSource was not given: nothing here proves the patched-tree assertions can fail.'
}

Write-Output ''
if ($fail) { Write-Output "$fail dialog-guard assertion(s) FAILED"; exit 1 }
Write-Output 'Dialog-guard assertions PASSED.'
exit 0
