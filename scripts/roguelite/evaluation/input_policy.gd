extends RefCounted
## 策略只能选方向/力度并调用正式发射接口；不写速度、伤害、冷却或攻击资格。
var strategy: String = "nearest"
var _attempt_left: float = 0.0
func update(fixture: Node, time: float, delta: float) -> void:
	_attempt_left -= delta
	if _attempt_left > 0.0 or fixture.health.hp <= 0:
		return
	_attempt_left = 0.1
	if fixture.scenario == "reverse" and fixture.launcher.shots > 0 and time < 2.35:
		return
	var intent: Vector2 = direction(fixture, time)
	if intent.is_zero_approx():
		return
	fixture.metrics.input_attempts += 1
	if fixture.launcher.launch_with_drag(intent * fixture.player.max_drag):
		fixture.metrics.input_accepted += 1
		fixture.metrics.raw.append({"time": fixture.metrics.elapsed, "kind": "launch", "direction": [intent.x, intent.y], "chain": fixture.launcher.shots})
func direction(fixture: Node, time: float) -> Vector2:
	if fixture.scenario == "reverse" and time < 2.35:
		return Vector2.RIGHT if fixture.launcher.shots == 0 else Vector2.ZERO
	var target: Node2D
	var distance: float = INF
	for enemy in fixture.enemies.get_children():
		if enemy.dead:
			continue
		var candidate: float = enemy.global_position.distance_squared_to(fixture.player.global_position)
		if candidate < distance:
			target = enemy
			distance = candidate
	if not is_instance_valid(target):
		return Vector2.ZERO
	var desired: Vector2 = (target.global_position - fixture.player.global_position).normalized()
	if strategy == "relay":
		for member in fixture.companions.members:
			var offset: Vector2 = member.global_position - fixture.player.global_position
			if member.mode != member.Mode.ACTIVE and offset.dot(desired) > 20.0 and offset.length() < 350.0:
				desired = offset.normalized()
				break
	if strategy == "safe":
		var best: float = -INF
		var chosen: Vector2 = desired
		for angle: float in [0.0, -0.55, 0.55, -1.1, 1.1, -1.65, 1.65]:
			var candidate: Vector2 = desired.rotated(angle)
			var destination: Vector2 = fixture.player.global_position + candidate * 180.0
			var score: float = candidate.dot(desired) * 100.0
			if not fixture.bounds.grow(-45).has_point(destination):
				score -= 180.0
			var query := PhysicsRayQueryParameters2D.create(fixture.player.global_position, destination, 17, [fixture.player.get_rid()])
			if not fixture.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				score -= 160.0
			for spikes in fixture.get_tree().get_nodes_in_group("map_spikes"):
				for fraction: float in [0.33, 0.66, 1.0]:
					var local: Vector2 = spikes.to_local(fixture.player.global_position.lerp(destination, fraction))
					if Rect2(-spikes.length * 0.5, -spikes.tooth_depth, spikes.length, spikes.tooth_depth + 5.0).grow(25.0).has_point(local):
						score -= 100.0
						break
			for enemy in fixture.enemies.get_children():
				# 这里只估计普通敌人预警；首领有独立阶段/震波字段，不能误读成DemoEnemy。
				if enemy is DemoEnemy and not enemy.dead and enemy.warning_left > 0 and destination.distance_to(enemy.global_position) < enemy.pulse_radius + 50.0:
					score -= 100.0
			if score > best:
				best = score
				chosen = candidate
		desired = chosen
	return desired
