#requires -Version 5.1
<#
Generate the built-in function reference from the AutoHotkey SOURCE tree.

Everything this script prints is read out of source files.  Nothing is inferred
from documentation, from the running binary, or from prior knowledge of what a
function "should" look like.

There are two declaration mechanisms in this upstream revision, and they are
DISJOINT -- 253 + 101 = the full 354 built-ins:

  1. source/lib/functions.h -- 253 entries, via
         md_func(ControlSend, (In, String, Keys), MD_CONTROL_ARGS_OPT)
     The macro carries direction, type and NAME for every parameter, plus the
     return type.  These entries get complete signatures.

  2. g_BIF[] in source/script.cpp -- 101 entries, via
         BIF1(InStr, 2, 5)
     FuncEntry holds only { name, impl, minParams, maxParams }.  The parameter
     names do not exist in this source tree: the implementations take positional
     arguments (BIF_DECL(BIF_InStr) { _f_param_string(haystack, 0, ...) } -- and
     `haystack` there is a local, not a parameter name).

     Upstream is migrating these from the old style to the new md_func/bif_impl
     style; the ones not yet migrated have no declared parameter names anywhere
     in the tree.  Verified by exhaustive search (functions.h, every bif_impl
     declaration, `// Name(...)` comments, and every file in the repository).

     This script therefore reports their ARITY -- which is real, from source --
     and states plainly that parameter names are not declared.  It does NOT
     invent `arg1, arg2, ...` placeholders, because a placeholder in a reference
     document is indistinguishable from a real name to a reader or an agent.

Every generated entry records which of the two sources it came from, so the
provenance of each signature is auditable.

AutoHotkey exposes MinParams / MaxParams / IsVariadic on every built-in function
object, so with -Verify the parsed arity is cross-checked against the running
interpreter.  A disagreement is an error, not a warning.

Usage:
  pwsh -NoProfile -File tools/extract-api-docs.ps1
  pwsh -NoProfile -File tools/extract-api-docs.ps1 -OutDir docs/api
  pwsh -NoProfile -File tools/extract-api-docs.ps1 -Summary dist/BUILTIN_API.md -Json dist/builtin-api.json
  pwsh -NoProfile -File tools/extract-api-docs.ps1 -Verify -Exe dist/AutoHotkey64.exe
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$UpstreamDir,
    [string]$OutDir,
    [string]$OutFile,
    [switch]$Json,
    [switch]$Verify,
    [string]$Exe,
    [string]$Summary
)

$ErrorActionPreference = 'Stop'

if (-not $UpstreamDir) { $UpstreamDir = Join-Path $RepoRoot 'upstream' }
$functionsH = Join-Path $UpstreamDir 'source\lib\functions.h'
if (-not (Test-Path $functionsH)) {
    throw "functions.h not found at $functionsH. Run tools/apply-patches.ps1 first."
}
$scriptCpp = Join-Path $UpstreamDir 'source\script.cpp'
if (-not (Test-Path $scriptCpp)) {
    throw "script.cpp not found at $scriptCpp. Run tools/apply-patches.ps1 first."
}

# --- read the source -------------------------------------------------------
# Normalise to LF so the same input produces the same output on any checkout,
# regardless of the line-ending policy in effect.
$raw = [System.IO.File]::ReadAllText($functionsH)
$text = $raw -replace "`r`n", "`n"
$lines = $text -split "`n"

# --- expand the MD_* argument-list aliases ---------------------------------
# functions.h starts with a few #define'd groups (MD_WINTITLE_ARGS and friends)
# that are spliced into many signatures. Expand them so each generated entry
# lists real parameters instead of an opaque macro name.
$aliases = @{}
foreach ($line in $lines) {
    if ($line -match '^\s*#define\s+(MD_[A-Z0-9_]+)\s+(.+?)\s*$') {
        $aliases[$Matches[1]] = $Matches[2]
    }
}
$aliasNote = ($aliases.Keys | Sort-Object) -join ', '

function Expand-AliasGroups([string]$s, [int]$depth = 0) {
    if ($depth -gt 8) { return $s }   # guard against a cyclic definition
    $changed = $false
    foreach ($k in $aliases.Keys) {
        if ($s -match "\b$([regex]::Escape($k))\b") {
            $s = $s -replace "\b$([regex]::Escape($k))\b", $aliases[$k]
            $changed = $true
        }
    }
    if ($changed) { return Expand-AliasGroups $s ($depth + 1) }
    return $s
}

