class_name DemoCombat
extends Node
signal hit(point: Vector2, speed: float)
signal relay(point: Vector2, generation: int)
signal explosion_triggered(point: Vector2, radius: float)
signal bowling_surged(point: Vector2, hit_count: int)
## 三名不同普通敌人的真实主球直伤；监听者校验当前局/链后才处理冷却。
signal precision_chain_completed(source_id: int, chain: int, source_revision: int, combat_revision: int)
## 逻辑判定证据；实验室只消费，不重新执行伤害或去重。
signal contact_outcome(event: Dictionary)
@export var minimum_speed: float = 180.0
@export var medium_speed: float = 450.0
@export var heavy_speed: float = 850.0
@export var pair_cooldown: float = 0.18
@export var max_generation: int = 3
@export_range(0.0,1.0) var transfer_retention: float = 0.85
var elapsed: float = 0.0
var pairs: Dictionary = {}
var events: Array[Dictionary] = []
var longest_chain: int = 0
var build: DemoBuild
var exploded_chains: Dictionary = {}
var relay_bonuses: Dictionary = {}
var projectile_targets: Dictionary = {}
var echo_history: Dictionary = {}
var pending_echoes: Array[Dictionary] = []
var _echo_revision: int = 0
var _precision_chain: int = 0
var _precision_targets: Dictionary = {}
var _precision_paid: bool = false

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
	if not is_instance_valid(actor):
		_report_outcome(actor, other, speed, point, "rejected", "invalid_actor")
		return
	if not is_instance_valid(other):
		_report_outcome(actor, other, speed, point, "rejected", "invalid_target")
		return
	if actor.reset_pending:
		_report_outcome(actor, other, speed, point, "rejected", "resetting")
		return
	if not actor.attacking():
		_report_outcome(actor, other, speed, point, "rejected", "no_attack_qualification")
		return
	if not damageable(other):
		_report_outcome(actor, other, speed, point, "rejected", "target_not_damageable")
		return
	var base_damage: int = damage_for(speed)
	if base_damage == 0:
		_report_outcome(actor, other, speed, point, "rejected", "speed_below_minimum")
		return
	if not accept_pair(actor, other):
		_report_outcome(actor, other, speed, point, "rejected", "pair_cooldown")
		return
	# 敌人投射物只消费自己的两次资格，不能继续制造下一代。
	var enemy_projectile: bool = actor.has_method("make_projectile")
	if enemy_projectile:
		var projectile_key: String = "%d:%d" % [actor.get_instance_id(), actor.chain_id]
		var struck: Array = projectile_targets.get(projectile_key, [])
		if struck.has(other.get_instance_id()):
			_report_outcome(actor, other, speed, point, "rejected", "projectile_target_repeat")
			return
		if struck.size() >= 2:
			_report_outcome(actor, other, speed, point, "rejected", "projectile_hit_budget_exhausted")
			return
		struck.append(other.get_instance_id())
		projectile_targets[projectile_key] = struck
		actor.set("projectile_hits_left", maxi(0, int(actor.get("projectile_hits_left")) - 1))
		trim_history(projectile_targets)
	var amount: int = base_damage
	if actor is DemoPlayer and build != null:
		amount += clampi(int(build.levels.get("heavy", 0)), 0, 3)
	if actor is DemoCompanion and build != null:
		amount += build.relay_damage_bonus(actor.generation)
	# hurt/died可同步重开；调用前保存链与物理方向，返回后必须复核生命周期。
	var revision: int = _echo_revision
	var source_revision: int = actor._reset_revision
	var source_id: int = actor.get_instance_id()
	var chain: int = actor.chain_id
	var generation: int = actor.generation
	var before_hp: int = _remaining_health(other)
	var target_id: int = other.get_instance_id()
	var killed_enemy: bool = other is DemoEnemy
	var impact_origin: Vector2 = other.global_position if other is Node2D else point
	var incoming: Vector2 = actor.incoming_velocity
	if incoming.is_zero_approx():
		incoming = impact_origin - actor.global_position
	if other.has_method("hurt_at"):
		other.call("hurt_at", amount, point)
	else:
		other.call("hurt", amount)
	if not _source_current(actor, revision, source_revision) or not is_instance_valid(other) or not other.is_inside_tree():
		return
	var effective: int = maxi(0, before_hp - _remaining_health(other))
	if effective <= 0:
		_report_outcome(actor, other, speed, point, "rejected", "no_effective_damage")
		return
	if actor is DemoPlayer and other is DemoEnemy:
		actor.sustain_enemy_impact(other.get_instance_id(), other.global_position - actor.global_position)
	# 冲量只作为一次明确击退，速度上限仍由刚体基类控制。
	if other is RigidBody2D and not bool(other.get("dead")):
		var direction: Vector2 = (other.global_position - actor.global_position).normalized()
		other.apply_central_impulse(direction * minf(speed * other.mass * 0.25, 260.0))
		if not enemy_projectile and (actor is DemoPlayer or actor is DemoCompanion) and upgraded("bowling") and other.has_method("make_projectile"):
			other.call("make_projectile", actor.chain_id)
	record({"chain": chain, "source": source_id, "target": other.get_instance_id(), "generation": generation, "damage": amount, "effective_damage": effective})
	_report_outcome(actor, other, speed, point, "accepted", "valid_damage", amount)
	if not _source_current(actor, revision, source_revision):
		return
	if actor is DemoPlayer and killed_enemy:
		_register_precision_hit(actor, target_id, chain, source_revision, revision)
	if not _source_current(actor, revision, source_revision):
		return
	hit.emit(point, speed)
	if not _source_current(actor, revision, source_revision):
		return
	if actor is DemoPlayer:
		actor.visual_event.emit(&"damage", {"speed": speed, "amount": amount})
	if not _source_current(actor, revision, source_revision):
		return
	if is_instance_valid(other) and (actor is DemoPlayer or actor is DemoCompanion) and upgraded("echo"):
		_schedule_echo(actor, other, speed)
	if is_instance_valid(other) and (actor is DemoPlayer or actor is DemoCompanion) and killed_enemy and bool(other.get("dead")) and upgraded("bowling"):
		_bowling_finish(impact_origin, incoming.normalized(), source_id, chain, generation, revision, source_revision)
	if not _source_current(actor, revision, source_revision):
		return
	if actor is DemoCompanion and upgraded("explosion") and not exploded_chains.has(actor.chain_id):
		exploded_chains[actor.chain_id] = true
		trim_history(exploded_chains)
		explode(actor, point)

