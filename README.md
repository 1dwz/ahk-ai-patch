# AutoHotkey AI Patch Set

Customized AutoHotkey v2 builds that **follow upstream**, delivered as a patch
series instead of a fork. Upstream lives in a git submodule at a pinned commit;
`patches/` is applied on top at build time.

- Upstream: <https://github.com/AutoHotkey/AutoHotkey> (`alpha` branch)
- Pinned base: **v2.1-alpha.32** (`d8f819c`)
- CI: GitHub Actions builds x64 Release (and optionally Win32 / Debug) and
  uploads the binaries as workflow artifacts.

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
  error, uncaught exception, warning, critical error, out-of-memory);
- never creates the main window or tray icon, and never installs the
  `WH_MSGFILTER` hook (nothing can block on a message pump);
- treats `#SingleInstance Prompt` as *ignore* instead of prompting;
- writes a stable, parseable line to **stderr**:

  ```
  <file> (<line>) : ==> <message>
       Specifically: <extra>
  ```
  with a trailing `File: <path>` / `Line: <n>` block when an exception object
  carries position info;
- exits non-zero when a thread died from an unhandled error.

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

### 2. Built-in API dump and generated documentation (`/dump-api`)

Upstream registers its built-in functions in **two disjoint tables**, and neither
is queryable from a running interpreter:

| Registry | Source | Entries | Carries |
| --- | --- | --- | --- |
| `g_BIF[]` | `source/script.cpp` | 101 | arity, variadic flag, output vars — no parameter names |
| `sMdFunc[]` | `source/MdFunc.cpp` | 253 | full `MdType` argument types and return type |

The sets do not overlap; together they are **354 functions**. `/dump-api` prints
them and exits, without loading a script:
```
AutoHotkey64.exe /dump-api
```

```
# name<TAB>min<TAB>max<TAB>variadic<TAB>outputs
# max is '*' when the function is variadic
Abs<TAB>1<TAB><TAB>0<TAB>
...

# typed functions (lib/functions.h)
# name<TAB>return<TAB>args (comma separated, in order)
StrLen<TAB>IntPtr<TAB>String
...
```

Two generators consume this, and both are run for you:

```powershell
# from upstream sources (cross-checks arity against the running interpreter)
pwsh -NoProfile -File tools/extract-api-docs.ps1 -OutDir docs/api -Verify -Exe dist/AutoHotkey64.exe
# from /dump-api output
pwsh -NoProfile -File tools/gen-builtin-docs.ps1 -Exe dist/AutoHotkey64.exe -OutDir dist
```

`tools/build.ps1` calls the second one automatically and emits `BUILTIN_API.md`
and `builtin-api.json` next to the executable, so a downloaded artifact is
self-describing. CI asserts the dump still reports 354 functions.


```
.
├── upstream/               git submodule -> AutoHotkey/AutoHotkey (pinned)
├── patches/                patch series, applied in filename order
│   ├── 0002-AutoHotkey.cpp.patch        also parses /dump-api
│   ├── 0003-MdFunc.cpp.patch            typed-function table for /dump-api
│   ├── 0004-error.cpp.patch
│   ├── 0007-script.cpp.patch
│   └── 0008-script.h.patch
├── tools/
│   ├── AhkAi.psm1          run the interpreter with a timeout + real stderr
│   ├── ConsoleProbe.cs     launch under a real console so output can be read back
│   ├── apply-patches.ps1   clone/update upstream + apply the series
│   ├── build.ps1           configure + build with MSBuild (+ docs, + console check)
│   ├── download.ps1        fetch a CI artifact (and optionally smoke-test it)
│   ├── export-patches.ps1  re-export the series from a working tree
│   ├── extract-api-docs.ps1    API reference built from upstream sources
│   ├── gen-builtin-docs.ps1    API reference built from /dump-api at runtime
│   ├── install-patched.ps1 install this build as the system interpreter
│   ├── test-console-visibility.ps1  /AI output is visible on a bare console
│   ├── test-noninteractive.ps1      /AI contract (redirected; bytes only)
│   ├── test-dump-api-console.ps1    /dump-api output reaches a real console
│   ├── DumpApiConsoleProbe.cs       launches it under a console it owns
│   ├── test-parity.ps1              behaviour matches stock outside the switches
│   ├── test-installer.ps1           install/uninstall round-trip
│   └── test-system-interpreter.ps1  the installed interpreter honours /AI
├── docs/
│   ├── debugging.md            how to run scripts so errors are visible
│   ├── v2-gotchas.md           v2 traps worth knowing in advance
│   ├── README-AI.md            artifact contents and the /AI contract
│   └── api/SIGNATURES.md, RUNTIME_API.md, builtin-api.json   generated, do not edit
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

The `verify` job runs the smoke test **and** the console-visibility check against
the freshly built artifact, so a green run proves the `/AI` contract on a clean
runner -- including that the diagnostics are actually visible, not merely
present on a redirected pipe.

```powershell
# latest successful run -> ./download, then smoke-test it
pwsh -NoProfile -File tools/download.ps1 -Test

