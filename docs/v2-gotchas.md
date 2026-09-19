# AutoHotkey v2 traps

Things that produce confusing symptoms rather than clear errors. Each one here
has been hit for real, so they are worth checking early when a script misbehaves.

## `/AI` does not make your script headless

This is the most important one to internalise. `/AI` suppresses the
**interpreter's own** diagnostics. It does nothing about dialogs your script
creates:

```ahk
MsgBox("hello")     ; blocks forever under /AI — nobody can click it
InputBox("value?")  ; same
g := Gui()
g.Show()            ; same
```

Verified: a script that calls `MsgBox` under `/AI` writes its output up to that
line and then hangs until killed. So when a script must run unattended, it must
not create a GUI as part of its normal flow, and any prompt must be replaced by
an argument, an environment variable, or a file.

This is also why "the script hung" is usually worth checking for a `MsgBox`
before suspecting the interpreter.

## Values and types

**`{ Key: value }` is an `Object`, not a `Map`.** In v2.1-alpha this literal
form produces an `Object`, so `{a: 1} is Map` is false and `Has()` is not
available on it. Use `Map("a", 1)` when you want a Map.

**Objects held in variables are a distinct code path from inline literals.**
Only inline objects arrive as `SYM_OBJECT`; a variable yields `SYM_VAR`. Built-in
functions in this build handle both, but if you write C++ built-ins, testing
only the inline form will miss half the cases — this exact oversight caused a
bug where `JsonStringify(JsonParse(...))` worked but `p := JsonParse(...)` then
`JsonStringify(p)` returned `""`.

**A plain `Object` is not enumerable.** Only `Map` and `Array` support
`for k, v in obj` directly; a plain `Object` raises `Value not enumerable`.
Use `obj.OwnProps()` when you need to walk an object's fields:

```ahk
o := { a: 1, b: 2 }
for k, v in o.OwnProps()      ; correct
    out .= k "=" v
```

This matters when feeding object literals to `JsonStringify`, which serializes
`Map`, `Object` and `Array` alike — `{ a: 1 }` becomes `{"a":1}`. Nested
containers of any mix of those three types all serialize correctly.

**Concatenating a Map or Array raises.** `out .= someMap` gives
`Expected a String but got a Map`. Serialize explicitly:

```ahk
out .= JsonStringify(someMap)          ; correct
```

**`Map` needs index assignment.** `m.key := v` is silently ignored; only
`m[key] := v` stores. Reading `m.key` then yields nothing, which looks like the
data vanished somewhere else entirely.

**Object literal keys cannot be quoted.** `{ "X-B": "2" }` raises
`Invalid property name in object literal`, because `X-B` is not a legal
identifier. Build it instead:

```ahk
m := Map()
m["X-B"] := "2"
```

## Syntax that changed or never existed

**`Ord(s, index)` is gone.** In v2.1-alpha `Ord` takes exactly one argument and
handles surrogate pairs itself: `Ord("😀")` is `0x1F600`. `Ord(s, 2)` is not a
runtime error — it is rejected when the script **loads**:

```
(2) : ==> Too many parameters passed to function.
     Specifically: Ord
```

The same applies to any built-in called with the wrong number of arguments, and
it is why an arity mistake shows up as a bare "won't start" rather than as an
exception you could catch.

**There is no `??` operator.** `x ?? 0` fails to load with
`==> Unexpected "?"`. Use `HasProp("x") ? x : 0`.

**Static methods need `this.` inside the class.** Calling a sibling static
method by bare name makes AHK read it as an *unassigned local variable*, and you
get a `#Warn` about a variable that "appears to never be assigned a value" at a
line that looks perfectly fine:

```ahk
class C {
    static A() => this.B()      ; correct
    static B() => 1
}
```

The exception is a nested function *inside* a method body, which uses lexical
scope and must **not** get `this.`.

## Error handling

**`#Warn Off` does not catch errors.** It discards warnings only; runtime errors
still propagate.

**`OnError` cannot catch load-time errors.** The callback can only be
registered after the script has loaded, so syntax errors and a missing script
file are reported before it can ever run. Use `/AI` (or `/ErrorStdOut`) for
those.

**`try`/`catch` only covers the path it wraps.** A `try` around a function call
will not catch an error raised later inside a timer or a hotkey callback.

## Text and encoding

**A wrong argument count is a load-time failure, not a catchable error.** See
the `Ord` note above: `Too many parameters passed to function.` appears before
the script runs at all, so `try`/`catch` never sees it. To validate calls
dynamically, compare `f.MinParams` / `f.MaxParams` instead of relying on
exceptions.

**Files must be UTF-8 without a BOM.** A BOM or UTF-16 makes the interpreter
silently ignore the file's contents in configuration contexts, and mis-read the
first line in others.

**`StrReplace` takes five parameters before `Limit`.**

```ahk
StrReplace(s, "=", "`t", , , 1)    ; replace first only — three blanks then 1
StrReplace(s, "=", "`t", , 1)      ; WRONG: this sets CaseSense
```

When you only need to split on the first delimiter, `InStr` + `SubStr` is
easier to get right.

**`DllCall` puts the calling convention at the end.**

```ahk
DllCall(dll "\curl_easy_perform", "Cdecl Int", h)   ; with a return type
DllCall(dll "\curl_free", "Cdecl", ptr)             ; without one
```

Putting `"Cdecl Ptr"` in a parameter position calls it as stdcall and silently
shifts every argument. The rule that catches most mistakes: **types and
arguments must be pairwise**, and a trailing type with no argument becomes the
return type — so `DllCall(f, "Ptr", a, "Int", b, "Int64", c, "Ptr")` silently
drops `c`.

## PowerShell host traps

These bite specifically when driving AHK from PowerShell rather than writing
AHK:

- `& exe args 2>&1` **drops native stderr**, making failures look silent.
- `ProcessStartInfo` + `WaitForExit()` can deadlock when the child fills its
  stdout pipe.
- `[System.IO.File]::ReadAllBytes(relative)` resolves against the process
  working directory, not your shell location.

See `debugging.md` for the correct patterns.
