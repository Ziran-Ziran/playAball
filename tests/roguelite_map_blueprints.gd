extends SceneTree
## 回归本轮图纸的玩法含义；不把旧测试通过当作图纸已满足。
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(40.0).timeout.connect(func(): push_error("Blueprint timeout"); quit(1))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	for id: String in ["map_01", "map_02", "map_03", "boss_map"]:
		var map: Node2D = load("res://scenes/roguelite/maps/%s.tscn" % id).instantiate()
		root.add_child(map)
		if id == "map_01":
			for side: String in ["LeftPaddle", "RightPaddle"]:
				check(map.get_node(side) is StaticBody2D, "Map one side is fixed: " + side)
			check(map.definition.player_spawn.y > map.get_node("UpperPaddle").position.y and map.definition.player_spawn.y < map.get_node("LowerPaddle").position.y if map.has_node("LowerPaddle") else false, "Map one spawn lies between upper and lower paddles")
			if map.has_node("LowerPaddle"):
				var lower: Node2D = map.get_node("LowerPaddle")
				check(lower.pivot_offset == Vector2.ZERO and is_equal_approx(lower.initial_angle, PI / 2.0), "Lower paddle is vertical and rotates about center")
		elif id == "map_02":
			check(is_equal_approx(map.get_node("CrossPivot").initial_angle, PI / 4.0), "Cross initially forms X")
			check(map.definition.player_spawn.y < map.get_node("CrossPivot").position.y, "Map two spawn is above X")
			await check_movers(map, Vector2.DOWN)
			var spikes: Array[Node] = map.find_children("*", "Area2D", true, false)
			check(spikes.size() == 6, "Only three separated spike clusters on each side")
			for spike: Node2D in spikes:
				check(spike.position.x < 100.0 or spike.position.x > 1180.0, "No top/bottom spikes")
				check(spike.length <= 40.0 and spike.tooth_depth <= 8.0, "Side spikes are short and shallow")
		elif id == "map_03":
			check(map.definition.player_spawn.is_equal_approx(map.get_node("TwinArcs").position), "Map three starts at ring center")
			check(is_equal_approx(map.get_node("TwinArcs").initial_angle, PI / 4.0), "Ring gaps initially upper left and lower right")
			await check_movers(map, Vector2.RIGHT)
			for side: String in ["MovingLeft", "MovingRight"]:
				var mover: Node2D = map.get_node(side)
				check(is_zero_approx(mover.rotation), "Spiked plate is horizontal: " + side)
				var spike: Node2D = mover.get_node("Body/" + side + "Spikes")
				var tip: Vector2 = Vector2.UP.rotated(spike.global_rotation)
				check(tip.dot(Vector2.DOWN if side == "MovingLeft" else Vector2.UP) > 0.99, "Spikes face arena center: " + side)
		else:
			check(map.definition.player_spawn.x < 400.0 and map.definition.player_spawn.y > 500.0, "Boss map player starts lower left")
			check(map.definition.boss_spawn.x > 900.0 and map.definition.boss_spawn.y < 300.0, "Boss starts upper right")
			check(map.find_children("InnerSpikes*", "Area2D", true, false).size() == 4, "Inner ring has four outward spike clusters")
			for side: String in ["LeftPaddle", "RightPaddle", "UpperPaddle", "LowerPaddle"]:
				check(map.has_node(side), "Boss paddle lies at cardinal side: " + side)
			for pair_name: String in ["GreenPortals", "YellowPortals"]:
				check(map.has_node(pair_name), "Boss has portal pair: " + pair_name)
				if map.has_node(pair_name):
					var pair: Node2D = map.get_node(pair_name)
					var a: Vector2 = pair.get_node("A").global_position
					var b: Vector2 = pair.get_node("B").global_position
					check(is_equal_approx(a.x, b.x) if pair_name == "GreenPortals" else is_equal_approx(a.y, b.y), "Portal pairing follows color axis")
		# 尖刺画面和真实接触范围必须同步，短刺不能留下旧长矩形。
		for spike: Node2D in map.find_children("*", "Area2D", true, false):
			if not spike.has_method("_currently_touching_player"):
				continue
			var shape: CollisionShape2D = spike.get_node("Shape")
			check(shape.shape.size.is_equal_approx(Vector2(spike.length, spike.tooth_depth + 5.0)), "Spike bounds follow authored visible dimensions")
		map.queue_free()
		await process_frame
	await boss_portal_contacts()
	print("BLUEPRINT CHECKS: %d failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check_movers(map: Node2D, axis: Vector2) -> void:
	var displacements: Array[Vector2] = []
	for side: String in ["MovingLeft", "MovingRight"]:
		var mover: Node2D = map.get_node(side)
		mover.set_physics_process(false)
		mover.reset_mechanism()
		var before: Vector2 = mover.get_node("Body").global_position
		mover._physics_process(mover.period / 4.0)
		var displacement: Vector2 = mover.get_node("Body").global_position - before
		check(absf(displacement.cross(axis)) < 0.01 and displacement.length() > 1.0, "Moving plate follows world axis: " + side)
		displacements.append(displacement)
	check((displacements[0] + displacements[1]).length() < 0.01, "Moving plates retain central symmetry")

func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame

func boss_portal_contacts() -> void:
	var map: Node2D = load("res://scenes/roguelite/maps/boss_map.tscn").instantiate()
	root.add_child(map)
	for mechanism: Node in map.get_children():
		if mechanism.has_method("set_active"):
			mechanism.set_active(false)
		mechanism.set_physics_process(false)
	for side: String in ["UpperPaddle", "LowerPaddle"]:
		var paddle: Node2D = map.get_node(side)
		var sweep_radius: float = Vector2(paddle.length / 2.0, 9.0).length()
		check(paddle.position.distance_to(Vector2(640, 400)) > 189.0 + sweep_radius + 3.0, "Full short-paddle sweep stays outside outer ring: " + side)
		check(paddle.position.y - sweep_radius > 125.0 and paddle.position.y + sweep_radius < 678.0, "Short-paddle sweep stays inside arena: " + side)
	for pair_name: String in ["GreenPortals", "YellowPortals"]:
		var pair: Node2D = map.get_node(pair_name)
		pair.set_active(true)
		for entry in 2:
			for actor_path: String in ["player_ball", "companion_ball", "enemy"]:
				pair.reset_mechanism()
				var body: DemoBody = load("res://scenes/roguelite/%s.tscn" % actor_path).instantiate()
				body.position = pair.get_node("A" if entry == 0 else "B").global_position
				root.add_child(body)
				body.set_physics_process(false)
				await frames(2)
				body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
				body.angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
				body.linear_damp = 0.0
				body.angular_damp = 0.0
				body.lock_rotation = false
				body.linear_velocity = Vector2(12, 7)
				body.angular_velocity = 1.7
				body.chain_id = 90
				body.generation = 2
				var source: Vector2 = body.position
				check(pair.try_teleport(body, entry), "Real boss-map portal accepts %s/%s/%d" % [pair_name, actor_path, entry])
				await frames(2)
				var exit: Vector2 = pair.get_node("B" if entry == 0 else "A").global_position
				check(body.position.distance_to(exit) < 85.0 and body.position.distance_to(source) > 100.0, "Actual relocation reaches same-color counterpart")
				check(body.linear_velocity.distance_to(Vector2(12, 7)) < 0.1 and absf(body.angular_velocity - 1.7) < 0.01 and body.chain_id == 90 and body.generation == 2, "Boss portal preserves motion and attack identity")
				body.queue_free()
				await frames(2)
		pair.set_active(false)
	map.queue_free()
	await frames(2)
