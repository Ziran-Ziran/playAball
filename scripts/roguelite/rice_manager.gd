class_name RiceManager
extends Node2D
signal eaten(point: Vector2)
@export var spawn_interval: float = 12.0
@export var safe_bounds: Rect2 = Rect2(140, 190, 1000, 430)
@export var player_clearance: float = 180.0
@export var spawn_points: Array[Vector2] = [Vector2(400, 250), Vector2(880, 550), Vector2(880, 250), Vector2(400, 550), Vector2(640, 250), Vector2(640, 400)]
var player: DemoPlayer
var launcher: DemoLaunch
var enemies: Node2D
var rice: DemoRice
var elapsed: float = 0.0
var stored_bonus: bool = false
var bound_chain: int = 0
var _spawn_cursor: int = 0
const RICE_SCENE: PackedScene = preload("res://scenes/roguelite/rice_lure.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func configure(new_player: DemoPlayer, new_launcher: DemoLaunch, new_enemies: Node2D) -> void:
	player = new_player
	launcher = new_launcher
	enemies = new_enemies

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.reset_pending:
		return
	elapsed += delta
	if elapsed >= maxf(0.1, spawn_interval):
		elapsed = fmod(elapsed, maxf(0.1, spawn_interval))
		spawn_rice()

func spawn_rice() -> bool:
	if not is_inside_tree() or not is_instance_valid(player) or (is_instance_valid(rice) and rice.is_inside_tree()):
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

func _on_collected(bowl: DemoRice) -> void:
	if not is_inside_tree() or bowl != rice or not bowl.is_inside_tree():
		return
	# 再吃一碗刷新待绑定强化，不叠层，也不把新强化交给旧飞行链。
	stored_bonus = true
	bound_chain = 0
	if is_instance_valid(launcher) and launcher.has_method("refund_cooldown"):
		launcher.call("refund_cooldown", 0.6)
	eaten.emit(bowl.global_position)

func bind_launch(chain: int) -> void:
	if stored_bonus and chain > 0:
		bound_chain = chain

func consume_bonus(chain: int) -> int:
	if not stored_bonus or chain <= 0 or chain != bound_chain:
		return 0
	stored_bonus = false
	bound_chain = 0
	return 1

func reset_rice() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	rice = null
	elapsed = 0.0
	stored_bonus = false
	bound_chain = 0
	_spawn_cursor = 0

func _exit_tree() -> void:
	reset_rice()
