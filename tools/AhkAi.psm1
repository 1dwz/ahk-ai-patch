#requires -Version 5.1
<#
Run the patched interpreter with a hard timeout and reliable stdout/stderr
capture.  Returns an object; never blocks on a dialog.

Why this exists: ProcessStartInfo with RedirectStandard* + WaitForExit() can
deadlock when the child fills a pipe buffer, and PowerShell's native-command
redirection (2>&1) drops native stderr.  This helper reads the streams on
background tasks before waiting, which is the only reliable pattern.

--------------------------------------------------------------------------
Command line rules for AutoHotkey.exe (from upstream source, do not guess):

  * Switches must appear BEFORE the script path.  ParseCmdLineArgs walks argv
    from index 1 and stops at the first argument that is not a switch; that
    argument becomes the script filespec and EVERYTHING AFTER IT goes to the
    script's A_Args.  So `AutoHotkey.exe script.ahk /AI` does NOT enable /AI --
    "/AI" becomes a script parameter.
    (source/AutoHotkey.cpp, ParseCmdLineArgs, the final `else` branch)

  * With NO script argument, the interpreter falls back to
    <EXEDIR>\<EXENAME>.ahk, which normally does not exist.

  * A missing/unloadable script shows a MODAL DIALOG unless one of two
    switches is set -- redirecting stdout/stderr does NOT suppress a MsgBox,
    because MsgBox is a window, not console output:
        if (!g_script.mErrorStdOut && !mNonInteractive)
            MsgBox(...);            // source/script.cpp, LoadFromFile
    /AI (alias /NonInteractive) and upstream's own /ErrorStdOut are therefore
    the ONLY safe way to run this interpreter unattended.

  * Consequently an invocation with neither switch can pop a dialog and hang
    forever.  That is what the guard below refuses, so no test can put a
    message box on the user's screen again.
--------------------------------------------------------------------------
#>
function Invoke-AhkAi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Exe,

        # Not mandatory: "no arguments at all" must stay expressible.  When this
        # was mandatory, a caller wanting that case had to pass something, and
        # passing a dummy like '/' silently substituted a different case (a
        # missing script file) while looking like it had tested "no args".
        [string[]]$Arguments = @(),

        [int]$TimeoutMs = 15000,
        [string]$WorkingDirectory,

        # Escape hatch for a deliberate negative test.  Requires the caller to
        # say out loud that it expects to risk a modal dialog.
        [switch]$AllowDialogRisk
    )

    $argv = @($Arguments | Where-Object { $_ -ne $null })

    # Safety rail derived from the source rules above: without one of these
    # switches the interpreter may raise a modal dialog that redirecting cannot
    # suppress, and the process would sit there until the timeout while the
    # window is visible to whoever is at the machine.
    $safe = $false
    foreach ($a in $argv) {
        if ($a -imatch '^/(AI|NonInteractive|ErrorStdOut)($|=)') { $safe = $true; break }
    }
    if (-not $safe -and -not $AllowDialogRisk) {
        throw ("Refusing to run '$Exe $($argv -join ' ')': argv contains none of " +
               "/AI, /NonInteractive or /ErrorStdOut, so a load error would raise a MODAL " +
               "DIALOG that redirection cannot suppress (see script.cpp LoadFromFile). " +
               "Add /AI, or pass -AllowDialogRisk if a dialog is genuinely what you want to observe.")
    }

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Exe
    # Only $null is dropped.  An empty string is a legitimate argv entry (a blank
    # script parameter is observable via A_Args), so filtering it would quietly
    # change what the interpreter is asked to do.
    #
    # ProcessStartInfo.ArgumentList is .NET Core only and Windows PowerShell 5.1
    # runs on .NET Framework, so argv is quoted into one string here.  Backslashes
    # matter only where they would escape a quote: double the run before each "
    # and the trailing run, so neither eats a quote.
    $psi.Arguments = ($argv | ForEach-Object {
        '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
    }) -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.RedirectStandardInput  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    if ($WorkingDirectory) { $psi.WorkingDirectory = $WorkingDirectory }

    $proc = [System.Diagnostics.Process]::Start($psi)

    # Start reading immediately, on background tasks, BEFORE waiting.
    $soTask = $proc.StandardOutput.ReadToEndAsync()
    $seTask = $proc.StandardError.ReadToEndAsync()
    $proc.StandardInput.Close()

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $exited = $proc.WaitForExit($TimeoutMs)
    if ($exited) {
        # Give the async reads a moment to drain after exit.
        try { $proc.WaitForExit() } catch {}
    } else {
        # Kill(bool) is .NET Core only.  Swallowing the MissingMethodException on
        # .NET Framework would leave the timed-out interpreter running, which is
        # how a watched process came to hold a build output locked; ask which
        # overload exists instead of guessing from the exception.
        try {
            if ([System.Diagnostics.Process].GetMethod('Kill', [type[]]@([bool]))) { $proc.Kill($true) }
            else { $proc.Kill() }
        } catch {}
    }
    $sw.Stop()

    $stdout = ''
    $stderr = ''
    try { $stdout = $soTask.GetAwaiter().GetResult() } catch {}
    try { $stderr = $seTask.GetAwaiter().GetResult() } catch {}

    [pscustomobject]@{
        Blocked    = -not $exited
        ExitCode   = if ($exited) { $proc.ExitCode } else { $null }
        StdOut     = $stdout
        StdErr     = $stderr
        ElapsedMs  = $sw.ElapsedMilliseconds
    }
}

