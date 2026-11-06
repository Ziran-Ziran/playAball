extends Node
## 唯一跨场景音乐播放器；音源来自本机外置文件或已获准的工程资源。
signal mix_changed
signal track_changed
const SETTINGS_PATH: String = "user://ui_settings.cfg"
const MUSIC_BUS: StringName = &"Music"
var music_volume: float = 0.22
var muted: bool = false
var source_path: String = ""
var _player: AudioStreamPlayer
var _master_was_muted: bool = false
var _mute_applied: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var index: int = AudioServer.get_bus_index(MUSIC_BUS)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count-1
		AudioServer.set_bus_name(index,MUSIC_BUS)
		AudioServer.set_bus_send(index,&"Master")
	_player = AudioStreamPlayer.new()
	_player.name = "PersistentMusicPlayer"
	_player.bus = MUSIC_BUS
	add_child(_player)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	music_volume = clampf(float(config.get_value("audio","music_volume",0.22)),0.0,1.0)
	_apply_music_level()
	set_muted(bool(config.get_value("audio","muted",false)),false)
	get_tree().process_frame.connect(_start_default_track,CONNECT_ONE_SHOT)

func _start_default_track() -> void:
	# 等待应用进入正常事件循环；若调用者已显式选曲，不覆盖其音源。
	await get_tree().process_frame
	if is_instance_valid(_player) and _player.stream == null:
		reload_track()

func _candidates(directory: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var folder: String = directory
	if folder.is_empty():
		folder = OS.get_executable_path().get_base_dir().path_join("music") if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://music")
	for extension: String in ["mp3","ogg","wav"]:
		paths.append(folder.path_join("let_me_go."+extension))
	if directory.is_empty():
		for extension: String in ["mp3","ogg","wav"]:
			paths.append("res://assets/music/let_me_go."+extension)
	return paths

func _load_audio(path: String) -> AudioStream:
	if path.begins_with("res://"):
		var resource: Resource = load(path)
		return resource.duplicate() as AudioStream if resource is AudioStream else null
	match path.get_extension().to_lower():
		"mp3":
			var audio := AudioStreamMP3.new()
			audio.data = FileAccess.get_file_as_bytes(path)
			return audio if audio.get_length()>0.0 else null
		"ogg": return AudioStreamOggVorbis.load_from_file(path)
		"wav": return AudioStreamWAV.load_from_file(path)
	return null

func reload_track(directory: String = "") -> bool:
	for path: String in _candidates(directory):
		var exists: bool = ResourceLoader.exists(path) if path.begins_with("res://") else FileAccess.file_exists(path)
		if not exists: continue
		if path == source_path and _player.stream != null:
			if not _player.playing: _player.play()
			return true
		var stream: AudioStream = _load_audio(path)
		if stream == null: continue
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
		else:
			stream.set("loop",true)
		_player.stop()
		_player.stream = stream
		source_path = path
		_player.play()
		track_changed.emit()
		return true
	_player.stop()
	_player.stream = null
	source_path = ""
	track_changed.emit()
	return false

func _apply_music_level() -> void:
	var index: int = AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(music_volume,0.0001)))
	AudioServer.set_bus_mute(index,music_volume<=0.0)

func _save_mix() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio","music_volume",music_volume)
	config.set_value("audio","muted",muted)
	config.save(SETTINGS_PATH)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value,0.0,1.0)
	_apply_music_level()
	_save_mix()
	mix_changed.emit()

func set_muted(value: bool, persist: bool = true) -> void:
	muted = value
	if value and not _mute_applied:
		_master_was_muted = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0,true)
		_mute_applied = true
	elif not value and _mute_applied:
		AudioServer.set_bus_mute(0,_master_was_muted)
		_mute_applied = false
	if persist: _save_mix()
	mix_changed.emit()

func status_text() -> String:
	return "未载入音乐" if source_path.is_empty() else "Let Me Go（共创版） · 罐装毕加索"

func snapshot() -> Dictionary:
	return {"available":_player.stream!=null,"playing":_player.playing,"position":_player.get_playback_position(),"length":_player.stream.get_length() if _player.stream!=null else 0.0,"source":source_path,"music_volume":music_volume,"muted":muted,"player_id":_player.get_instance_id()}

func _exit_tree() -> void:
	# 退出时主动断开循环音源，不能只等Autoload子节点的默认析构。
	if is_instance_valid(_player):
		var had_stream: bool = _player.stream != null
		AudioServer.lock()
		_player.stop()
		_player.stream = null
		_player.free()
		_player = null
		AudioServer.unlock()
		# 给予混音线程短回收窗口；这不是所有设备上完成回收的保证。
		if had_stream:
			OS.delay_msec(50)
			AudioServer.lock()
			AudioServer.unlock()
