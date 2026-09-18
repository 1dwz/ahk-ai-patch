#requires -Version 5.1
<#
Test the built-in JSON and HTTP functions added by this patch set.

JSON tests are fully offline and always run.
HTTP tests need network access; pass -SkipHttp to run JSON only, or
-SkipOffline if you only care about the HTTP path.

Usage:
  pwsh -NoProfile -File tools/test-json-http.ps1
  pwsh -NoProfile -File tools/test-json-http.ps1 -Exe dist\AutoHotkey64.exe
  pwsh -NoProfile -File tools/test-json-http.ps1 -SkipHttp
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Exe,
    [int]$TimeoutMs = 60000,
    [switch]$SkipHttp
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

if (-not $Exe) {
    foreach ($c in @(
        (Join-Path $RepoRoot 'dist\AutoHotkey64.exe'),
        (Join-Path $RepoRoot 'upstream\bin\AutoHotkey64.exe'),
        'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
    )) { if (Test-Path $c) { $Exe = $c; break } }
}
if (-not $Exe -or -not (Test-Path $Exe)) { throw "AutoHotkey64.exe not found. Pass -Exe <path>." }
$Exe = (Resolve-Path $Exe).Path
Write-Output "Testing: $Exe"
Write-Output ''

$enc = New-Object System.Text.UTF8Encoding($false)
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-jh-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null

# Every assertion appends a line; the script exits non-zero on any failure so
# the CI "verify" job fails loudly.
$json = @'
#Requires AutoHotkey v2.0
fails := 0
ok(cond, name, extra := "") {
    global fails
    if (!cond) {
        fails += 1
        FileAppend "  FAIL " name (extra != "" ? "  [" extra "]" : "") "`n", "*"
    } else
        FileAppend "  ok   " name "`n", "*"
}

; ---- parse basics ----
o := JsonParse('{"a":1,"b":"two","c":true,"d":false,"e":null,"f":3.5,"g":[1,2,3]}')
ok(Type(o) == "Map", "object becomes Map", Type(o))
ok(o["a"] == 1 && Type(o["a"]) == "Integer", "integer stays Integer")
ok(o["b"] == "two", "string")
ok(o["c"] == 1 && o["d"] == 0, "true/false map to 1/0")
ok(o["e"] == "", "null becomes empty string", "[" o["e"] "]")
ok(o["f"] == 3.5 && Type(o["f"]) == "Float", "float stays Float")
ok(Type(o["g"]) == "Array" && o["g"].Length == 3 && o["g"][2] == 2, "array")

; ---- big integers keep precision ----
big := JsonParse('{"n":9007199254740993}')
ok(Type(big["n"]) == "Integer" && big["n"] == 9007199254740993, "int64 precision kept")
huge := JsonParse('{"n":1e400}')
ok(Type(huge["n"]) == "Float", "overflow becomes Float")

; ---- string escapes and unicode ----
s := JsonParse('"tab\there\nnew"')
ok(StrLen(s) == 12 && InStr(s, "`t") && InStr(s, "`n"), "escapes decoded", StrLen(s))
u := JsonParse('"\u4e2d\u6587"')
ok(StrLen(u) == 2 && Ord(u) == 0x4E2D, "BMP unicode", Format("{:04X}", Ord(u)))
sp := JsonParse('"\uD83D\uDE00"')
ok(StrLen(sp) == 2 && Ord(sp) == 0x1F600, "surrogate pair combined", Format("{:X}", Ord(sp)))
q := JsonParse('"a\\b\"c"')
ok(q == 'a\b"c', "backslash and quote escapes")

; ---- empty and nested ----
ok(JsonParse("") == "", "empty input yields empty string")
nested := JsonParse('{"x":{"y":{"z":[1,{"w":"deep"}]}}}')
ok(nested["x"]["y"]["z"][2]["w"] == "deep", "deep nesting")

; ---- round trip ----
; Regression: JsonStringify must work on a Map that JsonParse produced, not
; just on one built by Map(). An earlier revision leaked the enumerator's
; reference and lost every key after the first, so this exact shape (a parsed
; map with several keys) is asserted directly.
rt := JsonParse('{"k":[1,"two",3.5,true,null],"m":{"a":1}}')
ok(Type(rt["k"]) == "Array" && rt["k"][2] == "two", "round trip keeps structure")
ok(JsonStringify(rt) != "", "round trip produces text")
parsed3 := JsonParse('{"a":1,"b":2,"c":3}')
ok(JsonStringify(parsed3) == "{" Chr(34) "a" Chr(34) ":1," Chr(34) "b" Chr(34) ":2," Chr(34) "c" Chr(34) ":3}"
    , "stringify a parsed multi-key map via a variable", JsonStringify(parsed3))
