# AutoHotkey AI Patch Set

Customized AutoHotkey v2 builds that **follow upstream**, delivered as a patch
series instead of a fork. Upstream lives in a git submodule at a pinned commit;
`patches/` is applied on top at build time.

The product of this repository is exactly two files:

```
AutoHotkey64.exe    x64 interpreter
AutoHotkey32.exe    Win32 interpreter
```

No installer, no DLL, no sidecar config, no extra build flavour -- both
customizations are compiled into the interpreter itself.

- Upstream: <https://github.com/AutoHotkey/AutoHotkey> (`alpha` branch)
- Pinned base: **v2.1-alpha.32** (`d8f819c`)
- CI: GitHub Actions builds x64 and Win32 Release, verifies both customizations
  against a pristine control, and uploads each interpreter as an artifact.

## Why patches instead of a fork

A vendored fork drifts. This repo keeps a clean checkout of upstream and only
tracks the delta, so:

- `git -C upstream fetch && git checkout <newer>` + re-applying the series is
  the entire rebase story.
- If a patch fails to apply after an upstream bump, CI fails loudly and only
  the conflicting hunk needs attention.
- The diff stays reviewable — one patch file per source file.

## Features added by this patch set

### 1. Non-interactive / AI-friendly diagnostics (`/AI`, `/NonInteractive`)

Upstream AutoHotkey always reports load-time and runtime problems with a GUI
dialog (`Script::ShowError` → `DialogBoxParam`, falling back to `MsgBox`), which
hangs any headless/automated caller. `/ErrorStdOut` only covers *load-time*
syntax errors and `OnError()` does not intercept every runtime path.

New opt-in switch:

```
AutoHotkey64.exe /AI script.ahk
AutoHotkey64.exe /NonInteractive script.ahk
```

In this mode the interpreter:

