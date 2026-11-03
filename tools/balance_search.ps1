param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [string]$BatchName='e-control-r1',
    [string[]]$Profiles=@('baseline','control_030','control_060'),
    [int[]]$Seeds=@(42,20261103),
    [double]$Seconds=20,
    [switch]$Isolated,
    [string[]]$Scenarios=@('single','crowd','corner','reverse','relay','mechanisms'),
    [string[]]$BuildIds=@()
)
$ErrorActionPreference='Stop'
if ($BatchName -notmatch '^[a-z0-9_-]+$') { throw 'Invalid local batch name.' }
if ($Seconds -le 0 -or $Seconds -gt 120) { throw 'Fixture duration must be1–120 seconds.' }
if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) { throw 'Specify the verified local Godot4.7.1 executable.' }
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
    $resource=Join-Path $projectRoot ('resources/roguelite/balance/'+$profileId+'.tres')
    if (-not (Test-Path -LiteralPath $resource)) { throw ('Missing profile '+$profileId) }
    $output=Join-Path $batchRoot $profileId
    if (Test-Path -LiteralPath $output) { throw ('Output exists; select a new batch or profiles: '+$output) }
    $configPath=Join-Path $batchRoot ($profileId+'-config.json')
    $config=[ordered]@{profile=('res://resources/roguelite/balance/'+$profileId+'.tres');output=$output.Replace('\','/');scenarios=$Scenarios;strategies=@('nearest','safe','relay');seeds=$Seeds;seconds=$Seconds;source_id=$sourceId;build_ids=$BuildIds}
    $config | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding utf8
    if ($Isolated) {
        New-Item -ItemType Directory -Force -Path $output | Out-Null
        $rows=[Collections.Generic.List[object]]::new()
        foreach ($scenarioId in $config.scenarios) {
            foreach ($strategyId in $config.strategies) {
                foreach ($trialSeed in $Seeds) {
                    $trialId=$scenarioId+'-'+$strategyId+'-'+$trialSeed
                    $trialOutput=Join-Path $output $trialId
                    $trialConfig=[ordered]@{profile=$config.profile;output=$trialOutput.Replace('\','/');scenarios=@($scenarioId);strategies=@($strategyId);seeds=@($trialSeed);seconds=$Seconds;source_id=$sourceId;build_ids=$BuildIds}
                    $trialConfigPath=Join-Path $output ($trialId+'-config.json')
                    $trialConfig | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $trialConfigPath -Encoding utf8
                    $trialOut=Join-Path $output ($trialId+'.out')
                    $trialErr=Join-Path $output ($trialId+'.err')
                    $trialArguments='--headless --fixed-fps 120 --disable-render-loop --path "'+$projectRoot+'" --script scripts/roguelite/evaluation/scenario_runner.gd -- "'+$trialConfigPath+'"'
                    $trialProcess=Start-Process -FilePath $GodotExe -ArgumentList $trialArguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $trialOut -RedirectStandardError $trialErr
                    $trialLog=(Get-Content -LiteralPath $trialOut,$trialErr -Raw) -join "`n"
                    if ($trialProcess.ExitCode -ne 0 -or $trialLog -match '(?m)^(SCRIPT ERROR|ERROR|WARNING):' -or $trialLog -notmatch 'BALANCE MATRIX COMPLETE') { throw ('Isolated trial failed: '+$trialOutput) }
                    $data=Get-Content -LiteralPath (Join-Path $trialOutput 'summary.json') -Raw | ConvertFrom-Json
                    $rows.Add($data.rows[0])
                }
            }
        }
        @{config=$config;version=($rows[0].evaluation_version+'-isolated');isolated_process_per_trial=$true;rows=$rows.ToArray()} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
        Write-Output ('EVALUATED ISOLATED '+$profileId+' trials='+$rows.Count+' source='+$sourceId)
        continue
    }
    $outFile=Join-Path $batchRoot ($profileId+'.out')
    $errFile=Join-Path $batchRoot ($profileId+'.err')
    $arguments='--headless --fixed-fps 120 --disable-render-loop --path "'+$projectRoot+'" --script scripts/roguelite/evaluation/scenario_runner.gd -- "'+$configPath+'"'
    $evaluation=Start-Process -FilePath $GodotExe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $log=(Get-Content -LiteralPath $outFile,$errFile -Raw) -join "`n"
    if ($evaluation.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR|WARNING):' -or $log -notmatch 'BALANCE MATRIX COMPLETE') { throw ('Evaluation failed: '+$profileId+'. Inspect '+$batchRoot) }
    Write-Output ('EVALUATED '+$profileId+' source='+$sourceId+' result='+$output)
}
