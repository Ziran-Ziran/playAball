class_name DemoEnemy
extends DemoBody
signal died(enemy: DemoEnemy)
## 玩法只发布只读快照；表现组件不得通过它修改生命、碰撞或攻击状态。
signal presentation_changed(snapshot: Dictionary)
signal presentation_event(event: StringName, payload: Dictionary)
enum Kind { FRAGILE, HEAVY, TURRET }
@export var kind: Kind = Kind.FRAGILE
@export var warning_duration: float = 0.8
@export var attack_cooldown: float = 2.2
@export var approach_force: float = 150.0
@export var approach_speed: float = 75.0
@export var pulse_radius: float = 90.0
@export var charge_range: float = 180.0
@export var attack_range: float = 480.0
@export var hit_points_override: int = 0
@export var charge_speed: float = 420.0
@export var hazard_speed: float = 180.0
@export var hazard_limit: int = 12
var player: DemoPlayer
var health: DemoHealth
var hazards: Node2D
@export var hit_stagger: float = 0.65
var stagger_left: float = 0.0
var hp: int = 1
var dead: bool = false
var warning_left: float = 0.0
var attack_left: float = 0.0
var attack_active: bool = false
var charge_left: float = 0.0
var aim_direction: Vector2 = Vector2.RIGHT
var projectile_left: float = 0.0
var projectile_hits_left: int = 0
var max_hp: int = 1
const HAZARD_SCENE: PackedScene = preload("res://scenes/roguelite/hazard_ball.tscn")
@onready var presentation: Node2D = $Presentation

func apply_attack_scale(scale: float) -> void:
	# 从基准重算，重复应用升级不会把半径指数压小，也不触碰实体形状。
	pulse_radius = 90.0 * clampf(scale, 0.7, 1.0)
	_notify_presentation(&"range_changed")

func _ready() -> void:
	super._ready()
	add_to_group("demo_damageable")
	hp = hit_points_override if hit_points_override > 0 else [1, 4, 2][kind]
	max_hp = hp
	mass = 0.55 if kind == Kind.HEAVY else 0.2
	if kind == Kind.HEAVY:
		$Shape.shape = $Shape.shape.duplicate()
		$Shape.shape.radius = 30.0
	_attach_presentation(presentation)
	_notify_presentation(&"initialized")

func _attach_presentation(view: Node2D) -> void:
	if not is_instance_valid(view):
		return
	presentation = view
	if view.has_method("bind_source"):
		view.call("bind_source", self)

func presentation_snapshot() -> Dictionary:
	# 这是表现层唯一需要的 actor 数据面；不暴露可写的生命或物理引用。
	return {
		"entity_id": get_instance_id(),
		"kind": int(kind),
		"kind_name": ["fragile", "heavy", "turret"][kind],
		"hp": hp,
		"max_hp": max_hp,
		"dead": dead,
		"warning_left": warning_left,
		"warning_fraction": warning_left / maxf(0.001, warning_duration),
		"attack_active": attack_active,
		"stagger_left": stagger_left,
		"aim_direction": aim_direction,
		"linear_velocity": linear_velocity,
		"pulse_radius": pulse_radius,
		"attack_range": pulse_radius if kind == Kind.FRAGILE else charge_range if kind == Kind.HEAVY else attack_range,
	}

func _notify_presentation(event: StringName, payload: Dictionary = {}) -> void:
	if not is_inside_tree():
		return
	presentation_changed.emit(presentation_snapshot())
	presentation_event.emit(event, payload)

func attacking() -> bool:
	return not dead and chain_id > 0 and projectile_left > 0.0 and projectile_hits_left > 0

func make_projectile(chain: int) -> void:
	if dead or chain <= 0:
		return
	chain_id = chain
	projectile_left = 0.6
	projectile_hits_left = 2
	warning_left = 0.0
	attack_active = false
	charge_left = 0.0
	attack_left = attack_cooldown