func _register_precision_hit(actor: DemoPlayer, target_id: int, chain: int, source_revision: int, revision: int) -> void:
	if actor.chain_id != chain or chain <= 0:
		return
	if _precision_chain != chain:
		_precision_chain = chain
		_precision_targets.clear()
		_precision_paid = false
	if _precision_paid:
		return
	_precision_targets[target_id] = true
	if _precision_targets.size() >= 3:
		# 先消费本链资格再发只读事件；监听者可同步重开，不能重入领奖。
		_precision_paid = true
		precision_chain_completed.emit(actor.get_instance_id(), chain, source_revision, revision)

func _source_current(actor: Variant, revision: int, source_revision: int) -> bool:
	# Variant允许先检查已free的引用；强类型参数会在进入守卫前就触发类型错误。
	return revision == _echo_revision and is_instance_valid(actor) and actor.is_inside_tree() and not actor.is_queued_for_deletion() and not actor.reset_pending and actor._reset_revision == source_revision

func _remaining_health(target: Node) -> int:
	# 首领模块属于独立受伤部位；把模块与核心一起求差，避免漏报真实模块命中。
	var total: int = int(target.get("hp"))
	if target is DemoBoss:
		for hp: int in target.module_hp:
			total += hp
	return total

func _bowling_finish(origin: Vector2, direction: Vector2, source_id: int, chain: int, generation: int, revision: int, source_revision: int) -> void:
	if direction.is_zero_approx():
		return
	var candidates: Array[DemoEnemy] = []
	for target: Node in get_tree().get_nodes_in_group("demo_damageable"):
		if target is not DemoEnemy or not damageable(target) or target.is_queued_for_deletion():
			continue
		var offset: Vector2 = target.global_position - origin
		if offset.length_squared() <= 120.0 * 120.0 and not offset.is_zero_approx() and direction.dot(offset.normalized()) >= 0.5:
			candidates.append(target)
	candidates.sort_custom(func(a: DemoEnemy, b: DemoEnemy):
		var da: float = a.global_position.distance_squared_to(origin)
		var db: float = b.global_position.distance_squared_to(origin)
		return a.get_instance_id() < b.get_instance_id() if is_equal_approx(da, db) else da < db)
	var affected: int = 0
	for target: DemoEnemy in candidates:
		var source: DemoBody = instance_from_id(source_id) as DemoBody
		if not _source_current(source, revision, source_revision):
			return
		if not is_instance_valid(target) or target.is_queued_for_deletion() or not damageable(target):
			continue
		# 只查询墙/挡板实体，不把待清理尸体和其他球当视线墙。
		var ray := PhysicsRayQueryParameters2D.create(origin, target.global_position, 17)
		if not target.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		var target_id: int = target.get_instance_id()
		var before: int = target.hp
		target.hurt(1)
		if not _source_current(source, revision, source_revision):
			return
		var dealt: int = before - target.hp if is_instance_valid(target) else mini(before, 1)
		if dealt <= 0:
			continue
		affected += 1
		record({"chain": chain, "source": source_id, "target": target_id, "generation": generation, "damage": 1, "effective_damage": dealt, "effect": "bowling_finish"})
		if affected >= 2:
			break
	if affected > 0:
		bowling_surged.emit(origin, affected)

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
	return is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion() and (target is DemoTarget or target.is_in_group("demo_damageable")) and target.has_method("hurt") and not bool(target.get("dead"))

