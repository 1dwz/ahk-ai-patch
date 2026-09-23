#requires -Version 5.1
<#
Prove the patch set changes nothing outside the new switches.

The stated goal is "/AI only, as close to upstream as possible", so the central
claim is not "the new switch works" (other suites cover that) but "nothing else
changed".  That is an A/B claim and needs two binaries from the SAME upstream
commit: the patched one and a pristine one.

## Why the case list is limited, and why the argv is identical

STOCK AUTOHOTKEY REPORTS ERRORS WITH A MODAL DIALOG.  A naive A/B harness throws
a wall of message boxes onto the user's screen and blocks until each is
dismissed -- it looks like the patch broke something, when in fact stock is
behaving exactly as documented.

Upstream's own /ErrorStdOut does NOT make stock safe to run everywhere.  Verified
against the pinned source:

  error.cpp:257  `if (g_script.mErrorStdOut && aErrorType != WARN)`
                 -> #Warn ALWAYS raises a dialog, even with /ErrorStdOut.
  error.cpp:789  `if (g_script.mErrorStdOut && !g_script.mIsReadyToExecute)`
                 -> comment: "runtime errors are always displayed via dialog".
  script.cpp:1414 `if (!g_script.mErrorStdOut)` -- the missing-file MsgBox IS
                 suppressed, so that one is safe.

So the compared set is the intersection of invocations that are dialog-free on
BOTH sides.  Both sides then receive the *identical* command line (just
/ErrorStdOut -- upstream's spelling, which the patched build accepts too), which
is the cleanest possible formulation of "an ordinary invocation is unchanged".
Deviating only on the switch spelling would be a weaker test.

Runtime errors, uncaught throw and #Warn are deliberately outside the
comparison: stock cannot run them without a dialog, so there is nothing to
compare against.  They are reported for the patched build only, and their
console visibility is covered by test-console-visibility.ps1.

A timeout on either side is a FAILURE, never an equality: two hung processes are
not evidence of equivalent behaviour.

Usage:
  pwsh -NoProfile -File tools/test-parity.ps1 -Patched dist/AutoHotkey64.exe `
                                               -Pristine pristine-dist/AutoHotkey64.exe
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Patched,
    [Parameter(Mandatory)][string]$Pristine,
    [string]$RepoRoot = '',
    # Unpatched source tree, used to prove stock does NOT know the new switches.
    # Optional: skipped with a note when absent.
    [string]$PristineSource
)
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }

$ErrorActionPreference = 'Stop'

$Patched  = (Resolve-Path $Patched).Path
$Pristine = (Resolve-Path $Pristine).Path

$script:pass = 0
$script:fail = 0
$script:notes = 0

function Pass([string]$n) { $script:pass++; Write-Host ("  PASS  {0}" -f $n) -ForegroundColor Green }
function Fail([string]$n, [string]$d) {
    $script:fail++
    Write-Host ("  FAIL  {0}" -f $n) -ForegroundColor Red
    if ($d) { Write-Host "        $d" -ForegroundColor Red }
}
function Note([string]$n, [string]$d) { $script:notes++; Write-Host ("  ....  {0}  {1}" -f $n, $d) -ForegroundColor DarkGray }

function Run-Interpreter([string]$exe, [string[]]$arguments, [int]$timeoutMs = 15000) {
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $arguments -NoNewWindow -PassThru `
                           -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        if (-not $p.WaitForExit($timeoutMs)) {
            try { $p.Kill() } catch { }
            try { $p.WaitForExit(3000) } catch { }
            return [pscustomobject]@{ Exit = $null; TimedOut = $true; Out = ''; Err = '' }
        }
        $p.WaitForExit()   # let the async stream readers drain
        return [pscustomobject]@{
            Exit = $p.ExitCode; TimedOut = $false
            Out = [System.IO.File]::ReadAllText($outFile)
            Err = [System.IO.File]::ReadAllText($errFile)
        }
    }
    finally {
        Remove-Item $outFile, $errFile -Force -ErrorAction SilentlyContinue
    }
}

