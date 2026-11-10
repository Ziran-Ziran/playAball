extends Control
## 主菜单只负责导航和音量；正式战斗、奖励、物理仍由既有玩法校验。
const ART := "res://assets/ui/"
var _music_slider: HSlider
var _music_status: Label
var _all_mute: CheckButton
var interaction_status: Label
var _settings_scrim: ColorRect
var _master_slider: HSlider
var settings_panel: PanelContainer
var credits_panel: Control
@onready var character_view: Control = $MenuCharacter

func picture(file: String, bounds: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(ART + file + ".png")
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.position = bounds.position
	node.size = bounds.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func action(node_name: String, file: String, bounds: Rect2, callback: Callable) -> void:
	var button := TextureButton.new()
	button.name = node_name
	var source: Texture2D = load(ART + file + ".png")
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	# 裁去生成图上下透明边距，保持可见按钮比例；不修改源素材。
	atlas.region = Rect2(0, source.get_height() * 0.17, source.get_width(), source.get_height() * 0.66)
	button.texture_normal = atlas
	button.texture_focused = atlas
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = bounds.position
	button.size = bounds.size
	# 透明边距不应成为可点击的隐形按钮。
	var mask := BitMap.new()
	mask.create_from_image_alpha(button.texture_normal.get_image(), 0.2)
	button.texture_click_mask = mask
	button.tooltip_text = {"Start": "开始游戏", "Settings": "设置", "Exit": "退出"}[node_name]
	OceanUi.bind_button(button)
	button.pressed.connect(callback)
	add_child(button)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	font.fallbacks = [preload("res://resources/ui/body_fallback.tres")]
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 22
	picture("ds_console/menu_room", Rect2(0, 0, 1280, 720))
	picture("fat_fish_menu_title", Rect2(64, 94, 576, 230))
	# 角色组件在背景之后、按钮/设置之前，透明区域不挡导航。
	move_child(character_view,get_child_count()-1)
	action("Start", "fat_fish_start_button_full", Rect2(102, 367, 461, 115), start_game)
	action("Settings", "fat_fish_settings_button_full", Rect2(102, 504, 223, 101), show_settings)
	action("Exit", "fat_fish_exit_button_full", Rect2(340, 504, 223, 101), func(): get_tree().quit())
	_build_settings()
	if character_view.character.loaded:
		var hint := Label.new()
		hint.text = "头顶：点头笑 · 左脸：眨眼歪头 · 右脸：鼓脸摇头"
		hint.position = Vector2(76,610)
		hint.add_theme_font_size_override("font_size",14)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hint)
		var gesture_hint := Label.new()
		gesture_hint.text = "上半身：鞠躬招呼 · 三连点：惊讶 · 抚摸头发：轻摆"
		gesture_hint.position = Vector2(76,638)
		gesture_hint.add_theme_font_size_override("font_size",14)
		gesture_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(gesture_hint)
		interaction_status = Label.new()
		interaction_status.name = "InteractionStatus"
		interaction_status.position = Vector2(76,666)
		interaction_status.add_theme_font_size_override("font_size",14)
		interaction_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(interaction_status)
		character_view.character.reaction_started.connect(func(kind: String):
			interaction_status.text = {"pet":"点头微笑","pet_sway":"跟着抚摸轻摆","wink":"向左歪头眨眼","cheek":"鼓脸轻摇头","greet":"鞠躬招呼","surprised":"轻轻后仰：哎呀！","shy":"害羞歪头"}.get(kind,"回应你")
		)
		character_view.character.reaction_rejected.connect(func(reason: String): interaction_status.text = reason)
		character_view.character.reaction_finished.connect(func(): _update_interaction_status())
		_update_interaction_status()
		var credits := Label.new()
		credits.text = "角色：神宫凉子  ·  Live2D：霓虹猫_NeonNeko"
		credits.position = Vector2(76,696)
		credits.add_theme_font_size_override("font_size",11)
		credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(credits)
		move_child(settings_panel,get_child_count()-1)

