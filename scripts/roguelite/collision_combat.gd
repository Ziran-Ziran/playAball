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
var build: DemoBuild
var rice_bonus: Node
var exploded_chains: Dictionary = {}
var relay_bonuses: Dictionary = {}
var projectile_targets: Dictionary = {}
var echo_history: Dictionary = {}
var pending_echoes: Array[Dictionary] = []
var _echo_revision: int = 0

func _physics_process(delta: float) -> void:
	elapsed += delta
	_advance_echoes(delta)
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
	if not damageable(other) or damage_for(speed) == 0:
		return
	if not accept_pair(actor, other):
		return
	# 敌人投射物只消费自己的两次资格，不能继续制造下一代。
	var enemy_projectile: bool = actor.has_method("make_projectile")
	if enemy_projectile:
		var projectile_key: String = "%d:%d" % [actor.get_instance_id(), actor.chain_id]
		var struck: Array = projectile_targets.get(projectile_key, [])
		if struck.has(other.get_instance_id()) or struck.size() >= 2:
			return
		struck.append(other.get_instance_id())
		projectile_targets[projectile_key] = struck
		actor.set("projectile_hits_left", maxi(0, int(actor.get("projectile_hits_left")) - 1))
		trim_history(projectile_targets)
	var amount: int = damage_for(speed)
	if actor is DemoPlayer and build != null:
		amount += clampi(int(build.levels.get("heavy", 0)), 0, 3)
	# 饱饭只属于吃饭后发起的新链，敌人投射物/爆炸不提前消费它。
	if is_instance_valid(rice_bonus) and (actor is DemoPlayer or actor is DemoCompanion):
		amount += int(rice_bonus.consume_bonus(actor.chain_id))
	if other.has_method("hurt_at"):
		other.call("hurt_at", amount, point)
	else:
		other.call("hurt", amount)
	# 冲量只作为一次明确击退，速度上限仍由刚体基类控制。
	if other is RigidBody2D and not bool(other.get("dead")):
		var direction: Vector2 = (other.global_position - actor.global_position).normalized()
		other.apply_central_impulse(direction * minf(speed * other.mass * 0.25, 260.0))
		if not enemy_projectile and (actor is DemoPlayer or actor is DemoCompanion) and upgraded("bowling") and other.has_method("make_projectile"):
			other.call("make_projectile", actor.chain_id)
	record({"chain": actor.chain_id, "source": actor.get_instance_id(), "target": other.get_instance_id(), "generation": actor.generation, "damage": amount})
	hit.emit(point, speed)
	if (actor is DemoPlayer or actor is DemoCompanion) and upgraded("echo"):
		_schedule_echo(actor, other, speed)
	if actor is DemoCompanion and upgraded("explosion") and not exploded_chains.has(actor.chain_id):
		exploded_chains[actor.chain_id] = true
		trim_history(exploded_chains)
		explode(actor, point)

func _schedule_echo(actor: DemoBody, target: Node, speed: float) -> void:
	if not target.is_inside_tree() or target.is_queued_for_deletion() or not damageable(target):
		return
	var key: String = "%d:%d:%d" % [actor.get_instance_id(), target.get_instance_id(), actor.chain_id]
	if echo_history.has(key) or pending_echoes.size() >= 256:
		return
	echo_history[key] = true
	trim_history(echo_history)
	pending_echoes.append({"left": 0.12, "target": target.get_instance_id(), "source": actor.get_instance_id(), "chain": actor.chain_id, "generation": actor.generation, "speed": speed})
	# 即使同一节点被移走后重新加入，也不能把旧命中带进新一局。
	if not target.tree_exiting.is_connected(_cancel_target_echoes.bind(target.get_instance_id())):
		target.tree_exiting.connect(_cancel_target_echoes.bind(target.get_instance_id()), CONNECT_ONE_SHOT)

func _cancel_target_echoes(target_id: int) -> void:
	for index in range(pending_echoes.size() - 1, -1, -1):
		if int(pending_echoes[index].target) == target_id:
			pending_echoes.remove_at(index)

func _advance_echoes(delta: float) -> void:
	var ready: Array[Dictionary] = []
	for index in range(pending_echoes.size() - 1, -1, -1):
		pending_echoes[index].left -= delta
		if float(pending_echoes[index].left) <= 0.0:
			ready.push_front(pending_echoes[index])
			pending_echoes.remove_at(index)
	var revision: int = _echo_revision
	for event in ready:
		# 伤害信号可能触发整局重置，已取出的本帧旧队列也必须一起作废。
		if revision != _echo_revision:
			return
		var target: Object = instance_from_id(int(event.target))
		if not is_instance_valid(target) or not target is Node2D or not target.is_inside_tree() or target.is_queued_for_deletion() or not damageable(target):
			continue
		var point: Vector2 = target.global_position
		# 只直接追加一次伤害；不经过 resolve，不消费白饭或触发其它升级。
		target.call("hurt", 1)
		if revision != _echo_revision:
			return
		record({"chain": event.chain, "source": event.source, "target": event.target, "generation": event.generation, "damage": 1, "effect": "echo"})
		hit.emit(point, float(event.speed))

func upgraded(id: String) -> bool:
	return build != null and build.has_upgrade(id)

func damageable(target: Node) -> bool:
	return (target is DemoTarget or target.is_in_group("demo_damageable")) and target.has_method("hurt") and not bool(target.get("dead"))

func explode(actor: DemoBody, point: Vector2) -> void:
	# 直接结算一次额外伤害，不重新进入 resolve，避免爆破递归或保龄球传代。
	for target: Node in get_tree().get_nodes_in_group("demo_damageable"):
		if target is Node2D and damageable(target) and target.global_position.distance_to(point) <= 80.0:
			target.call("hurt", 1)
			record({"chain": actor.chain_id, "source": actor.get_instance_id(), "target": target.get_instance_id(), "generation": actor.generation, "damage": 1, "effect": "explosion"})

func trim_history(history: Dictionary) -> void:
	# 活跃小兵仅持续3秒；保留最近256个链路标记足够且不会随整局无限增长。
	while history.size() > 256:
		history.erase(history.keys()[0])

func activate(source: DemoBody, receiver: DemoCompanion) -> bool:
	if not (source is DemoPlayer or source is DemoCompanion) or not source.attacking() or source.reset_pending or receiver.mode == DemoCompanion.Mode.ACTIVE:
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
	var bonus_key: String = "%d:%d" % [source.chain_id, receiver.get_instance_id()]
	if source is DemoCompanion and upgraded("relay") and not relay_bonuses.has(bonus_key):
		relay_bonuses[bonus_key] = true
		trim_history(relay_bonuses)
		var bonus: float = minf(speed * receiver.mass * 0.25, 262.5)
		receiver.apply_central_impulse(direction * bonus)
		record({"chain": source.chain_id, "source": source.get_instance_id(), "target": receiver.get_instance_id(), "generation": next_generation, "damage": 0, "effect": "relay_bonus", "impulse": bonus})
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
	_echo_revision += 1
	pending_echoes.clear()
	echo_history.clear()
	pairs.clear()
	events.clear()
	longest_chain = 0
	elapsed = 0.0
	exploded_chains.clear()
	relay_bonuses.clear()
	projectile_targets.clear()
