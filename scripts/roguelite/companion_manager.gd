class_name DemoCompanions
extends Node2D
const COMPANION: PackedScene = preload("res://scenes/roguelite/companion_ball.tscn")
var player: DemoPlayer
var combat: DemoCombat
var follow_enabled: bool = false
var members: Array[DemoCompanion] = []
func set_count(count: int) -> void:
	for member in members:
		remove_child(member)
		member.queue_free()
	members.clear()
	for index in clampi(count, 1, 4):
		add_member(clampi(count, 1, 4))

func add_member(formation_count: int = 0) -> void:
	if members.size() >= 4:
		return
	var member: DemoCompanion = COMPANION.instantiate()
	member.player = player
	member.combat = combat
	member.slot = members.size()
	member.slot_count = formation_count if formation_count > 0 else members.size() + 1
	member.follow_enabled = follow_enabled
	for existing in members:
		existing.slot_count = member.slot_count
	# 增员不重摆已有小弟；整局复位则使用下一物理帧的主球目标坐标。
	var origin: Vector2 = player.reset_point if player.reset_pending else player.position
	member.position = (origin + member.follow_offset()).clamp(Vector2(80, 165), Vector2(1200, 640))
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	query.shape = circle
	query.collision_mask = 25
	# 新增球不能生成在挡板或敌人内部；依次尝试八个初始位置。
	for attempt in 9:
		if attempt == 8:
			member.position = origin
		query.transform = Transform2D(0.0, member.position)
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			break
		member.position = (origin + member.follow_offset().rotated((attempt + 1) * TAU / 8.0)).clamp(Vector2(80, 165), Vector2(1200, 640))
	add_child(member)
	member.contact_report.connect(combat.resolve)
	members.append(member)

func set_follow_enabled(value: bool) -> void:
	follow_enabled = value
	for member in members:
		member.follow_enabled = value
		if member.mode != DemoCompanion.Mode.ACTIVE:
			member.end_attack()
