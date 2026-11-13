extends Control
## 手机仅安装APK也能读取署名和许可；只在打开时组装文本，不逐帧读取磁盘。
var panel: PanelContainer
var body: RichTextLabel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 80
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.02, 0.04, 0.08, 0.94)
	add_child(scrim)
	panel = PanelContainer.new()
	OceanUi.apply(panel)
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(OceanUi.label("制作与来源", 26))
	body = RichTextLabel.new()
	body.name = "LicenseText"
	body.bbcode_enabled = false
	body.selection_enabled = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 16)
	body.add_theme_color_override("default_color", Color("29385d"))
	content.add_child(body)
	var close := Button.new()
	close.text = "返回设置"
	close.custom_minimum_size.y = 48
	close.pressed.connect(hide)
	content.add_child(close)
	OceanUi.primary(close)
	get_viewport().size_changed.connect(_layout)
	hide()

func open() -> void:
	if body.text.is_empty():
		var sections: PackedStringArray = []
		for path: String in ["credits.txt", "music.txt", "ZCOOL_OFL.txt", "Noto_OFL.txt", "Kenney_CC0.txt"]:
			sections.append(FileAccess.get_file_as_string("res://resources/legal/" + path))
		sections.append(Engine.get_license_text())
		var licenses: Dictionary = Engine.get_license_info()
		for name: String in licenses:
			sections.append(name + "\n" + str(licenses[name]))
		body.text = "\n\n────────────────\n\n".join(sections)
	_layout()
	show()

func _layout() -> void:
	if not is_inside_tree(): return
	var extent: Vector2 = get_viewport_rect().size
	panel.size = Vector2(minf(1040, extent.x - 64), extent.y - 64)
	panel.position = (extent - panel.size) * 0.5

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

