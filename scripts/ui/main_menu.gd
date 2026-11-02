extends Control
## 主菜单只负责导航和音量；正式战斗、奖励、物理仍由既有玩法校验。
const ART := "res://assets/ui/"
var settings_panel: PanelContainer

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
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 22
	picture("fat_fish_menu_background", Rect2(0, 0, 1280, 720))
	picture("fat_fish_menu_title", Rect2(64, 94, 576, 230))
	picture("fat_fish_menu_character", Rect2(696, 0, 569, 684))
	action("Start", "fat_fish_start_button_full", Rect2(102, 367, 461, 115), start_game)
	action("Settings", "fat_fish_settings_button_full", Rect2(102, 504, 223, 101), show_settings)
	action("Exit", "fat_fish_exit_button_full", Rect2(340, 504, 223, 101), func(): get_tree().quit())
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(340, 170)
	settings_panel.size = Vector2(600, 350)
	add_child(settings_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	settings_panel.add_child(content)
	var heading := Label.new()
	heading.text = "设置 · 音量"
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
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(close_settings)
	content.add_child(back)
	settings_panel.hide()

func apply_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))
	var config := ConfigFile.new()
	config.set_value("audio", "volume", value)
	config.save("user://ui_settings.cfg")

func show_settings() -> void:
	for child in get_children():
		if child is TextureButton:
			child.disabled = true
	settings_panel.show()
	settings_panel.get_child(0).get_child(1).grab_focus()

func close_settings() -> void:
	settings_panel.hide()
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
