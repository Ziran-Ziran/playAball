param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [string]$BuildName = 'planner-preview'
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
$settings = [regex]::Replace($settings, '(?m)^run/main_scene=.*$', 'run/main_scene="res://scenes/roguelite/run.tscn"')
[IO.File]::WriteAllText((Join-Path $staging 'project.godot'), $settings, [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $projectRoot 'export_presets.cfg') -Destination $staging

# Ordinal排序避免不同PowerShell/系统区域设置把同一资源集算成不同指纹。
$sourceFiles = [string[]](Get-ChildItem -LiteralPath $staging -File -Recurse | Where-Object { $_.Extension -in @('.gd','.tscn','.tres','.godot','.png','.svg','.wav','.ogg','.ttf','.otf','.import','.uid','.cfg') } | ForEach-Object { $_.FullName })
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
if ((Get-FileHash -LiteralPath $settingsPath -Algorithm SHA256).Hash -ne $originalSettingsHash) { throw '原工程配置发生变化，请检查，脚本未主动写回。' }
$commit = (& git -C $projectRoot rev-parse HEAD).Trim()
$metadata = [ordered]@{
    build = $BuildName
    engine = '4.7.1.stable'
    platform = 'Windows x86_64 Compatibility'
    scene = 'res://scenes/roguelite/run.tscn'
    base_commit = $commit
    runtime_source_sha256 = $sourceHash
    exe_sha256 = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
    note = '策划功能预览，可能包含尚未提交的运行资源；以runtime_source_sha256区分。'
}
$metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'build_info.json') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/playtest/PLANNER_README.txt') -Destination (Join-Path $output '试玩说明.txt')
$archive = $output + '.zip'
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $output -File).FullName -DestinationPath $archive
Write-Output ('EXPORT READY: ' + $exePath)
Write-Output ('SHARE ZIP: ' + $archive)
Write-Output ('RUNTIME SOURCE SHA256: ' + $sourceHash)
