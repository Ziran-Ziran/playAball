extends SceneTree
var failures: int = 0
var checks: int = 0
class LegacyEventDirector extends Node:
	var rest_revision: int = 7
	var selected: String = ""
	func resolve_event(id: String, revision: int) -> void:
		if revision == rest_revision: selected = id
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func run() -> void:
	for file in ["evaluation_fixture", "metrics_recorder", "input_policy", "balance_profile"]:
		check(ResourceLoader.exists("res://scripts/roguelite/evaluation/%s.gd" % file), "Evaluation module exists: " + file)
	for profile in ["transfer_075","transfer_090","transfer_095"]:
		check(ResourceLoader.exists("res://resources/roguelite/balance/%s.tres"%profile),"Real transfer candidate exists: "+profile)
	for profile in ["impact_0945","impact_1155"]:
		check(ResourceLoader.exists("res://resources/roguelite/balance/%s.tres"%profile),"Real launch impulse candidate exists: "+profile)
	if failures:
		quit(1)
		return
	var fixture = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
	root.add_child(fixture)
	fixture.configure("single", 42)
	for tick in 4:
		await physics_frame
	await process_frame
	fixture.begin_measurement()
	var policy = load("res://scripts/roguelite/evaluation/input_policy.gd").new()
	policy.strategy = "nearest"
	var before: float = fixture.enemies.get_child(0).hp
	for tick in 480:
		policy.update(fixture, tick / 120.0, 1.0 / 120.0)
		await physics_frame
	var metrics: Dictionary = fixture.metrics.summary()
	check(fixture.launcher.shots > 0 and metrics.effective_damage > 0 and metrics.damage_events > 0, "Formal policy launch produces real collisions and measured HP loss")
	check(metrics.effective_damage <= before and metrics.nominal_damage >= metrics.effective_damage, "Effective damage excludes overkill and is bounded by real starting HP")
	check(fixture.player.max_impulse == 1050.0 and fixture.launcher.cooldown == 2.2 and Engine.time_scale == 1.0, "Baseline fixture leaves formal physics defaults and time scale intact")
	fixture.launcher.set_blocked(true)
	var shots: int = fixture.launcher.shots
	check(not fixture.launcher.launch_with_drag(Vector2(160, 0)) and fixture.launcher.shots == shots, "Evaluation cannot bypass formal blocked launch validation")
	for profile_id in ["cooldown_200", "cooldown_180"]:
		var profile: Resource = load("res://resources/roguelite/balance/%s.tres" % profile_id)
		fixture.build.reset_build()
		profile.apply(fixture)
		var previous: float = fixture.launcher.cooldown
		for rank in 4:
			fixture.build.choose("cooldown")
			profile.apply(fixture)
			check(is_equal_approx(previous - fixture.launcher.cooldown, 0.25), "Each of four cooldown ranks gives real benefit for candidate " + profile_id)
			previous = fixture.launcher.cooldown
	fixture.queue_free()
	await process_frame
	for id in ["impact_0945","impact_1155"]:
		var impulse_fixture = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
		root.add_child(impulse_fixture)
		impulse_fixture.configure("single",42)
		var profile: Resource = load("res://resources/roguelite/balance/%s.tres"%id)
		profile.apply(impulse_fixture)
		impulse_fixture.player.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
		impulse_fixture.player.linear_damp = 0.0
		for tick in 4: await physics_frame
		check(impulse_fixture.launcher.launch_with_drag(Vector2(160,0)),"Candidate uses formal legal launch: "+id)
		for tick in 2: await physics_frame
		check(absf(impulse_fixture.player.linear_velocity.x*impulse_fixture.player.mass-profile.impulse)<1.0,"Candidate applied actual launch momentum: "+id)
		check(impulse_fixture.combat.transfer_retention==0.85 and impulse_fixture.launcher.cooldown==2.2 and impulse_fixture.player.cancel_opposing_momentum==0,"Impulse candidate keeps other factors unchanged: "+id)
		impulse_fixture.queue_free()
		await process_frame
	for profile_id in ["baseline","transfer_075","transfer_090","transfer_095"]:
		var transfer_fixture = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
		root.add_child(transfer_fixture)
		transfer_fixture.configure("relay",42,PackedStringArray(["companion","companion"]))
		var profile: Resource = load("res://resources/roguelite/balance/%s.tres"%profile_id)
		profile.apply(transfer_fixture)
		var receiver: DemoCompanion = transfer_fixture.companions.members[0]
		for body in [transfer_fixture.player,receiver]:
			body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
			body.linear_damp = 0.0
		for tick in 4: await physics_frame
		transfer_fixture.begin_measurement()
		transfer_fixture.player.request_debug_state("linear_velocity",Vector2(500,0))
		for tick in 2: await physics_frame
		transfer_fixture.player.chain_id = 7
		check(transfer_fixture.combat.activate(transfer_fixture.player,receiver),"Real transfer activated for "+profile_id)
		for tick in 2: await physics_frame
		check(absf(receiver.linear_velocity.x-500.0*profile.transfer_retention)<1.0,"Candidate applies actual physical receiving impulse: "+profile_id)
		check(transfer_fixture.combat.max_generation==3 and transfer_fixture.launcher.cooldown==2.2 and transfer_fixture.player.max_impulse==1050,"Transfer candidate preserves unrelated rules: "+profile_id)
		var victim: DemoEnemy = transfer_fixture.enemies.get_child(0)
		transfer_fixture.combat.resolve(receiver,victim,900,victim.position)
		var attribution: Dictionary = transfer_fixture.metrics.summary()
		check(attribution.partner_direct_damage==1 and attribution.nominal_damage==3 and attribution.activations==1,"Partner attribution counts true HP loss, excludes overkill: "+profile_id)
		transfer_fixture.queue_free()
		await process_frame
	var fidelity = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
	root.add_child(fidelity)
	fidelity.configure("reverse",42,PackedStringArray(["companion","follow","shrink","pulse"]))
	check(fidelity.companions.members[0].follow_enabled and fidelity.companions.members[0].arena_bounds==fidelity.bounds,"Fixture applies real follow upgrade and extended bounds")
	check(is_equal_approx(fidelity.enemies.get_child(0).pulse_radius,76.5),"Fixture applies real enemy attack-range upgrade")
	check(fidelity.get_children().any(func(node):return node is DemoAssistEffects),"Fixture includes formal pulse component")
	fidelity.queue_free()
	await process_frame
	var a = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
	root.add_child(a)
	a.configure("crowd", 123456)
	var positions: Array[Vector2] = []
	for enemy in a.enemies.get_children():
		positions.append(enemy.position)
	a.queue_free()
	await process_frame
	var b = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
	root.add_child(b)
	b.configure("crowd", 123456)
	var repeated: Array[Vector2] = []
	for enemy in b.enemies.get_children():
		repeated.append(enemy.position)
	check(positions == repeated, "Same fixture and seed reconstruct identical initial enemy positions")
	b.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	# 首领不是DemoEnemy，没有warning_left/pulse_radius；完整局代理仍须能选合法方向。
	var boss_game=load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(boss_game)
	boss_game.director.set_process(false)
	boss_game.director.debug_wave(6)
	boss_game.director.pending.clear()
	var agent=load("res://scripts/roguelite/evaluation/full_run_agent.gd").new()
	boss_game.add_child(agent)
	agent.bind(boss_game,load("res://resources/roguelite/balance/baseline.tres"),"mobility")
	await physics_frame
	await process_frame
	var boss_intent: Vector2=agent.policy.direction(agent,0.0)
	check(boss_intent.is_finite() and not boss_intent.is_zero_approx(),"Safe evaluation strategy supports a real boss without ordinary-enemy-only fields")
	boss_game.queue_free()
	await process_frame
	paused=false
	await create_timer(0.2).timeout
	await full_agent_v4_cases()
	print("BALANCE METRIC CHECKS PASSED: ", checks) if failures == 0 else print("BALANCE METRIC FAILURES: ", failures)
	quit(0 if failures == 0 else 1)

