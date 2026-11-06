extends Node2D
## 只读发射手势，单体素材箭头不参与暂停、冲量或冷却。
@export_enum("Rounded", "Navigation") var arrow_style: int = 0
@export var face_clearance: float = 64.0
@export var arrow_size: float = 52.0
var arena: Node2D
var _head: Sprite2D
var _trail: Sprite2D
var _spark: Sprite2D
var _rounded: Texture2D = preload("res://assets/ui/aim_kenney/pointer_toon_a.png")
var _navigation: Texture2D = preload("res://assets/ui/aim_kenney/navigation_e.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	arena = get_parent()
	_trail = Sprite2D.new()
	_trail.texture = preload("res://assets/ui/aim_kenney/trace_06.png")
	add_child(_trail)
	_spark = Sprite2D.new()
	_spark.texture = preload("res://assets/ui/aim_kenney/light_03.png")
	add_child(_spark)
	_head = Sprite2D.new()
	_head.name = "SingleArrowHead"
	add_child(_head)
	visible = false

func update_indicator() -> void:
	if not is_instance_valid(_head) or not is_instance_valid(arena.launcher):
		return
	var aiming: bool = arena.launcher.aiming
	var recoil: float = clampf(arena._aim_recoil / 0.22, 0.0, 1.0)
	var drag: Vector2 = arena._last_aim_drag
	visible = (aiming or recoil > 0.0) and drag.length() >= 8.0
	if not visible:
		return
	# 素材原始朝向：圆角左上(-135度)，navigation向右；不逆变换镜头。
	var world_direction: Vector2 = drag.normalized()
	global_position = arena.player.global_position
	global_rotation = world_direction.angle()
	var strength: float = clampf(drag.length() / arena.player.max_drag, 0.0, 1.0)
	var extent: float = lerpf(82.0, 150.0, strength)
	var fraction: float = 1.0 if aiming else recoil
	var head_x: float = face_clearance + (extent - face_clearance) * fraction
	_head.texture = _rounded if arrow_style == 0 else _navigation
	_head.rotation = 3.0 * PI / 4.0 if arrow_style == 0 else 0.0
	_head.position = Vector2(head_x, 0)
	var breath: float = 1.0 + 0.035 * sin(arena._aim_phase * TAU)
	_head.scale = Vector2.ONE * arrow_size / maxf(_head.texture.get_width(), _head.texture.get_height()) * breath
	_head.modulate = Color(0.65, 0.97, 1.0, fraction)
	var tail_length: float = maxf(1.0, head_x - face_clearance)
	_trail.rotation = PI / 2.0
	_trail.position = Vector2(face_clearance + tail_length * 0.45, 0)
	_trail.scale = Vector2(0.047, tail_length / 512.0 * 1.7)
	_trail.modulate = Color(0.25, 0.85, 1.0, 0.22 * fraction)
	_spark.position = Vector2(lerpf(face_clearance, head_x, arena._aim_phase), 0)
	_spark.scale = Vector2.ONE * 0.035
	_spark.modulate = Color(0.6, 0.95, 1.0, sin(arena._aim_phase * PI) * 0.32 * fraction)
