# Patched AutoHotkey v2 for AI-driven work

Two files are the whole product: `AutoHotkey64.exe` and `AutoHotkey32.exe`. No
installer, no DLL, no sidecar config — point your tooling at the exe and a
script.

Against stock AutoHotkey there are exactly **two** behavioural changes, both
meant to let an unattended caller (an agent) run and debug a script over a
command line:

1. `/AI` — every diagnostic goes to stderr instead of a dialog, and the exit
   code says what happened;
2. `OutputDebug()` — the text reaches the console as well as the debugger.

No built-in function was added, removed or altered: the built-in set is exactly
upstream's.

## Run a script

```powershell
AutoHotkey64.exe /AI script.ahk
```

`/AI` is **not optional** for automation. Without it a broken script raises a
modal dialog, produces no stderr, and blocks until someone clicks it. With it,
diagnostics go to stderr as parseable text and the exit code tells you what
happened:

| Exit | Meaning |
|---|---|
| `0` | Normal completion |
| `1` | A thread died from an unhandled error |
| `2` | The script failed to load (syntax error, bad argument count) |
| `n` | An explicit `ExitApp n` in the script |

What `/AI` covers is everything the **interpreter** wants to tell you: load and
runtime errors, uncaught exceptions, warnings, out-of-memory, `#SingleInstance`,
and the notes upstream only ever raised as windows (hotkey throttle, a hook that
could not activate, a hotkey absent from the keyboard layout, `Edit()` failing to
start an editor, the debugger's connect prompts). None of them may become a
window; they are one line on stderr and the script continues.

What it does not cover is a window the script itself requests. A `MsgBox()`,
`InputBox()` or `Gui.Show()` in the code under test **still blocks** — that is the
program's behaviour, not the interpreter's error reporting. Keep a timeout around
any script that might open one of those.

The command-line grammar is upstream's, so read it before guessing: switches
must come **before** the script path, parsing stops at the first non-switch
argument, and everything after that path is a script argument.
`AutoHotkey.exe script.ahk /AI` does **not** enable `/AI`.

Beware the shell you type that switch into.  A POSIX-style shell that rewrites
arguments (Git Bash / MSYS2, and `cygpath`-style tooling generally) turns `/AI`
into a Windows path — `C:\Program Files\Git\AI` — which is no longer a switch but
the script path, so `/AI` is silently absent and the interpreter is back to
raising dialogs.  PowerShell, `cmd` and `Start-Process` pass it through as
written; from Git Bash set `MSYS_NO_PATHCONV=1` (or `MSYS2_ARG_CONV_EXCL='*'`)
for the call.  Symptom to recognise: exit `2`, empty stderr, and a dialog on
screen that mentions a path ending `\Git\AI`.

Under `/AI` a diagnostic is never a window: every case the interpreter would
report through a dialog in stock mode — load error, missing file, unhandled
runtime error, `throw`, warning — is written to stderr and the process returns.
`tools/test-no-dialog.ps1` asserts exactly that by watching a private desktop for
windows, and proves the watcher can see one by running the same argv against a
build that has no `/AI`.

In `/AI` mode the interpreter also skips the main window, the tray icon and the
`WH_MSGFILTER` hook, and treats `#SingleInstance Prompt` as *ignore*: a second
instance of the same script writes one warning to stderr and exits `0` rather than
opening the "Replace it with this instance?" box (stock behaviour, and a run that
never returns). Note the consequence when reading an exit code — `0` here can mean
"another instance already owns this script", which the stderr line names. Anything
that needs a GUI (tray menu, `ListLines`, Edit) is not available in this mode.

## Print debug output an agent can see

```ahk
OutputDebug("before the risky call")      ; stderr (plus debugger/DebugView)
FileAppend("result: " x "`n", "*")        ; stdout, only what the script prints
```

Stock `OutputDebug()` hands the text to a connected script debugger and
otherwise to `OutputDebugString()` — a terminal sees neither. Here it is mirrored
to stderr too, so it needs no switch: with no switch in play the first
`OutputDebug()` call attaches to the console the process was launched from (GUI
subsystem binaries are not given one), which fails harmlessly when there is
none. `/AI` additionally attaches at startup, so diagnostics and traces share one
visible stream either way.

- Debug text never lands in stdout, so the two streams stay separable.
- Each call is one terminated block; embedded newlines are preserved.
- Redirected or piped stderr is UTF-8, so non-ASCII messages survive a pipe
  (a GBK console renders them as mojibake — that is the terminal, not the data).
- `OutputDebug("")` writes nothing and does not stop the script.

## Confirming which build you have

Look for the `/NonInteractive` marker string in the file (see
`AhkAi.psm1`'s `Test-AhkPatchedBuild`). Do **not** probe it by running a switch
at it: a stock interpreter treats an unknown switch as the script path, fails to
find that file, and raises a modal dialog that blocks automation.

## Notes for an agent

- Prefer the **64-bit** exe unless a 32-bit-only dependency forces otherwise.
- A wrong built-in argument count is a **load-time** failure (exit 2), not a
  catchable exception.
- `A plain Object is not enumerable` — iterate `Map` and `Array`, not `{}`.
  `v2-gotchas.md` has the details; `debugging.md` covers running scripts so the
  output is actually visible.