# --- read the g_BIF registry from script.cpp -------------------------------
# Each row is BIF1(Name, minp, maxp) or BIFn(Name, minp, maxp, Impl) or
# BIFi(Name, minp, maxp, Impl, id, ...).  The two numbers are the interpreter's
# own MinParams/MaxParams; NA means variadic (MAX_FUNCTION_PARAMS).
# The macros (script.cpp) show exactly what is stored:
#     #define BIFn(name, minp, maxp, bif, ...) {_T(#name), bif, minp, maxp, FID_##name, __VA_ARGS__}
# i.e. name, impl, min, max -- no parameter names.
$gBif = @{}
$scriptText = ([System.IO.File]::ReadAllText($scriptCpp)) -replace "`r`n", "`n"
foreach ($m in [regex]::Matches($scriptText, '(?m)^\s*BIF[ni1]?\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*(\d+)\s*,\s*(\d+|NA)\s*')) {
    $gBif[$m.Groups[1].Value] = [pscustomobject]@{
        Min = [int]$m.Groups[2].Value
        Max = if ($m.Groups[3].Value -eq 'NA') { 0 } else { [int]$m.Groups[3].Value }
        Variadic = ($m.Groups[3].Value -eq 'NA')
    }
}

# --- parse the md_func* declarations --------------------------------------
# A declaration may wrap across physical lines (it is C, so line breaks are
# meaningless), and may be wrapped in #ifdef. Track the condition so that
# optionally-compiled entries can be flagged rather than silently included.
$entries = New-Object System.Collections.Generic.List[object]

# Split the text into declarations by scanning for `md_func` and then reading
# forward to the paren that balances the opening one. A regex lookahead is not
# good enough here: these declarations span multiple lines and their
# continuation lines start with `\t,`, which no line-based lookahead can see.
$decls = New-Object System.Collections.Generic.List[object]
$scan = [regex]'\bmd_func(?<variant>_[a-z]+)?\s*\('
foreach ($m in $scan.Matches($text)) {
    $start = $m.Index + $m.Length - 1   # index of the opening paren
    $depth = 0
    $end = -1
    for ($i = $start; $i -lt $text.Length; $i++) {
        $ch = $text[$i]
        if ($ch -eq '(') { $depth++ }
        elseif ($ch -eq ')') {
            $depth--
            if ($depth -eq 0) { $end = $i; break }
        }
    }
    if ($end -lt 0) { continue }
    $decls.Add([pscustomobject]@{
        Variant = $m.Groups['variant'].Value
        Body    = $text.Substring($start + 1, $end - $start - 1)
        Index   = $m.Index
    })
}

