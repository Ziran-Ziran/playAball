extends Control
## 独立菜单样板：GUI先消费输入，未消费的鼠标才触发角色回应。

@onready var character: Node3D = $Stage/World/Character
@onready var camera: Camera3D = $Stage/World/Camera
@onready var stage: SubViewport = $Stage
@onready var character_view: TextureRect = $CharacterView
var settings: PanelContainer
var settings_open: bool = false
var feedback: Label
var close_up: bool = false
var _mouse_inside: bool = true
var _pointer_position: Vector2 = Vector2(880, 210)
var _buttons: Dictionary = {}

func _ready() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 20
	_label("DEEP BLUE / PLAY A BALL", Vector2(82, 86), 16, Color("7cabc2"))
	_label("玩个球", Vector2(78, 140), 72, Color("f5f1e9"))
	_label("潮起时，见个面。", Vector2(84, 253), 22, Color("c0d7e1"))
	_button("greet", "打个招呼", 350, func() -> void: _react("greet"))
	_button("zoom", "靠近看看", 420, _toggle_zoom)
	_button("settings", "设置", 490, func() -> void: set_settings_open(true))
	feedback = _label("移动鼠标，她会看向你。\n点点头顶，试试她的回应。", Vector2(84, 594), 17, Color("a3bccd"))
	_label("角色：Manny  /  动作：Quaternius", Vector2(84, 685), 12, Color("668399"))
	_make_settings()
	get_window().mouse_entered.connect(func() -> void: _mouse_inside = true)
	get_window().mouse_exited.connect(func() -> void: _mouse_inside = false)
	queue_redraw()
	if "--validate" in OS.get_cmdline_user_args():
		call_deferred("_validate")

func _process(_delta: float) -> void:
	if not character.ready_for_input:
		return
	var head: Vector2 = head_screen_position()
	var mouse: Vector2 = _pointer_position
	character.requested_gaze = Vector2(clampf((mouse.x - head.x) / 500.0, -1.0, 1.0), clampf((mouse.y - head.y) / 360.0, -1.0, 1.0)) if _mouse_inside else Vector2.ZERO
	character.settings_open = settings_open

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# 使用进入视口的实际事件坐标；避免逐帧轮询系统鼠标覆盖已分发输入。
		_pointer_position = get_global_transform_with_canvas().affine_inverse() * event.position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_open:
		set_settings_open(false)
		get_viewport().set_input_as_handled()
	if settings_open or not character.ready_for_input:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.distance_to(head_screen_position()) < 90.0:
			_react("pet")
			get_viewport().set_input_as_handled()

func head_screen_position() -> Vector2:
	if not character.ready_for_input:
		return Vector2(880, 210)
	return character_view.position + camera.unproject_position(character.head_world_position()) / Vector2(stage.size) * character_view.size

func set_settings_open(value: bool) -> void:
	settings_open = value
	settings.visible = value
	character.settings_open = value

func _react(kind: String) -> void:
	if character.react(kind):
		feedback.text = "嗯？是在叫我吗？" if kind == "greet" else "……头发要揉乱啦。"
		var tween := create_tween()
		tween.tween_interval(2.2)
		tween.tween_callback(func() -> void: feedback.text = "移动鼠标，她会看向你。\n点点头顶，试试她的回应。")

func _toggle_zoom() -> void:
	close_up = not close_up
	_buttons.zoom.text = "退远一点" if close_up else "靠近看看"
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "size", 0.85 if close_up else 1.65, 0.65)
	tween.tween_property(camera, "position:y", 1.37 if close_up else 1.08, 0.65)

func _label(text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(key: String, text: String, y: float, action: Callable) -> void:
	var button := Button.new()
	button.position = Vector2(84, y)
	button.size = Vector2(300, 54)
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("193e52") if state == "normal" else Color("295f72")
		style.border_color = Color("5892a8")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	add_child(button)
	_buttons[key] = button

func _make_settings() -> void:
	settings = PanelContainer.new()
	settings.position = Vector2(390, 190)
	settings.size = Vector2(500, 330)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102739")
	style.set_content_margin_all(30)
	style.set_corner_radius_all(12)
	settings.add_theme_stylebox_override("panel", style)
	add_child(settings)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	settings.add_child(box)
	var title := Label.new()
	title.text = "相处方式"
	box.add_child(title)
	var follow := HSlider.new()
	follow.min_value = 0.25
	follow.max_value = 1.0
	follow.step = 0.05
	follow.value = 1.0
	follow.custom_minimum_size.y = 36
	follow.tooltip_text = "跟随幅度"
	follow.value_changed.connect(func(value: float) -> void: character.follow_amount = value)
	box.add_child(follow)
	var reduce := CheckButton.new()
	reduce.text = "减少动态"
	reduce.toggled.connect(func(value: bool) -> void: character.reduced_motion = value)
	box.add_child(reduce)
	var close := Button.new()
	close.text = "回到她身边"
	close.custom_minimum_size.y = 48
	close.pressed.connect(func() -> void: set_settings_open(false))
	box.add_child(close)
	settings.hide()

func _validate() -> void:
	var validator: RefCounted = load("res://sample/verify_sample.gd").new()
	await validator.run(self)
