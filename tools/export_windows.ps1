param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [string]$BuildName = 'planner-preview',
    [switch]$LiveTuning
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ($BuildName -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]*$') {
    throw 'BuildName只允许字母、数字、下划线和连字符。'
}
if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) { throw 'Godot路径不存在。' }
$taskId = [Guid]::NewGuid().ToString('N')
$staging = Join-Path $projectRoot ('.local/export-' + $taskId)
$output = Join-Path $projectRoot ('builds/' + $BuildName)
if (Test-Path -LiteralPath $output) { throw '目标构建目录已存在，请换一个BuildName，避免覆盖已交付版本。' }
New-Item -ItemType Directory -Path $staging,$output -Force | Out-Null
# 成品目录不属于源资源；防止编辑器导入多份旁置模型并报告重复UID。
$buildIgnore = Join-Path (Split-Path -Parent $output) '.gdignore'
if (-not (Test-Path -LiteralPath $buildIgnore)) { [IO.File]::WriteAllText($buildIgnore, '') }

function Invoke-GodotStep([string]$Name, [string]$Arguments) {
    $outFile = Join-Path $staging ($Name + '.out')
    $errFile = Join-Path $staging ($Name + '.err')
    $process = Start-Process -FilePath $GodotExe -ArgumentList $Arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $log = (Get-Content -LiteralPath $outFile,$errFile -Raw -Encoding UTF8) -join "`n"
    Write-Output $log
    if ($process.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR):') { throw ($Name + '失败，日志保留在.local导出暂存目录。') }
    if ($Name -eq 'version' -and $log.Trim() -notmatch '^4\.7\.1\.stable') { throw '团队固定Godot4.7.1 stable。' }
}
Invoke-GodotStep 'version' '--version'

