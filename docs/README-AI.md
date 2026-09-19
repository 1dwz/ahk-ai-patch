# AHK-v2 — patched AutoHotkey for AI-driven work

This directory is a self-contained AutoHotkey v2 interpreter built for machine
use. Point your tooling at the two exes here; nothing else is required.

The behavioural changes against stock AutoHotkey are two **additive switches**:
`/AI` (plus its alias `/NonInteractive`), described below, and `/dump-api`, which
prints the built-in function table and exits. No built-in function was added,
removed or altered: the built-in set is exactly upstream's.

## What is here

| Path | What it is |
|---|---|
| `AutoHotkey64.exe` | 64-bit interpreter (no DLLs to ship) |
| `AutoHotkey32.exe` | 32-bit interpreter, same patches |
| `doc/BUILTIN_API.md` | Every built-in function signature, arity and return type |
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

```powershell
AutoHotkey64.exe /dump-api
```

Writes the built-in function table and exits without loading a script. The table
has two sections -- `g_BIF` entries as `name<TAB>min<TAB>max<TAB>variadic<TAB>outputs`,
then typed functions as `name<TAB>return<TAB>args`. This build reports **354**
functions (101 + 253), the same set as a stock v2 interpreter at the same
upstream commit. Stock AutoHotkey does not recognise `/dump-api` at all, so a
zero exit code is itself the proof that this is the patched build.

## Notes for an agent

- Prefer the **64-bit** exe unless a 32-bit-only dependency forces otherwise.
- A wrong built-in argument count is a **load-time** failure (exit 2), not a
  catchable exception. Check `MinParams` / `MaxParams` before calling, or read
  `doc/BUILTIN_API.md`.
- `A plain Object is not enumerable` — iterate `Map` and `Array`, not `{}`.
  `doc/v2-gotchas.md` has the details.
