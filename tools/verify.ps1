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
}
Write-Output 'VERIFIED: import + smoke'
