# AHK-v2 — patched AutoHotkey for AI-driven work

This directory is a self-contained AutoHotkey v2 interpreter built for machine
use. Point your tooling at the two exes here; nothing else is required.

The behavioural change against stock AutoHotkey is a single **additive switch**:
`/AI` (plus its alias `/NonInteractive`), described below. No built-in function
was added, removed or altered: the built-in set is exactly upstream's.

## What is here

| Path | What it is |
|---|---|
| `AutoHotkey64.exe` | 64-bit interpreter (no DLLs to ship) |
| `AutoHotkey32.exe` | 32-bit interpreter, same patches |
| `doc/BUILTIN_API.md` | Every built-in function signature and return type, generated from source |
| `doc/builtin-api.json` | The same index, machine-readable |
| `doc/debugging.md` | How to run scripts so errors are actually visible |
| `doc/v2-gotchas.md` | Traps that cost time if you do not know them |
| `uninstall.exe` | Removes everything this installer added |

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

## Check what this build offers

Built-in signatures are documented in `doc/BUILTIN_API.md` (and machine-readably
in `doc/builtin-api.json`), generated from the AutoHotkey source tree at the
pinned upstream commit. There is no runtime switch for this: the tables live in
`source/lib/functions.h` and `source/script.cpp`.

This build reports **354** functions (253 + 101), the same set as a stock v2
interpreter at the same upstream commit. **253** carry full signatures with
parameter names; the other **101** are registered in a table that stores only a
name and an arity, and upstream has not migrated them yet, so those entries are
marked `[arity only]` and show no parameter names rather than invented ones.

To confirm a binary is this patched build, look for the `/NonInteractive` marker
string in the file (see `AhkAi.psm1`'s `Test-AhkPatchedBuild`). Do **not** probe
it by running a switch at it: a stock interpreter treats an unknown switch as the
script path, fails to find that file, and raises a modal dialog that blocks
automation.

## Notes for an agent

- Prefer the **64-bit** exe unless a 32-bit-only dependency forces otherwise.
- A wrong built-in argument count is a **load-time** failure (exit 2), not a
  catchable exception. Check `MinParams` / `MaxParams` before calling, or read
  `doc/BUILTIN_API.md`.
- `A plain Object is not enumerable` — iterate `Map` and `Array`, not `{}`.
  `doc/v2-gotchas.md` has the details.
