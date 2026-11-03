class_name DemoBoss
extends DemoBody
## 核心和模块共享同一个刚体；模块只增减碰撞形状，不产生嵌套物理体。
signal died(boss: DemoBoss)
signal summon_requested(point: Vector2)
signal presentation_event(event: StringName, payload: Dictionary)
enum Phase { WARNING, CHARGE, EXPOSED, RECOVERY }
@export var core_hit_points: int = 45
@export var module_hit_points: int = 3
@export var warning_duration: float = 1.0
@export var exposed_duration: float = 2.0
@export var recovery_duration: float = 1.0
@export var charge_speed: float = 850.0
@export var charge_timeout: float = 2.5
@export var wave_speed: float = 110.0
@export var wave_max_radius: float = 330.0
@export var wave_half_gap: float = PI / 3.0
var player: DemoPlayer
var health: Node
var hp: int = 45
var dead: bool = false
var phase: Phase = Phase.WARNING
var phase_left: float = 1.0
var charge_direction: Vector2 = Vector2.DOWN
var module_hp: Array[int] = []
var wave_origin: Vector2
var wave_radius: float = 70.0
var wave_warning_left: float = 0.0
var wave_active: bool = false
var _wave_hit: bool = false
var _charge_hit: bool = false
var _charge_revision: int = 0
var _wave_safe_direction: Vector2 = Vector2.UP
var _fight_elapsed: float = 0.0

func apply_attack_scale(scale: float) -> void:
	# 缩小远程震波范围；冲撞仍按模块/核心的真实刚体接触伤害。
	wave_max_radius = 330.0 * clampf(scale, 0.7, 1.0)
	queue_redraw()

func _ready() -> void:
	super._ready()
	add_to_group("demo_damageable")
	hp = core_hit_points
	for index in 4:
		module_hp.append(module_hit_points)
	begin_warning()

func begin_warning() -> void:
	_charge_revision += 1
	phase = Phase.WARNING
	# 超过90秒只缩短恢复间隔，仍保留完整一秒预警。
	phase_left = warning_duration
	if is_instance_valid(player):
		charge_direction = (player.global_position - global_position).normalized()
		if charge_direction.is_zero_approx():
			charge_direction = Vector2.DOWN
	_charge_hit = false
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead or reset_pending:
		return
	_fight_elapsed += delta
	phase_left -= delta
	if phase != Phase.CHARGE:
		# 用制动力消除冲刺惯性，弱点阶段不瞬移、不直接写刚体速度。
		apply_central_force(-linear_velocity * mass * 12.0)
	match phase:
		Phase.WARNING:
			if phase_left <= 0.0:
				phase = Phase.CHARGE
				phase_left = charge_timeout
				apply_central_impulse((charge_direction * charge_speed - linear_velocity) * mass)
		Phase.CHARGE:
			if phase_left <= 0.0:
				_begin_recovery(false)
		Phase.EXPOSED:
			if phase_left <= 0.0:
				_begin_recovery(true)
		Phase.RECOVERY:
			if phase_left <= 0.0:
				begin_warning()
	_tick_wave(delta)
	queue_redraw()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var was_resetting: bool = reset_pending
	super._integrate_forces(state)
	if dead or was_resetting or phase != Phase.CHARGE:
		return
	var hit_wall: bool = false
	for index in state.get_contact_count():
		var other: Object = state.get_contact_collider_object(index)
		if other == player and is_instance_valid(player) and not player.reset_pending and not _charge_hit and is_instance_valid(health):
			# 模块也属于同一刚体，必须读取真实接触，不能按核心中心距漏判或扩大空气伤害。
			_charge_hit = true
			publish_charge_hit.call_deferred(player.get_instance_id(), health.get_instance_id(), _charge_revision, _reset_revision, player._reset_revision)
		# 只有场景墙/挡板撞击才开弱点；箱体、球与小怪不触发。
		if other is PhysicsBody2D and other.collision_layer & 17 != 0:
			hit_wall = true
	if hit_wall:
		phase = Phase.EXPOSED
		phase_left = exposed_duration
		wave_origin = state.transform.origin
		wave_radius = 70.0
		wave_warning_left = warning_duration
		_wave_safe_direction = -charge_direction
		wave_active = true
		_wave_hit = false

