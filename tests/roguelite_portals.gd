extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame
func run() -> void:
	check(ResourceLoader.exists("res://scenes/roguelite/mechanisms/portal_pair.tscn"), "Editable portal pair exists")
	var probe := DemoBody.new()
	check(probe.has_method("request_teleport"), "Body exposes distinct controlled teleport interface")
	probe.free()
	if failures:
		quit(1)
		return
	var pair = load("res://scenes/roguelite/mechanisms/portal_pair.tscn").instantiate()
	pair.position = Vector2(640, 400)
	root.add_child(pair)
	pair.set_physics_process(false)
	var visuals: Array[Vector2] = []
	pair.traversed.connect(func(_from: Vector2,to: Vector2):visuals.append(to))
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = pair.get_node("A").global_position
	root.add_child(player)
	await frames(2)
	player.linear_damp = 0.0
	player.angular_damp = 0.0
	player.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	player.angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	player.lock_rotation = false
	player.linear_velocity = Vector2(700, 120)
	player.angular_velocity = 1.7
	player.chain_id = 90
	player.generation = 2
	var before: Vector2 = player.position
	check(pair.try_teleport(player, 0), "Player can enter portal")
	check(visuals.is_empty(), "Accepted request has no premature successful portal visual")
	check(player.position == before, "Teleport request does not write rigid transform outside integration")
	check(not pair.try_teleport(player, 0), "Same body cannot request twice in one physics step")
	await frames(2)
	check(player.position.x > 900, "Physics interface applies portal displacement")
	check(visuals.size()==1, "Exactly one visual follows actual physics teleport")
	print("VELOCITY: ", player.linear_velocity, " angular ", player.angular_velocity)
	check(player.linear_velocity.distance_to(Vector2(700, 120)) < 0.1 and absf(player.angular_velocity - 1.7) < 0.01, "Portal preserves linear and angular velocity")
	check(player.chain_id == 90 and player.generation == 2, "Portal preserves attack identity and generation")
	check(not pair.try_teleport(player, 1), "Paired lock prevents immediate return")
	pair.reset_mechanism()
	player.reset_body(pair.get_node("A").global_position)
	await frames(2)
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(350, 500)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = pair.get_node("B").global_position
	root.add_child(wall)
	await frames(2)
	check(not pair.try_teleport(player, 0), "Fully blocked exit rejects teleport safely")
	check(player.position.x < 500, "Blocked exit keeps body on original side")
	wall.queue_free()
	await frames(2)
	check(pair.try_teleport(player, 0), "Exit becomes available after blocker removal")
	player.reset_body(Vector2(640, 600))
	await frames(2)
	check(player.position.distance_to(Vector2(640, 600)) < 1.0 and player.chain_id == 0, "Reset cancels pending portal request and clears old attack")
	pair.reset_mechanism()
	player.reset_body(pair.get_node("A").global_position)
	await frames(2)
	check(pair.try_teleport(player, 0), "Fresh request before pause")
	pair.set_active(false)
	await frames(2)
	check(player.position.x < 500, "Pause cancels queued teleport before physical application")
	pair.set_active(true)
	pair.reset_mechanism()
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.position = pair.get_node("A").global_position + Vector2(0, 25)
	root.add_child(enemy)
	enemy.set_physics_process(false)
	await frames(2)
	check(pair.try_teleport(enemy, 0), "Ordinary enemy can request portal")
	enemy.dead = true
	await frames(2)
	check(enemy.position.x < 500, "Same-frame enemy death invalidates pending teleport")
	enemy.queue_free()
	pair.reset_mechanism()
	var boss: DemoBoss = load("res://scenes/roguelite/boss.tscn").instantiate()
	boss.position = pair.get_node("A").global_position
	root.add_child(boss)
	check(not pair.try_teleport(boss, 0), "Boss is excluded from portal whitelist")
	boss.queue_free()
	await frames(2)
	var companion: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	companion.position = pair.get_node("A").global_position + Vector2(0, -25)
	root.add_child(companion)
	companion.set_physics_process(false)
	companion.activate(101, 2, Vector2.ZERO)
	companion.active_left = 1.4
	await frames(2)
	player.reset_body(pair.get_node("A").global_position + Vector2(0, 25))
	await frames(2)
	var first: bool = pair.try_teleport(player, 0)
	var second: bool = pair.try_teleport(companion, 0)
	print("SIMULTANEOUS: ", first, " / ", second, " at ", player.position, " / ", companion.position)
	check(first and second, "Two bodies can reserve distinct exits during the same step")
	await frames(2)
	check(player.position.distance_to(companion.position) > 38 and companion.position.x > 900, "Simultaneous exits do not overlap")
	check(companion.chain_id == 101 and companion.generation == 2 and is_equal_approx(companion.active_left, 1.4), "Active companion keeps chain, depth and remaining attack time")
	companion.queue_free()
	await frames(2)
	pair.reset_mechanism()
	player.reset_body(pair.get_node("A").global_position)
	await frames(2)
	var before_blocked_visuals: int = visuals.size()
	check(pair.try_teleport(player, 0), "Request accepted before exit becomes blocked")
	var late_wall := StaticBody2D.new()
	var late_shape := CollisionShape2D.new()
	late_shape.shape = rect
	late_wall.add_child(late_shape)
	late_wall.position = pair.get_node("B").global_position
	root.add_child(late_wall)
	await frames(2)
	check(player.position.x < 500, "Exit is revalidated during physical application")
	check(visuals.size()==before_blocked_visuals, "Failed physical revalidation never plays successful traversal")
	late_wall.queue_free()
	await frames(2)
	pair.reset_mechanism()
	var health := DemoHealth.new()
	root.add_child(health)
	pair.player_health = health
	check(pair.try_teleport(player, 0), "Living player can request teleport")
	health.hurt(5)
	await frames(2)
	check(player.position.x < 500, "Same-frame player death cancels teleport")
	health.queue_free()
	pair.player_health = null
	pair.reset_mechanism()
	player.reset_body(pair.get_node("A").global_position - Vector2(80, 0))
	await frames(2)
	player.linear_velocity = Vector2(1500, 0)
	pair.set_physics_process(true)
	await frames(ceili(Engine.physics_ticks_per_second * 0.15))
	check(player.position.x > 900, "High-speed entry is detected through the real physical traversal")
	player.linear_velocity = Vector2.ZERO
	await frames(ceili(Engine.physics_ticks_per_second * 0.5))
	player.linear_velocity = Vector2(-900, 0)
	await frames(ceili(Engine.physics_ticks_per_second * 0.4))
	check(player.position.x < 500, "Leaving the exit and waiting cooldown permits a real return traversal")
	pair.reset_mechanism()
	player.queue_free()
	await frames(3)
	check(pair._locks.is_empty() and pair._previous.is_empty(), "Empty arena retains no portal body locks")
	for node in [pair]:
		node.queue_free()
	await frames(2)
	print("PORTAL CHECKS PASSED: ", checks) if failures == 0 else print("PORTAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
