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

Measured on the same broken script: with `/AI` it returns in about 5 ms with a
precise diagnostic and exit 1; without it, it sat on a dialog until killed.

Interactive behaviour is unchanged unless the switch is passed, so `/AI` is
safe to add unconditionally in automation.

## The `.ahk` association does NOT pass `/AI`

The installed association is:

```
"C:\Program Files\AHK-v2\AutoHotkey64.exe" "%1" %*
```

There is deliberately no `/AI` in it. That flag suppresses the interpreter's
dialogs, so baking it into the association would hide load-time and runtime
errors from the humans who double-click a script — the opposite of helpful.

The consequence for an agent: **the association is not a diagnostic path.**
If you launch a script by opening the `.ahk` file, a broken script produces a
modal dialog and no stderr, and the call blocks until the dialog is dismissed.

Always invoke the interpreter yourself so you control the flags:

```powershell
AutoHotkey64.exe /AI script.ahk      # diagnostics on stderr, never a dialog
$LASTEXITCODE                        # 0 ok, 1 thread error, 2 load failure
```

Use the association only when you specifically want to test what a user sees.

### "Redirected" is not the same as "visible"

`AutoHotkey.exe` is a Windows **GUI-subsystem** binary, not a console program.
Started from a terminal without redirection it has no console attached, so
output goes nowhere and you see **nothing at all** -- while the process still
exits 0, which makes it look like the program simply printed nothing.

This affects `/AI` in particular:

- `/AI` exports diagnostics to stderr, and the build here calls
  `AttachConsole(ATTACH_PARENT_PROCESS)` so the text does appear in the terminal
  you launched it from.

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

## Do not execute a binary to find out which build it is

A stock interpreter does not know the new switch, so it treats the switch itself
as the script path, fails to find that file, and raises a **modal dialog** that no
amount of redirection can suppress -- `MsgBox` is a window, not console output.
An automated run would then sit behind that window until a timeout kills it.

Identity is therefore checked **statically**, by scanning the file for the wide
literal `/NonInteractive` that every `/AI` build contains and stock does not
(`AhkAi.psm1`'s `Test-AhkPatchedBuild`, and the equivalent in `AhkSetup.cs`).

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

If you are writing a script whose *purpose* is to run unattended, prefer
`/AI` plus a non-zero exit code over string-matching stderr.

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