; A variable-held object arrives as SYM_VAR, not SYM_OBJECT, so stringifying
; through a variable is a distinct code path from inline use.
mv := Map("a", 1, "b", 2, "c", 3)
ok(JsonStringify(mv) == JsonStringify(Map("a", 1, "b", 2, "c", 3)), "stringify a variable-held Map")
av := [1, 2, 3]
ok(JsonStringify(av) == "[1,2,3]", "stringify a variable-held Array")
ok(InStr(JsonStringify(parsed3, 2), Chr(34) "c" Chr(34)), "pretty print a variable-held map")
parsed8 := JsonParse('{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8}')
ok(InStr(JsonStringify(parsed8), Chr(34) "h" Chr(34) ":8") , "stringify a parsed 8-key map")
ok(InStr(JsonStringify(JsonParse('{"a":{"b":{"c":[1,2,{"d":"x"}]}}}')), "x")
    , "stringify deeply nested parsed value")
ok(JsonStringify(JsonParse('{"x":1}'), 2) != "", "pretty print a parsed map")

; ---- stringify basics ----
mapOut := JsonStringify(Map("a", 1))
ok(mapOut == "{" Chr(34) "a" Chr(34) ":1}", "stringify map", mapOut)
ok(JsonStringify([1, 2, 3]) == "[1,2,3]", "stringify array")
numOut := JsonStringify(Map("n", 1))
ok(numOut == "{" Chr(34) "n" Chr(34) ":1}", "stringify number", numOut)
; a quote inside a string must come back escaped as backslash + quote
qout := JsonStringify(Chr(34) "a" Chr(34))
qq := Chr(92) . Chr(34)
ok(qout == Chr(34) qq "a" qq Chr(34), "stringify escapes quotes", qout)
pf := JsonStringify(Map("x", [1, 2]), 2)
ok(InStr(pf, "`n") && InStr(pf, "  "), "pretty print indents")

; ---- malformed input must raise, not silently succeed ----
bad := ["{", "[1,", '{"a"}', '{"a":}', "tru", '{"a":1,}', "01", "+1"]
for i, src in bad {
    try {
        JsonParse(src)
        ok(false, "malformed raises #" i, src)
    } catch as e {
        ok(Type(e) == "ValueError", "malformed raises #" i, src)
    }
}

FileAppend (fails = 0 ? "JSON: ALL PASSED`n" : "JSON: " fails " FAILED`n"), "*"
ExitApp(fails = 0 ? 0 : 1)
'@

$http = @'
#Requires AutoHotkey v2.0
fails := 0
ok(cond, name, extra := "") {
    global fails
    if (!cond) {
        fails += 1
        FileAppend "  FAIL " name (extra != "" ? "  [" extra "]" : "") "`n", "*"
    } else
        FileAppend "  ok   " name "`n", "*"
}
Base := "https://httpbin.org"

; ---- GET ----
try {
    r := HttpRequest(Base "/get?probe=42")
    ok(r.Has("Status") && r["Status"] == 200, "GET status 200", r["Status"])
    ok(r["Ok"] == 1, "GET ok flag")
    ok(r["BodyBytes"] > 0, "GET has body bytes")
    ok(Type(r["Headers"]) == "Map", "headers is a Map")
    ok(r["Headers"].Has("content-type"), "content-type header present")
    j := JsonParse(r["Body"])
    ok(InStr(j["url"], "probe=42"), "query string echoed")
    ok(j["headers"]["Host"] == "httpbin.org", "host header")
    ok(r["Url"] != "", "final url reported")
} catch as e {
    ok(false, "GET", e.Message)
}

; ---- POST with a JSON body ----
try {
    body := '{"hello":"world"}'
    r := HttpRequest(Base "/anything", { Method: "POST", Body: body, ContentType: "application/json" })
    ok(r["Status"] == 200, "POST status", r["Status"])
    j := JsonParse(r["Body"])
    ok(j["method"] == "POST", "POST verb reached server", j["method"])
    ok(j["data"] == body, "POST body reached server", j["data"])
    ok(j["headers"]["Content-Type"] == "application/json", "content-type sent")
} catch as e {
    ok(false, "POST", e.Message)
}

; ---- other verbs ----
for verb in ["PUT", "PATCH", "DELETE"] {
    try {
        r := HttpRequest(Base "/anything", { Method: verb, Body: "payload" })
        j := JsonParse(r["Body"])
        ok(j["method"] == verb, verb " verb reached server", j["method"])
    } catch as e {
        ok(false, verb, e.Message)
    }
}

