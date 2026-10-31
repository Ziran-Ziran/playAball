extends Node
## 机制只发事件；音频预算不能反向影响伤害或物理。
signal event_played(event: StringName, variant: int, volume_db: float)
@export var palette: Resource = preload("res://resources/roguelite/audio/default_palette.tres")
@export_range(1, 16) var max_voices: int = 8
@export_range(0.0, 1.0) var sfx_volume: float = 0.65
@export_range(0.0, 1.0) var ui_volume: float = 0.7
@export var muted: bool = false
var last_variant: Dictionary = {}
var _cooldowns: Dictionary = {}
var _voices: Array[Dictionary] = []
var _audio_paused: bool = false
var _rng := RandomNumberGenerator.new()
const UI_EVENTS: Array[StringName] = [&"upgrade", &"stage", &"victory", &"defeat"]
const KEY_EVENTS: Array[StringName] = [&"hurt", &"rice", &"upgrade", &"stage", &"victory", &"defeat"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	# 预热短样本，避免第一次碰撞时合成占用主线程。
	for event: StringName in palette.events:
		for variant in palette.variant_count(event):
			palette.stream_for(event, variant)

func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	for event: StringName in _cooldowns:
		_cooldowns[event] = maxf(0.0, float(_cooldowns[event]) - maxf(0.0, delta))

func play_event(event: StringName, intensity: float = 1.0) -> bool:
	if not event in palette.events or muted:
		return false
	var is_ui: bool = event in UI_EVENTS
	var level: float = ui_volume if is_ui else sfx_volume
	if level <= 0.0 or (_audio_paused and not is_ui) or float(_cooldowns.get(event, 0.0)) > 0.0:
		return false
	var priority: int = 2 if event in KEY_EVENTS else (1 if event == &"heavy" else 0)
	var ordinary_count: int = 0
	for voice in _voices:
		if voice.priority < 2:
			ordinary_count += 1
	if priority < 2 and ordinary_count >= maxi(1, max_voices - 2):
		var light_victim: int = -1
		for i in _voices.size():
			if int(_voices[i].priority) < priority:
				light_victim = i
				break
		if light_victim < 0:
			return false
		_stop_voice(light_victim)
	if _voices.size() >= max_voices:
		var victim: int = -1
		for i in _voices.size():
			if int(_voices[i].priority) < priority:
				victim = i
				break
		if victim < 0:
			return false
		_stop_voice(victim)
	var count: int = palette.variant_count(event)
	var previous: int = int(last_variant.get(event, -1))
	var variant: int = _rng.randi_range(0, count - 2) if previous >= 0 and count > 1 else _rng.randi_range(0, count - 1)
	if previous >= 0 and variant >= previous:
		variant += 1
	last_variant[event] = variant
	_cooldowns[event] = 0.10 if priority < 2 else 0.12
	# 关键提示出现时压低既有碰撞；密集声部再做能量补偿，保留混音余量。
	if priority > 0:
		for voice in _voices:
			if int(voice.priority) < priority:
				voice.duck_db = -9.0 if priority == 2 else -5.0
				voice.player.volume_db = float(voice.base_db) + float(voice.duck_db) + linear_to_db(maxf(0.0001, sfx_volume))
	var attenuation: float = (3.0 if priority == 0 else 1.5) * float(_voices.size()) if priority < 2 else 0.0
	var base_db: float = (-15.0 if priority == 0 else (-10.0 if priority == 1 else -11.0)) - attenuation + linear_to_db(clampf(intensity, 0.25, 1.0))
	var db: float = base_db + linear_to_db(level)
	var player := AudioStreamPlayer.new()
	player.stream = palette.stream_for(event, variant)
	player.volume_db = db
	player.pitch_scale = _rng.randf_range(0.98, 1.02)
	add_child(player)
	_voices.append({"player": player, "priority": priority, "is_ui": is_ui, "base_db": base_db, "duck_db": 0.0})
	player.finished.connect(_on_finished.bind(player))
	player.play()
	event_played.emit(event, variant, db)
	return true

func _on_finished(player: AudioStreamPlayer) -> void:
	for i in range(_voices.size() - 1, -1, -1):
		if _voices[i].player == player:
			_voices.remove_at(i)
	player.queue_free()

func _stop_voice(index: int) -> void:
	var player: AudioStreamPlayer = _voices[index].player
	player.stop()
	player.stream = null
	_voices.remove_at(index)
	player.queue_free()

func active_voice_count() -> int:
	return _voices.size()

func set_mix(sfx: float, ui: float, is_muted: bool = false) -> void:
	sfx_volume = clampf(sfx, 0.0, 1.0)
	ui_volume = clampf(ui, 0.0, 1.0)
	muted = is_muted
	if muted:
		_clear_voices()
	else:
		# 现存声部也响应音量，避免拖到零后尾音仍响。
		for voice in _voices:
			var level: float = ui_volume if voice.is_ui else sfx_volume
			voice.player.volume_db = float(voice.base_db) + float(voice.duck_db) + linear_to_db(maxf(0.0001, level))

func _clear_voices() -> void:
	while not _voices.is_empty():
		_stop_voice(_voices.size() - 1)

func set_audio_paused(value: bool) -> void:
	if value != _audio_paused:
		for i in range(_voices.size() - 1, -1, -1):
			if not _voices[i].is_ui:
				_stop_voice(i)
	_audio_paused = value

func reset_audio() -> void:
	_clear_voices()
	_cooldowns.clear()
	last_variant.clear()
	_audio_paused = false

func _exit_tree() -> void:
	# 退出时先停止后端播放，清掉记录中的引用；子节点由树正常释放。
	for voice in _voices:
		var player: AudioStreamPlayer = voice.player
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_voices.clear()
