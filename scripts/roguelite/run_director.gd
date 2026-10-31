extends Node2D
enum State { BATTLE, UPGRADE, PAUSED, VICTORY, DEFEAT }
@export var spawn_duration: float = 30.0
@export var spawn_warning: float = 0.8
@export var spawn_interval: float = 3.4
@export var enemy_limit: int = 24
@export var run_seed: int = 31030
@export var reward_first: int = 6
@export var reward_increment: int = 2
@export var reward_cap: int = 16
@export_range(1, 6) var debug_start_wave: int = 1
@export var debug_upgrades: PackedStringArray = []
var arena: Node2D
var player: DemoPlayer
var companions: DemoCompanions
var launcher: DemoLaunch
var combat: DemoCombat
var enemies: Node2D
var hazards: Node2D
var hud: CanvasLayer
var health: Node
var rice: Node2D
var assists: Node
var build
var rewards = preload("res://scripts/roguelite/kill_rewards.gd").new()
var chosen_rewards: int = 0
var _run_revision: int = 0
var _choice_revision: int = 0
var _pulse_left: float = 0.0
var _pulse_point: Vector2
var _pulse_radius: float = 150.0
var boss: Node2D
var state: State = State.BATTLE
var wave: int = 1
var wave_elapsed: float = 0.0
var spawn_left: float = 0.0
var kills: int = 0
var pending: Array[Dictionary] = []
var current_choices: Array = []
var rng := RandomNumberGenerator.new()
const ENTRANCES: Array[Vector2] = [Vector2(140, 220), Vector2(1140, 220), Vector2(140, 570), Vector2(1140, 570)]

func setup(owner_arena: Node2D) -> void:
	arena = owner_arena
	player = arena.player
	companions = arena.companions
	launcher = arena.launcher
	combat = arena.combat
	enemies = arena.get_node("Enemies")
	hazards = arena.get_node("Hazards")
	hud = arena.get_node("RunHUD")
	build = load("res://scripts/roguelite/run_build.gd").new()
	combat.build = build
	health = load("res://scripts/roguelite/player_health.gd").new()
	health.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(health)
	health.died.connect(func(): finish(false))
	rice = load("res://scripts/roguelite/rice_manager.gd").new()
	rice.player = player
	rice.launcher = launcher
	rice.enemies = enemies
	add_child(rice)
	combat.rice_bonus = rice
	launcher.fired.connect(rice.bind_launch)
	rice.eaten.connect(arena.feedback.play_cue)
	assists = load("res://scripts/roguelite/assist_effects.gd").new()
	assists.player = player
	assists.enemies = enemies
	assists.build = build
	add_child(assists)
	assists.pulsed.connect(func(point: Vector2, radius: float):
		_pulse_point = point
		_pulse_radius = radius
		_pulse_left = 0.3
	)
	hud.upgrade_selected.connect(choose_upgrade)
	hud.restart_requested.connect(restart)

func clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func restart() -> void:
	_run_revision += 1
	_choice_revision += 1
	get_tree().paused = false
	arena.paused = false
	arena.menu.hide()
	clear_container(enemies)
	clear_container(hazards)
	boss = null
	pending.clear()
	rice.reset_rice()
	assists.reset_effects()
	_pulse_left = 0.0
	current_choices.clear()
	hud.close()
	arena.feedback.reset_feedback()
	launcher.reset_launch()
	player.reset_body(Vector2(640, 540))
	player.cancel_opposing_momentum = 0.0
	combat.reset_combat()
	build.reset_build()
	launcher.cooldown = build.launch_cooldown()
	player.apply_launch_stats(1.0, 1.0, 1.0)
	health.max_hp = build.max_health()
	health.reset_health()
	companions.set_follow_enabled(false)
	companions.set_count(1)
	rng.seed = run_seed
	kills = 0
	rewards.first_target = reward_first
	rewards.increment = reward_increment
	rewards.target_cap = reward_cap
	rewards.reset_progress()
	chosen_rewards = 0
	debug_build(debug_upgrades)
	start_wave(debug_start_wave)

func start_wave(number: int) -> void:
	wave = number
	wave_elapsed = 0.0
	spawn_left = spawn_interval
	state = State.BATTLE
	launcher.set_blocked(false)
	if number <= 5:
		queue_batch()
	else:
		spawn_boss()

