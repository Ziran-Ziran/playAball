extends RigidBody2D
@export_range(0.1, 4.0) var max_angular_speed: float = 1.2
var rest_angle: float = 0.0
var angle_limit: float = 0.0
var _restore: bool = false
var _restore_transform: Transform2D
func request_restore(value: Transform2D) -> void:
	_restore_transform = value
	_restore = true
	sleeping = false
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _restore:
		state.transform = _restore_transform
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		_restore = false
	# 内置Pin限位在当前Godot Physics中会越界并持续加速；保留真实轴心约束，
	# 限制向外转速；求解误差仅用有限向内速度消除，不逐帧改刚体位置/角度。
	var spin := clampf(state.angular_velocity, -max_angular_speed, max_angular_speed)
	if angle_limit > 0.0:
		var angle := angle_difference(rest_angle, state.transform.get_rotation())
		var step := maxf(state.step, 0.0001)
		if spin > 0.0:
			spin = minf(spin, maxf(0.0, angle_limit - angle) / step)
		elif spin < 0.0:
			spin = maxf(spin, minf(0.0, -angle_limit - angle) / step)
		# 接触求解在积分回调之后仍可能产生微小越界；否则重复撞击会累积漂移。
		if angle > angle_limit:
			spin = minf(spin, -minf(max_angular_speed, (angle - angle_limit) * 12.0))
		elif angle < -angle_limit:
			spin = maxf(spin, minf(max_angular_speed, (-angle_limit - angle) * 12.0))
	state.angular_velocity = spin
