# check-docs.ps1 - Stop hook: if code changed after the .md docs were last touched, ask Claude (once) to update the docs.
# Rule source: CLAUDE.md "Always update the .md files after a change".
# Blocks at most once per stop: when stop_hook_active is true it lets the stop through.

$ErrorActionPreference = "SilentlyContinue"
$raw = [Console]::In.ReadToEnd()
$data = $null
if ($raw) { try { $data = $raw | ConvertFrom-Json } catch {} }
if ($data -and $data.stop_hook_active) { exit 0 }

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$root = (Get-Item -LiteralPath $root).FullName.TrimEnd('\')   # long-path form, so names below print correctly

$code = @(
    "timetravel_godot\scripts\*.gd", "timetravel_godot\tests\*.gd", "timetravel_godot\*.tscn",
    "timetravel_godot\project.godot", "Code\*.py", "Code\*.json"
) | ForEach-Object { Get-ChildItem -Path (Join-Path $root $_) -File }
$docs = @(
    "timetravel_godot\README.md", "IMPROVEMENTS.md", "Code\setup.md", "CLAUDE.md"
) | ForEach-Object { Get-ChildItem -Path (Join-Path $root $_) -File }

if (-not $code) { exit 0 }
$newestCode = ($code | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
$newestDoc = ($docs | Sort-Object LastWriteTime -Descending | Select-Object -First 1)

if (-not $newestDoc -or $newestCode.LastWriteTime -gt $newestDoc.LastWriteTime) {
    $name = $newestCode.FullName.Substring($root.Length).TrimStart('\')
    $reason = "Code changed after the docs were last updated (newest: $name). Per CLAUDE.md, update timetravel_godot/README.md " +
        "(current state + stage history) and IMPROVEMENTS.md (mark done / add new), plus Code/setup.md for pipeline changes. " +
        "If no doc change is needed, say why."
    @{ decision = "block"; reason = $reason } | ConvertTo-Json -Compress
}
exit 0
