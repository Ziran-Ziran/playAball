class_name DemoLabPanel
extends CanvasLayer
## 实验室表现层：收集白名单请求并显示只读读数；不直接修改玩法状态。
signal action_requested(action: String, payload: Dictionary, revision: int)
var revision: int = 0
var _fixture: OptionButton
var _fields: Dictionary = {}
var _parameters: VBoxContainer
var _pending_label: Label
var _status_label: Label
var _readout: Label
var _log: RichTextLabel
var _log_panel: PanelContainer
var _readout_panel: PanelContainer
var _specs: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_shell()

func configure(specs: Array, fixture_names: Array[String]) -> void:
	_specs = specs
	_fixture.clear()
	for index in fixture_names.size():
		_fixture.add_item(fixture_names[index], index)
	for spec in specs:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(spec.label)
		label.custom_minimum_size = Vector2(148, 0)
		row.add_child(label)
		var control: Control
		match String(spec.type):
			"option":
				var option := OptionButton.new()
				var choices: Array = spec.options
				for index in choices.size():
					option.add_item(String(choices[index]), index)
				control = option
			"bool":
				var check := CheckButton.new()
				control = check
			_:
				var spin := SpinBox.new()
				spin.min_value = float(spec.min)
				spin.max_value = float(spec.max)
				spin.step = float(spec.step)
				spin.allow_greater = false
				spin.allow_lesser = false
				spin.custom_minimum_size = Vector2(138, 0)
				control = spin
		control.name = String(spec.id).to_pascal_case()
		control.tooltip_text = "正式基线：%s；当前显示试验值。修改后按“应用并重置”或 R 生效。" % str(spec.get("default", ""))
		if control is OptionButton:
			control.item_selected.connect(func(_index: int): _mark_pending())
		elif control is CheckButton:
			control.toggled.connect(func(_pressed: bool): _mark_pending())
		elif control is SpinBox:
			control.value_changed.connect(func(_value: float): _mark_pending())
		row.add_child(control)
		_parameters.add_child(row)
		_fields[String(spec.id)] = control
	_fixture.item_selected.connect(func(_index: int): _mark_pending())
	_pending_label.text = "参数修改后需按 R / 应用并重置才生效"

func set_revision(value: int) -> void:
	revision = value

func set_values(values: Dictionary) -> void:
	_fixture.select(clampi(int(values.get("fixture", 0)), 0, maxi(0, _fixture.item_count - 1)))
	for spec in _specs:
		var id: String = String(spec.id)
		var control: Control = _fields.get(id)
		if control == null:
			continue
		var value: Variant = values.get(id, spec.get("default", 0))
		if control is OptionButton:
			control.select(clampi(int(value), 0, maxi(0, control.item_count - 1)))
		elif control is CheckButton:
			control.button_pressed = bool(value)
		elif control is SpinBox:
			control.value = float(value)
	_mark_pending()

func values() -> Dictionary:
	var result: Dictionary = {"fixture": _fixture.selected}
	for spec in _specs:
		var id: String = String(spec.id)
		var control: Control = _fields.get(id)
		if control is OptionButton:
			result[id] = control.selected
		elif control is CheckButton:
			result[id] = control.button_pressed
		elif control is SpinBox:
			result[id] = control.value
	return result

func set_status(text: String, applied: bool = true) -> void:
	_status_label.text = text
	_status_label.modulate = Color("bce9da") if applied else Color("ffcf8f")
	if applied:
		_pending_label.text = "当前参数已应用；继续修改需再次重置"

func set_readout(text: String) -> void:
	_readout.text = text

func set_log(text: String) -> void:
	_log.text = text

func set_visuals_visible(value: bool) -> void:
	_log_panel.visible = value
	_readout_panel.visible = value

func _build_shell() -> void:
	var control := Control.new()
	control.name = "Control"
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)

	var panel := PanelContainer.new()
	panel.name = "ParameterPanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -420.0
	panel.offset_right = -16.0
	panel.offset_top = 16.0
	panel.offset_bottom = 704.0
	control.add_child(panel)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)
	var title := Label.new()
	title.text = "玩法实验室 · B线"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var fixture_row := HBoxContainer.new()
	var fixture_label := Label.new()
	fixture_label.text = "夹具"
	fixture_label.custom_minimum_size = Vector2(148, 0)
	fixture_row.add_child(fixture_label)
	_fixture = OptionButton.new()
	_fixture.name = "Fixture"
	_fixture.custom_minimum_size = Vector2(180, 0)
	fixture_row.add_child(_fixture)
	layout.add_child(fixture_row)
	var parameter_scroll := ScrollContainer.new()
	parameter_scroll.name = "ParameterScroll"
	parameter_scroll.custom_minimum_size = Vector2(0, 410)
	parameter_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parameter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(parameter_scroll)
	_parameters = VBoxContainer.new()
	_parameters.name = "Parameters"
	_parameters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_parameters.add_theme_constant_override("separation", 3)
	parameter_scroll.add_child(_parameters)
	_pending_label = Label.new()
	_pending_label.name = "Pending"
	_pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_pending_label)
	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 6)
	buttons.add_theme_constant_override("v_separation", 6)
	layout.add_child(buttons)
	for spec in [
		{"id": "apply", "text": "应用并重置"},
		{"id": "launch", "text": "固定发射 T"},
		{"id": "save", "text": "保存预设"},
		{"id": "load", "text": "加载预设"},
		{"id": "defaults", "text": "恢复默认"},
		{"id": "record", "text": "保存复现"},
	]:
		var button := Button.new()
		button.text = String(spec.text)
		button.pressed.connect(func(): action_requested.emit(String(spec.id), values(), revision))
		buttons.add_child(button)
	var visual_toggle := CheckButton.new()
	visual_toggle.text = "显示读数与日志（L）"
	visual_toggle.button_pressed = true
	visual_toggle.toggled.connect(set_visuals_visible)
	layout.add_child(visual_toggle)

	_readout_panel = PanelContainer.new()
	_readout_panel.name = "ReadoutPanel"
	_readout_panel.offset_left = 16.0
	_readout_panel.offset_top = 122.0
	_readout_panel.offset_right = 760.0
	_readout_panel.offset_bottom = 260.0
	control.add_child(_readout_panel)
	_readout = Label.new()
	_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout.add_theme_font_size_override("font_size", 15)
	_readout_panel.add_child(_readout)

	_log_panel = PanelContainer.new()
	_log_panel.name = "LogPanel"
	_log_panel.offset_left = 16.0
	_log_panel.offset_top = 270.0
	_log_panel.offset_right = 760.0
	_log_panel.offset_bottom = 704.0
	control.add_child(_log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	_log.fit_content = false
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log_panel.add_child(_log)

func _mark_pending() -> void:
	if _pending_label != null:
		_pending_label.text = "有未应用修改 · R 重置后生效"
		_pending_label.modulate = Color("ffcf8f")
