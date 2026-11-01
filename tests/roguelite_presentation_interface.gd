extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(25.0).timeout.connect(func(): push_error("Presentation interface test timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func body_signature(body: RigidBody2D) -> Array:
	return [
		body.mass,
		body.gravity_scale,
		body.collision_layer,
		body.collision_mask,
		body.linear_damp,
		body.get_node("Shape").shape.radius,
		body.physics_material_override.friction,
		body.physics_material_override.bounce,
	]

func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var health := DemoHealth.new()
	world.add_child(health)
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.freeze = true
	world.add_child(player)
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.hit_points_override = 6
	enemy.set_physics_process(false)
	world.add_child(enemy)
	await process_frame
	check(not player.contact_diagnostics_enabled and not enemy.contact_diagnostics_enabled, "Formal actors keep non-damaging contact diagnostics off by default")
	check(enemy.get_node_or_null("Presentation") is DemoEnemyView, "Enemy scene exposes a replaceable default view")
	var view: DemoEnemyView = enemy.get_node("Presentation")
	var initial: Dictionary = enemy.presentation_snapshot()
	check(initial.hp == 6 and initial.max_hp == 6 and initial.kind == DemoEnemy.Kind.FRAGILE, "Enemy snapshot contains read-only life/type data")
	var base_signature: Array = body_signature(enemy)
	var events: Array[StringName] = []
	enemy.presentation_event.connect(func(event: StringName, _payload: Dictionary): events.append(event))
	enemy.hurt(1)
	await process_frame
	check(enemy.hp == 5 and view._state.hp == 5, "View consumes current life without writing it")
	check(events.has(&"hurt"), "Enemy emits a real presentation event for accepted damage")
	check(body_signature(enemy) == base_signature, "Enemy presentation does not alter collision or mass")
	enemy.remove_child(view)
	view.queue_free()
	var replacement: DemoEnemyView = load("res://scenes/roguelite/presentation/enemy_view.tscn").instantiate()
	replacement.name = "Presentation"
	enemy.add_child(replacement)
	enemy._attach_presentation(replacement)
	await process_frame
	check(replacement._state.hp == enemy.hp and replacement.source == enemy, "A replacement view can bind to the same actor state")
	check(body_signature(enemy) == base_signature, "Replacing a view cannot change physical signatures")

	var combat := DemoCombat.new()
	world.add_child(combat)
	var outcomes: Array[Dictionary] = []
	combat.contact_outcome.connect(func(event: Dictionary): outcomes.append(event))
	player.chain_id = 0
	combat.resolve(player, enemy, 400.0, enemy.global_position)
	player.chain_id = 31
	combat.resolve(player, enemy, 100.0, enemy.global_position)
	var hp_before: int = enemy.hp
	combat.resolve(player, enemy, 400.0, enemy.global_position)
	check(outcomes.size() >= 3, "Combat publishes one logic outcome per real contact decision")
	check(outcomes[0].reason == "no_attack_qualification", "Combat reports missing attack qualification")
	check(outcomes[1].reason == "speed_below_minimum", "Combat reports insufficient contact speed")
	check(outcomes[2].result == "accepted" and enemy.hp < hp_before, "Combat accepted outcome matches the actual damage branch")
	combat.resolve(player, enemy, 400.0, enemy.global_position)
	check(outcomes[3].reason == "pair_cooldown", "Combat reports the actual pair cooldown rejection")
	enemy.player = player
	enemy.health = health
	var release_states: Array[bool] = []
	enemy.presentation_event.connect(func(event: StringName, _payload: Dictionary):
		if event == &"attack_released":
			release_states.append(enemy.presentation_snapshot().attack_active)
	)
	enemy._release_attack(Vector2(50, 0))
	check(release_states == [true], "Attack release event observes the committed attack state")
	enemy.kind = DemoEnemy.Kind.TURRET
	enemy.hazards = Node2D.new()
	world.add_child(enemy.hazards)
	enemy.hazard_limit = 0
	enemy._release_attack(Vector2(50, 0))
	check(release_states.size() == 1, "A turret blocked by its projectile budget emits no successful release event")
	health.reset_health()

	var hud = load("res://scenes/roguelite/run_hud.tscn").instantiate()
	root.add_child(hud)
	hud.bind_health(health)
	await process_frame
	var health_view: DemoHealthView = hud.get_node("Overlay/PlayerPanel")
	check(health_view is DemoHealthView, "Run HUD hosts a replaceable health view")
	check(health_view.snapshot().hp == 5 and health.hp == 5, "Health view reports source data without mutating it")
	hud.free()
	world.free()
	await process_frame
	print("PRESENTATION INTERFACE CHECKS PASSED: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
