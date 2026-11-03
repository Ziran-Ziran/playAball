class_name DemoCompanions
extends Node2D
const COMPANION: PackedScene = preload("res://scenes/roguelite/companion_ball.tscn")
var player: DemoPlayer
var combat: DemoCombat
var follow_enabled: bool = false
var members: Array[DemoCompanion] = []
var desired_count: int = 0
var _retry_left: float = 0.0
var map_provider: Node

func _physics_process(delta: float) -> void:
	_retry_left = maxf(0.0, _retry_left - delta)
	if members.size() < desired_count and _retry_left <= 0.0:
		ensure_count(desired_count)
		_retry_left = 0.2

func ensure_count(count: int) -> void:
	desired_count = clampi(count, 0, 4)
	while members.size() < desired_count:
		if not add_member(desired_count):
			break

func set_count(count: int) -> void:
	for member in members:
		remove_child(member)
		member.queue_free()
	members.clear()
	# 独立实验靶场仍可摆四球验证接力上限；正式局数量由构筑限制为三。
	ensure_count(count)

func add_member(formation_count: int = 0) -> bool:
	if members.size() >= 4:
		return false
	var member: DemoCompanion = COMPANION.instantiate()
	member.player = player
	member.combat = combat
	member.slot = members.size()
	member.slot_count = formation_count if formation_count > 0 else members.size() + 1
	member.follow_enabled = follow_enabled
	if is_instance_valid(map_provider):
		member.arena_bounds = map_provider.definition.bounds
		member.map_provider = map_provider
	# 增员不重摆已有小弟；整局复位则使用下一物理帧的主球目标坐标。
	var origin: Vector2 = player.reset_point if player.reset_pending else player.position
	var safe_bounds: Rect2 = member.arena_bounds.grow(-30.0)
	member.position = (origin + member.follow_offset()).clamp(safe_bounds.position, safe_bounds.end)
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	query.shape = circle
	query.collision_mask = 27
	# 完全堵住时保留增员请求，待空间空出后重试，不回退到主球中心。
	var found: bool = false
	for ring in [1.0, 1.6, 2.2]:
		for attempt in 8:
			member.position = (origin + member.follow_offset().rotated(attempt * TAU / 8.0) * ring).clamp(safe_bounds.position, safe_bounds.end)
			query.transform = Transform2D(0.0, member.position)
			var overlaps_member: bool = false
			for existing in members:
				if existing.position.distance_to(member.position) < 32.0:
					overlaps_member = true
			var map_safe: bool = not is_instance_valid(map_provider) or map_provider.point_safe(member.position, 14.0)
			if map_safe and not overlaps_member and member.position.distance_to(origin) >= 40.0 and get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
				found = true
				break
		if found:
			break
	if not found:
		member.free()
		return false
	for existing in members:
		existing.slot_count = member.slot_count
	add_child(member)
	member.contact_report.connect(combat.resolve)
	members.append(member)
	return true

func set_follow_enabled(value: bool) -> void:
	follow_enabled = value
	for member in members:
		member.follow_enabled = value
		if member.mode != DemoCompanion.Mode.ACTIVE:
			member.end_attack()