func explode(actor: DemoBody, point: Vector2) -> void:
	# 直接结算一次额外伤害，不重新进入 resolve，避免爆破递归或保龄球传代。
	var radius: float = build.explosion_radius(actor.generation) if build != null else 80.0
	var revision: int = _echo_revision
	var chain: int = actor.chain_id
	var source_id: int = actor.get_instance_id()
	var generation: int = actor.generation
	var source_revision: int = actor._reset_revision
	for target: Node in get_tree().get_nodes_in_group("demo_damageable"):
		if target is Node2D and damageable(target) and target.global_position.distance_to(point) <= radius:
			var before: int = _remaining_health(target)
			var target_id: int = target.get_instance_id()
			target.call("hurt", 1)
			if not _source_current(actor, revision, source_revision):
				return
			var effective: int = before - _remaining_health(target) if is_instance_valid(target) else mini(before, 1)
			if effective > 0:
				record({"chain": chain, "source": source_id, "target": target_id, "generation": generation, "damage": 1, "effective_damage": effective, "effect": "explosion"})
	explosion_triggered.emit(point, radius)

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
	receiver.activate(source.chain_id, next_generation, direction * minf(speed * receiver.mass * clampf(transfer_retention,0.0,1.0), 1050.0))
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

func _report_outcome(actor: Node, other: Node, speed: float, point: Vector2, result: String, reason: String, damage: int = 0) -> void:
	contact_outcome.emit({
		"result": result,
		"reason": reason,
		"source": actor.get_instance_id() if is_instance_valid(actor) else 0,
		"target": other.get_instance_id() if is_instance_valid(other) else 0,
		"source_chain": int(actor.get("chain_id")) if is_instance_valid(actor) else 0,
		"source_generation": int(actor.get("generation")) if is_instance_valid(actor) else 0,
		"speed": maxf(0.0, speed),
		"point": point,
		"damage": damage,
		"time": elapsed,
	})

func reset_combat() -> void:
	_precision_chain = 0
	_precision_targets.clear()
	_precision_paid = false
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
