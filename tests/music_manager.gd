extends SceneTree
var checks: int = 0
var failures: int = 0
var manager: Node
var had_settings: bool = false
var settings_bytes: PackedByteArray
var master_db: float
var master_mute: bool
var music_db: float
var music_mute: bool
var original_mix: Dictionary
var done: bool = false
const FIXTURE: String = "res://.local/music_test_fixture"
func _initialize() -> void:
	call_deferred("run")
	create_timer(35.0,true).timeout.connect(func(): check(false,"bounded music test timeout"); finish())
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func frames(count: int) -> void:
	for index in count: await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/music_"+name+".png")
func run() -> void:
	if "--small" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i.ZERO
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.size = Vector2i(1024,576)
	manager = root.get_node_or_null("MusicManager")
	check(manager!=null,"persistent MusicManager autoload exists")
	if manager==null: quit(1); return
	had_settings = FileAccess.file_exists("user://ui_settings.cfg")
	if had_settings: settings_bytes = FileAccess.get_file_as_bytes("user://ui_settings.cfg")
	master_db = AudioServer.get_bus_volume_db(0)
	master_mute = AudioServer.is_bus_mute(0)
	var bus: int = AudioServer.get_bus_index(&"Music")
	music_db = AudioServer.get_bus_volume_db(bus)
	music_mute = AudioServer.is_bus_mute(bus)
	original_mix = manager.snapshot()
	manager.set_muted(false)
	AudioServer.set_bus_mute(0,false)
	AudioServer.set_bus_volume_db(0,-6.0)
	manager.set_music_volume(0.22)
	var config := ConfigFile.new()
	config.load("user://ui_settings.cfg")
	config.set_value("visual","music_test_sentinel",37)
	config.save("user://ui_settings.cfg")
	manager.set_music_volume(0.31)
	config.load("user://ui_settings.cfg")
	check(is_equal_approx(float(config.get_value("audio","music_volume",-1)),0.31) and int(config.get_value("visual","music_test_sentinel",0))==37,"music volume persists without overwriting unrelated visual settings")
	manager.set_muted(true)
	check(AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_db(0),-6.0),"all mute suppresses Master without changing its volume")
	manager.set_muted(false)
	check(not AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_db(0),-6.0),"unmute preserves prior Master gain")
	AudioServer.set_bus_mute(0,true)
	manager.set_muted(true)
	manager.set_muted(false)
	check(AudioServer.is_bus_mute(0),"unmute preserves an externally pre-muted Master")
	AudioServer.set_bus_mute(0,false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE))
	var fixture := AudioStreamWAV.new()
	fixture.format = AudioStreamWAV.FORMAT_16_BITS
	fixture.mix_rate = 44100
	var data := PackedByteArray()
	for sample in 5292:
		var value: int = roundi(sin(sample*TAU*440.0/44100.0)*1800.0)
		data.append(value & 255)
		data.append((value >> 8) & 255)
	fixture.data = data
	check(fixture.save_to_wav(FIXTURE.path_join("let_me_go.wav"))==OK,"temporary 0.12 second WAV fixture prepared outside production assets")
	check(manager.reload_track(ProjectSettings.globalize_path(FIXTURE)),"external WAV fixture loads")
	var player_id: int = int(manager.snapshot().player_id)
	check(manager.get_child_count()==1,"manager owns one audio player only")
	await create_timer(0.45,true).timeout
	check(manager.snapshot().playing and manager.snapshot().position<0.18,"short WAV remains playing after multiple real loop durations")
	check(not manager.reload_track(ProjectSettings.globalize_path(FIXTURE.path_join("missing"))) and not manager.snapshot().available and manager.status_text()=="未载入音乐","missing track stays silent with truthful friendly status")
	check(manager.reload_track(),"production user-supplied MP3 loads after fixture")
	check(manager.snapshot().length>120.0 and manager.snapshot().source.ends_with("let_me_go.mp3"),"actual user track decodes to expected full duration")
	manager.set_music_volume(0.22)
	var peak: float = -200.0
	for sample in 15:
		await create_timer(0.05,true).timeout
		peak = maxf(peak,AudioServer.get_bus_peak_volume_left_db(bus,0))
	if DisplayServer.get_name()!="headless": check(peak > -120.0,"actual MP3 produces non-silent Music bus samples")
	print("ACTUAL MP3 ",manager.snapshot()," peak_db=",peak)
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(8)
	menu.show_settings()
	await frames(3)
	check(root.get_visible_rect().encloses(menu.settings_panel.get_global_rect()),"menu music controls fit visible viewport")
	await capture("settings")
	menu.close_settings()
	var before: float = float(manager.snapshot().position)
	menu.start_game()
	await frames(6)
	check(current_scene.name=="Game" and int(manager.snapshot().player_id)==player_id and manager.snapshot().position>=before,"menu to Game preserves singleton player and playback position")
	var game = current_scene
	game.set_paused(true)
	await frames(3)
	check(root.get_visible_rect().encloses(game.menu.get_global_rect()),"pause music row fits full viewport")
	await capture("pause")
	before = float(manager.snapshot().position)
	await create_timer(0.2,true).timeout
	check(manager.snapshot().playing and manager.snapshot().position>before,"music keeps progressing during real gameplay pause")
	manager.set_muted(true)
	check(game.audio.muted and not game.feedback.sound_enabled and AudioServer.is_bus_mute(0),"all mute suppresses both actual game SFX and music")
	manager.set_muted(false)
	game.set_paused(false)
	game.launcher.request_aim(Vector2(800,350))
	check(paused,"aim actually freezes battle")
	before = float(manager.snapshot().position)
	await create_timer(0.2,true).timeout
	check(manager.snapshot().position>before,"aim never interrupts or freezes music")
	game.launcher.cancel()
	before = float(manager.snapshot().position)
	game.return_to_menu()
	await frames(6)
	check(current_scene.name=="MainMenu" and int(manager.snapshot().player_id)==player_id and manager.snapshot().position>=before,"return to menu preserves same live track")
	# 重复第二轮，随后发出全局设置事件，旧场景必须已断开持久信号。
	current_scene.start_game()
	await frames(6)
	manager.set_music_volume(0.27)
	manager.set_muted(true)
	manager.set_muted(false)
	check(current_scene.name=="Game" and int(manager.snapshot().player_id)==player_id,"second scene cycle still owns only original player")
	current_scene.return_to_menu()
	await frames(6)
	manager.set_music_volume(0.22)
	manager.set_muted(true)
	manager.set_muted(false)
	check(manager.mix_changed.get_connections().size()==1 and manager.track_changed.get_connections().size()==1,"second return has only live menu signal subscriptions")
	current_scene.queue_free()
	current_scene = null
	await frames(8)
	check(manager.mix_changed.get_connections().is_empty() and manager.track_changed.get_connections().is_empty(),"all scene callbacks disconnect when final scene is freed")
	finish()