func _build_settings() -> void:
	_settings_scrim = ColorRect.new()
	_settings_scrim.name = "SettingsScrim"
	_settings_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_scrim.color = Color(0.015, 0.035, 0.07, 0.8)
	_settings_scrim.z_index = 20
	add_child(_settings_scrim)
	_settings_scrim.hide()
	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.z_index = 21
	settings_panel.size = Vector2(880, 500)
	OceanUi.apply(settings_panel)
	add_child(settings_panel)
	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.add_theme_constant_override("separation", 32)
	settings_panel.add_child(columns)
	var character_column := Control.new()
	character_column.name = "CharacterColumn"
	character_column.custom_minimum_size = Vector2(220, 420)
	columns.add_child(character_column)
	var portrait := Control.new()
	portrait.name = "WhaleMaidPortrait"
	portrait.set_script(load("res://scripts/ui/ocean_motion.gd"))
	portrait.set("is_badge", true)
	portrait.set("is_portrait", true)
	portrait.position = Vector2(0, 24)
	character_column.add_child(portrait)
	var identity := OceanUi.label("DS  /  鲸鱼娘", 13, Color("5a70ad"))
	identity.position = Vector2(16, 0)
	character_column.add_child(identity)
	var aside := OceanUi.label("等调好声音，\n我再陪你出发。", 20)
	aside.position = Vector2(16, 338)
	character_column.add_child(aside)
	var content := VBoxContainer.new()
	content.name = "Preferences"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	columns.add_child(content)
	OceanUi.section(content, "PREFERENCES  /  偏好")
	content.add_child(OceanUi.label("设置", 30))
	content.add_child(OceanUi.label("声音、音乐，还有舒服的互动节奏。", 16, Color("5c6e91")))
	content.add_child(HSeparator.new())
	var config := ConfigFile.new()
	config.load("user://ui_settings.cfg")
	OceanUi.section(content, "声音")
	var volume: float = float(config.get_value("audio", "volume", 0.8))
	_master_slider = OceanUi.volume_row(content, "主音量", volume, apply_volume, "MasterVolume")
	apply_volume(volume)
	_music_slider = OceanUi.volume_row(content, "背景音乐", MusicManager.music_volume, MusicManager.set_music_volume, "MusicVolume")
	_music_status = OceanUi.label(MusicManager.status_text(), 14, Color("5c6e91"))
	_music_status.name = "MusicStatus"
	_music_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_music_status)
	MusicManager.track_changed.connect(_sync_music_status)
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 24)
	content.add_child(options)
	_all_mute = CheckButton.new()
	_all_mute.name = "AllMute"
	_all_mute.text = "全部静音"
	_all_mute.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_all_mute.button_pressed = MusicManager.muted
	_all_mute.toggled.connect(MusicManager.set_muted)
	options.add_child(_all_mute)
	var reduce := CheckButton.new()
	reduce.name = "ReducedMotion"
	reduce.text = "减少动态效果"
	reduce.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reduce.button_pressed = bool(config.get_value("visual", "reduced_motion", false))
	character_view.character.set_reduced_motion(reduce.button_pressed)
	reduce.toggled.connect(apply_reduced_motion)
	options.add_child(reduce)
	content.add_child(OceanUi.label("减少角色动作、装饰动画与界面过渡。", 14, Color("5c6e91")))
	content.add_child(HSeparator.new())
	var back := Button.new()
	back.text = "保存并返回  ·  Esc"
	back.custom_minimum_size.y = 46
	back.pressed.connect(close_settings)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	content.add_child(footer)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(back)
	credits_panel = Control.new()
	credits_panel.name = "CreditsPanel"
	credits_panel.set_script(load("res://scripts/ui/credits_panel.gd"))
	add_child(credits_panel)
	var credits_button := Button.new()
	credits_button.name = "Credits"
	credits_button.text = "制作与来源"
	credits_button.custom_minimum_size = Vector2(150, 46)
	credits_button.pressed.connect(func(): credits_panel.call("open"))
	footer.add_child(credits_button)
	OceanUi.primary(back)
	MusicManager.mix_changed.connect(_sync_music_controls)
	settings_panel.hide()
	get_viewport().size_changed.connect(_layout_settings)

func _sync_music_status() -> void:
	_music_status.text = MusicManager.status_text()

func _sync_music_controls() -> void:
	_music_slider.set_value_no_signal(MusicManager.music_volume)
	_all_mute.set_pressed_no_signal(MusicManager.muted)

func _update_interaction_status() -> void:
	if is_instance_valid(interaction_status):
		interaction_status.text = "减少动态已开启：设置中关闭后可互动" if character_view.character.reduced_motion else "左右按你看屏幕的方向 · 点一下，马上回应"

func apply_reduced_motion(value: bool) -> void:
	OceanUi.reduced_motion = value
	character_view.character.set_reduced_motion(value)
	_update_interaction_status()
	var config := ConfigFile.new()
	config.load("user://ui_settings.cfg")
	config.set_value("visual","reduced_motion",value)
	config.save("user://ui_settings.cfg")

func apply_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))
	var config := ConfigFile.new()
	config.load("user://ui_settings.cfg")
	config.set_value("audio", "volume", value)
	config.save("user://ui_settings.cfg")

func _layout_settings() -> void:
	var visible_size: Vector2 = get_viewport().get_visible_rect().size
	settings_panel.size.x = minf(880.0,visible_size.x-64.0)
	settings_panel.size.y = maxf(500.0, settings_panel.get_combined_minimum_size().y)
	settings_panel.position = (visible_size-settings_panel.size)*0.5

func show_settings() -> void:
	character_view.set_suspended(true)
	for child in get_children():
		if child is TextureButton:
			child.disabled = true
	_settings_scrim.show()
	settings_panel.show()
	OceanUi.reveal(settings_panel)
	_layout_settings.call_deferred()
	_master_slider.grab_focus()
	# 字体和自动换行需要完成布局后再收紧高度，避免初次最小尺寸撑出屏幕。
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(settings_panel) and settings_panel.visible:
		_layout_settings()

func close_settings() -> void:
	_settings_scrim.hide()
	settings_panel.hide()
	character_view.set_suspended(false)
	for child in get_children():
		if child is TextureButton:
			child.disabled = false
	$Settings.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		close_settings()
		get_viewport().set_input_as_handled()

func start_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/game.tscn")

func _notification(what: int) -> void:
	# 返回由一处关闭最上层，避免同一通知同时关闭来源弹窗和下方设置。
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(credits_panel) and credits_panel.visible:
			credits_panel.hide()
		elif is_instance_valid(settings_panel) and settings_panel.visible:
			close_settings()
