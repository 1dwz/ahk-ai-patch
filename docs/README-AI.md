# AHK-v2 — patched AutoHotkey for AI-driven work

This directory is a self-contained AutoHotkey v2 interpreter built for machine
use. Point your tooling at the two exes here; nothing else is required.

## What is here

| Path | What it is |
|---|---|
| `AutoHotkey64.exe` | 64-bit interpreter (static libcurl, no DLLs to ship) |
| `AutoHotkey32.exe` | 32-bit interpreter, same patches |
| `doc/BUILTIN_API.md` | Every built-in function signature, arity and return type |
| `doc/builtin-api.json` | The same index, machine-readable |
| `doc/BUILTIN_HTTP_JSON.md` | The `HttpRequest` / `JsonStringify` / `JsonParse` additions |
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

Writes one `name<TAB>signature` line per built-in function. This build reports
**357**; a stock v2 interpreter reports the same number but is missing the three
functions below, so check for those rather than trusting the count alone:

```powershell
AutoHotkey64.exe /dump-api | Select-String '^(HttpRequest|JsonStringify|JsonParse)\b'
```

## The additions

```ahk
resp := HttpRequest("https://example.com/api", { Method: "POST", Body: '{"a":1}' })
; -> Map with Status, Body, Headers

text := JsonStringify(Map("a", 1, "b", [1,2,3]))
obj  := JsonParse(text)
```

See `doc/BUILTIN_HTTP_JSON.md` for the full option list and the error model.

## Notes for an agent

- Prefer the **64-bit** exe unless a 32-bit-only dependency forces otherwise.
- `HttpRequest` uses Schannel, so it needs no CA bundle and respects the
  machine's proxy and certificate settings.
- A wrong built-in argument count is a **load-time** failure (exit 2), not a
  catchable exception. Check `MinParams` / `MaxParams` before calling, or read
  `doc/BUILTIN_API.md`.
- `A plain Object is not enumerable` — iterate `Map` and `Array`, not `{}`.
  `doc/v2-gotchas.md` has the details.
