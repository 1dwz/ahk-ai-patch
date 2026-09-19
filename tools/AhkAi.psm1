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
    foreach ($a in $argv) { $psi.ArgumentList.Add($a) }
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
        try { $proc.Kill($true) } catch {}
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

Export-ModuleMember -Function Invoke-AhkAi, Test-AhkPatchedBuild