<#
Static identity check: is this binary built from the patch series?

Deliberately NOT a runtime probe.  Asking a STOCK interpreter about a patched
switch makes it treat the switch as the script path, fail to find it, and raise
a modal dialog -- i.e. executing an unknown binary to identify it is itself the
thing that hangs unattended runs.

Every /AI build contains the wide-character literal "/NonInteractive", because
the parser compares argv against it at runtime
(source/AutoHotkey.cpp: `_tcsicmp(param, _T("/NonInteractive"))`).  Stock
AutoHotkey has no such literal anywhere.  A 30-byte UTF-16LE needle does not
occur by accident, so a byte scan is a sound, side-effect-free identity test.
#>
function Test-AhkPatchedBuild {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Patched = $false; Needle = 0; Reason = 'file not found' }
    }

    $needle = [System.Text.Encoding]::Unicode.GetBytes('/NonInteractive')
    $bytes  = [System.IO.File]::ReadAllBytes($Path)
    $hits = 0
    for ($i = 0; $i -le $bytes.Length - $needle.Length; $i++) {
        if ($bytes[$i] -ne $needle[0]) { continue }
        $m = $true
        for ($j = 1; $j -lt $needle.Length; $j++) {
            if ($bytes[$i + $j] -ne $needle[$j]) { $m = $false; break }
        }
        if ($m) { $hits++ }
    }

    [pscustomobject]@{
        Patched = ($hits -gt 0)
        Needle  = $hits
        Reason  = if ($hits -gt 0) { "found the /NonInteractive literal ($hits occurrence(s))" }
                  else { 'no /NonInteractive literal -- this is not the patched build' }
    }
}

<#
Compile tools/ConsoleProbe.cs, which is how a test observes output that has no
pipe in front of it.  Returns the path to the probe.
#>
function New-ConsoleProbe {
    [CmdletBinding()]
    param(
        [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
        [string]$OutFile = (Join-Path ([System.IO.Path]::GetTempPath()) 'ahk-console-probe.exe')
    )

    $src = Join-Path $RepoRoot 'tools\ConsoleProbe.cs'
    if (-not (Test-Path -LiteralPath $src)) { throw "missing $src" }

    $csc = @(
        'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
        'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $csc) { throw 'csc.exe not found; cannot build the console probe' }

    # Always recompiled: the probe is small, and a cached copy would silently
    # test against whatever ConsoleProbe.cs looked like the last time it ran.
    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
    & $csc /nologo "/out:$OutFile" $src | Out-Null
    if (-not (Test-Path -LiteralPath $OutFile)) { throw 'failed to compile the console probe' }
    $OutFile
}

<#
Run the interpreter with NO redirection of any kind, on a console this function
owns, and return what ended up on that console.

Invoke-AhkAi cannot answer this question: it always puts a pipe on stderr, and a
GUI-subsystem binary with a pipe looks healthy while printing nothing to the
terminal a human is watching.  The probe therefore allocates its own console,
starts the interpreter as a child with inherited (i.e. real, unredirected)
handles, and reads the screen buffer back afterwards.

Arguments pass through untouched, so the same path can observe behaviour with and
without /AI.
#>
function Invoke-AhkInConsole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Exe,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Probe,
        # Same rail as Invoke-AhkAi: with no switch in argv an error raises a
        # modal dialog, and on a bare console nothing suppresses it.
        [switch]$AllowDialogRisk
    )

    $argv = @($Arguments | Where-Object { $_ -ne $null })
    $safe = $false
    foreach ($a in $argv) {
        if ($a -imatch '^/(AI|NonInteractive|ErrorStdOut)($|=)') { $safe = $true; break }
    }
    if (-not $safe -and -not $AllowDialogRisk) {
        throw ("Refusing to run '$Exe $($argv -join ' ')': argv contains none of " +
               "/AI, /NonInteractive or /ErrorStdOut, so a load error would raise a MODAL " +
               "DIALOG on the console. Pass -AllowDialogRisk for a script that cannot error.")
    }

    if (-not (Test-Path -LiteralPath $Probe)) { throw "console probe not found: $Probe" }
    $capture = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-console-capture-{0}.txt' -f [guid]::NewGuid().ToString('N'))
    try {
        # Never pipe the probe itself: a redirected stdout is exactly the
        # condition being tested around.
        & $Probe $Exe $capture @argv
        $code = $LASTEXITCODE
        $text = if (Test-Path -LiteralPath $capture) { [System.IO.File]::ReadAllText($capture) } else { '' }
        [pscustomobject]@{
            # 259 is what the probe reports for "child still running at the
            # timeout", i.e. blocked on a dialog.
            Blocked  = ($code -eq 259)
            ExitCode = $code
            Console  = $text
        }
    }
    finally {
        Remove-Item $capture -Force -ErrorAction SilentlyContinue
    }
}