- never creates a dialog for any diagnostic (load error, syntax error, runtime
  error, uncaught exception, warning, critical error, out-of-memory), nor for the
  notes upstream only ever raises as windows: the hotkey throttle ("N hotkeys have
  been received… Do you want to continue?"), a keyboard/mouse hook that could not
  be activated, a hotkey missing from the current keyboard layout, `Edit()`
  failing to launch an editor, and the debugger's failed-connect/fatal prompts;
- never creates the main window or tray icon, and never installs the
  `WH_MSGFILTER` hook (nothing can block on a message pump);
- when a dialog upstream uses to *ask* something has no one to answer, takes the
  branch that keeps the script running and prints the text instead. Exiting here
  would turn a recoverable warning into an unexplained death, and an unattended
  caller can always kill the process itself;
- treats `#SingleInstance Prompt` as *ignore* instead of prompting;
- writes a stable, parseable line to **stderr**:

  ```
  <file> (<line>) : ==> <message>
       Specifically: <extra>
  ```
  with a trailing `File: <path>` / `Line: <n>` block when an exception object
  carries position info;
- exits non-zero when a thread died from an unhandled error.

Windows a script asks for on purpose — `MsgBox()`, `InputBox()`, `Gui` — are
**not** touched: `/AI` suppresses the interpreter's own diagnostics, not the
script's UI.

Because `AutoHotkey.exe` is a Windows **GUI-subsystem** binary it does not
externally own a console. In `/AI` mode it therefore calls
`AttachConsole(ATTACH_PARENT_PROCESS)` so the diagnostics land in the terminal
you launched it from. Without that, running
`AutoHotkey64.exe /AI script.ahk` in a plain `cmd` window printed nothing at
all — the text only appeared when stderr was redirected (`2>&1`), which is not
how anyone types it. If there is no parent console the attach simply fails and
the behaviour falls back to redirect-only, so piping and `2>` still work.

> This is why `tools/test-noninteractive.ps1` is **not** sufficient on its own:
> it always redirects stderr into a pipe, so it verifies the bytes exist but not
> that a human would see them. `tools/test-console-visibility.ps1` owns a real
> console and checks the second question; CI runs both.

Normal interactive behaviour is unchanged unless the switch is passed.

### 2. `OutputDebug()` reaches the debugger **and** the command line

Upstream's `OutputDebug(Text)` is either/or: with a script-debugger client
connected the text goes to the debugger and `OutputDebugString()` is skipped, so
the only ways to read it are a debugger or DebugView. A caller sitting in a
terminal has neither and sees nothing at all.

This build keeps both existing destinations and adds a third: the text is also
mirrored to **stderr**, terminated on its own line.

```ahk
OutputDebug("about to touch the registry")   ; debugger + DebugView + stderr
```

- stdout stays reserved for what the script itself prints
  (`FileAppend(..., "*")`), so the two streams never mix and a caller can read
  them separately;
- the mirror belongs to the *function*, not to `/AI` — forgetting the switch
  still leaves debug output visible;
- `AutoHotkey.exe` is a GUI-subsystem binary, so outside `/AI` the first
  `OutputDebug()` call attaches to the parent console. That attach fails
  harmlessly when there is none (a double-clicked script), and redirected or
  piped stderr is written as UTF-8;
- this is the **only** change that is live without a switch, so it is audited as
  a deliberate divergence rather than claimed as parity: `tools/test-parity.ps1`
  runs the same script against a pristine binary and requires the difference to
  be exactly the debug lines — same exit code, same stdout.
  `tools/test-outputdebug.ps1` covers the rest, including the negative control
  (a stock build must stay silent) and the non-ASCII path.

Both customizations exist for one purpose: an AI (or any unattended caller) can
run and debug AHK scripts over a command line without ever risking a modal
dialog it cannot dismiss.

```
.
├── upstream/               git submodule -> AutoHotkey/AutoHotkey (pinned)
├── patches/                patch series, applied in filename order
│   ├── 0002-AutoHotkey.cpp.patch        parses /AI and /NonInteractive
│   ├── 0004-error.cpp.patch             diagnostics to stderr, never a dialog
│   ├── 0007-script.cpp.patch            /AI propagation (no window, no tray)
│   ├── 0008-script.h.patch              declarations
│   ├── 0009-script2.cpp.patch           OutputDebug() mirrors to the console
│   ├── 0010-Debugger.cpp.patch          DBGp connect/fatal prompts go to stderr
│   ├── 0011-hook.cpp.patch              hook-activation failure goes to stderr
│   └── 0012-hotkey.cpp.patch            hotkey throttle goes to stderr
├── tools/
│   ├── AhkAi.psm1          run the interpreter with a timeout + real stderr,
│   │                       or on a console it owns, or on a private desktop
│   │                       where a dialog can be seen but not touched;
│   │                       Test-AhkPatchedBuild (static patch-marker scan)
│   ├── ConsoleProbe.cs     console-owning launcher: argv in, screen buffer back
│   ├── DesktopProbe.cs     private-desktop launcher: argv in, window list back,
│   │                       child claimed by a kill-on-close job object
│   ├── apply-patches.ps1   clone/update upstream + apply the series
│   ├── build.ps1           MSBuild + copy the exe to dist/ + post-build checks
│   ├── download.ps1        fetch a CI artifact (and optionally smoke-test it)
│   ├── export-patches.ps1  re-export the series from a working tree
│   ├── pack-release.ps1    assemble/publish the two interpreters from a CI run
│   ├── test-console-visibility.ps1  /AI output is visible on a bare console
│   ├── test-dialog-guards.ps1       static: every interpreter dialog call is
│   │                                gated by mNonInteractive (sites no runtime
│   │                                test can reach on a given machine)
│   ├── test-no-dialog.ps1           /AI raises NO window (watched on a private
│   │                                desktop; a stock build must raise one; runs
│   │                                two instances for #SingleInstance)
│   ├── test-noninteractive.ps1      /AI contract (redirected; bytes only)
│   ├── test-outputdebug.ps1         OutputDebug() reaches the console, per arch
│   └── test-parity.ps1              behaviour matches stock, plus the audited
│                                    OutputDebug divergence against a control
├── docs/
│   ├── ARTIFACT_CONTENTS.txt  the payload list both build.ps1 and CI enforce
│   ├── debugging.md            how to run scripts so errors are visible
│   ├── v2-gotchas.md           v2 traps worth knowing in advance
│   └── README-AI.md            the /AI + OutputDebug contract, for an agent
├── samples/                one script per trap, runnable under /AI
├── UPSTREAM_PIN            the upstream commit the series is based on
└── .github/workflows/build.yml
```

## Non-interactive exit-code policy

| Situation | Exit code |
|---|---|
| Normal completion (`ExitApp 0`) | `0` |
| Unhandled runtime error in a thread | `1` (`EXIT_ERROR`) |
| Failed to load the script (syntax error, missing file) | `2` (`CRITICAL_ERROR`) |
| Deliberate `ExitApp n` | `n` |

Warnings do not change the exit code.

## Download the CI build

The `verify` job runs the `/AI` smoke test, the console-visibility check and the
`OutputDebug` check against the freshly built artifact, then rebuilds a pristine
binary from the same pin and compares the two -- so a green run proves both
customizations work on a clean runner and that nothing else changed.

```powershell
# latest successful run -> ./download, then smoke-test it
pwsh -NoProfile -File tools/download.ps1 -Test

# a specific run / artifact
pwsh -NoProfile -File tools/download.ps1 `
  -RunId 35368001961 -Artifact AutoHotkey32-Win32-Release

# equivalent raw gh commands
gh run list --workflow=build.yml --limit 5
gh run download <run-id> -n AutoHotkey64-x64-Release -D ./download
./download/AutoHotkey64.exe /AI samples/1-unset-var.ahk   # exit 1, stderr non-empty
./download/AutoHotkey64.exe samples/2-outputdebug.ahk     # debug text on stderr
```

Available artifacts: `AutoHotkey64-x64-Release` and `AutoHotkey32-Win32-Release`,
each containing the one interpreter. `tools/pack-release.ps1` pulls both out of a
green run and ships them as `AutoHotkey64.exe` + `AutoHotkey32.exe` +
`SHA256SUMS.txt`.

## Local build

```powershell
git submodule update --init --recursive
pwsh -NoProfile -File tools/apply-patches.ps1
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform x64   -OutDir dist
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform Win32 -OutDir dist

# the whole local suite, on both interpreters
pwsh -NoProfile -File tools/test-noninteractive.ps1     -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-console-visibility.ps1 -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-no-dialog.ps1          -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-outputdebug.ps1        -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-dialog-guards.ps1      -PristineSource pristine-test
```

Every `-Exe` above takes a comma- or semicolon-separated list and runs each
architecture in turn; repeating the switch is not valid for an array parameter,
and `-File` does not split `a,b` into two arguments the way `-Command` does, so
the tests normalise it themselves.

Requires VS 2022 Build Tools with the "Desktop development with C++" workload;
`tools/build.ps1` locates it via `vswhere` and sources `vcvarsall.bat` itself.
Output lands in `upstream/bin/AutoHotkey64.exe`; `-OutDir` copies the exe to
`dist/`, checks the payload against `docs/ARTIFACT_CONTENTS.txt` (the
interpreter, and nothing else) and verifies that `/AI` diagnostics are visible
on a bare console.

> Build **both** architectures before claiming success. CI has a `Release/Win32`
> job for good reason: a 32/64-bit difference in type aliasing (`UIntPtr` is
> `UInt32` on Win32 and `UInt64` on x64) once compiled cleanly for x64 and failed
> only under Win32.

### Proving the result is still stock in every other respect

The goal is "/AI and OutputDebug, as close to upstream as possible", so the
interesting claim is not that the new behaviour works but that **nothing else
changed**. Build a pristine binary from the same pin and compare:

```powershell
# NOTE the `../`: `-o` resolves against the submodule directory, not the shell's
# cwd, so `-o pristine.zip` drops the archive inside upstream/.
git -C upstream archive --format=zip -o ../pristine.zip HEAD
Expand-Archive pristine.zip pristine-test
pwsh -NoProfile -File tools/build.ps1 -UpstreamDir pristine-test
Copy-Item pristine-test/bin/AutoHotkey64.exe pristine-dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/test-parity.ps1 `
     -Patched dist/AutoHotkey64.exe `
     -Pristine pristine-dist/AutoHotkey64.exe `
     -PristineSource pristine-test
```

It runs both binaries with the **same** command line and compares exit code,
stdout and stderr byte-for-byte (after path normalisation). CI builds that
control for you.

> **Do not run stock on a failing script without a switch.** Stock reports errors
> with a modal dialog, and upstream's `/ErrorStdOut` does *not* make it safe: it
> only suppresses load-time non-warning errors (`error.cpp:257` makes `#Warn`
> always dialog, `error.cpp:789` makes runtime errors always dialog). So the
> parity test only covers invocations that are dialog-free on **both** sides —
> success, `ExitApp n`, empty script, argument passing, load-time syntax errors,
> and a missing script file — and treats a timeout as a failure rather than as
> equality. Runtime errors, `throw` and `#Warn` are checked on the patched side
> only (see `tools/test-console-visibility.ps1`).
>
> For the same reason the test does **not** prove "stock rejects `/AI`" by
> running stock with `/AI`: stock treats the unknown switch as the script path and
> raises "Script file not found". It reads the source instead.

> Note: `upstream/` must not have `core.autocrlf=true`. Upstream ships
> `* text=auto` and the patch series matches context lines byte-for-byte, so a
> CRLF work tree makes `git apply` fail. `apply-patches.ps1` sets
> `core.autocrlf=false` / `core.eol=lf` for you.

## Known upstream breakage

The **Self-contained** (`AutoHotkeySC.bin`) configuration does **not** compile
at the pinned upstream commit `d8f819c`. Verified against a pristine checkout
with zero patches applied: `source/script_module.cpp` is compiled
unconditionally yet references members that `script.h` hides behind
`#ifndef AUTOHOTKEYSC` (`sMaxSourceFiles`, `mCurrentModule`, `mFileIdx`,
`InitModuleSearchPath`, …), and `script.cpp` assigns to `LPTSTR sSourceFile[1]`.
22 errors, identical with and without this patch series.

It is therefore not built at all: the CI matrix is x64 Release and Win32
Release only. Should upstream fix it, adding a matrix entry is a one-line change
-- until then a target that cannot compile must not appear in the artifact list.

## Updating to a newer upstream

```powershell
git -C upstream fetch origin alpha
git -C upstream checkout <new-tag-or-sha>
git add upstream && git commit -m "bump upstream to <tag>"
pwsh -NoProfile -File tools/apply-patches.ps1 -CheckOnly  # surfaces conflicts
```

If a patch no longer applies, rebase it against the new base and re-export:

```powershell
git -C upstream apply --reject patches/0004-error.cpp.patch   # resolve .rej
# `--output=`, never `>`: PowerShell decodes git's stdout with the console code
# page, so a UTF-8 BOM arrives as GBK mojibake and the patch looks fine while
# its bytes are broken.  Unlike `git archive -o`, this path resolves against the
# shell's cwd, so there is no `../`.
git -C upstream diff --output=patches/0004-error.cpp.patch -- source/error.cpp
# or, for every file at once:
pwsh -NoProfile -File tools/export-patches.ps1
```

CI's `patch-check` job runs first and fails fast on a stale series, so an
upstream bump can never silently produce a mis-patched binary.