func hurt(amount: int) -> void:
	if dead or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	stagger_left = maxf(0.0, hit_stagger)
	# 有效命中打断敌人的预警/冲撞，给主动撞击一个防守用途。
	warning_left = 0.0
	attack_active = false
	charge_left = 0.0
	attack_left = attack_cooldown
	_notify_presentation(&"hurt", {"amount": amount, "hp": hp})
	if hp == 0:
		dead = true
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		_notify_presentation(&"died", {"point": global_position, "entire_family": false})
		died.emit(self)
		queue_free()

func _physics_process(delta: float) -> void:
	if dead:
		return
	# 攻击体窗口期间保留惯性，不施加追踪力或继续敌方攻击。
	if projectile_left > 0.0:
		projectile_left = maxf(0.0, projectile_left - delta)
		if projectile_left <= 0.0:
			chain_id = 0
			projectile_hits_left = 0
		return
	# 受击后保留击退惯性，不立刻用追踪力刹住击退并贴回玩家。
	if stagger_left > 0.0:
		stagger_left = maxf(0.0, stagger_left - delta)
		return
	if not is_instance_valid(player) or not is_instance_valid(health) or health.hp <= 0:
		return
	attack_left = maxf(0.0, attack_left - delta)
	var offset: Vector2 = player.global_position - global_position
	if not _within_attack_range(offset) and (warning_left > 0.0 or charge_left > 0.0 or attack_active):
		_cancel_attack(&"out_of_range")
	if charge_left > 0.0:
		charge_left = maxf(0.0, charge_left - delta)
		attack_active = charge_left > 0.0
		if attack_active and offset.length() < (pulse_radius if kind == Kind.FRAGILE else 59.0):
			health.hurt()
	elif warning_left > 0.0:
		warning_left = maxf(0.0, warning_left - delta)
		if warning_left <= 0.0:
			_release_attack(offset)
	elif attack_left <= 0.0 and _within_attack_range(offset):
		warning_left = warning_duration
		aim_direction = offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
		_notify_presentation(&"warning_started")
	elif kind != Kind.TURRET:
		var speed: float = approach_speed * (0.6 if kind == Kind.HEAVY else 1.0)
		var desired: Vector2 = offset.normalized() * speed
		apply_central_force(((desired - linear_velocity) * mass * 3.0).limit_length(approach_force))

func _within_attack_range(offset: Vector2) -> bool:
	var radius: float = pulse_radius if kind == Kind.FRAGILE else charge_range if kind == Kind.HEAVY else attack_range
	return offset.length() <= maxf(0.0, radius)

func _cancel_attack(reason: StringName = &"cancelled") -> void:
	# 离开范围立即撤销危险资格；保留真实惯性，不用强制改速度来停冲撞。
	warning_left = 0.0
	attack_active = false
	charge_left = 0.0
	attack_left = 0.0
	_notify_presentation(&"attack_cancelled", {"reason": String(reason)})

func _release_attack(offset: Vector2) -> void:
	# 释放点再次确认，不能把已经过期的预警带到范围外。
	if not _within_attack_range(offset):
		_cancel_attack(&"out_of_range_release")
		return
	attack_left = attack_cooldown
	_notify_presentation(&"attack_released")
	match kind:
		Kind.FRAGILE:
			attack_active = true
			charge_left = 0.16
			if offset.length() <= pulse_radius:
				health.hurt()
		Kind.HEAVY:
			attack_active = true
			charge_left = 0.4
			# 仅注入一次冲量，之后撞墙反弹由引擎处理，不持续拐弯追人。
			apply_central_impulse(aim_direction * charge_speed * mass)
		Kind.TURRET:
			if not is_instance_valid(hazards) or hazards.get_child_count() >= mini(hazard_limit, 12):
				return
			var shot: DemoHazard = HAZARD_SCENE.instantiate()
			shot.health = health
			# 在进入物理世界前完成初态，避免首帧错误地出现在容器原点。
			shot.position = hazards.to_local(global_position + aim_direction * 43.0)
			shot.linear_velocity = aim_direction * hazard_speed
			hazards.add_child(shot)
