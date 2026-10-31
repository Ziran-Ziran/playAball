class_name DemoBody
extends RigidBody2D
## 所有位置修复只在物理状态接口执行；正常运动只受力和冲量驱动。
signal contact_report(actor: DemoBody, other: Node, speed: float, point: Vector2)
signal impacted(point: Vector2, strength: float)
@export var speed_limit: float = 1500.0
var chain_id: int = 0
var generation: int = 0
var incoming_velocity: Vector2 = Vector2.ZERO
var _previous_velocity: Vector2 = Vector2.ZERO
var _velocity_frame: int = -1
var reset_pending: bool = false
var reset_point: Vector2
var _feedback_left: float = 0.0
var _reset_revision: int = 0

func _ready() -> void:
	# 新玩法派生刚体统一禁用环境重力，旧原型不继承此类。
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 12
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	lock_rotation = true

func attacking() -> bool:
	return chain_id > 0

func reset_body(point: Vector2) -> void:
	_reset_revision += 1
	_feedback_left = 0.0
	reset_point = point
	reset_pending = true
	chain_id = 0
	generation = 0
	sleeping = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if reset_pending:
		state.transform = Transform2D(0.0, reset_point)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		incoming_velocity = Vector2.ZERO
		_previous_velocity = Vector2.ZERO
		_velocity_frame = Engine.get_physics_frames()
		reset_pending = false
		return
	state.linear_velocity = state.linear_velocity.limit_length(speed_limit)
	_feedback_left = maxf(0.0, _feedback_left - state.step)
	for index in state.get_contact_count():
		var other: Object = state.get_contact_collider_object(index)
		if not other is Node:
			continue
		var other_velocity: Vector2 = state.get_contact_collider_velocity_at_position(index)
		if other is DemoBody:
			other_velocity = other.velocity_for_contact(Engine.get_physics_frames())
		var speed: float = maxf(0.0, -(incoming_velocity - other_velocity).dot(state.get_contact_local_normal(index)))
		# API 名称中的 local 指本体，返回值已经是世界坐标，不能再乘 transform。
		var point: Vector2 = state.get_contact_local_position(index)
		# 目标受击由统一战斗信号反馈，避免同一接触播放两次。
		if not (other is DemoTarget or other.is_in_group("demo_damageable")) and speed >= 75.0 and _feedback_left <= 0.0:
			_feedback_left = 0.09
			publish_impact.call_deferred(point, speed, _reset_revision)
		if attacking():
			# 延后避开物理锁，并保留事件产生时的发射编号，丢弃复位前的过期事件。
			publish_contact.call_deferred(other.get_instance_id(), speed, point, chain_id, _reset_revision)
	_previous_velocity = incoming_velocity
	incoming_velocity = state.linear_velocity
	_velocity_frame = Engine.get_physics_frames()
	queue_redraw()

func velocity_for_contact(frame: int) -> Vector2:
	# 本帧已经回调过的刚体须回读上一份快照，避免误用撞飞后的速度漏伤。
	return _previous_velocity if _velocity_frame == frame else incoming_velocity

func publish_impact(point: Vector2, speed: float, revision: int) -> void:
	if revision == _reset_revision and not reset_pending:
		impacted.emit(point, speed)

func publish_contact(other_id: int, speed: float, point: Vector2, chain: int, revision: int) -> void:
	var other: Object = instance_from_id(other_id)
	if other is Node and revision == _reset_revision and chain == chain_id and not reset_pending:
		contact_report.emit(self, other, speed, point)
