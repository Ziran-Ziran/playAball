extends Node2D
enum State { BATTLE, UPGRADE, PAUSED, VICTORY, DEFEAT }
@export var spawn_duration: float = 30.0
@export var spawn_warning: float = 0.8
@export var spawn_interval: float = 3.4
@export var enemy_limit: int = 24
@export var run_seed: int = 31030
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
var build
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
	hud.upgrade_selected.connect(choose_upgrade)
	hud.restart_requested.connect(restart)

func clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func restart() -> void:
	get_tree().paused = false
	arena.paused = false
	arena.menu.hide()
	clear_container(enemies)
	clear_container(hazards)
	boss = null
	pending.clear()
	rice.reset_rice()
	current_choices.clear()
	hud.close()
	arena.feedback.reset_feedback()
	launcher.reset_launch()
	player.reset_body(Vector2(640, 540))
	player.cancel_opposing_momentum = 0.0
	combat.reset_combat()
	build.reset_build()
	launcher.cooldown = build.launch_cooldown()
	health.reset_health()
	companions.set_follow_enabled(false)
	companions.set_count(1)
	rng.seed = run_seed
	kills = 0
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
	queue_redraw()

func advance(delta: float) -> void:
	if state != State.BATTLE:
		return
	if health.hp <= 0:
		finish(false)
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
			open_upgrade()

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
	enemy.contact_report.connect(combat.resolve)
	enemy.died.connect(func(defeated):
		if defeated.is_inside_tree() and state == State.BATTLE:
			kills += 1
	)

func open_upgrade() -> void:
	state = State.UPGRADE
	launcher.set_blocked(true)
	clear_container(hazards)
	current_choices = build.candidates(rng, wave == 1, health.hp, health.max_hp)
	hud.show_choices(current_choices)
	get_tree().paused = true

func choose_upgrade(id: String) -> void:
	if state != State.UPGRADE:
		return
	if not current_choices.any(func(choice): return choice.id == id):
		return
	if not build.choose(id):
		return
	if id == "heal":
		health.hp = mini(health.max_hp, health.hp + 2)
		health.changed.emit(health.hp)
	apply_build()
	get_tree().paused = false
	hud.close()
	current_choices.clear()
	start_wave(wave + 1)

func apply_build() -> void:
	launcher.cooldown = build.launch_cooldown()
	companions.set_follow_enabled(int(build.levels.get("follow", 0)) > 0)
	# 增员保留已有球的位置和动量，不能每次选升级都重摆全队。
	while companions.members.size() < build.companion_count():
		companions.add_member()

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
	boss.contact_report.connect(combat.resolve)
	var encounter: Node2D = boss
	boss.died.connect(func(defeated):
		if defeated == boss and encounter.is_inside_tree():
			kills += 1
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
	var energy: String = "就绪" if launcher.remaining == 0.0 else "冷却 %.1f" % (ceilf(launcher.remaining * 10.0) / 10.0)
	if rice.stored_bonus:
		energy += " · 饱饭"
	return "生命 %d/%d · %s · 第 %s 波 · %s · 剩余 %d · 击破 %d" % [health.hp, health.max_hp, energy, "首领" if wave == 6 else str(wave), "刷怪 %.0fs" % maxf(0.0, spawn_duration - wave_elapsed) if wave < 6 and wave_elapsed < spawn_duration else "清场", alive_count(), kills]

func _draw() -> void:
	for warning: Dictionary in pending:
		draw_arc(warning.point, 26, 0, TAU, 24, Color("ffb35c"), 3, true)
		draw_line(warning.point - Vector2(10, 0), warning.point + Vector2(10, 0), Color("ffb35c"), 2)
