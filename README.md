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

Normal interactive behaviour is unchanged unless the switch is passed.

## Repository layout

```
.
├── upstream/               git submodule -> AutoHotkey/AutoHotkey (pinned)
├── patches/                patch series, applied in filename order
│   ├── 0001-AutoHotkey.cpp.patch
│   ├── 0002-error.cpp.patch
│   ├── 0003-script.cpp.patch
│   └── 0004-script.h.patch
├── tools/
│   ├── apply-patches.ps1   clone/update upstream + apply the series
│   ├── build.ps1           configure + build with MSBuild
│   ├── export-patches.ps1  re-export the series from a working tree
│   └── test-noninteractive.ps1
└── .github/workflows/build.yml
```

## Local build

```powershell
# 1. submodule + patches
git submodule update --init --recursive
pwsh -NoProfile -File tools/apply-patches.ps1

# 2. build (needs VS 2022 Build Tools / MSVC + Windows SDK)
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform x64

# 3. smoke test the non-interactive contract
pwsh -NoProfile -File tools/test-noninteractive.ps1
```

Output lands in `upstream/bin/AutoHotkey64.exe`.

## Download the CI build

```powershell
gh run list --workflow=build.yml --limit 5
gh run download <run-id> -n AutoHotkey64-x64-Release -D ./dist
./dist/AutoHotkey64.exe /AI tools/tests/ok.ahk
```

## Updating to a newer upstream

```powershell
git -C upstream fetch origin alpha
git -C upstream checkout <new-tag-or-sha>
git add upstream && git commit -m "bump upstream to <tag>"
pwsh -NoProfile -File tools/apply-patches.ps1   # surfaces conflicts
pwsh -NoProfile -File tools/export-patches.ps1  # if you resolved them
```
