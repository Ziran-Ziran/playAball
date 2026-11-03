extends RefCounted
var elapsed: float = 0.0
var input_attempts: int = 0
var input_accepted: int = 0
var nominal_damage: int = 0
var effective_damage: int = 0
var damage_events: int = 0
var partner_direct_damage: int = 0
var partner_damage_events: int = 0
var activations: int = 0
var kills: int = 0
var first_kill: float = -1.0
var first_damage: float = -1.0
var first_hurt: float = -1.0
var clear_time: float = -1.0
var threat_time: float = 0.0
var hp_lost: int = 0
var blocked_time: float = 0.0
var corner_time: float = 0.0
var portal_requests: int = 0
var teleports: int = 0
var spike_hits: int = 0
var reversal_time: float = -1.0
var rejection_reasons: Dictionary = {}
var raw: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var hard_failures: Array[String] = []
var _hp: Dictionary = {}
var _recent_hp_loss: Dictionary = {}
var _health_hp: int = 5
var _previous_position: Vector2
var _sample_left: float = 0.0
var fixture: Node
func bind(owner_fixture: Node) -> void:
	fixture = owner_fixture
	_previous_position = fixture.player.position
	_health_hp = fixture.health.hp
	fixture.combat.contact_outcome.connect(on_contact)
	fixture.combat.relay.connect(func(point: Vector2,generation: int):
		activations += 1
		raw.append({"time":elapsed,"kind":"partner_activation","generation":generation,"point":[point.x,point.y]}))
	fixture.health.changed.connect(on_health)
	for enemy in fixture.enemies.get_children():
		_hp[enemy.get_instance_id()] = enemy.hp
		enemy.presentation_event.connect(on_enemy_event.bind(enemy.get_instance_id()))
		enemy.died.connect(func(_enemy):
			kills += 1
			if first_kill < 0.0: first_kill = elapsed
			if kills == _hp.size(): clear_time = elapsed)
func on_enemy_event(event: StringName, payload: Dictionary, id: int) -> void:
	if event != &"hurt":
		return
	var remaining: int = int(payload.hp)
	var lost: int = maxi(0, int(_hp.get(id, remaining)) - remaining)
	_recent_hp_loss[id] = {"lost":lost,"time":elapsed}
	_hp[id] = remaining
	effective_damage += lost
	if lost > 0:
		if first_damage < 0.0: first_damage = elapsed
		raw.append({"time": elapsed, "kind": "effective_damage", "target": id, "amount": lost, "remaining_hp": remaining})
func on_contact(event: Dictionary) -> void:
	var record: Dictionary = event.duplicate()
	var point: Vector2 = record.point
	record.point = [point.x, point.y]
	record.kind = "contact_outcome"
	raw.append(record)
	if event.result == "accepted":
		damage_events += 1
		nominal_damage += int(event.damage)
		var source: Object = instance_from_id(int(event.source))
		var target: int = int(event.target)
		var recent: Dictionary = _recent_hp_loss.get(target,{})
		# 正式hurt同步发布HP，随后发布接触结果；只归因同目标紧邻的实际扣血。
		if source is DemoCompanion and not recent.is_empty() and is_equal_approx(float(recent.time),elapsed):
			partner_direct_damage += int(recent.lost)
			partner_damage_events += 1
		_recent_hp_loss.erase(target)
	else:
		rejection_reasons[event.reason] = int(rejection_reasons.get(event.reason, 0)) + 1
func on_health(hp: int) -> void:
	var lost: int = maxi(0, _health_hp - hp)
	_health_hp = hp
	hp_lost += lost
	if lost > 0:
		if first_hurt < 0.0: first_hurt = elapsed
		raw.append({"time": elapsed, "kind": "player_hurt", "amount": lost, "hp": hp})
func tick(delta: float) -> void:
	elapsed += delta
	var threats: int = 0
	for enemy in fixture.enemies.get_children():
		if not enemy.dead: threats += 1
	if threats > 0 and fixture.health.hp > 0:
		threat_time += delta
	if threats > 0 and not fixture.launcher.available() and fixture.health.hp > 0:
		blocked_time += delta
	var point: Vector2 = fixture.player.position
	if point.distance_to(_previous_position) > 250.0:
		teleports += 1
	_previous_position = point
	if not fixture.bounds.grow(5).has_point(point) and not hard_failures.has("player_out_of_bounds"):
		hard_failures.append("player_out_of_bounds")
	if not point.is_finite() or not fixture.player.linear_velocity.is_finite():
		if not hard_failures.has("non_finite_physics"): hard_failures.append("non_finite_physics")
	for member in fixture.companions.members:
		if not fixture.bounds.grow(5).has_point(member.position) and not hard_failures.has("partner_out_of_bounds"):
			hard_failures.append("partner_out_of_bounds")
		if not member.position.is_finite() or not member.linear_velocity.is_finite():
			if not hard_failures.has("non_finite_partner_physics"): hard_failures.append("non_finite_partner_physics")
	var safe: Rect2 = fixture.bounds.grow(-70.0)
	if not safe.has_point(point) and fixture.player.linear_velocity.length() < 80.0 and fixture.enemies.get_child_count() > 0:
		corner_time += delta
	if fixture.scenario == "reverse" and elapsed >= 2.35 and reversal_time < 0.0 and fixture.player.linear_velocity.x < -50.0:
		reversal_time = elapsed - 2.35
	_sample_left -= delta
	if _sample_left <= 0.0:
		_sample_left += 0.1
		samples.append({"time": elapsed, "position": [point.x, point.y], "velocity": [fixture.player.linear_velocity.x, fixture.player.linear_velocity.y], "hp": fixture.health.hp, "shots": fixture.launcher.shots, "cooldown": fixture.launcher.remaining})
func summary() -> Dictionary:
	return {"seconds": elapsed, "threat_seconds": threat_time, "clear_time": clear_time, "outcome": "cleared" if clear_time >= 0.0 else ("dead" if fixture.health.hp <= 0 else "censored"), "input_attempts": input_attempts, "input_accepted": input_accepted, "nominal_damage": nominal_damage,"partner_direct_damage":partner_direct_damage,"partner_damage_events":partner_damage_events,"activations":activations, "effective_damage": effective_damage, "damage_events": damage_events, "kills": kills, "first_kill": first_kill, "first_damage": first_damage, "first_hurt": first_hurt, "hp_lost": hp_lost, "cooldown_wait": blocked_time, "corner_time": corner_time, "portal_requests": portal_requests, "teleports": teleports, "spike_hits": spike_hits, "reversal_time": reversal_time, "longest_chain": fixture.combat.longest_chain, "rejections": rejection_reasons, "hard_failures": hard_failures.duplicate()}
