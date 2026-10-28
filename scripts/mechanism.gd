extends Area2D
## 只改变区域内球的物理参数，离开区域时恢复。

enum Kind { BOOST, STICKY, REVERSE_GRAVITY }

@export var kind: Kind = Kind.BOOST
@export var boost_force: float = 1700.0
@export var sticky_damping: float = 5.0
@export var reversed_gravity: float = -0.65
@export var zone_size: Vector2 = Vector2(180, 220)

var _bodies: Array[PlayBall] = []

func _ready() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = zone_size
	$Shape.shape = rectangle
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)

func _on_entered(body: Node2D) -> void:
	if body is PlayBall and not _bodies.has(body):
		_bodies.append(body)

func _on_exited(body: Node2D) -> void:
	if body is PlayBall:
		_restore(body)
		_bodies.erase(body)

func _restore(body: PlayBall) -> void:
	body.gravity_scale = 1.0
	body.linear_damp = body.base_damping

func set_kind(value: int) -> void:
	for body in _bodies:
		if is_instance_valid(body):
			_restore(body)
	kind = value as Kind
	queue_redraw()

func _physics_process(_delta: float) -> void:
	for body in _bodies:
		if not is_instance_valid(body) or body.completed:
			continue
		match kind:
			Kind.BOOST:
				body.apply_central_force(Vector2(boost_force, 0))
			Kind.STICKY:
				body.linear_damp = sticky_damping
			Kind.REVERSE_GRAVITY:
				body.gravity_scale = reversed_gravity

func _draw() -> void:
	var colors: Array[Color] = [Color("f6b965"), Color("c899ff"), Color("77e6b4")]
	var color: Color = colors[kind]
	draw_rect(Rect2(-zone_size / 2.0, zone_size), Color(color, 0.08))
	draw_rect(Rect2(-zone_size / 2.0, zone_size), Color(color, 0.6), false, 1.5)
	for y in range(-80, 90, 40):
		var direction := Vector2(15, 0) if kind == Kind.BOOST else Vector2(0, -15)
		if kind == Kind.STICKY:
			draw_circle(Vector2(0, y), 4.0, color)
		else:
			var center := Vector2(0, y)
			draw_line(center - direction, center + direction, color, 2.0, true)
			draw_line(center + direction, center + direction.rotated(2.4), color, 2.0, true)
			draw_line(center + direction, center + direction.rotated(-2.4), color, 2.0, true)
