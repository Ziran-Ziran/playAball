extends SceneTree
var failures: int = 0
var checks: int = 0

class ProjectileFixture extends DemoBody:
	var hp: int = 30
	var dead: bool = false
	var projectile_left: float = 0.0
	var projectile_hits_left: int = 0
	func hurt(amount: int) -> void:
		hp -= amount
	func make_projectile(chain: int) -> void:
		chain_id = chain
		projectile_left = 0.6
		projectile_hits_left = 2
	func attacking() -> bool:
		return projectile_left > 0.0 and projectile_hits_left > 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)
	else:
		print("PASS: ", message)

func run() -> void:
	check(ResourceLoader.exists("res://scripts/roguelite/run_build.gd"), "Run build resource exists")
	if failures > 0:
		quit(1)
		return
	var build = load("res://scripts/roguelite/run_build.gd").new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	check(build.companion_count() == 1 and is_equal_approx(build.launch_cooldown(), 2.2), "New run starts with one companion and base cooldown")
	for index in 3:
		check(build.choose("companion"), "Companion rank accepted")
	check(build.companion_count() == 4 and not build.choose("companion"), "Companion cap is four")
	for index in 4:
		check(build.choose("cooldown"), "Cooldown accepts four ranks")
	check(is_equal_approx(build.launch_cooldown(), 1.2) and not build.choose("cooldown"), "Cooldown cap is 1.2 seconds")
	for index in 3:
		check(build.choose("heavy"), "Heavy accepts three ranks")
	check(not build.choose("heavy"), "Heavy stops at rank three")
	for id in ["follow", "relay", "bowling", "explosion"]:
		check(build.choose(id) and not build.choose(id), "One-rank upgrade cap: " + id)
	check(build.choose("heal") and build.choose("heal") and not build.choose("unknown"), "Heal repeats and unknown IDs are rejected")
	build.reset_build()
	check(build.levels.is_empty() and build.companion_count() == 1, "Restart clears all build ranks")
	for index in 30:
		var cards = build.candidates(rng, true, 5, 5)
		var ids: Array[String] = []
		for card in cards:
			ids.append(card.id)
		check(cards.size() == 3 and ids.has("companion") and not ids.has("heal") and ids.size() == _unique(ids), "First wave unique cards guarantee companion without full-health heal")
	check(build.has_method("choice_count"), "Build exposes expanded reward APIs")
	if build.has_method("choice_count"):
		new_reward_rules(build, rng)
	build.reset_build()
	await combat_upgrades(build)
	print("BUILD CHECKS PASSED: ", checks) if failures == 0 else print("BUILD CHECKS FAILED: ", failures)
	quit(0 if failures == 0 else 1)

func _unique(ids: Array[String]) -> int:
	var found: Dictionary = {}
	for id in ids:
		found[id] = true
	return found.size()

