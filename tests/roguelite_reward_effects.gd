extends SceneTree
var checks: int = 0
var failures: int = 0

class RiceCounter extends Node:
	var calls: int = 0
	func consume_bonus(_chain: int) -> int:
		calls += 1
		return 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(30).timeout.connect(func(): push_error("Reward effects timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func target_at(arena: Node2D, point: Vector2) -> DemoTarget:
	var target: DemoTarget = load("res://scenes/roguelite/destructible.tscn").instantiate()
	target.hit_points = 100
	target.position = point
	arena.add_child(target)
	return target

func run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var combat := DemoCombat.new()
	arena.add_child(combat)
	combat.set_physics_process(false)
	combat.build = DemoBuild.new()
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = Vector2(100, 500)
	player.chain_id = 10
	arena.add_child(player)
	player.freeze = true
	var target := target_at(arena, Vector2(700, 500))
	for rank in [1, 2, 3, 99]:
		combat.reset_combat()
		combat.build.levels = {"heavy": rank}
		var before: int = target.hp
		combat.resolve(player, target, 300, target.position)
		check(target.hp == before - 1 - mini(rank, 3), "Heavy adds rank damage capped at three: " + str(rank))
	combat.reset_combat()
	var before: int = target.hp
	combat.resolve(player, target, 179, target.position)
	check(target.hp == before, "Ranked heavy never turns low-speed contact into damage")
	check(combat.has_method("_advance_echoes"), "Combat exposes delayed echo advancement")
	check(ResourceLoader.exists("res://scripts/roguelite/assist_effects.gd"), "Assist pulse effect resource exists")
	var probe = load("res://scripts/roguelite/enemy.gd").new()
	check(probe.has_method("apply_attack_scale"), "Enemies expose fixed-base attack scaling")
	probe.free()
	if failures > 0:
		arena.free()
		quit(1)
		return
	combat.build.levels = {"echo": 1}
	combat.reset_combat()
	var impacts: Array[Vector2] = []
	combat.hit.connect(func(point, _speed): impacts.append(point))
	before = target.hp
	combat.resolve(player, target, 300, target.position)
	check(target.hp == before - 1 and impacts.size() == 1, "Echo starts with exactly one direct hit")
	combat._physics_process(0.119)
	check(target.hp == before - 1, "Echo waits full 0.12 battle seconds")
	target.position += Vector2(60, 20)
	player.chain_id = 11
	combat._physics_process(0.002)
	check(target.hp == before - 2 and impacts.size() == 2 and impacts[-1] == target.position, "Echo adds actual second damage and feedback at current target position")
	check(combat.events[-1].chain == 10 and combat.events[-1].effect == "echo", "Echo records original launch chain after actor relaunches")
	combat._physics_process(0.2)
	player.chain_id = 10
	combat.resolve(player, target, 300, target.position)
	combat._physics_process(0.2)
	check(target.hp == before - 3, "Repeated source-target-chain cannot enqueue another echo")
	combat.reset_combat()
	combat.resolve(player, target, 300, target.position)
	before = target.hp
	combat.reset_combat()
	combat._physics_process(1.0)
	check(target.hp == before, "Reset discards queued echoes")
	combat.resolve(player, target, 300, target.position)
	before = target.hp
	arena.remove_child(target)
	combat._physics_process(0.2)
	check(target.hp == before, "Removed old-run target cannot receive echo")
	target.free()
	target = target_at(arena, Vector2(700, 500))
	combat.reset_combat()
	combat.resolve(player, target, 300, target.position)
	target.free()
	combat._physics_process(0.2)
	check(combat.events.size() == 1, "Freed target produces no delayed hit or record")
	target = target_at(arena, Vector2(700, 500))
	combat.reset_combat()
	combat.resolve(player, target, 300, target.position)
	target.dead = true
	before = target.hp
	combat._physics_process(0.2)
	check(target.hp == before, "Dead target cannot receive echo")
	target.dead = false
	combat.reset_combat()
	combat.resolve(player, target, 300, target.position)
	before = target.hp
	combat.set_physics_process(true)
	paused = true
	await frames(30)
	check(target.hp == before, "Pause does not advance echo queue")
	paused = false
	await frames(20)
	check(target.hp == before - 1, "Echo resumes after battle unpauses")
	combat.set_physics_process(false)
	await echo_isolation(arena, player, combat)
	await scaling_and_pulse(arena, player, combat.build)
	arena.queue_free()
	await frames(2)
	print("REWARD EFFECTS CHECKS PASSED: ", checks) if failures == 0 else print("REWARD EFFECTS CHECKS FAILED: ", failures)
	quit(0 if failures == 0 else 1)

func echo_isolation(arena: Node2D, player: DemoPlayer, combat: DemoCombat) -> void:
	combat.reset_combat()
	combat.build.levels = {"echo": 1, "bowling": 1, "explosion": 1, "heavy": 3}
	var member: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	member.position = Vector2(100, 100)
	member.mode = DemoCompanion.Mode.ACTIVE
	member.chain_id = 20
	arena.add_child(member)
	member.set_physics_process(false)
	member.freeze = true
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.position = Vector2(600, 100)
	arena.add_child(enemy)
	enemy.hp = 30
	enemy.freeze = true
	enemy.set_physics_process(false)
	var neighbor := target_at(arena, Vector2(650, 100))
	neighbor.add_to_group("demo_damageable")
	var counter := RiceCounter.new()
	arena.add_child(counter)
	combat.rice_bonus = counter
	combat.resolve(member, enemy, 300, enemy.position)
	var nearby_hp: int = neighbor.hp
	enemy.projectile_left = 0.05
	combat._physics_process(0.13)
	check(enemy.hp == 27, "Companion echo adds exactly one after direct hit and first explosion")
	check(neighbor.hp == nearby_hp and counter.calls == 1 and is_equal_approx(enemy.projectile_left, 0.05), "Echo cannot explode, consume rice, refresh bowling or add ranked heavy")
	combat._physics_process(1.0)
	check(enemy.hp == 27 and combat.pending_echoes.is_empty(), "Echo never recursively schedules another echo")
	combat.reset_combat()
	enemy.projectile_left = 0.6
	enemy.projectile_hits_left = 2
	enemy.chain_id = 21
	combat.resolve(enemy, neighbor, 300, neighbor.position)
	check(combat.pending_echoes.is_empty(), "Enemy bowling projectile cannot trigger echo")
	combat.reset_combat()
	for chain in 300:
		player.chain_id = chain + 1
		combat._schedule_echo(player, neighbor, 300)
	check(combat.pending_echoes.size() <= 256 and combat.echo_history.size() <= 256, "Echo queue and history stay bounded")
	combat.reset_combat()
	combat.rice_bonus = null
	member.queue_free()
	enemy.queue_free()
	neighbor.queue_free()
	counter.queue_free()
	await frames(2)

func scaling_and_pulse(arena: Node2D, player: DemoPlayer, build: DemoBuild) -> void:
	var enemies := Node2D.new()
	arena.add_child(enemies)
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.position = player.position + Vector2(100, 0)
	enemies.add_child(enemy)
	enemy.set_physics_process(false)
	var shape_size: float = enemy.get_node("Shape").shape.radius
	enemy.apply_attack_scale(0.85)
	enemy.apply_attack_scale(0.85)
	check(is_equal_approx(enemy.pulse_radius, 76.5), "Enemy shrink derives from base rather than multiplying repeatedly")
	enemy.apply_attack_scale(0.1)
	check(is_equal_approx(enemy.pulse_radius, 63.0), "Enemy pulse radius cannot shrink below 70 percent")
	enemy.apply_attack_scale(1.0)
	check(is_equal_approx(enemy.pulse_radius, 90.0) and enemy.get_node("Shape").shape.radius == shape_size, "Enemy scaling reset preserves physical shape")
	var boss: DemoBoss = load("res://scenes/roguelite/boss.tscn").instantiate()
	boss.position = Vector2(1100, 100)
	enemies.add_child(boss)
	boss.set_physics_process(false)
	boss.apply_attack_scale(0.7)
	boss.apply_attack_scale(0.7)
	check(is_equal_approx(boss.wave_max_radius, 231.0), "Boss shrink derives from fixed 330 base")
	boss.apply_attack_scale(1.0)
	check(is_equal_approx(boss.wave_max_radius, 330.0), "Boss radius restores independently of charge contact shapes")
	var health := DemoHealth.new()
	arena.add_child(health)
	enemy.health = health
	enemy.apply_attack_scale(0.7)
	enemy._release_attack(Vector2(80, 0))
	check(health.hp == 5, "Shrunk pulse no longer damages at former outer range")
	enemy.apply_attack_scale(1.0)
	enemy._release_attack(Vector2(80, 0))
	check(health.hp == 4, "Base pulse still damages the same outer-range position")
	health.reset_health()
	boss.player = player
	boss.health = health
	boss.wave_origin = player.global_position - Vector2(250, 0)
	boss.wave_radius = 250
	boss.wave_active = true
	boss.wave_warning_left = 0
	boss.apply_attack_scale(0.7)
	boss._tick_wave(0.01)
	check(health.hp == 5 and not boss.wave_active, "Shrunk boss wave expires before original outer damage ring")
	boss.apply_attack_scale(1.0)
	boss.wave_radius = 250
	boss.wave_active = true
	boss._tick_wave(0.01)
	check(health.hp == 4, "Base boss wave reaches original outer ring")
	var effects = load("res://scripts/roguelite/assist_effects.gd").new()
	effects.player = player
	effects.enemies = enemies
	effects.build = build
	arena.add_child(effects)
	effects.set_physics_process(false)
	build.levels = {"pulse": 1}
	var hp: int = enemy.hp
	effects._physics_process(3.99)
	await frames(2)
	check(enemy.linear_velocity.is_zero_approx(), "Protective pulse waits four battle seconds")
	effects._physics_process(0.02)
	await frames(2)
	check(enemy.linear_velocity.x > 1 and enemy.linear_velocity.length() <= 251.0, "Protective pulse physically pushes nearby enemy with bounded impulse")
	check(enemy.hp == hp and enemy.chain_id == 0 and not enemy.attacking(), "Pulse does not damage, transfer ownership or activate bowling")
	check(boss.linear_velocity.is_zero_approx(), "Pulse leaves distant boss untouched")
	effects.reset_effects()
	check(effects.elapsed == 0.0, "Reset clears pulse timer")
	paused = true
	effects.set_physics_process(true)
	await frames(30)
	check(effects.elapsed == 0.0, "Paused battle freezes protective pulse timer")
	paused = false
