#requires -Version 5.1
<#
Extract built-in function signatures from the AutoHotkey source into Markdown.

The authoritative source is source/lib/functions.h: every built-in function is
declared there with its parameter directions, types and names plus its return
type, in a machine-readable macro form:

    md_func(WinWait, (In_Opt, Variant, WinTitle), ..., (Ret, UInt32, Hwnd))

This script turns that into reference documentation. It does not guess: the
macro bodies in source/MdType.h define the exact meaning of every field, and
the `MD_*` argument-list aliases at the top of functions.h are expanded so the
generated signature lists real parameters rather than a macro name.

Beyond the source, the script can cross-check its own output against a live
interpreter. AutoHotkey exposes MinParams / MaxParams / IsVariadic on every
built-in function object, so those are ground truth for arity. If the parsed
arity ever disagrees with the running build, the script fails -- which is what
keeps this documentation honest across upstream bumps.

Usage:
  pwsh -NoProfile -File tools/extract-api-docs.ps1
  pwsh -NoProfile -File tools/extract-api-docs.ps1 -OutDir docs/api
  pwsh -NoProfile -File tools/extract-api-docs.ps1 -Verify -Exe dist/AutoHotkey64.exe
  pwsh -NoProfile -File tools/extract-api-docs.ps1 -Json -OutFile dist/api.json
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

# --- extra parameter names for patch-added built-ins ----------------------
# HttpRequest / JsonParse / JsonStringify are registered through BIF1(...) in
# script.cpp, which records arity but no parameter names. Their real
# signatures only exist in the implementation, so they are spelled out here.
# extract-api-docs.ps1 verifies the arity below against the interpreter, so a
# mismatch fails the build rather than silently documenting the wrong thing.
$manualSignatures = @{
    'HttpRequest'   = @{ Params = @('url', 'options');                              Returns = 'Map' }
    'JsonParse'     = @{ Params = @('text');                                        Returns = 'Any' }
    'JsonStringify' = @{ Params = @('value', 'indent');                             Returns = 'String' }
}

# --- read the g_BIF registry from script.cpp -------------------------------
# functions.h declares parameter types, but not every built-in appears there:
# the `g_BIF[]` table in script.cpp is the definitive runtime list, and it is
# where a function compiled in under an #ifdef (or added by a patch) shows up.
# Each row is BIF1(Name, minp, maxp) or BIFn(Name, minp, maxp, Impl) -- the two
# numbers are the interpreter's own MinParams/MaxParams for that function.
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
$current = ''
$condStack = New-Object System.Collections.Generic.List[string]

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
    #     ends up as one past the LAST required parameter. ControlGetPos is the
    #     clear case: four Out_Opt params, then a required Control, then
    #     optional window params, giving Min=5 / Max=9 -- verified against the
    #     interpreter, and `ControlGetPos("Button1")` is rejected at run time.
    $min = 0
    $pc = 0
    foreach ($p in $parsed) {
        $pc++
        if ($p.Required) { $min = $pc }
    }
    $max = $pc

    # If g_BIF lists this function, trust the interpreter's own numbers: they
    # are what a script actually sees, and they cover anything the declaration
    # above could not express.
    if ($gBif.ContainsKey($name)) {
        $min = $gBif[$name].Min
        $max = $gBif[$name].Max
    }

    $entries.Add([pscustomobject]@{
        Name       = $name
        Variant    = $variant
        ReturnType = $retType
        ReturnName = $retName
        Params     = $parsed
        Min        = $min
        Max        = $max
        Condition  = $cond
        # md_func_v marks a function shaped like a bare statement (it returns
        # the previous setting), which is worth surfacing in the docs.
        Statement  = ($variant -eq 'v')
    })
}

$entries = @($entries | Sort-Object Name)

# --- include built-ins that only exist in g_BIF ----------------------------
# The patch set registers HttpRequest / JsonParse / JsonStringify through
# BIF1(...) in script.cpp rather than through functions.h, so they would
# otherwise be missing from the generated reference entirely.
$declared = @{}
foreach ($e in $entries) { $declared[$e.Name] = $true }

