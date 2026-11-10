extends Control
## 内置生图八帧图集；减少动态时固定首帧，按钮命中区域从不缩放。
var is_badge: bool = false
var is_portrait: bool = false
var elapsed: float = 0.0
var frame_index: int = 0
var _tween: Tween
var _button: BaseButton
var _atlas: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_badge:
		size = Vector2(220, 300) if is_portrait else Vector2(84, 86)
		_atlas = load("res://assets/ui/ds_console/ds_maid_frames.png")
	else:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_button = get_parent() as BaseButton
		_button.mouse_entered.connect(_update_button)
		_button.mouse_exited.connect(_update_button)
		_button.focus_entered.connect(_update_button)
		_button.focus_exited.connect(_update_button)
		_button.button_down.connect(func(): _tint(Color(0.7, 0.9, 1.0)))
		_button.button_up.connect(_update_button)

func _process(delta: float) -> void:
	if not is_badge or not is_visible_in_tree(): return
	if OceanUi.reduced_motion:
		frame_index = 0
	else:
		elapsed += delta
		# 留出注视时间再眨眼，避免一秒一次重复点头抢走设置控件的注意力。
		var phase: float = fmod(elapsed, 3.8)
		frame_index = 0 if phase < 2.0 else mini(7, int((phase - 2.0) / 1.8 * 8.0))
	queue_redraw()

func _update_button() -> void:
	_tint(Color(1.12, 1.16, 1.1) if not _button.disabled and (_button.is_hovered() or _button.has_focus()) else Color.WHITE)

func _tint(color: Color) -> void:
	if is_instance_valid(_tween): _tween.kill()
	if OceanUi.reduced_motion:
		_button.modulate = color
		return
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_button, "modulate", color, 0.12).set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	if not is_badge or _atlas == null: return
	var cell := Vector2(_atlas.get_width() / 4.0, _atlas.get_height() / 2.0)
	var origin := Vector2(frame_index % 4, frame_index / 4) * cell
	# 正文插画显示完整人物；标题头像裁取同一人物上半身，不把她变成普通鱼。
	var region := Rect2(origin, cell) if is_portrait else Rect2(origin + cell * Vector2(0.04, 0.02), cell * Vector2(0.92, 0.62))
	draw_texture_rect_region(_atlas, Rect2(Vector2.ZERO, size), region)