# 单独复制运行资源；不把测试、文档、个人配置或原编辑器差异写回工程。
foreach ($directory in @('scripts','scenes','resources','assets')) {
    $source = Join-Path $projectRoot $directory
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $staging -Recurse }
}
$settingsPath = Join-Path $projectRoot 'project.godot'
$originalSettingsHash = (Get-FileHash -LiteralPath $settingsPath -Algorithm SHA256).Hash
$settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
if ([regex]::Matches($settings, '(?m)^run/main_scene=.*$').Count -ne 1) { throw '无法唯一识别主场景配置。' }
$entryScene = if ($LiveTuning) { 'res://scenes/roguelite/tuning_run.tscn' } else { 'res://scenes/ui/main_menu.tscn' }
$settings = [regex]::Replace($settings, '(?m)^run/main_scene=.*$', ('run/main_scene="' + $entryScene + '"'))
[IO.File]::WriteAllText((Join-Path $staging 'project.godot'), $settings, [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $projectRoot 'export_presets.cfg') -Destination $staging
if (-not $LiveTuning) {
    # 正式包保留动态加载的玩法资源，但不携带调参/评估入口或生成提示词个人路径。
    $presetPath = Join-Path $staging 'export_presets.cfg'
    $presets = Get-Content -LiteralPath $presetPath -Raw -Encoding UTF8
    $exclusions = 'scenes/roguelite/*tuning*,scenes/roguelite/*lab*,scenes/roguelite/audio_preview*,scenes/main.tscn,scenes/ball.tscn,scenes/mechanism.tscn,scripts/roguelite/*tuning*,scripts/roguelite/gameplay_lab*,scripts/roguelite/audio_preview*,scripts/roguelite/lab/*,scripts/roguelite/evaluation/*,resources/roguelite/balance/*,assets/roguelite/presentation/*.json'
    $presets = [regex]::Replace($presets, '(?m)^exclude_filter="(.*)"$', { param($match) 'exclude_filter="' + (($match.Groups[1].Value,$exclusions | Where-Object { $_ }) -join ',') + '"' })
    [IO.File]::WriteAllText($presetPath, $presets, [Text.UTF8Encoding]::new($false))
}

# Ordinal排序避免不同PowerShell/系统区域设置把同一资源集算成不同指纹。
$sourceFiles = [string[]](Get-ChildItem -LiteralPath $staging -File -Recurse | Where-Object { $_.Extension -in @('.gd','.tscn','.tres','.godot','.png','.ico','.svg','.wav','.ogg','.mp3','.ttf','.otf','.import','.uid','.cfg','.json') } | ForEach-Object { $_.FullName })
[Array]::Sort($sourceFiles, [StringComparer]::Ordinal)
$fingerprintLines = foreach ($filePath in $sourceFiles) {
    $relative = $filePath.Substring($staging.Length).TrimStart([char[]]'\/').Replace('\','/')
    $relative + ':' + (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
}
$fingerprintBytes = [Text.Encoding]::UTF8.GetBytes(($fingerprintLines -join "`n"))
$hasher = [Security.Cryptography.SHA256]::Create()
try { $sourceHash = [BitConverter]::ToString($hasher.ComputeHash($fingerprintBytes)).Replace('-','') }
finally { $hasher.Dispose() }

Invoke-GodotStep 'import' ('--headless --path "' + $staging + '" --editor --import')
$exePath = Join-Path $output 'PlayABall.exe'
Invoke-GodotStep 'export' ('--headless --path "' + $staging + '" --export-release "Windows Planner" "' + $exePath + '"')
if (-not (Test-Path -LiteralPath $exePath) -or (Get-Item -LiteralPath $exePath).Length -lt 1000000) { throw '未生成有效的Windows可执行文件。' }
if (-not $LiveTuning) {
    $probeOut = Join-Path $staging 'package_probe.out'
    $probeErr = Join-Path $staging 'package_probe.err'
    $probePath = Join-Path $projectRoot 'tools/package_probe.gd'
    $manifestPath = Join-Path $output 'package_manifest.json'
    # 标准发布模板禁用外部脚本覆盖；用同版编辑器引擎读取EXE内嵌包。
    # 此检查验证实际包资源；发布模板窗口输入另做原生UI验证。
    $probe = Start-Process -FilePath $GodotExe -ArgumentList ('--headless --path "' + $output + '" --main-pack "' + $exePath + '" --script "' + $probePath + '" -- "' + $manifestPath + '"') -WorkingDirectory $output -WindowStyle Hidden -PassThru -RedirectStandardOutput $probeOut -RedirectStandardError $probeErr
    if (-not $probe.WaitForExit(40000)) { $probe.Kill(); throw '内嵌包探针超时，保留日志。' }
    $probe.Refresh()
    $probeLog = (Get-Content -LiteralPath $probeOut,$probeErr -Raw) -join "`n"
    Write-Output $probeLog
    if ($probe.ExitCode -ne 0 -or $probeLog -match '(?m)^(SCRIPT ERROR|ERROR|WARNING):' -or $probeLog -notmatch 'PACKAGE PROBE PASSED') { throw '导出资源包检查失败，暂不生成交付zip。' }
}
if ((Get-FileHash -LiteralPath $settingsPath -Algorithm SHA256).Hash -ne $originalSettingsHash) { throw '原工程配置发生变化，请检查，脚本未主动写回。' }
$commit = (& git -C $projectRoot rev-parse HEAD).Trim()
$metadata = [ordered]@{
    build = $BuildName
    engine = '4.7.1.stable'
    platform = 'Windows x86_64 Compatibility'
    scene = $entryScene
    live_tuning = [bool]$LiveTuning
    base_commit = $commit
    runtime_source_sha256 = $sourceHash
    exe_sha256 = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
    note = '本地游戏预览，包含本轮未提交资源；源指纹是含导出过滤规则的暂存输入，实际包内容见package_manifest.json。'
}
$metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'build_info.json') -Encoding utf8
$readmeFile = if ($LiveTuning) { 'docs/playtest/PLANNER_README.txt' } else { 'docs/playtest/OVERNIGHT_README.txt' }
Copy-Item -LiteralPath (Join-Path $projectRoot $readmeFile) -Destination (Join-Path $output '试玩说明.txt')
$feedbackFile = if ($LiveTuning) { 'docs/playtest/PLANNER_FEEDBACK.txt' } else { 'docs/playtest/OVERNIGHT_FEEDBACK.txt' }
Copy-Item -LiteralPath (Join-Path $projectRoot $feedbackFile) -Destination (Join-Path $output '策略与成长反馈.txt')
$archive = $output + '.zip'
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $output -File).FullName -DestinationPath $archive
Write-Output ('EXPORT READY: ' + $exePath)
Write-Output ('SHARE ZIP: ' + $archive)
Write-Output ('RUNTIME SOURCE SHA256: ' + $sourceHash)
