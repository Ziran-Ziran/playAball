extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Run test timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame

func run() -> void:
	check(ResourceLoader.exists("res://scenes/roguelite/run.tscn"), "Independent full-run entry exists")
	if failures:
		quit(1)
		return
	var arena = load("res://scenes/roguelite/run.tscn").instantiate()
	# 此夹具依赖首批敌人数；正式默认随机后，显式保留旧基线以复现奖励门槛。
	arena.get_node("RunDirector").run_seed = 31030
	root.add_child(arena)
	current_scene = arena
	await frames(3)
	arena.feedback.sound_enabled = false
	var director = arena.director
	director.set_process(false)
	director.enable_stage_breaks = false
	check(director.wave == 1 and director.health.hp == 5, "Run starts at wave one with full health")
	check(director.companions.members.size() == 0 and not director.companions.follow_enabled, "Base run starts without companions")
	check(director.pending.size() > 0 and director.enemies.get_child_count() == 0, "Spawn warning precedes enemy creation")
	player_position_guard(director)
	director.advance(0.81)
	await frames(2)
	check(director.enemies.get_child_count() > 0, "Warning completes before real enemy spawn")
	director.wave_elapsed = director.spawn_duration + 1.0
	director.pending.clear()
	director.advance(0.1)
	check(director.state == director.State.BATTLE, "Expired wave waits for remaining enemies")
	for enemy in director.enemies.get_children():
		enemy.hurt(999)
	await frames(2)
	director.advance(0.1)
	check(director.wave == 2 and director.state == director.State.BATTLE and not paused, "Clear wave advances without giving an extra reward")
	for id in range(1000, 1003):
		director.register_kill(id)
	director.advance(0.01)
	check(director.state == director.State.UPGRADE and paused and arena.launcher.blocked, "Kill threshold opens upgrade and blocks battle input")
	check(arena.get_node("RunHUD").cards.get_child_count() == 3, "Upgrade presents three cards")
	director.set_paused(false)
	check(paused and director.state == director.State.UPGRADE, "Escape cannot bypass upgrade selection")
	var choices: Array = director.current_choices
	check(choices.any(func(choice): return choice.id == "companion"), "First upgrade guarantees new companion choice")
	director.choose_upgrade("companion")
	check(not paused and director.wave == 2 and director.companions.members.size() == 1, "Choosing upgrade resumes current wave and applies new companion")
	director.set_paused(true)
	var time_before: float = director.wave_elapsed
	director.advance(10.0)
	check(director.wave_elapsed == time_before and director.state == director.State.PAUSED, "Pause stops wave timer")
	director.set_paused(false)
	director.health.hurt(5)
	await frames(1)
	check(director.state == director.State.DEFEAT and arena.launcher.blocked, "Zero health ends run once and blocks launch")
	director.restart()
	check(director.health.hp == 5 and director.wave == 1 and director.build.levels.is_empty(), "Restart resets health, wave and build")
	check(director.companions.members.size() == 0 and director.enemies.get_child_count() == 0, "Restart removes old combatants and companions")
	# 跳到首领仅用于复现，不伪称真实玩家通关。
	director.debug_wave(6)
	check(director.boss != null, "Dedicated boss encounter remains available")
	director.boss.hurt(999)
	await frames(1)
	check(director.state == director.State.VICTORY and director.rewards.pending == 0, "Boss death produces victory without post-victory rewards")
	for attempt in 10:
		director.restart()
		await frames(2)
	check(director.enemies.get_child_count() == 0 and director.hazards.get_child_count() == 0 and director.companions.members.size() == 0, "Ten restarts leave no growing combatant or hazard population")
	for number in range(1, 6):
		director.wave_elapsed = director.spawn_duration + 1.0
		director.pending.clear()
		director.advance(0.1)
		check(director.state == director.State.BATTLE and director.wave == number + 1, "Wave %d transitions without a free reward" % number)
	check(director.wave == 6 and director.boss != null and director.chosen_rewards == 0, "Five clears reach boss independently of kill rewards")
	for preset in [PackedStringArray(["companion", "companion", "companion"]), PackedStringArray(["heavy", "bowling"]), PackedStringArray(["relay", "explosion", "follow"])]:
		director.restart()
		director.debug_build(preset)
		check(director.build.levels.size() > 0 and director.companions.members.size() == director.build.companion_count(), "Fixed build applies valid runtime configuration")
	director.debug_build(PackedStringArray(["cooldown", "cooldown"]))
	check(is_equal_approx(arena.launcher.cooldown, 1.7), "Cooldown upgrade reaches configured runtime value")
	director.restart()
	check(is_equal_approx(arena.launcher.cooldown, 2.2) and not director.companions.follow_enabled, "Restart clears cooldown and follow upgrades")
	await frames(3)
	var target: DemoTarget = load("res://scenes/roguelite/destructible.tscn").instantiate()
	target.position = Vector2(300, 300)
	arena.add_child(target)
	director.health.hp = 3
	director.rice.spawn_rice()
	check(is_instance_valid(director.rice.rice), "Formal run wires injured health to rice manager")
	director.rice._on_collected(director.rice.rice)
	check(director.health.hp == 4, "Formal run rice restores one HP")
	arena.player.chain_id = 42
	arena.combat.resolve(arena.player, target, 180.0, target.position)
	check(target.hp == 2, "Eating rice leaves collision damage unchanged")
	director.restart()
	check(director.rice.rice == null and director.rice.elapsed == 0, "Restart clears rice and timer")
	target.queue_free()
	# 完全占用场地时必须等待，而不是把新增伙伴塞进墙或主球。
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1280, 720)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	wall.position = Vector2(640, 360)
	arena.add_child(wall)
	await frames(2)
	director.companions.set_count(1)
	check(director.companions.members.is_empty(), "Blocked companion spawn waits without creating an overlapping body")
	wall.queue_free()
	await frames(24)
	check(director.companions.members.size() == 1, "Pending companion appears after a safe space becomes available")
	arena.queue_free()
	await process_frame
	check(not paused and Engine.time_scale == 1.0, "Leaving full run restores pause and time")
	if failures == 0:
		print("RUN CHECKS PASSED: ", checks)
	quit(0 if failures == 0 else 1)

func player_position_guard(director: Node) -> void:
	# 直接排入贴近玩家的请求也必须改到安全入口并重新预警。
	var count: int = director.enemies.get_child_count()
	director.spawn_enemy(0, director.player.position)
	check(director.enemies.get_child_count() == count, "Unsafe spawn never creates enemy on player")
