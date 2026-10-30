class_name DemoPlayer
extends DemoBody
@export var max_impulse: float = 1050.0
@export var max_drag: float = 160.0
@export_range(0.0, 1.0) var cancel_opposing_momentum: float = 0.0
var energy_fraction: float = 1.0
const DEFAULT_THEME: DemoTheme = preload("res://resources/roguelite/themes/fat_fish.tres")
@export var theme: DemoTheme = DEFAULT_THEME
var well_fed: bool = false

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
	var palette: DemoTheme = theme if theme != null else DEFAULT_THEME
	var motion: Vector2 = linear_velocity.abs().limit_length(900.0) / 900.0
	var squash: Vector2 = Vector2(1.0 + motion.x * 0.04 - motion.y * 0.03, 1.0 + motion.y * 0.04 - motion.x * 0.03)
	var startled: bool = _feedback_left > 0.0
	if startled:
		squash = Vector2(1.04, 0.94)
	# 绘图变换只作用于鱼身，绝不缩放刚体、Shape 或外侧能量环。
	draw_set_transform(Vector2.ZERO, 0.0, squash)
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -8), Vector2(-13, 0), Vector2(-24, 8)]), palette.outline_color)
	draw_circle(Vector2.ZERO, 23, palette.player_color)
	draw_arc(Vector2.ZERO, 23, 0, TAU, 48, palette.outline_color, 1.5, true)
	draw_circle(Vector2(2, 8), 12, palette.belly_color)
	draw_arc(Vector2(17, 4), 5, -PI / 2, PI / 2, 12, palette.outline_color, 2, true)
	for eye_x: float in [-6.0, 7.0]:
		var eye: Vector2 = Vector2(eye_x, -6)
		if startled:
			draw_line(eye + Vector2(-3, -2), eye + Vector2(2, 2), palette.outline_color, 2, true)
		else:
			draw_circle(eye, 5, palette.belly_color)
			draw_circle(eye + Vector2(1, 0), 2.4, palette.outline_color)
	if well_fed:
		# 饱饭仅作为外部状态的图形提示，消费/强化逻辑不放在绘制中。
		draw_arc(Vector2(1, 7), 8, 0.15, PI - 0.15, 16, palette.well_fed_color, 3, true)
		draw_colored_polygon(PackedVector2Array([Vector2(16, 12), Vector2(18, 8), Vector2(20, 12), Vector2(18, 16)]), palette.well_fed_color)
	elif startled:
		draw_circle(Vector2(1, 7), 3, palette.outline_color)
	else:
		draw_arc(Vector2(1, 5), 4, 0.1, PI - 0.1, 12, palette.outline_color, 1.5, true)
	draw_set_transform(Vector2.ZERO)
	draw_arc(Vector2.ZERO, 29, -PI / 2, -PI / 2 + TAU * maxf(energy_fraction, 0.005), 48, palette.energy_color, 3, true)
