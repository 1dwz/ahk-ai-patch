#requires -Version 5.1
<#
Run the patched interpreter in /AI mode with a hard timeout and reliable
stdout/stderr capture. Returns an object; never blocks on a dialog.

Why this exists: ProcessStartInfo with RedirectStandard* + WaitForExit() can
deadlock when the child fills a pipe buffer, and PowerShell's native-command
redirection (2>&1) drops native stderr. This helper reads the streams on
background tasks before waiting, which is the only reliable pattern.
#>
function Invoke-AhkAi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Exe,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutMs = 15000,
        [string]$WorkingDirectory
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Exe
    foreach ($a in $Arguments) { $psi.ArgumentList.Add($a) }
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