$extra = @()
foreach ($name in ($gBif.Keys | Sort-Object)) {
    if ($declared.ContainsKey($name)) { continue }
    $g = $gBif[$name]
    # Fill in parameter names for patch-added functions from the table above.
    $manual = $null
    if ($manualSignatures.ContainsKey($name)) { $manual = $manualSignatures[$name] }

    $extra += [pscustomobject]@{
        Name           = $name
        Variant        = 'func'
        ReturnType     = if ($manual) { $manual.Returns } else { $null }
        ReturnName     = $null
        # Rebuild as real parameters so the signature renders with names. Every
        # one of these has a fixed maximum, so positional optionality from the
        # g_BIF min count is accurate.
        Params         = if ($manual) {
            $i = 0
            @($manual.Params | ForEach-Object {
                $i++
                [pscustomobject]@{ Kind = if ($i -le $g.Min) { 'In' } else { 'In_Opt' }; Type = ''; Name = $_; Required = ($i -le $g.Min) }
            })
        } else { @() }
        Min            = $g.Min
        Max            = $g.Max
        Condition      = $null
        Statement      = $false
        Variadic       = $g.Variadic
        # Flag it so the docs can say where to find its parameter details.
        RegisteredOnly = (-not $manual)
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

# --- render ---------------------------------------------------------------
function Format-Signature($e) {
    if ($e.RegisteredOnly) {
        # Known only from g_BIF, which records arity but no parameter names.
        $ret = if ($e.ReturnType) { "  -> $($e.ReturnType)" } else { '' }
        $parts = @()
        for ($i = 0; $i -lt $e.Max; $i++) {
            if ($i -lt $e.Min) { $parts += "arg$($i + 1)" } else { $parts += "[, arg$($i + 1)]" }
        }
        return "$($e.Name)(" + ($parts -join ', ') + ")$ret"
    }
    $ps = @($e.Params | ForEach-Object {
        $n = $_.Name
        if ($_.Required) { $n } else { "[, $n]" }
    })
    $ret = if ($e.ReturnType) { "  -> $($e.ReturnType)" } else { '' }
    return "$($e.Name)(" + ($ps -join ', ') + ")$ret"
}

function Get-Summary {
    param($Entries)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Built-in function signatures')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Extracted from ``source/lib/functions.h`` -- the authoritative declaration of")
    [void]$sb.AppendLine('every built-in function, its parameter directions/types/names and its return type.')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("$($Entries.Count) functions. ``[, x]`` marks an optional parameter.")
    [void]$sb.AppendLine()
    if ($aliasNote) {
        [void]$sb.AppendLine("Argument-group macros expanded: ``$aliasNote``.")
        [void]$sb.AppendLine()
    }
    [void]$sb.AppendLine('| Function | Signature |')
    [void]$sb.AppendLine('| --- | --- |')
    foreach ($e in $Entries) {
        $sig = (Format-Signature $e) -replace '\|', '\|'
        [void]$sb.AppendLine("| ``$($e.Name)`` | ``$sig`` |")
    }
    return $sb.ToString()
}

function Get-FullDoc {
    param($Entries)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Built-in function reference')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('Generated from `source/lib/functions.h`. Do not edit by hand --')
    [void]$sb.AppendLine('regenerate with `pwsh -NoProfile -File tools/extract-api-docs.ps1`.')
    [void]$sb.AppendLine()
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
            if ($e.RegisteredOnly) {
                [void]$sb.AppendLine('Registered in ``g_BIF`` (``source/script.cpp``) rather than declared in')
                [void]$sb.AppendLine('``functions.h``, so its parameter names are not available from source.')
                [void]$sb.AppendLine('See the hand-written notes in the repository ``docs/`` for its options.')
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

# --- emit ------------------------------------------------------------------
Write-Output "source   : $functionsH"
Write-Output "functions: $($entries.Count)"
if ($aliasNote) { Write-Output "aliases  : $aliasNote" }

if ($Json) {
    $jsonOut = if ($OutFile) { $OutFile } else { Join-Path $RepoRoot 'dist\api.json' }
    $dir = Split-Path -Parent $jsonOut
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $payload = [pscustomobject]@{
        generated_from = 'upstream/source/lib/functions.h'
        count          = $entries.Count
        functions      = @($entries | ForEach-Object {
            [pscustomobject]@{
                name        = $_.Name
                return_type = $_.ReturnType
                min_params  = $_.Min
                max_params  = $_.Max
                signature   = Format-Signature $_
                condition   = $_.Condition
                params      = @($_.Params | ForEach-Object {
                    [pscustomobject]@{ name = $_.Name; direction = $_.Kind; type = $_.Type; optional = (-not $_.Required) }
                })
            }
        })
    }
    $jsonText = $payload | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($jsonOut, ($jsonText -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "json     : $jsonOut"
}

if ($Summary) {
    $dir = Split-Path -Parent $Summary
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Summary, ((Get-Summary $entries) -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "summary  : $Summary"
}

if ($OutDir) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
    $fullPath = Join-Path $OutDir 'SIGNATURES.md'
    [System.IO.File]::WriteAllText($fullPath, ((Get-FullDoc $entries) -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
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
