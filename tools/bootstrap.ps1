$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'run.ps1') -Mode import
if ($LASTEXITCODE) { exit $LASTEXITCODE }
& (Join-Path $PSScriptRoot 'run.ps1') -Mode test
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Write-Output 'Afterlight is ready. Run tools/run.ps1 -Mode play.'