; ---- custom headers (Map form) ----
try {
    r := HttpRequest(Base "/headers", { Headers: Map("X-Probe", "alpha", "X-Other", "beta") })
    j := JsonParse(r["Body"])
    ok(j["headers"]["X-Probe"] == "alpha", "custom header 1")
    ok(j["headers"]["X-Other"] == "beta", "custom header 2")
} catch as e {
    ok(false, "custom headers", e.Message)
}

; ---- body implies POST ----
try {
    r := HttpRequest(Base "/anything", { Body: "implicit" })
    j := JsonParse(r["Body"])
    ok(j["method"] == "POST", "body alone implies POST", j["method"])
} catch as e {
    ok(false, "implicit POST", e.Message)
}

; ---- HTTP error status is not a transport error ----
try {
    r := HttpRequest(Base "/status/404")
    ok(r["Status"] == 404, "404 status reported", r["Status"])
    ok(r["Ok"] == 0, "404 is not ok")
    ok(!r.Has("Error"), "404 has no transport Error")
} catch as e {
    ok(false, "404", e.Message)
}

; ---- redirects ----
try {
    r := HttpRequest(Base "/redirect/1")
    ok(r["Status"] == 200, "follows redirect by default", r["Status"])
    r2 := HttpRequest(Base "/redirect/1", { FollowRedirects: false })
    ok(r2["Status"] >= 300 && r2["Status"] < 400, "FollowRedirects:false keeps 3xx", r2["Status"])
} catch as e {
    ok(false, "redirect", e.Message)
}

; ---- HEAD ----
try {
    r := HttpRequest(Base "/get", { Method: "HEAD" })
    ok(r["Status"] == 200, "HEAD status", r["Status"])
    ok(r["Body"] == "", "HEAD has no body")
} catch as e {
    ok(false, "HEAD", e.Message)
}

; ---- transport failure reports Error, not an exception ----
try {
    r := HttpRequest("http://127.0.0.1:9/nothing", { Timeout: 3, ConnectTimeout: 2 })
    ok(r["Status"] == 0, "unreachable host gives status 0", r["Status"])
    ok(r.Has("Error"), "unreachable host sets Error")
    ok(r["Ok"] == 0, "unreachable host is not ok")
} catch as e {
    ok(false, "transport failure", e.Message)
}

; ---- JSON + HTTP together ----
try {
    r := HttpRequest(Base "/post", { Method: "POST", Body: JsonStringify(Map("k", [1, 2, 3])), ContentType: "application/json" })
    j := JsonParse(r["Body"])
    ok(JsonStringify(j["json"]) == '{"k":[1,2,3]}', "round trip through a server")
} catch as e {
    ok(false, "json+http round trip", e.Message)
}

FileAppend (fails = 0 ? "HTTP: ALL PASSED`n" : "HTTP: " fails " FAILED`n"), "*"
ExitApp(fails = 0 ? 0 : 1)
'@

$fail = 0

function Run-Case([string]$name, [string]$src, [int]$timeout) {
    $p = Join-Path $work ("$name.ahk")
    [System.IO.File]::WriteAllText($p, $src, $enc)
    $r = Invoke-AhkAi -Exe $Exe -Arguments @('/AI', $p) -TimeoutMs $timeout -WorkingDirectory $work
    Write-Output "--- $name ---"
    if ($r.Blocked) {
        Write-Output "  FAIL blocked (a dialog appeared)"
        $script:fail++
        return
    }
    foreach ($line in ($r.StdOut -split "`r?`n")) {
        if ($line.Trim()) { Write-Output ("  " + $line.TrimEnd()) }
    }
    if ($r.StdErr.Trim()) {
        foreach ($line in ($r.StdErr -split "`r?`n")) {
            if ($line.Trim()) { Write-Output ("  stderr: " + $line.TrimEnd()) }
        }
    }
    if ($r.ExitCode -ne 0) { $script:fail++ }
    Write-Output ("  exit=$($r.ExitCode)")
    Write-Output ''
}

Run-Case 'json' $json 60000
if (-not $SkipHttp) { Run-Case 'http' $http $TimeoutMs }

Remove-Item $work -Recurse -Force -EA SilentlyContinue

Write-Output ''
if ($fail) { Write-Output "$fail suite(s) FAILED"; exit 1 }
Write-Output 'JSON/HTTP suites PASSED.'
exit 0
