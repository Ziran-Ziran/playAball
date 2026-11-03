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
	for key in ["pivot_paddle", "moving_barrier", "rotating_arc", "spike_strip"]:
		check(ResourceLoader.exists("res://scenes/roguelite/mechanisms/%s.tscn" % key), "Editable mechanism scene: " + key)
	if failures > 0:
		quit(1)
		return
	var pivot = load("res://scenes/roguelite/mechanisms/pivot_paddle.tscn").instantiate()
	pivot.position = Vector2(400, 400)
	root.add_child(pivot)
	await frames(3)
	check(pivot.get_node("Paddle") is RigidBody2D and pivot.get_node("Pin") is PinJoint2D, "Paddle uses a real rigid body and joint")
	var paddle: RigidBody2D = pivot.get_node("Paddle")
	paddle.apply_impulse(Vector2(0, 120), Vector2(70, 0))
	await frames(18)
	check(absf(paddle.rotation) > 0.02, "Off-center physical impulse actually rotates paddle")
	check(paddle.global_position.distance_to(pivot.global_position) < 5.0, "Joint retains the center anchor")
	var eccentric = load("res://scenes/roguelite/mechanisms/pivot_paddle.tscn").instantiate()
	eccentric.position = Vector2(400, 200)
	eccentric.initial_angle = 0.3
	eccentric.pivot_offset = Vector2(55, 0)
	root.add_child(eccentric)
	await frames(25)
	check(eccentric.get_node("Paddle").to_global(eccentric.pivot_offset).distance_to(eccentric.global_position) < 5.0, "Eccentric joint keeps the configured local pivot on the world anchor")
	eccentric.queue_free()
	var moving = load("res://scenes/roguelite/mechanisms/moving_barrier.tscn").instantiate()
	moving.position = Vector2(750, 400)
	root.add_child(moving)
	var arc = load("res://scenes/roguelite/mechanisms/rotating_arc.tscn").instantiate()
	arc.position = Vector2(1000, 400)
	root.add_child(arc)
	await frames(20)
	check(moving.get_node("Body") is AnimatableBody2D and moving.get_node("Body").position.length() > 1.0, "Moving barrier follows physical-frame animatable motion")
	check(arc.get_node("Body") is AnimatableBody2D and absf(arc.get_node("Body").rotation) > 0.01, "Arc rotates as an animatable body")
	check(arc.get_node("Body").get_child_count() >= 12, "Arc uses explicit editable collision segments")
	var before: Vector2 = moving.get_node("Body").position
	var angle_before: float = arc.get_node("Body").rotation
	paused = true
	await create_timer(0.12).timeout
	check(moving.get_node("Body").position == before and arc.get_node("Body").rotation == angle_before, "Pause freezes both moving mechanisms")
	paused = false
	moving.reset_mechanism()
	arc.reset_mechanism()
	pivot.reset_mechanism()
	await frames(2)
	check(moving.elapsed < 0.06 and arc.elapsed < 0.06, "Reset restores mechanism phase")
	check(absf(paddle.rotation - pivot.initial_angle) < 0.03 and absf(paddle.angular_velocity) < 0.1, "Paddle reset uses the physics state interface")
	moving.set_active(false)
	arc.set_active(false)
	pivot.set_active(false)
	before = moving.get_node("Body").position
	angle_before = arc.get_node("Body").rotation
	await frames(10)
	check(moving.get_node("Body").position == before and arc.get_node("Body").rotation == angle_before and paddle.freeze, "Map activation interface independently freezes mechanisms")
	moving.set_active(true)
	arc.set_active(true)
	pivot.set_active(true)
	for period: float in [0.2, 60.0]:
		moving.period = period
		moving.reset_mechanism()
		arc.angular_speed = 1.0 if period < 1.0 else 0.001
		arc.reset_mechanism()
		await frames(10)
		check(moving.get_node("Body").position.is_finite() and moving.get_node("Body").position.length() <= moving.travel.length() + 0.01 and is_finite(arc.get_node("Body").rotation), "Slow/fast configured mechanism extremes remain bounded: " + str(period))
	moving.period = 6.0
	moving.reset_mechanism()
	var pushed: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	pushed.position = moving.position + Vector2(0, 45)
	root.add_child(pushed)
	await frames(ceili(Engine.physics_ticks_per_second * 0.8))
	check(pushed.position.y > moving.position.y + 55.0, "Animated barrier actually pushes a dynamic player through collision")
	pushed.queue_free()
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = Vector2(200, 300)
	root.add_child(player)
	var health := DemoHealth.new()
	root.add_child(health)
	var spikes = load("res://scenes/roguelite/mechanisms/spike_strip.tscn").instantiate()
	spikes.player = player
	spikes.health = health
	spikes.position = player.position
	root.add_child(spikes)
	await frames(8)
	check(health.hp == 4, "Real spike overlap causes exactly one player damage during invulnerability")
	await frames(10)
	check(health.hp == 4, "Persistent overlap respects shared invulnerability")
	player.reset_body(Vector2(200, 500))
	await frames(3)
	var companion: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	companion.position = spikes.position
	root.add_child(companion)
	health.invulnerability_left = 0.0
	await frames(5)
	check(health.hp == 4, "Companion overlap does not damage player remotely")
	for node in [pivot, moving, arc, spikes, player, companion, health]:
		node.queue_free()
	await frames(2)
	print("MAP MECHANISM CHECKS PASSED: ", checks) if failures == 0 else print("MAP MECHANISM FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