func _process(delta: float) -> void:
	advance(delta)
	if state == State.BATTLE:
		_pulse_left = maxf(0.0, _pulse_left - delta)
	queue_redraw()

func advance(delta: float) -> void:
	if state != State.BATTLE:
		return
	if health.hp <= 0:
		finish(false)
		return
	if rewards.pending > 0:
		open_upgrade()
		return
	wave_elapsed += delta
	for warning: Dictionary in pending:
		warning.left -= delta
	for index in range(pending.size() - 1, -1, -1):
		if pending[index].left <= 0.0:
			spawn_enemy(pending[index].kind, pending[index].point)
			pending.remove_at(index)
	if wave <= 5:
		if wave_elapsed < spawn_duration:
			spawn_left -= delta
			if spawn_left <= 0.0:
				queue_batch()
				spawn_left = maxf(2.1, spawn_interval - (wave - 1) * 0.2)
		elif alive_count() == 0 and pending.is_empty():
			start_wave(wave + 1)

func alive_count() -> int:
	var count: int = 0
	for enemy in enemies.get_children():
		if not enemy.dead:
			count += 1
	return count

func safe_entrance(offset: int) -> Vector2:
	for attempt in ENTRANCES.size():
		var point: Vector2 = ENTRANCES[(offset + attempt) % ENTRANCES.size()]
		if point.distance_to(player.position) >= 200.0:
			return point
	return ENTRANCES[offset % ENTRANCES.size()]

func queue_batch() -> void:
	var amount: int = 2 if wave <= 2 else 3
	for index in amount:
		if alive_count() + pending.size() >= enemy_limit:
			break
		var kind: int = 0
		var roll: float = rng.randf()
		if wave >= 3 and roll > 0.76:
			kind = 2
		elif wave >= 2 and roll > 0.54:
			kind = 1
		var point: Vector2 = safe_entrance(rng.randi_range(0, 3)) + Vector2(index * 34, 0)
		pending.append({"point": point, "kind": kind, "left": spawn_warning})

func spawn_enemy(kind: int, point: Vector2) -> void:
	if alive_count() >= (7 if wave == 6 else enemy_limit):
		return
	# 预警后再次核对距离；玩家已到入口时，改到安全入口并重新预警。
	if point.distance_to(player.position) < 200.0:
		pending.append({"point": safe_entrance(0), "kind": kind, "left": spawn_warning})
		return
	var enemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.kind = kind
	enemy.player = player
	enemy.health = health
	enemy.hazards = hazards
	enemy.position = point
	enemies.add_child(enemy)
	apply_enemy_build(enemy)
	enemy.contact_report.connect(combat.resolve)
	var revision: int = _run_revision
	enemy.died.connect(func(defeated):
		if revision == _run_revision and defeated.is_inside_tree():
			register_kill(defeated.get_instance_id())
	)

func register_kill(instance_id: int) -> void:
	if state in [State.VICTORY, State.DEFEAT]:
		return
	if rewards.add_kill(instance_id):
		kills = rewards.kills

func open_upgrade() -> void:
	if rewards.pending <= 0 or state not in [State.BATTLE, State.UPGRADE]:
		return
	state = State.UPGRADE
	launcher.set_blocked(true)
	# 战斗中领奖只暂停，不删除飞行中的弹/球或改变它们的动量。
	current_choices = build.candidates(rng, chosen_rewards == 0, health.hp, health.max_hp)
	_choice_revision += 1
	hud.show_choices(current_choices, build.levels, rewards.pending, _choice_revision)
	get_tree().paused = true

func choose_upgrade(id: String, offer_id: int = -1) -> void:
	if state != State.UPGRADE:
		return
	if offer_id >= 0 and offer_id != _choice_revision:
		return
	if not current_choices.any(func(choice): return choice.id == id):
		return
	if not build.choose(id):
		return
	if not rewards.consume_reward():
		return
	chosen_rewards += 1
	if id == "heal":
		health.hp = mini(health.max_hp, health.hp + 2)
	apply_build()
	hud.close()
	current_choices.clear()
	if rewards.pending > 0:
		open_upgrade()
		return
	get_tree().paused = false
	state = State.BATTLE
	launcher.set_blocked(false)

