# Built-in function reference

Generated from `source/lib/functions.h`. Do not edit by hand --
regenerate with `pwsh -NoProfile -File tools/extract-api-docs.ps1`.

`In` = required, `In_Opt` = optional, `Out*` = by-reference output,
`Ret` = return value. Types are the native declarations, which map to AHK
v2 values as: `String` -> String, `Int32`/`Int64`/`UInt32`/`IntPtr` -> Integer,
`Float64` -> Float, `Variant` -> any, `Object` -> Object/Map/Array.

## A

### Abs

```ahk
Abs(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ACos

```ahk
ACos(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ASin

```ahk
ASin(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ATan

```ahk
ATan(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ATan2

```ahk
ATan2(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Ceil(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### Chr

```ahk
Chr(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### Click

```ahk
Click([, arg1], [, arg2], [, arg3], [, arg4], [, arg5], [, arg6])
```

min params: 0, max params: 6.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
ComCall()
```

min params: 2, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjActive

```ahk
ComObjActive(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjConnect

```ahk
ComObjConnect(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjFlags

```ahk
ComObjFlags(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjFromPtr

```ahk
ComObjFromPtr(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjGet

```ahk
ComObjGet(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjQuery

```ahk
ComObjQuery(arg1, arg2, [, arg3])
```

min params: 2, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjType

```ahk
ComObjType(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ComObjValue

```ahk
ComObjValue(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Cos(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
DefineProp(arg1, arg2, arg3)
```

min params: 3, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
DllCall()
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Exp(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
FileOpen(arg1, arg2, [, arg3])
```

min params: 2, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Floor(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### Format

```ahk
Format()
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### FormatTime

```ahk
FormatTime([, arg1], [, arg2])
```

min params: 0, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
GetMethod(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
HasBase(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### HasMethod

```ahk
HasMethod(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### HasProp

```ahk
HasProp(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
InStr(arg1, arg2, [, arg3], [, arg4], [, arg5])
```

min params: 2, max params: 5.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsAlnum

```ahk
IsAlnum(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsAlpha

```ahk
IsAlpha(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsDigit

```ahk
IsDigit(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsFloat

```ahk
IsFloat(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsInteger

```ahk
IsInteger(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
IsLower(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsNumber

```ahk
IsNumber(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsObject

```ahk
IsObject(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsSetRef

```ahk
IsSetRef(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsSpace

```ahk
IsSpace(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsTime

```ahk
IsTime(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsUpper

```ahk
IsUpper(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### IsXDigit

```ahk
IsXDigit(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Ln(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Log(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### LTrim

```ahk
LTrim(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

## M

### Max

```ahk
Max()
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Min()
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### Mod

```ahk
Mod(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
NumGet(arg1, arg2, [, arg3])
```

min params: 2, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### NumPut

```ahk
NumPut()
```

min params: 3, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

## O

### ObjAddRef

```ahk
ObjAddRef(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjBindMethod

```ahk
ObjBindMethod()
```

min params: 1, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjFromPtr

```ahk
ObjFromPtr(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjFromPtrAddRef

```ahk
ObjFromPtrAddRef(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjGetBase

```ahk
ObjGetBase(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjGetCapacity

```ahk
ObjGetCapacity(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
ObjHasOwnProp(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjOwnPropCount

```ahk
ObjOwnPropCount(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjOwnProps

```ahk
ObjOwnProps(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjPtr

```ahk
ObjPtr(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjPtrAddRef

```ahk
ObjPtrAddRef(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjRelease

```ahk
ObjRelease(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjSetBase

```ahk
ObjSetBase(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### ObjSetCapacity

```ahk
ObjSetCapacity(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Ord(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Props(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

## R

### Random

```ahk
Random([, arg1], [, arg2])
```

min params: 0, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### RegCreateKey

```ahk
RegCreateKey([, arg1])
```

min params: 0, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### RegDelete

```ahk
RegDelete([, arg1], [, arg2])
```

min params: 0, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### RegDeleteKey

```ahk
RegDeleteKey([, arg1])
```

min params: 0, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
RegRead([, arg1], [, arg2], [, arg3])
```

min params: 0, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### RegWrite

```ahk
RegWrite(arg1, [, arg2], [, arg3], [, arg4])
```

min params: 1, max params: 4.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### Reload

```ahk
Reload()
```

min params: 0, max params: 0.

### Round

```ahk
Round(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### RTrim

```ahk
RTrim(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Sin(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Sort(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
SoundGetInterface(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### SoundGetMute

```ahk
SoundGetMute([, arg1], [, arg2])
```

min params: 0, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### SoundGetName

```ahk
SoundGetName([, arg1], [, arg2])
```

min params: 0, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### SoundGetVolume

```ahk
SoundGetVolume([, arg1], [, arg2])
```

min params: 0, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
SoundSetMute(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### SoundSetVolume

```ahk
SoundSetVolume(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Sqrt(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
StrCompare(arg1, arg2, [, arg3])
```

min params: 2, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### StrGet

```ahk
StrGet(arg1, [, arg2], [, arg3])
```

min params: 1, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### StrLen

```ahk
StrLen(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### StrLower

```ahk
StrLower(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### StrPtr

```ahk
StrPtr(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### StrPut

```ahk
StrPut(arg1, [, arg2], [, arg3], [, arg4])
```

min params: 1, max params: 4.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
StrTitle(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### StrUpper

```ahk
StrUpper(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### SubStr

```ahk
SubStr(arg1, arg2, [, arg3])
```

min params: 2, max params: 3.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Tan(arg1)
```

min params: 1, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Throw()
```

min params: 0, max params: 0; variadic (accepts a variable number of arguments).

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
Trim(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### Type

```ahk
Type([, arg1])
```

min params: 0, max params: 1.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

## V

### VarSetStrCapacity

```ahk
VarSetStrCapacity(arg1, [, arg2])
```

min params: 1, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

### VerCompare

```ahk
VerCompare(arg1, arg2)
```

min params: 2, max params: 2.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
WinActive([, arg1], [, arg2], [, arg3], [, arg4])
```

min params: 0, max params: 4.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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
WinExist([, arg1], [, arg2], [, arg3], [, arg4])
```

min params: 0, max params: 4.

Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in
``functions.h``, so its parameter names are not available from source.
See the hand-written notes in the repository ``docs/`` for its options.

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

