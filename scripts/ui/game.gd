extends "res://scripts/roguelite/run_arena.gd"
## 发布用外壳：沿用完整run规则，将开发控件留给原run/实验室/调参入口。
var _pause_button: BaseButton
var _reward_progress: TextureProgressBar

func _ready() -> void:
	super._ready()
	if DisplayServer.get_name()!="headless":get_window().title="玩个球 / playAball"
	$RunHUD.menu_requested.connect(return_to_menu)
	var arena_skin := Node2D.new()
	arena_skin.name = "ArenaSkin"
	arena_skin.set_script(load("res://scripts/ui/arena_skin.gd"))
	add_child(arena_skin)
	for path in ["BottomBoundary/Visual", "LeftRamp/Visual", "RightRamp/Visual"]:
		get_node(path).hide()
	$HUD/Controls.hide()
	# 顶栏空位提供首次手势说明，不覆盖战斗区域，也不创建鼠标热区。
	$HUD/Hint.position = Vector2(475,14)
	$HUD/Hint.size = Vector2(320,80)
	$HUD/Hint.text = "空白处按住左键，向后拖动\n松开即可发射 · 右键取消\nEsc 暂停"
	$HUD/Hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$HUD/Hint.add_theme_font_size_override("font_size",18)
	$HUD/Hint.modulate = Color("a4c5bd")
	$HUD/Hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.position = Vector2(850, 16)
	status.add_theme_font_size_override("font_size", 20)
	var pause_button := TextureButton.new()
	_pause_button = pause_button
	var hud_art: Texture2D = load("res://assets/ui/health_skin.png")
	var pause_art := AtlasTexture.new()
	pause_art.atlas = hud_art
	pause_art.region = Rect2(1560,55,74,74)
	pause_button.texture_normal = pause_art
	pause_button.ignore_texture_size = true
	pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	pause_button.tooltip_text = "暂停"
	pause_button.position = Vector2(1190, 20)
	pause_button.size = Vector2(70, 40)
	pause_button.pressed.connect(func(): set_paused(true))
	$HUD.add_child(pause_button)
	var coin := TextureRect.new()
	var coin_art := AtlasTexture.new()
	coin_art.atlas = hud_art
	coin_art.region = Rect2(1414,63,63,63)
	coin.texture = coin_art
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.position = Vector2(818, 48)
	coin.size = Vector2(27, 27)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(coin)
	_reward_progress = TextureProgressBar.new()
	_reward_progress.position = Vector2(850, 84)
	_reward_progress.size = Vector2(310, 12)
	_reward_progress.nine_patch_stretch = true
	_reward_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for part in ["fill", "background"]:
		var strip := AtlasTexture.new()
		strip.atlas = hud_art
		strip.region = Rect2(1200 if part == "fill" else 1450, 145, 60, 12)
		if part == "fill": _reward_progress.texture_progress = strip
		else: _reward_progress.texture_under = strip
	$HUD.add_child(_reward_progress)
	var home := Button.new()
	home.text = "返回主菜单"
	home.pressed.connect(return_to_menu)
	$HUD/Menu/Buttons.add_child(home)
	menu.position = Vector2(370, 115)
	menu.size = Vector2(540, 520)
	for option_name in ["Mute", "Shake", "Split"]:
		var original := $HUD/Controls.get_node(option_name) as BaseButton
		var option := CheckButton.new()
		option.name = option_name
		option.text = original.text
		option.button_pressed = original.button_pressed
		option.toggled.connect(func(value: bool): original.button_pressed = value)
		$HUD/Menu/Buttons.add_child(option)
	for kind in ["音效", "提示"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = kind
		row.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(260, 30)
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = sfx_volume if kind == "音效" else ui_volume
		slider.value_changed.connect(func(value: float):
			if kind == "音效": sfx_volume = value
			else: ui_volume = value
			sync_audio_mix()
		)
		row.add_child(slider)
		$HUD/Menu/Buttons.add_child(row)
	var health_skin := Control.new()
	health_skin.set_script(load("res://scripts/ui/health_skin.gd"))
	health_skin.source = $RunHUD.health_view
	$RunHUD/Overlay.add_child(health_skin)
	$RunHUD/Overlay/PlayerPanel.hide()
	var panel_style := StyleBoxTexture.new()
	var panel_atlas := AtlasTexture.new()
	panel_atlas.atlas = load("res://assets/ui/panel_base.png")
	panel_atlas.region = Rect2(28,112,1480,792)
	panel_style.texture = panel_atlas
	panel_style.set_content_margin_all(32)
	menu.add_theme_stylebox_override("panel", panel_style)
	$RunHUD.panel.add_theme_stylebox_override("panel", panel_style)
	director.rest_panel.get_node("Backdrop/Panel").add_theme_stylebox_override("panel", panel_style)

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(director):
		$HUD/Hint.visible = director.wave==1 and launcher.shots==0 and director.state==director.State.BATTLE and not launcher.aiming
		status.text = "阶段 %d / 3  ·  第 %s 波\n金币 %d  ·  成长 %d / %d" % [director.flow.stage_number(director.wave), str(director.wave) if director.wave < 6 else "首领", director.wallet.balance, director.rewards.progress, director.rewards.next_target()]
		if is_instance_valid(_reward_progress):
			_reward_progress.max_value = director.rewards.next_target()
			_reward_progress.value = director.rewards.progress

func return_to_menu() -> void:
	launcher.cancel()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func over_controls(point: Vector2) -> bool:
	# 隐藏的开发栏没有热区，正式暂停按钮独占释放手势。
	return (is_instance_valid(_pause_button) and _pause_button.is_visible_in_tree() and _pause_button.get_global_rect().has_point(point)) or (menu.visible and menu.get_global_rect().has_point(point))

func _draw() -> void:
	# 只替换网格和墙体，真实手势瞄准属于玩家反馈，必须保留。
	if not is_instance_valid(launcher) or not launcher.aiming:
		return
	var drag: Vector2 = (launcher.anchor - launcher.pointer).limit_length(player.max_drag)
	var world_drag: Vector2 = get_global_transform_with_canvas().affine_inverse().basis_xform(drag)
	var end: Vector2 = player.position + world_drag
	draw_line(player.position, end, Color("fff1ad"), 4, true)
	if drag.length() >= 8:
		draw_line(end, end - drag.normalized().rotated(0.5) * 18, Color("fff1ad"), 4, true)
		draw_line(end, end - drag.normalized().rotated(-0.5) * 18, Color("fff1ad"), 4, true)
