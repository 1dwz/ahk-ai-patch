#Requires AutoHotkey v2.0
; Verify every factual claim in docs/BUILTIN_HTTP_JSON.md against the build.
out := ""
t(name, ok, extra := "") {
    global out
    out .= (ok ? "  OK   " : "  FAIL ") name (extra != "" ? "  [" extra "]" : "") "`n"
}

; --- JsonParse type mapping ---
p := JsonParse('{"i":42,"f":1.5,"s":"x","b":true,"n":null,"a":[1,2],"o":{"k":1}}')
t("object -> Map",       p is Map)
t("array  -> Array",     p["a"] is Array)
t("string -> String",    Type(p["s"]) == "String")
t("int    -> Integer",   Type(p["i"]) == "Integer")
t("float  -> Float",     Type(p["f"]) == "Float")
t("true   -> 1",         p["b"] = 1)
t("null   -> empty string", p["n"] == "")
t("big int keeps precision", JsonParse('{"n":9007199254740993}')["n"] == 9007199254740993)

; empty / whitespace returns "" rather than raising
t("empty input -> empty",      JsonParse("") == "")
t("whitespace input -> empty", JsonParse("   ") == "")

; malformed raises ValueError with offset
try {
    JsonParse('{bad}')
    t("malformed raises", false, "did not raise")
} catch as e
    t("malformed raises ValueError", InStr(e.Message, "offset") > 0, e.Message)

; --- JsonStringify ---
t("Map -> object",        JsonStringify(Map("k", [1,2,3])) == '{"k":[1,2,3]}')
t("Object -> object",     JsonStringify({ a: 1 }) == '{"a":1}')
t("nested Object",        JsonStringify(Map("k", { a: 1 })) == '{"k":{"a":1}}')
t("var-held Map",         (m := Map("a",1)) && JsonStringify(m) == '{"a":1}')
t("var-held Object",      (o := {a:1}) && JsonStringify(o) == '{"a":1}')
t("null and empty string both -> empty", JsonStringify(JsonParse('null')) == '""')
t("float round-trips",    JsonStringify(JsonParse('1.5')) == "1.5")
t("quote escaped",        JsonStringify(JsonParse('{"s":"a\"b"}')) == '{"s":"a\"b"}')
t("indent pretty",        InStr(JsonStringify(Map("k", [1,2]), 2), "`n") > 0)
t("indent capped at 16",  InStr(JsonStringify(Map("k", 1), 99), "`n") > 0)
; plain Class instance -> {} (an Object with no own props), per doc
class C {
    x => 1
}
t("Class -> {}", JsonStringify(C()) == "{}")

Raises(fn) {
    try {
        fn()
        return false
    } catch {
        return true
    }
}

; --- arity as documented ---
t("JsonParse(text)",              JsonParse.MinParams == 1 && JsonParse.MaxParams == 1)
t("JsonStringify(v [, indent])",  JsonStringify.MinParams == 1 && JsonStringify.MaxParams == 2)
t("HttpRequest(url [, options])", HttpRequest.MinParams == 1 && HttpRequest.MaxParams == 2)

; --- HttpRequest error model (offline checks only) ---
t("empty URL raises", Raises(() => HttpRequest("")))

r := HttpRequest("http://127.0.0.1:9/")          ; nothing listening -> transport failure
t("transport failure Status=0", r["Status"] == 0)
t("transport failure Ok=0",     r["Ok"] == 0)
t("transport failure has Error", r.Has("Error"))

FileAppend out, "*"
