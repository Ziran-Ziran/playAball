extends "res://scripts/roguelite/run_arena.gd"
## 发布用外壳：沿用完整run规则，将开发控件留给原run/实验室/调参入口。
var _pause_button: BaseButton
var _reward_progress: TextureProgressBar
var _wallet_icon: TextureRect
var _health_skin: Control
var _cancel_button: Button
var mobile_controls: bool = OS.has_feature("android")
var _safe_layout: Rect2

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
	_wallet_icon = coin
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
	home.name = "Home"
	home.text = "返回主菜单"
	home.pressed.connect(return_to_menu)
	$HUD/Menu/Buttons.add_child(home)
	menu.position = Vector2(340, 85)
	menu.size = Vector2(600, 550)
	for option_name in ["Mute", "Shake", "Split"]:
		var original := $HUD/Controls.get_node(option_name) as BaseButton
		var option := CheckButton.new()
		option.name = option_name
		option.text = original.text
		option.button_pressed = original.button_pressed
		option.toggled.connect(func(value: bool): original.button_pressed = value)
		$HUD/Menu/Buttons.add_child(option)
	var buttons: VBoxContainer = $HUD/Menu/Buttons
	buttons.add_theme_constant_override("separation", 6)
	$HUD/Menu/Buttons/Title.text = "暂停航行"
	$HUD/Menu/Buttons/Title.add_theme_font_size_override("font_size", 26)
	for action_name: String in ["Resume", "Reset"]:
		buttons.get_node(action_name).custom_minimum_size.y = 40
	$HUD/Menu/Buttons/Resume.text = "继续航行  ·  Esc"
	$HUD/Menu/Buttons/Reset.text = "重新开局"
	home.custom_minimum_size.y = 40
	OceanUi.section(buttons, "声音与体验  /  战场已冻结")
	buttons.move_child(buttons.get_child(buttons.get_child_count()-1), 4)
	for kind: String in ["音效", "提示", "音乐"]:
		OceanUi.volume_row(buttons, kind, MusicManager.music_volume if kind == "音乐" else (sfx_volume if kind == "音效" else ui_volume), func(value: float):
			if kind == "音乐": MusicManager.set_music_volume(value)
			elif kind == "音效": sfx_volume = value
			else: ui_volume = value
			sync_audio_mix()
		, "MusicVolume" if kind == "音乐" else "Volume")
	for child: Node in buttons.get_children():
		if child is BaseButton:
			OceanUi.bind_button(child)
	OceanUi.primary($HUD/Menu/Buttons/Resume)
	var scrim := ColorRect.new()
	scrim.name = "PauseScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.01, 0.025, 0.05, 0.8)
	scrim.visible = menu.visible
	$HUD.add_child(scrim)
	$HUD.move_child(scrim, menu.get_index())
	menu.visibility_changed.connect(func():
		scrim.visible = menu.visible
		if menu.visible: OceanUi.reveal(menu)
	)
	MusicManager.mix_changed.connect(_sync_music_pause_controls)
	var health_skin := Control.new()
	_health_skin = health_skin
	health_skin.set_script(load("res://scripts/ui/health_skin.gd"))
	health_skin.source = $RunHUD.health_view
	$RunHUD/Overlay.add_child(health_skin)
	$RunHUD/Overlay/PlayerPanel.hide()
	_layout_pause_columns()
	_cancel_button = Button.new()
	_cancel_button.name = "CancelAim"
	_cancel_button.text = "取消瞄准"
	_cancel_button.position = Vector2(1070, 616)
	_cancel_button.size = Vector2(168, 60)
	_cancel_button.pressed.connect(cancel_pointer_gesture)
	OceanUi.bind_button(_cancel_button)
	$HUD.add_child(_cancel_button)
	if mobile_controls:
		_pause_button.size = Vector2(80, 60)
		$HUD/Menu/Buttons/Resume.text = "继续航行"
		$HUD/Hint.text = "空白处单指向后拖动\n松手发射 · 取消键撤销\n暂停键 / 系统返回暂停"
	get_viewport().size_changed.connect(_apply_safe_layout)
	_apply_safe_layout()
	# 面板皮肤由各弹窗统一管理，避免父场景覆盖内容流和九宫格边距。

