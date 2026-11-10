extends SceneTree
## 发布前策略兑现回归：使用正式节点和伤害接口，不修改玩家物理规则。
var checks: int = 0
var failures: int = 0
var arena: Node2D
var combat: DemoCombat
var player: DemoPlayer
var member: DemoCompanion
class RejectingTarget extends DemoTarget:
	func hurt(_amount: int) -> void:
		pass

func _initialize() -> void:
	call_deferred("run")
	create_timer(40).timeout.connect(func(): push_error("Strategy payoff timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func enemy_at(point: Vector2, hp: int = 10) -> DemoEnemy:
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.position = point
	arena.add_child(enemy)
	enemy.hp = hp
	enemy.max_hp = hp
	enemy.freeze = true
	enemy.set_physics_process(false)
	return enemy

func run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	combat = DemoCombat.new()
	arena.add_child(combat)
	combat.set_physics_process(false)
	combat.build = DemoBuild.new()
	player = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	arena.add_child(player)
	player.freeze = true
	player.chain_id = 1
	member = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	arena.add_child(member)
	member.freeze = true
	member.set_physics_process(false)
	member.mode = DemoCompanion.Mode.ACTIVE
	member.chain_id = 2
	for generation in [1, 2, 3]:
		combat.reset_combat()
		combat.build.levels = {"relay": 1}
		member.generation = generation
		var enemy: DemoEnemy = enemy_at(Vector2(600, 400))
		combat.resolve(member, enemy, 300, enemy.position)
		check(enemy.hp == 10 - generation, "Relay actual direct damage for generation " + str(generation))
		check(combat.events.size() == 1 and combat.events[0].damage == generation, "Relay records direct amount")
		enemy.free()
	combat.reset_combat()
	combat.build.levels = {"relay": 1}
	member.generation = 3
	var enemy: DemoEnemy = enemy_at(Vector2(600, 400))
	combat.resolve(member, enemy, 179, enemy.position)
	check(enemy.hp == 10, "Relay cannot manufacture low-speed damage")
	combat.resolve(player, enemy, 300, enemy.position)
	check(enemy.hp == 9, "Relay does not buff player")
	enemy.free()
	combat.reset_combat()
	combat.build.levels = {"echo": 1, "explosion": 1}
	var rejecting := RejectingTarget.new()
	rejecting.position = Vector2(600, 400)
	arena.add_child(rejecting)
	combat.resolve(member, rejecting, 300, rejecting.position)
	check(rejecting.hp == 3 and combat.pending_echoes.is_empty() and combat.exploded_chains.is_empty(), "Rejected actual damage cannot grant extra effects")
	rejecting.free()
	for generation in [1, 2, 3]:
		combat.reset_combat()
		combat.build.levels = {"explosion": 1}
		member.generation = generation
		var radii: Array[float] = []
		var callback: Callable = func(_point: Vector2, radius: float): radii.append(radius)
		combat.explosion_triggered.connect(callback)
		enemy = enemy_at(Vector2(600, 400))
		var distant: DemoEnemy = enemy_at(Vector2(705, 400))
		combat.resolve(member, enemy, 300, enemy.position)
		check(radii == [80.0 + 16.0 * (generation - 1)], "Explosion actual generation radius")
		check(distant.hp == (9 if generation == 3 else 10), "Explosion range is gameplay range")
		combat.elapsed += 1.0
		combat.resolve(member, distant, 300, distant.position)
		check(radii.size() == 1, "Explosion remains once per chain")
		combat.explosion_triggered.disconnect(callback)
		enemy.free()
		distant.free()
	await bowling_cases()
	await isolation_cases()
	await actual_chain_case()
	await secondary_lifecycle_cases()
	arena.free()
	await rest_cases()
	print("STRATEGY PAYOFF CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)

func bowling_cases() -> void:
	combat.reset_combat()
	combat.build.levels = {"bowling": 1, "heavy": 3, "echo": 1}
	var surges: Array[int] = []
	if combat.has_signal("bowling_surged"):
		combat.connect("bowling_surged", func(_point: Vector2, count: int): surges.append(count))
	player.position = Vector2(300, 400)
	player.incoming_velocity = Vector2(700, 0)
	var victim: DemoEnemy = enemy_at(Vector2(400, 400), 1)
	var first: DemoEnemy = enemy_at(Vector2(450, 400), 1)
	var second: DemoEnemy = enemy_at(Vector2(475, 410), 10)
	var third: DemoEnemy = enemy_at(Vector2(490, 400), 10)
	var behind: DemoEnemy = enemy_at(Vector2(350, 400), 10)
	combat.resolve(player, victim, 700, victim.position)
	check(victim.dead, "Direct kill is real before aftershock")
	check(first.dead and second.hp == 9 and third.hp == 10, "Bowling kill hits at most two nearest targets for one")
	check(behind.hp == 10, "Bowling kill only continues forward")
	check(first.projectile_hits_left == 0 and second.projectile_hits_left == 0, "Kill aftershock cannot grant bowling projectiles")
	check(combat.pending_echoes.is_empty(), "Aftershock does not enqueue echoes")
	check(combat.events.filter(func(event): return event.get("effect", "") == "bowling_finish").size() == 2, "Aftershock has separate bounded damage attribution")
	check(surges == [2], "Bowling presentation receives only real affected count")
	for enemy in [victim, first, second, third, behind]: enemy.free()
	combat.reset_combat()
	victim = enemy_at(Vector2(400, 400), 1)
	first = enemy_at(Vector2(450, 400), 10)
	var wall := StaticBody2D.new()
	wall.collision_layer = 16
	wall.position = Vector2(425, 400)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10, 160)
	shape.shape = rectangle
	wall.add_child(shape)
	arena.add_child(wall)
	await physics_frame
	await physics_frame
	combat.resolve(player, victim, 700, victim.position)
	check(first.hp == 10, "Physical wall blocks bowling kill aftershock")
	check(surges == [2], "Blocked bowling emits no false surge")
	wall.free()
	victim.free()
	first.free()
	combat.reset_combat()
	victim = enemy_at(Vector2(400, 400), 10)
	combat.build.levels = {"bowling": 1}
	combat.resolve(player, victim, 300, victim.position)
	check(victim.projectile_hits_left == 2, "Survivors retain original bowling mechanic")
	victim.free()
	combat.reset_combat()
	victim = enemy_at(Vector2(400, 400), 1)
	first = enemy_at(Vector2(450, 400), 10)
	victim.died.connect(func(_dead: DemoEnemy): combat.reset_combat())
	combat.resolve(player, victim, 700, victim.position)
	check(first.hp == 10 and combat.events.is_empty(), "Synchronous death reset discards old-chain side effects")
	victim.free()
	first.free()

func rest_cases() -> void:
	var game = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var d = game.director
	d.set_process(false)
	d.clear_container(d.enemies)
	d.pending.clear()
	d.wave = 4
	d.enter_rest("event")
	var revision: int = d.rest_revision
	check(d.has_method("buy_event_supply"), "Paid later-stage supply entry exists")
	if d.has_method("buy_event_supply"):
		check(not d.buy_event_supply("upgrade", revision), "Paid supply rejects insufficient funds")
		d.wallet.balance = 18
		check(not d.buy_event_supply("heal", revision), "Paid supply rejects full HP")
		d.health.hp = 2
		check(d.buy_event_supply("heal", revision) and d.health.hp == 4 and d.wallet.balance == 12, "Paid heal charges six and restores two")
		check(not d.buy_event_supply("heal", revision), "Paid heal stock once per event")
		check(d.buy_event_supply("upgrade", revision) and d.wallet.balance == 0, "Paid growth charges twelve")
		d.choose_upgrade(d.current_choices[0].id, d._choice_revision)
		check(d.state == d.State.EVENT and paused, "Paid growth returns to event without consuming free supply")
		check(not d.buy_event_supply("upgrade", revision), "Paid growth stock once")
		d.wallet.balance = 100
		d.health.hp = 0
		check(not d.buy_event_supply("heal", revision), "Dead player cannot buy paid supplies")
		d.health.hp = 4
		check(not d.buy_event_supply("upgrade", revision - 1), "Old event revision cannot buy supplies")
		d.resolve_event("upgrade", revision)
		d.choose_upgrade(d.current_choices[0].id, d._choice_revision)
		check(d.state == d.State.TRANSITION, "Free growth remains available after paid purchase")
		check(not d.buy_event_supply("heal", revision), "Old event quote rejected on exit")
	d.run_seed = 123456
	d.restart()
	var first_random: int = d.rng.randi()
	d.restart()
	check(first_random == d.rng.randi(), "Explicit seed remains reproducible")
	check(d.has_method("active_seed_value"), "Active random or fixed seed is exposed read-only")
	if d.has_method("active_seed_value"):
		check(d.active_seed_value() == 123456, "Explicit seed snapshot matches seed used")
		d.run_seed = 0
		d.restart()
		var random_seed: int = d.active_seed_value()
		d.restart()
		check(random_seed != d.active_seed_value(), "Random mode selects a new seed on restart")
		var replay_seed: int = d.active_seed_value()
		var random_sequence: Array[int] = [d.rng.randi(), d.rng.randi(), d.rng.randi()]
		check(replay_seed > 0, "Random seed is a replayable positive signed integer")
		d.run_seed = replay_seed
		d.restart()
		check(random_sequence == [d.rng.randi(), d.rng.randi(), d.rng.randi()], "Random active seed can be copied into explicit seed to replay RNG")
	paused = false
	game.queue_free()
	await process_frame
	await physics_frame

func isolation_cases() -> void:
	combat.reset_combat()
	combat.build.levels = {"relay": 1, "bowling": 1}
	member.generation = 3
	member.mode = DemoCompanion.Mode.IDLE
	var victim: DemoEnemy = enemy_at(Vector2(500, 400), 10)
	combat.resolve(member, victim, 300, victim.position)
	check(victim.hp == 10, "Idle companion cannot receive relay damage")
	member.mode = DemoCompanion.Mode.ACTIVE
	combat.build.levels.clear()
	combat.resolve(member, victim, 300, victim.position)
	check(victim.hp == 9, "Deep generation without relay has no extra damage")
	victim.free()

	combat.reset_combat()
	combat.build.levels = {"relay": 1, "bowling": 1}
	var boss: DemoBoss = load("res://scenes/roguelite/boss.tscn").instantiate()
	boss.position = Vector2(500, 400)
	arena.add_child(boss)
	boss.freeze = true
	boss.set_physics_process(false)
	boss.phase = DemoBoss.Phase.EXPOSED
	var neighbor: DemoEnemy = enemy_at(Vector2(550, 400), 10)
	var before: int = boss.hp
	combat.resolve(member, boss, 300, boss.position)
	check(boss.hp == before - 3, "Relay can damage exposed boss core through ordinary direct rule")
	check(neighbor.hp == 10, "Boss core hit cannot emit ordinary-enemy bowling aftershock")
	combat.reset_combat()
	var module_point: Vector2 = boss.get_node("Module0").global_position
	before = boss.hp
	combat.resolve(member, boss, 300, module_point)
	check(boss.module_hp[0] == 0 and boss.hp == before, "Module damage remains separate from core damage")
	check(combat.events[0].effective_damage == 3, "Real module damage counted without duplicate core loss")
	boss.free()
	neighbor.free()

	combat.reset_combat()
	combat.build.levels = {"bowling": 1}
	victim = enemy_at(Vector2(400, 400), 1)
	neighbor = enemy_at(Vector2(450, 400), 10)
	victim.died.connect(func(_dead: DemoEnemy): player.reset_body(Vector2(300, 400)))
	combat.resolve(player, victim, 700, victim.position)
	check(neighbor.hp == 10 and combat.events.is_empty(), "Source reset alone invalidates old contact effects")
	victim.free()
	neighbor.free()
	await physics_frame
	await physics_frame
	combat.reset_combat()
	combat.build.levels = {"relay": 1}
	member.position = Vector2(300, 500)
	member.mode = DemoCompanion.Mode.ACTIVE
	member.generation = 2
	member.chain_id = 77
	member.freeze = false
	member.contact_report.connect(combat.resolve)
	victim = enemy_at(Vector2(390, 500), 10)
	member.apply_central_impulse(Vector2(700, 0) * member.mass)
	for frame in 30: await physics_frame
	check(victim.hp <= 8, "Actual rigid-body contact delivers second-generation relay payoff")
	member.contact_report.disconnect(combat.resolve)
	member.freeze = true
	victim.free()

func actual_chain_case() -> void:
	combat.reset_combat()
	combat.build.levels = {"relay": 1, "explosion": 1}
	player.freeze = false
	player.reset_body(Vector2(100, 300))
	await physics_frame
	await physics_frame
	check(player.launch(Vector2(160, 0), 91), "Chain fixture starts with real launch impulse")
	var team: Array[DemoCompanion] = []
	for index in 3:
		var ball: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
		ball.position = Vector2(240 + 140 * index, 300)
		arena.add_child(ball)
		ball.set_physics_process(false)
		team.append(ball)
	await physics_frame
	await physics_frame
	var source: DemoBody = player
	for index in 3:
		check(combat.activate(source, team[index]), "Real activate handoff accepted: " + str(index + 1))
		await physics_frame
		await physics_frame
		check(team[index].generation == index + 1 and team[index].chain_id == 91, "Real handoff assigns original chain and next generation")
		check(team[index].linear_velocity.length() > 180, "Handoff impulse produces actual attacking speed")
		source = team[index]
	var target: DemoEnemy = enemy_at(Vector2(610, 300), 20)
	var neighbor: DemoEnemy = enemy_at(Vector2(610, 405), 10)
	var radii: Array[float] = []
	var callback: Callable = func(_point: Vector2, radius: float): radii.append(radius)
	combat.explosion_triggered.connect(callback)
	team[2].contact_report.connect(combat.resolve)
	for frame in 25: await physics_frame
	var direct: Array[Dictionary] = combat.events.filter(func(event): return event.source == team[2].get_instance_id() and event.get("effect", "") == "" and int(event.get("damage", 0)) > 0)
	check(not direct.is_empty() and direct[0].generation == 3 and direct[0].damage >= 3, "Launched then three real handoffs deliver actual third-generation collision payoff")
	check(radii == [112.0] and neighbor.hp == 9, "Actual deep-chain first collision explodes at 112 range for real HP loss")
	combat.explosion_triggered.disconnect(callback)
	team[2].contact_report.disconnect(combat.resolve)
	player.freeze = true
	for ball in team: ball.free()
	target.free()
	neighbor.free()

func secondary_lifecycle_cases() -> void:
	for effect: String in ["bowling", "explosion"]:
		for action: String in ["reset", "queue"]:
			combat.reset_combat()
			combat.build.levels = {effect: 1}
			var actor: DemoBody
			if effect == "bowling":
				actor = load("res://scenes/roguelite/player_ball.tscn").instantiate()
			else:
				actor = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
				actor.mode = DemoCompanion.Mode.ACTIVE
			actor.position = Vector2(300, 400)
			arena.add_child(actor)
			actor.freeze = true
			actor.set_physics_process(false)
			actor.chain_id = 88
			var primary: DemoEnemy = enemy_at(Vector2(400, 400), 1 if effect == "bowling" else 20)
			var first: DemoEnemy = enemy_at(Vector2(440, 400), 1)
			var second: DemoEnemy = enemy_at(Vector2(460, 400), 10)
			first.died.connect(func(_dead: DemoEnemy):
				if action == "reset": actor.reset_body(Vector2.ZERO)
				else: actor.queue_free())
			var successful: Array[int] = []
			var surge: Callable = func(_point: Vector2, count: int): successful.append(count)
			combat.bowling_surged.connect(surge)
			combat.resolve(actor, primary, 300, primary.position)
			check(first.dead and second.hp == 10, effect + " stops secondary damage after source " + action)
			check(successful.is_empty(), "Invalidated source does not emit stale bowling success")
			combat.bowling_surged.disconnect(surge)
			for enemy in [primary, first, second]: enemy.free()
			actor.free()
