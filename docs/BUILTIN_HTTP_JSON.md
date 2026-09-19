# Built-in HTTP and JSON

This patch set adds three built-in functions to AutoHotkey v2:

| Function | Purpose |
| --- | --- |
| `JsonParse(text)` | Parse a JSON document into AHK values |
| `JsonStringify(value [, indent])` | Serialize AHK values to JSON text |
| `HttpRequest(url [, options])` | Perform an HTTP request via libcurl |

They are `BIF`s, so they are always available — no `#Include`, no
`lib/` script, and no `LoadLibrary` in user code.

> This file documents only the three functions this patch set adds. For every
> other built-in function in this build — all 357 of them — see the generated
> index, `BUILTIN_API.md` (shipped beside the interpreter) or
> `docs/api/RUNTIME_API.md` in the repository, both produced from the
> interpreter itself by `AutoHotkey64.exe /dump-api`.

Every option below was verified against the built interpreter; where behaviour
is surprising it is called out rather than glossed over.

---

## JsonParse

```ahk
obj := JsonParse(text)
```

Parses `text` and returns AHK values. Type mapping is deliberate and
lossless where AHK allows it:

| JSON | AHK v2 | Note |
| --- | --- | --- |
| object | `Map` | |
| array | `Array` | |
| string | `String` | escapes and `\uXXXX` decoded |
| number | `Integer` | when it fits in Int64, so ids/timestamps keep precision |
| number | `Float` | when it does not fit, or has `.`/`e` |
| `true` / `false` | `1` / `0` | AHK v2 has no boolean type; these are what `true`/`false` evaluate to |
| `null` | `""` | AHK v2 has no `undefined`; `""` is how AHK already means "no value" |

**`null` is lossy.** JSON `null` and JSON `""` both become `""`, and
`JsonStringify` writes `""` for either. If you must distinguish them, encode
the distinction in your own schema (for example a `{"has": false}` flag).

An empty or whitespace-only input returns `""` rather than raising.

Malformed input **raises a `ValueError`** naming the offset, so a bad payload
surfaces as a real error instead of a silent empty result:

```ahk
try
    obj := JsonParse("{bad}")
catch as e
    MsgBox e.Message        ; JsonParse: expected a string key (at offset 1)
```

Rejected by the strict grammar (RFC 8259): trailing commas, unquoted keys,
leading zeros (`01`), `+1`, single quotes, comments, and trailing garbage
after a complete value.

Nesting is limited to 512 levels, so a hostile document cannot exhaust the
stack.

## JsonStringify

```ahk
text := JsonStringify(value [, indent])
```

Serializes `Map`, `Object`, `Array`, `String`, `Integer` and `Float`. `indent`
greater than 0 pretty-prints with that many spaces per level (capped at 16); `0`
or omitted produces compact output.

`Float` is written with `%.17g`, which round-trips an IEEE double exactly.
Quotes, backslashes, and control characters are escaped; a `"` inside a string
becomes `\"`.

`Map` and `Object` both become JSON objects and `Array` becomes a JSON array, at
any nesting depth:

```ahk
JsonStringify(Map("k", [1, 2, 3]))        ; {"k":[1,2,3]}
JsonStringify({ a: 1 })                    ; {"a":1}
JsonStringify(Map("k", { a: 1 }))          ; {"k":{"a":1}}
JsonStringify(Map("k", [1, 2]), 2)         ; pretty
```

A value held in a variable serializes identically to an inline literal, for
both `Map` and `Object`.

Any other object is treated as a JSON object with no enumerable own properties.
A custom `Class` instance therefore serializes to `{}`, not to a string, and a
COM object serializes to `""`:

```ahk
class C {
    x => 1
}
JsonStringify(C())                       ; {}      (a class instance is an Object)
JsonStringify(ComObject("Scripting.Dictionary"))   ; ""
```

Neither is a useful representation; convert to a `Map` first if you need the
contents serialized.

> A plain `Object` is **not** enumerable by the language itself — `for k, v in
> o` raises `Value not enumerable` for an `Object`, unlike a `Map` or `Array`.
> `JsonStringify` handles this internally via `OwnProps()`. If you walk an
> object yourself, use `o.OwnProps()`.

---

## HttpRequest

