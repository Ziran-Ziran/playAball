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
func fire(launch: DemoLaunch) -> bool:
	return launch.begin(Vector2(500, 350)) and launch.release(Vector2(340, 350))
func run() -> void:
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	root.add_child(player)
	var launch := DemoLaunch.new()
	launch.player = player
	root.add_child(launch)
	launch.set_process(false)
	check(launch.has_method("set_capacity"), "Launch capacity upgrade API exists")
	check(player.has_method("apply_launch_stats"), "Player launch stats API exists")
	if failures > 0:
		player.queue_free()
		launch.queue_free()
		await process_frame
		quit(1)
		return
	check(launch.get("capacity") == 1 and launch.get("charges") == 1, "Base launch begins with one full charge")
	launch.set("remaining", 0.5)
	check(not launch.begin(Vector2.ZERO), "Legacy remaining assignment blocks single launch")
	launch.advance(0.5)
	check(launch.get("charges") == 1 and fire(launch), "Legacy cooldown restores one usable charge")
	launch.call("set_capacity", 2)
	check(launch.get("charges") == 1, "Upgrade grants exactly the newly added slot")
	launch.call("set_capacity", 2)
	check(launch.get("charges") == 1, "Repeated capacity application cannot grant extra charges")
	check(fire(launch) and launch.shots == 2 and player.chain_id == 2, "Second rapid shot consumes independent charge and chain")
	check(launch.get("charges") == 0 and not fire(launch), "Two shots exhaust double capacity")
	launch.advance(launch.cooldown)
	check(launch.get("charges") == 1 and is_equal_approx(launch.remaining, launch.cooldown), "First serial interval restores only one charge")
	launch.advance(launch.cooldown)
	check(launch.get("charges") == 2 and launch.remaining == 0.0, "Second serial interval fills capacity")
	var velocity: Vector2 = player.linear_velocity
	launch.begin(Vector2(300, 300))
	launch.cancel()
	check(launch.get("charges") == 2 and player.linear_velocity == velocity, "Begin and cancel preserve both charges and velocity")
	launch.begin(Vector2(300, 300))
	check(not launch.release(Vector2(298, 300)) and launch.get("charges") == 2, "Tiny drag cannot consume a charge")
	check(fire(launch), "First full double shot launches")
	launch.advance(0.4)
	var partial: float = launch.remaining
	check(fire(launch) and is_equal_approx(launch.remaining, partial), "Second shot preserves existing serial recharge progress")
	launch.set_blocked(true)
	launch.advance(100.0)
	check(launch.remaining == partial and launch.get("charges") == 0, "Blocked launch does not recharge")
	launch.set_blocked(false)
	launch.request_aim(Vector2(500, 350))
	launch.pointer = Vector2(340, 350)
	launch.advance(partial)
	check(launch.aiming and launch.pointer == Vector2(340, 350) and launch.get("charges") == 1, "Held drag resumes when one charge becomes ready")
	var aim_remaining: float = launch.remaining
	launch.advance(10.0)
	check(launch.remaining == aim_remaining and launch.get("charges") == 1, "Aiming cannot farm serial recharge")
	launch.cancel()
	launch.refund_cooldown(100.0)
	check(launch.get("charges") == 2 and launch.remaining == 0.0, "Rice refund restores at most the missing charge")
	fire(launch)
	fire(launch)
	launch.refund_cooldown(100.0)
	check(launch.get("charges") == 1 and is_equal_approx(launch.remaining, launch.cooldown), "One rice refund cannot fill two missing charges")
	launch.reset_launch()
	check(launch.get("capacity") == 1 and launch.get("charges") == 1 and launch.shots == 0 and launch.remaining == 0.0, "Reset clears double capacity and all launch progress")
	var other: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	root.add_child(other)
	var previous_velocity: Vector2 = player.linear_velocity
	var previous_position: Vector2 = player.position
	player.call("apply_launch_stats", 1.45, 0.25, 0.1)
	player.call("apply_launch_stats", 1.45, 0.25, 0.1)
	check(is_equal_approx(player.max_impulse, 1522.5) and is_equal_approx(player.linear_damp, 0.03) and is_equal_approx(player.physics_material_override.friction, 0.005), "Repeated stat application recomputes fixed baselines idempotently")
	check(is_equal_approx(other.physics_material_override.friction, 0.05) and player.physics_material_override != other.physics_material_override, "Glide duplicates material without affecting another ball")
	check(player.linear_velocity == previous_velocity and player.position == previous_position and player.speed_limit == 1500.0, "Stat application never changes velocity position or speed cap")
	player.call("apply_launch_stats", 1.0, 1.0, 1.0)
	check(is_equal_approx(player.max_impulse, 1050.0) and is_equal_approx(player.linear_damp, 0.12) and is_equal_approx(player.physics_material_override.friction, 0.05), "Neutral multipliers reset original launch and glide stats")
	player.queue_free()
	other.queue_free()
	launch.queue_free()
	await process_frame
	print("ROGUELITE LAUNCH REWARDS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
