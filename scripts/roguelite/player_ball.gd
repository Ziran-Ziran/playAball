class_name DemoPlayer
extends DemoBody
@export var max_impulse: float = 1050.0
@export var max_drag: float = 160.0
@export_range(0.0, 1.0) var cancel_opposing_momentum: float = 0.0
var energy_fraction: float = 1.0

func launch(drag: Vector2, new_chain: int) -> bool:
	if drag.length() < 8.0 or reset_pending:
		return false
	chain_id = new_chain
	generation = 0
	var ratio: float = clampf((drag.length() - 8.0) / (max_drag - 8.0), 0.0, 1.0)
	# 仅抵消与新方向相反的投影；横向分量与同向惯性保留，八向规则一致。
	var direction: Vector2 = drag.normalized()
	var opposing_speed: float = minf(0.0, linear_velocity.dot(direction))
	apply_central_impulse(-direction * opposing_speed * mass * cancel_opposing_momentum)
	apply_central_impulse(direction * max_impulse * lerpf(0.45, 1.0, ratio))
	sleeping = false
	return true

func _draw() -> void:
	draw_circle(Vector2.ZERO, 23, Color("70e5ff"))
	draw_circle(Vector2(-6, -7), 7, Color("e9fbff"))
	draw_arc(Vector2.ZERO, 29, -PI / 2, -PI / 2 + TAU * maxf(energy_fraction, 0.005), 48, Color("eaffff"), 3, true)
