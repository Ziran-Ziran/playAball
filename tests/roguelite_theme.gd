extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func body_signature(body: RigidBody2D) -> Array:
	return [body.mass, body.gravity_scale, body.collision_layer, body.collision_mask,
		body.linear_damp, body.get_node("Shape").shape.radius,
		body.physics_material_override.friction, body.physics_material_override.bounce,
		body.position, body.rotation, body.scale, body.linear_velocity]

func run() -> void:
	var room := Node2D.new()
	root.add_child(room)
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	var companion: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	room.add_child(player)
	room.add_child(companion)
	player.freeze = true
	companion.freeze = true
	check(player.get_node("Shape").shape.radius == 23.0, "Player physics radius remains 23")
	check(companion.get_node("Shape").shape.radius == 14.0, "Companion physics radius remains 14")
	check(companion.get_node("Sensor/Shape").shape.radius == 17.0, "Companion sensor radius remains 17")
	check(player.collision_layer == 2 and player.collision_mask == 29, "Player layers remain 2/29")
	check(companion.collision_layer == 0 and companion.collision_mask == 25, "Idle companion layers remain 0/25")
	check(player.gravity_scale == 0.0 and companion.gravity_scale == 0.0, "Both theme bodies remain zero gravity")
	check(is_equal_approx(player.physics_material_override.bounce, 0.85) and is_equal_approx(companion.physics_material_override.bounce, 0.85), "Theme preserves bounce materials")
	check(not companion.follow_enabled, "Theme does not enable automatic follow")
	check(ResourceLoader.exists("res://resources/roguelite/themes/fat_fish.tres"), "Default fat fish theme resource exists")
	if failures == 0:
		var theme: Resource = load("res://resources/roguelite/themes/fat_fish.tres")
		check(theme.get("display_name") == "肥鱼", "Theme has the intended display name")
		check(player.get("theme") == theme and companion.get("theme") == theme, "Both bodies share the default theme resource")
		check(player.get("well_fed") == false, "Well-fed visual starts disabled")
		var baseline: Array = body_signature(player)
		var companion_baseline: Array = body_signature(companion)
		player.set("well_fed", true)
		player.queue_redraw()
		companion.queue_redraw()
		await process_frame
		check(body_signature(player) == baseline, "Well-fed drawing leaves all player physics unchanged")
		check(body_signature(companion) == companion_baseline, "Companion drawing leaves all physics unchanged")
		var alternate: Resource = theme.duplicate()
		alternate.set("player_color", Color("bd8ee8"))
		player.set("theme", alternate)
		companion.set("theme", alternate)
		player.queue_redraw()
		companion.queue_redraw()
		await process_frame
		check(body_signature(player) == baseline and body_signature(companion) == companion_baseline, "Replacing palette cannot change physical signatures")
		check(not companion.follow_enabled and companion.mode == DemoCompanion.Mode.IDLE, "Replacing theme leaves companion state untouched")
	room.queue_free()
	await process_frame
	print("ROGUELITE THEME: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
