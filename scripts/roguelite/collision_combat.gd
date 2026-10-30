class_name DemoCombat
extends Node
signal hit(point: Vector2, speed: float)
signal relay(point: Vector2, generation: int)
@export var minimum_speed: float = 180.0
@export var medium_speed: float = 450.0
@export var heavy_speed: float = 850.0
@export var pair_cooldown: float = 0.18
@export var max_generation: int = 3
var elapsed: float = 0.0
var pairs: Dictionary = {}
var events: Array[Dictionary] = []
var longest_chain: int = 0

func _physics_process(delta: float) -> void:
	elapsed += delta
	# 只保留近期配对和有限诊断记录，长时间试玩不会增长无界。
	for key: String in pairs.keys():
		if elapsed - float(pairs[key]) > 1.0:
			pairs.erase(key)

func damage_for(speed: float) -> int:
	if speed < minimum_speed:
		return 0
	return 3 if speed >= heavy_speed else (2 if speed >= medium_speed else 1)

func accept_pair(a: Node, b: Node) -> bool:
	var key: String = "%d:%d" % [mini(a.get_instance_id(), b.get_instance_id()), maxi(a.get_instance_id(), b.get_instance_id())]
	if elapsed - float(pairs.get(key, -100.0)) < pair_cooldown:
		return false
	pairs[key] = elapsed
	return true

func resolve(actor: DemoBody, other: Node, speed: float, point: Vector2) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(other) or not actor.attacking() or actor.reset_pending:
		return
	if not other is DemoTarget or other.dead or damage_for(speed) == 0:
		return
	if not accept_pair(actor, other):
		return
	other.hurt(damage_for(speed))
	record({"chain": actor.chain_id, "source": actor.get_instance_id(), "target": other.get_instance_id(), "generation": actor.generation, "damage": damage_for(speed)})
	hit.emit(point, speed)

func activate(source: DemoBody, receiver: DemoCompanion) -> bool:
	if not source.attacking() or source.reset_pending or receiver.mode == DemoCompanion.Mode.ACTIVE:
		return false
	var next_generation: int = source.generation + 1
	if next_generation > max_generation:
		return false
	var direction: Vector2 = (receiver.global_position - source.global_position).normalized()
	var speed: float = maxf(0.0, (source.linear_velocity - receiver.linear_velocity).dot(direction))
	if damage_for(speed) == 0 or not accept_pair(source, receiver):
		return false
	# 传感器交接没有实体碰撞，只有此处一次传能；出击球之间不额外补冲量。
	receiver.activate(source.chain_id, next_generation, direction * minf(speed * receiver.mass * 0.85, 1050.0))
	source.apply_central_impulse(-direction * minf(speed * 0.12 * source.mass, 120.0))
	longest_chain = maxi(longest_chain, next_generation)
	record({"chain": source.chain_id, "source": source.get_instance_id(), "target": receiver.get_instance_id(), "generation": next_generation, "damage": 0})
	relay.emit(receiver.global_position, next_generation)
	return true

func record(event: Dictionary) -> void:
	events.append(event)
	if events.size() > 256:
		events.pop_front()

func reset_combat() -> void:
	pairs.clear()
	events.clear()
	longest_chain = 0
	elapsed = 0.0
