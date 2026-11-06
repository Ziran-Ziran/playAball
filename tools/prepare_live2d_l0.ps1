param([ValidatePattern('^[a-z0-9_]+$')][string]$FixtureName = 'fixture')
$ErrorActionPreference = 'Stop'
# 所有实验文件留在忽略目录；现有不同内容拒绝覆盖，避免丢失本地实验。
$repoRoot = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path $repoRoot ('.local/art_audio_r2/' + $FixtureName)
New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$files = @{}
$files['project.godot'] = @'
config_version=5

[application]
config/name="PlayABall L0 isolated preflight"
run/main_scene="res://preflight.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]
window/size/viewport_width=640
window/size/viewport_height=360

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"

'@
$files['preflight.gd'] = @'
extends Node2D
## 只验证真实图形/导出基线，不将缺少模型的结果冒充Live2D通过。
func _ready() -> void:
	queue_redraw()
	for index: int in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output: String = "user://l0_preflight.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output = argument.trim_prefix("--out=")
	var capture: Image = get_viewport().get_texture().get_image()
	var png_result: Error = capture.save_png(output.trim_suffix(".json") + ".png")
	var data: Dictionary = {
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"display": DisplayServer.get_name(),
		"editor_binary": OS.has_feature("editor"),
		"capture_size": [capture.get_width(), capture.get_height()],
		"capture_result": png_result,
		"bridge_class_available": ClassDB.class_exists("GDCubismUserModel"),
		"live2d_tested": false,
		"scope": "engine/export baseline only; awaiting licensed SDK/Core and test model"
	}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write evidence: " + output)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print(JSON.stringify(data))
	get_tree().quit(0 if png_result == OK else 1)

func _draw() -> void:
	for y: int in 6:
		for x: int in 10:
			var shade: float = 0.16 if (x + y) % 2 == 0 else 0.3
			draw_rect(Rect2(x * 64, y * 60, 64, 60), Color(shade, shade, shade))

'@
$files['preflight.tscn'] = @'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://preflight.gd" id="1"]
[node name="Preflight" type="Node2D"]
script = ExtResource("1")

'@
$files['export_presets.cfg'] = @'
[preset.0]
name="Windows L0"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="../export/l0_preflight.exe"

[preset.0.options]
binary_format/architecture="x86_64"
binary_format/embed_pck=true

'@
foreach ($name in $files.Keys) {
    $target = Join-Path $fixtureRoot $name
    $content = $files[$name].Replace("`r`n", "`n").TrimEnd() + "`n"
    if (Test-Path -LiteralPath $target) {
        $existing = [System.IO.File]::ReadAllText($target).Replace("`r`n", "`n").TrimEnd() + "`n"
        if ($existing -ne $content) { throw "Refusing to overwrite differing file: $target" }
    } else { [System.IO.File]::WriteAllText($target, $content, $utf8) }
}
Write-Output "Prepared engine/export baseline only: $fixtureRoot"
Write-Output 'No Live2D SDK, model, plugin, license acceptance, or download performed.'
