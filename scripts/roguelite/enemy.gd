class_name DemoEnemy
extends DemoBody
signal died(enemy: DemoEnemy)
enum Kind { FRAGILE, HEAVY, TURRET }
@export var kind: Kind = Kind.FRAGILE
@export var warning_duration: float = 0.8
@export var attack_cooldown: float = 2.2
@export var approach_force: float = 150.0
@export var approach_speed: float = 75.0
@export var pulse_radius: float = 90.0
@export var charge_range: float = 180.0
@export var charge_speed: float = 420.0
@export var hazard_speed: float = 180.0
@export var hazard_limit: int = 12
var player: DemoPlayer
var health: DemoHealth
var hazards: Node2D
var hp: int = 1
var dead: bool = false
var warning_left: float = 0.0
var attack_left: float = 0.0
var attack_active: bool = false
var charge_left: float = 0.0
var aim_direction: Vector2 = Vector2.RIGHT
var projectile_left: float = 0.0
var projectile_hits_left: int = 0
const HAZARD_SCENE: PackedScene = preload("res://scenes/roguelite/hazard_ball.tscn")

func _ready() -> void:
	super._ready()
	add_to_group("demo_damageable")
	hp = [1, 4, 2][kind]
	mass = 2.8 if kind == Kind.HEAVY else 0.85
	if kind == Kind.HEAVY:
		$Shape.shape = $Shape.shape.duplicate()
		$Shape.shape.radius = 30.0

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
	# 有效命中打断敌人的预警/冲撞，给主动撞击一个防守用途。
	warning_left = 0.0
	attack_active = false
	charge_left = 0.0
	attack_left = attack_cooldown
	if hp == 0:
		dead = true
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		died.emit(self)
		queue_free()
	queue_redraw()

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
	if not is_instance_valid(player) or not is_instance_valid(health) or health.hp <= 0:
		return
	attack_left = maxf(0.0, attack_left - delta)
	var offset: Vector2 = player.global_position - global_position
	if charge_left > 0.0:
		charge_left = maxf(0.0, charge_left - delta)
		attack_active = charge_left > 0.0
		if attack_active and offset.length() < (pulse_radius if kind == Kind.FRAGILE else 59.0):
			health.hurt()
	elif warning_left > 0.0:
		warning_left = maxf(0.0, warning_left - delta)
		if warning_left <= 0.0:
			_release_attack(offset)
	elif attack_left <= 0.0 and (kind == Kind.TURRET or offset.length() < (charge_range if kind == Kind.HEAVY else pulse_radius)):
		warning_left = warning_duration
		aim_direction = offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	elif kind != Kind.TURRET:
		var speed: float = approach_speed * (0.6 if kind == Kind.HEAVY else 1.0)
		var desired: Vector2 = offset.normalized() * speed
		apply_central_force(((desired - linear_velocity) * mass * 3.0).limit_length(approach_force))
	queue_redraw()

func _release_attack(offset: Vector2) -> void:
	attack_left = attack_cooldown
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

func _draw() -> void:
	var color := Color("df866b")
	match kind:
		Kind.FRAGILE:
			draw_rect(Rect2(-19, -19, 38, 38), color)
			draw_line(Vector2(-14, -14), Vector2(14, 14), Color("ffd3a8"), 3)
		Kind.HEAVY:
			draw_circle(Vector2.ZERO, 30, Color("b8a383"))
			draw_rect(Rect2(-23, -11, 46, 22), Color("695973"))
			for index in hp:
				draw_circle(Vector2(-15 + index * 10, 0), 3, Color("fff1c9"))
		Kind.TURRET:
			draw_colored_polygon(PackedVector2Array([Vector2(-22, 20), Vector2(22, 20), Vector2(0, -25)]), Color("c39ac9"))
			draw_line(Vector2.ZERO, aim_direction * 33, Color("f1c6df"), 9)
	if warning_left > 0.0 or attack_active:
		var radius: float = pulse_radius if kind == Kind.FRAGILE else 40.0
		draw_circle(Vector2.ZERO, radius, Color(1, 0.35, 0.25, 0.22) if attack_active else Color("ffac64"), attack_active, -1.0 if attack_active else 2.0, true)
		if kind != Kind.FRAGILE:
			draw_line(aim_direction * 40, aim_direction * 115, Color("ffac64"), 3)
