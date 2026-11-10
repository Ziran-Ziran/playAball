extends SceneTree
var checks: int = 0
var failures: int = 0
var _had_settings: bool
var _settings: PackedByteArray

func _initialize() -> void:
	run.call_deferred()
	create_timer(35, true).timeout.connect(func(): finish(1))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames() -> void:
	for tick in 6: await process_frame

func run() -> void:
	_had_settings = FileAccess.file_exists("user://ui_settings.cfg")
	if _had_settings: _settings = FileAccess.get_file_as_bytes("user://ui_settings.cfg")
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1024,576)]:
		root.size = resolution
		menu.show_settings()
		await frames()
		check(root.get_visible_rect().encloses(menu.settings_panel.get_global_rect()), "Settings stays inside viewport at " + str(resolution))
		check(menu.get_node("Start").disabled and menu.get_node("SettingsScrim").visible, "Modal blocks underlying actions")
		var badge: Control = menu.settings_panel.get_node("Columns/CharacterColumn/WhaleMaidPortrait")
		check(menu.settings_panel.get_global_rect().encloses(badge.get_global_rect()), "DS whale-maid illustration stays in its allocated column")
		check(badge.is_portrait and badge._atlas.resource_path.ends_with("ds_console/ds_maid_frames.png"), "Every fish-related UI portrait uses the DS whale-maid atlas")
		menu.close_settings()
		check(not menu.get_node("SettingsScrim").visible and not menu.get_node("Start").disabled, "Closing restores menu input")
	menu._master_slider.value = 0.46
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.46)), "Master slider changes actual audio mix")
	check(menu._master_slider.get_parent().get_node("Percent").text == "46%", "Volume label follows real value")
	menu.apply_reduced_motion(false)
	menu.show_settings()
	var moving_badge: Control = menu.settings_panel.get_node("Columns/CharacterColumn/WhaleMaidPortrait")
	moving_badge.elapsed = 2.1
	await create_timer(0.18, true).timeout
	check(moving_badge.frame_index > 0, "Normal mode plays generated animation frames")
	menu.apply_reduced_motion(true)
	menu.show_settings()
	await frames()
	check(menu.settings_panel.get_node("Columns/CharacterColumn/WhaleMaidPortrait").frame_index == 0, "Reduced motion freezes generated frames")
	check(menu.settings_panel.modulate.a == 1.0, "Reduced motion opens panel immediately")
	menu.close_settings()
	menu.queue_free()
	await frames()
	# 首次死亡前可能没有选过卡，不能依靠show_choices顺带清掉旧深色override。
	var fresh_hud = load("res://scenes/roguelite/run_hud.tscn").instantiate()
	root.add_child(fresh_hud)
	fresh_hud.show_result(false, 0, 0)
	await frames()
	check(fresh_hud.panel.get_theme_stylebox("panel") is StyleBoxTexture, "First result uses the chosen light theme before any reward")
	check(fresh_hud.result_body.defeats.text == "0" and fresh_hud.result_body.relay.text == "0", "Zero-result statistics remain truthful")
	fresh_hud.queue_free()
	await frames()
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	game.director.set_process(false)
	await frames()
	var hud_text: Color = game.get_node("RunHUD/Overlay/HealthSkin")._hp.get_theme_color("font_color")
	check(hud_text.r + hud_text.g + hud_text.b > 2.0, "Light modal theme does not darken text on the dark combat HUD")
	for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1024,576)]:
		root.size = resolution
		game.set_paused(true)
		await frames()
		check(root.get_visible_rect().encloses(game.menu.get_global_rect()), "Pause stays inside viewport at " + str(resolution))
		check(game.get_node("HUD/PauseScrim").visible and paused, "Pause dims and freezes battle")
		check(not game.status.visible and not game._wallet_icon.visible, "World HUD cannot paint over pause panel")
		game.set_paused(false)
		await frames()
		check(game.status.visible and game._wallet_icon.visible, "Closing modal restores actual world HUD")
		check(not game.get_node("HUD/PauseScrim").visible, "Resume clears scrim")
	game.director.hud.show_choices([load("res://resources/roguelite/upgrades/companion.tres")], {}, 1, 42)
	await frames()
	var card: Button = game.director.hud.cards.get_child(0)
	check(not card.disabled and card.scale == Vector2.ONE and card.modulate.a == 1, "Reduced motion makes reward immediately usable")
	var flow: Control = card.get_child(card.get_child_count()-1)
	check(flow.clock == 0.0, "Reduced motion stops card shimmer")
	var choices: Array = []
	for id: String in ["companion", "relay", "explosion", "glide"]:
		choices.append(load("res://resources/roguelite/upgrades/%s.tres" % id))
	game.director.hud.show_choices(choices, {}, 1, 43)
	await frames()
	for entry: Control in game.director.hud.cards.get_children():
		check(game.director.hud.panel.get_global_rect().encloses(entry.get_global_rect()), "Four-card content respects generated frame padding")
		check(root.get_visible_rect().encloses(entry.get_global_rect()), "Four-card row remains inside small viewport")
	var catalog: Array = []
	for filename: String in DirAccess.get_files_at("res://resources/roguelite/upgrades"):
		if filename.ends_with(".tres"):
			catalog.append(load("res://resources/roguelite/upgrades/" + filename))
	for start: int in range(0, catalog.size(), 4):
		game.director.hud.show_choices(catalog.slice(start, start + 4), {}, 1, 44 + start)
		await frames()
		for entry: Control in game.director.hud.cards.get_children():
			for key: String in ["Preview", "Detail", "Flavor"]:
				var text: Label = entry.get_node("Content/" + key)
				check(text.position.y + text.get_minimum_size().y <= entry.size.y - 18.0, "Narrow four-card text remains inside: " + str(entry.get_meta("upgrade_id")) + "/" + key)
	var growth_width: float = game.director.hud.panel.size.x
	for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1024,576)]:
		root.size = resolution
		for won: bool in [true, false]:
			game.director.hud.show_result(won, 42, 6)
			await frames()
			var result: DsResultBody = game.director.hud.result_body
			check(root.get_visible_rect().encloses(game.director.hud.panel.get_global_rect()), "Illustrated result stays within viewport")
			check(result.defeats.text == "42" and result.relay.text == "6", "Record cards show actual supplied counts")
			check(result.portrait.texture.resource_path.ends_with("result_victory.png" if won else "result_retry.png"), "Result uses the matching DS expression")
			check(result.get_global_rect().end.y <= game.director.hud.result_actions.get_global_rect().position.y, "Result artwork and navigation do not overlap")
			check(game.director.hud.restart_button.has_focus(), "Result remains keyboard accessible")
	# 同帧切换后，旧结算的延迟测高不能反过来挤窄新的成长面板。
	game.director.hud.show_result(false, 1, 1)
	game.director.hud.show_choices(choices, {}, 1, 99)
	await frames()
	check(not game.director.hud.result_body.visible and not game.director.hud.result_actions.visible, "Switching to growth clears the result-only view")
	check(is_equal_approx(game.director.hud.panel.size.x, growth_width), "Deferred result layout cannot overwrite small-window growth width")
	game.director.hud.close()
	game.queue_free()
	paused = false
	await frames()
	print("OCEAN UI CHECKS: %d checks, %d failures" % [checks, failures])
	finish(0 if failures == 0 else 1)

func finish(code: int) -> void:
	if _had_settings:
		var file := FileAccess.open("user://ui_settings.cfg", FileAccess.WRITE)
		file.store_buffer(_settings)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ui_settings.cfg"))
	quit(code)
