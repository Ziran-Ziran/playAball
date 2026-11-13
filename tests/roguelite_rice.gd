extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Rice test timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in ceili(count * Engine.physics_ticks_per_second / 60.0):
		await physics_frame

func run() -> void:
	for path in ["res://scripts/roguelite/rice_manager.gd", "res://scenes/roguelite/rice_lure.tscn"]:
		check(ResourceLoader.exists(path), "Rice resource exists: " + path)
	if failures > 0:
		quit(1)
		return
	var arena := Node2D.new()
	root.add_child(arena)
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = Vector2(640, 540)
	arena.add_child(player)
	var launcher: DemoLaunch = load("res://scripts/roguelite/launch_controller.gd").new()
	launcher.player = player
	arena.add_child(launcher)
	launcher.set_process(false)
	var enemies := Node2D.new()
	arena.add_child(enemies)
	var health := DemoHealth.new()
	arena.add_child(health)
	var manager := RiceManager.new()
	manager.configure(player, health, enemies)
	arena.add_child(manager)
	manager.set_physics_process(false)
	check(not manager.spawn_rice(), "Full health blocks direct rice spawning")
	manager._physics_process(12.1)
	check(manager.get_child_count() == 0 and manager.elapsed == 0.0, "Full health blocks periodic spawning and clears timer")
	health.hp = 3
	check(manager.process_mode == Node.PROCESS_MODE_PAUSABLE, "Rice manager explicitly pauses with battle tree")
	manager._physics_process(11.9)
	check(manager.get_child_count() == 0, "Rice does not spawn before twelve battle seconds")
	manager._physics_process(0.11)
	check(manager.get_child_count() == 1, "Rice attempts spawn after twelve battle seconds")
	check(not manager.spawn_rice() and manager.get_child_count() == 1, "At most one rice bowl exists")
	var rice = manager.rice
	check(is_equal_approx(rice.remaining, 8.0), "Rice starts with an eight-second lifetime")
	check(rice.global_position.distance_to(player.global_position) >= 180, "Spawn avoids player immediate surroundings")
	check(not manager.can_spawn_at(Vector2(50, 140)), "Spawn rejects arena corner")
	check(rice.pull_force(player.global_position + Vector2(500, 0)).is_zero_approx(), "Rice attraction is limited to local radius")
	check(rice.pull_force(rice.global_position + Vector2(10, 0)).length() <= rice.max_force, "Rice attraction has a bounded force")
	var start: Vector2 = rice.global_position - Vector2(150, 0)
	player.reset_body(start)
	await frames(3)
	await frames(15)
	check(player.linear_velocity.x > 1 and absf(player.linear_velocity.y) < 0.01, "Rice applies planar physical attraction without vertical gravity")
	check(player.position.distance_to(start) < 20, "Attraction does not teleport player to food")
	var wall := StaticBody2D.new()
	wall.position = rice.global_position - Vector2(65, 0)
	wall.collision_layer = 16
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 180)
	collider.shape = rectangle
	wall.add_child(collider)
	arena.add_child(wall)
	await frames(90)
	check(player.global_position.x < wall.global_position.x - 25.0, "Attraction cannot pull player through solid internal wall")
	check(not manager.can_spawn_at(wall.global_position), "Rice spawn rejects solid obstacle overlap")
	wall.queue_free()
	var companion: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	companion.player = player
	companion.position = rice.global_position + Vector2(100, 0)
	arena.add_child(companion)
	var companion_start: Vector2 = companion.position
	await frames(10)
	check(companion.position.distance_to(companion_start) < 0.1, "Rice does not attract default companion")
	launcher.remaining = 1.5
	var meals: Array = []
	var changes: Array = []
	var damage_events: Array = []
	manager.eaten.connect(func(point): meals.append(point))
	health.changed.connect(func(hp): changes.append(hp))
	health.damaged.connect(func(amount): damage_events.append(amount))
	player.reset_body(rice.global_position)
	await frames(5)
	check(health.hp == 4 and meals.size() == 1 and manager.get_child_count() == 0, "Overlap consumes once and heals one HP")
	check(changes == [4] and damage_events.is_empty(), "Healing updates health UI without damage events")
	check(is_equal_approx(launcher.remaining, 1.5), "Eating does not refund launch cooldown")
	player.reset_body(Vector2(640, 540))
	await frames(3)
	manager.heal_amount = 3
	check(manager.spawn_rice(), "Injured player can receive another bowl")
	player.reset_body(manager.rice.global_position)
	await frames(5)
	check(health.hp == health.max_hp, "Healing clamps to maximum HP")
	check(not manager.spawn_rice(), "Healing to full suppresses further bowls")
	manager.reset_rice()
	check(manager.rice == null and manager.elapsed == 0, "Restart clears bowl and timer")
	health.hp = 4
	player.reset_body(Vector2(640, 540))
	await frames(3)
	check(manager.spawn_rice(), "Bowl can exist before another source heals player")
	health.hp = health.max_hp
	manager.rice._on_body_entered(player)
	await frames(2)
	check(health.hp == health.max_hp and meals.size() == 2, "Existing bowl collected at full HP grants no extra health or heal cue")
	health.hp = 0
	check(not manager.spawn_rice(), "Dead player cannot spawn healing rice")
	manager.health = null
	check(not manager.spawn_rice(), "Missing health binding fails closed")
	manager.health = health
	health.hp = 3
	player.reset_body(Vector2(640, 540))
	await frames(3)
	var enemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.position = Vector2(400, 250)
	enemy.kind = 1
	enemy.warning_left = 0.5
	enemy.aim_direction = Vector2.RIGHT
	enemies.add_child(enemy)
	enemy.set_physics_process(false)
	check(not manager.can_spawn_at(Vector2(500, 250)), "Rice avoids heavy enemy warning lane")
	enemy.kind = 2
	check(not manager.can_spawn_at(Vector2(900, 250)), "Rice avoids turret warning ray")
	enemy.queue_free()
	await frames(2)
	var boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	boss.position = Vector2(300, 400)
	enemies.add_child(boss)
	boss.set_physics_process(false)
	boss.charge_direction = Vector2.RIGHT
	check(not manager.can_spawn_at(Vector2(900, 400)), "Rice avoids boss warning charge corridor")
	boss.queue_free()
	await frames(2)
	manager.spawn_rice()
	rice = manager.rice
	get_tree_pause(true)
	var age: float = rice.remaining
	manager.set_physics_process(true)
	await frames(12)
	check(is_equal_approx(rice.remaining, age), "Pause freezes rice lifetime")
	get_tree_pause(false)
	manager.set_physics_process(false)
	rice.remaining = 0.01
	await frames(3)
	check(manager.get_child_count() == 0, "Rice expires and stops attracting after eight seconds")
	manager.spawn_rice()
	var stale = manager.rice
	manager.remove_child(stale)
	stale._on_body_entered(player)
	check(health.hp == 3, "Removed bowl callback cannot heal a new run")
	stale.free()
	manager.spawn_rice()
	arena.remove_child(manager)
	check(manager.get_child_count() == 0 and manager.rice == null and manager.elapsed == 0, "Removing manager clears bowl force source, and timer")
	manager.free()
	arena.queue_free()
	await frames(2)
	check(Engine.time_scale == 1.0, "Rice keeps battle at normal time scale")
	if failures == 0:
		print("RICE CHECKS PASSED: ", checks)
	quit(0 if failures == 0 else 1)

func get_tree_pause(value: bool) -> void:
	paused = value
