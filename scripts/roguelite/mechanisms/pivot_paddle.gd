extends Node2D
## 可撞转动由刚体和关节求解；脚本只负责配置和显式复位。
@export var initial_angle: float = 0.0
@export var pivot_offset: Vector2 = Vector2.ZERO
@export var initial_angular_velocity: float = 0.0
@export var angle_limit: float = 1.2
@export_range(40.0, 400.0) var length: float = 180.0
var _saved_velocity: Vector2 = Vector2.ZERO
var _saved_spin: float = 0.0
func set_active(value: bool) -> void:
	if $Paddle.freeze == not value:
		return
	if not value:
		_saved_velocity = $Paddle.linear_velocity
		_saved_spin = $Paddle.angular_velocity
	$Paddle.freeze = not value
	if value:
		$Paddle.linear_velocity = _saved_velocity
		$Paddle.angular_velocity = _saved_spin
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# 尺寸只在建立刚体前配置；短翻板的碰撞和画面使用同一长度。
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length, 18.0)
	$Paddle/Shape.shape = shape
	$Paddle/Visual.polygon = PackedVector2Array([Vector2(-length / 2.0, -9), Vector2(length / 2.0, -9), Vector2(length / 2.0, 9), Vector2(-length / 2.0, 9)])
	$Paddle.position = -pivot_offset.rotated(initial_angle)
	$Paddle.rotation = initial_angle
	$Paddle.angular_velocity = initial_angular_velocity
	# 子节点先于父节点ready；偏心摆位之后必须重建关节的局部锚点。
	$Pin.node_b = NodePath("")
	$Pin.node_b = NodePath("../Paddle")
	$Pin.angular_limit_enabled = false
	$Paddle.rest_angle = global_rotation + initial_angle
	$Paddle.angle_limit = absf(angle_limit)
func reset_mechanism() -> void:
	var local := Transform2D(initial_angle, -pivot_offset.rotated(initial_angle))
	$Paddle.request_restore(global_transform * local)
