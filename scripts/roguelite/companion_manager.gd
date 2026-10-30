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
		var member: DemoCompanion = COMPANION.instantiate()
		member.player = player
		member.combat = combat
		member.slot = index
		member.slot_count = clampi(count, 1, 4)
		member.follow_enabled = follow_enabled
		# 整场复位尚待下一物理帧执行，不能围绕主球旧位置生成同伴。
		var origin: Vector2 = player.reset_point if player.reset_pending else player.position
		member.position = (origin + member.follow_offset()).clamp(Vector2(80, 165), Vector2(1200, 640))
		add_child(member)
		member.contact_report.connect(combat.resolve)
		members.append(member)

func set_follow_enabled(value: bool) -> void:
	follow_enabled = value
	for member in members:
		member.follow_enabled = value
		if member.mode != DemoCompanion.Mode.ACTIVE:
			member.end_attack()