foreach ($d in $decls) {
    $variant = $d.Variant.TrimStart('_')
    if (-not $variant) { $variant = 'func' }
    $body = ($d.Body -replace "`r?`n", ' ') -replace '\s+', ' '
    $body = Expand-AliasGroups $body

    # First bare token is the script-visible name.
    if ($body -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:,\s*(.*))?$') { continue }
    $name = $Matches[1]
    $rest = if ($Matches.Count -gt 2) { $Matches[2] } else { '' }

    # Each parameter group is a parenthesised triple. Matching the groups
    # directly is far less error-prone than walking the string character by
    # character (an earlier version of this script silently split on the
    # parens themselves and produced empty parameter lists).
    $params = New-Object System.Collections.Generic.List[string]
    $retType = $null
    $retName = $null
    foreach ($g in [regex]::Matches($rest, '\(([^()]*)\)')) {
        $inner = ($g.Groups[1].Value -split '\s*,\s*') | Where-Object { $_ -ne '' }
        if ($inner.Count -lt 2) { continue }
        if ($inner[0] -eq 'Ret') {
            # A return declaration, not a parameter: record it but keep it out
            # of the parameter list and out of the arity count.
            $retType = $inner[1]
            if ($inner.Count -ge 3) { $retName = $inner[2] }
            continue
        }
        $params.Add(($inner -join ','))
    }

    $parsed = New-Object System.Collections.Generic.List[object]
    foreach ($p in $params) {
        $parts = $p -split ','
        if ($parts.Count -lt 2) { continue }
        $kind = $parts[0]
        $parsed.Add([pscustomobject]@{
            Kind     = $kind
            Type     = $parts[1]
            Name     = if ($parts.Count -ge 3) { $parts[2] } else { '' }
            # A parameter counts toward the minimum arity unless it is optional.
            Required = ($kind -notmatch 'Opt$')
        })
    }

    # Determine which #ifdef block this declaration sits in, if any.
    $before = $text.Substring(0, $d.Index)
    $cond = $null
    foreach ($cm in [regex]::Matches($before, '(?m)^\s*#(ifdef|ifndef|if|else|elif|endif)\b\s*(.*)$')) {
        switch ($cm.Groups[1].Value) {
            'ifdef'  { $cond = "ifdef $($cm.Groups[2].Value.Trim())" }
            'ifndef' { $cond = "ifndef $($cm.Groups[2].Value.Trim())" }
            'if'     { $cond = "if $($cm.Groups[2].Value.Trim())" }
            'else'   { if ($cond) { $cond = "else of $cond" } }
            'elif'   { if ($cond) { $cond = "elif $($cm.Groups[2].Value.Trim())" } }
            'endif'  { $cond = $null }
        }
    }

    # Arity follows MdFunc::MdFunc in source/MdFunc.cpp exactly:
    #   - a `Ret` parameter is not a parameter at all: it only names the
    #     return value, so it is skipped and does not count toward arity
    #     (this is why PixelSearch reports Min=7 even though its declaration
    #     starts with (Ret, Bool32, Found))
    #   - output parameters DO count; they are passed by address but still
    #     occupy a positional slot
    #   - Max is the number of counted parameters
    #   - Min advances to the count after every non-optional parameter, so it
    #     ends up as one past the LAST required parameter.
    $min = 0
    $pc = 0
    foreach ($p in $parsed) {
        $pc++
        if ($p.Required) { $min = $pc }
    }
    $max = $pc

    # If g_BIF also lists this function, trust the interpreter's own numbers.
    # (In this revision the two tables are disjoint, so this normally does not
    # fire for md_func entries; it is kept because upstream is mid-migration and
    # a name may appear in both during the transition.)
    $fromGBif = $gBif.ContainsKey($name)
    $variadic = $false
    if ($fromGBif) {
        $min = $gBif[$name].Min
        $max = $gBif[$name].Max
        $variadic = $gBif[$name].Variadic
    }

    $entries.Add([pscustomobject]@{
        Name            = $name
        Variant         = $variant
        ReturnType      = $retType
        ReturnName      = $retName
        Params          = $parsed
        Min             = $min
        Max             = $max
        Variadic        = $variadic
        Condition       = $cond
        DeclaredIn      = 'source/lib/functions.h'
        NamesDeclared   = $true
        # md_func_v marks a function shaped like a bare statement (it returns
        # the previous setting), which is worth surfacing in the docs.
        Statement       = ($variant -eq 'v')
        RegisteredOnly  = $false
    })
}

# --- include built-ins that only exist in g_BIF ----------------------------
# These have no declaration in functions.h at all, so source gives their name
# and arity and nothing else.  Recorded as such rather than padded out with
# invented parameter names.
$declared = @{}
foreach ($e in $entries) { $declared[$e.Name] = $true }

$extra = @()
foreach ($name in ($gBif.Keys | Sort-Object)) {
    if ($declared.ContainsKey($name)) { continue }
    $g = $gBif[$name]

    $extra += [pscustomobject]@{
        Name            = $name
        Variant         = 'func'
        ReturnType      = $null
        ReturnName      = $null
        Params          = @()
        Min             = $g.Min
        Max             = $g.Max
        Variadic        = $g.Variadic
        Condition       = $null
        DeclaredIn      = 'g_BIF (source/script.cpp)'
        NamesDeclared   = $false
        Statement       = $false
        RegisteredOnly  = $true
    }
}
if ($extra.Count) {
    # Build a plain array rather than relying on the + operator, which errors
    # with "Argument types do not match" when either side collapses to a
    # single object instead of a collection.
    $merged = New-Object System.Collections.Generic.List[object]
    foreach ($e in $entries) { $merged.Add($e) }
    foreach ($e in $extra) { $merged.Add($e) }
    $entries = @($merged | Sort-Object Name)
}

$entryCount   = @($entries).Count
$namedCount   = @($entries | Where-Object { $_.NamesDeclared }).Count
$arityOnly    = @($entries | Where-Object { -not $_.NamesDeclared }).Count

# --- render ---------------------------------------------------------------
function Get-ArityText($e) {
    if ($e.Variadic) { return "$($e.Min) or more arguments" }
    if ($e.Min -eq $e.Max) { return "$($e.Min) argument(s)" }
    return "$($e.Min) to $($e.Max) arguments"
}

