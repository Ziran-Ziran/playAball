extends Control
## 主菜单只负责导航和音量；正式战斗、奖励、物理仍由既有玩法校验。
const ART := "res://assets/ui/"
var _music_slider: HSlider
var _music_status: Label
var _all_mute: CheckButton
var interaction_status: Label
var settings_panel: PanelContainer
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
	button.mouse_entered.connect(func(): button.modulate = Color(1.15, 1.15, 1.15))
	button.mouse_exited.connect(func(): button.modulate = Color.WHITE)
	button.focus_entered.connect(func(): button.modulate = Color(1.25, 1.25, 1.25))
	button.focus_exited.connect(func(): button.modulate = Color.WHITE)
	button.pressed.connect(callback)
	add_child(button)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 22
	picture("fat_fish_menu_background", Rect2(0, 0, 1280, 720))
	picture("fat_fish_menu_title", Rect2(64, 94, 576, 230))
	# 角色组件在背景之后、按钮/设置之前，透明区域不挡导航。
	move_child(character_view,get_child_count()-1)
	action("Start", "fat_fish_start_button_full", Rect2(102, 367, 461, 115), start_game)
	action("Settings", "fat_fish_settings_button_full", Rect2(102, 504, 223, 101), show_settings)
	action("Exit", "fat_fish_exit_button_full", Rect2(340, 504, 223, 101), func(): get_tree().quit())
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(340, 170)
	settings_panel.size = Vector2(600, 350)
	var settings_style := StyleBoxFlat.new()
	settings_style.bg_color = Color("102c28")
	settings_style.border_color = Color("667d66")
	settings_style.set_border_width_all(1)
	settings_style.set_corner_radius_all(14)
	settings_style.set_content_margin_all(24)
	settings_panel.add_theme_stylebox_override("panel",settings_style)
	add_child(settings_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	settings_panel.add_child(content)
	var heading := Label.new()
	heading.text = "设置 · 主音量"
	content.add_child(heading)
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.01
	var config := ConfigFile.new()
	config.load("user://ui_settings.cfg")
	slider.value = float(config.get_value("audio", "volume", 0.8))
	apply_volume(slider.value)
	slider.value_changed.connect(apply_volume)
	content.add_child(slider)
	var reduce := CheckButton.new()
	reduce.text = "减少动态效果"
	reduce.button_pressed = bool(config.get_value("visual","reduced_motion",false))
	character_view.character.set_reduced_motion(reduce.button_pressed)
	reduce.toggled.connect(apply_reduced_motion)
	content.add_child(reduce)
	var music_row := HBoxContainer.new()
	var music_label := Label.new()
	music_label.text = "音乐"
	music_row.add_child(music_label)
	var music_slider := HSlider.new()
	_music_slider = music_slider
	music_slider.name = "MusicVolume"
	music_slider.custom_minimum_size = Vector2(280,30)
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = MusicManager.music_volume
	music_slider.value_changed.connect(MusicManager.set_music_volume)
	music_row.add_child(music_slider)
	content.add_child(music_row)
	var music_status := Label.new()
	_music_status = music_status
	music_status.name = "MusicStatus"
	music_status.text = MusicManager.status_text()
	music_status.add_theme_font_size_override("font_size",15)
	content.add_child(music_status)
	MusicManager.track_changed.connect(_sync_music_status)
	var mute := CheckButton.new()
	_all_mute = mute
	mute.name = "AllMute"
	mute.text = "全部静音"
	mute.button_pressed = MusicManager.muted
	mute.toggled.connect(MusicManager.set_muted)
	content.add_child(mute)
	MusicManager.mix_changed.connect(_sync_music_controls)
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(close_settings)
	content.add_child(back)
	settings_panel.hide()
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

func _sync_music_status() -> void:
	_music_status.text = MusicManager.status_text()

func _sync_music_controls() -> void:
	_music_slider.set_value_no_signal(MusicManager.music_volume)
	_all_mute.set_pressed_no_signal(MusicManager.muted)

func _update_interaction_status() -> void:
	if is_instance_valid(interaction_status):
		interaction_status.text = "减少动态已开启：设置中关闭后可互动" if character_view.character.reduced_motion else "左右按你看屏幕的方向 · 点一下，马上回应"

func apply_reduced_motion(value: bool) -> void:
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
	settings_panel.size.x = minf(600.0,visible_size.x-64.0)
	settings_panel.position = (visible_size-settings_panel.size)*0.5

func show_settings() -> void:
	character_view.set_suspended(true)
	for child in get_children():
		if child is TextureButton:
			child.disabled = true
	settings_panel.show()
	_layout_settings.call_deferred()
	settings_panel.get_child(0).get_child(1).grab_focus()

func close_settings() -> void:
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
