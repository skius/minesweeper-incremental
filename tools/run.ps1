param([ValidateSet('import','test','shots','play','balance','power','trials')][string]$Mode='play')
$ErrorActionPreference='Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = $env:GODOT_EXE
if (-not $enginePath -and (Test-Path (Join-Path $projectRoot '.env.local'))) {
    $line = Get-Content (Join-Path $projectRoot '.env.local') | Where-Object { $_ -match '^GODOT_EXE=' } | Select-Object -First 1
    if ($line) { $enginePath = $line.Substring(10).Trim('"') }
}
if (-not $enginePath -or -not (Test-Path -LiteralPath $enginePath)) { throw 'Set GODOT_EXE to the Godot executable, or set it in .env.local.' }
$runRoot = Join-Path $projectRoot 'test_runs'
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
$ignoreHandle = [System.IO.File]::Open((Join-Path $runRoot '.gdignore'), [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::ReadWrite)
$ignoreHandle.Dispose()
$runLog = Join-Path $runRoot ($Mode + '.log')
switch ($Mode) {
    'play' { Start-Process -FilePath $enginePath -ArgumentList @('--path', ('"'+$projectRoot+'"')) -WindowStyle Normal; exit 0 }
    'import' { $engineArgs = @('--headless','--path',('"'+$projectRoot+'"'),'--editor','--import','--quit','--log-file',('"'+$runLog+'"')) }
    'test' { $engineArgs = @('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tests/test_core.gd','--log-file',('"'+$runLog+'"'),'--',('"--test-data='+(Join-Path $runRoot 'unit_data')+'"')) }
    'balance' { $engineArgs = @('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tests/balance.gd','--log-file',('"'+$runLog+'"'),'--',('"--test-data='+(Join-Path $runRoot 'balance_data')+'"')) }
    'power' { $engineArgs = @('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tests/power_curve.gd','--log-file',('"'+$runLog+'"')) }
    'trials' { $engineArgs = @('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tests/trials.gd','--log-file',('"'+$runLog+'"')) }
    'shots' { python (Join-Path $PSScriptRoot 'hidden_run.py') --engine $enginePath --project $projectRoot --log $runLog; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
}
if ($Mode -in @('import','test','balance','power','trials')) {
    $engineProcess = Start-Process -FilePath $enginePath -ArgumentList $engineArgs -WindowStyle Hidden -PassThru
    if (-not $engineProcess.WaitForExit($(if ($Mode -eq 'balance') {900000} else {180000}))) { $engineProcess.Kill(); throw ('Godot timed out; stopped owned PID '+$engineProcess.Id) }
    if ($engineProcess.ExitCode -ne 0) { Get-Content $runLog -Tail 30; exit 1 }
}
if (Test-Path $runLog) {
    $failures = Select-String -Path $runLog -Pattern 'SCRIPT ERROR:|ERROR:|Parse Error|Assertion failed'
    if ($failures) { $failures | ForEach-Object { Write-Output $_.Line }; exit 1 }
    if ($Mode -in @('test','balance','shots','power','trials') -and -not (Select-String -Path $runLog -Pattern 'AFTERLIGHT PASS')) { throw 'Test completion marker missing.' }
    if ($Mode -in @('test','balance','shots','power','trials')) { (Select-String -Path $runLog -Pattern 'AFTERLIGHT PASS' | Select-Object -Last 1).Line }
}
