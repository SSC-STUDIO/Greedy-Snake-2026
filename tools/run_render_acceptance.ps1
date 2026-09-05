param(
    [string]$GodotExe = 'C:\Program Files\Godot\Godot_v4.7.1-stable_win64_console.exe',
    [switch]$Quick,
    [switch]$Supplement
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $workspace 'screenshots\acceptance\display'
if ($Supplement) { $outputDir = Join-Path $outputDir 'supplement' }
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$reportPath = Join-Path $outputDir 'report.json'
if (Test-Path -LiteralPath $reportPath) { Remove-Item -LiteralPath $reportPath }
$env:APPDATA = Join-Path $outputDir 'isolated-userdata'
$arguments = @('--path', ('"' + $workspace + '"'), '--windowed', '--position', '-12000,-12000', '--resolution', '1920x1080', '--rendering-method', 'gl_compatibility', 'res://scenes/tools/RenderAcceptance.tscn')
if ($Supplement) { $arguments += @('--', '--supplement') }
elseif ($Quick) { $arguments += @('--', '--quick') }
$process = Start-Process -FilePath $GodotExe -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputDir 'stdout.log') -RedirectStandardError (Join-Path $outputDir 'stderr.log')
$started = [DateTime]::UtcNow
while (-not $process.WaitForExit(250)) {
    $errorsFound = (Get-Content -LiteralPath (Join-Path $outputDir 'stderr.log') -Raw) -match '(?m)^(SCRIPT ERROR:|ERROR:)'
    if ($errorsFound -or ([DateTime]::UtcNow - $started).TotalSeconds -gt 330) {
        Get-CimInstance Win32_Process -Filter ('ParentProcessId=' + $process.Id) | ForEach-Object { Stop-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }
        if (-not $process.HasExited) { $process.Kill() }
        $process.WaitForExit()
        Get-Content -LiteralPath (Join-Path $outputDir 'stderr.log') | Select-Object -Last 15
        throw 'Render acceptance failed or timed out before completion.'
    }
}
$process.Refresh()
if (Test-Path -LiteralPath $reportPath) {
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    $exitErrors = @(Get-Content -LiteralPath (Join-Path $outputDir 'stderr.log') | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:)' })
    $exitErrors += @(Get-Content -LiteralPath (Join-Path $outputDir 'stdout.log') | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:)' })
    $report | Add-Member -NotePropertyName engine_exit_errors -NotePropertyValue $exitErrors -Force
    $expectedCaptureCount = if ($Supplement) { 24 } elseif ($Quick) { 8 } else { 36 }
    $expectedTitleCount = if ($Supplement) { 1 } else { $expectedCaptureCount / 4 }
    $report.passed = [bool]$report.passed -and $exitErrors.Count -eq 0 -and $process.ExitCode -eq 0 -and [bool]$report.completed -and $report.resolutions.Count -eq $expectedCaptureCount -and $report.title_screens.Count -eq $expectedTitleCount
    [IO.File]::WriteAllText($reportPath, ($report | ConvertTo-Json -Depth 14), (New-Object Text.UTF8Encoding($false)))
}
else {
    Write-Error 'Rendering stopped before report.json was produced; no completed acceptance result exists.'
    exit 1
}
Get-Content -LiteralPath (Join-Path $outputDir 'stdout.log') | Select-Object -Last 8
Get-Content -LiteralPath (Join-Path $outputDir 'stderr.log') | Select-Object -Last 12
if ($null -ne $report -and -not $report.passed) { exit 1 }
exit $process.ExitCode
