extends Node2D
signal run_event(event: String)
enum State { BATTLE, UPGRADE, PAUSED, VICTORY, DEFEAT, SHOP, EVENT, TRANSITION }
@export var enable_stage_breaks: bool = true
@export var heal_price: int = 4
@export var upgrade_price: int = 8
@export var transition_duration: float = 3.0
@export var split_enabled: bool = false
var flow = preload("res://scripts/roguelite/stage_flow.gd").new()
var wallet = preload("res://scripts/roguelite/run_wallet.gd").new()
var rest_panel: CanvasLayer
var rest_revision: int = 0
var shop_bought: Dictionary = {}
var reward_source: String = "kill"
var transition_left: float = 0.0
var _next_wave: int = 1
var _rest_kind: String = ""
@export var spawn_duration: float = 30.0
@export var spawn_warning: float = 0.8
@export var spawn_interval: float = 5.5
@export var enemy_limit: int = 24
@export var wave_enemy_limits: PackedInt32Array = PackedInt32Array([6, 8, 10, 12, 14])
@export var wave_spawn_intervals: PackedFloat32Array = PackedFloat32Array([5.5, 5.2, 4.9, 4.6, 4.3])
@export var wave_heavy_fractions: PackedFloat32Array = PackedFloat32Array([0.0, 0.15, 0.20, 0.25, 0.30])
@export var wave_turret_fractions: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.10, 0.15, 0.20])
var _wave_queued: int = 0
var _wave_heavies: int = 0
var _wave_turrets: int = 0
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
	rest_panel = load("res://scenes/roguelite/rest_panel.tscn").instantiate()
	arena.add_child(rest_panel)
	rest_panel.action_selected.connect(_rest_action)

func clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func restart() -> void:
	run_event.emit("reset")
	rest_revision += 1
	wallet.reset_wallet()
	shop_bought.clear()
	reward_source = "kill"
	transition_left = 0.0
	rest_panel.hide()
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
	_wave_queued = 0
	_wave_heavies = 0
	_wave_turrets = 0
	wave_elapsed = 0.0
	spawn_left = wave_interval()
	state = State.BATTLE
	launcher.set_blocked(false)
	if number <= 5:
		queue_batch()
	else:
		spawn_boss()

func _process(delta: float) -> void:
	advance_transition(delta)
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
			var warning: Dictionary = pending[index]
			pending.remove_at(index)
			# 先释放该预警占用的名额，再转换成实体或重新预警，避免重复预算。
			materialize_warning(warning)
	if wave <= 5:
		if wave_elapsed < spawn_duration:
			spawn_left -= delta
			if spawn_left <= 0.0:
				queue_batch()
				spawn_left = wave_interval()
		elif alive_count() == 0 and pending.is_empty():
			var rest: String = flow.rest_after(wave) if enable_stage_breaks else ""
			if not rest.is_empty():
				enter_rest(rest)
			else:
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

func wave_budget() -> int:
	if wave >= 6:
		return mini(maxi(1, enemy_limit), 7)
	var index: int = clampi(wave - 1, 0, maxi(0, wave_enemy_limits.size() - 1))
	var limit: int = wave_enemy_limits[index] if not wave_enemy_limits.is_empty() else 6
	return mini(maxi(1, enemy_limit), maxi(1, limit))

func wave_interval() -> float:
	if wave_spawn_intervals.is_empty():
		return maxf(0.5, spawn_interval)
	var index: int = clampi(wave - 1, 0, wave_spawn_intervals.size() - 1)
	# 保留原总间隔旋钮：5.5为基准，逐波数组决定缓慢递增的压力。
	return maxf(0.5, float(wave_spawn_intervals[index]) * maxf(0.5, spawn_interval) / 5.5)

