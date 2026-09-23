# Running and debugging AHK scripts here

The short version: **run every script with `/AI`**, capture stderr and the exit
code, and never let a script run without a timeout.

## Why `/AI` matters

Stock AutoHotkey reports every problem — load-time syntax errors, runtime
errors, uncaught exceptions, even `#SingleInstance Prompt` — through a **modal
dialog**. In an automated context that dialog has nobody to click it, so the
process blocks forever. This is the single most common way an AHK task appears
to hang.

`/AI` (synonym: `/NonInteractive`) makes the interpreter:

- never create a dialog for any diagnostic;
- never create the main window, the tray icon, or the `WH_MSGFILTER` hook, so
  nothing can block on a message pump;
- treat `#SingleInstance Prompt` as *ignore* rather than prompting;
- write a stable, parseable line to **stderr**;
- exit non-zero when a thread died from an unhandled error.

"Any diagnostic" is the claim, and it is wider than the error path. Upstream also
raises windows for things that are neither errors nor warnings, and a window is
the one thing an unattended run cannot survive: the hotkey throttle ("N hotkeys
have been received… Do you want to continue?"), a keyboard/mouse hook that could
not be activated, a hotkey that does not exist in the current keyboard layout,
`Edit()` failing to start an editor, and the debugger's connect/fatal prompts.
Under `/AI` each of those is one line on stderr, and the branch upstream took on
the user's answer is the one that **keeps the script running** — an unattended
caller can always kill the process, whereas exiting on a recoverable warning
destroys the thing being debugged with no explanation.

What is deliberately *not* suppressed: the windows your own script asks for.
`MsgBox()`, `InputBox()` and `Gui` still open windows, because those are program
behaviour rather than interpreter diagnostics; suppressing them would change the
language, not just its error reporting.

Measured on the same broken script: with `/AI` it returns in about 5 ms with a
precise diagnostic and exit 1; without it, it sat on a dialog until killed.

Interactive behaviour is unchanged unless the switch is passed, so `/AI` is
safe to add unconditionally in automation.

## Double-clicking a script is not a diagnostic path

This build ships two executables and installs nothing, so the `.ahk` association
on a machine belongs to whatever interpreter the user registered -- normally one
without `/AI`, because the flag suppresses the dialogs a human double-clicking a
script needs to see.

The consequence for an agent: **launch the interpreter yourself and pass the
switch.** Opening the `.ahk` file hands the decision to the registry, and a
broken script then produces a modal dialog, no stderr, and a call that blocks
until somebody dismisses it.

```powershell
AutoHotkey64.exe /AI script.ahk      # diagnostics on stderr, never a dialog
$LASTEXITCODE                        # 0 ok, 1 thread error, 2 load failure
```

### "Redirected" is not the same as "visible"

`AutoHotkey.exe` is a Windows **GUI-subsystem** binary, not a console program.
Started from a terminal without redirection it has no console attached, so
output goes nowhere and you see **nothing at all** -- while the process still
exits 0, which makes it look like the program simply printed nothing.

This affects `/AI` in particular:

- `/AI` exports diagnostics to stderr, and the build here calls
  `AttachConsole(ATTACH_PARENT_PROCESS)` so the text does appear in the terminal
  you launched it from.
- `OutputDebug()` attaches on its own first call, so debug output is visible with
  or without any switch.

The handle is not a usable signal for that decision. Measured for a GUI-subsystem
child of a real console: `GetStdHandle(STD_ERROR_HANDLE)` returns a **non-NULL,
non-`INVALID_HANDLE_VALUE`** handle that `GetFileType` even answers -- and every
byte written to it vanishes, because the process owns no console. It is
indistinguishable from a correctly redirected handle (both report
`FILE_TYPE_DISK`, both fail `GetConsoleMode`), so code that "checks first" either
skips the attach it needs or performs the one that would break redirection.
`AttachConsole` is the call that knows the difference: with redirected stderr it
succeeds and leaves the existing handles alone, and only for the unusable
inherited handle does it replace them with the console's.

Two consequences worth remembering:

- If you see no output, check whether you actually have a console before
  suspecting the script. `cmd /c "... 2>&1"`, `| Out-String` and `> file` all
  work because the redirection hands over a real pipe handle -- which can mask
  the problem entirely.
- **A test that redirects proves the bytes exist, not that anyone can see
  them.** `Invoke-AhkAi` and every `2>&1` capture fall in this category. To
  verify visibility you must own a console. The harness is
  `tools\test-console-visibility.ps1`; it launches the subject under a console it
  allocates and reads the screen buffer back, and self-checks the read-back with
  a sentinel so "nothing printed" cannot be mistaken for "the reader is broken".
- **Nor can a stderr capture see a window.** A regression that prints the
  diagnostic *and* still shows the dialog is green under every byte assertion and
  fatal to an unattended run, because the process then waits in a nested message
  loop. `tools\test-no-dialog.ps1` covers that half: `tools\DesktopProbe.cs`
  starts the interpreter on a private desktop of the current window station, so a
  dialog is rendered where no one can see or click it, and enumerates that desktop
  to report the window class, title and control text. The test's own positive
  control runs the same erroring script WITHOUT the switch and requires a dialog;
  without it, "no window" would be indistinguishable from a watcher that cannot
  see windows -- which is precisely the bug that control once caught (a poll loop
  comparing `WaitForSingleObject`'s result against `STILL_ACTIVE`/259 instead of
  `WAIT_TIMEOUT`/258 never ran, and six cases passed while looking at nothing).
- One interpreter dialog cannot be reproduced by a single process: `#SingleInstance
  Prompt` only asks once another instance of the same script already owns the main
  window the check looks for. `DesktopProbe` therefore accepts a second child
  (`<capture> <exe> <argv> --then <exe> <argv>`): it starts the prior instance,
  waits until that one really owns a window on the private desktop, then watches
  the second with its own pid as the scope and its stderr captured to a file.
  `test-no-dialog.ps1` asserts the prior instance's readiness and the capture as
  part of the case, because a `#SingleInstance` test whose first instance never
  registered would pass by watching an empty desktop. Run with the switch it exits
  silently with the reason on stderr; run without it the `#32770` prompt appears
  and the case is named by its button text.

## Do not execute a binary to find out which build it is

A stock interpreter does not know the new switch, so it treats the switch itself
as the script path, fails to find that file, and raises a **modal dialog** that no
amount of redirection can suppress -- `MsgBox` is a window, not console output.
An automated run would then sit behind that window until a timeout kills it.

Identity is therefore checked **statically**, by scanning the file for the wide
literal `/NonInteractive` that every `/AI` build contains and stock does not
(`AhkAi.psm1`'s `Test-AhkPatchedBuild`).

The same trap has a milder, more confusing cousin: an argument-rewriting shell can
delete the switch from a command that looks correct.  Git Bash / MSYS2 path
conversion turns `/AI` into `C:\Program Files\Git\AI`, the interpreter then reads
it as the script path, and the run is back to stock behaviour -- with `/AI`
apparently present in what you typed.  Recognise it by the combination *exit 2,
empty stderr, and an error box whose text ends in `\Git\AI`*.  Invoke the
interpreter from PowerShell or `cmd`, or set `MSYS_NO_PATHCONV=1` for that one
call.  `csc`'s `/nologo` is eaten the same way; that one is spelled `-nologo`.

## Running a script safely

```powershell
$exe = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
$p = Start-Process -FilePath $exe -ArgumentList @('/AI', $script) `
    -RedirectStandardOutput out.txt -RedirectStandardError err.txt `
    -PassThru -NoNewWindow
if (-not $p.WaitForExit(15000)) {
    $p.Kill()          # a script that blocks is a bug to report, not to wait on
    throw "timed out after 15s (does the script show a GUI or an InputBox?)"
}
$exit = $p.ExitCode
```

Three traps specific to PowerShell:

1. **`& exe args 2>&1` drops native stderr.** PowerShell only merges
   *PowerShell* streams; a native program's stderr is discarded. A failing
   script then looks like it produced no diagnostic at all. Redirect to files,
   or use `Start-Process -RedirectStandardError`.
2. **`ProcessStartInfo` + `WaitForExit()` can deadlock** when a child fills its
   stdout pipe before exiting. Either use `-RedirectStandardOutput` to files, or
   read the streams asynchronously before waiting. The helper module in
   `ahk-patch\tools\AhkAi.psm1` (`Invoke-AhkAi`) already does this correctly and
   applies a timeout.
3. **`[System.IO.File]::ReadAllBytes` with a relative path** resolves against
   the *process* working directory, not your shell's location. Pass absolute
   paths.

### Killing strays

A killed run can leave an `AutoHotkey64.exe` holding the script. Before
rebuilding or overwriting a binary, clear strays — but **only** ones you
started; other automation may be running its own interpreter legitimately:

```powershell
Get-Process -Name 'AutoHotkey*' -EA SilentlyContinue |
    Where-Object { $_.Path -like '*ahk-patch*' } |
    Stop-Process -Force
```

The suite should not need that. A test harness that starts an interpreter owns
the duty to finish it, and "we called `TerminateProcess` on the way out" only
covers an orderly exit: when the run is killed from outside, no cleanup code
executes at all. Three such orphans once sat on a private desktop for twenty
minutes with `dist\AutoHotkey64.exe` locked, so the next build could not copy
over it — invisible to everyone, and self-reproducing in any long CI queue. The
fix is a kernel guarantee rather than a code path: `DesktopProbe` claims its
child with a job object flagged `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`, so closing
the job — including by process death — reaps it. `tools\test-no-dialog.ps1`
holds the watcher to that standard directly: it kills the probe mid-run with a
child alive and asserts nothing survives, which is also the case that fails on
the pre-job-object probe.

## Exit codes

| Situation | Exit code |
| --- | --- |
| Normal completion (`ExitApp 0`) | `0` |
| Unhandled runtime error in a thread | `1` |
| Failed to load: syntax error, missing file | `2` |
| Deliberate `ExitApp n` | `n` |
| Warnings only | unchanged |

Note that a **warning does not change the exit code**. If a warning matters, you
must inspect stderr rather than relying on the code.

## stderr format

```
<file> (<line>) : ==> <message>
     Specifically: <extra>
File: <path>
Line: <n>
```

The `File:` / `Line:` block appears when the exception carries position
information. `<file>` is `<unknown>` when the failure happened before the source
file table existed — a missing script file is the usual case.

Real examples:

```
C:\temp\syn.ahk (3) : ==> Missing ")"
     Specifically: MsgBox("hi"

C:\temp\run.ahk (4) : ==> Warning: This local variable appears to never be assigned a value.

C:\temp\thr.ahk (2) : ==> boom

<unknown> (0) : ==> Script file not found.
```

Because the format is stable, prefer matching on it (for example
`^(.+) \((\d+)\) : ==>` ) over guessing from exit codes alone.

## How this relates to the stock features

These still exist and still work; `/AI` is the one to reach for, but knowing
what the others do prevents confusion.

| Feature | Scope | Limitation |
| --- | --- | --- |
| `/AI`, `/NonInteractive` | all diagnostics, no GUI at all | this build only |
| `/ErrorStdOut`, `#ErrorStdOut` | **load-time** syntax errors only | does not catch runtime errors |
| `#Warn All, StdOut` | warnings to stdout | warnings are not exceptions |
| `OnError(callback)` | runtime errors, if the callback returns 1 | can only be registered after the script has loaded, so it cannot catch load-time errors |
| `try` / `catch` | errors you expect | must actually cover the failing path |
| `/Debug` + DBGp | breakpoints, call stacks, variables | needs a DBGp client on the other end |
| `OutputDebug(Text)` | free-form tracing, no dialog, no exit-code change | stock sends it to a debugger or DebugView only; here it also reaches stderr |

If you are writing a script whose *purpose* is to run unattended, prefer
`/AI` plus a non-zero exit code over string-matching stderr.

## Tracing with `OutputDebug()`

`/AI` reports what went wrong. `OutputDebug()` is for what did not go wrong but
is worth seeing: which branch ran, what a value was, how far the script got
before it hung.

```ahk
OutputDebug("entering Sync-Registry")
regValue := RegRead("HKCU\Some\Key")        ; the risky call
OutputDebug("got: " regValue)
```

On this build each call writes to **stderr** as well as to whichever channel
stock used, so a caller in a terminal sees the trace:

```
entering Sync-Registry
got: 1
```

- stdout keeps carrying only what the script prints with
  `FileAppend(..., "*")`, so the two can be read as separate streams.
- The trace does not need `/AI`, but `/AI` is what guarantees the process owns a
  console when launched from one (`AutoHotkey.exe` is a GUI-subsystem binary;
  outside `/AI` the first `OutputDebug()` call attaches to the parent console,
  which fails harmlessly when there is none).
- With a DBGp debugger attached (`/Debug`) the debugger still receives the text
  exactly as before; the mirror is in addition to it, not instead of it.
- Redirected stderr is UTF-8, so non-ASCII traces survive a pipe. Read it as
  UTF-8 rather than trusting a GBK console's rendering.
- Because a trace is not an error, it never changes the exit code.

`tools/test-outputdebug.ps1` asserts all of the above against both
architectures, against a real console (no pipe anywhere), and against a stock
binary as the negative control. `samples/2-outputdebug.ahk` is the same thing on
a command line you can type.

## Debugging a script you cannot see

When a script fails and the reason is not obvious from the message, these
investigations are usually faster than reading the whole file:

```ahk
; 1. Is the function you called real, and how many arguments does it take?
if !IsSet(Func("MyFunc"))
    FileAppend "MyFunc does not exist`n", "*"

; 2. Does it exist, and what is its arity?
try {
    f := Func("StrLen")
    FileAppend "StrLen min=" f.MinParams " max=" f.MaxParams "`n", "*"
}

; 3. What did a value actually come back as?
x := StrSplit(text, ",")
FileAppend "type of x = " Type(x) "`n", "*"

; 4. How many elements did it end up with?
FileAppend "x.Length = " x.Length "`n", "*"
```

`FileAppend(..., "*")` writes to stdout and `FileAppend(..., "**")` to stderr,
which is the simplest way to instrument a script while debugging. Remove them
before delivering.

Two mistakes that produce very confusing errors, so check for them early:

- **Concatenating an object into a string.** `out .= someMap` raises
  `Expected a String but got a Map`. Walk it with `OwnProps()` instead.
- **Setting a Map with dot syntax.** `m.key := v` is silently ignored; only
  `m[key] := v` works. The read-back then returns nothing, which looks like the
  value was lost somewhere else.
