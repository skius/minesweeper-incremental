param([ValidateSet('Windows Desktop','Web')][string]$Target='Windows Desktop')
$ErrorActionPreference='Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = $env:GODOT_EXE
if (-not $enginePath -and (Test-Path (Join-Path $projectRoot '.env.local'))) {
    $line = Get-Content (Join-Path $projectRoot '.env.local') | Where-Object { $_ -match '^GODOT_EXE=' } | Select-Object -First 1
    if ($line) { $enginePath = $line.Substring(10).Trim('"') }
}
if (-not $enginePath -or -not (Test-Path -LiteralPath $enginePath)) { throw 'Set GODOT_EXE or .env.local.' }
$folder = Join-Path $projectRoot ('builds/'+ $(if ($Target -eq 'Web') {'web'} else {'windows'}))
New-Item -ItemType Directory -Force -Path $folder | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'test_runs') | Out-Null
$exportLog = Join-Path $projectRoot 'test_runs/export.log'
$filename = Join-Path $folder $(if ($Target -eq 'Web') {'index.html'} else {'Afterlight.exe'})
$engineArgs = @('--headless','--path',('"'+$projectRoot+'"'),'--export-release',('"'+$Target+'"'),('"'+$filename+'"'),'--log-file',('"'+$exportLog+'"'))
$engineProcess = Start-Process -FilePath $enginePath -ArgumentList $engineArgs -WindowStyle Hidden -PassThru
if (-not $engineProcess.WaitForExit(180000)) { $engineProcess.Kill(); throw ('Export timed out; stopped owned PID '+$engineProcess.Id) }
if ($engineProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $filename)) { Get-Content $exportLog -Tail 40; throw 'Export failed.' }
$failures = Select-String -Path $exportLog -Pattern 'ERROR:|Parse Error|SCRIPT ERROR:'
if ($failures) { $failures | ForEach-Object { Write-Output $_.Line }; throw 'Export emitted errors.' }
Write-Output ('Exported '+$Target+' to '+$filename)