function Format-Signature($e) {
    if (-not $e.NamesDeclared) {
        # The source declares no parameter names for this function, so none are
        # printed.  A placeholder such as `arg1` would read as a real name.
        $ret = if ($e.ReturnType) { "  -> $($e.ReturnType)" } else { '' }
        return "$($e.Name)(<$(Get-ArityText $e)>)$ret"
    }
    $ps = @($e.Params | ForEach-Object {
        $n = $_.Name
        if ($_.Required) { $n } else { "[, $n]" }
    })
    $ret = if ($e.ReturnType) { "  -> $($e.ReturnType)" } else { '' }
    return "$($e.Name)(" + ($ps -join ', ') + ")$ret"
}

function Get-ProvenanceNote {
    param($Entries, [int]$Named, [int]$Total)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("$Total built-in function(s) are declared in this source tree.")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("- **$Named** carry full signatures (directions, types, parameter names,")
    [void]$sb.AppendLine('  return type), declared with the `md_func` family of macros in')
    [void]$sb.AppendLine('  `source/lib/functions.h`.')
    [void]$sb.AppendLine("- **$($Total - $Named)** are registered in the `g_BIF[]` table in")
    [void]$sb.AppendLine('  `source/script.cpp`, which stores only a name and an arity. Their')
    [void]$sb.AppendLine('  implementations take positional arguments, so **this source tree does')
    [void]$sb.AppendLine('  not declare their parameter names**; upstream is migrating them to the')
    [void]$sb.AppendLine('  `md_func` form and the rest have no names here to read. Those entries')
    [void]$sb.AppendLine('  show their real arity and are marked `[arity only]`. No placeholder')
    [void]$sb.AppendLine('  names are invented, because a placeholder is indistinguishable from a')
    [void]$sb.AppendLine('  real parameter name once it is in a document.')
    [void]$sb.AppendLine()
    return $sb.ToString()
}

function Get-Summary {
    param($Entries, [int]$Named, [int]$Total)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Built-in function signatures')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('Generated from the AutoHotkey source tree -- `source/lib/functions.h` and')
    [void]$sb.AppendLine('the `g_BIF[]` registry in `source/script.cpp`. Every line below is read out')
    [void]$sb.AppendLine('of those files; nothing is taken from documentation or from memory.')
    [void]$sb.AppendLine()
    [void]$sb.Append((Get-ProvenanceNote -Entries $Entries -Named $Named -Total $Total))
    [void]$sb.AppendLine("$Total functions. ``[, x]`` marks an optional parameter. ``[arity only]``")
    [void]$sb.AppendLine('marks a function whose parameter names are not declared in the source.')
    [void]$sb.AppendLine()
    if ($aliasNote) {
        [void]$sb.AppendLine("Argument-group macros expanded: ``$aliasNote``.")
        [void]$sb.AppendLine()
    }
    [void]$sb.AppendLine('| Function | Signature | Source |')
    [void]$sb.AppendLine('| --- | --- | --- |')
    foreach ($e in $Entries) {
        $sig = (Format-Signature $e) -replace '\|', '\|'
        $prov = if ($e.NamesDeclared) { 'functions.h' } else { 'g_BIF [arity only]' }
        [void]$sb.AppendLine("| ``$($e.Name)`` | ``$sig`` | $prov |")
    }
    return $sb.ToString()
}

