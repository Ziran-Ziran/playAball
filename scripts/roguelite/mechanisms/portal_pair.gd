extends Node2D
## 入口检测、出口占用与门锁归规则组件；刚体只在物理状态接口搬移。
signal teleport_requested(body: DemoBody, destination: Vector2)
signal teleport_rejected(body: DemoBody, reason: StringName)
signal traversed(from_point: Vector2, to_point: Vector2)
@export var portal_radius: float = 30.0
@export var reentry_cooldown: float = 0.35
@export var exit_clearance: float = 12.0
@export var a_normal: Vector2 = Vector2.RIGHT
@export var b_normal: Vector2 = Vector2.LEFT
@export var a_color: Color = Color("77dfd0")
@export var b_color: Color = Color("94cee6")
@export var arena_bounds: Rect2 = Rect2(40, 125, 1200, 553)
var player_health: DemoHealth
var active: bool = true
var _clock: float = 0.0
var _locks: Dictionary = {}
var _previous: Dictionary = {}
var _reservations: Array[Dictionary] = []
var _reserved_frame: int = -1
var _pending: Dictionary = {}
var _visual_pending: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	queue_redraw()
func radius_of(body: DemoBody) -> float:
	var collider: CollisionShape2D = body.get_node_or_null("Shape")
	if collider != null and collider.shape is CircleShape2D:
		return collider.shape.radius
	return 24.0
func eligible(body: DemoBody) -> bool:
	if not (body is DemoPlayer or body is DemoCompanion or body is DemoEnemy):
		return false
	if body is DemoPlayer and is_instance_valid(player_health) and player_health.hp <= 0:
		return false
	return body.can_teleport()
func set_active(value: bool) -> void:
	active = value
	if not value:
		cancel_pending()
func cancel_pending() -> void:
	for reference: WeakRef in _pending.values():
		var body = reference.get_ref()
		if is_instance_valid(body):
			body.cancel_teleport()
	_pending.clear()
	_visual_pending.clear()
	_reservations.clear()
func reset_mechanism() -> void:
	cancel_pending()
	_locks.clear()
	_previous.clear()
	_clock = 0.0
func _exit_tree() -> void:
	cancel_pending()
func _physics_process(delta: float) -> void:
	if not active:
		return
	_clock += delta
	var present: Dictionary = {}
	for node in get_tree().get_nodes_in_group("demo_bodies"):
		if not node is DemoBody or not eligible(node):
			continue
		var body: DemoBody = node
		var id: int = body.get_instance_id()
		present[id] = true
		var radius: float = portal_radius + radius_of(body)
		if _locks.has(id):
			if _clock >= float(_locks[id]) and body.global_position.distance_to($A.global_position) > radius + 8.0 and body.global_position.distance_to($B.global_position) > radius + 8.0:
				_locks.erase(id)
		var previous: Vector2 = _previous.get(id, body.global_position)
		for index in 2:
			var entry: Node2D = $A if index == 0 else $B
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(entry.global_position, previous, body.global_position)
			if closest.distance_to(entry.global_position) <= radius:
				if try_teleport(body, index):
					break
		_previous[id] = body.global_position
	for id in _previous.keys():
		if not present.has(id):
			_previous.erase(id)
			_locks.erase(id)
	for id in _pending.keys():
		if not is_instance_valid(_pending[id].get_ref()):
			_pending.erase(id)
func try_teleport(body: DemoBody, entry_index: int) -> bool:
	if not active or entry_index not in [0, 1] or not eligible(body):
		return false
	var id: int = body.get_instance_id()
	if _locks.has(id):
		return false
	var entry: Node2D = $A if entry_index == 0 else $B
	var previous: Vector2 = _previous.get(id, body.global_position)
	if Geometry2D.get_closest_point_to_segment(entry.global_position, previous, body.global_position).distance_to(entry.global_position) > portal_radius + radius_of(body):
		return false
	var frame: int = Engine.get_physics_frames()
	if frame != _reserved_frame:
		_reserved_frame = frame
		_reservations.clear()
	var exit: Node2D = $B if entry_index == 0 else $A
	var normal: Vector2 = (b_normal if entry_index == 0 else a_normal).normalized().rotated(global_rotation)
	if normal.is_zero_approx():
		normal = Vector2.LEFT if entry_index == 0 else Vector2.RIGHT
	var radius: float = radius_of(body)
	var center: Vector2 = exit.global_position + normal * (portal_radius + radius + maxf(4.0, exit_clearance))
	var tangent: Vector2 = normal.orthogonal()
	# 以最大普通敌人体积留位，不以当前小伙伴半径推算相邻大球的间隔。
	var spacing: float = 2.0 * maxf(radius, 32.0) + 12.0
	for offset: Vector2 in [Vector2.ZERO, tangent * spacing, -tangent * spacing, normal * spacing]:
		var destination: Vector2 = center + offset
		if not _space_clear(body, destination, true):
			continue
		if body.request_teleport(destination, _can_apply.bind(body, destination)):
			var callback: Callable = _body_teleported.bind(id)
			if not body.teleport_applied.is_connected(callback): body.teleport_applied.connect(callback)
			_visual_pending[id] = true
			_locks[id] = _clock + maxf(0.1, reentry_cooldown)
			_reservations.append({"body": id, "point": destination, "radius": radius})
			_pending[id] = weakref(body)
			teleport_requested.emit(body, destination)
			return true
	teleport_rejected.emit(body, &"exit_blocked")
	return false
func _can_apply(body: DemoBody, destination: Vector2) -> bool:
	var valid: bool = active and eligible(body) and _space_clear(body, destination, false)
	if not valid:
		_locks.erase(body.get_instance_id())
		_visual_pending.erase(body.get_instance_id())
	return valid

func _body_teleported(from_point: Vector2, to_point: Vector2, id: int) -> void:
	if active and _visual_pending.has(id):
		_visual_pending.erase(id)
		traversed.emit(from_point,to_point)
func _space_clear(body: DemoBody, destination: Vector2, check_reservations: bool) -> bool:
	var radius: float = radius_of(body)
	if not arena_bounds.grow(-radius - 3.0).has_point(destination):
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius + 3.0
	query.shape = circle
	query.transform = Transform2D(0.0, destination)
	query.collision_mask = 31
	query.exclude = [body.get_rid()]
	if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
		return false
	# 待命伙伴层为0，仍属于出口实体占用；不能只依赖碰撞层查询。
	for node in get_tree().get_nodes_in_group("demo_bodies"):
		if node is DemoBody and node != body and node.is_inside_tree() and not node.is_queued_for_deletion():
			if node.global_position.distance_to(destination) < radius + radius_of(node) + 4.0:
				return false
	if check_reservations:
		for reservation in _reservations:
			if reservation.body != body.get_instance_id() and destination.distance_to(reservation.point) < radius + float(reservation.radius) + 6.0:
				return false
	return true
func presentation_snapshot() -> Dictionary:
	return {"points":[$A.position,$B.position],"normals":[a_normal,b_normal],"colors":[a_color,b_color],"radius":portal_radius,"active":active}
