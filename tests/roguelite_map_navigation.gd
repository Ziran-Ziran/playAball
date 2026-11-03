extends SceneTree
## 在真实碰撞空间采样通道，不从贴图或视觉包围盒猜测。
var checks: int = 0
var failures: int = 0
var results: Array[Dictionary] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)
	else:
		print("PASS: ", text)
func run() -> void:
	var game = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(game)
	game.director.set_process(false)
	game.set_process(false)
	for wave in [5, 6]:
		game.director.debug_wave(wave)
		game.director.maps.set_active(false)
		game.player.freeze = true
		if is_instance_valid(game.director.boss):
			game.director.boss.freeze = true
			game.director.boss.set_physics_process(false)
		var map = game.director.maps
		var excluded: Array[RID] = [game.player.get_rid()]
		if is_instance_valid(game.director.boss):
			excluded.append(game.director.boss.get_rid())
		for sample in 12:
			var time: float = sample * 8.0
			for name in ["TwinArcs", "InnerRing", "OuterRing"]:
				var arc = map.current_map.get_node_or_null(name)
				if arc != null:
					arc.initial_angle = time * arc.angular_speed
					arc.reset_mechanism()
			for tick in 3:
				await physics_frame
			await process_frame
			var reachable: bool = path_exists(map, map.definition.player_spawn, Vector2(640, 400), excluded)
			results.append({"map": map.definition.map_id, "rotation_time": time, "player_path": reachable})
			check(reachable, "%s rotation %.0fs retains a real 46px-player passage" % [map.definition.map_id, time])
			if wave == 6:
				check(map.point_safe(map.definition.boss_spawn, 77.0, excluded), "Whole boss including offset modules remains safe at ring center")
		if wave == 6:
			for name in ["InnerRing", "OuterRing"]:
				var arc = map.current_map.get_node(name)
				arc.initial_angle = 0.0
				arc.reset_mechanism()
			for tick in 3:
				await physics_frame
			check(boss_path_clear(game.director.boss, Vector2(250, 400)), "Complete boss shape plus margin passes initial left entrances")
			check(boss_path_clear(game.director.boss, Vector2(1030, 400)), "Complete boss shape plus margin passes initial right entrances")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.local"))
	var evidence := FileAccess.open("res://.local/map_navigation_results.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify(results, "\t"))
	evidence.close()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("MAP NAVIGATION CHECKS PASSED: ", checks) if failures == 0 else print("MAP NAVIGATION FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
func path_exists(map: Node, start: Vector2, goal: Vector2, excluded: Array[RID]) -> bool:
	const STEP: float = 8.0
	var origin: Vector2 = map.definition.bounds.position + Vector2(27, 27)
	var first := Vector2i(((start - origin) / STEP).round())
	var queue: Array[Vector2i] = [first]
	var visited: Dictionary = {first: true}
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		var point: Vector2 = origin + Vector2(cell) * STEP
		if point.distance_to(goal) <= 10.0:
			return true
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if visited.has(next):
				continue
			visited[next] = true
			var destination: Vector2 = origin + Vector2(next) * STEP
			if map.point_safe(destination, 23.0, excluded):
				queue.append(next)
	return false

func boss_path_clear(boss: Node2D, destination: Vector2) -> bool:
	for sample in range(41):
		var center: Vector2 = boss.global_position.lerp(destination, sample / 40.0)
		for collider in boss.get_children():
			if not collider is CollisionShape2D or collider.disabled:
				continue
			var circle := CircleShape2D.new()
			circle.radius = collider.shape.radius + 3.0
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = circle
			query.transform = Transform2D(0.0, center + collider.position)
			query.collision_mask = 17
			if not boss.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
				return false
	return true
