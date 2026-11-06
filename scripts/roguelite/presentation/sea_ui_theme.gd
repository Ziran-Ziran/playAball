extends RefCounted
## 实色面板与统一交互状态；状态仅展示，购买许可仍由玩法提供。
static func apply(control: Control) -> void:
	var theme := Theme.new()
	theme.default_font_size = 17
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("254c43")
		if state == "hover": box.bg_color = Color("37675a")
		if state == "pressed": box.bg_color = Color("183a32")
		if state == "disabled": box.bg_color = Color("182b29")
		box.border_color = Color("b5a77d") if state == "focus" else Color("57756a")
		box.set_border_width_all(2 if state == "focus" else 1)
		box.set_corner_radius_all(8)
		box.content_margin_left = 20
		box.content_margin_right = 20
		box.content_margin_top = 12
		box.content_margin_bottom = 12
		theme.set_stylebox(state,"Button",box)
	theme.set_color("font_color","Button",Color("f7edd2"))
	theme.set_color("font_disabled_color","Button",Color("74827b"))
	theme.set_color("font_color","Label",Color("d3dfd4"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("102c28")
	panel.border_color = Color("667d66")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(14)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 28
	panel.content_margin_bottom = 28
	theme.set_stylebox("panel","PanelContainer",panel)
	control.theme = theme

static func primary(button: Button) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("d6bd82")
	box.set_corner_radius_all(8)
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	button.add_theme_stylebox_override("normal",box)
	button.add_theme_color_override("font_color",Color("182d27"))

	# 主操作每种状态都保持浅底深字；禁用单独弱化，避免继承深底造成低对比。
	for state: String in ["hover","pressed","disabled"]:
		var variant: StyleBoxFlat = box.duplicate()
		variant.bg_color = Color("ead6a3") if state == "hover" else Color("b49b65") if state == "pressed" else Color("34443c")
		button.add_theme_stylebox_override(state,variant)
	button.add_theme_color_override("font_hover_color",Color("182d27"))
	button.add_theme_color_override("font_pressed_color",Color("182d27"))
	button.add_theme_color_override("font_disabled_color",Color("91a094"))
