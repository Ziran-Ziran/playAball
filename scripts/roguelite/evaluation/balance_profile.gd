extends Resource
## 评估白名单。只改这一组可复核参数，不碰求解器、伤害去重或出生规则。
@export var profile_id: String = "baseline"
@export var group: String = "control"
@export var impulse: float = 1050.0
@export_range(0, 1) var opposing_cancel: float = 0.0
@export var cooldown: float = 2.2
@export_range(0,1) var transfer_retention: float = 0.85
func apply(fixture: Node) -> void:
	fixture.player.max_impulse = impulse * fixture.build.launch_multiplier()
	fixture.player.cancel_opposing_momentum = opposing_cancel
	fixture.launcher.cooldown = maxf(0.5, cooldown - 0.25 * int(fixture.build.levels.get("cooldown", 0)))
	fixture.combat.transfer_retention = transfer_retention
func snapshot() -> Dictionary:
	return {"id": profile_id, "group": group, "impulse": impulse, "opposing_cancel": opposing_cancel, "cooldown": cooldown,"transfer_retention":transfer_retention}