# 8.3 short paths (ADMINI~1), the temp root and the work dir differ by
# construction; trailing whitespace and EOL style are not behaviour.
function Normalize([string]$text, [string]$workDir) {
    if ([string]::IsNullOrEmpty($text)) { return '' }
    $t = $text -replace [regex]::Escape($workDir), '<WORK>'
    $t = $t -replace '(?i)C:\\Users\\[^\\]+\\AppData\\Local\\Temp', '<TEMP>'
    $t = ($t -split "`r?`n" | ForEach-Object { $_.TrimEnd() }) -join "`n"
    return $t.Trim()
}

function Show([string]$s) {
    if (-not $s) { return '<empty>' }
    return ($s -split "`n" | Select-Object -First 3) -join ' / '
}

$work = Join-Path $env:TEMP ('ahk-parity-{0}' -f ([guid]::NewGuid().ToString('N')))
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Script([string]$name, [string]$content) {
    $p = Join-Path $work $name
    [System.IO.File]::WriteAllText($p, $content, (New-Object System.Text.UTF8Encoding($false)))
    return $p
}

# Identical on both sides: /ErrorStdOut is upstream's own spelling and the
# patched build accepts it, so this is a command line a stock user could have
# typed before the patch existed.
$sharedArgs = @('/ErrorStdOut')

