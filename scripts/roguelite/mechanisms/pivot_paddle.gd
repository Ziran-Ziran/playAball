extends Node2D
## 可撞转动由刚体和关节求解；脚本只负责配置和显式复位。
@export var initial_angle: float = 0.0
@export var pivot_offset: Vector2 = Vector2.ZERO
@export var initial_angular_velocity: float = 0.0
@export var angle_limit: float = 1.2
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
