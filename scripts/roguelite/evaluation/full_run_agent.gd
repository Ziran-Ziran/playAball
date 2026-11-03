extends Node2D
## 正常整局代理：只瞄准正式发射并选择真实菜单提供的合法请求。
class InputLedger extends RefCounted:
	var input_attempts: int = 0
	var input_accepted: int = 0
	var raw: Array[Dictionary] = []
	var elapsed: float = 0.0
var scenario: String = "full_run"
var bounds: Rect2
var player: Node2D
var launcher: Node
var enemies: Node2D
var companions: Node2D
var health: Node
var build: RefCounted
var game: Node2D
var director: Node
var combat: Node
var profile: Resource
var policy: RefCounted
var metrics := InputLedger.new()
var route: String
var elapsed: float = 0.0
var battle_seconds: float = 0.0
var hp_lost: int = 0
var effective_damage: int = 0
var module_damage: int = 0
var _last_hp: int = 5
var _enemy_hp: Dictionary = {}
var _module_hp: Dictionary = {}
var choices: Array[Dictionary] = []
var stage_events: Array[Dictionary] = []
var recoveries: Array[Dictionary] = []
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(delta: float) -> void:
	# 恢复暂停必须发生在正常idle阶段，避开Godot4.7.1 step/flush间隙。
	if is_instance_valid(director) and director.state != director.State.BATTLE:
		drive(elapsed, delta)
func bind(owner_game: Node2D, candidate: Resource, build_route: String) -> void:
	game = owner_game
	director = game.director
	combat = director.combat
	director.maps.recovery_requested.connect(func(body: Node2D, from_point: Vector2, to_point: Vector2):
		recoveries.append({"time": elapsed, "body": body.get_class(), "name": body.name, "from": [from_point.x, from_point.y], "to": [to_point.x, to_point.y], "velocity": [body.linear_velocity.x, body.linear_velocity.y], "wave": director.wave}))
	player = game.player
	launcher = game.launcher
	enemies = director.enemies
	companions = game.companions
	health = director.health
	build = director.build
	profile = candidate
	route = build_route
	policy = load("res://scripts/roguelite/evaluation/input_policy.gd").new()
	policy.strategy = "relay" if route == "partners" else ("safe" if route == "mobility" else "nearest")
	bounds = director.maps.definition.bounds
	health.changed.connect(_on_health)
	director.run_event.connect(func(event: String): stage_events.append({"time": elapsed, "event": event, "wave": director.wave, "map": director.maps.definition.map_id}))
	enemies.child_entered_tree.connect(func(enemy: Node): _watch_enemy.call_deferred(enemy.get_instance_id()))
	director.combat.contact_outcome.connect(func(event: Dictionary):
		var item: Dictionary = event.duplicate()
		var point: Vector2 = item.point
		item.point = [point.x, point.y]
		metrics.raw.append(item))
	apply_profile()
func apply_profile() -> void:
	var old: float = launcher.cooldown
	profile.apply(self)
	launcher.remaining *= launcher.cooldown / maxf(0.001, old)
func drive(time: float, delta: float) -> void:
	elapsed = time
	metrics.elapsed = time
	poll_boss_damage()
	bounds = director.maps.definition.bounds
	match director.state:
		director.State.BATTLE:
			battle_seconds += delta
			policy.update(self, time, delta)
		director.State.UPGRADE:
			if director.current_choices.is_empty(): return
			var priorities: Array = ["heavy","echo","bowling","launch_power","cooldown","double_launch","pulse","heal","companion"]
			if route == "partners": priorities = ["companion","follow","relay","explosion","heavy","echo","cooldown","heal"]
			if route == "mobility": priorities = ["cooldown","double_launch","glide","launch_power","pulse","shrink","heal","heavy"]
			if health.hp <= 2: priorities.push_front("heal")
			var available: Array[String] = []
			for card in director.current_choices: available.append(card.id)
			var chosen: String = available[0]
			for id: String in priorities:
				if available.has(id):
					chosen = id
					break
			var card: Button = director.hud.cards.get_child(available.find(chosen))
			if card.disabled:
				return
			choices.append({"time": elapsed, "wave": director.wave, "available": available, "selected": chosen, "source": director.reward_source})
			card.pressed.emit()
			apply_profile()
		director.State.SHOP:
			if health.hp <= 3: director.buy_shop("heal", director.rest_revision)
			if not director.buy_shop("upgrade", director.rest_revision): director.continue_stage(director.rest_revision)
		director.State.EVENT:
			director.resolve_event("heal" if health.hp <= 3 else "upgrade", director.rest_revision)
func _on_health(hp: int) -> void:
	hp_lost += maxi(0, _last_hp - hp)
	_last_hp = hp
	metrics.raw.append({"kind": "health", "time": elapsed, "hp": hp})
func _watch_enemy(id: int) -> void:
	var enemy: Object = instance_from_id(id)
	if not is_instance_valid(enemy) or not enemy.is_inside_tree() or _enemy_hp.has(id): return
	_enemy_hp[id] = enemy.hp
	if "module_hp" in enemy:
		_module_hp[id] = enemy.module_hp.duplicate()
	if enemy.has_signal("presentation_event"):
		enemy.presentation_event.connect(_enemy_event.bind(id))
func _enemy_event(event: StringName, payload: Dictionary, id: int) -> void:
	if event != &"hurt": return
	var remaining: int = int(payload.hp)
	var lost: int = maxi(0, int(_enemy_hp.get(id, remaining)) - remaining)
	_enemy_hp[id] = remaining
	effective_damage += lost
	metrics.raw.append({"kind": "effective_damage", "time": elapsed, "amount": lost, "remaining_hp": remaining, "target": id})
func poll_boss_damage() -> void:
	for enemy in enemies.get_children():
		if not "module_hp" in enemy: continue
		var id: int = enemy.get_instance_id()
		var previous: int = int(_enemy_hp.get(id, enemy.hp))
		var lost: int = maxi(0, previous - enemy.hp)
		_enemy_hp[id] = enemy.hp
		effective_damage += lost
		var modules: Array = _module_hp.get(id, enemy.module_hp)
		var lost_modules: int = 0
		for index in modules.size(): lost_modules += maxi(0, int(modules[index]) - int(enemy.module_hp[index]))
		_module_hp[id] = enemy.module_hp.duplicate()
		module_damage += lost_modules
		if lost > 0 or lost_modules > 0:
			metrics.raw.append({"kind": "boss_damage", "time": elapsed, "core_loss": lost, "module_loss": lost_modules})
