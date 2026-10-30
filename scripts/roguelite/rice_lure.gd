class_name DemoRice
extends Area2D
## 只是平面局部力源和拾取区域；绝不覆盖刚体位置、速度或碰撞层。
signal collected(rice: DemoRice)
@export var lifetime: float = 8.0
@export var attraction_radius: float = 200.0
@export var max_force: float = 180.0
@export var show_radius: bool = true
var player: DemoPlayer
var remaining: float = 8.0
var consumed: bool = false

func _ready() -> void:
	remaining = lifetime
	body_entered.connect(_on_body_entered)

func pull_force(point: Vector2) -> Vector2:
	if consumed or remaining <= 0.0 or not is_inside_tree():
		return Vector2.ZERO
	var offset: Vector2 = global_position - point
	var distance: float = offset.length()
	if distance >= attraction_radius or distance <= 0.01:
		return Vector2.ZERO
	return offset.normalized() * maxf(0.0, max_force) * clampf(1.0 - distance / attraction_radius, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0:
		consumed = true
		_retire.call_deferred()
		return
	if is_instance_valid(player) and not player.reset_pending:
		player.apply_central_force(pull_force(player.global_position))
	# 最后一秒只闪烁外观，不挪走碰撞区域，接近中的主球仍可吃到。
	modulate.a = 0.35 if remaining < 1.0 and fmod(remaining, 0.2) < 0.1 else 1.0
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if not is_inside_tree() or consumed or remaining <= 0.0 or body != player:
		return
	consumed = true
	collected.emit(self)
	_retire.call_deferred()

func _retire() -> void:
	# Area 回调中不可直接移除物理对象；先用 consumed 停力/去重，延后退出世界。
	if is_inside_tree():
		get_parent().remove_child(self)
	queue_free()

func _draw() -> void:
	if show_radius:
		draw_arc(Vector2.ZERO, attraction_radius, 0, TAU, 80, Color(0.9, 0.95, 0.7, 0.12), 1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-23, 0), Vector2(23, 0), Vector2(16, 19), Vector2(-16, 19)]), Color("b4e4d5"))
	draw_circle(Vector2(0, -3), 18, Color("fff9db"))
	draw_circle(Vector2(-11, -3), 10, Color("fff9db"))
	draw_circle(Vector2(11, -3), 10, Color("fff9db"))
	draw_line(Vector2(-23, 2), Vector2(23, 2), Color("589d9b"), 3, true)
	for index in 3:
		var x: float = (index - 1) * 12.0
		var drift: float = sin((lifetime - remaining) * 3.0 + index) * 3.0
		draw_polyline(PackedVector2Array([Vector2(x, -27), Vector2(x + drift, -35), Vector2(x - drift, -44)]), Color(1, 1, 0.9, 0.6), 2, true)
