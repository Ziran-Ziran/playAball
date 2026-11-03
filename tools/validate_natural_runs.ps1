param(
 [Parameter(Mandatory=$true)][string]$GodotExe,
 [string]$BatchName='e-natural-isolated-v3',
 [string[]]$Profiles=@('baseline','control_060','cooldown_200'),
 [int[]]$Seeds=@(123456),
 [int]$MaxSeconds=480
)
$ErrorActionPreference='Stop'
if ($BatchName -notmatch '^[a-z0-9_-]+$') { throw 'Invalid batch name.' }
$projectRoot=Split-Path -Parent $PSScriptRoot
$batchRoot=Join-Path $projectRoot ('.local/overnight/'+$BatchName)
New-Item -ItemType Directory -Force -Path $batchRoot | Out-Null
$sourcePaths=[string[]](& git -C $projectRoot ls-files --cached --others --exclude-standard -- scripts scenes resources | Where-Object { $_ -match '\.(gd|tscn|tres)$' })
[Array]::Sort($sourcePaths,[StringComparer]::Ordinal)
$manifest=foreach ($sourcePath in $sourcePaths) { $sourcePath+':'+(Get-FileHash -LiteralPath (Join-Path $projectRoot $sourcePath) -Algorithm SHA256).Hash }
$hasher=[Security.Cryptography.SHA256]::Create()
try { $sourceId=[BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($manifest -join "`n")))).Replace('-','') }
finally { $hasher.Dispose() }
$manifest | Set-Content -LiteralPath (Join-Path $batchRoot 'source_manifest.txt') -Encoding utf8
foreach ($profileId in $Profiles) {
 if ($profileId -notmatch '^[a-z0-9_]+$') { throw 'Invalid profile id.' }
 foreach ($route in @('fire','mobility','partners')) {
  foreach ($runSeed in $Seeds) {
   $runId=$profileId+'-'+$route+'-'+$runSeed
   $output=Join-Path $batchRoot $runId
   if (Test-Path -LiteralPath $output) { throw ('Preserved output exists; choose a new batch: '+$output) }
   $configPath=Join-Path $batchRoot ($runId+'-config.json')
   @{profile=('res://resources/roguelite/balance/'+$profileId+'.tres');output=$output;routes=@($route);seeds=@($runSeed);max_seconds=$MaxSeconds;source_id=$sourceId} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding utf8
   $outFile=Join-Path $batchRoot ($runId+'.out');$errFile=Join-Path $batchRoot ($runId+'.err')
   $arguments='--headless --fixed-fps 120 --disable-render-loop --path "'+$projectRoot+'" --script scripts/roguelite/evaluation/full_run_runner.gd -- "'+$configPath+'"'
   $run=Start-Process -FilePath $GodotExe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
   $log=(Get-Content -LiteralPath $outFile,$errFile -Raw) -join "`n"
   if ($run.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR|WARNING):' -or $log -notmatch 'NATURAL FULL RUN MATRIX COMPLETE') { throw ('Natural run failed validation: '+$runId) }
   $result=Get-Content -LiteralPath (Join-Path $output 'summary.json') -Raw | ConvertFrom-Json
   Write-Output ('NATURAL '+$runId+' '+$result.rows[0].outcome+' wave='+$result.rows[0].wave+' kills='+$result.rows[0].kills)
  }
 }
}
