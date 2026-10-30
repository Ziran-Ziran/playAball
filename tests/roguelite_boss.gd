extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(35.0).timeout.connect(func(): push_error("Boss test timeout"); quit(1))

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

func physical_charge_cases() -> void:
	for direction: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var fixture := Node2D.new()
		root.add_child(fixture)
		var target: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
		target.position = Vector2(500, 350) + direction * 100.0
		fixture.add_child(target)
		var shared_health: Node = load("res://scripts/roguelite/player_health.gd").new()
		# 关闭无敌时间，使重复扣血无法被健康组件掩盖。
		shared_health.invulnerability = 0.0
		fixture.add_child(shared_health)
		var attacker = load("res://scenes/roguelite/boss.tscn").instantiate()
		attacker.position = Vector2(500, 350)
		attacker.player = target
		attacker.health = shared_health
		fixture.add_child(attacker)
		check(target.chain_id == 0 and target.linear_velocity == Vector2.ZERO and target.collision_layer == 2 and target.collision_mask == 29, "Real charge fixture uses resting normal player %s" % direction)
		check(attacker.module_hp == [3, 3, 3, 3], "All four modules remain intact for charge %s" % direction)
		var contact_count: Array[int] = [0]
		var contact_distance: Array[float] = [0.0]
		attacker.body_entered.connect(func(body):
			if body == target:
				contact_count[0] += 1
				contact_distance[0] = attacker.global_position.distance_to(target.global_position))
		await frames(100)
		check(attacker.phase == attacker.Phase.WARNING and shared_health.hp == 5, "Physical module contact during warning is harmless %s" % direction)
		var steps: int = 0
		while attacker.phase == attacker.Phase.WARNING and steps < 60:
			await physics_frame
			steps += 1
		await frames(30)
		# body_entered 送达时已完成本步求解分离，允许一个物理步的位移误差。
		check(contact_count[0] > 0 and contact_distance[0] > 75.0 and contact_distance[0] < 120.0, "Real module contact is outside old core radius %s" % direction)
		check(attacker.phase == attacker.Phase.CHARGE and shared_health.hp == 4, "First actual module charge contact hurts once %s" % direction)
		# 接触可能从预警延续到冲刺，body_entered 不保证重新发出；伤害应读实际接触点。
		check(attacker._charge_hit, "Charge records physical hit at module reach %s" % direction)
		await frames(70)
		check(shared_health.hp == 4 and attacker.module_hp == [3, 3, 3, 3], "Persistent collision cannot damage twice or break modules %s" % direction)
		fixture.queue_free()
		await process_frame

func stale_charge_cases() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	var target: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	target.position = Vector2(1000, 600)
	fixture.add_child(target)
	var shared_health: Node = load("res://scripts/roguelite/player_health.gd").new()
	fixture.add_child(shared_health)
	var attacker = load("res://scenes/roguelite/boss.tscn").instantiate()
	attacker.player = target
	attacker.health = shared_health
	fixture.add_child(attacker)
	attacker.set_physics_process(false)
	attacker.phase = attacker.Phase.CHARGE
	attacker.publish_charge_hit.call_deferred(target.get_instance_id(), shared_health.get_instance_id(), attacker._charge_revision, attacker._reset_revision, target._reset_revision)
	attacker.reset_body(Vector2(200, 200))
	await frames(3)
	check(shared_health.hp == 5, "Boss reset discards queued charge damage")
	attacker.publish_charge_hit.call_deferred(target.get_instance_id(), shared_health.get_instance_id(), attacker._charge_revision, attacker._reset_revision, target._reset_revision)
	target.reset_body(Vector2(1100, 600))
	await frames(3)
	check(shared_health.hp == 5, "Player reset discards queued charge damage")
	attacker.publish_charge_hit.call_deferred(target.get_instance_id(), shared_health.get_instance_id(), attacker._charge_revision, attacker._reset_revision, target._reset_revision)
	attacker.begin_warning()
	attacker.phase = attacker.Phase.CHARGE
	await process_frame
	check(shared_health.hp == 5, "Previous attack cannot damage in a later charge")
	attacker.publish_charge_hit.call_deferred(target.get_instance_id(), shared_health.get_instance_id(), attacker._charge_revision, attacker._reset_revision, target._reset_revision)
	var next_health: Node = load("res://scripts/roguelite/player_health.gd").new()
	fixture.add_child(next_health)
	attacker.health = next_health
	await process_frame
	check(shared_health.hp == 5 and next_health.hp == 5, "Queued event cannot damage replacement health")
	attacker.publish_charge_hit.call_deferred(target.get_instance_id(), next_health.get_instance_id(), attacker._charge_revision, attacker._reset_revision, target._reset_revision)
	attacker.hurt(999)
	await process_frame
	check(next_health.hp == 5, "Boss death discards queued charge damage")
	fixture.queue_free()
	await process_frame