func _layout_pause_columns() -> void:
	var previous: VBoxContainer = $HUD/Menu/Buttons
	previous.name = "PreviousButtons"
	var grid := GridContainer.new()
	grid.name = "Buttons"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 12)
	menu.add_child(grid)
	var heading: Label = previous.get_node("Title")
	heading.reparent(grid)
	grid.add_child(OceanUi.label("声音与体验", 16, Color("586d99")))
	# 保留原按钮对象和Buttons/Resume等路径；物理暂停、重开与请求信号不重接。
	for pair: Array in [["Resume", "Mute"], ["Reset", "Shake"], ["Home", "Split"]]:
		for key: String in pair:
			var button: Control = previous.get_node(key)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size.x = 300
			button.reparent(grid)
	var character_note := Control.new()
	character_note.custom_minimum_size = Vector2(300, 136)
	character_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(character_note)
	var portrait := Control.new()
	portrait.name = "WhaleMaidPortrait"
	portrait.set_script(load("res://scripts/ui/ocean_motion.gd"))
	portrait.set("is_badge", true)
	portrait.set("is_portrait", true)
	character_note.add_child(portrait)
	portrait.size = Vector2(96, 130)
	var note := OceanUi.label("歇一会儿，\n再去大闹一场。", 17, Color("5c6e91"))
	note.position = Vector2(112, 32)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_note.add_child(note)
	var volumes := VBoxContainer.new()
	volumes.name = "Volumes"
	volumes.add_theme_constant_override("separation", 10)
	grid.add_child(volumes)
	for child: Node in previous.get_children():
		if child is HBoxContainer:
			child.reparent(volumes)
	menu.remove_child(previous)
	previous.queue_free()
	menu.size = Vector2(820, 440)

func _sync_music_pause_controls() -> void:
	$HUD/Menu/Buttons/Mute.set_pressed_no_signal(MusicManager.muted)
	for slider: HSlider in menu.find_children("MusicVolume", "HSlider", true, false):
		slider.set_value_no_signal(MusicManager.music_volume)

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(director):
		var modal_open: bool = menu.visible or director.hud.panel.visible or director.rest_panel.visible
		# 世界HUD不越过模态弹窗；弹窗关闭后恢复同一份真实读数。
		for item: CanvasItem in [status, _wallet_icon, _pause_button, _reward_progress, _health_skin]:
			item.visible = not modal_open
		_cancel_button.visible = mobile_controls and launcher.input_held and not modal_open
		$HUD/Hint.visible = not modal_open and director.wave==1 and launcher.shots==0 and director.state==director.State.BATTLE and not launcher.aiming
		if is_instance_valid(_reward_progress):
			_reward_progress.max_value = director.rewards.next_target()
			_reward_progress.value = director.rewards.progress

func return_to_menu() -> void:
	launcher.cancel()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func over_controls(point: Vector2) -> bool:
	# 隐藏的开发栏没有热区，正式暂停按钮独占释放手势。
	return touch_cancel_at(point) or (is_instance_valid(_pause_button) and _pause_button.is_visible_in_tree() and _pause_button.get_global_rect().has_point(point)) or (menu.visible and menu.get_global_rect().has_point(point))

func touch_cancel_at(point: Vector2) -> bool:
	return is_instance_valid(_cancel_button) and _cancel_button.is_visible_in_tree() and _cancel_button.get_global_rect().has_point(point)

func battle_status_text() -> String:
	if not is_instance_valid(director):
		return "准备航行"
	return "阶段 %d / 3  ·  第 %s 波\n金币 %d  ·  成长 %d / %d" % [director.flow.stage_number(director.wave), str(director.wave) if director.wave < 6 else "首领", director.wallet.balance, director.rewards.progress, director.rewards.next_target()]

func logical_safe_rect(display_rect: Rect2, screen_transform: Transform2D) -> Rect2:
	# 操作区映射到固定逻辑画布；世界/刚体与屏幕震动均不参与布局计算。
	return (screen_transform.affine_inverse() * display_rect).intersection(Rect2(0,0,1280,720))

func _apply_safe_layout() -> void:
	if not is_instance_valid(_cancel_button):
		return
	var safe := Rect2(0,0,1280,720)
	if OS.has_feature("android"):
		safe = logical_safe_rect(Rect2(DisplayServer.get_display_safe_area()), get_viewport().get_screen_transform())
	if safe.size.x < 900 or safe.size.y < 500:
		return
	_safe_layout = safe
	_pause_button.position = Vector2(minf(1190,safe.end.x-_pause_button.size.x-16),maxf(20,safe.position.y+8))
	_cancel_button.position = Vector2(minf(1070,safe.end.x-184),minf(616,safe.end.y-76))
	_health_skin.position = Vector2(maxf(0,safe.position.x),maxf(0,safe.position.y))
	status.position = Vector2(minf(850,safe.end.x-430),maxf(16,safe.position.y+8))
	_wallet_icon.position = status.position+Vector2(-32,32)
	_reward_progress.position = status.position+Vector2(0,68)
	menu.position = safe.get_center()-menu.size*0.5

func _draw() -> void:
	# 正式外壳隐藏试验场网格，但与试验场共享瞄准和回弹表现。
	_draw_aim_feedback()
