extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(60.0).timeout.connect(func(): push_error("Roguelite test timeout"); quit(1))
func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for index in count:
		await physics_frame

func companion_basics(arena: Node2D) -> void:
	var player: DemoPlayer = arena.player
	var member: DemoCompanion = arena.companions.members[0]
	player.freeze = true
	member.reset_body(Vector2(800, 400))
	await frames(3)
	var resting: Vector2 = member.position
	await frames(90)
	check(member.position.distance_to(resting) < 0.1, "Base companion stays still instead of automatically following")
	member.end_attack()
	check(member.mode == DemoCompanion.Mode.IDLE, "Base companion ends attack in idle without auto-return")
	member.return_force = 0.0
	# 独立的内部墙夹具，验证实际反弹，不能仅断言 mask 数字。
	var wall := StaticBody2D.new()
	wall.position = Vector2(900, 400)
	wall.collision_layer = 16
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20, 180)
	shape.shape = rectangle
	wall.add_child(shape)
	arena.add_child(wall)
	member.reset_body(Vector2(800, 400))
	await frames(3)
	member.apply_central_impulse(Vector2(250, 0) * member.mass)
	await frames(90)
	check(member.position.x < 890 and member.linear_velocity.x < 0, "Idle companion physically bounces off internal wall")
	member.follow_enabled = true
	member.end_attack()
	member.reset_body(Vector2(800, 400))
	await frames(3)
	member.apply_central_impulse(Vector2(250, 0) * member.mass)
	await frames(90)
	check(member.position.x < 890 and member.linear_velocity.x < 0, "Upgraded returning companion also bounces off internal wall")
	member.reset_body(Vector2(800, 400))
	await frames(3)
	member.activate(20, 1, Vector2(250, 0) * member.mass)
	await frames(90)
	check(member.position.x < 890 and member.linear_velocity.x < 0, "Active companion bounces off internal wall")
	member.follow_enabled = false
	member.end_attack()
	wall.collision_layer = 8
	member.reset_body(Vector2(800, 400))
	await frames(3)
	member.apply_central_impulse(Vector2(250, 0) * member.mass)
	await frames(90)
	check(member.position.x < 890 and member.linear_velocity.x < 0, "Idle companion cannot pass through solid target layer")
	wall.queue_free()
	# 再撞真实场景中的旋转挡板，覆盖高速 CCD，而不是只测轴对齐墙。
	var bumper: StaticBody2D = arena.get_node("RightRamp")
	var normal: Vector2 = Vector2.DOWN.rotated(bumper.rotation)
	member.reset_body(bumper.position - normal * 110.0)
	await frames(3)
	member.apply_central_impulse(normal * 900.0 * member.mass)
	await frames(30)
	check(member.linear_velocity.dot(normal) < -100.0 and (member.position - bumper.position).dot(normal) < 0.0, "Fast idle companion reflects from actual angled bumper")
	player.freeze = false
	arena.reset_range()
	await frames(3)
	check(not arena.companions.follow_enabled and not arena.companions.members[0].follow_enabled, "Reset starts with follow upgrade disabled")
