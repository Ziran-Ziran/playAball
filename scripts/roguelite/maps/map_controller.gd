extends Node
signal recovery_requested(body: Node2D, from_point: Vector2, to_point: Vector2)
## 先以旧围场实现相同接口；四图接线阶段替换内部地图，不触碰构筑/经济。
var definition: Resource = preload("res://resources/roguelite/maps/legacy.tres")
var arena: Node2D
var current_map: Node2D
var active: bool = true
var last_change: bool = false
var player_health: DemoHealth
const MAPS: Array[String] = ["map_01", "map_02", "map_03", "boss_map"]
func setup(owner_arena: Node2D) -> void:
	arena = owner_arena
	arena.map_provider = self
	current_map = owner_arena
	process_mode = Node.PROCESS_MODE_PAUSABLE
	arena.companions.map_provider = self

func select_wave(wave: int, force: bool = false) -> bool:
	var index: int = 0 if wave <= 2 else (1 if wave <= 4 else (2 if wave == 5 else 3))
	last_change = force or definition.map_id != MAPS[index]
	if not last_change:
		return true
	set_active(false)
	if current_map != arena and is_instance_valid(current_map):
		current_map.get_parent().remove_child(current_map)
		current_map.queue_free()
	for key in ["LeftRamp", "RightRamp"]:
		var old: Node2D = arena.get_node_or_null(key)
		if old != null:
			old.hide()
			old.get_node("Shape").disabled = true
	current_map = load("res://scenes/roguelite/maps/%s.tscn" % MAPS[index]).instantiate()
	arena.add_child(current_map)
	definition = current_map.definition
	var rice: Node = arena.get_node("RunDirector").rice
	if is_instance_valid(rice):
		rice.safe_bounds = definition.bounds.grow(-60.0)
	for mechanism in current_map.find_children("*", "Node2D", true, false):
		if "player_health" in mechanism:
			mechanism.player_health = player_health
			mechanism.arena_bounds = definition.bounds
		if mechanism.is_in_group("map_spikes"):
			mechanism.player = arena.player
			mechanism.health = player_health
	for member: DemoCompanion in arena.companions.members:
		member.arena_bounds = definition.bounds
	set_active(false)
	return place_party()

func place_party() -> bool:
	var excluded: Array[RID] = [arena.player.get_rid()]
	for member: DemoCompanion in arena.companions.members:
		excluded.append(member.get_rid())
	var point: Vector2 = find_safe_point(definition.player_spawn, 23.0, excluded)
	if not point.is_finite():
		push_error("地图没有可用的玩家安全出生点")
		return false
	arena.player.reset_body(point)
	var placed: Array[Vector2] = [point]
	for member: DemoCompanion in arena.companions.members:
		var candidate: Vector2 = Vector2.INF
		for direction in 16:
			var preferred: Vector2 = point + member.follow_offset().rotated(direction * TAU / 16.0)
			var safe: Vector2 = find_safe_point(preferred, 14.0, excluded)
			var separate: bool = safe.is_finite()
			for occupied: Vector2 in placed:
				if safe.distance_to(occupied) < 42.0:
					separate = false
			if separate:
				candidate = safe
				break
		if not candidate.is_finite():
			push_error("地图没有可用的伙伴安全出生点")
			return false
		member.end_attack()
		member.reset_body(candidate)
		placed.append(candidate)
	return true
func obstacles() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if current_map == arena:
		for key in ["LeftRamp", "RightRamp", "Corners"]:
			var obstacle: Node2D = arena.get_node_or_null(key)
			if obstacle != null:
				result.append(obstacle)
	else:
		for node in current_map.get_children():
			if node is Node2D:
				result.append(node)
	return result
func point_safe(point: Vector2, radius: float, excluded: Array[RID] = []) -> bool:
	if not point.is_finite() or not definition.bounds.grow(-radius - 3.0).has_point(point):
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = maxf(1.0, radius + 3.0)
	query.shape = circle
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 31
	query.exclude = excluded
	if not arena.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
		return false
	# 伤害区域和待命伙伴没有实体碰撞层，仍不能作为出生位置。
	for hazard in get_tree().get_nodes_in_group("map_spikes"):
		if not is_instance_valid(hazard) or not hazard.is_inside_tree():
			continue
		var local: Vector2 = hazard.to_local(point)
		if Rect2(-hazard.length * 0.5, -hazard.tooth_depth, hazard.length, hazard.tooth_depth + 5).grow(radius + 4.0).has_point(local):
			return false
	for body in get_tree().get_nodes_in_group("demo_bodies"):
		if body is DemoCompanion and not excluded.has(body.get_rid()) and body.global_position.distance_to(point) < radius + 18.0:
			return false
	return true
func find_safe_point(preferred: Vector2, radius: float, excluded: Array[RID] = []) -> Vector2:
	if point_safe(preferred, radius, excluded):
		return preferred
	for ring in range(1, 9):
		for direction in 16:
			var candidate: Vector2 = preferred + Vector2.from_angle(TAU * direction / 16.0) * float(ring) * 40.0
			if point_safe(candidate, radius, excluded):
				return candidate
	return Vector2.INF
func set_active(value: bool) -> void:
	active = value
	if current_map != arena and is_instance_valid(current_map):
		for portal in current_map.find_children("*", "Node2D", true, false):
			if portal.has_method("set_active"):
				portal.set_active(value)
func reset_map() -> void:
	if current_map != arena and is_instance_valid(current_map):
		for mechanism in current_map.find_children("*", "Node2D", true, false):
			if mechanism.has_method("reset_mechanism"):
				mechanism.reset_mechanism()