func finish() -> void:
	if done: return
	done = true
	paused = false
	if manager!=null and not original_mix.is_empty():
		manager.set_music_volume(float(original_mix.music_volume))
		manager.set_muted(bool(original_mix.muted),false)
		manager.reload_track()
		AudioServer.set_bus_volume_db(0,master_db)
		AudioServer.set_bus_mute(0,master_mute)
		var bus: int = AudioServer.get_bus_index(&"Music")
		AudioServer.set_bus_volume_db(bus,music_db)
		AudioServer.set_bus_mute(bus,music_mute)
		if had_settings:
			var file: FileAccess = FileAccess.open("user://ui_settings.cfg",FileAccess.WRITE)
			file.store_buffer(settings_bytes)
			file.close()
		elif FileAccess.file_exists("user://ui_settings.cfg"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ui_settings.cfg"))
		check(FileAccess.get_file_as_bytes("user://ui_settings.cfg")==settings_bytes if had_settings else not FileAccess.file_exists("user://ui_settings.cfg"),"test restores original settings bytes exactly")
		check(AudioServer.get_bus_volume_db(0)==master_db and AudioServer.is_bus_mute(0)==master_mute and AudioServer.get_bus_volume_db(bus)==music_db and AudioServer.is_bus_mute(bus)==music_mute,"test restores Master and Music bus gain and mute")
	print("MUSIC CHECKS ",checks," failures ",failures)
	quit(1 if failures else 0)
