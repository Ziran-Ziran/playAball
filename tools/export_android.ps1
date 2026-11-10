param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [Parameter(Mandatory = $true)][string]$JavaSdkPath,
    [Parameter(Mandatory = $true)][string]$AndroidSdkPath,
    [string]$TemplatePath,
    [string]$BuildName = 'android-release',
    [switch]$Signed,
    [switch]$EmulatorX64
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ($BuildName -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]*$') { throw 'BuildName只允许字母、数字、下划线、连字符。' }
foreach ($path in @($GodotExe, (Join-Path $JavaSdkPath 'bin/java.exe'), (Join-Path $AndroidSdkPath 'build-tools/36.0.0/aapt2.exe'))) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw '引擎或JDK/SDK36工具缺失。' }
}
if (-not $TemplatePath) { $TemplatePath = Join-Path $env:APPDATA 'Godot/export_templates/4.7.1.stable/android_release.apk' }
if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) { throw '请指定已安装的4.7.1 Android release模板。' }
if ($Signed) {
    foreach ($name in @('GODOT_ANDROID_KEYSTORE_RELEASE_PATH','GODOT_ANDROID_KEYSTORE_RELEASE_USER','GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')) {
        if (-not [Environment]::GetEnvironmentVariable($name)) { throw ('签名缺少环境变量：' + $name) }
    }
}
$output = Join-Path $projectRoot ('builds/' + $BuildName)
if (Test-Path -LiteralPath $output) { throw '目标构建目录已存在，请更换BuildName。' }
$staging = Join-Path $projectRoot ('.local/android-export-' + [Guid]::NewGuid().ToString('N'))
$profileRoot = Join-Path $staging 'profile'
New-Item -ItemType Directory -Force $output,$staging,(Join-Path $profileRoot 'Godot') | Out-Null
[IO.File]::WriteAllText((Join-Path (Split-Path -Parent $output) '.gdignore'), '')
$originalAppData = $env:APPDATA
$originalJava = $env:JAVA_HOME
$globalSettings = Join-Path $originalAppData 'Godot/editor_settings-4.7.tres'
$settingsHash = if (Test-Path -LiteralPath $globalSettings) { (Get-FileHash -LiteralPath $globalSettings).Hash } else { '' }
function Invoke-Engine([string]$Name, [string]$Arguments) {
    $outFile = Join-Path $staging ($Name + '.out')
    $errFile = Join-Path $staging ($Name + '.err')
    $process = Start-Process -FilePath $GodotExe -ArgumentList $Arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $log = (Get-Content -LiteralPath $outFile,$errFile -Raw) -join "`n"
    if ($process.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR):') { throw ($Name + '失败；日志保留在.local暂存目录。') }
    if ($Name -eq 'version' -and $log.Trim() -notmatch '^4\.7\.1\.stable') { throw '固定使用Godot4.7.1 stable。' }
}
try {
    # 独立用户配置仅供子进程导出，路径不写回工程或用户全局EditorSettings。
    $env:APPDATA = $profileRoot
    $env:JAVA_HOME = (Resolve-Path -LiteralPath $JavaSdkPath).Path
    $jdk = $env:JAVA_HOME.Replace('\','/')
    $sdk = (Resolve-Path -LiteralPath $AndroidSdkPath).Path.Replace('\','/')
    $editorSettings = "[gd_resource type=`"EditorSettings`" format=3]`n`n[resource]`nexport/android/java_sdk_path = `"$jdk`"`nexport/android/android_sdk_path = `"$sdk`"`n"
    [IO.File]::WriteAllText((Join-Path $profileRoot 'Godot/editor_settings-4.7.tres'), $editorSettings)
    Invoke-Engine 'version' '--version'
    foreach ($directory in @('scripts','scenes','resources','assets')) { Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination $staging -Recurse }
    Copy-Item -LiteralPath (Join-Path $projectRoot 'project.godot') -Destination $staging
    $presets = Get-Content -LiteralPath (Join-Path $projectRoot 'export_presets.cfg') -Raw
    $exclusions = 'scenes/roguelite/*tuning*,scenes/roguelite/*lab*,scenes/roguelite/audio_preview*,scenes/main.tscn,scenes/ball.tscn,scenes/mechanism.tscn,scripts/roguelite/*tuning*,scripts/roguelite/gameplay_lab*,scripts/roguelite/audio_preview*,scripts/roguelite/lab/*,scripts/roguelite/evaluation/*,resources/roguelite/balance/*,assets/roguelite/presentation/*.json'
    $presets = [regex]::Replace($presets, '(?m)^exclude_filter="(.*)"$', { param($m) 'exclude_filter="' + (($m.Groups[1].Value,$exclusions | Where-Object { $_ }) -join ',') + '"' })
    if ($EmulatorX64) { $presets = $presets.Replace('architectures/x86_64=false','architectures/x86_64=true') }
    # 引擎先产未签名release，外部apksigner完成签名，避免把身份写入preset/日志。
    $template = (Resolve-Path -LiteralPath $TemplatePath).Path.Replace('\','/')
    $presets += "`ncustom_template/release=`"$template`"`n"
    [IO.File]::WriteAllText((Join-Path $staging 'export_presets.cfg'), $presets)
    $sourceFiles = [string[]](Get-ChildItem -LiteralPath $staging -Recurse -File | Where-Object { $_.FullName -notlike ($profileRoot + '*') } | ForEach-Object { $_.FullName })
    [Array]::Sort($sourceFiles,[StringComparer]::Ordinal)
    $fingerprints = foreach ($file in $sourceFiles) { $file.Substring($staging.Length).Replace('\','/') + ':' + (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash }
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { $sourceHash = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($fingerprints -join "`n")))).Replace('-','') } finally { $hasher.Dispose() }
    Invoke-Engine 'import' ('--headless --path "' + $staging + '" --editor --import')
    $apk = Join-Path $output 'PlayABall.apk'
    $unsignedApk = Join-Path $staging 'PlayABall-unsigned.apk'
    Invoke-Engine 'export' ('--headless --path "' + $staging + '" --export-release "Android Release" "' + $unsignedApk + '"')
    if ($Signed) {
        $signer = Join-Path $AndroidSdkPath 'build-tools/36.0.0/apksigner.bat'
        & $signer sign --ks $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH --ks-key-alias $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER --ks-pass env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD --out $apk $unsignedApk *> (Join-Path $staging 'sign.log')
        if ($LASTEXITCODE -ne 0) { throw '签名失败，检查本地签名日志。' }
        & $signer verify $apk *> (Join-Path $staging 'signature-verify.log')
        if ($LASTEXITCODE -ne 0) { throw 'APK签名验证失败。' }
    } else { Copy-Item -LiteralPath $unsignedApk -Destination $apk }
    # 解析真实APK，不以源preset代替ABI/Manifest验证。aapt1不支持模板部分属性。
    & (Join-Path $AndroidSdkPath 'build-tools/36.0.0/aapt2.exe') dump badging $apk *> (Join-Path $output 'android_manifest.txt')
    if ($LASTEXITCODE -ne 0) { throw 'APK Manifest检查失败。' }
    $manifest = Get-Content -LiteralPath (Join-Path $output 'android_manifest.txt') -Raw
    if ($manifest -notmatch "minSdkVersion:'24'" -or $manifest -notmatch "targetSdkVersion:'36'" -or $manifest -notmatch 'arm64-v8a' -or $manifest -notmatch 'armeabi-v7a') { throw 'APK SDK或ABI与发布要求不符。' }
    # APK把Godot资源放在assets/下；从实际包重封资源ZIP供同版引擎探针读取。
    # --path必须是空成品目录，防止源工程补齐包里漏掉的资源，造成假通过。
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $packPath = Join-Path $staging 'android-runtime.zip'
    $apkArchive = [IO.Compression.ZipFile]::OpenRead($apk)
    $runtimeArchive = [IO.Compression.ZipFile]::Open($packPath,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($entry in $apkArchive.Entries) {
            if (-not $entry.FullName.StartsWith('assets/') -or $entry.FullName.EndsWith('/')) { continue }
            $packEntry = $runtimeArchive.CreateEntry($entry.FullName.Substring(7),[IO.Compression.CompressionLevel]::NoCompression)
            $sourceStream = $entry.Open()
            $targetStream = $packEntry.Open()
            try { $sourceStream.CopyTo($targetStream) } finally { $sourceStream.Dispose(); $targetStream.Dispose() }
        }
    } finally { $apkArchive.Dispose(); $runtimeArchive.Dispose() }
    Invoke-Engine 'package_probe' ('--headless --path "' + $output + '" --main-pack "' + $packPath + '" --script "' + (Join-Path $projectRoot 'tools/package_probe.gd') + '" -- "' + (Join-Path $output 'package_manifest.json') + '"')
    if ((Get-Content -LiteralPath (Join-Path $staging 'package_probe.out') -Raw) -notmatch 'PACKAGE PROBE PASSED') { throw '未取得APK资源探针成功标志。' }
    [ordered]@{ build=$BuildName; engine='4.7.1.stable'; platform='Android Compatibility'; signed=[bool]$Signed; emulator_x64=[bool]$EmulatorX64; base_commit=(& git -C $projectRoot rev-parse HEAD).Trim(); runtime_source_sha256=$sourceHash; apk_sha256=(Get-FileHash -LiteralPath $apk).Hash; source_logs=$staging; note='本地release构建；模拟器验证不代表ARM真机性能验收。' } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'build_info.json') -Encoding utf8
    $notices = Join-Path $output 'Notices'
    Invoke-Engine 'notices' ('--headless --path "' + $staging + '" --script "' + (Join-Path $projectRoot 'tools/release_notices.gd') + '" -- "' + $notices + '"')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts/zcool_kuaile/OFL.txt') -Destination (Join-Path $notices 'ZCOOL_OFL.txt')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts/noto_sans_sc/OFL.txt') -Destination (Join-Path $notices 'Noto_OFL.txt')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/ui/aim_kenney/KENNEY_PARTICLE_LICENSE.txt') -Destination (Join-Path $notices 'Kenney_CC0.txt')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/music/SOURCE.md') -Destination (Join-Path $notices 'Music_Credits.md')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/playtest/RELEASE_CREDITS.md') -Destination (Join-Path $output 'CREDITS.md')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/playtest/RELEASE_README.txt') -Destination (Join-Path $output '游玩说明.txt')
    Write-Output ('ANDROID RELEASE READY: ' + $apk)
} finally {
    $env:APPDATA = $originalAppData
    $env:JAVA_HOME = $originalJava
    if ($settingsHash -and (Get-FileHash -LiteralPath $globalSettings).Hash -ne $settingsHash) { throw '用户全局编辑器配置变化，需要调查；脚本不主动写回。' }
}