func apply_build() -> void:
	var old_cooldown: float = launcher.cooldown
	launcher.cooldown = build.launch_cooldown()
	# 缩冷却保留当前恢复百分比；重复同步构筑不会再额外减一次。
	launcher.remaining *= launcher.cooldown / maxf(0.001, old_cooldown)
	launcher.set_capacity(build.launch_capacity())
	player.apply_launch_stats(build.launch_multiplier(), build.damping_multiplier(), build.friction_multiplier())
	var old_max: int = health.max_hp
	health.max_hp = build.max_health()
	health.hp = mini(health.max_hp, health.hp + maxi(0, health.max_hp - old_max))
	health.changed.emit(health.hp)
	companions.set_follow_enabled(int(build.levels.get("follow", 0)) > 0)
	# 增员保留已有球的位置和动量，不能每次选升级都重摆全队。
	while companions.members.size() < build.companion_count():
		companions.add_member()
	for enemy in enemies.get_children():
		apply_enemy_build(enemy)

func apply_enemy_build(enemy: Node) -> void:
	if enemy.has_method("apply_attack_scale"):
		enemy.apply_attack_scale(build.attack_radius_scale())

func debug_build(ids: PackedStringArray) -> void:
	build.reset_build()
	for id in ids:
		build.choose(id)
	apply_build()

func spawn_boss() -> void:
	clear_container(enemies)
	boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	boss.player = player
	boss.health = health
	boss.position = Vector2(640, 240)
	enemies.add_child(boss)
	apply_enemy_build(boss)
	boss.contact_report.connect(combat.resolve)
	var encounter: Node2D = boss
	boss.died.connect(func(defeated):
		if defeated == boss and encounter.is_inside_tree():
			register_kill(defeated.get_instance_id())
			finish(true)
	)
	boss.summon_requested.connect(func(point: Vector2):
		if alive_count() - 1 + pending.size() < 6:
			pending.append({"point": point.clamp(Vector2(140, 200), Vector2(1140, 580)), "kind": 0, "left": spawn_warning})
	)

func finish(won: bool) -> void:
	if state in [State.VICTORY, State.DEFEAT]:
		return
	state = State.VICTORY if won else State.DEFEAT
	launcher.set_blocked(true)
	pending.clear()
	rewards.pending = 0
	current_choices.clear()
	rice.reset_rice()
	get_tree().paused = true
	arena.menu.hide()
	hud.show_result(won, kills, combat.longest_chain)

func set_paused(value: bool) -> void:
	if state not in [State.BATTLE, State.PAUSED]:
		return
	state = State.PAUSED if value else State.BATTLE
	arena.paused = value
	arena.menu.visible = value
	launcher.set_blocked(value)
	get_tree().paused = value

func debug_wave(number: int) -> void:
	get_tree().paused = false
	arena.paused = false
	arena.menu.hide()
	hud.close()
	current_choices.clear()
	clear_container(enemies)
	clear_container(hazards)
	boss = null
	pending.clear()
	start_wave(clampi(number, 1, 6))

func status_text() -> String:
	var energy: String = "%d/%d次可发" % [launcher.charges, launcher.capacity] if launcher.available() else "冷却 %.1f" % (ceilf(launcher.remaining * 10.0) / 10.0)
	if rice.stored_bonus:
		energy += " · 饱饭"
	return "生命%d/%d · %s · %s波 · 发射%d · 敌%d · 击杀%d · 奖励%d/%d（待选%d）" % [health.hp, health.max_hp, energy, "首领" if wave == 6 else str(wave), launcher.shots, alive_count(), kills, rewards.progress, rewards.next_target(), rewards.pending]

func _draw() -> void:
	if _pulse_left > 0.0:
		draw_arc(to_local(_pulse_point), _pulse_radius * (1.0 - _pulse_left / 0.3), 0, TAU, 48, Color(0.4, 0.9, 1.0, _pulse_left / 0.3), 3, true)
	for warning: Dictionary in pending:
		draw_arc(warning.point, 26, 0, TAU, 24, Color("ffb35c"), 3, true)
		draw_line(warning.point - Vector2(10, 0), warning.point + Vector2(10, 0), Color("ffb35c"), 2)