<#
Compile tools/DesktopProbe.cs, which is how a test sees a modal dialog without
one ever reaching the user's screen.  Returns the path to the probe.
#>
function New-DesktopProbe {
    [CmdletBinding()]
    param(
        [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
        [string]$OutFile = (Join-Path ([System.IO.Path]::GetTempPath()) 'ahk-desktop-probe.exe')
    )

    $src = Join-Path $RepoRoot 'tools\DesktopProbe.cs'
    if (-not (Test-Path -LiteralPath $src)) { throw "missing $src" }

    $csc = @(
        'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
        'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $csc) { throw 'csc.exe not found; cannot build the desktop probe' }

    # Always recompiled, for the same reason as New-ConsoleProbe.
    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
    & $csc /nologo "/out:$OutFile" $src | Out-Null
    if (-not (Test-Path -LiteralPath $OutFile)) { throw 'failed to compile the desktop probe' }
    $OutFile
}

<#
Run the interpreter on a private desktop and report whether it raised a dialog.

Invoke-AhkAi can only infer a dialog from "the child never came back within the
timeout", which costs the whole timeout and names nothing.  This returns the
window class, title and control text instead, so a failure says which dialog
escaped -- and it can assert the POSITIVE case (a dialog must appear) cheaply,
which is what makes the negative assertions trustworthy.

Because the child is isolated on its own desktop, a dialog here is invisible to
whoever is sitting at the machine; -AllowDialogRisk is therefore honest for
scripts that error without a switch.
#>
function Invoke-AhkDialogWatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Exe,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Probe,
        # A first instance to launch before the watched one, on the same private
        # desktop -- what #SingleInstance needs before it has anything to prompt
        # about.  The watcher below is the child whose windows count.
        [string[]]$PriorArguments = @(),
        [string]$PriorExe,
        [switch]$AllowDialogRisk
    )

    $argv = @($Arguments | Where-Object { $_ -ne $null })
    $prior = @($PriorArguments | Where-Object { $_ -ne $null })
    if ($prior.Count -and -not $PriorExe) { $PriorExe = $Exe }
    $safe = $false
    foreach ($a in $argv) {
        if ($a -imatch '^/(AI|NonInteractive|ErrorStdOut)($|=)') { $safe = $true; break }
    }
    if (-not $safe -and -not $AllowDialogRisk) {
        throw ("Refusing to run '$Exe $($argv -join ' ')': argv contains none of " +
               "/AI, /NonInteractive or /ErrorStdOut, so an error raises a modal dialog. " +
               "Pass -AllowDialogRisk when that dialog is the point of the case.")
    }

    if (-not (Test-Path -LiteralPath $Probe)) { throw "desktop probe not found: $Probe" }
    $capture = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-dialog-capture-{0}.txt' -f [guid]::NewGuid().ToString('N'))
    try {
        if ($prior.Count) {
            & $Probe $capture $PriorExe @prior '--then' $Exe @argv
        } else {
            & $Probe $capture $Exe @argv
        }
        $code = $LASTEXITCODE
        $text = if (Test-Path -LiteralPath $capture) { [System.IO.File]::ReadAllText($capture) } else { '' }
        # The probe closes its capture handle before it exits, so this file is
        # complete by now; it only exists in the two-child mode.
        $stderrPath = "$capture.stderr"
        $childStdErr = if (Test-Path -LiteralPath $stderrPath) {
            [System.IO.File]::ReadAllText($stderrPath, [System.Text.Encoding]::UTF8)
        } else { '' }

        # The capture's own words are the verdict.  The probe's exit code cannot be
        # the authority, because the child's exit code travels through it and a
        # script is free to `ExitApp 3`.
        $dialog = ($text -match '(?m)^DIALOGS:')
        $seenMarker = ($dialog -or $text -match '(?m)^NO DIALOG SEEN$')
        $childExit = $code
        if ($text -match ' exit=(\d+)') { $childExit = [int]$Matches[1] }

        [pscustomobject]@{
            Dialog     = $dialog
            # No marker at all means the watcher never got as far as looking, so a
            # caller must not read that as "no dialog".
            Watched    = $seenMarker
            ExitCode   = $childExit
            Detail     = $text
            # Two-child mode: did the prior instance actually register a window, and
            # did the watched child's stderr reach the file.  Both false would make a
            # case pass without the situation it claims to set up ever occurring.
            PriorReady = ($text -match 'prior_ready=True')
            Captured   = ($text -match 'captured=True')
            StdErr     = $childStdErr
        }
    }
    finally {
        Remove-Item $capture -Force -ErrorAction SilentlyContinue
        Remove-Item "$capture.stderr" -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Invoke-AhkAi, Test-AhkPatchedBuild, New-ConsoleProbe, Invoke-AhkInConsole, `
    New-DesktopProbe, Invoke-AhkDialogWatch
