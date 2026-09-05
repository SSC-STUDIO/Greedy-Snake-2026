param(
    [string]$GodotExe = 'C:\Program Files\Godot\Godot_v4.7.1-stable_win64_console.exe',
    [string]$CaseFilter = '',
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $PSScriptRoot
$runDir = Join-Path $env:TEMP ('Rustgrave-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$stdoutPath = Join-Path $runDir 'stdout.log'
$stderrPath = Join-Path $runDir 'stderr.log'
$arguments = @('--headless', '--path', ('"' + $projectDir + '"'), 'res://tests/run_tests.tscn')
if ($CaseFilter) { $arguments += @('--', ('"--case-filter=' + $CaseFilter.Replace('"', '') + '"')) }

# Child processes inherit this isolated user directory; never touch player saves.
$originalAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $runDir 'userdata'
    $process = Start-Process -FilePath $GodotExe -ArgumentList $arguments -WorkingDirectory $projectDir `
        -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru
} finally {
    $env:APPDATA = $originalAppData
}

$started = [DateTime]::UtcNow
$timedOut = $false
$earlyError = $false
while (-not $process.WaitForExit(250)) {
    $timedOut = ([DateTime]::UtcNow - $started).TotalSeconds -ge $TimeoutSeconds
    if (Test-Path -LiteralPath $stderrPath) {
        $earlyError = (Get-Content -LiteralPath $stderrPath -Raw) -match '(?m)^(?:SCRIPT ERROR|ERROR):'
    }
    if ($timedOut -or $earlyError) { break }
}
if ($timedOut -or $earlyError) {
    # The console launcher may own the actual engine process.
    Get-CimInstance Win32_Process -Filter ('ParentProcessId=' + $process.Id) |
        ForEach-Object { Stop-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }
    if (-not $process.HasExited) { $process.Kill() }
    $process.WaitForExit()
}
$process.Refresh()
$stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { '' }
$stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
Write-Output $stdout
if ($stderr) { Write-Output $stderr }
Write-Output ('Test artifacts: ' + $runDir)

# Also catch errors before the scene/logger could load, and require completion.
$hasErrors = ($stdout + "`n" + $stderr) -match '(?m)^(?:SCRIPT ERROR|ERROR|\[ENGINE ERROR\]):?'
$completed = $stdout -match '(?m)^OK .+\d+/\d+ passed; 0 engine errors'
if ($timedOut -or $process.ExitCode -ne 0 -or $hasErrors -or -not $completed) {
    if ($timedOut) { Write-Output ('[FAIL] process timeout after ' + $TimeoutSeconds + ' seconds') }
    exit 1
}
exit 0
