class_name OceanUi
extends RefCounted
## 图片只负责装饰；布局、数值与输入保留为真实控件。
static var reduced_motion: bool = false
static var _skin: Theme
const ART: String = "res://assets/ui/ds_console/"

static func read_preferences() -> void:
	var config := ConfigFile.new()
	config.load("user://ui_settings.cfg")
	reduced_motion = bool(config.get_value("visual", "reduced_motion", false))

static func panel_style() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(ART + "panel.png")
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 18.0)
		box.set_content_margin(side, 32.0)
	return box

static func button_style(tint: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(ART + "button.png")
	box.modulate_color = tint
	box.texture_margin_left = 28.0
	box.texture_margin_right = 28.0
	box.texture_margin_top = 10.0
	box.texture_margin_bottom = 10.0
	box.content_margin_left = 22.0
	box.content_margin_right = 22.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box

static func apply(control: Control) -> void:
	read_preferences()
	if _skin != null:
		control.theme = _skin
		return
	var skin := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "WenQuanYi Zen Hei"])
	skin.default_font = font
	skin.default_font_size = 18
	var colors: Dictionary = {"normal": Color(1, 1, 1, 0.1), "hover": Color(1, 1, 1, 0.2), "pressed": Color(1, 1, 1, 0.28), "disabled": Color(1, 1, 1, 0.04)}
	for state: String in colors:
		skin.set_stylebox(state, "Button", button_style(colors[state]))
		var switch_box := StyleBoxFlat.new()
		switch_box.bg_color = Color(0.35, 0.46, 0.84, 0.08 if state == "hover" else 0.0)
		switch_box.set_content_margin_all(6)
		skin.set_stylebox(state, "CheckButton", switch_box)
	# 键盘焦点有独立清晰轮廓，不靠hover颜色辨认。
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("526adb")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(10)
	skin.set_stylebox("focus", "Button", focus)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		skin.set_color(state, "Button", Color("29385d"))
	skin.set_color("font_disabled_color", "Button", Color("8792a9"))
	skin.set_color("font_color", "Label", Color("29385d"))
	skin.set_stylebox("panel", "PanelContainer", panel_style())
	var track := StyleBoxFlat.new()
	track.bg_color = Color("dce3f2")
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	skin.set_stylebox("slider", "HSlider", track)
	var fill: StyleBoxFlat = track.duplicate()
	fill.bg_color = Color("637de2")
	skin.set_stylebox("grabber_area", "HSlider", fill)
	skin.set_stylebox("grabber_area_highlight", "HSlider", fill)
	# 共享主题保持字体存活；展示商店时不在布局回调中释放旧SystemFont。
	_skin = skin
	control.theme = _skin

static func label(text: String, font_size: int = 18, color: Color = Color("29385d")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func section(parent: Container, title: String) -> void:
	parent.add_child(label(title, 15, Color("536b94")))

static func volume_row(parent: Container, title: String, value: float, changed: Callable, node_name: String = "") -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 38
	row.add_theme_constant_override("separation", 14)
	var heading := label(title)
	heading.custom_minimum_size.x = 80
	row.add_child(heading)
	var slider := HSlider.new()
	slider.name = node_name if not node_name.is_empty() else "Volume"
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(150, 34)
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.tooltip_text = title + "：左右方向键微调"
	row.add_child(slider)
	var percent := label("%d%%" % roundi(value * 100), 17, Color("526adb"))
	percent.name = "Percent"
	percent.custom_minimum_size.x = 48
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(percent)
	slider.value_changed.connect(func(amount: float):
		percent.text = "%d%%" % roundi(amount * 100)
		changed.call(amount)
	)
	# 外部同步不触发value_changed，显示读数仍随实际值更新。
	slider.draw.connect(func(): percent.text = "%d%%" % roundi(slider.value * 100))
	parent.add_child(row)
	return slider

static func primary(button: Button) -> void:
	for state: String in ["normal", "hover", "pressed"]:
		var tint := Color.WHITE if state == "normal" else Color(1.1, 1.1, 1.1) if state == "hover" else Color(0.85, 0.9, 1.0)
		button.add_theme_stylebox_override(state, button_style(tint))
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, Color.WHITE)
	bind_button(button)

static func bind_button(button: BaseButton) -> void:
	if button.has_node("OceanFeedback"):
		return
	var feedback := Control.new()
	feedback.name = "OceanFeedback"
	feedback.set_script(load("res://scripts/ui/ocean_motion.gd"))
	button.add_child(feedback)

static func reveal(control: Control) -> void:
	var previous: Tween = control.get_meta("ocean_reveal") if control.has_meta("ocean_reveal") else null
	if is_instance_valid(previous): previous.kill()
	control.modulate.a = 1.0 if reduced_motion else 0.0
	if reduced_motion: return
	var tween := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta("ocean_reveal", tween)
	tween.tween_property(control, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