func full_agent_v4_cases() -> void:
	var game = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var director = game.director
	director.set_process(false)
	director.clear_container(director.enemies)
	director.pending.clear()
	director.wave = 4
	director.enter_rest("event")
	# 资金仅由事务测试夹具准备；代理本身只能调用正式购买，不注入钱或生命。
	director.wallet.balance = 30
	director.health.hp = 2
	var agent = load("res://scripts/roguelite/evaluation/full_run_agent.gd").new()
	game.add_child(agent)
	agent.bind(game, load("res://resources/roguelite/balance/baseline.tres"), "partners")
	agent.set_process(false)
	agent.drive_event_supply()
	check(director.reward_source == "event_paid" and director.wallet.balance == 18, "V4 event agent buys affordable growth before low-health heal")
	check(agent.paid_actions.size() == 1 and agent.paid_actions[0].spent == 12, "V4 records only successful real paid transactions")
	director.choose_upgrade(director.current_choices[0].id, director._choice_revision)
	agent.drive_event_supply()
	check(director.health.hp >= 4 and director.wallet.balance == 12 and agent.paid_actions.size() == 2, "V4 return purchases one low-health heal with real balance")
	check(director.reward_source == "event", "V4 proceeds to original free supply after paid stock is consumed")
	director.choose_upgrade(director.current_choices[0].id, director._choice_revision)
	check(director.state == director.State.TRANSITION, "V4 event strategy exits rather than cycling paid menu")
	paused = false
	director.debug_wave(1)
	director.pending.clear()
	await physics_frame
	await physics_frame
	var victim: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	victim.position = Vector2(800, 400)
	director.enemies.add_child(victim)
	victim.hp = 10
	victim.freeze = true
	victim.set_physics_process(false)
	agent._watch_enemy(victim.get_instance_id())
	director.player.chain_id = 55
	director.build.levels = {"echo": 1}
	director.combat.resolve(director.player, victim, 900, victim.position)
	director.combat._advance_echoes(0.13)
	agent.collect_source_damage()
	var attribution: Dictionary = agent.source_damage_snapshot()
	check(attribution.get("player_direct", 0) == 3 and attribution.get("echo", 0) == 1, "V4 source attribution separates direct and extra real HP loss")
	check(attribution.unattributed == 0 and agent.effective_damage == 4, "V4 attributed contributions reconcile to observed actual HP")
	game.queue_free()
	await process_frame
	var legacy := LegacyEventDirector.new()
	var legacy_health := DemoHealth.new()
	root.add_child(legacy)
	root.add_child(legacy_health)
	var old_agent = load("res://scripts/roguelite/evaluation/full_run_agent.gd").new()
	old_agent.director = legacy
	old_agent.health = legacy_health
	old_agent.drive_event_supply()
	check(legacy.selected == "upgrade", "V4 gracefully supports old director without paid-supply method")
	old_agent.free()
	legacy.free()
	legacy_health.free()
