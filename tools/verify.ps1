param([string]$GodotExe = $env:GODOT_EXE)
$ErrorActionPreference = 'Stop'
if (-not $GodotExe) {
    $godotCommand = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($godotCommand) { $GodotExe = $godotCommand.Source }
}
if (-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw '请使用 -GodotExe 指定本机 Godot 4.7.1 可执行文件的实际绝对路径。'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $projectRoot '.local'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
foreach ($step in @(
    @{ Name = 'version'; Arguments = '--version' },
    @{ Name = 'import'; Arguments = '--headless --path "' + $projectRoot + '" --editor --import' },
    @{ Name = 'map'; Arguments = '--headless --path "' + $projectRoot + '" --script tools/project_map.gd -- --check' },
    @{ Name = 'roguelite'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_smoke.gd' },
    @{ Name = 'input_feedback'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_input_feedback.gd' },
    @{ Name = 'enemies'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_enemies.gd' },
    @{ Name = 'build'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_build.gd' },
    @{ Name = 'boss'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_boss.gd' },
    @{ Name = 'run'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_run.gd' },
    @{ Name = 'rice'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_rice.gd' },
    @{ Name = 'theme'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/roguelite_theme.gd' },
    @{ Name = 'smoke'; Arguments = '--headless --path "' + $projectRoot + '" --script tests/smoke.gd' }
)) {
    $outFile = Join-Path $logDirectory ($step.Name + '.out')
    $errFile = Join-Path $logDirectory ($step.Name + '.err')
    $godotProcess = Start-Process -FilePath $GodotExe -ArgumentList $step.Arguments -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $logText = (Get-Content -LiteralPath $outFile,$errFile -Raw) -join "`n"
    Write-Output $logText
    if ($godotProcess.ExitCode -ne 0 -or $logText -match '(?m)^(SCRIPT ERROR|ERROR):') {
        throw ($step.Name + ' 检查失败，请检查 .local 中的日志。')
    }
    if ($step.Name -eq 'version' -and $logText.Trim() -notmatch '^4\.7\.1\.stable') {
        throw '团队统一使用 Godot 4.7.1 stable。'
    }
    if ($step.Name -eq 'smoke' -and $logText -notmatch 'ALL CHECKS PASSED') {
        throw '未获得测试完成标志。'
    }
    if ($step.Name -eq 'roguelite' -and $logText -notmatch 'ROGUELITE CHECKS PASSED') {
        throw '未获得肉鸽测试完成标志。'
    }
    if ($step.Name -eq 'input_feedback' -and $logText -notmatch 'INPUT FEEDBACK CHECKS PASSED') {
        throw '未获得输入与反馈回归测试完成标志。'
    }
    $completionMarkers = @{ enemies = 'ENEMY CHECKS PASSED'; build = 'BUILD CHECKS PASSED'; boss = 'ROGUELITE BOSS: \d+ checks, 0 failures'; run = 'RUN CHECKS PASSED'; rice = 'RICE CHECKS PASSED'; theme = 'ROGUELITE THEME: \d+ checks, 0 failures' }
    if ($completionMarkers.ContainsKey($step.Name) -and $logText -notmatch $completionMarkers[$step.Name]) {
        throw ($step.Name + ' 未获得测试完成标志。')
    }
    if ($step.Name -eq 'map' -and $logText -notmatch 'PROJECT MAP CHECK PASSED') {
        throw '未获得目录检查完成标志。'
    }
}
Write-Output 'VERIFIED: import + map + roguelite + input + enemies + build + boss + run + rice + theme + smoke'
