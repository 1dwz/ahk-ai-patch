# Built-in function reference

Generated from the AutoHotkey source tree. Do not edit by hand --
regenerate with `pwsh -NoProfile -File tools/extract-api-docs.ps1`.

354 built-in function(s) are declared in this source tree.

- **253** carry full signatures (directions, types, parameter names,
  return type), declared with the `md_func` family of macros in
  `source/lib/functions.h`.
- **101** are registered in the g_BIF[] table in
  `source/script.cpp`, which stores only a name and an arity. Their
  implementations take positional arguments, so **this source tree does
  not declare their parameter names**; upstream is migrating them to the
  `md_func` form and the rest have no names here to read. Those entries
  show their real arity and are marked `[arity only]`. No placeholder
  names are invented, because a placeholder is indistinguishable from a
  real parameter name once it is in a document.

`In` = required, `In_Opt` = optional, `Out*` = by-reference output,
`Ret` = return value. Types are the native declarations, which map to AHK
v2 values as: `String` -> String, `Int32`/`Int64`/`UInt32`/`IntPtr` -> Integer,
`Float64` -> Float, `Variant` -> any, `Object` -> Object/Map/Array.

## A

### Abs

```ahk
Abs(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ACos

```ahk
ACos(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ASin

```ahk
ASin(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ATan

```ahk
ATan(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ATan2

```ahk
ATan2(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## B

### BlockInput

```ahk
BlockInput(Mode)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In | `String` |  |

## C

### CallbackCreate

```ahk
CallbackCreate(Function, [, Options], [, Params])  -> UIntPtr
```

min params: 1, max params: 3; returns: `UIntPtr`; only built when `ifdef ENABLE_REGISTERCALLBACK`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Function` | In | `Object` |  |
| `Options` | In_Opt | `String` | yes |
| `Params` | In_Opt | `Variant` | yes |

### CallbackFree

```ahk
CallbackFree(Callback)
```

min params: 1, max params: 1; only built when `ifdef ENABLE_REGISTERCALLBACK`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Callback` | In | `UIntPtr` |  |

### CaretGetPos

```ahk
CaretGetPos([, X], [, Y])
```

min params: 0, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Variant` | yes |
| `Y` | Out_Opt | `Variant` | yes |

### Ceil

```ahk
Ceil(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Chr

```ahk
Chr(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Click

```ahk
Click(<0 to 6 arguments>)
```

min params: 0, max params: 6.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ClipWait

```ahk
ClipWait([, Timeout], [, AnyType])  -> Bool32
```

min params: 0, max params: 2; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Timeout` | In_Opt | `Float64` | yes |
| `AnyType` | In_Opt | `Int32` | yes |

### ComCall

```ahk
ComCall(<2 or more arguments>)
```

min params: 2, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjActive

```ahk
ComObjActive(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjConnect

```ahk
ComObjConnect(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjFlags

```ahk
ComObjFlags(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjFromPtr

```ahk
ComObjFromPtr(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjGet

```ahk
ComObjGet(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjQuery

```ahk
ComObjQuery(<2 to 3 arguments>)
```

min params: 2, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjType

```ahk
ComObjType(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ComObjValue

```ahk
ComObjValue(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ControlAddItem

```ahk
ControlAddItem(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> IntPtr
```

min params: 2, max params: 6; returns: `IntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlChooseIndex

```ahk
ControlChooseIndex(Index, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Index` | In | `IntPtr` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlChooseString

```ahk
ControlChooseString(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> IntPtr
```

min params: 2, max params: 6; returns: `IntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlClick

```ahk
ControlClick([, Control], [, WinTitle], [, WinText], [, Button], [, Count], [, Options], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 8.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In_Opt | `Variant` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Button` | In_Opt | `String` | yes |
| `Count` | In_Opt | `Int32` | yes |
| `Options` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlDeleteItem

```ahk
ControlDeleteItem(Index, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Index` | In | `IntPtr` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlFindItem

```ahk
ControlFindItem(Item, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> IntPtr
```

min params: 2, max params: 6; returns: `IntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Item` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlFocus

```ahk
ControlFocus(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetChecked

```ahk
ControlGetChecked(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Bool32
```

min params: 1, max params: 5; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetChoice

```ahk
ControlGetChoice(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 1, max params: 5; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetClassNN

```ahk
ControlGetClassNN(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 1, max params: 5; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetEnabled

```ahk
ControlGetEnabled(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Bool32
```

min params: 1, max params: 5; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetExStyle

```ahk
ControlGetExStyle(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 1, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetFocus

```ahk
ControlGetFocus([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetHwnd

```ahk
ControlGetHwnd(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 1, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetIndex

```ahk
ControlGetIndex(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> IntPtr
```

min params: 1, max params: 5; returns: `IntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetItems

```ahk
ControlGetItems(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Object
```

min params: 1, max params: 5; returns: `Object`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetPos

```ahk
ControlGetPos([, X], [, Y], [, Width], [, Height], Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 5, max params: 9.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Int32` | yes |
| `Y` | Out_Opt | `Int32` | yes |
| `Width` | Out_Opt | `Int32` | yes |
| `Height` | Out_Opt | `Int32` | yes |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetStyle

```ahk
ControlGetStyle(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 1, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetText

```ahk
ControlGetText(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 1, max params: 5; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlGetVisible

```ahk
ControlGetVisible(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Bool32
```

min params: 1, max params: 5; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlHide

```ahk
ControlHide(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlHideDropDown

```ahk
ControlHideDropDown(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlMove

```ahk
ControlMove([, X], [, Y], [, Width], [, Height], Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 5, max params: 9.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | In_Opt | `Int32` | yes |
| `Y` | In_Opt | `Int32` | yes |
| `Width` | In_Opt | `Int32` | yes |
| `Height` | In_Opt | `Int32` | yes |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSend

```ahk
ControlSend(Keys, [, Control], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Keys` | In | `String` |  |
| `Control` | In_Opt | `Variant` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSendText

```ahk
ControlSendText(Keys, [, Control], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Keys` | In | `String` |  |
| `Control` | In_Opt | `Variant` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSetChecked

```ahk
ControlSetChecked(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `Int32` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSetEnabled

```ahk
ControlSetEnabled(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `Int32` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSetExStyle

```ahk
ControlSetExStyle(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSetStyle

```ahk
ControlSetStyle(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlSetText

```ahk
ControlSetText(NewText, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `NewText` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlShow

```ahk
ControlShow(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ControlShowDropDown

```ahk
ControlShowDropDown(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### CoordMode

```ahk
CoordMode(TargetType, [, RelativeTo])  -> String
```

min params: 1, max params: 2; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `TargetType` | In | `String` |  |
| `RelativeTo` | In_Opt | `String` | yes |

### Cos

```ahk
Cos(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Critical

```ahk
Critical([, OnOffNumber])  -> Int32
```

min params: 0, max params: 1; returns: `Int32`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `OnOffNumber` | In_Opt | `String` | yes |

## D

### DateAdd

```ahk
DateAdd(DateTime, Time, TimeUnits)  -> String
```

min params: 3, max params: 3; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `DateTime` | In | `String` |  |
| `Time` | In | `Float64` |  |
| `TimeUnits` | In | `String` |  |

### DateDiff

```ahk
DateDiff(DateTime1, DateTime2, TimeUnits)  -> Int64
```

min params: 3, max params: 3; returns: `Int64`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `DateTime1` | In | `String` |  |
| `DateTime2` | In | `String` |  |
| `TimeUnits` | In | `String` |  |

### DefineProp

```ahk
DefineProp(<3 argument(s)>)
```

min params: 3, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### DetectHiddenText

```ahk
DetectHiddenText(Mode)  -> Bool32
```

min params: 1, max params: 1; returns: `Bool32`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In | `Bool32` |  |

### DetectHiddenWindows

```ahk
DetectHiddenWindows(Mode)  -> Bool32
```

min params: 1, max params: 1; returns: `Bool32`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In | `Bool32` |  |

### DirCopy

```ahk
DirCopy(Source, Dest, [, Overwrite])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Source` | In | `String` |  |
| `Dest` | In | `String` |  |
| `Overwrite` | In_Opt | `Int32` | yes |

### DirCreate

```ahk
DirCreate(Path)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |

### DirDelete

```ahk
DirDelete(Path, [, Recurse])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |
| `Recurse` | In_Opt | `Bool32` | yes |

### DirExist

```ahk
DirExist(Pattern)  -> String
```

min params: 1, max params: 1; returns: `String`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Pattern` | In | `String` |  |

### DirMove

```ahk
DirMove(Source, Dest, [, Flag])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Source` | In | `String` |  |
| `Dest` | In | `String` |  |
| `Flag` | In_Opt | `String` | yes |

### DirSelect

```ahk
DirSelect([, StartingFolder], [, Options], [, Prompt])  -> String
```

min params: 0, max params: 3; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `StartingFolder` | In_Opt | `String` | yes |
| `Options` | In_Opt | `Int32` | yes |
| `Prompt` | In_Opt | `String` | yes |

### DllCall

```ahk
DllCall(<1 or more arguments>)
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Download

```ahk
Download(URL, Path)
```

min params: 2, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `URL` | In | `String` |  |
| `Path` | In | `String` |  |

### DriveEject

```ahk
DriveEject([, Drive])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In_Opt | `String` | yes |

### DriveGetCapacity

```ahk
DriveGetCapacity(Path)  -> Int64
```

min params: 1, max params: 1; returns: `Int64`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |

### DriveGetFilesystem

```ahk
DriveGetFilesystem(Drive)  -> String
```

min params: 1, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In | `String` |  |

### DriveGetLabel

```ahk
DriveGetLabel(Drive)  -> String
```

min params: 1, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In | `String` |  |

### DriveGetList

```ahk
DriveGetList([, Type])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Type` | In_Opt | `String` | yes |

### DriveGetSerial

```ahk
DriveGetSerial(Drive)  -> Int64
```

min params: 1, max params: 1; returns: `Int64`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In | `String` |  |

### DriveGetSpaceFree

```ahk
DriveGetSpaceFree(Path)  -> Int64
```

min params: 1, max params: 1; returns: `Int64`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |

### DriveGetStatus

```ahk
DriveGetStatus(Path)  -> String
```

min params: 1, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |

### DriveGetStatusCD

```ahk
DriveGetStatusCD([, Drive])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In_Opt | `String` | yes |

### DriveGetType

```ahk
DriveGetType(Path)  -> String
```

min params: 1, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |

### DriveLock

```ahk
DriveLock(Drive)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In | `String` |  |

### DriveRetract

```ahk
DriveRetract([, Drive])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In_Opt | `String` | yes |

### DriveSetLabel

```ahk
DriveSetLabel(Drive, [, Label])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In | `String` |  |
| `Label` | In_Opt | `String` | yes |

### DriveUnlock

```ahk
DriveUnlock(Drive)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In | `String` |  |

## E

### Edit

```ahk
Edit([, Filename])
```

min params: 0, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Filename` | In_Opt | `String` | yes |

### EditGetCurrentCol

```ahk
EditGetCurrentCol(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 1, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### EditGetCurrentLine

```ahk
EditGetCurrentLine(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UIntPtr
```

min params: 1, max params: 5; returns: `UIntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### EditGetLine

```ahk
EditGetLine(Index, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 2, max params: 6; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Index` | In | `IntPtr` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### EditGetLineCount

```ahk
EditGetLineCount(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UIntPtr
```

min params: 1, max params: 5; returns: `UIntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### EditGetSelectedText

```ahk
EditGetSelectedText(Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 1, max params: 5; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### EditPaste

```ahk
EditPaste(Value, Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 2, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### EnvGet

```ahk
EnvGet(VarName)  -> String
```

min params: 1, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `VarName` | In | `String` |  |

### EnvSet

```ahk
EnvSet(VarName, [, Value])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `VarName` | In | `String` |  |
| `Value` | In_Opt | `String` | yes |

### Exit

```ahk
Exit([, ExitCode])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `ExitCode` | In_Opt | `Int32` | yes |

### ExitApp

```ahk
ExitApp([, ExitCode])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `ExitCode` | In_Opt | `Int32` | yes |

### Exp

```ahk
Exp(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## F

### FileAppend

```ahk
FileAppend(Value, [, Path], [, Options])
```

min params: 1, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `Variant` |  |
| `Path` | In_Opt | `String` | yes |
| `Options` | In_Opt | `String` | yes |

### FileCopy

```ahk
FileCopy(Source, Dest, [, Overwrite])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Source` | In | `String` |  |
| `Dest` | In | `String` |  |
| `Overwrite` | In_Opt | `Int32` | yes |

### FileCreateShortcut

```ahk
FileCreateShortcut(Target, LinkFile, [, WorkingDir], [, Args], [, Description], [, IconFile], [, ShortcutKey], [, IconNumber], [, RunState])
```

min params: 2, max params: 9.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Target` | In | `String` |  |
| `LinkFile` | In | `String` |  |
| `WorkingDir` | In_Opt | `String` | yes |
| `Args` | In_Opt | `String` | yes |
| `Description` | In_Opt | `String` | yes |
| `IconFile` | In_Opt | `String` | yes |
| `ShortcutKey` | In_Opt | `String` | yes |
| `IconNumber` | In_Opt | `Int32` | yes |
| `RunState` | In_Opt | `Int32` | yes |

### FileDelete

```ahk
FileDelete(Pattern)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Pattern` | In | `String` |  |

### FileEncoding

```ahk
FileEncoding(Encoding)  -> Variant
```

min params: 1, max params: 1; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Encoding` | In | `String` |  |

### FileExist

```ahk
FileExist(Pattern)  -> String
```

min params: 1, max params: 1; returns: `String`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Pattern` | In | `String` |  |

### FileGetAttrib

```ahk
FileGetAttrib([, Path])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In_Opt | `String` | yes |

### FileGetShortcut

```ahk
FileGetShortcut(LinkFile, [, Target], [, WorkingDir], [, Args], [, Description], [, IconFile], [, IconNum], [, RunState])
```

min params: 1, max params: 8.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `LinkFile` | In | `String` |  |
| `Target` | Out_Opt | `String` | yes |
| `WorkingDir` | Out_Opt | `String` | yes |
| `Args` | Out_Opt | `String` | yes |
| `Description` | Out_Opt | `String` | yes |
| `IconFile` | Out_Opt | `String` | yes |
| `IconNum` | Out_Opt | `Variant` | yes |
| `RunState` | Out_Opt | `Int32` | yes |

### FileGetSize

```ahk
FileGetSize([, Path], [, Units])  -> Int64
```

min params: 0, max params: 2; returns: `Int64`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In_Opt | `String` | yes |
| `Units` | In_Opt | `String` | yes |

### FileGetTime

```ahk
FileGetTime([, Path], [, WhichTime])  -> String
```

min params: 0, max params: 2; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In_Opt | `String` | yes |
| `WhichTime` | In_Opt | `String` | yes |

### FileGetVersion

```ahk
FileGetVersion([, Path])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In_Opt | `String` | yes |

### FileInstall

```ahk
FileInstall(Source, Dest, [, Overwrite])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Source` | In | `String` |  |
| `Dest` | In | `String` |  |
| `Overwrite` | In_Opt | `Int32` | yes |

### FileMove

```ahk
FileMove(Source, Dest, [, Overwrite])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Source` | In | `String` |  |
| `Dest` | In | `String` |  |
| `Overwrite` | In_Opt | `Int32` | yes |

### FileOpen

```ahk
FileOpen(<2 to 3 arguments>)
```

min params: 2, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### FileRead

```ahk
FileRead(Path, [, Options])  -> Variant
```

min params: 1, max params: 2; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |
| `Options` | In_Opt | `String` | yes |

### FileRecycle

```ahk
FileRecycle(Pattern)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Pattern` | In | `String` |  |

### FileRecycleEmpty

```ahk
FileRecycleEmpty([, Drive])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Drive` | In_Opt | `String` | yes |

### FileSelect

```ahk
FileSelect([, Options], [, RootDirFileName], [, Title], [, Filter])  -> Variant
```

min params: 0, max params: 4; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Options` | In_Opt | `String` | yes |
| `RootDirFileName` | In_Opt | `String` | yes |
| `Title` | In_Opt | `String` | yes |
| `Filter` | In_Opt | `String` | yes |

### FileSetAttrib

```ahk
FileSetAttrib(Attributes, [, Pattern], [, Mode])
```

min params: 1, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Attributes` | In | `String` |  |
| `Pattern` | In_Opt | `String` | yes |
| `Mode` | In_Opt | `String` | yes |

### FileSetTime

```ahk
FileSetTime([, YYYYMMDD], [, Pattern], [, WhichTime], [, Mode])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `YYYYMMDD` | In_Opt | `String` | yes |
| `Pattern` | In_Opt | `String` | yes |
| `WhichTime` | In_Opt | `String` | yes |
| `Mode` | In_Opt | `String` | yes |

### Floor

```ahk
Floor(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Format

```ahk
Format(<1 or more arguments>)
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### FormatTime

```ahk
FormatTime(<0 to 2 arguments>)
```

min params: 0, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## G

### GetKeyName

```ahk
GetKeyName(KeyName)  -> String
```

min params: 1, max params: 1; returns: `String`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `KeyName` | In | `String` |  |

### GetKeySC

```ahk
GetKeySC(KeyName)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `KeyName` | In | `String` |  |

### GetKeyState

```ahk
GetKeyState(KeyName, [, Mode])  -> Variant
```

min params: 1, max params: 2; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `KeyName` | In | `String` |  |
| `Mode` | In_Opt | `String` | yes |

### GetKeyVK

```ahk
GetKeyVK(KeyName)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `KeyName` | In | `String` |  |

### GetMethod

```ahk
GetMethod(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### GroupActivate

```ahk
GroupActivate(GroupName, [, Mode])  -> UInt32
```

min params: 1, max params: 2; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `GroupName` | In | `String` |  |
| `Mode` | In_Opt | `String` | yes |

### GroupAdd

```ahk
GroupAdd(GroupName, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `GroupName` | In | `String` |  |
| `WinTitle` | In_Opt | `String` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### GroupClose

```ahk
GroupClose(GroupName, [, Mode])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `GroupName` | In | `String` |  |
| `Mode` | In_Opt | `String` | yes |

### GroupDeactivate

```ahk
GroupDeactivate(GroupName, [, Mode])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `GroupName` | In | `String` |  |
| `Mode` | In_Opt | `String` | yes |

### GuiCtrlFromHwnd

```ahk
GuiCtrlFromHwnd(Hwnd)  -> Object
```

min params: 1, max params: 1; returns: `Object`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Hwnd` | In | `UInt32` |  |

### GuiFromHwnd

```ahk
GuiFromHwnd(Hwnd, [, Recurse])  -> Object
```

min params: 1, max params: 2; returns: `Object`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Hwnd` | In | `UInt32` |  |
| `Recurse` | In_Opt | `Bool32` | yes |

## H

### HasBase

```ahk
HasBase(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### HasMethod

```ahk
HasMethod(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### HasProp

```ahk
HasProp(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### HotIf

```ahk
HotIf([, Criterion])  -> Variant
```

min params: 0, max params: 1; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Criterion` | In_Opt | `Variant` | yes |

### HotIfWinActive

```ahk
HotIfWinActive([, WinTitle], [, WinText])  -> Variant
```

min params: 0, max params: 2; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `String` | yes |
| `WinText` | In_Opt | `String` | yes |

### HotIfWinExist

```ahk
HotIfWinExist([, WinTitle], [, WinText])  -> Variant
```

min params: 0, max params: 2; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `String` | yes |
| `WinText` | In_Opt | `String` | yes |

### HotIfWinNotActive

```ahk
HotIfWinNotActive([, WinTitle], [, WinText])  -> Variant
```

min params: 0, max params: 2; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `String` | yes |
| `WinText` | In_Opt | `String` | yes |

### HotIfWinNotExist

```ahk
HotIfWinNotExist([, WinTitle], [, WinText])  -> Variant
```

min params: 0, max params: 2; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `String` | yes |
| `WinText` | In_Opt | `String` | yes |

### Hotkey

```ahk
Hotkey(KeyName, [, Action], [, Options])
```

min params: 1, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `KeyName` | In | `String` |  |
| `Action` | In_Opt | `Variant` | yes |
| `Options` | In_Opt | `String` | yes |

### Hotstring

```ahk
Hotstring(String, [, Replacement], [, OnOffToggle])  -> Variant
```

min params: 1, max params: 3; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `String` | In | `String` |  |
| `Replacement` | In_Opt | `Variant` | yes |
| `OnOffToggle` | In_Opt | `String` | yes |

## I

### IL_Add

```ahk
IL_Add(ImageList, Filename, [, IconNumber], [, ResizeNonIcon])  -> Int32
```

min params: 2, max params: 4; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `ImageList` | In | `UIntPtr` |  |
| `Filename` | In | `String` |  |
| `IconNumber` | In_Opt | `Int32` | yes |
| `ResizeNonIcon` | In_Opt | `Bool32` | yes |

### IL_Create

```ahk
IL_Create([, InitialCount], [, GrowCount], [, LargeIcons])
```

min params: 0, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `InitialCount` | In_Opt | `Int32` | yes |
| `GrowCount` | In_Opt | `Int32` | yes |
| `LargeIcons` | In_Opt | `Bool32` | yes |

### IL_Destroy

```ahk
IL_Destroy(ImageList)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `ImageList` | In | `UIntPtr` |  |

### ImageSearch

```ahk
ImageSearch([, X], [, Y], X1, Y1, X2, Y2, Image)  -> Bool32
```

min params: 7, max params: 7; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Variant` | yes |
| `Y` | Out_Opt | `Variant` | yes |
| `X1` | In | `Int32` |  |
| `Y1` | In | `Int32` |  |
| `X2` | In | `Int32` |  |
| `Y2` | In | `Int32` |  |
| `Image` | In | `String` |  |

### IniDelete

```ahk
IniDelete(Path, Section, [, Key])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |
| `Section` | In | `String` |  |
| `Key` | In_Opt | `String` | yes |

### IniRead

```ahk
IniRead(Path, [, Section], [, Key], [, Default])  -> String
```

min params: 1, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |
| `Section` | In_Opt | `String` | yes |
| `Key` | In_Opt | `String` | yes |
| `Default` | In_Opt | `String` | yes |

### IniWrite

```ahk
IniWrite(Value, Path, Section, [, Key])
```

min params: 3, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `Path` | In | `String` |  |
| `Section` | In | `String` |  |
| `Key` | In_Opt | `String` | yes |

### InputBox

```ahk
InputBox([, Prompt], [, Title], [, Options], [, Default])  -> Object
```

min params: 0, max params: 4; returns: `Object`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Prompt` | In_Opt | `String` | yes |
| `Title` | In_Opt | `String` | yes |
| `Options` | In_Opt | `String` | yes |
| `Default` | In_Opt | `String` | yes |

### InstallKeybdHook

```ahk
InstallKeybdHook([, Install], [, Force])
```

min params: 0, max params: 2; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Install` | In_Opt | `Bool32` | yes |
| `Force` | In_Opt | `Bool32` | yes |

### InstallMouseHook

```ahk
InstallMouseHook([, Install], [, Force])
```

min params: 0, max params: 2; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Install` | In_Opt | `Bool32` | yes |
| `Force` | In_Opt | `Bool32` | yes |

### InStr

```ahk
InStr(<2 to 5 arguments>)
```

min params: 2, max params: 5.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsAlnum

```ahk
IsAlnum(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsAlpha

```ahk
IsAlpha(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsDigit

```ahk
IsDigit(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsFloat

```ahk
IsFloat(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsInteger

```ahk
IsInteger(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsLabel

```ahk
IsLabel(Name)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Name` | In | `String` |  |

### IsLower

```ahk
IsLower(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsNumber

```ahk
IsNumber(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsObject

```ahk
IsObject(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsSetRef

```ahk
IsSetRef(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsSpace

```ahk
IsSpace(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsTime

```ahk
IsTime(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsUpper

```ahk
IsUpper(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### IsXDigit

```ahk
IsXDigit(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## K

### KeyHistory

```ahk
KeyHistory([, MaxEvents])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `MaxEvents` | In_Opt | `Int32` | yes |

### KeyWait

```ahk
KeyWait(KeyName, [, Options])  -> Bool32
```

min params: 1, max params: 2; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `KeyName` | In | `String` |  |
| `Options` | In_Opt | `String` | yes |

## L

### ListHotkeys

```ahk
ListHotkeys()
```

min params: 0, max params: 0; statement form (returns the previous setting).

### ListLines

```ahk
ListLines([, Mode])  -> Int32
```

min params: 0, max params: 1; returns: `Int32`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In_Opt | `Int32` | yes |

### ListVars

```ahk
ListVars()
```

min params: 0, max params: 0; statement form (returns the previous setting).

### ListViewGetContent

```ahk
ListViewGetContent([, Options], Control, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Variant
```

min params: 2, max params: 6; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Options` | In_Opt | `String` | yes |
| `Control` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### Ln

```ahk
Ln(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### LoadPicture

```ahk
LoadPicture(Filename, [, Options], [, ImageType])  -> UIntPtr
```

min params: 1, max params: 3; returns: `UIntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Filename` | In | `String` |  |
| `Options` | In_Opt | `String` | yes |
| `ImageType` | Out_Opt | `Int32` | yes |

### Log

```ahk
Log(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### LTrim

```ahk
LTrim(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## M

### Max

```ahk
Max(<1 or more arguments>)
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### MenuFromHandle

```ahk
MenuFromHandle(Handle)  -> Object
```

min params: 1, max params: 1; returns: `Object`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Handle` | In | `UIntPtr` |  |

### MenuSelect

```ahk
MenuSelect([, WinTitle], [, WinText], Menu, [, SubMenu1], [, SubMenu2], [, SubMenu3], [, SubMenu4], [, SubMenu5], [, SubMenu6], [, ExcludeTitle], [, ExcludeText])
```

min params: 3, max params: 11.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Menu` | In | `String` |  |
| `SubMenu1` | In_Opt | `String` | yes |
| `SubMenu2` | In_Opt | `String` | yes |
| `SubMenu3` | In_Opt | `String` | yes |
| `SubMenu4` | In_Opt | `String` | yes |
| `SubMenu5` | In_Opt | `String` | yes |
| `SubMenu6` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### Min

```ahk
Min(<1 or more arguments>)
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Mod

```ahk
Mod(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### MonitorGet

```ahk
MonitorGet([, N], [, Left], [, Top], [, Right], [, Bottom])  -> Int32
```

min params: 0, max params: 5; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `N` | In_Opt | `Int32` | yes |
| `Left` | Out_Opt | `Int32` | yes |
| `Top` | Out_Opt | `Int32` | yes |
| `Right` | Out_Opt | `Int32` | yes |
| `Bottom` | Out_Opt | `Int32` | yes |

### MonitorGetCount

```ahk
MonitorGetCount()
```

min params: 0, max params: 0.

### MonitorGetName

```ahk
MonitorGetName([, N])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `N` | In_Opt | `Int32` | yes |

### MonitorGetPrimary

```ahk
MonitorGetPrimary()
```

min params: 0, max params: 0.

### MonitorGetWorkArea

```ahk
MonitorGetWorkArea([, N], [, Left], [, Top], [, Right], [, Bottom])  -> Int32
```

min params: 0, max params: 5; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `N` | In_Opt | `Int32` | yes |
| `Left` | Out_Opt | `Int32` | yes |
| `Top` | Out_Opt | `Int32` | yes |
| `Right` | Out_Opt | `Int32` | yes |
| `Bottom` | Out_Opt | `Int32` | yes |

### MouseClick

```ahk
MouseClick([, Button], [, X], [, Y], [, ClickCount], [, Speed], [, DownOrUp], [, Relative])
```

min params: 0, max params: 7.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Button` | In_Opt | `String` | yes |
| `X` | In_Opt | `Int32` | yes |
| `Y` | In_Opt | `Int32` | yes |
| `ClickCount` | In_Opt | `Int32` | yes |
| `Speed` | In_Opt | `Int32` | yes |
| `DownOrUp` | In_Opt | `String` | yes |
| `Relative` | In_Opt | `String` | yes |

### MouseClickDrag

```ahk
MouseClickDrag([, Button], [, X1], [, Y1], X2, Y2, [, Speed], [, Relative])
```

min params: 5, max params: 7.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Button` | In_Opt | `String` | yes |
| `X1` | In_Opt | `Int32` | yes |
| `Y1` | In_Opt | `Int32` | yes |
| `X2` | In | `Int32` |  |
| `Y2` | In | `Int32` |  |
| `Speed` | In_Opt | `Int32` | yes |
| `Relative` | In_Opt | `String` | yes |

### MouseGetPos

```ahk
MouseGetPos([, X], [, Y], [, Win], [, Control], [, Flag])
```

min params: 0, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Int32` | yes |
| `Y` | Out_Opt | `Int32` | yes |
| `Win` | Out_Opt | `Variant` | yes |
| `Control` | Out_Opt | `Variant` | yes |
| `Flag` | In_Opt | `Int32` | yes |

### MouseMove

```ahk
MouseMove(X, Y, [, Speed], [, Relative])
```

min params: 2, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | In | `Int32` |  |
| `Y` | In | `Int32` |  |
| `Speed` | In_Opt | `Int32` | yes |
| `Relative` | In_Opt | `String` | yes |

### MsgBox

```ahk
MsgBox([, Text], [, Title], [, Options])  -> String
```

min params: 0, max params: 3; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Text` | In_Opt | `String` | yes |
| `Title` | In_Opt | `String` | yes |
| `Options` | In_Opt | `String` | yes |

## N

### NumGet

```ahk
NumGet(<2 to 3 arguments>)
```

min params: 2, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### NumPut

```ahk
NumPut(<3 or more arguments>)
```

min params: 3, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## O

### ObjAddRef

```ahk
ObjAddRef(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjBindMethod

```ahk
ObjBindMethod(<1 or more arguments>)
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjFromPtr

```ahk
ObjFromPtr(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjFromPtrAddRef

```ahk
ObjFromPtrAddRef(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjGetBase

```ahk
ObjGetBase(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjGetCapacity

```ahk
ObjGetCapacity(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjGetDataPtr

```ahk
ObjGetDataPtr(Obj)  -> UIntPtr
```

min params: 1, max params: 1; returns: `UIntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Obj` | In | `Object` |  |

### ObjGetDataSize

```ahk
ObjGetDataSize(Obj)  -> UIntPtr
```

min params: 1, max params: 1; returns: `UIntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Obj` | In | `Object` |  |

### ObjHasOwnProp

```ahk
ObjHasOwnProp(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjOwnPropCount

```ahk
ObjOwnPropCount(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjOwnProps

```ahk
ObjOwnProps(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjPtr

```ahk
ObjPtr(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjPtrAddRef

```ahk
ObjPtrAddRef(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjRelease

```ahk
ObjRelease(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjSetBase

```ahk
ObjSetBase(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjSetCapacity

```ahk
ObjSetCapacity(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ObjSetDataPtr

```ahk
ObjSetDataPtr(Obj, Ptr)
```

min params: 2, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Obj` | In | `Object` |  |
| `Ptr` | In | `UIntPtr` |  |

### OnClipboardChange

```ahk
OnClipboardChange(Function, [, AddRemove])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Function` | In | `Object` |  |
| `AddRemove` | In_Opt | `Int32` | yes |

### OnError

```ahk
OnError(Function, [, AddRemove])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Function` | In | `Object` |  |
| `AddRemove` | In_Opt | `Int32` | yes |

### OnExit

```ahk
OnExit(Function, [, AddRemove])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Function` | In | `Object` |  |
| `AddRemove` | In_Opt | `Int32` | yes |

### OnMessage

```ahk
OnMessage(Number, Function, [, MaxThreads])
```

min params: 2, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Number` | In | `UInt32` |  |
| `Function` | In | `Object` |  |
| `MaxThreads` | In_Opt | `Int32` | yes |

### Ord

```ahk
Ord(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### OutputDebug

```ahk
OutputDebug(Text)
```

min params: 1, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Text` | In | `String` |  |

## P

### Pause

```ahk
Pause([, NewState])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `NewState` | In_Opt | `Int32` | yes |

### Persistent

```ahk
Persistent([, NewValue])  -> Bool32
```

min params: 0, max params: 1; returns: `Bool32`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `NewValue` | In_Opt | `Bool32` | yes |

### PixelGetColor

```ahk
PixelGetColor(X, Y, [, Mode])  -> String
```

min params: 2, max params: 3; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | In | `Int32` |  |
| `Y` | In | `Int32` |  |
| `Mode` | In_Opt | `String` | yes |

### PixelSearch

```ahk
PixelSearch([, X], [, Y], X1, Y1, X2, Y2, Color, [, Variation])  -> Bool32
```

min params: 7, max params: 8; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Variant` | yes |
| `Y` | Out_Opt | `Variant` | yes |
| `X1` | In | `Int32` |  |
| `Y1` | In | `Int32` |  |
| `X2` | In | `Int32` |  |
| `Y2` | In | `Int32` |  |
| `Color` | In | `UInt32` |  |
| `Variation` | In_Opt | `Int32` | yes |

### PostMessage

```ahk
PostMessage(Msg, [, wParam], [, lParam], [, Control], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 8.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Msg` | In | `UInt32` |  |
| `wParam` | In_Opt | `Variant` | yes |
| `lParam` | In_Opt | `Variant` | yes |
| `Control` | In_Opt | `Variant` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### ProcessClose

```ahk
ProcessClose(Process)  -> UInt32
```

min params: 1, max params: 1; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In | `String` |  |

### ProcessExist

```ahk
ProcessExist([, Process])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In_Opt | `String` | yes |

### ProcessGetName

```ahk
ProcessGetName([, Process])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In_Opt | `String` | yes |

### ProcessGetParent

```ahk
ProcessGetParent([, Process])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In_Opt | `String` | yes |

### ProcessGetPath

```ahk
ProcessGetPath([, Process])  -> String
```

min params: 0, max params: 1; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In_Opt | `String` | yes |

### ProcessSetPriority

```ahk
ProcessSetPriority(Priority, [, Process])  -> UInt32
```

min params: 1, max params: 2; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Priority` | In | `String` |  |
| `Process` | In_Opt | `String` | yes |

### ProcessWait

```ahk
ProcessWait(Process, [, Timeout])  -> UInt32
```

min params: 1, max params: 2; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In | `String` |  |
| `Timeout` | In_Opt | `Float64` | yes |

### ProcessWaitClose

```ahk
ProcessWaitClose(Process, [, Timeout])  -> UInt32
```

min params: 1, max params: 2; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Process` | In | `String` |  |
| `Timeout` | In_Opt | `Float64` | yes |

### Props

```ahk
Props(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## R

### Random

```ahk
Random(<0 to 2 arguments>)
```

min params: 0, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### RegCreateKey

```ahk
RegCreateKey(<0 to 1 arguments>)
```

min params: 0, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### RegDelete

```ahk
RegDelete(<0 to 2 arguments>)
```

min params: 0, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### RegDeleteKey

```ahk
RegDeleteKey(<0 to 1 arguments>)
```

min params: 0, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### RegExMatch

```ahk
RegExMatch(Haystack, Needle, [, Match], [, StartingPos])  -> Int32
```

min params: 2, max params: 4; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Haystack` | In | `Variant` |  |
| `Needle` | In | `String` |  |
| `Match` | Out_Opt | `Object` | yes |
| `StartingPos` | In_Opt | `Int32` | yes |

### RegExReplace

```ahk
RegExReplace(Haystack, Needle, [, Replacement], [, Count], [, Limit], [, StartingPos])  -> Variant
```

min params: 2, max params: 6; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Haystack` | In | `Variant` |  |
| `Needle` | In | `String` |  |
| `Replacement` | In_Opt | `Variant` | yes |
| `Count` | Out_Opt | `Int32` | yes |
| `Limit` | In_Opt | `Int32` | yes |
| `StartingPos` | In_Opt | `Int32` | yes |

### RegRead

```ahk
RegRead(<0 to 3 arguments>)
```

min params: 0, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### RegWrite

```ahk
RegWrite(<1 to 4 arguments>)
```

min params: 1, max params: 4.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Reload

```ahk
Reload()
```

min params: 0, max params: 0.

### Round

```ahk
Round(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### RTrim

```ahk
RTrim(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Run

```ahk
Run(Target, [, WorkingDir], [, Options], [, PID])
```

min params: 1, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Target` | In | `String` |  |
| `WorkingDir` | In_Opt | `String` | yes |
| `Options` | In_Opt | `String` | yes |
| `PID` | Out_Opt | `Variant` | yes |

### RunAs

```ahk
RunAs([, User], [, Password], [, Domain])
```

min params: 0, max params: 3; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `User` | In_Opt | `String` | yes |
| `Password` | In_Opt | `String` | yes |
| `Domain` | In_Opt | `String` | yes |

### RunWait

```ahk
RunWait(Target, [, WorkingDir], [, Options], [, PID])  -> Int32
```

min params: 1, max params: 4; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Target` | In | `String` |  |
| `WorkingDir` | In_Opt | `String` | yes |
| `Options` | In_Opt | `String` | yes |
| `PID` | In_Opt | `Object` | yes |

## S

### Send

```ahk
Send(Keys)
```

min params: 1, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Keys` | In | `String` |  |

### SendEvent

```ahk
SendEvent(Keys)
```

min params: 1, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Keys` | In | `String` |  |

### SendInput

```ahk
SendInput(Keys)
```

min params: 1, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Keys` | In | `String` |  |

### SendLevel

```ahk
SendLevel(Level)  -> Int32
```

min params: 1, max params: 1; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Level` | In | `Int32` |  |

### SendMessage

```ahk
SendMessage(Msg, [, wParam], [, lParam], [, Control], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText], [, Timeout])  -> UIntPtr
```

min params: 1, max params: 9; returns: `UIntPtr`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Msg` | In | `UInt32` |  |
| `wParam` | In_Opt | `Variant` | yes |
| `lParam` | In_Opt | `Variant` | yes |
| `Control` | In_Opt | `Variant` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |
| `Timeout` | In_Opt | `Int32` | yes |

### SendMode

```ahk
SendMode(Mode)  -> Variant
```

min params: 1, max params: 1; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In | `String` |  |

### SendPlay

```ahk
SendPlay(Keys)
```

min params: 1, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Keys` | In | `String` |  |

### SendText

```ahk
SendText(Text)
```

min params: 1, max params: 1; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Text` | In | `String` |  |

### SetCapsLockState

```ahk
SetCapsLockState([, State])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `State` | In_Opt | `String` | yes |

### SetControlDelay

```ahk
SetControlDelay(Delay)  -> Int32
```

min params: 1, max params: 1; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Delay` | In | `Int32` |  |

### SetDefaultMouseSpeed

```ahk
SetDefaultMouseSpeed(Speed)  -> Int32
```

min params: 1, max params: 1; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Speed` | In | `Int32` |  |

### SetKeyDelay

```ahk
SetKeyDelay([, Delay], [, Duration], [, Mode])
```

min params: 0, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Delay` | In_Opt | `Int32` | yes |
| `Duration` | In_Opt | `Int32` | yes |
| `Mode` | In_Opt | `String` | yes |

### SetMouseDelay

```ahk
SetMouseDelay(Delay, [, Mode])  -> Int32
```

min params: 1, max params: 2; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Delay` | In | `Int32` |  |
| `Mode` | In_Opt | `String` | yes |

### SetNumLockState

```ahk
SetNumLockState([, State])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `State` | In_Opt | `String` | yes |

### SetRegView

```ahk
SetRegView(RegView)  -> Variant
```

min params: 1, max params: 1; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `RegView` | In | `String` |  |

### SetScrollLockState

```ahk
SetScrollLockState([, State])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `State` | In_Opt | `String` | yes |

### SetStoreCapsLockMode

```ahk
SetStoreCapsLockMode(Mode)  -> Bool32
```

min params: 1, max params: 1; returns: `Bool32`; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In | `Bool32` |  |

### SetTimer

```ahk
SetTimer([, Function], [, Period], [, Priority])
```

min params: 0, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Function` | In_Opt | `Object` | yes |
| `Period` | In_Opt | `Int64` | yes |
| `Priority` | In_Opt | `Int32` | yes |

### SetTitleMatchMode

```ahk
SetTitleMatchMode(Mode)  -> Variant
```

min params: 1, max params: 1; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In | `String` |  |

### SetWinDelay

```ahk
SetWinDelay(Delay)  -> Int32
```

min params: 1, max params: 1; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Delay` | In | `Int32` |  |

### SetWorkingDir

```ahk
SetWorkingDir(Path)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |

### Shutdown

```ahk
Shutdown(Flags)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Flags` | In | `Int32` |  |

### Sin

```ahk
Sin(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Sleep

```ahk
Sleep(Delay)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Delay` | In | `Int32` |  |

### Sort

```ahk
Sort(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SoundBeep

```ahk
SoundBeep([, Duration], [, Frequency])
```

min params: 0, max params: 2; statement form (returns the previous setting).

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Duration` | In_Opt | `Int32` | yes |
| `Frequency` | In_Opt | `Int32` | yes |

### SoundGetInterface

```ahk
SoundGetInterface(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SoundGetMute

```ahk
SoundGetMute(<0 to 2 arguments>)
```

min params: 0, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SoundGetName

```ahk
SoundGetName(<0 to 2 arguments>)
```

min params: 0, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SoundGetVolume

```ahk
SoundGetVolume(<0 to 2 arguments>)
```

min params: 0, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SoundPlay

```ahk
SoundPlay(Path, [, Wait])
```

min params: 1, max params: 2.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |
| `Wait` | In_Opt | `String` | yes |

### SoundSetMute

```ahk
SoundSetMute(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SoundSetVolume

```ahk
SoundSetVolume(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SplitPath

```ahk
SplitPath(Path, [, Name], [, Dir], [, Ext], [, NameNoExt], [, Drive])
```

min params: 1, max params: 6.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Path` | In | `String` |  |
| `Name` | Out_Opt | `String` | yes |
| `Dir` | Out_Opt | `String` | yes |
| `Ext` | Out_Opt | `String` | yes |
| `NameNoExt` | Out_Opt | `String` | yes |
| `Drive` | Out_Opt | `String` | yes |

### Sqrt

```ahk
Sqrt(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StatusBarGetText

```ahk
StatusBarGetText([, Part], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 5; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Part` | In_Opt | `Int32` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### StatusBarWait

```ahk
StatusBarWait([, Text], [, Timeout], [, Part], [, WinTitle], [, WinText], [, Interval], [, ExcludeTitle], [, ExcludeText])  -> Bool32
```

min params: 0, max params: 8; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Text` | In_Opt | `String` | yes |
| `Timeout` | In_Opt | `Float64` | yes |
| `Part` | In_Opt | `Int32` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Interval` | In_Opt | `Int32` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### StrCompare

```ahk
StrCompare(<2 to 3 arguments>)
```

min params: 2, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrGet

```ahk
StrGet(<1 to 3 arguments>)
```

min params: 1, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrLen

```ahk
StrLen(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrLower

```ahk
StrLower(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrPtr

```ahk
StrPtr(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrPut

```ahk
StrPut(<1 to 4 arguments>)
```

min params: 1, max params: 4.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrReplace

```ahk
StrReplace(Haystack, Needle, [, ReplaceText], [, CaseSense], [, Count], [, Limit])  -> Variant
```

min params: 2, max params: 6; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Haystack` | In | `Variant` |  |
| `Needle` | In | `String` |  |
| `ReplaceText` | In_Opt | `String` | yes |
| `CaseSense` | In_Opt | `Variant` | yes |
| `Count` | Out_Opt | `UInt32` | yes |
| `Limit` | In_Opt | `UInt32` | yes |

### StrSplit

```ahk
StrSplit(String, [, Delimiters], [, OmitChars], [, MaxParts])  -> Object
```

min params: 1, max params: 4; returns: `Object`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `String` | In | `String` |  |
| `Delimiters` | In_Opt | `Variant` | yes |
| `OmitChars` | In_Opt | `String` | yes |
| `MaxParts` | In_Opt | `Int32` | yes |

### StrTitle

```ahk
StrTitle(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### StrUpper

```ahk
StrUpper(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### SubStr

```ahk
SubStr(<2 to 3 arguments>)
```

min params: 2, max params: 3.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Suspend

```ahk
Suspend([, Mode])
```

min params: 0, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Mode` | In_Opt | `Int32` | yes |

### SysGet

```ahk
SysGet(Index)
```

min params: 1, max params: 1.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Index` | In | `Int32` |  |

### SysGetIPAddresses

```ahk
SysGetIPAddresses()  -> Object
```

min params: 0, max params: 0; returns: `Object`.

## T

### Tan

```ahk
Tan(<1 argument(s)>)
```

min params: 1, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Thread

```ahk
Thread(Command, [, Value1], [, Value2])
```

min params: 1, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Command` | In | `String` |  |
| `Value1` | In_Opt | `Int32` | yes |
| `Value2` | In_Opt | `Int32` | yes |

### Throw

```ahk
Throw(<0 or more arguments>)
```

min params: 0, max params: 0; variadic (accepts a variable number of arguments).

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### ToolTip

```ahk
ToolTip([, Text], [, X], [, Y], [, Index])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Text` | In_Opt | `String` | yes |
| `X` | In_Opt | `Int32` | yes |
| `Y` | In_Opt | `Int32` | yes |
| `Index` | In_Opt | `Int32` | yes |

### TraySetIcon

```ahk
TraySetIcon([, File], [, Number], [, Freeze])
```

min params: 0, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `File` | In_Opt | `String` | yes |
| `Number` | In_Opt | `Int32` | yes |
| `Freeze` | In_Opt | `Bool32` | yes |

### TrayTip

```ahk
TrayTip([, Text], [, Title], [, Options])
```

min params: 0, max params: 3.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Text` | In_Opt | `String` | yes |
| `Title` | In_Opt | `String` | yes |
| `Options` | In_Opt | `String` | yes |

### Trim

```ahk
Trim(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### Type

```ahk
Type(<0 to 1 arguments>)
```

min params: 0, max params: 1.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## V

### VarSetStrCapacity

```ahk
VarSetStrCapacity(<1 to 2 arguments>)
```

min params: 1, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### VerCompare

```ahk
VerCompare(<2 argument(s)>)
```

min params: 2, max params: 2.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

## W

### WinActivate

```ahk
WinActivate([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinActivateBottom

```ahk
WinActivateBottom([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinActive

```ahk
WinActive(<0 to 4 arguments>)
```

min params: 0, max params: 4.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### WinClose

```ahk
WinClose([, WinTitle], [, WinText], [, WaitTime], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `WaitTime` | In_Opt | `Float64` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinExist

```ahk
WinExist(<0 to 4 arguments>)
```

min params: 0, max params: 4.

Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name
and an arity only, and the implementation takes positional arguments, so
**this source tree declares no parameter names for it**. Upstream is
migrating built-ins to the ``md_func`` form; until this one is migrated
there are no names to publish, and none are invented here.

### WinGetAlwaysOnTop

```ahk
WinGetAlwaysOnTop([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Bool32
```

min params: 0, max params: 4; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetClass

```ahk
WinGetClass([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetClientPos

```ahk
WinGetClientPos([, X], [, Y], [, Width], [, Height], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 8.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Int32` | yes |
| `Y` | Out_Opt | `Int32` | yes |
| `Width` | Out_Opt | `Int32` | yes |
| `Height` | Out_Opt | `Int32` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetControls

```ahk
WinGetControls([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Object
```

min params: 0, max params: 4; returns: `Object`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetControlsHwnd

```ahk
WinGetControlsHwnd([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Object
```

min params: 0, max params: 4; returns: `Object`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetCount

```ahk
WinGetCount([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Int32
```

min params: 0, max params: 4; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetEnabled

```ahk
WinGetEnabled([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Bool32
```

min params: 0, max params: 4; returns: `Bool32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetExStyle

```ahk
WinGetExStyle([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetID

```ahk
WinGetID([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetIDLast

```ahk
WinGetIDLast([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetList

```ahk
WinGetList([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Object
```

min params: 0, max params: 4; returns: `Object`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetMinMax

```ahk
WinGetMinMax([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Int32
```

min params: 0, max params: 4; returns: `Int32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetPID

```ahk
WinGetPID([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetPos

```ahk
WinGetPos([, X], [, Y], [, Width], [, Height], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 8.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | Out_Opt | `Int32` | yes |
| `Y` | Out_Opt | `Int32` | yes |
| `Width` | Out_Opt | `Int32` | yes |
| `Height` | Out_Opt | `Int32` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetProcessName

```ahk
WinGetProcessName([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetProcessPath

```ahk
WinGetProcessPath([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetStyle

```ahk
WinGetStyle([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 4; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetText

```ahk
WinGetText([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetTitle

```ahk
WinGetTitle([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetTransColor

```ahk
WinGetTransColor([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> String
```

min params: 0, max params: 4; returns: `String`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinGetTransparent

```ahk
WinGetTransparent([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])  -> Variant
```

min params: 0, max params: 4; returns: `Variant`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinHide

```ahk
WinHide([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinKill

```ahk
WinKill([, WinTitle], [, WinText], [, WaitTime], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `WaitTime` | In_Opt | `Float64` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinMaximize

```ahk
WinMaximize([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinMinimize

```ahk
WinMinimize([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinMinimizeAll

```ahk
WinMinimizeAll()
```

min params: 0, max params: 0; statement form (returns the previous setting).

### WinMinimizeAllUndo

```ahk
WinMinimizeAllUndo()
```

min params: 0, max params: 0; statement form (returns the previous setting).

### WinMove

```ahk
WinMove([, X], [, Y], [, Width], [, Height], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 8.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `X` | In_Opt | `Int32` | yes |
| `Y` | In_Opt | `Int32` | yes |
| `Width` | In_Opt | `Int32` | yes |
| `Height` | In_Opt | `Int32` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinMoveBottom

```ahk
WinMoveBottom([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinMoveTop

```ahk
WinMoveTop([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinRedraw

```ahk
WinRedraw([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinRestore

```ahk
WinRestore([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetAlwaysOnTop

```ahk
WinSetAlwaysOnTop([, Value], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In_Opt | `Int32` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetEnabled

```ahk
WinSetEnabled(Value, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `Int32` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetExStyle

```ahk
WinSetExStyle(Style, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Style` | In | `String` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetRegion

```ahk
WinSetRegion([, Options], [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Options` | In_Opt | `String` | yes |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetStyle

```ahk
WinSetStyle(Style, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Style` | In | `String` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetTitle

```ahk
WinSetTitle(NewTitle, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `NewTitle` | In | `String` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetTransColor

```ahk
WinSetTransColor(Value, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `Variant` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinSetTransparent

```ahk
WinSetTransparent(Value, [, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 1, max params: 5.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `Value` | In | `String` |  |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinShow

```ahk
WinShow([, WinTitle], [, WinText], [, ExcludeTitle], [, ExcludeText])
```

min params: 0, max params: 4.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinWait

```ahk
WinWait([, WinTitle], [, WinText], [, Timeout], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Timeout` | In_Opt | `Float64` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinWaitActive

```ahk
WinWaitActive([, WinTitle], [, WinText], [, Timeout], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Timeout` | In_Opt | `Float64` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinWaitClose

```ahk
WinWaitClose([, WinTitle], [, WinText], [, Timeout], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Timeout` | In_Opt | `Float64` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

### WinWaitNotActive

```ahk
WinWaitNotActive([, WinTitle], [, WinText], [, Timeout], [, ExcludeTitle], [, ExcludeText])  -> UInt32
```

min params: 0, max params: 5; returns: `UInt32`.

| Param | Direction | Type | Optional |
| --- | --- | --- | --- |
| `WinTitle` | In_Opt | `Variant` | yes |
| `WinText` | In_Opt | `String` | yes |
| `Timeout` | In_Opt | `Float64` | yes |
| `ExcludeTitle` | In_Opt | `String` | yes |
| `ExcludeText` | In_Opt | `String` | yes |