try {
    Write-Output "patched  : $Patched"
    Write-Output "pristine : $Pristine"
    Write-Output "argv     : $($sharedArgs -join ' ') <script>   (identical on both sides)"
    Write-Output "work     : $work"
    Write-Output ''

    $okScript     = Script 'ok.ahk'     "#Requires AutoHotkey v2.0`nFileAppend(`"OK`", `"*`")`n"
    $exit7Script  = Script 'exit7.ahk'  "#Requires AutoHotkey v2.0`nExitApp(7)`n"
    $emptyScript  = Script 'empty.ahk'  ''
    $syntaxScript = Script 'syntax.ahk' "#Requires AutoHotkey v2.0`nFileAppend(`"x`"`n"
    $multiScript  = Script 'multi.ahk'  "#Requires AutoHotkey v2.0`nFileAppend(`"a`", `"*`")`nFileAppend(`"b`", `"*`")`n"
    $argScript    = Script 'arg.ahk'    "#Requires AutoHotkey v2.0`nFileAppend(A_Args.Length, `"*`")`n"
    $missing      = Join-Path $work 'does-not-exist.ahk'

    # expect: exit code both sides must produce.  err: whether a diagnostic must
    # be present (so "silently exits non-zero" cannot pass unnoticed).
    $cases = @(
        @{ n='success (script runs)';     s=$okScript;     a=@();          exit=0; err=$false },
        @{ n='ExitApp 7';                 s=$exit7Script;  a=@();          exit=7; err=$false },
        @{ n='empty script';              s=$emptyScript;  a=@();          exit=0; err=$false },
        @{ n='script arguments';          s=$argScript;    a=@('p','q');   exit=0; err=$false },
        @{ n='multi-statement script';    s=$multiScript;  a=@();          exit=0; err=$false },
        @{ n='syntax error (load time)';  s=$syntaxScript; a=@();          exit=2; err=$true  },
        @{ n='missing script file';       s=$missing;      a=@();          exit=2; err=$true  }
    )

    foreach ($c in $cases) {
        # The script path must be the FIRST non-switch argument: upstream's own
        # ParseCmdLineArgs assigns the first non-switch arg to script_filespec and
        # treats everything after it as the script's A_Args.  Putting script
        # parameters before the path (an earlier version of this file did) makes
        # the first parameter the "script", so the case silently tests a missing
        # file instead of argument passing.
        $argv = $sharedArgs + @($c.s) + $c.a
        $pa = Run-Interpreter $Patched  $argv
        $pr = Run-Interpreter $Pristine $argv

        if ($pa.TimedOut -or $pr.TimedOut) {
            Fail $c.n "TIMED OUT (patched=$($pa.TimedOut) pristine=$($pr.TimedOut)) -- a hang is never equality"
            continue
        }
        if ($pa.Exit -ne $c.exit) {
            Fail $c.n "patched exit=$($pa.Exit), expected $($c.exit)"
            continue
        }
        if ($pr.Exit -ne $pa.Exit) {
            Fail $c.n "exit differs: patched=$($pa.Exit) pristine=$($pr.Exit)"
            continue
        }

        $pOut = Normalize $pa.Out $work
        $prOut = Normalize $pr.Out $work
        $pErr = Normalize $pa.Err $work
        $prErr = Normalize $pr.Err $work

        if ($pOut -ne $prOut) {
            Fail $c.n "stdout differs:`n          patched : $(Show $pOut)`n          pristine: $(Show $prOut)"
            continue
        }
        if ($pErr -ne $prErr) {
            Fail $c.n "stderr differs:`n          patched : $(Show $pErr)`n          pristine: $(Show $prErr)"
            continue
        }
        if ($c.err -and -not $pErr) {
            Fail $c.n "expected a diagnostic on stderr, got none"
            continue
        }
        if (-not $c.err -and ($pErr -or $pOut) -and $c.exit -ne 0) {
            # informational: non-zero exit with output is fine, just make it visible
            Note $c.n "output: out='$(Show $pOut)' err='$(Show $pErr)'"
        }

        Write-Host ("  PASS  {0}  (exit {1}, stdout='{2}')" -f $c.n, $pa.Exit, (Show $pOut)) -ForegroundColor Green
        $script:pass++
    }

    Write-Output ''
    Write-Output '### reported only -- stock needs a dialog for these, so they cannot be'
    Write-Output '    compared (patched side shown; see test-console-visibility.ps1)'
    $rtScript   = Script 'rt.ahk'   "#Requires AutoHotkey v2.0`nxx`n"
    $thrScript  = Script 'thr.ahk'  "#Requires AutoHotkey v2.0`nthrow Error(`"boom`")`n"
    $warnScript = Script 'warn.ahk' "#Requires AutoHotkey v2.0`n#Warn`nFileAppend(xx, `"*`")`n"
    foreach ($c in @(
        @{ n='runtime error';   s=$rtScript },
        @{ n='uncaught throw';  s=$thrScript },
        @{ n='#Warn diagnostic'; s=$warnScript }
    )) {
        $pa = Run-Interpreter $Patched @('/AI', $c.s)
        Note $c.n ("patched /AI: exit=$($pa.Exit)  $(Show (Normalize $pa.Err $work))")
    }

    Write-Output ''
    Write-Output '### the one divergence that is NOT behind a switch: OutputDebug()'
    # Everything else this patch set does is gated on /AI.  The OutputDebug()
    # console mirror is not -- an AI caller that forgets the switch still has to
    # see its debug output.  That makes it the one change parity cannot claim,
    # so it is audited here instead: the debug lines must be the ONLY
    # difference.  Exit code and stdout have to stay identical, or the mirror is
    # leaking into the script's own output; and the stock control must show that
    # it printed nothing, or this case would pass on a mirror that was removed.
    $odbScript = Script 'odb.ahk' "#Requires AutoHotkey v2.0`nFileAppend(`"OUT``n`", `"*`")`nOutputDebug(`"DBG``nSECOND`")`nFileAppend(`"AFTER``n`", `"*`")`n"
    $paO  = Run-Interpreter $Patched  ($sharedArgs + @($odbScript))
    $prO  = Run-Interpreter $Pristine ($sharedArgs + @($odbScript))
    if ($paO.TimedOut -or $prO.TimedOut) {
        Fail 'OutputDebug mirror' "TIMED OUT (patched=$($paO.TimedOut) pristine=$($prO.TimedOut))"
    } else {
        $pOutO = Normalize $paO.Out $work
        $prOutO = Normalize $prO.Out $work
        $pErrO = Normalize $paO.Err $work
        $prErrO = Normalize $prO.Err $work
        if ($paO.Exit -ne $prO.Exit) {
            Fail 'OutputDebug mirror' "exit differs: patched=$($paO.Exit) pristine=$($prO.Exit)"
        } elseif ($pOutO -ne $prOutO) {
            Fail 'OutputDebug mirror' "stdout differs:`n          patched : $(Show $pOutO)`n          pristine: $(Show $prOutO)"
        } elseif ($prErrO -ne '') {
            Fail 'OutputDebug mirror' "the stock control wrote stderr ('$prErrO'); this comparison no longer isolates the mirror"
        } elseif ($pErrO -ne "DBG`nSECOND") {
            Fail 'OutputDebug mirror' "patched stderr is '$(Show $pErrO)', expected exactly the two debug lines"
        } else {
            Pass "OutputDebug mirror (stdout and exit unchanged, stderr gains only '$(Show $pErrO)')"
        }
    }

    Write-Output ''
    Write-Output '### the new switches are additions'
    Write-Output '    Checked against the pristine SOURCE rather than by running stock with'
    Write-Output '    them: an unknown switch makes stock treat the switch as the script path'
    Write-Output '    and raise a "Script file not found" DIALOG, so invoking it that way puts'
    Write-Output '    a message box on the user''s screen and cannot be part of a test run.'
    $upstreamSrc = Join-Path $RepoRoot 'upstream'
    if (-not (Test-Path $upstreamSrc)) { $upstreamSrc = $RepoRoot }
    if (-not $PristineSource) { $PristineSource = Join-Path $RepoRoot 'pristine-test' }
    $patchedCpp = Join-Path $upstreamSrc 'source\AutoHotkey.cpp'
    $stockCpp   = Join-Path $PristineSource 'source\AutoHotkey.cpp'
    if (Test-Path $patchedCpp) {
        $patchedText = [System.IO.File]::ReadAllText($patchedCpp)
        $stockText = if (Test-Path $stockCpp) { [System.IO.File]::ReadAllText($stockCpp) } else { $null }
        foreach ($sw in @('/AI', '/NonInteractive')) {
            $inPatched = $patchedText -match [regex]::Escape("`"$sw`"")
            if (-not $inPatched) {
                Fail $sw 'not present in the patched parser -- the addition is missing'
                continue
            }
            if ($null -eq $stockText) {
                Note $sw 'in the patched parser; pristine source unavailable for the negative half'
                continue
            }
            $inStock = $stockText -match [regex]::Escape("`"$sw`"")
            if ($inStock) {
                Fail $sw 'already present in stock -- it is not an addition'
            }
            else {
                Pass "$sw is added (absent from stock source, present in the patched parser)"
            }
        }
    }
    else {
        Note 'source check' "skipped ($patchedCpp not found)"
    }

    Write-Output ''
    Write-Output '### the additions work on the patched build'
    # /AI is exercised by running a script whose runtime error must be reported
    # on stderr with a non-zero exit and no dialog.  A stock build would raise a
    # message box here (that is the whole point of the switch), so this half of
    # the pair is only ever run against the patched binary -- never against
    # stock.  test-noninteractive.ps1 covers the same contract in more depth.
    $aiProbe = Script 'ai-probe.ahk' "#Requires AutoHotkey v2.0`nx := NoSuchFuncAnywhere(1)`n"
    $ai = Run-Interpreter $Patched @('/AI', $aiProbe)
    if ($ai.TimedOut) { Fail 'patched /AI' 'timed out' }
    elseif ($ai.Exit -eq 0) { Fail 'patched /AI' 'a script with an unhandled error exited 0' }
    elseif (-not $ai.Err.Trim()) { Fail 'patched /AI' 'nothing written to stderr' }
    else { Pass "/AI reports the error on stderr and exits non-zero (exit $($ai.Exit))" }
}
finally {
    # Safety net: if a case ever reaches a modal dialog despite the case list
    # above, the process would sit there with a visible message box until the
    # per-run timeout.  Kill anything still referencing this run's work dir,
    # immediately, so no dialog is left on the user's screen.
    foreach ($proc in @(Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" -ErrorAction SilentlyContinue)) {
        if ($proc.CommandLine -like "*$work*") {
            Write-Host ("  !! killing blocked interpreter PID {0} (would be showing a dialog): {1}" -f
                $proc.ProcessId, $proc.CommandLine) -ForegroundColor Yellow
            try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue } catch { }
        }
    }
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output ''
Write-Output ("parity: {0} passed, {1} failed ({2} reported-only)" -f $script:pass, $script:fail, $script:notes)
if ($script:fail -gt 0) {
    Write-Output 'DIFFERENCES FOUND: the patch set is not behaviourally equivalent to stock.'
    exit 1
}
Write-Output 'OK: no behavioural difference outside the added switches and the audited OutputDebug() mirror'
exit 0
