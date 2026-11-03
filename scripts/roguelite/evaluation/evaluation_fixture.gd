extends Node2D
## 仅用于独立评估。初始位置/构筑可设定，运行中操作只能通过DemoLaunch。
var scenario: String
var bounds: Rect2 = Rect2(40,125,1200,553)
var player: DemoPlayer
var launcher: DemoLaunch
var combat: DemoCombat
var companions: DemoCompanions
var health: DemoHealth
var enemies: Node2D
var hazards: Node2D
var build := DemoBuild.new()
var metrics: RefCounted
var measuring: bool = false
var seed_value: int
func configure(id: String, rng_seed: int, build_ids: PackedStringArray = []) -> void:
	scenario = id
	seed_value = rng_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	if id == "reverse": bounds = Rect2(40,125,4960,553)
	make_wall(Vector2(bounds.get_center().x, bounds.position.y - 12), Vector2(bounds.size.x,24))
	make_wall(Vector2(bounds.get_center().x, bounds.end.y + 12), Vector2(bounds.size.x,24))
	make_wall(Vector2(bounds.position.x - 12, bounds.get_center().y), Vector2(24,bounds.size.y))
	make_wall(Vector2(bounds.end.x + 12, bounds.get_center().y), Vector2(24,bounds.size.y))
	player = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = Vector2(420,450)
	if id == "corner": player.position = Vector2(95,620)
	if id == "reverse": player.position = Vector2(350,450)
	if id == "mechanisms": player.position = Vector2(280,400)
	player.contact_diagnostics_enabled = true
	add_child(player)
	launcher = DemoLaunch.new()
	launcher.player = player
	add_child(launcher)
	combat = DemoCombat.new()
	add_child(combat)
	player.contact_report.connect(combat.resolve)
	health = DemoHealth.new()
	add_child(health)
	enemies = Node2D.new()
	add_child(enemies)
	hazards = Node2D.new()
	add_child(hazards)
	companions = DemoCompanions.new()
	companions.player = player
	companions.combat = combat
	add_child(companions)
	var ids: PackedStringArray = build_ids
	if id == "relay" and ids.is_empty(): ids = PackedStringArray(["companion","companion","relay"])
	for upgrade in ids: build.choose(upgrade)
	health.max_hp = build.max_health()
	health.reset_health()
	combat.build = build
	player.apply_launch_stats(build.launch_multiplier(), build.damping_multiplier(), build.friction_multiplier())
	launcher.cooldown = build.launch_cooldown()
	launcher.set_capacity(build.launch_capacity())
	companions.set_follow_enabled(build.has_upgrade("follow"))
	companions.ensure_count(build.companion_count())
	for i in companions.members.size():
		companions.members[i].arena_bounds = bounds
		companions.members[i].reset_body(Vector2(550 + i * 105,450))
	var count: int = 6 if id == "crowd" else (3 if id in ["relay","relay_fan","mechanisms"] else 1)
	if id == "corner": make_wall(Vector2(260,570), Vector2(18,150))
	if id == "mechanisms":
		var map = load("res://scenes/roguelite/maps/map_03.tscn").instantiate()
		add_child(map)
		for component in map.find_children("*", "Node2D", true, false):
			if component.is_in_group("map_spikes"):
				component.player = player
				component.health = health
			if "player_health" in component: component.player_health = health
	for index in count:
		var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
		enemy.kind = DemoEnemy.Kind.HEAVY if id == "single" or (id == "crowd" and index >= 4) else DemoEnemy.Kind.FRAGILE
		enemy.position = Vector2(800 + (index % 3) * 70, 390 + (index / 3) * 90)
		if id in ["single","relay"]: enemy.position = Vector2(810 + index * 70,450)
		# 侧向靶避免主球沿直线先清空全部目标，使伙伴命中可被独立观测。
		if id == "relay_fan": enemy.position = [Vector2(810,350),Vector2(880,550),Vector2(990,350)][index]
		if id == "reverse": enemy.position = Vector2(160,450)
		if id == "corner": enemy.position = Vector2(600,450)
		if id == "mechanisms": enemy.position = Vector2(980 + (index % 2) * 60,350 + index * 45)
		enemy.position += Vector2(rng.randf_range(-8,8), rng.randf_range(-8,8))
		enemy.player = player
		enemy.health = health
		enemy.hazards = hazards
		enemy.contact_diagnostics_enabled = true
		enemies.add_child(enemy)
		enemy.apply_attack_scale(build.attack_radius_scale())
		enemy.set_physics_process(id in ["crowd","corner","mechanisms"])
		enemy.contact_report.connect(combat.resolve)
	var assists := DemoAssistEffects.new()
	assists.player = player
	assists.enemies = enemies
	assists.build = build
	add_child(assists)
func make_wall(point: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = point
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
func begin_measurement() -> void:
	metrics = load("res://scripts/roguelite/evaluation/metrics_recorder.gd").new()
	metrics.bind(self)
	for spikes in get_tree().get_nodes_in_group("map_spikes"):
		spikes.player_hit.connect(func(_point): metrics.spike_hits += 1)
	for node in find_children("*", "Node2D", true, false):
		if node.has_signal("teleport_requested"):
			node.teleport_requested.connect(func(_body, _point): metrics.portal_requests += 1)
	measuring = true
func _physics_process(delta: float) -> void:
	if measuring:
		metrics.tick(delta)
func _exit_tree() -> void:
	# 信号闭包持有Recorder，Recorder反向引用夹具；显式断开避免长矩阵泄漏。
	if is_instance_valid(metrics): metrics.fixture = null
