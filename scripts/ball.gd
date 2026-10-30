class_name PlayBall
extends RigidBody2D
## 刚体仅接收冲量；位置复位在 _integrate_forces 中完成。

signal impacted(point: Vector2, strength: float)

@export var max_drag: float = 180.0
@export var max_impulse: float = 1050.0
@export var stop_speed: float = 22.0
@export var settle_time: float = 0.3
@export var impact_threshold: float = 75.0
@export var base_damping: float = 0.3

var completed: bool = false
var _still_time: float = 0.0
var _impact_cooldown: float = 0.0
var _reset_requested: bool = false
var _reset_position: Vector2
var _previous_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	linear_damp = base_damping
	contact_monitor = true
	max_contacts_reported = 8
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	lock_rotation = true

func can_launch() -> bool:
	return not completed and _still_time >= settle_time and linear_velocity.length() < stop_speed

func impulse_for_drag(drag: Vector2) -> Vector2:
	return drag.limit_length(max_drag) * max_impulse / max_drag

func launch(drag: Vector2) -> bool:
	if not can_launch() or drag.length() < 8.0:
		return false
	_still_time = 0.0
	sleeping = false
	apply_central_impulse(impulse_for_drag(drag))
	return true

func reset_ball(point: Vector2) -> void:
	_reset_position = point
	_reset_requested = true
	completed = false
	freeze = false
	sleeping = false
	_still_time = 0.0
	gravity_scale = 1.0
	linear_damp = base_damping

func _physics_process(delta: float) -> void:
	if linear_velocity.length() < stop_speed:
		_still_time += delta
	else:
		_still_time = 0.0
	_impact_cooldown = maxf(0.0, _impact_cooldown - delta)
	queue_redraw()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _reset_requested:
		state.transform = Transform2D(0.0, _reset_position)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		_previous_velocity = Vector2.ZERO
		_reset_requested = false
		return
	state.linear_velocity = state.linear_velocity.limit_length(1500.0)
	var strongest: float = 0.0
	var point: Vector2 = global_position
	for index in state.get_contact_count():
		# 部分 2D 后端不提供有效接触冲量；用上一物理帧的入射法线速度补足。
		# 该值用于表现强弱，不宣称为真实冲量或能量。
		var relative: Vector2 = _previous_velocity - state.get_contact_collider_velocity_at_position(index)
		var normal: Vector2 = state.get_contact_local_normal(index)
		var strength: float = maxf(state.get_contact_impulse(index).length() / mass, -relative.dot(normal))
		if strength > strongest:
			strongest = strength
			# 返回的接触点已经是世界坐标，不重复变换。
			point = state.get_contact_local_position(index)
	_previous_velocity = state.linear_velocity
	if strongest >= impact_threshold and _impact_cooldown <= 0.0:
		_impact_cooldown = 0.09
		impacted.emit.call_deferred(point, strongest)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color(0.15, 0.85, 1.0, 0.09))
	draw_circle(Vector2.ZERO, 16.0, Color("71e5ef"))
	draw_circle(Vector2(-4, -5), 6.0, Color("ddfbff"))
	draw_arc(Vector2.ZERO, 20.0, 0, TAU, 48, Color("b6f5ff") if can_launch() else Color("23687d"), 1.5, true)
