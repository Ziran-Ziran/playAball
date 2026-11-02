extends CanvasLayer
## 只收集滑杆/按钮请求；参数校验和应用由LiveTuning完成。
signal parameter_requested(id: String, value: float)
signal action_requested(action: String)
signal pause_preference_changed(enabled: bool)
@onready var panel: PanelContainer = $Root/Panel
@onready var toggle: Button = $Root/Toggle
@onready var parameters: VBoxContainer = $Root/Panel/Layout/Scroll/Parameters
@onready var readout: Label = $Root/Panel/Layout/Readout
@onready var status: Label = $Root/Panel/Layout/Status
var _fields: Dictionary = {}
var _syncing: bool = false
var _full_view: Control
var _mode: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	toggle.pressed.connect(func(): action_requested.emit("toggle"))
	$Root/Panel/Layout/Pause.toggled.connect(func(enabled: bool): pause_preference_changed.emit(enabled))
	for spec: Dictionary in [
		{"id": "remember", "text": "记住这组"}, {"id": "compare", "text": "切换对照"},
		{"id": "defaults", "text": "恢复基线"}, {"id": "copy", "text": "复制参数"},
		{"id": "save", "text": "保存参数"}, {"id": "load", "text": "加载参数"},
	]:
		var button := Button.new()
		button.text = String(spec.text)
		button.pressed.connect(func(): action_requested.emit(String(spec.id)))
		$Root/Panel/Layout/Buttons.add_child(button)
	panel.hide()

func configure(specs: Array[Dictionary], values: Dictionary) -> void:
	for spec: Dictionary in specs:
		var id: String = String(spec.id)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		var label := Label.new()
		label.text = String(spec.label)
		label.tooltip_text = String(spec.hint)
		label.add_theme_font_size_override("font_size", 17)
		row.add_child(label)
		var controls := HBoxContainer.new()
		var slider := HSlider.new()
		slider.name = id.to_pascal_case()
		slider.min_value = float(spec.min)
		slider.max_value = float(spec.max)
		slider.step = float(spec.step)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 28
		slider.tooltip_text = String(spec.hint)
		var spin := SpinBox.new()
		spin.min_value = float(spec.min)
		spin.max_value = float(spec.max)
		spin.step = float(spec.step)
		spin.custom_minimum_size.x = 100
		slider.value_changed.connect(func(value: float):
			if not _syncing: parameter_requested.emit(id, value)
		)
		spin.value_changed.connect(func(value: float):
			if not _syncing: parameter_requested.emit(id, value)
		)
		controls.add_child(slider)
		controls.add_child(spin)
		row.add_child(controls)
		parameters.add_child(row)
		_fields[id] = [slider, spin]
	set_values(values)

func set_values(values: Dictionary) -> void:
	_syncing = true
	for id: String in _fields:
		for field: Range in _fields[id]:
			field.set_value_no_signal(float(values[id]))
	_syncing = false

func attach_full(model: RefCounted) -> void:
	_mode=OptionButton.new()
	_mode.add_item("完整属性：引擎 / 物理 / 玩法 / 资源")
	_mode.add_item("常用手感：快捷滑杆")
	var layout: VBoxContainer = $Root/Panel/Layout
	layout.add_child(_mode)
	layout.move_child(_mode,2)
	_full_view=load("res://scripts/roguelite/lab/full_tuning_view.gd").new()
	layout.add_child(_full_view)
	layout.move_child(_full_view,3)
	_full_view.configure(model,set_status)
	$Root/Panel/Layout/Scroll.hide()
	_mode.item_selected.connect(func(index: int):
		_full_view.visible=index==0
		$Root/Panel/Layout/Scroll.visible=index==1
	)
	$Root/Panel/Layout/Title.text="引擎与玩法 · 完整调参台"

func set_status(text: String) -> void:
	status.text = text

func set_readout(text: String) -> void:
	readout.text = text

func set_open(value: bool) -> void:
	panel.visible = value
	toggle.text = "F1 收起调参 / 继续试" if value else "F1 完整调参"
	if not value:
		var focus: Control = get_viewport().gui_get_focus_owner()
		if focus != null: focus.release_focus()

func is_open() -> bool:
	return panel.visible

func panel_rect() -> Rect2:
	return panel.get_global_rect()

func covers_point(point: Vector2) -> bool:
	return toggle.get_global_rect().has_point(point) or (panel.visible and panel.get_global_rect().has_point(point))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9:
			action_requested.emit("defaults")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F1 or (event.keycode == KEY_ESCAPE and panel.visible):
			action_requested.emit("toggle")
			get_viewport().set_input_as_handled()
