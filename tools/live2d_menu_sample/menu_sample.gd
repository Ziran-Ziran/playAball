extends Control
## 独立样板：不导航到游戏，不写游戏设置，不参与正式菜单。
@onready var character: Node2D = $Stage/Character
@onready var stage: SubViewport = $Stage
var portrait: TextureRect
var settings: PanelContainer
var status_label: Label
var left_panel: VBoxContainer
var press_position: Vector2 = Vector2.ZERO
var press_time: int = 0
var pressing: bool = false
var screenshot_path: String = ""
var base_model_scale: Vector2 = Vector2.ONE
var closeup: bool = false
var closeup_button: Button
var _closeup_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 20
	portrait = TextureRect.new()
	portrait.texture = stage.get_texture()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(portrait)
	left_panel = VBoxContainer.new()
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_theme_constant_override("separation", 18)
	add_child(left_panel)
	_label("玩个球", 42, Color("d7e9ef"))
	_label("窗边的鲸鱼", 30, Color("f6e1bb"))
	_label("DeepSeek-chan · 菜单互动样板", 18, Color("96bac5"))
	_label("移动鼠标，她会看向你。\n轻点角色，或在头部慢慢划动。", 20, Color("c1d5dc"))
	closeup_button = _button("靠近看看", func(): set_closeup(not closeup))
	_button("打个招呼", func(): character.request_reaction("greet"))
	_button("逗逗她", func(): character.request_reaction("cheek"))
	_button("设置", func(): show_settings(true))
	_button("退出样板", func(): get_tree().quit())
	status_label = _label("正在等她过来…", 18, Color("e5cda4"))
	_label("角色 / 分层：神宫凉子 Kamiya Ryoko\nLive2D 绑定：霓虹猫_NeonNeko\n本地技术样板 · 非正式游戏入口", 13, Color("88a9b6"))
	_build_settings()
	character.reaction_started.connect(_on_reaction)
	character.reaction_finished.connect(func(): status_label.text = "她又安静地看着你了。")
	status_label.text = "她在看着你。" if character.loaded else character.load_error
	if character.loaded:
		base_model_scale = character.model.scale
	resized.connect(_layout)
	get_window().focus_exited.connect(_on_focus_exited)
	_layout()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): screenshot_path = arg.trim_prefix("--capture=")
	if not screenshot_path.is_empty(): _capture.call_deferred()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	left_panel.add_child(label)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.pressed.connect(callback)
	left_panel.add_child(button)
	return button

func set_closeup(value: bool) -> void:
	if not character.loaded or settings.visible:
		return
	closeup = value
	closeup_button.text = "退远一点" if value else "靠近看看"
	if is_instance_valid(_closeup_tween):
		_closeup_tween.kill()
	_closeup_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_closeup_tween.tween_property(character.model, "scale", base_model_scale * (1.65 if value else 1.0), 0.65)
	_closeup_tween.tween_property(character.model, "position", Vector2(360,500) if value else Vector2(360,360), 0.65)

func character_point(stage_point: Vector2) -> Vector2:
	# 近景改变模型在Stage中的尺度；命中类别需反算回原来的角色画布。
	var ratio: float = character.model.scale.x / base_model_scale.x
	return (stage_point - character.model.position) / ratio + Vector2(360,360)

func _build_settings() -> void:
	settings = PanelContainer.new()
	settings.custom_minimum_size = Vector2(430, 270)
	settings.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(settings)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 20)
	settings.add_child(contents)
	var heading := Label.new()
	heading.text = "休息一下"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents.add_child(heading)
	var detail := Label.new()
	detail.text = "设置打开时，角色不会接收触摸。\nEsc 或下方按钮返回。"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents.add_child(detail)
	var reduce := CheckButton.new()
	reduce.text = "减少动态效果"
	reduce.toggled.connect(func(value: bool): character.set_reduced_motion(value))
	contents.add_child(reduce)
	var back := Button.new()
	back.text = "回到她身边"
	back.pressed.connect(func(): show_settings(false))
	contents.add_child(back)
	settings.hide()

func _layout() -> void:
	var side: float = minf(size.y, size.x * 0.59)
	portrait.position = Vector2(size.x - side - 8, (size.y - side) * 0.5)
	portrait.size = Vector2.ONE * side
	left_panel.position = Vector2(40, 24)
	left_panel.size.x = maxf(250, portrait.position.x - 68)
	settings.position = (size - settings.size) * 0.5
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("102631"))
	draw_circle(size * Vector2(0.8, 0.25), size.y * 0.7, Color("193e50"))
	draw_circle(size * Vector2(0.88, 0.18), size.y * 0.42, Color("204a5d"))
	draw_line(Vector2(size.x * 0.44, 28), Vector2(size.x * 0.44, size.y - 28), Color("395d6c"), 1)

func portrait_point(point: Vector2) -> Vector2:
	# 交互使用720逻辑画布，与1440超采样纹理分开，防止提高画质后命中偏移。
	return (point - portrait.position) / portrait.size * Vector2(720, 720)

func hits_character(point: Vector2) -> bool:
	if not portrait.get_rect().has_point(point): return false
	var image: Image = stage.get_texture().get_image()
	var p: Vector2i = Vector2i(portrait_point(point) / Vector2(720, 720) * Vector2(image.get_size()))
	if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height(): return false
	# 使用当前帧真实透明度，不让角色画布的空白挡住菜单。
	return image.get_pixelv(p).a > 0.2

func _input(event: InputEvent) -> void:
	# 跟随也能看到按钮上方的鼠标；点击仍交给 UI 和未处理输入仲裁。
	if event is InputEventMouseMotion and not settings.visible and character.loaded:
		var point: Vector2 = portrait_point(event.position)
		var ratio: float = character.model.scale.x / base_model_scale.x
		var face: Vector2 = character.model.position + (Vector2(360,155) - Vector2(360,360)) * ratio
		character.set_pointer((point - face) / Vector2(320,300))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		show_settings(not settings.visible)
		get_viewport().set_input_as_handled()
		return
	if settings.visible or not character.loaded: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressing = hits_character(event.position)
			if pressing:
				press_position = character_point(portrait_point(event.position))
				press_time = Time.get_ticks_msec()
				get_viewport().set_input_as_handled()
		elif pressing:
			pressing = false
			if not hits_character(event.position): return
			var end: Vector2 = character_point(portrait_point(event.position))
			var is_pet: bool = Time.get_ticks_msec() - press_time > 200 and end.distance_to(press_position) > 16 and end.y < 215
			var kind: String = "pet" if is_pet else ("cheek" if end.y < 240 else "greet")
			character.request_reaction(kind, signf(end.x - 360))
			get_viewport().set_input_as_handled()

func _on_reaction(kind: String) -> void:
	status_label.text = {"pet":"她轻轻闭起了眼。", "cheek":"她露出了另一副表情。", "annoyed":"好啦，先让她歇一会儿。", "greet":"她向你打了个招呼。"}.get(kind, "她注意到了你。")

func show_settings(value: bool) -> void:
	settings.visible = value
	pressing = false
	character.set_blocked(value)
	if value: settings.get_child(0).get_child(3).grab_focus()

func _on_focus_exited() -> void:
	pressing = false
	character.set_pointer(Vector2.ZERO)

func _capture() -> void:
	for frame: int in 45: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result: Error = get_viewport().get_texture().get_image().save_png(screenshot_path)
	print("DEEPSEEK_CAPTURE ", result)
	get_tree().quit(int(result))
