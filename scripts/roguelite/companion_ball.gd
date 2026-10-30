class_name DemoCompanion
extends DemoBody
enum Mode { IDLE, ACTIVE, RETURNING }
@export var active_duration: float = 3.0
@export var return_force: float = 420.0
@export var return_speed: float = 400.0
@export var follow_distance: float = 110.0
@export var follow_enabled: bool = false
var mode: Mode = Mode.IDLE
var player: DemoPlayer
var combat: DemoCombat
var slot: int = 0
var slot_count: int = 1
var active_left: float = 0.0
var low_speed_time: float = 0.0
const DEFAULT_THEME: DemoTheme = preload("res://resources/roguelite/themes/fat_fish.tres")
@export var theme: DemoTheme = DEFAULT_THEME
@onready var sensor: Area2D = $Sensor

func attacking() -> bool:
	return mode == Mode.ACTIVE and chain_id > 0

func activate(chain: int, depth: int, impulse: Vector2) -> void:
	mode = Mode.ACTIVE
	speed_limit = 1500.0
	chain_id = chain
	generation = depth
	active_left = active_duration
	low_speed_time = 0.0
	set_deferred("collision_layer", 4)
	set_deferred("collision_mask", 31)
	apply_central_impulse(impulse)
	sleeping = false

func end_attack() -> void:
	# 默认散落在场内；只有未来的“跟随”升级开启后才主动归队。
	mode = Mode.RETURNING if follow_enabled else Mode.IDLE
	speed_limit = return_speed if follow_enabled else 1500.0
	chain_id = 0
	generation = 0
	set_deferred("collision_layer", 0)
	# 只对球使用传感器，外墙、内部挡板和箱体在任何状态下都必须实体碰撞。
	set_deferred("collision_mask", 25)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if mode == Mode.ACTIVE:
		active_left -= delta
		low_speed_time = low_speed_time + delta if linear_velocity.length() < 180.0 else 0.0
		if active_left <= 0.0 or low_speed_time >= 0.3:
			end_attack()
	else:
		if follow_enabled:
			speed_limit = return_speed
			var target: Vector2 = (player.global_position + follow_offset()).clamp(Vector2(80, 165), Vector2(1200, 640))
			var difference: Vector2 = target - global_position
			# 升级后的引导仍使用物理力，不以穿墙或瞬移解决被挡住的问题。
			apply_central_force((difference * 9.0 - linear_velocity * 5.0).limit_length(return_force))
			if difference.length() < 45.0:
				mode = Mode.IDLE
		for body: Node2D in sensor.get_overlapping_bodies():
			if body is DemoBody and body != self:
				if combat.activate(body, self):
					break
	if global_position.y > 820 or global_position.y < -100 or global_position.x < -100 or global_position.x > 1380:
		end_attack()
		reset_body(player.global_position + Vector2(0, -80))
	queue_redraw()

func follow_offset() -> Vector2:
	return Vector2.from_angle(-PI / 2.0 + TAU * slot / maxi(1, slot_count)) * follow_distance

func _draw() -> void:
	var palette: DemoTheme = theme if theme != null else DEFAULT_THEME
	var color: Color = palette.active_color if mode == Mode.ACTIVE else palette.companion_color
	# 尾迹始终沿速度反向，脸保持正向，避免旋转表情干扰主球辨识。
	if mode == Mode.ACTIVE:
		draw_line(Vector2.ZERO, -linear_velocity.limit_length(36), palette.active_color, 4, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -6), Vector2(-8, 0), Vector2(-16, 6)]), color)
	draw_circle(Vector2.ZERO, 14, color)
	draw_circle(Vector2(1, 5), 7, palette.belly_color)
	draw_arc(Vector2.ZERO, 14, 0, TAU, 28, palette.outline_color, 1, true)
	for eye_x: float in [-4.0, 5.0]:
		if _feedback_left > 0.0:
			draw_line(Vector2(eye_x - 2, -4), Vector2(eye_x + 1, -2), palette.outline_color, 1.5, true)
		else:
			draw_circle(Vector2(eye_x, -3), 2.5, palette.outline_color)
	draw_arc(Vector2.ZERO, 18, 0, TAU, 28, color, 2 if mode == Mode.ACTIVE else 1, true)
	if mode == Mode.RETURNING:
		draw_line(Vector2(-4, 8), Vector2(0, 11), palette.outline_color, 1.5, true)
		draw_line(Vector2(0, 11), Vector2(4, 8), palette.outline_color, 1.5, true)