func new_reward_rules(build, rng: RandomNumberGenerator) -> void:
	check(build.definitions.size() == 15, "Standard pool contains fifteen upgrades, excluding fallback")
	check(build.choice_count() == 3 and build.launch_capacity() == 1 and build.max_health() == 5, "Base choice, capacity and max health")
	check(is_equal_approx(build.launch_multiplier(), 1.0) and is_equal_approx(build.damping_multiplier(), 1.0) and is_equal_approx(build.friction_multiplier(), 1.0) and is_equal_approx(build.attack_radius_scale(), 1.0), "Base derived modifiers are neutral")
	var known_categories: Array[String] = ["机动", "火力", "伙伴", "生存", "节奏"]
	for upgrade in build.definitions:
		check(known_categories.has(upgrade.category) and upgrade.weight > 0.0, "Resource has category and weight: " + upgrade.id)
	for index in 60:
		var ids: Array[String] = card_ids(build.candidates(rng, false, 5, 5))
		check(not ids.has("relay") and not ids.has("heal") and not ids.has("vigor"), "Base eligibility excludes relay, full-health heal and fallback")
	build.choose("companion")
	var saw_relay: bool = false
	var saw_heal: bool = false
	for index in 100:
		var cards = build.candidates(rng, false, 2, 5)
		saw_relay = saw_relay or card_ids(cards).has("relay")
		saw_heal = saw_heal or card_ids(cards).has("heal")
		var categories: Dictionary = {}
		for card in cards:
			categories[card.category] = true
		check(cards.size() == 3 and categories.size() == 3, "Three cards favor distinct available categories")
	check(saw_relay and saw_heal, "Two companions unlock relay, injured player can draw heal")
	build.choose("choices")
	build.choose("double_launch")
	check(build.choice_count() == 4 and build.launch_capacity() == 2, "Choices and double launch change capacities")
	var four = build.candidates(rng, false, 5, 5)
	var four_categories: Dictionary = {}
	for card in four:
		four_categories[card.category] = true
	check(four.size() == 4 and card_ids(four).size() == _unique(card_ids(four)) and four_categories.size() == 4, "Four choices are unique and diverse")
	for id in ["launch_power", "glide"]:
		for index in 3:
			check(build.choose(id), "Three modifier ranks: " + id)
		check(not build.choose(id), "Modifier rank cap: " + id)
	build.choose("shrink")
	build.choose("shrink")
	check(not build.choose("shrink") and is_equal_approx(build.attack_radius_scale(), 0.7), "Shrink stops at two ranks with 70 percent radius")
	check(is_equal_approx(build.launch_multiplier(), 1.45) and is_equal_approx(build.damping_multiplier(), pow(0.75, 3)) and is_equal_approx(build.friction_multiplier(), pow(0.7, 3)), "Modifiers derive from fixed base without repeated application")
	for upgrade in build.definitions:
		if upgrade.max_level > 0:
			while build.choose(upgrade.id):
				pass
	var fallback = build.candidates(rng, false, 5, 5)
	check(fallback.size() == 1 and fallback[0].id == "vigor", "Exhausted standard pool returns single vigor")
	build.levels["heavy"] = 2
	var partial = build.candidates(rng, true, 5, 5)
	check(partial.size() == 1 and partial[0].id == "heavy", "Partial pool returns remaining valid card without duplicate or fallback padding")
	build.choose("heavy")
	check(build.choose("vigor") and build.choose("vigor") and build.max_health() == 7, "Vigor is repeatable and raises max health")
	var injured = build.candidates(rng, false, 4, 7)
	check(injured.size() == 1 and injured[0].id == "heal", "Remaining repeatable heal prevents fallback when injured")
	build.reset_build()
	check(build.max_health() == 5 and build.choice_count() == 3 and build.launch_capacity() == 1 and is_equal_approx(build.launch_multiplier(), 1.0), "Reset clears expanded modifiers and max health")
	# 同一随机序列比较火力已投点前后抽到火力卡的次数，避免用单抽断言权重。
	var base_fire: int = 0
	var focused_fire: int = 0
	for focused in [false, true]:
		build.reset_build()
		if focused:
			build.choose("heavy")
		rng.seed = 20261031
		for index in 1000:
			for card in build.candidates(rng, false, 5, 5):
				if card.category == "火力":
					if focused:
						focused_fire += 1
					else:
						base_fire += 1
	check(focused_fire > base_fire, "Existing build gently increases matching category draw rate")
	var repeated_rng := RandomNumberGenerator.new()
	rng.seed = 123456
	repeated_rng.seed = 123456
	check(card_ids(build.candidates(rng, false, 5, 5)) == card_ids(build.candidates(repeated_rng, false, 5, 5)), "Same build and RNG seed reproduce reward candidates")

func card_ids(cards) -> Array[String]:
	var ids: Array[String] = []
	for card in cards:
		ids.append(card.id)
	return ids

