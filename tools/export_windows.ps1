param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [string]$BuildName = 'planner-preview',
    [switch]$LiveTuning,
    [string]$Live2DRuntime,
    [string]$Live2DNotices
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
if ($Live2DRuntime) {
    if ($LiveTuning) { throw 'Live2D只用于正式菜单导出。' }
    $runtimeSource = (Resolve-Path -LiteralPath $Live2DRuntime).Path
    foreach ($required in @('model/runtime.model3.json','native/gd_cubism.gdextension','native/bin/libgd_cubism.windows.release.x86_64.dll','menu_profile.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $runtimeSource $required) -PathType Leaf)) { throw ('Live2D运行资源不完整：' + $required) }
    }
    # 只给副本增加接线autoload，源工程及原Live2D文件保持原字节。
    $settings = $settings.Replace('[autoload]', "[autoload]`n`nReleaseMenuPaths=""*res://scripts/ui/release_menu_paths.gd""")
    [IO.File]::WriteAllText((Join-Path $staging 'project.godot'), $settings, [Text.UTF8Encoding]::new($false))
    $runtimeTarget = Join-Path $output 'menu_character_runtime'
    New-Item -ItemType Directory -Force -Path $runtimeTarget | Out-Null
    foreach ($directory in @('model','native','textures')) { Copy-Item -LiteralPath (Join-Path $runtimeSource $directory) -Destination $runtimeTarget -Recurse }
    Copy-Item -LiteralPath (Join-Path $runtimeSource 'menu_profile.json') -Destination $runtimeTarget
    # preparation.json包含本机来源路径，不属于运行资源，不随包分发。
    $runtimeManifest = Get-ChildItem -LiteralPath $runtimeTarget -Recurse -File | Sort-Object FullName | ForEach-Object {
        [ordered]@{ path = $_.FullName.Substring($runtimeTarget.Length).TrimStart([char[]]'\/').Replace('\','/'); sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    }
    $runtimeManifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'live2d_manifest.json') -Encoding utf8
    if ($Live2DNotices) {
        Copy-Item -LiteralPath $Live2DNotices -Destination (Join-Path $output 'Live2D_Notices') -Recurse
    }
}
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
    live2d = [bool]$Live2DRuntime
    base_commit = $commit
    runtime_source_sha256 = $sourceHash
    exe_sha256 = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
    note = 'Release模板本地构建；源指纹是含导出过滤规则的暂存输入，实际包内容见package_manifest.json；不表示已上传渠道或完成人工平衡验收。'
}
$metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'build_info.json') -Encoding utf8
$notices = Join-Path $output 'Notices'
Invoke-GodotStep 'notices' ('--headless --path "' + $staging + '" --script "' + (Join-Path $projectRoot 'tools/release_notices.gd') + '" -- "' + $notices + '"')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts/zcool_kuaile/OFL.txt') -Destination (Join-Path $notices 'ZCOOL_OFL.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts/noto_sans_sc/OFL.txt') -Destination (Join-Path $notices 'Noto_OFL.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/ui/aim_kenney/KENNEY_PARTICLE_LICENSE.txt') -Destination (Join-Path $notices 'Kenney_CC0.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/music/SOURCE.md') -Destination (Join-Path $notices 'Music_Credits.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/playtest/RELEASE_CREDITS.md') -Destination (Join-Path $output 'CREDITS.md')
$readmeFile = if ($LiveTuning) { 'docs/playtest/PLANNER_README.txt' } else { 'docs/playtest/RELEASE_README.txt' }
Copy-Item -LiteralPath (Join-Path $projectRoot $readmeFile) -Destination (Join-Path $output '游玩说明.txt')
if ($LiveTuning) {
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/playtest/PLANNER_FEEDBACK.txt') -Destination (Join-Path $output '策略与成长反馈.txt')
}
$archive = $output + '.zip'
# 包含旁置目录；只压顶层文件会丢失Live2D模型及Native库。
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $output).FullName -DestinationPath $archive
Write-Output ('EXPORT READY: ' + $exePath)
Write-Output ('SHARE ZIP: ' + $archive)
Write-Output ('RUNTIME SOURCE SHA256: ' + $sourceHash)
