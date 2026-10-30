class_name DemoHazard
extends RigidBody2D
## 单发慢危险弹；传感器只伤玩家，刚体只与环境碰撞。
@export var lifetime: float = 5.0
var health: DemoHealth
var spent: bool = false

func _ready() -> void:
	gravity_scale = 0.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	add_to_group("demo_hazard")
	$PlayerSensor.body_entered.connect(_on_player_entered)
	body_entered.connect(_on_wall_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_player_entered(body: Node) -> void:
	# 重开先移除旧危险物；物理队列中的旧接触不可伤到新局。
	if not is_inside_tree() or spent or not body is DemoPlayer:
		return
	spent = true
	if is_instance_valid(health):
		health.hurt()
	queue_free()

func _on_wall_entered(_body: Node) -> void:
	spent = true
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12, Color("ff6659"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -15), Vector2(15, 11), Vector2(-15, 11)]), Color("ffbc63"))
	draw_line(Vector2(-5, -5), Vector2(5, 5), Color("511c31"), 3)
	draw_line(Vector2(-5, 5), Vector2(5, -5), Color("511c31"), 3)