# a specific run / artifact
pwsh -NoProfile -File tools/download.ps1 `
  -RunId 35368001961 -Artifact AutoHotkey32-Win32-Release

# equivalent raw gh commands
gh run list --workflow=build.yml --limit 5
gh run download <run-id> -n AutoHotkey64-x64-Release -D ./download
./download/AutoHotkey64.exe /AI tools/tests/ok.ahk
```

Available artifacts: `AutoHotkey64-x64-Release`, `AutoHotkey32-Win32-Release`,
`AutoHotkey64-x64-Debug`, and (experimental) `AutoHotkeySC-x64`.

## Local build

```powershell
git submodule update --init --recursive
pwsh -NoProfile -File tools/apply-patches.ps1
pwsh -pwsh -NoProfile -File tools/test-noninteractive.ps1 -Exe dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/test-console-visibility.ps1 -Exe dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/test-dump-api-console.ps1 -Exe dist/AutoHotkey64.exe
```

Requires VS 2022 Build Tools with the "Desktop development with C++" workload;
`tools/build.ps1` locates it via `vswhere` and sources `vcvarsall.bat` itself.
Output lands in `upstream/bin/AutoHotkey64.exe`; `-OutDir` also copies it to
`dist/`, generates the API reference, and checks that **both** `/AI` diagnostics
and the `/dump-api` table are visible on a bare console.

> Build **both** architectures before claiming success, then repack the installer.
> CI has a `Release/Win32` job for good reason: a duplicate-case-label bug in the
> `/dump-api` type naming (`MdType::UIntPtr` aliases `UInt32` on Win32 and
> `UInt64` on x64) compiled cleanly for x64 and failed only under Win32.

### Proving the result is still stock in every other respect

The goal is "/AI only, as close to upstream as possible", so the interesting
claim is not that the new switch works but that **nothing else changed**. Build a
pristine binary from the same pin and compare:

```powershell
git -C upstream archive --format=zip -o pristine.zip HEAD
Expand-Archive pristine.zip pristine-test
pwsh -NoProfile -File tools/build.ps1 -UpstreamDir pristine-test -OutDir pristine-dist
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
> raises "Script file not found". It reads the source instead.Win32 and
> `UInt64` on x64) compiled cleanly for x64 and failed only under Win32.

### Installing this build as the default interpreter

To make AI debugging work everywhere rather than only when a caller remembers
to pass `/AI`:

```powershell
pwsh -NoProfile -File tools/install-patched.ps1            # install
pwsh -NoProfile -File tools/install-patched.ps1 -Revert    # restore upstream
```

It backs the original binaries up to `backup-stock/` and **refuses to install a
candidate that does not demonstrably honour `/AI`**, so a stale build can never
be promoted by accident.

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

It is therefore kept in the CI matrix but marked `experimental`
(`continue-on-error`), so a future upstream fix is picked up automatically
while a failure never blocks the usable artifacts.

## Updating to a newer upstream

```powershell
git -C upstream fetch origin alpha
git -C upstream checkout <new-tag-or-sha>
git add upstream && git commit -m "bump upstream to <tag>"
pwsh -NoProfile -File tools/apply-patches.ps1 -CheckOnly  # surfaces conflicts
```

If a patch no longer applies, rebase it against the new base and re-export:

```powershell
git -C upstream apply --reject patches/0002-error.cpp.patch   # resolve .rej
git -C upstream diff -- source/error.cpp > patches/0002-error.cpp.patch
# or, for every file at once:
pwsh -NoProfile -File tools/export-patches.ps1
```

CI's `patch-check` job runs first and fails fast on a stale series, so an
upstream bump can never silently produce a mis-patched binary.
