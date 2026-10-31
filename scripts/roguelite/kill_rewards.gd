class_name KillRewards
extends Resource
@export var first_target: int = 6
@export var increment: int = 2
@export var target_cap: int = 16
var kills: int = 0
var progress: int = 0
var pending: int = 0
var earned: int = 0
var _seen: Dictionary = {}

func next_target() -> int:
	var first: int = maxi(1, first_target)
	return mini(maxi(first, target_cap), first + maxi(0, increment) * earned)

func add_kill(instance_id: int) -> bool:
	if instance_id <= 0 or _seen.has(instance_id):
		return false
	_seen[instance_id] = true
	kills += 1
	progress += 1
	# 爆破同帧跨门槛时保留余数，每次奖励仍需由玩家独立选择。
	while progress >= next_target():
		progress -= next_target()
		pending += 1
		earned += 1
	return true

func consume_reward() -> bool:
	if pending <= 0:
		return false
	pending -= 1
	return true

func reset_progress() -> void:
	kills = 0
	progress = 0
	pending = 0
	earned = 0
	_seen.clear()
