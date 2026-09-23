#requires -Version 5.1
<#
Verify the second customisation: OutputDebug() reaches the debugger AND the
command line.

Stock AutoHotkey hands the text to the script debugger if a client is attached,
and only falls back to OutputDebugString() otherwise -- so a caller that has
neither (an agent running the script from a terminal) sees nothing at all.  The
patch mirrors every OutputDebug() call onto stderr as well, which is where /AI
puts its diagnostics, so stdout keeps carrying only what the script itself
prints.

What each case guards:
  mirror-to-stderr   the text arrives, exit code untouched
  streams-stay-split debug text does not pollute script output
  multiline          embedded newlines survive and the last line is terminated
  without-ai         the mirror belongs to the function, not to the switch
  empty-text         OutputDebug("") is a no-op, not a crash
  non-ascii          redirected/piped output is UTF-8 (a GBK console cannot show
                     this: the .NET stream readers in Invoke-AhkAi decode with
                     the console codepage, so this case writes to a file)
  console-*          the text lands on a REAL console with no pipe in front of
                     it, with and without /AI -- every case above redirects
                     stderr, which is precisely what hides an AttachConsole bug
  debugger-intact    source-level: the debugger call is still there, so the
                     mirror added a destination instead of replacing one

The `without-ai` case is also the honest-control case: run against a pristine
binary (-Pristine) the marker MUST be absent.  Without that control this whole
script could report green while testing nothing, because a stock AutoHotkey also
produces no stderr output for OutputDebug().

Usage:
  pwsh -NoProfile -File tools/test-outputdebug.ps1
  pwsh -NoProfile -File tools/test-outputdebug.ps1 -Exe dist\AutoHotkey64.exe
  pwsh -NoProfile -File tools/test-outputdebug.ps1 -Pristine pristine-dist\AutoHotkey64.exe
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string[]]$Exe,
    [string]$Pristine,
    [int]$TimeoutMs = 15000
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