func combat_upgrades(build) -> void:
	var combat := DemoCombat.new()
	root.add_child(combat)
	check("build" in combat, "Combat accepts a build")
	if not "build" in combat:
		combat.queue_free()
		return
	combat.set("build", build)
	var player := DemoPlayer.new()
	root.add_child(player)
	player.chain_id = 10
	var target := ProjectileFixture.new()
	target.position = Vector2(100, 0)
	target.add_to_group("demo_damageable")
	root.add_child(target)
	build.choose("heavy")
	combat.resolve(player, target, 179.0, target.position)
	check(target.hp == 30, "Heavy does not turn low speed into damage")
	combat.resolve(player, target, 200.0, target.position)
	check(target.hp == 28, "Heavy adds one to valid player impact against dynamic enemy")
	combat.resolve(player, target, 200.0, target.position)
	check(target.hp == 28, "Same contact pair does not settle twice")
	combat.reset_combat()
	build.choose("bowling")
	combat.resolve(player, target, 200.0, target.position)
	check(target.projectile_left == 0.6 and target.projectile_hits_left == 2, "Bowling activates finite friendly enemy projectile")
	var victims: Array[ProjectileFixture] = []
	for index in 3:
		var victim := ProjectileFixture.new()
		root.add_child(victim)
		victim.add_to_group("demo_damageable")
		victims.append(victim)
		combat.resolve(target, victim, 200.0, victim.position)
	check(victims[0].hp == 29 and victims[1].hp == 29 and victims[2].hp == 30, "Bowling damages at most two enemies")
	check(victims[0].projectile_left == 0.0, "Enemy projectile cannot create next generation")
	combat.reset_combat()
	build.choose("explosion")
	var companion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	root.add_child(companion)
	companion.set_physics_process(false)
	companion.activate(20, 1, Vector2.ZERO)
	var primary := DemoTarget.new()
	primary.hit_points = 20
	primary.position = Vector2(500, 500)
	root.add_child(primary)
	primary.add_to_group("demo_damageable")
	var near := DemoTarget.new()
	near.hit_points = 20
	near.position = Vector2(579, 500)
	root.add_child(near)
	near.add_to_group("demo_damageable")
	var far := DemoTarget.new()
	far.hit_points = 20
	far.position = Vector2(581, 500)
	root.add_child(far)
	far.add_to_group("demo_damageable")
	combat.resolve(companion, primary, 179.0, primary.position)
	check(near.hp == 20, "Low-speed companion cannot trigger explosion")
	combat.resolve(companion, primary, 200.0, primary.position)
	check(primary.hp == 18 and near.hp == 19 and far.hp == 20, "Explosion radius 80 deals one extra damage including first target")
	combat.elapsed += 0.2
	combat.resolve(companion, primary, 200.0, primary.position)
	check(near.hp == 19, "Explosion triggers only once per launch chain without recursion")
	companion.chain_id = 21
	combat.elapsed += 0.2
	combat.resolve(companion, primary, 200.0, primary.position)
	check(near.hp == 18, "A new chain can trigger explosion again")
	# 小兵传感器交接保留基础传能，升级仅增加一次有限补偿。
	build.choose("relay")
	var receiver = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	root.add_child(receiver)
	receiver.set_physics_process(false)
	receiver.position = Vector2(100, 0)
	companion.position = Vector2.ZERO
	companion.linear_velocity = Vector2(1500, 0)
	companion.generation = 1
	companion.chain_id = 90
	check(combat.activate(companion, receiver), "Active companion can relay to idle companion")
	var bonus_events: int = 0
	for event in combat.events:
		if event.get("effect", "") == "relay_bonus":
			bonus_events += 1
			check(float(event.impulse) <= 262.5, "Relay bonus impulse stays below quarter full launch")
	check(bonus_events == 1, "Relay applies one explicit bonus")
	receiver.end_attack()
	receiver.linear_velocity = Vector2.ZERO
	companion.linear_velocity = Vector2(1500, 0)
	combat.elapsed += 0.2
	combat.activate(companion, receiver)
	bonus_events = 0
	for event in combat.events:
		if event.get("effect", "") == "relay_bonus":
			bonus_events += 1
	check(bonus_events == 1, "Same ball and chain never receive repeated relay bonus")
	receiver.end_attack()
	receiver.linear_velocity = Vector2.ZERO
	companion.generation = 3
	combat.elapsed += 0.2
	check(not combat.activate(companion, receiver), "Upgrade preserves three-generation cap")
	companion.generation = 1
	companion.linear_velocity = Vector2(179, 0)
	combat.elapsed += 0.2
	check(not combat.activate(companion, receiver), "Relay upgrade cannot activate low-speed handoff")
	target.projectile_left = 0.6
	target.projectile_hits_left = 2
	target.linear_velocity = Vector2(1500, 0)
	target.position = Vector2.ZERO
	check(not combat.activate(target, receiver), "Enemy projectile cannot launch a companion")
	combat.reset_combat()
	check(combat.events.is_empty() and combat.longest_chain == 0 and combat.exploded_chains.is_empty() and combat.relay_bonuses.is_empty() and combat.projectile_targets.is_empty(), "Combat reset clears diagnostics and chain effects")
	for node in [player, target, companion, receiver, primary, near, far]:
		node.queue_free()
	for victim in victims:
		victim.queue_free()
	combat.queue_free()
	await process_frame
