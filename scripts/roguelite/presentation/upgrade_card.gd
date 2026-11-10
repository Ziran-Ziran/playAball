class_name DemoUpgradeCard
extends Button
## 单张卡只展示传入的数据、纹理和收益，不应用升级、不读取或修改物理。
@export_group("插画与文字布局")
@export_range(18, 28, 1) var title_font_size: int = 20
@export_range(13, 18, 1) var detail_font_size: int = 13
@export_range(48, 120, 1) var minimum_image_height: float = 72.0
const SELECTION_DRAG_THRESHOLD: float = 18.0
var _gesture_origin: Vector2
var _gesture_moved: bool = false
var _pointer_active: bool = false
var _pointer_touch_index: int = -1
var _keyboard_selection: bool = false

func _input(event: InputEvent) -> void:
	# 只观察输入，不accept_event，外层ScrollContainer仍能完整接收滚动。
	# _input先于Button处理释放；保留拖动标记直到下一次真实按下，避免pressed误提交。
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _pointer_active and _can_begin_gesture(event.position):
				_begin_selection_gesture(event.position,event.index)
		elif _pointer_active and event.index == _pointer_touch_index:
			_measure_selection_drag(event.position)
			_gesture_moved = _gesture_moved or event.canceled
			_pointer_active = false
	elif event is InputEventScreenDrag:
		if _pointer_active and event.index == _pointer_touch_index:
			_measure_selection_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _can_begin_gesture(event.position):
				_begin_selection_gesture(event.position,-1)
		elif _pointer_active and _pointer_touch_index == -1:
			_measure_selection_drag(event.position)
			_pointer_active = false
	elif event is InputEventMouseMotion:
		if _pointer_active and _pointer_touch_index == -1:
			_measure_selection_drag(event.position)
	elif event.is_action_pressed("ui_accept"):
		_keyboard_selection = true

func _can_begin_gesture(point: Vector2) -> bool:
	return is_visible_in_tree() and not disabled and Rect2(Vector2.ZERO,size).has_point(get_global_transform_with_canvas().affine_inverse()*point)

func _begin_selection_gesture(point: Vector2, touch_index: int) -> void:
	_gesture_origin = point
	_gesture_moved = false
	_keyboard_selection = false
	_pointer_active = true
	_pointer_touch_index = touch_index

func _measure_selection_drag(point: Vector2) -> void:
	# 事件坐标为视口逻辑像素，与固定画布的18像素阈值一致，不随卡片滚动重置。
	_gesture_moved = _gesture_moved or point.distance_to(_gesture_origin) > SELECTION_DRAG_THRESHOLD

func can_submit_selection() -> bool:
	return _keyboard_selection or not _gesture_moved

func _ready() -> void:
	resized.connect(_layout)
	mouse_entered.connect(func(): self_modulate = Color(1.10, 1.10, 1.10))
	mouse_exited.connect(func(): self_modulate = Color.WHITE)
	_layout.call_deferred()

func configure(definition: DemoUpgrade, next_level: int, benefit: String, copy: Dictionary, art: Texture2D) -> void:
	$Content/Category.text = definition.category
	$Content/Heading.text = definition.title
	$Content/Illustration.texture = art
	$Content/Level.text = "%d → %d 级 / %d" % [next_level - 1, next_level, definition.max_level] if definition.max_level > 0 else "可重复 · 本局成长" if definition.id == "vigor" else "可重复 · 即时恢复"
	$Content/Preview.text = benefit
	$Content/Detail.text = str(copy.get("rules", definition.description))
	$Content/Flavor.text = str(copy.get("flavor", ""))
	tooltip_text = definition.description
	set_meta("upgrade_id", definition.id)
	set_meta("next_level", next_level)
	_layout()

func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	pivot_offset = size * 0.5
	# 所有文字先按实际宽度测量，再给插画剩余空间；文字不再依赖卡高百分比。
	var inset: float = 20.0
	var width: float = maxf(1.0, size.x - inset * 2)
	$Content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var heights: Dictionary = {}
	for key: String in ["Category","Heading","Level","Preview","Detail","Flavor"]:
		var label: Label = get_node("Content/"+key)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		label.size.x = width
		var font_size: int = {"Category":11,"Heading":title_font_size,"Level":11,"Preview":20 if size.x >= 260 else 17,"Detail":detail_font_size,"Flavor":10}[key]
		label.add_theme_font_size_override("font_size",font_size)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heights[key] = maxf(label.get_minimum_size().y,label.get_line_count() * label.get_theme_font("font").get_height(font_size) + 2.0)
	var text_total: float = 0.0
	for value: float in heights.values(): text_total += value
	var gap: float = 5.0
	# 四卡窄屏和新增完整规则可能超过固定420高度；让外层滚动承载正文，不裁字。
	var required_height: float = maxf(420.0, inset * 2.0 + text_total + gap * 6.0 + minimum_image_height)
	if not is_equal_approx(custom_minimum_size.y, required_height):
		custom_minimum_size.y = required_height
	# 容器下一次排序前也保持当前帧正文完整，避免最小高度已更新而实际卡高仍旧。
	if size.y < required_height:
		size.y = required_height
	var image_height: float = maxf(minimum_image_height,size.y-inset*2-text_total-gap*6)
	var y: float = inset
	for key: String in ["Category","Heading","Illustration","Level","Preview","Detail","Flavor"]:
		var height: float = image_height if key == "Illustration" else float(heights[key])
		_place(get_node("Content/"+key),Rect2(inset,y,width,height))
		y += height + gap

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
