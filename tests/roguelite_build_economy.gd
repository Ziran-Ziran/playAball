extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(40).timeout.connect(func(): push_error("Build economy timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	var game = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var d = game.director
	d.set_process(false)
	d.pending.clear()
	d.clear_container(d.enemies)
	check(d.has_method("reroll_upgrade"), "Director offers transactional reroll")
	check(d.combat.has_signal("precision_chain_completed"), "Combat publishes precise direct-chain completion")
	if not d.has_method("reroll_upgrade") or not d.combat.has_signal("precision_chain_completed"):
		game.free()
		quit(1)
		return
	d.wallet.balance = 40
	d.rewards.pending = 1
	d.open_upgrade()
	var old: int = d._choice_revision
	check(not d.reroll_upgrade(old), "Entrance lock rejects reroll without payment")
	await create_timer(0.9).timeout
	for price in [6, 10, 14]:
		old = d._choice_revision
		var before: int = d.wallet.balance
		var original: Array = d.current_choices.map(func(card): return card.id)
		check(d.reroll_upgrade(old), "Legal reroll accepted at price " + str(price))
		check(d.wallet.balance == before - price and d.rewards.pending == 1 and d.reward_source == "kill", "Exact price paid without consuming pending reward/source")
		check(d._choice_revision != old and not d.reroll_upgrade(old), "Old and repeated quote cannot double-pay")
		var renewed: Array = d.current_choices.map(func(card): return card.id)
		check(renewed.any(func(id): return not original.has(id)), "At least one distinct legal new candidate")
		check(renewed.has("companion"), "First-kill companion guarantee survives reroll")
		for card in d.current_choices:
			check(d.build.eligible_upgrades(d.health.hp, d.health.max_hp).has(card), "Rerolled card is currently eligible")
		check(not d.reroll_upgrade(d._choice_revision), "New offer entrance rejects immediate second click")
		await create_timer(0.9).timeout
	check(d.wallet.balance == 10 and not d.reroll_upgrade(d._choice_revision), "Three rerolls capped even with remaining budget")
	d.choose_upgrade(d.current_choices[0].id, d._choice_revision)
	await source_cases(d)
	d.restart()
	d.set_process(false)
	d.pending.clear()
	d.clear_container(d.enemies)
	d.wallet.balance = 5
	d.rewards.pending = 1
	d.open_upgrade()
	await create_timer(0.9).timeout
	check(not d.reroll_upgrade(d._choice_revision) and d.wallet.balance == 5, "Insufficient funds cannot reroll")
	d.health.hp = 0
	d.wallet.balance = 40
	check(not d.reroll_upgrade(d._choice_revision) and d.wallet.balance == 40, "Dead state rejects reroll without charging")
	d.health.hp = d.health.max_hp
	d.wallet.balance = 40
	for definition in d.build.definitions:
		if definition.max_level > 0: d.build.levels[definition.id] = definition.max_level
	d.health.hp = d.health.max_hp
	d.current_choices = [d.build.fallback]
	d._choice_revision += 1
	d.hud.show_choices(d.current_choices, d.build.levels, 1, d._choice_revision)
	await create_timer(0.9).timeout
	check(not d.reroll_upgrade(d._choice_revision) and d.wallet.balance == 40, "Exhausted legal pool never charges reroll")
	d.restart()
	d.set_process(false)
	d.pending.clear()
	d.clear_container(d.enemies)
	await physics_frame
	await physics_frame
	await chain_cases(game)
	await chain_isolation_cases(game)
	await secondary_damage_isolation_cases(game)
	await physical_precision_case(game)
	paused = false
	game.queue_free()
	await process_frame
	await refund_source_lifecycle_cases()
	print("BUILD ECONOMY CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)

func enemy(game: Node2D, point: Vector2, hp: int = 10) -> DemoEnemy:
	var foe: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	foe.position = point
	game.director.enemies.add_child(foe)
	foe.hp = hp
	foe.freeze = true
	foe.set_physics_process(false)
	return foe

func chain_cases(game: Node2D) -> void:
	var d = game.director
	var combat: DemoCombat = d.combat
	combat.set_physics_process(false)
	game.launcher.set_process(false)
	game.player.chain_id = 100
	game.launcher.charges = 0
	game.launcher.remaining = 2.0
	var foes: Array[DemoEnemy] = []
	for index in 4: foes.append(enemy(game, Vector2(400 + 100 * index, 450)))
	combat.resolve(game.player, foes[0], 300, foes[0].position)
	combat.elapsed += 1
	combat.resolve(game.player, foes[0], 300, foes[0].position)
	check(game.launcher.remaining == 2.0, "Repeated same enemy is not a different-target chain")
	combat.resolve(game.player, foes[1], 179, foes[1].position)
	combat.resolve(game.player, foes[1], 300, foes[1].position)
	check(game.launcher.remaining == 2.0, "Only two different actual direct hits cannot refund")
	combat.resolve(game.player, foes[2], 300, foes[2].position)
	check(game.launcher.remaining == 1.5, "Three distinct ordinary-enemy hits refund exactly 0.5 current cooldown")
	combat.resolve(game.player, foes[3], 300, foes[3].position)
	check(game.launcher.remaining == 1.5, "A chain can refund only once")
	combat.reset_combat()
	game.player.chain_id = 101
	game.launcher.remaining = 0.2
	for foe in foes.slice(0, 3): combat.resolve(game.player, foe, 300, foe.position)
	check(game.launcher.remaining == 0.0 and game.launcher.charges == 1, "Short remaining cooldown caps at one recharge without overflow")
	combat.reset_combat()
	game.player.chain_id = 102
	for foe in foes.slice(0, 3): combat.resolve(game.player, foe, 300, foe.position)
	check(game.launcher.remaining == 0.0 and game.launcher.charges == 1, "Full charge does not bank a future refund")
	combat.reset_combat()
	game.player.chain_id = 103
	game.launcher.set_capacity(2)
	game.launcher.charges = 0
	game.launcher.remaining = 0.1
	for foe in foes.slice(0, 3): combat.resolve(game.player, foe, 300, foe.position)
	check(game.launcher.charges == 1 and is_equal_approx(game.launcher.remaining, game.launcher.cooldown), "Double launch caps refund at current slot and discards excess 0.4 seconds")
	game.launcher.set_capacity(1)
	for foe in foes: foe.free()

func source_cases(d: Node) -> void:
	for source: String in ["shop", "event", "event_paid"]:
		d.restart()
		d.set_process(false)
		d.pending.clear()
		d.clear_container(d.enemies)
		d.wallet.balance = 60
		d.enter_rest("shop" if source == "shop" else "event")
		if source == "shop": d.buy_shop("upgrade", d.rest_revision)
		elif source == "event_paid": d.buy_event_supply("upgrade", d.rest_revision)
		else: d.resolve_event("upgrade", d.rest_revision)
		await create_timer(0.9).timeout
		var before: int = d.wallet.balance
		var stock: Dictionary = d.shop_bought.duplicate()
		var pending_count: int = d.rewards.pending
		var old_revision: int = d._choice_revision
		var old_id: String = d.current_choices[0].id
		check(d.reroll_upgrade(old_revision) and d.wallet.balance == before - 6, "All legal upgrade sources support exact paid reroll: " + source)
		check(d.reward_source == source and d.shop_bought == stock and d.rewards.pending == pending_count, "Reroll preserves purchase/free source, stock and kill reward queue")
		d.choose_upgrade(old_id, old_revision)
		check(d.state == d.State.UPGRADE and d.reward_source == source, "Old card cannot resolve refreshed paid/free reward")
		await create_timer(0.9).timeout
		d.choose_upgrade(d.current_choices[0].id, d._choice_revision)
		var expected: int = d.State.SHOP if source == "shop" else (d.State.EVENT if source == "event_paid" else d.State.TRANSITION)
		check(d.state == expected, "Refreshed card returns to original source destination")

func chain_isolation_cases(game: Node2D) -> void:
	var d = game.director
	var combat: DemoCombat = d.combat
	combat.reset_combat()
	game.launcher.remaining = 2.0
	game.launcher.charges = 0
	game.player.chain_id = 200
	var foes: Array[DemoEnemy] = []
	for index in 4: foes.append(enemy(game, Vector2(400 + index * 90, 450), 30))
	for foe in foes.slice(0, 2): combat.resolve(game.player, foe, 300, foe.position)
	game.player.chain_id = 201
	combat.resolve(game.player, foes[2], 300, foes[2].position)
	check(game.launcher.remaining == 2.0, "Different launches cannot pool three targets")
	combat.reset_combat()
	combat.build.levels = {"echo": 1}
	game.player.chain_id = 202
	combat.resolve(game.player, foes[0], 300, foes[0].position)
	combat._advance_echoes(0.2)
	check(game.launcher.remaining == 2.0, "Echo does not supply extra direct target counts")
	combat.reset_combat()
	var member: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	game.add_child(member)
	member.freeze = true
	member.set_physics_process(false)
	member.mode = DemoCompanion.Mode.ACTIVE
	member.chain_id = 202
	for foe in foes.slice(0, 3): combat.resolve(member, foe, 300, foe.position)
	check(game.launcher.remaining == 2.0, "Companion direct damage never earns player refund")
	member.free()
	var source_id: int = game.player.get_instance_id()
	var source_revision: int = game.player._reset_revision
	d._on_precision_chain_completed(source_id, 999, source_revision, combat._echo_revision)
	d._on_precision_chain_completed(source_id, game.player.chain_id, source_revision, combat._echo_revision - 1)
	check(game.launcher.remaining == 2.0, "Old source chain and combat epoch cannot redeem a refund")
	d.health.hp = 0
	d._on_precision_chain_completed(source_id, game.player.chain_id, source_revision, combat._echo_revision)
	check(game.launcher.remaining == 2.0, "Dead player cannot redeem precise-chain event")
	d.health.hp = 5
	combat.reset_combat()
	game.player.chain_id = 203
	for foe in foes.slice(0, 2): combat.resolve(game.player, foe, 300, foe.position)
	foes[2].hp = 1
	foes[2].died.connect(func(_dead: DemoEnemy): game.player.reset_body(Vector2(640, 400)))
	combat.resolve(game.player, foes[2], 300, foes[2].position)
	check(game.launcher.remaining == 2.0, "Synchronous source reset during third target cannot refund old shot")
	for foe in foes: foe.free()
	game.player.freeze = false
	await physics_frame
	await physics_frame
	combat.reset_combat()
	game.player.chain_id = 204
	game.launcher.remaining = 0.1
	game.launcher.charges = 0
	for index in 3: foes[index] = enemy(game, Vector2(400 + index * 90, 450), 30)
	game.launcher.recharged.connect(func(): d.restart(), CONNECT_ONE_SHOT)
	var success: Array[float] = []
	d.precision_rewarded.connect(func(_point: Vector2, seconds: float): success.append(seconds))
	for foe in foes.slice(0, 3): combat.resolve(game.player, foe, 300, foe.position)
	check(success.is_empty(), "Synchronous recharge-triggered restart prevents old success feedback")
	# restart已移除本局敌人，节点仍等待queue_free，不再访问旧数组。

func physical_precision_case(game: Node2D) -> void:
	var d = game.director
	d.restart()
	d.set_process(false)
	d.pending.clear()
	d.clear_container(d.enemies)
	game.player.reset_body(Vector2(420, 360))
	await physics_frame
	await physics_frame
	game.launcher.set_process(false)
	var successful: Array[float] = []
	d.precision_rewarded.connect(func(_point: Vector2, seconds: float): successful.append(seconds))
	for x in [510, 575, 640]:
		var foe: DemoEnemy = enemy(game, Vector2(x, 360), 1)
		foe.freeze = false
		foe.died.connect(func(dead: DemoEnemy): d.register_kill(dead.get_instance_id()))
	check(game.launcher.launch_with_drag(Vector2(160, 0)), "Precise-chain physical fixture uses formal impulse launch")
	for frame in 45: await physics_frame
	print("PHYSICAL PRECISION kills=", d.kills, " refunds=", successful, " remaining=", game.launcher.remaining, " player=", game.player.position, " events=", d.combat.events)
	check(d.kills == 3 and successful == [0.5], "Actual rigid-body path through three enemies earns exactly one refund")
	check(is_equal_approx(game.launcher.remaining, game.launcher.cooldown - 0.5), "Actual physical chain saves 0.5 seconds without timer manipulation")

func secondary_damage_isolation_cases(game: Node2D) -> void:
	var d = game.director
	for effect: String in ["bowling", "explosion", "projectile"]:
		d.restart()
		d.set_process(false)
		d.pending.clear()
		d.clear_container(d.enemies)
		game.player.reset_body(Vector2(300, 400))
		await physics_frame
		await physics_frame
		game.launcher.remaining = 2.0
		game.launcher.charges = 0
		game.launcher.set_process(false)
		game.player.chain_id = 300
		var foes: Array[DemoEnemy] = []
		for x in [400, 450, 480]: foes.append(enemy(game, Vector2(x, 400), 1))
		if effect == "bowling":
			d.build.levels = {"bowling": 1}
			d.combat.resolve(game.player, foes[0], 300, foes[0].position)
			check(foes[0].dead and foes[1].dead and foes[2].dead and game.launcher.remaining == 2.0, "Three kills including bowling aftershock do not count as three player direct targets")
		elif effect == "explosion":
			d.build.levels = {"explosion": 1}
			var member: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
			game.add_child(member)
			member.freeze = true
			member.set_physics_process(false)
			member.mode = DemoCompanion.Mode.ACTIVE
			member.chain_id = 300
			d.combat.resolve(member, foes[0], 300, foes[0].position)
			check(foes[0].dead and foes[1].dead and foes[2].dead and game.launcher.remaining == 2.0, "Three kills including explosion cannot earn player direct-chain refund")
			member.free()
		else:
			for foe in foes:
				var projectile: DemoEnemy = enemy(game, Vector2(300, 300), 10)
				projectile.make_projectile(300)
				d.combat.resolve(projectile, foe, 300, foe.position)
				projectile.free()
			check(foes.all(func(foe): return foe.dead) and game.launcher.remaining == 2.0, "Enemy projectile chains cannot masquerade as main-ball direct hits")
		for foe in foes: foe.free()

func refund_source_lifecycle_cases() -> void:
	for action: String in ["reset", "queue", "remove", "free"]:
		var game = load("res://scenes/roguelite/run.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		var d = game.director
		d.set_process(false)
		d.pending.clear()
		await physics_frame
		await physics_frame
		var source: DemoPlayer = game.player
		source.chain_id = 200
		game.launcher.remaining = 0.1
		game.launcher.charges = 0
		game.launcher.set_process(false)
		var success: Array[int] = []
		d.precision_refunded.connect(func(_chain: int, _seconds: float): success.append(1))
		d.precision_rewarded.connect(func(_point: Vector2, _seconds: float): success.append(2))
		var invalidate_source: Callable = func():
			match action:
				"reset": source.reset_body(Vector2.ZERO)
				"queue": source.queue_free()
				"remove": source.get_parent().remove_child(source)
				"free": source.free()
		game.launcher.recharged.connect(invalidate_source, CONNECT_ONE_SHOT)
		d._on_precision_chain_completed(source.get_instance_id(), 200, source._reset_revision, d.combat._echo_revision)
		check(success.is_empty(), "Refund completion cannot emit success after source " + action)
		game.free()
		if action == "remove" and is_instance_valid(source): source.free()
