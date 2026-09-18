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

### 1. Built-in HTTP and JSON

Three new built-in functions, available with no `#Include` and no script
library — see **[docs/BUILTIN_HTTP_JSON.md](docs/BUILTIN_HTTP_JSON.md)** for the
full reference.

```ahk
resp := HttpRequest("https://example.com/api", {
    Method: "POST",
    Body: JsonStringify(Map("name", "test")),
    ContentType: "application/json"
})
if (resp["Ok"])
    data := JsonParse(resp["Body"])
```

`JsonParse` / `JsonStringify` are hand-written and dependency-free; integers
that fit in Int64 keep full precision, and malformed input raises a
`ValueError` rather than silently yielding `""`.

`HttpRequest` drives **libcurl, linked statically** into the interpreter, so a
built `AutoHotkey64.exe` is a single self-contained file — no `libcurl-x64.dll`
to ship and no CA bundle to locate. TLS goes through **Schannel**, so
certificates are validated against the Windows trust store. Transport failures
come back as `Status = 0` with an `Error` field; HTTP error statuses (`404`) are
normal returns with `Ok = 0`.

The only new runtime dependencies are Windows' own libraries: `ws2_32.dll`,
`iphlpapi.dll`, `secur32.dll`, `crypt32.dll` and `bcrypt.dll`.

The prebuilt import libraries live in `third_party/curl-static/` (committed: the
headers plus `lib-x64/libcurl.lib` and `lib-x86/libcurl.lib`, ~5 MB total).
`tools/build-libcurl-static.ps1` regenerates them from curl source when a new
curl is wanted.

### 2. Non-interactive / AI-friendly diagnostics (`/AI`, `/NonInteractive`)

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
│   ├── 0001-AutoHotkeyx.vcxproj.patch
│   ├── 0002-AutoHotkey.cpp.patch
│   ├── 0003-error.cpp.patch
│   ├── 0004-lib_http_builtin.cpp.patch
│   ├── 0005-lib_json_builtin.cpp.patch
│   ├── 0006-script.cpp.patch
│   └── 0007-script.h.patch
├── third_party/curl-static/  libcurl headers + libcurl.lib for x64 and x86
│                             (committed; built by tools/build-libcurl-static.ps1)
├── tools/
│   ├── AhkAi.psm1          run the interpreter with a timeout + real stderr
│   ├── apply-patches.ps1   clone/update upstream + apply the series
│   ├── build-libcurl-static.ps1  build libcurl as a static lib for x64/x86
│   ├── build.ps1           configure + build with MSBuild
│   ├── download.ps1        fetch a CI artifact (and optionally smoke-test it)
│   ├── export-patches.ps1  re-export the series from a working tree
│   ├── install-patched.ps1 install this build as the system interpreter
│   ├── test-noninteractive.ps1
│   └── test-json-http.ps1
├── docs/BUILTIN_HTTP_JSON.md
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

The `verify` job runs the smoke test against the freshly built artifact, so a
green run already proves the `/AI` contract on a clean runner.

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
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform x64 -OutDir dist
pwsh -NoProfile -File tools/test-noninteractive.ps1 -Exe dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/test-json-http.ps1 -Exe dist/AutoHotkey64.exe
```

Requires VS 2022 Build Tools with the "Desktop development with C++" workload;
`tools/build.ps1` locates it via `vswhere` and sources `vcvarsall.bat` itself.
Output lands in `upstream/bin/AutoHotkey64.exe`; `-OutDir` also copies it to
`dist/` and asserts the result has no libcurl DLL import.

Regenerating the static libcurl (only needed to bump curl itself):

```powershell
pwsh -NoProfile -File tools/build-libcurl-static.ps1 -Platform both
```

It downloads the pinned curl tarball into `third_party/src/` (git-ignored),
builds it with VS's bundled CMake + Ninja against the MSVC runtime, and leaves
the `.lib` files where the project expects them. `tools/build.ps1` never does
this automatically — CI uses the committed `.lib` files so a build stays fast.

`test-json-http.ps1` exercises the HTTP functions against `httpbin.org`, so it
needs network access. CI has none, so the `verify` job runs it with `-SkipHttp`
(the JSON half is fully offline); run it without that switch locally.

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