func publish_charge_hit(player_id: int, health_id: int, attack_revision: int, boss_revision: int, player_revision: int) -> void:
	# 接触与扣血之间可能死亡、复位或换局，旧攻击不得命中新实例/新生命。
	if dead or is_queued_for_deletion() or not is_inside_tree() or reset_pending or boss_revision != _reset_revision or attack_revision != _charge_revision:
		return
	if phase != Phase.CHARGE and phase != Phase.EXPOSED:
		return
	if not is_instance_valid(player) or player.is_queued_for_deletion() or player.reset_pending or player.get_instance_id() != player_id or player._reset_revision != player_revision:
		return
	if not is_instance_valid(health) or health.is_queued_for_deletion() or health.get_instance_id() != health_id:
		return
	_hurt_player()

func _begin_recovery(summon: bool) -> void:
	phase = Phase.RECOVERY
	phase_left = recovery_duration * (0.5 if _fight_elapsed > 90.0 else 1.0)
	if summon:
		# 上限由整局控制器统一计数；这里每轮仅发两个位置请求。
		summon_requested.emit(global_position + Vector2(-85, 70))
		summon_requested.emit(global_position + Vector2(85, 70))

func wave_is_safe(point: Vector2) -> bool:
	var offset: Vector2 = point - wave_origin
	return absf(_wave_safe_direction.angle_to(offset)) <= wave_half_gap

func _tick_wave(delta: float) -> void:
	if not wave_active:
		return
	if wave_warning_left > 0.0:
		wave_warning_left = maxf(0.0, wave_warning_left - delta)
		return
	wave_radius += wave_speed * delta
	if wave_radius >= wave_max_radius:
		wave_active = false
		return
	if not _wave_hit and is_instance_valid(player):
		var distance: float = player.global_position.distance_to(wave_origin)
		if absf(distance - wave_radius) <= 37.0 and not wave_is_safe(player.global_position):
			_wave_hit = true
			_hurt_player()

func _hurt_player() -> void:
	if is_instance_valid(health) and health.has_method("hurt"):
		health.hurt(1)

func hurt_at(amount: int, point: Vector2) -> void:
	if dead or amount <= 0:
		return
	var local_point: Vector2 = to_local(point)
	for index in 4:
		var shape: CollisionShape2D = get_node("Module%d" % index)
		if module_hp[index] > 0 and local_point.distance_to(shape.position) <= 25.0:
			var effective: int = mini(module_hp[index],amount)
			module_hp[index] = maxi(0, module_hp[index] - amount)
			presentation_event.emit(&"module_hurt",{"amount":effective,"point":shape.position,"index":index})
			if module_hp[index] == 0:
				shape.set_deferred("disabled", true)
			queue_redraw()
			return
	hurt(amount)

func hurt(amount: int) -> void:
	if dead or amount <= 0:
		return
	var damage: int = amount if phase == Phase.EXPOSED else ceili(amount * 0.5)
	var effective: int = mini(hp,damage)
	hp = maxi(0, hp - damage)
	presentation_event.emit(&"core_hurt",{"amount":effective,"point":Vector2.ZERO})
	if hp == 0:
		dead = true
		wave_active = false
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		died.emit(self)
	queue_redraw()

func presentation_snapshot() -> Dictionary:
	var modules: Array[Dictionary] = []
	for index in module_hp.size():
		modules.append({"point":get_node("Module%d"%index).position,"hp":module_hp[index],"max_hp":module_hit_points})
	return {"hp":hp,"max_hp":core_hit_points,"dead":dead,"phase":int(phase),"phase_left":phase_left,"modules":modules,"charge_direction":charge_direction,"wave_active":wave_active,"wave_center":to_local(wave_origin),"wave_radius":wave_radius,"wave_warning_left":wave_warning_left,"safe_direction":_wave_safe_direction,"wave_half_gap":wave_half_gap}
