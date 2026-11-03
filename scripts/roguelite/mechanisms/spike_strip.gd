extends Area2D
## 尖刺只表达接触，生命组件统一校验无敌时间、死亡与重复伤害。
signal player_hit(point: Vector2)
@export var length: float = 180.0
@export var tooth_depth: float = 12.0
var player: DemoPlayer
var health: DemoHealth
var active: bool = true
func set_active(value: bool) -> void:
	active = value
func _ready() -> void:
	add_to_group("map_spikes")
	process_mode = Node.PROCESS_MODE_PAUSABLE
func _physics_process(_delta: float) -> void:
	if not active or not is_instance_valid(player) or not is_instance_valid(health):
		return
	if get_overlapping_bodies().has(player) and not player.reset_pending and _currently_touching_player():
		if health.hurt(1):
			player_hit.emit(player.global_position)

func _currently_touching_player() -> bool:
	# Area重叠列表可能比刚体复位晚一物理步；按当前真实形状复核，不能远程扣血。
	var player_shape: CollisionShape2D = player.get_node("Shape")
	var spike_shape: CollisionShape2D = $Shape
	if not player_shape.shape is CircleShape2D or not spike_shape.shape is RectangleShape2D: return false
	var point: Vector2 = spike_shape.to_local(player_shape.global_position)
	var half: Vector2 = spike_shape.shape.size*0.5
	var radius: float = player_shape.shape.radius*absf(player_shape.global_scale.x)/maxf(0.001,absf(spike_shape.global_scale.x))
	return point.distance_squared_to(point.clamp(-half,half)) <= radius*radius
func reset_mechanism() -> void:
	pass
func _draw() -> void:
	var count: int = maxi(1, int(length / 18.0))
	var step: float = length / count
	for index in count:
		var x: float = -length * 0.5 + index * step
		draw_colored_polygon(PackedVector2Array([Vector2(x, 5), Vector2(x + step * 0.5, -tooth_depth), Vector2(x + step, 5)]), Color("d75964"))