function Get-FullDoc {
    param($Entries, [int]$Named, [int]$Total)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Built-in function reference')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('Generated from the AutoHotkey source tree. Do not edit by hand --')
    [void]$sb.AppendLine('regenerate with `pwsh -NoProfile -File tools/extract-api-docs.ps1`.')
    [void]$sb.AppendLine()
    [void]$sb.Append((Get-ProvenanceNote -Entries $Entries -Named $Named -Total $Total))
    [void]$sb.AppendLine('`In` = required, `In_Opt` = optional, `Out*` = by-reference output,')
    [void]$sb.AppendLine('`Ret` = return value. Types are the native declarations, which map to AHK')
    [void]$sb.AppendLine('v2 values as: `String` -> String, `Int32`/`Int64`/`UInt32`/`IntPtr` -> Integer,')
    [void]$sb.AppendLine('`Float64` -> Float, `Variant` -> any, `Object` -> Object/Map/Array.')
    [void]$sb.AppendLine()

    $byLetter = $Entries | Group-Object { $_.Name.Substring(0, 1).ToUpper() } | Sort-Object Name
    foreach ($g in $byLetter) {
        [void]$sb.AppendLine("## $($g.Name)")
        [void]$sb.AppendLine()
        foreach ($e in $g.Group) {
            [void]$sb.AppendLine("### $($e.Name)")
            [void]$sb.AppendLine()
            [void]$sb.AppendLine('```ahk')
            [void]$sb.AppendLine((Format-Signature $e))
            [void]$sb.AppendLine('```')
            [void]$sb.AppendLine()
            $facts = @()
            $facts += "min params: $($e.Min), max params: $($e.Max)"
            if ($e.ReturnType) { $facts += "returns: ``$($e.ReturnType)``" }
            if ($e.Statement) { $facts += 'statement form (returns the previous setting)' }
            if ($e.Variadic) { $facts += 'variadic (accepts a variable number of arguments)' }
            if ($e.Condition) { $facts += "only built when ``$($e.Condition)``" }
            [void]$sb.AppendLine(($facts -join '; ') + '.')
            [void]$sb.AppendLine()
            if (-not $e.NamesDeclared) {
                [void]$sb.AppendLine('Declared in ``g_BIF[]`` (``source/script.cpp``). That table stores a name')
                [void]$sb.AppendLine('and an arity only, and the implementation takes positional arguments, so')
                [void]$sb.AppendLine('**this source tree declares no parameter names for it**. Upstream is')
                [void]$sb.AppendLine('migrating built-ins to the ``md_func`` form; until this one is migrated')
                [void]$sb.AppendLine('there are no names to publish, and none are invented here.')
                [void]$sb.AppendLine()
            }
            elseif ($e.Params.Count) {
                [void]$sb.AppendLine('| Param | Direction | Type | Optional |')
                [void]$sb.AppendLine('| --- | --- | --- | --- |')
                foreach ($p in $e.Params) {
                    $opt = if ($p.Required) { '' } else { 'yes' }
                    $ty = if ($p.Type) { "``$($p.Type)``" } else { '' }
                    [void]$sb.AppendLine("| ``$($p.Name)`` | $($p.Kind) | $ty | $opt |")
                }
                [void]$sb.AppendLine()
            }
        }
    }
    return $sb.ToString()
}