# `-File script.ps1 -Exe a,b` hands PowerShell one literal string (array splitting
# is a `-Command` feature), so normalise both shell forms here.
$Exe = @($Exe | ForEach-Object { $_ -split '[,;]' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

if (-not $Exe) {
    $Exe = @(foreach ($c in 'AutoHotkey64.exe', 'AutoHotkey32.exe') {
        $p = Join-Path $RepoRoot "dist\$c"
        if (Test-Path $p) { $p }
    })
}
$Exe = @($Exe | ForEach-Object { (Resolve-Path $_).Path })
if (-not $Exe.Count) { throw "no interpreter found in $(Join-Path $RepoRoot 'dist'); pass -Exe <path>." }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-odb-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$enc = New-Object System.Text.UTF8Encoding($false)

# Compiled once and shared by every console case below.
$probe = Build-ConsoleProbe -RepoRoot $RepoRoot

function New-Script([string]$name, [string]$body) {
    $p = Join-Path $tmp "$name.ahk"
    [System.IO.File]::WriteAllText($p, $body, $enc)
    return $p
}

# Write-Output of the marker is deliberately unlike anything a stock run emits,
# so an accidental match cannot make a case pass.
$MARK   = 'AHKAI-OUTPUTDEBUG-MARKER'
$MARK2  = 'AHKAI-ODB-MULTI-B'
$MARKU8 = 'AHKAI-ODB-中文调试'

$sSimple   = New-Script 'simple'   "#NoTrayIcon`nOutputDebug(`"$MARK`")`nFileAppend `"STDOUT-OK``n`", `"*`"`nExitApp 0"
$sMulti    = New-Script 'multi'    "#NoTrayIcon`nOutputDebug(`"AHKAI-ODB-MULTI-A``n$MARK2`")`nExitApp 0"
$sEmpty    = New-Script 'empty'    "#NoTrayIcon`nOutputDebug(`"`")`nFileAppend `"AFTER-EMPTY``n`", `"*`"`nExitApp 0"
$sNonAscii = New-Script 'nonascii' "#NoTrayIcon`nOutputDebug(`"$MARKU8`")`nExitApp 0"

# For the console cases: exits 0 on its own, so it is safe to run without any
# switch -- nothing can raise the dialog that the no-switch path tolerates.
$sConsole  = New-Script 'console'  "#NoTrayIcon`nOutputDebug(`"$MARK`")`nExitApp 0"

$fail = 0
function Report([string]$status, [string]$name, [string[]]$problems, [string]$detail) {
    if ($status -eq 'FAIL') { $script:fail++ }
    Write-Output ("[{0}] {1}  {2}" -f $status, $name, $detail)
    foreach ($p in $problems) { Write-Output ("        !! {0}" -f $p) }
}

# --- cases that go through Invoke-AhkAi (stderr arrives as a .NET-decoded string)
foreach ($target in $Exe) {
    $label = Split-Path -Leaf $target
    Write-Output ''
    Write-Output "== $target"
    $id = Test-AhkPatchedBuild -Path $target
    if (-not $id.Patched) {
        Report 'FAIL' "$label identity" @("static /NonInteractive marker absent: $($id.Reason)") ''
        continue
    }

    $suites = @(
        @{ Name = "$label /AI mirror";      Exe = $target; Args = @('/AI', $sSimple);   Mark = $MARK },
        @{ Name = "$label /ErrorStdOut";    Exe = $target; Args = @('/ErrorStdOut', $sSimple); Mark = $MARK }
    )
    foreach ($s in $suites) {
        $r = Invoke-AhkAi -Exe $s.Exe -Arguments $s.Args -TimeoutMs $TimeoutMs -WorkingDirectory $tmp
        $problems = @()
        if ($r.Blocked) {
            $problems += "BLOCKED after ${TimeoutMs}ms (a dialog appeared?)"
        } else {
            if ($r.ExitCode -ne 0) { $problems += "exit code $($r.ExitCode), expected 0 (OutputDebug must not change it)" }
            if ($r.StdErr -notmatch [regex]::Escape($s.Mark)) { $problems += "stderr has no '$($s.Mark)'" }
            if ($r.StdOut -notmatch 'STDOUT-OK')             { $problems += "stdout lost 'STDOUT-OK'" }
            if ($r.StdOut -match [regex]::Escape($s.Mark))   { $problems += "debug text leaked into stdout" }
        }
        $first = (($r.StdErr.Trim() -split "`r?`n") | Select-Object -First 1)
        Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) $s.Name $problems "stderr='$first'"
    }

    # multiline: both lines on stderr, and the block ends in a newline so the
    # next thing the process writes cannot be glued onto it.
    $r = Invoke-AhkAi -Exe $target -Arguments @('/AI', $sMulti) -TimeoutMs $TimeoutMs -WorkingDirectory $tmp
    $problems = @()
    if ($r.Blocked) { $problems += 'BLOCKED' }
    else {
        if ($r.StdErr -notmatch 'AHKAI-ODB-MULTI-A') { $problems += 'first line missing' }
        if ($r.StdErr -notmatch [regex]::Escape($MARK2)) { $problems += 'second line missing' }
        if ($r.StdErr -notmatch [regex]::Escape("$MARK2`n")) { $problems += 'no newline after the last line' }
    }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) "$label multiline" $problems "stderr=$($r.StdErr.Length)B"

    # empty text must be a no-op, not a crash and not a swallowed script
    $r = Invoke-AhkAi -Exe $target -Arguments @('/AI', $sEmpty) -TimeoutMs $TimeoutMs -WorkingDirectory $tmp
    $problems = @()
    if ($r.Blocked) { $problems += 'BLOCKED' }
    else {
        if ($r.ExitCode -ne 0) { $problems += "exit code $($r.ExitCode), expected 0" }
        if ($r.StdOut -notmatch 'AFTER-EMPTY') { $problems += 'the script stopped after OutputDebug("")' }
    }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) "$label empty-text no-op" $problems "exit=$($r.ExitCode)"

    # non-ASCII: read the raw bytes instead of a console-codepage string, so a
    # GBK machine cannot make correct UTF-8 look broken (or the reverse).
    $errFile = Join-Path $tmp "$label-nonascii.err"
    $p = Start-Process -FilePath $target -ArgumentList @('/AI', $sNonAscii) -WorkingDirectory $tmp `
         -NoNewWindow -Wait -PassThru -RedirectStandardError $errFile
    $problems = @()
    if ($p.ExitCode -ne 0) { $problems += "exit code $($p.ExitCode), expected 0" }
    $bytes = if (Test-Path $errFile) { [System.IO.File]::ReadAllBytes($errFile) } else { @() }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text -notmatch [regex]::Escape($MARKU8)) { $problems += "UTF-8 stderr lacks '$MARKU8' (got: $($text.Trim()))" }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) "$label non-ascii UTF-8" $problems "$($bytes.Length) bytes"

    # --- no redirection at all: a console the probe owns, read back afterwards.
    # Everything above pipes stderr, which is exactly the condition that hides a
    # missing AttachConsole, so a green run there proves nothing about what a
    # human sees in a terminal.
    $c = Invoke-AhkInConsole -Probe $probe -Exe $target -Arguments @('/AI', $sConsole)
    $problems = @()
    if ($c.Blocked) { $problems += 'BLOCKED on the console (a dialog appeared?)' }
    if ($c.ExitCode -ne 0) { $problems += "exit code $($c.ExitCode), expected 0" }
    if ($c.Console -notmatch [regex]::Escape($MARK)) { $problems += "console shows no '$MARK'" }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) "$label bare console /AI" $problems "$($c.Console.Trim().Length) char(s)"

    # ... and without /AI, which is the path the mirror's own console attach
    # exists for: with no switch the interpreter never attaches to the parent
    # console, so this fails if that attach is removed from the mirror.
    $c = Invoke-AhkInConsole -Probe $probe -Exe $target -Arguments @($sConsole) -AllowDialogRisk
    $problems = @()
    if ($c.Blocked) { $problems += 'BLOCKED on the console (the script errors without a switch?)' }
    if ($c.ExitCode -ne 0) { $problems += "exit code $($c.ExitCode), expected 0" }
    if ($c.Console -notmatch [regex]::Escape($MARK)) { $problems += "console shows no '$MARK' without /AI" }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) "$label bare console, no switch" $problems "$($c.Console.Trim().Length) char(s)"
}

# --- the debugger half of "debugger + command line" must still be there
$src = Join-Path $RepoRoot 'upstream\source\script2.cpp'
$problems = @()
if (Test-Path $src) {
    $raw = Get-Content $src -Raw
    $m = [regex]::Match($raw, 'bif_impl void OutputDebug\(StrArg aText\)\s*\{(?<body>.*?)\r?\n\}', 'Singleline')
    if (-not $m.Success) {
        $problems += 'could not find the OutputDebug() definition to inspect'
    } else {
        $b = $m.Groups['body'].Value
        if ($b -notmatch 'g_Debugger\.OutputStdErr\(aText\)') { $problems += 'debugger call is gone: the mirror replaced a destination' }
        if ($b -notmatch 'OutputDebugString\(aText\)')       { $problems += 'OutputDebugString() fallback is gone (DebugView/VS)' }
        if ($b -notmatch 'OutputDebugMirrorToConsole\(aText\)') { $problems += 'console mirror is not wired up' }
    }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) 'source: debugger + console' $problems $src
} else {
    Report 'FAIL' 'source: debugger + console' @("not found: $src (run tools/apply-patches.ps1)") ''
}

# --- negative control: a stock interpreter must NOT produce this output
if ($Pristine -and (Test-Path $Pristine)) {
    $pri = (Resolve-Path $Pristine).Path

    $r = Invoke-AhkAi -Exe $pri -Arguments @('/ErrorStdOut', $sSimple) -TimeoutMs $TimeoutMs -WorkingDirectory $tmp
    $problems = @()
    if ($r.Blocked) { $problems += 'BLOCKED (a dialog appeared; the control is invalid)' }
    elseif ($r.StdErr -match [regex]::Escape($MARK)) { $problems += 'pristine build emitted the marker: the test proves nothing' }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) 'control: pristine stays silent' $problems "stderr=$($r.StdErr.Length)B"

    # /ErrorStdOut, not /AI: stock reads an unknown switch as the script path and
    # answers a missing file with a modal dialog.  This is the control that makes
    # the two bare-console cases above more than a reading of the console buffer.
    $c = Invoke-AhkInConsole -Probe $probe -Exe $pri -Arguments @('/ErrorStdOut', $sConsole)
    $problems = @()
    if ($c.Blocked) { $problems += 'BLOCKED on the console (the control is invalid)' }
    elseif ($c.Console -match [regex]::Escape($MARK)) { $problems += 'pristine build printed on the console: the console cases prove nothing' }
    Report $(if ($problems.Count) { 'FAIL' } else { 'PASS' }) 'control: pristine silent on a console' $problems "$($c.Console.Trim().Length) char(s)"
} else {
    Write-Output ''
    Write-Warning ("no -Pristine control passed: the marker-absence assertion was not run. " +
                   "Build one with tools/build.ps1 -UpstreamDir pristine-test, or this suite " +
                   "cannot tell a working mirror from an interpreter that printed nothing.")
}

Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
Remove-Item $probe -Force -EA SilentlyContinue

Write-Output ''
if ($fail) { Write-Output "$fail case(s) FAILED"; exit 1 }
Write-Output 'All OutputDebug cases PASSED.'
exit 0