```ahk
resp := HttpRequest(url [, options])
```

Performs a blocking HTTP request and returns a `Map`.

### options

An options bag may be given either as an object literal `{ ... }` or as a
`Map(...)`. Keys are case-sensitive.

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `Method` | String | `"GET"` | `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, or any verb |
| `Body` | String | — | request body; implies `POST` when `Method` is omitted |
| `Headers` | Map or Object | — | header name → value |
| `ContentType` | String | — | shorthand for the `Content-Type` header |
| `Timeout` | Integer | `30` | total time limit, seconds |
| `ConnectTimeout` | Integer | `10` | connection time limit, seconds |
| `FollowRedirects` | Boolean | `true` | follow 3xx |
| `MaxRedirects` | Integer | `10` | redirect limit |
| `UserAgent` | String | `"AutoHotkey/2.1 (ahk-ai)"` | |
| `Proxy` | String | — | e.g. `"http://127.0.0.1:8080"` |
| `Insecure` | Boolean | `false` | skip TLS verification (testing only) |
| `SaveTo` | String | — | write the body to this file instead of returning it |

`Headers` may also be an `Array` of `"Name: value"` strings, which are sent
verbatim.

### result

| Key | Type | Meaning |
| --- | --- | --- |
| `Status` | Integer | HTTP status; `0` on transport failure |
| `Ok` | Integer | `1` when `200 <= Status < 300` |
| `StatusText` | String | reason phrase (libcurl does not expose it, so usually `""`) |
| `Headers` | Map | lower-cased name → value; repeated names (`set-cookie`) become an `Array` |
| `Body` | String | response body, decoded from UTF-8 (omitted when `SaveTo` is used) |
| `BodyBytes` | Integer | body* **Malformed arguments** (empty URL): raises, because it is a programming
  error rather than a network condition.
* **libcurl could not initialise** (e.g. the Winsock stack is unavailable):nsport failure** (DNS failure, refused connection, timeout): the call
  **returns normally** with `Status = 0`, `Ok = 0`, and an `Error` string.
* **HTTP error status** (`404`, `500`, ...): `Status` holds the real code,
  `Ok = 0`, and there is **no** `Error`. A 404 is a successful exchange.
* **Malformed arguments** (empty URL): raises, because it is a programming
  error rather than a network condition.
* **Invalid arguments** (empty URL): raises, because it is a programming
  error rather than a network condition.
* **libcurl could not initialise** (e.g. the Winsock stack is unavailable):
  raises. This is the only failure that is neither a transport result nor a
  bad argument — it cannot happen on a working Windows install.

```ahk
resp := HttpRequest("https://example.com/api", {
    Method: "POST",
    Body: JsonStringify(Map("name", "test")),
    ContentType: "application/json"
})

if (resp.Has("Error"))
    MsgBox "network: " resp["Error"]
else if (!resp["Ok"])
    MsgBox "HTTP " resp["Status"]
else
    data := JsonParse(resp["Body"])
```

### TLS

libcurl is **linked statically** into `AutoHotkey64.exe` / `AutoHotkey32.exe`,
so there is nothing extra to ship: no `libcurl-x64.dll`, no
`curl-ca-bundle.crt`, no `#Include`.

TLS uses the **Schannel** backend, so certificates are validated against the
**Windows certificate store**. That is why no CA bundle is needed, and it also
means a corporate root CA installed system-wide is honoured automatically.

`Insecure: true` disables peer and host verification; it exists for testing
against self-signed endpoints and should not be used in shipped scripts. (To
trust one specific self-signed certificate properly, install it into the
Windows trust store instead.)

The interpreted build therefore imports only Windows DLLs — `ws2_32.dll`,
`iphlpapi.dll`, `secur32.dll`, `crypt32.dll`, `bcrypt.dll` — plus what
AutoHotkey already used.

The static import libraries live in `third_party/curl-static/`. To rebuild them
from curl source:

```powershell
pwsh -NoProfile -File tools/build-libcurl-static.ps1 -Platform both
```

Requests are blocking, so a long call stalls the script. Use a small `Timeout`
when that matters.

Bodies are decoded as UTF-8. Response bodies of other encodings come back as
replacement characters — decode them yourself via `SaveTo` and
`FileRead(..., "RAW")` if you need exact bytes.
