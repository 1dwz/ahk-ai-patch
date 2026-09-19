#requires -Version 5.1
<#
Generate the built-in API reference from a live AutoHotkey build.

This is the runtime counterpart to tools/extract-api-docs.ps1. That script
reads the source (upstream/source/lib/functions.h and script.cpp) and is what
you run in the patch repository; this one asks the interpreter itself via
/dump-api, so it documents the exact binary someone is holding -- which is the
only thing that is definitely true about it.

The two are deliberately independent: extract-api-docs.ps1 proves the source
matches the build, this proves the build describes itself.

/dump-api emits two sections because AutoHotkey keeps two registries:

  g_BIF   (script.cpp)         arity, variadic flag, output-parameter indices
  sMdFunc (MdFunc.cpp)         full argument and return types

They do not overlap -- a function appears in exactly one -- so both are needed
to describe the whole surface. See docs/BUILTIN_HTTP_JSON.md for the
hand-written option reference for the functions this patch set adds, which no
generated table can supply.

Usage:
  pwsh -NoProfile -File tools/gen-builtin-docs.ps1
  pwsh -NoProfile -File tools/gen-builtin-docs.ps1 -Exe dist/AutoHotkey64.exe -OutDir docs/api
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Exe,
    [string]$OutDir,
    [string]$Markdown,
    [string]$Json,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AhkAi.psm1') -Force

if (-not $Exe) {
    foreach ($c in @(
        (Join-Path $RepoRoot 'dist\AutoHotkey64.exe'),
        (Join-Path $RepoRoot 'upstream\bin\AutoHotkey64.exe')
    )) { if (Test-Path $c) { $Exe = $c; break } }
}
if (-not $Exe -or -not (Test-Path $Exe)) { throw "interpreter not found; pass -Exe <path>" }
$Exe = (Resolve-Path $Exe).Path

if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'docs\api' }
if (-not $Markdown) { $Markdown = Join-Path $OutDir 'RUNTIME_API.md' }
if (-not $Json) { $Json = Join-Path $OutDir 'builtin-api.json' }

# --- ask the interpreter ---------------------------------------------------
# Invoke-AhkAi runs the process with a timeout and captures real stderr, which
# matters here: a build without /dump-api would otherwise sit on a dialog.
$r = Invoke-AhkAi -Exe $Exe -Arguments @('/dump-api') -TimeoutMs 60000
if ($r.Blocked) { throw '/dump-api blocked (a dialog appeared); this build predates the flag' }
if ($r.ExitCode -ne 0) { throw "/dump-api exited $($r.ExitCode): $($r.StdErr.Trim())" }
if ($r.StdErr.Trim()) { throw "/dump-api wrote to stderr: $($r.StdErr.Trim())" }

$lines = $r.StdOut -split "`r?`n"