# --- cross-check against a live interpreter --------------------------------
function Invoke-Verify {
    param($Entries, [string]$ExePath, [string]$RepoRoot)
    Import-Module (Join-Path $RepoRoot 'tools\AhkAi.psm1') -Force

    # Ask the interpreter for the arity of every parsed name. Building the
    # probe as one script keeps it to a single process start.
    $names = @($Entries | ForEach-Object { $_.Name })
    $probe = New-Object System.Text.StringBuilder
    [void]$probe.AppendLine('#Requires AutoHotkey v2.0')
    [void]$probe.AppendLine('names := [' + (($names | ForEach-Object { '"' + $_ + '"' }) -join ',') + ']')
    [void]$probe.AppendLine('for n in names {')
    [void]$probe.AppendLine('    try {')
    [void]$probe.AppendLine('        f := %n%')
    [void]$probe.AppendLine('        FileAppend n "`t" f.MinParams "`t" f.MaxParams "`t" f.IsVariadic "`n", "*"')
    [void]$probe.AppendLine('    } catch {')
    # A Class (like Map) has no arity; report it distinctly rather than failing.
    [void]$probe.AppendLine('        FileAppend n "`tCLASS`n", "*"')
    [void]$probe.AppendLine('    }')
    [void]$probe.AppendLine('}')

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('ahk-api-' + [guid]::NewGuid().ToString('N') + '.ahk')
    [System.IO.File]::WriteAllText($tmp, $probe.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    try {
        $r = Invoke-AhkAi -Exe $ExePath -Arguments @('/AI', $tmp) -TimeoutMs 120000
        if ($r.Blocked) { throw 'interpreter blocked (a dialog appeared)' }
        if ($r.StdErr.Trim()) { throw "interpreter wrote to stderr: $($r.StdErr.Trim())" }
    } finally {
        Remove-Item $tmp -Force -EA SilentlyContinue
    }

    $live = @{}
    foreach ($line in ($r.StdOut -split "`r?`n")) {
        if (-not $line.Trim()) { continue }
        $f = $line -split "`t"
        if ($f.Count -lt 2) { continue }
        $live[$f[0]] = [pscustomobject]@{
            Min = if ($f[1] -eq 'CLASS') { $null } else { [int]$f[1] }
            Max = if ($f[1] -eq 'CLASS') { $null } elseif ($f.Count -ge 3) { [int]$f[2] } else { $null }
        }
    }

    $mismatch = New-Object System.Collections.Generic.List[string]
    $checked = 0
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($e in $Entries) {
        if (-not $live.ContainsKey($e.Name)) { $missing.Add($e.Name); continue }
        $l = $live[$e.Name]
        if ($null -eq $l.Min) { continue }   # a Class, no arity to compare
        $checked++
        if ($e.Min -ne $l.Min) {
            $mismatch.Add("$($e.Name): source says min=$($e.Min), interpreter says min=$($l.Min)")
        }
        # Variadic built-ins (registered with NA = MAX_FUNCTION_PARAMS) report
        # MaxParams as MAX_FUNCTION_PARAMS in the g_BIF table, so there is no
        # fixed maximum to compare against.
        if (-not $e.Variadic -and $l.Max -gt 0 -and $e.Max -ne $l.Max) {
            $mismatch.Add("$($e.Name): source says max=$($e.Max), interpreter says max=$($l.Max)")
        }
    }

    Write-Output "verify   : checked $checked function(s) against $ExePath"
    if ($missing.Count) {
        Write-Output "note     : $($missing.Count) declared name(s) not resolvable at run time"
        Write-Output "           (expected for #ifdef'd ones): $(($missing | Select-Object -First 8) -join ', ')"
    }
    if ($mismatch.Count) {
        Write-Output ''
        Write-Output '::error::signature mismatch between source and interpreter:'
        $mismatch | Select-Object -First 30 | ForEach-Object { Write-Output "  $_" }
        throw "$($mismatch.Count) arity mismatch(es); the generated docs would be wrong"
    }
    Write-Output 'verify   : OK - parsed arity matches the running interpreter'
}

function Write-Lf([string]$path, [string]$content) {
    $dir = Split-Path -Parent $path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, ($content -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
}

# --- emit ------------------------------------------------------------------
Write-Output "source   : $functionsH"
Write-Output "functions: $entryCount ($namedCount with declared parameter names, $arityOnly arity-only)"
if ($aliasNote) { Write-Output "aliases  : $aliasNote" }

if ($Json) {
    $jsonOut = if ($OutFile) { $OutFile } else { Join-Path $RepoRoot 'dist\builtin-api.json' }
    $payload = [pscustomobject]@{
        generated_from = 'upstream/source (source/lib/functions.h + g_BIF[] in source/script.cpp)'
        count          = $entryCount
        parameter_names_declared = $namedCount
        parameter_names_absent   = $arityOnly
        functions      = @($entries | ForEach-Object {
            [pscustomobject]@{
                name        = $_.Name
                declared_in = $_.DeclaredIn
                # False means the source declares no names for this function
                # (g_BIF stores arity only); the params array is then empty and
                # the signature shows the arity instead of invented names.
                parameter_names_declared = $_.NamesDeclared
                return_type = $_.ReturnType
                min_params  = $_.Min
                max_params  = $_.Max
                variadic    = [bool]$_.Variadic
                signature   = Format-Signature $_
                condition   = $_.Condition
                params      = @($_.Params | ForEach-Object {
                    [pscustomobject]@{ name = $_.Name; direction = $_.Kind; type = $_.Type; optional = (-not $_.Required) }
                })
            }
        })
    }
    $jsonText = $payload | ConvertTo-Json -Depth 8
    Write-Lf $jsonOut $jsonText
    Write-Output "json     : $jsonOut"
}

if ($Summary) {
    Write-Lf $Summary (Get-Summary -Entries $entries -Named $namedCount -Total $entryCount)
    Write-Output "summary  : $Summary"
}

if ($OutDir) {
    $fullPath = Join-Path $OutDir 'SIGNATURES.md'
    Write-Lf $fullPath (Get-FullDoc -Entries $entries -Named $namedCount -Total $entryCount)
    Write-Output "markdown : $fullPath"
}

if ($Verify) {
    if (-not $Exe) {
        foreach ($c in @(
            (Join-Path $RepoRoot 'dist\AutoHotkey64.exe'),
            (Join-Path $UpstreamDir 'bin\AutoHotkey64.exe')
        )) { if (Test-Path $c) { $Exe = $c; break } }
    }
    if (-not $Exe -or -not (Test-Path $Exe)) { throw 'no interpreter to verify against; pass -Exe <path>' }
    Invoke-Verify -Entries $entries -ExePath (Resolve-Path $Exe).Path -RepoRoot $RepoRoot
}

exit 0
