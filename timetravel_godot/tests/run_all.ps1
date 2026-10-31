# run_all.ps1 - runs both test suites headless and prints one line each. Exit code 1 if anything failed.
# Usage (any folder):  powershell -ExecutionPolicy Bypass -File timetravel_godot\tests\run_all.ps1
# Pass -Verbose to also print every FAIL line and script error.
param([string]$Godot = "C:\Users\Chittranjan\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
      [switch]$Verbose)

$project = Split-Path $PSScriptRoot -Parent
$bad = 0
foreach ($suite in "world", "fight") {
    $out = & $Godot --headless --fixed-fps 60 --path $project -s "tests/$suite.gd" 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    $summary = $out | Where-Object { $_ -match '^---- passed:' } | Select-Object -Last 1
    if (-not $summary) { $summary = "no summary (crashed or script error)" }
    $result = if ($code -eq 0) { "OK" } else { "FAILED"; $bad++ }
    "{0,-6} {1,-7} {2}" -f $suite, $result, $summary.Replace("---- ", "")
    if ($code -ne 0 -or $Verbose) {
        $out | Where-Object { $_ -match '^FAIL|SCRIPT ERROR|Parse Error' } | ForEach-Object { "    $_" }
    }
}
exit $(if ($bad -gt 0) { 1 } else { 0 })