# --- parse -----------------------------------------------------------------
# Section 1 (g_BIF):    name <tab> min <tab> max|* <tab> variadic <tab> outputs
# Section 2 (sMdFunc):  name <tab> arg, arg, ...        (types, in order)
$arity = [ordered]@{}
$typed = [ordered]@{}
$section = 'none'
foreach ($line in $lines) {
    if (-not $line.Trim()) { continue }
    if ($line -eq '# typed functions (lib/functions.h)') { $section = 'typed'; continue }
    if ($line.StartsWith('#')) {
        if ($line -like '*built-in functions*') { $section = 'arity' }
        continue
    }
    $f = $line -split "`t"
    if ($f.Count -lt 2) { continue }
    if ($section -eq 'typed') {
        # Typed lines are "name <tab> arg, arg, ..." -- the arguments are the
        # second field, and a function with no arguments has no second field at
        # all (there is no separate return column, since the Ret modifier is
        # part of the argument list).
        $args = if ($f.Count -ge 2 -and $f[1].Trim()) {
            @($f[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        } else { @() }
        $typed[$f[0]] = $args
    }
    else {
        # Arity lines are "name <tab> min <tab> max <tab> variadic <tab> outputs".
        $out = if ($f.Count -ge 5 -and $f[4].Trim()) { @($f[4] -split ',') } else { @() }
        $arity[$f[0]] = [pscustomobject]@{
            Min      = [int]$f[1]
            Max      = if ($f[2].Trim() -eq '*') { $null } else { [int]$f[2] }
            Variadic = ($f[3].Trim() -eq '1')
            Outputs  = $out
        }
    }
}

$allNames = @($arity.Keys) + @($typed.Keys) | Sort-Object -Unique

if (-not $Quiet) {
    Write-Output "interpreter : $Exe"
    Write-Output "g_BIF       : $($arity.Count) function(s)"
    Write-Output "sMdFunc     : $($typed.Count) function(s)"
    Write-Output "union       : $($allNames.Count) function(s)"
}

# --- extra parameter names for patch-added built-ins ----------------------
# HttpRequest / JsonParse / JsonStringify are registered through BIF1(...) in
# script.cpp, which records arity but no parameter names, and they are not in
# lib/functions.h either. Their real signatures live in the implementation, so
# they are spelled out here. Keep this in sync with the same table in
# tools/extract-api-docs.ps1; the arity below is checked against g_BIF, so a
# drift fails loudly instead of printing a wrong signature.
$manualSignatures = @{
    'HttpRequest'   = @{ Params = @('url', 'options');          Returns = 'Map' }
    'JsonParse'     = @{ Params = @('text');                    Returns = 'Any' }
    'JsonStringify' = @{ Params = @('value', 'indent');         Returns = 'String' }
}

# --- render ----------------------------------------------------------------
function Get-Signature {
    param([string]$Name, $Arity, $Typed, $Manual)
    # A hand-written signature wins when there is one, because it carries real
    # parameter names rather than types alone.
    if ($Manual.Contains($Name)) {
        $m = $Manual[$Name]
        $a = $Arity[$Name]
        $parts = @()
        for ($i = 0; $i -lt $m.Params.Count; $i++) {
            $n = $m.Params[$i]
            if ($a -and $i -ge $a.Min) { $parts += "[, $n]" } else { $parts += $n }
        }
        $ret = if ($m.Returns) { "  -> $($m.Returns)" } else { '' }
        if ($parts.Count -eq 0) { return "$Name()$ret" }
        return "$Name(" + ($parts -join ', ') + ")$ret"
    }
    # Prefer the typed form: it names the argument types, which is what a
    # caller actually needs.  Fall back to the arity form otherwise.
    #
    # Each typed argument is a sequence of space-separated words, e.g.
    # "Out_Opt Int32".  Only the LAST word is the type; the rest are
    # modifiers.  Optionality is expressed by the "Opt" modifier, and the
    # trailing Out_Ret marks the return slot rather than a parameter.
    if ($Typed.Contains($Name)) {
        $args = $Typed[$Name]
        if (-not $args -or $args.Count -eq 0) { return "$Name()" }
        $parts = @()
        $retType = $null
        foreach ($a in $args) {
            $words = @($a -split '\s+' | Where-Object { $_ })
            if ($words.Count -eq 0) { continue }
            $mods = @($words[0..($words.Count - 2)])
            $type = $words[-1]
            # The return slot is marked with a Ret/RetVal modifier, emitted as
            # "Out_Ret" (or "Ret" / "Ret_Opt" depending on the declaration).
            # Match it as a substring of the modifier list.  It is not a
            # parameter, but its type is worth keeping.
            if (($mods -join '_') -match 'Ret') { $retType = $type; continue }
            $isOpt = ($mods -contains 'Opt') -or ($mods -contains 'In_Opt') -or ($mods -contains 'Out_Opt')
            $label = if ($isOpt) { "[, $type]" } else { $type }
            $parts += $label
        }
        $ret = if ($retType) { "  -> $retType" } else { '' }
        if ($parts.Count -eq 0) { return "$Name()$ret" }
        return "$Name(" + ($parts -join ', ') + ")$ret"
    }
    if ($Arity.Contains($Name)) {
        # g_BIF records only the counts, so the parameters cannot be named.
        $a = $Arity[$Name]
        $parts = @()
        for ($i = 0; $i -lt $a.Min; $i++) { $parts += "arg$($i + 1)" }
        if ($a.Variadic) {
            $parts += '...'
        } else {
            for ($i = $a.Min; $i -lt $a.Max; $i++) { $parts += "[, arg$($i + 1)]" }
        }
        if ($parts.Count -eq 0) { return "$Name()" }
        return "$Name(" + ($parts -join ', ') + ")"
    }
    return $Name
}

function Get-Doc {
    param($AllNames, $Arity, $Typed, $Manual, [string]$ExePath)

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Built-in API of this build')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('Generated by `tools/gen-builtin-docs.ps1`, which asks the interpreter')
    [void]$sb.AppendLine('itself (`AutoHotkey64.exe /dump-api`). This describes the exact binary it')
    [void]$sb.AppendLine('was run against, not the source it was built from.')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Interpreter: ``$([System.IO.Path]::GetFileName($ExePath))``")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("**$($AllNames.Count) built-in functions.** Every name appears in exactly one of two")
    [void]$sb.AppendLine('internal registries, so both are reported:')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('| Registry | Count | Carries |')
    [void]$sb.AppendLine('| --- | --- | --- |')
    [void]$sb.AppendLine("| ``g_BIF`` (``source/script.cpp``) | $($Arity.Count) | minimum/maximum argument count, variadic flag, output parameters |")
    [void]$sb.AppendLine("| ``sMdFunc`` (``source/MdFunc.cpp``) | $($Typed.Count) | full argument and return types |")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('Prefer the typed signature where one exists: it tells you what each')
    [void]$sb.AppendLine('argument must be. `[, x]` marks an optional argument.')
    [void]$sb.AppendLine()

    # A few functions deserve a pointer to the hand-written option reference,
    # because their real surface is an options object that no signature table
    # can express.
    $hasOptions = @($AllNames | Where-Object { $Manual.Contains($_) })
    if ($hasOptions.Count) {
        [void]$sb.AppendLine('> `HttpRequest`, `JsonParse` and `JsonStringify` are added by this patch')
        [void]$sb.AppendLine('> set. Their signatures are listed below, but their behaviour and the')
        [void]$sb.AppendLine('> `HttpRequest` options object are documented by hand in')
        [void]$sb.AppendLine('> [docs/BUILTIN_HTTP_JSON.md](../BUILTIN_HTTP_JSON.md) -- read that before using them.')
        [void]$sb.AppendLine()
    }

    [void]$sb.AppendLine('## All functions')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('| Function | Signature | Source of truth |')
    [void]$sb.AppendLine('| --- | --- | --- |')
    foreach ($n in $AllNames) {
        $sig = (Get-Signature -Name $n -Arity $Arity -Typed $Typed -Manual $Manual) -replace '\|', '\|'
        $src = if ($Manual.Contains($n)) { 'declared in the patch' } elseif ($Typed.Contains($n)) { 'sMdFunc' } else { 'g_BIF' }
        [void]$sb.AppendLine("| ``$n`` | ``$sig`` | $src |")
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine('## Functions with output parameters')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('These write back through one or more arguments (`g_BIF` records which),')
    [void]$sb.AppendLine('which is easy to miss when calling them from generated code.')
    [void]$sb.AppendLine()
    $withOut = @($Arity.Keys | Where-Object { $Arity[$_].Outputs.Count -gt 0 } | Sort-Object)
    if ($withOut.Count) {
        [void]$sb.AppendLine('| Function | Output argument(s) |')
        [void]$sb.AppendLine('| --- | --- |')
        foreach ($n in $withOut) {
            [void]$sb.AppendLine("| ``$n`` | $($Arity[$n].Outputs -join ', ') |")
        }
    } else {
        [void]$sb.AppendLine('(none reported by this build)')
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine('## Variadic functions')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('These accept an unbounded number of arguments, so the maximum in the')
    [void]$sb.AppendLine('signature table does not apply.')
    [void]$sb.AppendLine()
    $variadic = @($Arity.Keys | Where-Object { $Arity[$_].Variadic } | Sort-Object)
    if ($variadic.Count) {
        foreach ($n in $variadic) { [void]$sb.AppendLine("- ``$n`` (at least $($Arity[$n].Min))") }
    } else {
        [void]$sb.AppendLine('(none reported by this build)')
    }
    [void]$sb.AppendLine()

    return $sb.ToString()
}

# --- emit ------------------------------------------------------------------
$dir = Split-Path -Parent $Markdown
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

# PowerShell's AppendLine() and ConvertTo-Json emit CRLF on Windows, but every
# generated artefact in this repo is kept at LF.  Normalising here means the
# output is stable regardless of which host generated it.
function Write-TextLf([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, ($Text -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
}

$docText = Get-Doc -AllNames $allNames -Arity $arity -Typed $typed -Manual $manualSignatures -ExePath $Exe
Write-TextLf $Markdown $docText

$payload = [pscustomobject]@{
    generated_by = '/dump-api'
    interpreter  = $Exe
    count        = $allNames.Count
    g_bif_count  = $arity.Count
    s_mdfunc_count = $typed.Count
    functions    = @($allNames | ForEach-Object {
        $n = $_
        [pscustomobject]@{
            name       = $n
            registry   = if ($manualSignatures.Contains($n)) { 'patch' } elseif ($typed.Contains($n)) { 'sMdFunc' } else { 'g_BIF' }
            signature  = Get-Signature -Name $n -Arity $arity -Typed $typed -Manual $manualSignatures
            arguments  = if ($typed.Contains($n)) { @($typed[$n]) } else { @() }
            min_params = if ($arity.Contains($n)) { $arity[$n].Min } else { $null }
            max_params = if ($arity.Contains($n)) { $arity[$n].Max } else { $null }
            variadic   = if ($arity.Contains($n)) { $arity[$n].Variadic } else { $false }
            outputs    = if ($arity.Contains($n)) { @($arity[$n].Outputs) } else { @() }
        }
    })
}
$jsonDir = Split-Path -Parent $Json
if ($jsonDir -and -not (Test-Path $jsonDir)) { New-Item -ItemType Directory -Force -Path $jsonDir | Out-Null }
Write-TextLf $Json ($payload | ConvertTo-Json -Depth 8)

if (-not $Quiet) {
    Write-Output "markdown    : $Markdown"
    Write-Output "json        : $Json"
}

exit 0
