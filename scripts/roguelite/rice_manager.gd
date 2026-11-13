class_name RiceManager
extends Node2D
signal eaten(point: Vector2)
@export_range(1, 20) var heal_amount: int = 1
@export var spawn_interval: float = 12.0
@export var safe_bounds: Rect2 = Rect2(140, 190, 1000, 430)
@export var player_clearance: float = 180.0
@export var spawn_points: Array[Vector2] = [Vector2(400, 250), Vector2(880, 550), Vector2(880, 250), Vector2(400, 550), Vector2(640, 250), Vector2(640, 400)]
var player: DemoPlayer
var health: DemoHealth
var enemies: Node2D
var map_provider: Node
var rice: DemoRice
var elapsed: float = 0.0
var _spawn_cursor: int = 0
const RICE_SCENE: PackedScene = preload("res://scenes/roguelite/rice_lure.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func configure(new_player: DemoPlayer, new_health: DemoHealth, new_enemies: Node2D) -> void:
	player = new_player
	health = new_health
	enemies = new_enemies

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.reset_pending:
		return
	# 满血/死亡不积攒生成时间，重新受伤后再等一个完整周期。
	if not _needs_healing():
		elapsed = 0.0
		return
	elapsed += delta
	if elapsed >= maxf(0.1, spawn_interval):
		elapsed = fmod(elapsed, maxf(0.1, spawn_interval))
		spawn_rice()

func spawn_rice() -> bool:
	if not _needs_healing() or not is_inside_tree() or not is_instance_valid(player) or (is_instance_valid(rice) and rice.is_inside_tree()):
		return false
	for index in spawn_points.size():
		var candidate: Vector2 = spawn_points[(_spawn_cursor + index) % spawn_points.size()]
		if not can_spawn_at(candidate):
			continue
		_spawn_cursor = (_spawn_cursor + index + 1) % spawn_points.size()
		rice = RICE_SCENE.instantiate()
		rice.player = player
		rice.position = to_local(candidate)
		rice.collected.connect(_on_collected)
		add_child(rice)
		return true
	return false

func can_spawn_at(point: Vector2) -> bool:
	if not is_inside_tree() or not is_instance_valid(player) or not safe_bounds.has_point(point) or point.distance_to(player.global_position) < player_clearance:
		return false
	if is_instance_valid(map_provider) and not map_provider.point_safe(point, 36.0):
		return false
	if is_instance_valid(enemies):
		for enemy in enemies.get_children():
			if enemy is DemoEnemy and (enemy.warning_left > 0.0 or enemy.attack_active):
				var offset: Vector2 = point - enemy.global_position
				if enemy.kind == DemoEnemy.Kind.FRAGILE and offset.length() < enemy.pulse_radius + 60.0:
					return false
				if enemy.kind != DemoEnemy.Kind.FRAGILE and _in_warning_lane(offset, enemy.aim_direction, 110.0, 1400.0 if enemy.kind == DemoEnemy.Kind.TURRET else 400.0):
					return false
			if enemy is DemoBoss:
				if enemy.wave_warning_left > 0.0 and point.distance_to(enemy.wave_origin) <= enemy.wave_max_radius + 60.0:
					return false
				if enemy.phase in [DemoBoss.Phase.WARNING, DemoBoss.Phase.CHARGE] and _in_warning_lane(point - enemy.global_position, enemy.charge_direction, 150.0, 1400.0):
					return false
	# 拒绝实际墙/挡板/箱体覆盖的位置，候选为空时等下一轮，不强行贴脸生成。
	var shape := CircleShape2D.new()
	shape.radius = 36.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 25
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _in_warning_lane(offset: Vector2, direction: Vector2, width: float, distance: float) -> bool:
	var forward: float = offset.dot(direction)
	return forward >= -60.0 and forward <= distance and absf(offset.cross(direction)) < width

func _needs_healing() -> bool:
	return is_instance_valid(health) and health.hp > 0 and health.hp < health.max_hp

func _on_collected(bowl: DemoRice) -> void:
	if not is_inside_tree() or bowl != rice or not bowl.is_inside_tree() or not _needs_healing():
		return
	# 治疗只发布生命变化，不触发受伤事件，也不修改冷却或碰撞伤害。
	health.hp = mini(health.max_hp, health.hp + maxi(1, heal_amount))
	health.changed.emit(health.hp)
	eaten.emit(bowl.global_position)

func reset_rice() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	rice = null
	elapsed = 0.0
	_spawn_cursor = 0

func _exit_tree() -> void:
	reset_rice()
