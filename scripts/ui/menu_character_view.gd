extends Control
## 把菜单坐标转换为720逻辑画布，只在当前帧不透明角色上接收触摸。
@export_range(1.0,1.8) var camera_scale: float = 1.35
@export var camera_position := Vector2(360,430)
@onready var character: Node2D = $Stage/Character
@onready var stage: SubViewport = $Stage
@onready var portrait: TextureRect = $Portrait
@onready var fallback: TextureRect = $Fallback
var base_model_scale: Vector2 = Vector2.ONE
var suspended: bool = false
var focused: bool = true
var pressing: bool = false
var press_position: Vector2 = Vector2.ZERO
var press_time: int = 0
var alpha_frame: int = -1
var alpha_image: Image

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = stage.get_texture()
	portrait.visible = character.loaded
	fallback.visible = not character.loaded
	if character.loaded:
		base_model_scale = character.model.scale
		character.model.scale = base_model_scale*camera_scale
		character.model.position = camera_position
	else:
		stage.render_target_update_mode = SubViewport.UPDATE_DISABLED
		print("MENU_CHARACTER_FALLBACK ",character.load_error)
	resized.connect(_layout)
	get_window().focus_exited.connect(_focus_exited)
	get_window().focus_entered.connect(_focus_entered)
	get_window().mouse_exited.connect(_mouse_exited)
	_layout()

func _layout() -> void:
	var side: float = minf(size.x,size.y)
	portrait.position = (size-Vector2.ONE*side)*0.5
	portrait.size = Vector2.ONE*side

func _menu_to_local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*point

func menu_to_logical(point: Vector2) -> Vector2:
	return (_menu_to_local(point)-portrait.position)/portrait.size*720.0

func logical_to_menu(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas()*(portrait.position+point/720.0*portrait.size)

func canonical_to_menu(point: Vector2) -> Vector2:
	return logical_to_menu(camera_position+(point-Vector2(360,360))*camera_scale)

func canonical_point(point: Vector2) -> Vector2:
	return (menu_to_logical(point)-camera_position)/camera_scale+Vector2(360,360)

func hits_character(point: Vector2) -> bool:
	if not character.loaded or not portrait.get_rect().has_point(_menu_to_local(point)): return false
	var frame: int = Engine.get_process_frames()
	if alpha_image == null or alpha_frame != frame:
		alpha_image = stage.get_texture().get_image()
		alpha_frame = frame
	var pixel := Vector2i(menu_to_logical(point)/720.0*Vector2(alpha_image.get_size()))
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= alpha_image.get_width() or pixel.y >= alpha_image.get_height(): return false
	return alpha_image.get_pixelv(pixel).a > 0.2

func _input(event: InputEvent) -> void:
	# 注视可以看向左侧菜单；只有点击留到GUI处理之后，避免按钮穿透。
	if event is InputEventMouseMotion and character.loaded and not character.blocked:
		var face: Vector2 = camera_position+(Vector2(360,155)-Vector2(360,360))*camera_scale
		character.set_pointer((menu_to_logical(event.position)-face)/Vector2(320,300))

func _unhandled_input(event: InputEvent) -> void:
	if not character.loaded or character.blocked: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressing = hits_character(event.position)
			if pressing:
				press_position = canonical_point(event.position)
				press_time = Time.get_ticks_msec()
				get_viewport().set_input_as_handled()
		elif pressing:
			pressing = false
			if not hits_character(event.position): return
			var point: Vector2 = canonical_point(event.position)
			var stroke: bool = Time.get_ticks_msec()-press_time > 200 and point.distance_to(press_position) > 16 and point.y < 215
			var kind: String = "pet" if point.y < 145 or stroke else ("cheek" if point.y < 240 else "greet")
			character.request_reaction(kind,signf(point.x-360))
			get_viewport().set_input_as_handled()

func set_suspended(value: bool) -> void:
	suspended = value
	_update_blocked()

func _update_blocked() -> void:
	pressing = false
	character.set_blocked(suspended or not focused)

func _focus_exited() -> void:
	focused = false
	_update_blocked()

func _focus_entered() -> void:
	focused = true
	_update_blocked()

func _mouse_exited() -> void:
	pressing = false
	character.set_pointer(Vector2.ZERO)
