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
	root.add_child(arena)
	current_scene = arena
	await frames(3)
	arena.feedback.sound_enabled = false
	var director = arena.director
	director.set_process(false)
	director.enable_stage_breaks = false
	check(director.wave == 1 and director.health.hp == 5, "Run starts at wave one with full health")
	check(director.companions.members.size() == 1 and not director.companions.follow_enabled, "Base run starts with one non-following companion")
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
	check(not paused and director.wave == 2 and director.companions.members.size() == 2, "Choosing upgrade resumes current wave and applies new companion")
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
	check(director.companions.members.size() == 1 and director.enemies.get_child_count() == 0, "Restart removes old combatants and companions")
	# 跳到首领仅用于复现，不伪称真实玩家通关。
	director.debug_wave(6)
	check(director.boss != null, "Dedicated boss encounter remains available")
	director.boss.hurt(999)
	await frames(1)
	check(director.state == director.State.VICTORY and director.rewards.pending == 0, "Boss death produces victory without post-victory rewards")
	for attempt in 10:
		director.restart()
		await frames(2)
	check(director.enemies.get_child_count() == 0 and director.hazards.get_child_count() == 0 and director.companions.members.size() == 1, "Ten restarts leave no growing combatant or hazard population")
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
	director.rice.stored_bonus = true
	director.rice.bound_chain = 0
	arena.player.chain_id = 42
	arena.combat.resolve(arena.player, target, 180.0, target.position)
	check(target.hp == 2 and director.rice.stored_bonus, "Existing flying chain cannot consume newly eaten rice bonus")
	arena.launcher.fired.emit(43)
	arena.player.chain_id = 43
	arena.combat.elapsed += 0.2
	arena.combat.resolve(arena.player, target, 180.0, target.position)
	check(target.hp == 0 and not director.rice.stored_bonus, "Next active launch receives exactly one extra rice damage")
	director.restart()
	check(not director.rice.stored_bonus and director.rice.bound_chain == 0 and director.rice.rice == null, "Restart clears rice, bonus and bound launch")
	target.queue_free()
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
