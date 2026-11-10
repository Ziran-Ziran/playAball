extends SceneTree

func _initialize() -> void:
	call_deferred("check_game")
	create_timer(15).timeout.connect(func(): quit(1))

func check_game() -> void:
	root.size = Vector2i(1280, 720)
	if not ResourceLoader.exists("res://scenes/ui/main_menu.tscn"):
		push_error("UI integration: main menu missing")
		quit(1)
		return
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	assert(menu.get_node("Start") is TextureButton)
	menu.show_settings()
	assert(menu.get_node("Start").disabled)
	assert(menu.get_node("Exit").disabled)
	menu.close_settings()
	assert(not menu.get_node("Start").disabled)
	mouse(Vector2(330, 425), true)
	await process_frame
	mouse(Vector2(330, 425), false)
	await process_frame
	await process_frame
	assert(current_scene.name == "Game")
	var game = current_scene
	if not game.has_node("ArenaSkin") or not game.get_node("RunHUD/Overlay").has_node("HealthSkin"):
		push_error("Approved arena and segmented health art are not installed")
		quit(1)
		return
	assert(not game.get_node("HUD/Controls").visible)
	assert(not game.has_node("LiveTuning"))
	assert(not game.over_controls(Vector2(350, 100)))
	assert(game.over_controls(Vector2(1210, 35)))
	assert(game.get_node("HUD/Menu/Buttons/Split") is CheckButton)
	game.get_node("HUD/Menu/Buttons/Split").button_pressed = true
	assert(game.director.split_enabled)
	game.get_node("HUD/Menu/Buttons/Split").button_pressed = false
	assert(game.director.health.hp == 5)
	var launch_hint: Label = game.get_node("HUD/Hint")
	assert(launch_hint.visible and launch_hint.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(launch_hint.get_global_rect().end.y<125 and launch_hint.position.x>=475)
	# 提示文字本身也是空白手势区域，不得成为隐形按钮。
	mouse(Vector2(600,55),true)
	await process_frame
	await process_frame
	assert(game.launcher.input_held and not launch_hint.visible)
	mouse(Vector2(720,55),false)
	await process_frame
	await process_frame
	assert(game.launcher.shots==1 and not launch_hint.visible)
	game.reset_range()
	await process_frame
	await process_frame
	assert(launch_hint.visible)
	# 从原隐藏控件所在区域发射，再验证在正式暂停按钮上释放会取消。
	mouse(Vector2(350, 100), true)
	await process_frame
	assert(game.launcher.input_held)
	mouse(Vector2(450, 100), false)
	await process_frame
	assert(game.launcher.shots == 1)
	game.launcher.reset_launch()
	mouse(Vector2(350, 100), true)
	await process_frame
	mouse(Vector2(1210, 35), false)
	await process_frame
	assert(game.launcher.shots == 0)
	game.director.health.hurt(1)
	await process_frame
	assert(game.get_node("RunHUD").health_snapshot().hp == 4)
	await process_frame
	var health_skin = game.get_node("RunHUD/Overlay/HealthSkin")
	assert(health_skin._count == 5)
	assert(health_skin._clips[4].size.x == 0)
	assert(health_skin._hp.text == "4 / 5")
	game.director.health.max_hp = 8
	game.director.health.hp = 8
	game.director.health.changed.emit(8)
	await process_frame
	await process_frame
	assert(health_skin._count == 8 and health_skin._hp.text == "8 / 8")
	var hud = game.get_node("RunHUD")
	var choices: Array = []
	for id in ["heal", "companion", "cooldown", "heavy"]:
		choices.append(load("res://resources/roguelite/upgrades/" + id + ".tres"))
	hud.show_choices(choices)
	assert(hud.cards.get_child_count() == 4)
	assert(hud.cards.get_child(2).get_node("Content/Preview").text.contains("2.20 → 1.95"))
	# 正式卡框已采用可编辑实色边框，固定分隔位图会再次穿过内容流。
	assert(hud.cards.get_child(0).get_theme_stylebox("normal") is StyleBoxFlat)
	assert(hud.cards.get_child(0).disabled)
	await create_timer(0.85).timeout
	assert(not hud.cards.get_child(3).disabled)
	# 检查真实字体排版后的最小尺寸，而非只验证文案字符串存在。
	var all_ids: Array[String] = ["launch_power","glide","cooldown","double_launch","heavy","echo","bowling","explosion","companion","follow","relay","shrink","pulse","heal","choices","vigor"]
	for batch in 4:
		var group: Array = []
		for slot in 4:
			var id: String = all_ids[batch*4+slot]
			if id == "vigor":
				group.append(game.director.build.fallback)
			else:
				group.append(load("res://resources/roguelite/upgrades/%s.tres"%id))
		hud.show_choices(group)
		await process_frame
		await process_frame
		for card in hud.cards.get_children():
			var heading: Label = card.get_node("Content/Heading")
			var preview: Label = card.get_node("Content/Preview")
			var detail: Label = card.get_node("Content/Detail")
			var illustration: TextureRect = card.get_node("Content/Illustration")
			var level: Label = card.get_node("Content/Level")
			var flavor: Label = card.get_node("Content/Flavor")
			print("CARD_LAYOUT: ", heading.text.replace("\n", " / "), " heights=", heading.get_minimum_size().y, ",", preview.get_minimum_size().y, ",", detail.get_minimum_size().y)
			assert(illustration.texture != null)
			assert(heading.position.y+heading.get_minimum_size().y <= illustration.position.y)
			assert(illustration.position.y+illustration.size.y <= level.position.y)
			assert(level.position.y+level.get_minimum_size().y <= preview.position.y)
			assert(preview.position.y+preview.get_minimum_size().y <= detail.position.y)
			assert(detail.position.y+detail.get_minimum_size().y <= flavor.position.y)
			assert(flavor.position.y+flavor.get_minimum_size().y < card.size.y-10.0)
	# 模拟另一平台的较高字体行距，标题仍应完整显示且不压到插画。
	var tall_heading: Label = hud.cards.get_child(0).get_node("Content/Heading")
	tall_heading.add_theme_constant_override("line_spacing", 8)
	await process_frame
	hud.cards.get_child(0)._layout()
	assert(tall_heading.position.y + tall_heading.get_minimum_size().y <= hud.cards.get_child(0).get_node("Content/Illustration").position.y)
	hud.clear_cards()
	game.set_paused(true)
	game.reset_range()
	assert(not paused)
	assert(game.director.health.hp == 5)
	game.director.debug_wave(6)
	await process_frame
	await process_frame
	assert(not launch_hint.visible and game.director.boss.get_node("Presentation/Status").visible)
	game.reset_range()
	await process_frame
	await process_frame
	game.director.finish(true)
	await process_frame
	await process_frame
	assert(not launch_hint.visible)
	await process_frame
	# 人物化结算按真实内容测高；检查视口边界与内容，避免锁死旧纯文字框尺寸。
	assert(root.get_visible_rect().encloses(hud.panel.get_global_rect()))
	assert(hud.result_body.visible and hud.result_actions.visible)
	assert(hud.result_body.get_global_rect().end.y <= hud.result_actions.get_global_rect().position.y)
	assert(hud.home_button.visible)
	hud.home_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.has_node("Start") and not paused)
	current_scene.queue_free()
	# 等待音频混音线程释放最后一段WAV播放引用，避免进程退出时误报泄漏。
	await create_timer(0.1).timeout
	print("UI INTEGRATION CHECKS PASSED")
	quit(0)

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