func fraction_for(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	return clampf(float(values[clampi(wave - 1, 0, values.size() - 1)]), 0.0, 1.0)

func next_enemy_kind() -> int:
	_wave_queued += 1
	# 用累计出场配额替代概率，避免只有几只怪时随机连续刷出重型敌人。
	var heavy_due: bool = _wave_heavies < floori(_wave_queued * fraction_for(wave_heavy_fractions) + 0.00001)
	var turret_due: bool = _wave_turrets < floori(_wave_queued * fraction_for(wave_turret_fractions) + 0.00001)
	if heavy_due and (not turret_due or rng.randf() < 0.5):
		_wave_heavies += 1
		return 1
	if turret_due:
		_wave_turrets += 1
		return 2
	return 0

func queue_batch() -> void:
	var amount: int = 2
	for index in amount:
		if alive_count() + pending.size() >= wave_budget():
			break
		var kind: int = next_enemy_kind()
		var point: Vector2 = safe_entrance(rng.randi_range(0, 3)) + Vector2(index * 34, 0)
		var hp_override: int = 6 if split_enabled and wave in [4, 5] and kind == 1 and _wave_heavies % 2 == 0 else 0
		pending.append({"point": point, "kind": kind, "left": spawn_warning, "hp_override": hp_override, "family_reward": true, "generation": 0})

func spawn_enemy(kind: int, point: Vector2, hp_override: int = 0, family_reward: bool = true, split_generation: int = 0, from_split: bool = false) -> void:
	if alive_count() + pending.size() >= wave_budget():
		return
	# 预警后再次核对距离；玩家已到入口时，改到安全入口并重新预警。
	if not from_split and point.distance_to(player.position) < 200.0:
		pending.append({"point": safe_entrance(0), "kind": kind, "left": spawn_warning, "hp_override": hp_override, "family_reward": family_reward, "generation": split_generation})
		return
	var enemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.kind = kind
	enemy.hit_points_override = hp_override
	enemy.player = player
	enemy.health = health
	enemy.hazards = hazards
	enemy.position = point
	enemies.add_child(enemy)
	apply_enemy_build(enemy)
	enemy.contact_report.connect(combat.resolve)
	var revision: int = _run_revision
	var initial_hp: int = enemy.hp
	enemy.died.connect(func(defeated):
		if revision == _run_revision and defeated.is_inside_tree() and not defeated.get_meta("family_death_processed", false) and state not in [State.VICTORY, State.DEFEAT]:
			defeated.set_meta("family_death_processed", true)
			if family_reward:
				register_kill(defeated.get_instance_id())
			queue_split(defeated.position, initial_hp, split_generation)
	)

func set_split_enabled(value: bool) -> void:
	split_enabled = value

func materialize_warning(warning: Dictionary) -> void:
	if warning.get("split", false) and not split_point_safe(warning.point):
		warning.waited = float(warning.get("waited", 0.0)) + maxf(0.8, spawn_warning)
		if warning.waited >= 4.8:
			# 玩家持续追着预警或局部无空间时取消这一只，不能永远卡清波。
			return
		if warning.waited >= 2.4:
			var replacement: Vector2 = find_split_point(warning.origin)
			if not replacement.is_finite():
				return
			warning.point = replacement
		warning.left = maxf(0.8, spawn_warning)
		pending.append(warning)
		return
	spawn_enemy(warning.kind, warning.point, int(warning.get("hp_override", 0)), bool(warning.get("family_reward", true)), int(warning.get("generation", 0)), bool(warning.get("split", false)))

func split_point_safe(point: Vector2) -> bool:
	if point.x < 70.0 or point.x > 1210.0 or point.y < 155.0 or point.y > 648.0 or point.distance_to(player.position) < 80.0:
		return false
	for warning in pending:
		if warning.get("split", false) and point.distance_to(warning.point) < 46.0:
			return false
	var shape := CircleShape2D.new()
	shape.radius = 23.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 25
	var exclusions: Array[RID] = []
	for enemy in enemies.get_children():
		if enemy.dead:
			exclusions.append(enemy.get_rid())
	query.exclude = exclusions
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func find_split_point(origin: Vector2) -> Vector2:
	for radius: float in [48.0, 88.0, 128.0, 168.0]:
		for index in 12:
			var point: Vector2 = origin + Vector2.from_angle(TAU * index / 12.0) * radius
			if split_point_safe(point):
				return point
	return Vector2.INF

func queue_split(origin: Vector2, initial_hp: int, generation: int) -> void:
	if not split_enabled or initial_hp <= 1 or generation >= 2:
		return
	var child_hp: int = 3 if initial_hp >= 4 else (1 if initial_hp == 3 else 0)
	if child_hp == 0:
		return
	for index in 2:
		if alive_count() + pending.size() >= wave_budget():
			break
		var point: Vector2 = origin + Vector2(-32.0 if index == 0 else 32.0, 0)
		# 初始贴脸仍展示原位置预警，后续有限延迟后再找附近安全点。
		pending.append({"point": point, "kind": 0, "left": maxf(0.8, spawn_warning), "hp_override": child_hp, "family_reward": false, "generation": generation + 1, "split": true, "origin": origin, "waited": 0.0})

func register_kill(instance_id: int) -> void:
	if state in [State.VICTORY, State.DEFEAT]:
		return
	if rewards.add_kill(instance_id):
		kills = rewards.kills
		if not is_instance_valid(boss) or instance_id != boss.get_instance_id():
			wallet.credit_kill(instance_id)
		run_event.emit("kill")

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
	if reward_source == "kill" and not rewards.consume_reward():
		return
	if reward_source == "kill":
		chosen_rewards += 1
	run_event.emit("upgrade")
	if id == "heal":
		health.hp = mini(health.max_hp, health.hp + 2)
	apply_build()
	hud.close()
	current_choices.clear()
	if reward_source == "event":
		reward_source = "kill"
		state = State.EVENT
		continue_stage(rest_revision)
		return
	if reward_source == "shop":
		reward_source = "kill"
		state = State.SHOP
		refresh_rest()
		return
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
	rest_revision += 1
	rest_panel.hide()
	reward_source = "kill"
	run_event.emit("victory" if won else "defeat")
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
	if value:
		run_event.emit("pause")
	arena.paused = value
	arena.menu.visible = value
	launcher.set_blocked(value)
	get_tree().paused = value

func debug_wave(number: int) -> void:
	_run_revision += 1
	rest_revision += 1
	rest_panel.hide()
	reward_source = "kill"
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

func enter_rest(kind: String) -> void:
	# 只允许已清场的战斗进入休息；领奖与胜负拥有更高优先级。
	if state != State.BATTLE or health.hp <= 0 or rewards.pending > 0 or alive_count() > 0 or not pending.is_empty():
		return
	state = State.SHOP if kind == "shop" else State.EVENT
	_rest_kind = kind
	_next_wave = wave + 1
	rest_revision += 1
	shop_bought.clear()
	launcher.set_blocked(true)
	clear_container(hazards)
	rice.reset_rice()
	# 清除跨阶段攻击资格，但不清累计最长链、升级、冷却或玩家动量。
	combat.pending_echoes.clear()
	combat.echo_history.clear()
	combat._echo_revision += 1
	combat.pairs.clear()
	for body in companions.members:
		body.end_attack()
	player.chain_id = 0
	assists.reset_effects()
	_pulse_left = 0.0
	get_tree().paused = true
	run_event.emit("stage")
	refresh_rest()

func refresh_rest() -> void:
	var offers: Array[Dictionary] = []
	if state == State.SHOP:
		offers = [
			{"id": "heal", "text": "恢复2点生命 · %d币%s" % [heal_price, "（满血）" if health.hp >= health.max_hp else ("（已购）" if shop_bought.has("heal") else ("（余额不足）" if wallet.balance < heal_price else ""))], "enabled": health.hp < health.max_hp and wallet.balance >= heal_price and not shop_bought.has("heal")},
			{"id": "upgrade", "text": "选一次成长奖励 · %d币%s" % [upgrade_price, "（已购）" if shop_bought.has("upgrade") else ("（余额不足）" if wallet.balance < upgrade_price else "")], "enabled": wallet.balance >= upgrade_price and not shop_bought.has("upgrade")},
			{"id": "continue", "text": "继续下一阶段", "enabled": true}]
	elif state == State.EVENT:
		offers = [{"id": "heal", "text": "补给：恢复2点生命" + ("（满血）" if health.hp >= health.max_hp else ""), "enabled": health.hp < health.max_hp}, {"id": "upgrade", "text": "补给：免费选一次成长奖励", "enabled": true}, {"id": "skip", "text": "跳过并继续", "enabled": true}]
	else:
		return
	var guidance: String = "每项限购一次，可直接继续。" if state == State.SHOP else "选择一项补给，或跳过继续。"
	rest_panel.show_rest("阶段商店" if state == State.SHOP else "路边补给摊", "当前 %d币 · 生命%d/%d\n休息中，战斗与冷却暂停。%s" % [wallet.balance, health.hp, health.max_hp, guidance], offers, rest_revision)

func _rest_action(action: String, revision: int) -> void:
	if state == State.SHOP:
		if action == "continue":
			continue_stage(revision)
		else:
			buy_shop(action, revision)
	elif state == State.EVENT:
		resolve_event(action, revision)

func buy_shop(id: String, revision: int) -> bool:
	if state != State.SHOP or revision != rest_revision or shop_bought.has(id) or health.hp <= 0:
		return false
	var price: int
	if id == "heal":
		if health.hp >= health.max_hp:
			return false
		price = maxi(0, heal_price)
	elif id == "upgrade":
		price = maxi(0, upgrade_price)
	else:
		return false
	if not wallet.spend(price):
		return false
	shop_bought[id] = true
	if id == "heal":
		health.hp = mini(health.max_hp, health.hp + 2)
		health.changed.emit(health.hp)
		run_event.emit("upgrade")
		refresh_rest()
	else:
		reward_source = "shop"
		state = State.UPGRADE
		current_choices = build.candidates(rng, false, health.hp, health.max_hp)
		_choice_revision += 1
		rest_panel.hide()
		hud.show_choices(current_choices, build.levels, 1, _choice_revision)
		hud.title.text = "商店成长 · 选择一项"
		hud.summary.text = "已支付 · 不消耗击杀奖励 · 选完返回商店"
	return true

func resolve_event(id: String, revision: int) -> void:
	if state != State.EVENT or revision != rest_revision or health.hp <= 0:
		return
	if id == "heal":
		if health.hp >= health.max_hp:
			return
		health.hp = mini(health.max_hp, health.hp + 2)
		health.changed.emit(health.hp)
	elif id == "upgrade":
		reward_source = "event"
		state = State.UPGRADE
		current_choices = build.candidates(rng, false, health.hp, health.max_hp)
		_choice_revision += 1
		rest_panel.hide()
		hud.show_choices(current_choices, build.levels, 1, _choice_revision)
		hud.title.text = "补给成长 · 选择一项"
		hud.summary.text = "免费补给 · 不消耗击杀奖励 · 选完进入下一阶段"
		return
	elif id != "skip":
		return
	run_event.emit("upgrade")
	continue_stage(revision)

func continue_stage(revision: int) -> void:
	if state not in [State.SHOP, State.EVENT] or revision != rest_revision:
		return
	state = State.TRANSITION
	rest_revision += 1
	transition_left = maxf(0.0, transition_duration)
	rest_panel.show_rest("准备进入下一阶段", "准备 %.0f 秒 · 松开鼠标，等待安全进场预警" % ceilf(transition_left), [], rest_revision)

func advance_transition(delta: float) -> void:
	if state != State.TRANSITION:
		return
	transition_left = maxf(0.0, transition_left - delta)
	if transition_left > 0.0:
		rest_panel.detail.text = "准备 %.0f 秒 · 松开鼠标，等待安全进场预警" % ceilf(transition_left)
		return
	rest_revision += 1
	rest_panel.hide()
	get_tree().paused = false
	launcher.cancel()
	start_wave(_next_wave)

func _draw() -> void:
	if _pulse_left > 0.0:
		draw_arc(to_local(_pulse_point), _pulse_radius * (1.0 - _pulse_left / 0.3), 0, TAU, 48, Color(0.4, 0.9, 1.0, _pulse_left / 0.3), 3, true)
	for warning: Dictionary in pending:
		draw_arc(warning.point, 26, 0, TAU, 24, Color("ffb35c"), 3, true)
		draw_line(warning.point - Vector2(10, 0), warning.point + Vector2(10, 0), Color("ffb35c"), 2)
