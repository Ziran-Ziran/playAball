extends Node
## F6直接试听原创音组；数字单听，Space重放完整比较，M静音。
const DIRECTOR = preload("res://scripts/roguelite/audio_director.gd")
var audio: Node
var label: Label
var _generation: int = 0
var _muted: bool = false
var _events: Array[StringName] = [&"light", &"heavy", &"kill", &"hurt", &"rice", &"upgrade", &"stage", &"victory", &"defeat", &"launch"]
var _names: Array[String] = ["轻碰", "重撞", "击杀", "玩家受伤", "白饭拾取", "升级确认", "阶段完成", "胜利", "失败", "冲量发射"]
func _ready() -> void:
	audio = DIRECTOR.new()
	add_child(audio)
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	label.position = Vector2(60, 70)
	label.add_theme_font_size_override("font_size", 24)
	layer.add_child(label)
	_show("准备试听")
	_sequence()
func _show(now: String) -> void:
	label.text = "玩个球 · 音效试听\n\n1轻碰  2重撞  3击杀  4受伤  5白饭\n6升级  7阶段  8胜利  9失败  0发射\nSpace完整序列；M静音；Esc退出\n\n当前：%s\nSFX 65%% / UI 70%%\n\n观察：轻重音色、受伤辨识、密集叠加是否刺耳。" % now
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	elif event.keycode == KEY_SPACE:
		_sequence()
	elif event.keycode == KEY_M:
		_muted = not _muted
		audio.set_mix(0.65, 0.7, _muted)
		_show("静音" if _muted else "取消静音")
	elif event.keycode >= KEY_0 and event.keycode <= KEY_9:
		_generation += 1
		audio.reset_audio()
		var index: int = 9 if event.keycode == KEY_0 else event.keycode - KEY_1
		audio.play_event(_events[index])
		_show(_names[index])
func _sequence() -> void:
	_generation += 1
	var generation: int = _generation
	audio.reset_audio()
	for i in _events.size():
		if generation != _generation:
			return
		_show(_names[i])
		audio.play_event(_events[i])
		await get_tree().create_timer(1.2).timeout
	_show("10秒密集连锁，中途包含受伤和奖励")
	for i in 100:
		if generation != _generation:
			return
		audio.play_event(&"light", 0.7)
		audio.play_event(&"heavy", 0.85)
		if i % 5 == 0:
			audio.play_event(&"kill", 0.65)
		if i == 30:
			audio.play_event(&"hurt")
		if i == 70:
			audio.play_event(&"upgrade")
		await get_tree().create_timer(0.1).timeout
	_show("试听结束，可用数字重复比较")