func run() -> void:
	check(ResourceLoader.exists("res://scenes/roguelite/arena.tscn"), "Independent roguelite arena exists")
	if failures > 0:
		quit(1)
		return
	var arena = load("res://scenes/roguelite/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.feedback.sound_enabled = false
	await frames(3)
	var launch: DemoLaunch = arena.launcher
	var player: DemoPlayer = arena.player
	var combat: DemoCombat = arena.combat
	launch.set_process(false)
	await companion_basics(arena)
	# 发射方向检查隔离接力传感器，避免小弟主动接走测试用的动量。
	arena.companions.members[0].set_physics_process(false)
	check(player.gravity_scale == 0.0, "Player scene disables environmental gravity")
	for member: DemoCompanion in arena.companions.members:
		check(member.gravity_scale == 0.0, "Companion scene disables environmental gravity")
	player.reset_body(Vector2(800, 400))
	await frames(3)
	var resting_point: Vector2 = player.position
	await frames(60)
	check(player.position.distance_to(resting_point) < 0.1, "Unforced player has no planar drift")
	# 八向真实冲量，不在夹具中覆盖重力，避免掩盖场景配置错误。
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
		player.reset_body(Vector2(640, 440))
		await frames(3)
		player.launch(direction * 80.0, 1)
		await frames(3)
		check(player.linear_velocity.normalized().dot(direction) > 0.999, "Launch follows planar direction %s" % direction)
		# B 只抵消反向投影；同向与垂直分量应与 A 相同。
		player.reset_body(Vector2(640, 440))
		await frames(3)
		player.linear_velocity = -direction * 300.0 + direction.orthogonal() * 100.0
		player.cancel_opposing_momentum = 0.6
		player.launch(direction * 80.0, 2)
		await frames(2)
		var expected_speed: float = player.max_impulse * lerpf(0.45, 1.0, 72.0 / 152.0) - 120.0
		check(absf(player.linear_velocity.dot(direction) - expected_speed) < 8.0 and absf(player.linear_velocity.dot(direction.orthogonal()) - 100.0) < 3.0, "Momentum B cancels opposing projection in direction %s" % direction)
	player.cancel_opposing_momentum = 0.0
	for fixture: Array in [[Vector2(1100, 250), Vector2.RIGHT], [Vector2(180, 250), Vector2.LEFT], [Vector2(800, 210), Vector2.UP], [Vector2(640, 590), Vector2.DOWN]]:
		player.reset_body(fixture[0])
		await frames(3)
		player.launch(fixture[1] * 160.0, 3)
		await frames(30)
		check(player.linear_velocity.dot(fixture[1]) < -100.0, "Planar boundary reflects launch %s" % fixture[1])
	arena.reset_range()
	await frames(3)
	check(arena.get_node("HUD/Controls/Count").selected == 0, "Companion selector starts with one selected")
	launch.begin(Vector2(500, 400))
	var ui_release := InputEventMouseButton.new()
	ui_release.button_index = MOUSE_BUTTON_LEFT
	ui_release.pressed = false
	ui_release.position = arena.get_node("HUD/Controls/Mute").get_global_rect().get_center()
	arena._input(ui_release)
	check(not launch.aiming and launch.remaining == 0.0 and Engine.time_scale == 1.0, "Release over GUI cancels aim without spending energy")
	launch.begin(Vector2(500, 400))
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	arena._input(right_click)
	check(not launch.aiming and launch.remaining == 0.0, "Right click cancels without firing")
	check(launch.begin(Vector2(500, 400)), "Aim begins away from player")
	launch.advance(0.4)
	launch.cancel()
	check(launch.remaining == 0.0 and Engine.time_scale == 1.0, "Cancel spends no energy and keeps normal speed")
	launch.begin(Vector2(500, 400))
	launch.advance(0.8)
	check(Engine.time_scale == 1.0 and launch.aiming, "Long drag keeps normal battle speed")
	check(not launch.release(Vector2(496, 400)) and launch.remaining == 0.0, "Tiny drag consumes no energy")
	player.linear_velocity = Vector2(500, 0)
	launch.begin(Vector2(500, 400))
	check(launch.release(Vector2(340, 400)), "Moving player accepts launch")
	check(not launch.begin(Vector2(500, 400)), "Cooldown prevents immediate second launch")
	var remaining: float = launch.remaining
	launch.aiming = true
	launch.advance(1.0)
	check(launch.remaining == remaining, "Cooldown cannot recover during aim")
	launch.cancel()
	launch.advance(2.2)
	check(launch.remaining == 0.0, "Battle cooldown restores launch availability")
	launch.begin(Vector2(500, 400))
	launch._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not launch.aiming and Engine.time_scale == 1.0, "Focus loss cancels aim and restores time")
	launch.begin(Vector2(500, 400))
	arena.set_paused(true)
	check(paused and launch.blocked and not launch.aiming and Engine.time_scale == 1.0, "Pause dominates aim cancellation")
	arena.set_paused(false)
	check(not paused and not launch.blocked, "Resume restores launch availability")
	player.reset_body(Vector2(400, 300))
	await frames(3)
	launch.begin(Vector2(500, 400))
	arena.reset_range()
	await frames(3)
	check(launch.shots == 0 and launch.remaining == 0.0 and player.chain_id == 0 and Engine.time_scale == 1.0, "Range reset clears launch chain and time")
	check(player.position.distance_to(Vector2(640, 540)) < 5.0, "Player reset uses physics state interface")
	check(arena.companions.members[0].position.distance_to(player.position + arena.companions.members[0].follow_offset()) < 5.0, "Range reset spawns companion around pending player reset position")
	check(combat.damage_for(179) == 0 and combat.damage_for(180) == 1 and combat.damage_for(450) == 2 and combat.damage_for(850) == 3, "Normal approach speed damage boundaries")
	var target: DemoTarget = arena.get_node("Targets/LeftTarget")
	player.chain_id = 7
	combat.resolve(player, target, 0, target.position)
	check(target.hp == 3, "Resting contact does not hurt")
	combat.resolve(player, target, 450, target.position)
	combat.resolve(player, target, 450, target.position)
	check(target.hp == 1 and combat.events.size() == 1, "Repeated pair resolves damage once")
	check(not combat.accept_pair(target, player), "Reversed pair shares cooldown")
	combat.elapsed += 0.19
	var death_count: Array[int] = [0]
	target.broken.connect(func(_target: DemoTarget): death_count[0] += 1)
	combat.resolve(player, target, 450, target.position)
	combat.elapsed += 0.19
	combat.resolve(player, target, 850, target.position)
	check(target.dead and death_count[0] == 1, "Death is emitted once")
	arena.companions.set_count(9)
	check(arena.companions.members.size() == 4, "Companion count capped at four")
	var offset_sum := Vector2.ZERO
	for member: DemoCompanion in arena.companions.members:
		offset_sum += member.follow_offset()
	check(offset_sum.length() < 0.01, "Four companions surround the player across the full plane")
	await frames(2)
	var members: Array[DemoCompanion] = arena.companions.members
	for member in members:
		member.set_physics_process(false)
		member.freeze = true
	player.freeze = true
	player.position = Vector2(300, 400)
	player.linear_velocity = Vector2(900, 0)
	player.chain_id = 9
	player.generation = 0
	for index in 4:
		members[index].position = Vector2(350 + index * 50, 400)
		members[index].linear_velocity = Vector2.ZERO
	combat.reset_combat()
	check(combat.activate(player, members[0]), "Main ball activates idle companion")
	check(not combat.activate(player, members[0]), "Overlap cannot repeatedly energize active companion")
	members[0].linear_velocity = Vector2(850, 0)
	check(combat.activate(members[0], members[1]), "Active companion relays to idle companion")
	members[1].linear_velocity = Vector2(800, 0)
	check(combat.activate(members[1], members[2]), "Third generation accepted")
	members[2].linear_velocity = Vector2(800, 0)
	check(not combat.activate(members[2], members[3]), "Fourth generation rejected")
	check(members[2].chain_id == 9 and members[2].generation == 3, "Relay retains original launch identity")
	members[0].end_attack()
	target.reset_target()
	combat.reset_combat()
	combat.resolve(members[0], target, 900, target.position)
	check(not members[0].attacking() and target.hp == 3, "Returning companion cannot deal damage")
	await frames(2)
	check(members[0].collision_layer == 0 and members[0].collision_mask == 25, "Inactive companion keeps solid walls, bumpers and targets")
	# 以下使用真实物理帧，独立于上面的确定性规则检查。
	arena.reset_range()
	await frames(3)
	player.freeze = false
	arena.companions.set_count(1)
	var companion: DemoCompanion = arena.companions.members[0]
	companion.set_physics_process(false)
	player.reset_body(Vector2(120, 570))
	await frames(2)
	player.launch(Vector2(160, 0), 10)
	await frames(25)
	check(target.hp < 3, "Real rigid-body collision damages target")
	arena.reset_range()
	await frames(3)
	player.reset_body(Vector2(400, 400))
	companion = arena.companions.members[0]
	companion.reset_body(Vector2(460, 400))
	await frames(2)
	player.launch(Vector2(160, 0), 11)
	await frames(12)
	check(companion.mode == DemoCompanion.Mode.ACTIVE and companion.chain_id == 11, "Real sensor contact hands off launch chain")
	# 后续跟随升级的既有引导力另测，不能再把它当成开局默认行为。
	arena.companions.set_follow_enabled(true)
	companion.active_left = 0.01
	await frames(3)
	check(companion.mode != DemoCompanion.Mode.ACTIVE and not companion.attacking(), "Active timeout switches attack off")
	await frames(600)
	check(companion.position.distance_to(player.position) < 200.0, "Force guidance brings companion back near player")
	# 跟随目标不能落入实体靶内；不能再靠穿透靶通过此检查。
	player.reset_body(Vector2(800, 400))
	await frames(3)
	player.freeze = true
	companion.reset_body(player.position + companion.follow_offset())
	await frames(3)
	var companion_rest: Vector2 = companion.position
	await frames(60)
	check(companion.position.distance_to(companion_rest) < 0.1, "Companion at follow target has no antigravity drift")
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		companion.end_attack()
		companion.reset_body(player.position + direction * 160.0)
		await frames(240)
		check(companion.mode == DemoCompanion.Mode.IDLE and companion.position.distance_to(player.position + companion.follow_offset()) < 45.0, "Force guidance returns companion from %s" % direction)
	player.freeze = false
	var shots_before: int = launch.shots
	companion.reset_body(Vector2(-200, 400))
	await frames(8)
	check(companion.position.x > 0 and launch.shots == shots_before, "Out-of-bounds recovery resets only companion")
	arena.reset_range()
	await frames(240)
	var intact: bool = true
	for item: DemoTarget in arena.get_node("Targets").get_children():
		intact = intact and item.hp == item.hit_points
	check(intact, "Idle companions never clear targets without launch")
	arena.reset_range()
	await frames(3)
	arena.companions.set_count(2)
	player.reset_body(Vector2(550, 400))
	var lower: DemoTarget = arena.get_node("Targets/RightTarget")
	# 零重力下散射是直线；两靶位于传感器交接后两条对称出射线上。
	target.position = Vector2(830, 200)
	lower.position = Vector2(830, 600)
	for index in 2:
		var member: DemoCompanion = arena.companions.members[index]
		member.return_force = 0
		member.reset_body(Vector2(640, 380 + index * 40))
	await frames(3)
	player.launch(Vector2(160, 0), 42)
	await frames(180)
	var companion_targets: Dictionary = {}
	for event: Dictionary in combat.events:
		if event.chain == 42 and event.generation > 0 and event.damage > 0:
			companion_targets[event.target] = true
	check(companion_targets.size() >= 2, "Single launch scatters companions into two distinct targets")
	target.position = Vector2(300, 570)
	lower.position = Vector2(980, 570)
	arena.queue_free()
	await process_frame
	check(Engine.time_scale == 1.0 and not paused, "Leaving range restores global time and pause")
	if failures == 0:
		print("ROGUELITE CHECKS PASSED: ", checks)
	quit(0 if failures == 0 else 1)