func run() -> void:
	check(ResourceLoader.exists("res://scenes/roguelite/boss.tscn"), "Boss scene exists")
	if failures > 0:
		quit(1)
		return
	await physical_charge_cases()
	await stale_charge_cases()
	var room := Node2D.new()
	root.add_child(room)
	var boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	room.add_child(boss)
	boss.reset_body(Vector2(500, 350))
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	room.add_child(player)
	player.reset_body(Vector2(680, 350))
	boss.player = player
	await frames(3)
	boss.set_physics_process(false)
	boss.freeze = true
	player.freeze = true
	player.collision_layer = 0
	player.collision_mask = 0
	check(boss.gravity_scale == 0.0 and boss.hp == 45, "Boss is zero-gravity with 45 core HP")
	check(boss.is_in_group("demo_damageable"), "Boss participates in unified collision damage")
	boss.hurt(3)
	check(boss.hp == 43, "Armored core rounds half damage upward")
	boss.phase = boss.Phase.EXPOSED
	boss.hurt(3)
	check(boss.hp == 40, "Exposed core takes full damage")
	boss.hurt_at(3, boss.to_global(boss.get_node("Module0").position))
	await process_frame
	check(boss.module_hp[0] == 0 and boss.get_node("Module0").disabled, "A 3HP module breaks and disables its physical shape")
	check(boss.hp == 40, "Module damage does not also hit the core")
	# 墙体夹具要求状态由真实物理碰撞推进，不能用计时器伪造撞墙。
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.position = Vector2(850, 350)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 600)
	shape.shape = rect
	wall.add_child(shape)
	room.add_child(wall)
	boss.reset_body(Vector2(500, 350))
	boss.freeze = false
	boss.begin_warning()
	boss.set_physics_process(true)
	await frames(60)
	check(boss.phase == boss.Phase.WARNING, "Charge waits for the complete one-second warning")
	var attempts: int = 0
	while boss.phase != boss.Phase.EXPOSED and attempts < 400:
		await physics_frame
		attempts += 1
	check(boss.phase == boss.Phase.EXPOSED, "Real wall collision opens the weak point")
	check(boss.wave_warning_left > 0.0, "Wall shockwave starts with its own visible warning")
	check(boss.wave_is_safe(boss.wave_origin - boss.charge_direction * 150.0), "Shockwave leaves the marked direction safe")
	check(not boss.wave_is_safe(boss.wave_origin + boss.charge_direction * 150.0), "Opposite shockwave arc remains dangerous")
	await frames(120)
	check(boss.phase == boss.Phase.EXPOSED and boss.phase_left > 0.9 and boss.phase_left < 1.1, "Two-second weak point is still open halfway through")
	await frames(130)
	check(boss.phase == boss.Phase.RECOVERY, "Weak point closes after two seconds")
	boss.set_physics_process(false)
	var health: Node = load("res://scripts/roguelite/player_health.gd").new()
	room.add_child(health)
	boss.health = health
	boss.wave_warning_left = 1.0
	boss.wave_radius = 150.0
	boss.wave_origin = player.global_position - Vector2(150, 0)
	boss._tick_wave(0.5)
	check(health.hp == 5, "Shockwave warning cannot damage the player")
	boss.wave_warning_left = 0.0
	boss.wave_origin = player.global_position + Vector2(150, 0)
	boss._tick_wave(0.0)
	check(health.hp == 5, "Safe gap prevents actual shockwave damage")
	boss.wave_origin = player.global_position - Vector2(150, 0)
	boss._tick_wave(0.0)
	check(health.hp == 4, "Active dangerous arc damages through shared player health")
	health.invulnerability_left = 0.0
	boss._tick_wave(0.0)
	check(health.hp == 4, "One wave cannot hit twice after invulnerability expires")
	boss.wave_radius = boss.wave_max_radius
	boss._tick_wave(0.01)
	check(not boss.wave_active, "Expanding shockwave has a finite lifetime")
	# 用统一接触信号实际击中偏移模块，而不是只调用模块方法。
	var module_boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	module_boss.position = Vector2(300, 350)
	room.add_child(module_boss)
	module_boss.set_physics_process(false)
	module_boss.freeze = true
	player.freeze = false
	player.collision_layer = 2
	player.collision_mask = 8
	player.reset_body(Vector2(500, 350))
	await frames(3)
	var module_hits: Array[int] = [0]
	player.contact_report.connect(func(_actor, other, _speed, point):
		if other == module_boss:
			module_hits[0] += 1
			module_boss.hurt_at(3, point))
	player.launch(Vector2(-160, 0), 99)
	await frames(40)
	check(module_hits[0] > 0 and module_boss.module_hp[0] == 0, "Real rigid-body contact can break an attached module")
	check(module_boss.hp == 45, "Physical module hit does not double-damage the core")
	module_boss.queue_free()
	player.collision_layer = 0
	player.collision_mask = 0
	player.reset_body(boss.global_position)
	await frames(3)
	player.freeze = true
	health.reset_health()
	boss.begin_warning()
	boss._physics_process(0.1)
	check(health.hp == 5, "Ordinary body overlap during warning does not hurt")
	boss.phase = boss.Phase.CHARGE
	boss.phase_left = 1.0
	boss._physics_process(0.01)
	check(health.hp == 5, "Center overlap without a physical contact cannot cause air damage")
	var summons: Array[int] = [0]
	boss.summon_requested.connect(func(_point): summons[0] += 1)
	boss._begin_recovery(true)
	check(summons[0] == 2, "Completed wall cycle requests only two small enemies")
	# 不提供墙时也须退出冲刺，防止刚体卡住导致无限攻击。
	boss.set_physics_process(false)
	boss.phase = boss.Phase.CHARGE
	boss.phase_left = 0.01
	boss._physics_process(0.02)
	check(boss.phase == boss.Phase.RECOVERY, "Charge timeout exits without inventing a wall weak point")
	var deaths: Array[int] = [0]
	boss.died.connect(func(_body): deaths[0] += 1)
	boss.hurt(999)
	boss.hurt(999)
	await process_frame
	check(boss.dead and deaths[0] == 1, "Boss death is emitted exactly once")
	check(boss.collision_layer == 0 and not boss.wave_active, "Death removes attack and collision")
	room.queue_free()
	await process_frame
	print("ROGUELITE BOSS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
