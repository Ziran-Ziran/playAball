extends SceneTree
## 补齐“合法卡池→真实卡按钮→正式构筑接线→实际效果”的集成链。
var checks: int = 0
var failures: int = 0
var d: Node
func _initialize() -> void:
	call_deferred("run")
	create_timer(90).timeout.connect(func(): push_error("Feature acceptance timeout"); quit(1))
func check(value: bool, message: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures += 1
func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame
func run() -> void:
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	# Game每帧由正式静音控件同步混音；只改AudioDirector.muted会被覆盖。
	game.get_node("HUD/Controls/Mute").button_pressed = true
	await frames(3)
	d = game.director
	d.set_process(false)
	var ids := ["launch_power", "glide", "cooldown", "double_launch", "heavy", "echo", "bowling", "explosion", "companion", "follow", "relay", "shrink", "pulse", "heal", "choices", "vigor"]
	for id: String in ids:
		d.restart()
		d.pending.clear()
		d.chosen_rewards = 1
		d.rice.set_physics_process(false)
		if id in ["explosion", "follow", "relay"]:
			d.debug_build(PackedStringArray(["companion", "companion"]))
		if id == "heal":
			d.health.hp = 2
		if id == "vigor":
			for definition in d.build.definitions:
				if definition.max_level > 0:
					for rank in definition.max_level:
						d.build.choose(definition.id)
			d.apply_build()
		var baseline_speed: float = await glide_sample() if id == "glide" else 0.0
		var found_seed: int = -1
		for seed_value in range(1, 513):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var candidates: Array = d.build.candidates(rng, false, d.health.hp, d.health.max_hp)
			if candidates.any(func(card): return card.id == id):
				found_seed = seed_value
				break
		check(found_seed >= 0, "Legal pool offers " + id)
		if found_seed < 0:
			continue
		d.rng.seed = found_seed
		d.rewards.pending = 1
		d.open_upgrade()
		await frames(100)
		var index: int = -1
		for card_index in d.current_choices.size():
			if d.current_choices[card_index].id == id:
				index = card_index
		check(index >= 0, "Formal offer contains " + id)
		if index < 0:
			continue
		var card: Button = d.hud.cards.get_child(index)
		check(not card.disabled and card.visible, "Real selectable card enabled: " + id)
		check(not card.get_node("Content/Preview").text.is_empty(), "Card has actual benefit preview: " + id)
		var old_level: int = int(d.build.levels.get(id, 0))
		card.pressed.emit()
		await frames(3)
		check(int(d.build.levels.get(id, 0)) == old_level + 1 and d.rewards.pending == 0 and d.state == d.State.BATTLE and not paused, "Card signal applies once and resumes battle: " + id)
		await verify_effect(id, baseline_speed)
	game.queue_free()
	d = null
	await frames(10)
	print("FEATURE ACCEPTANCE CHECKS PASSED: %d failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
func glide_sample() -> float:
	d.player.reset_body(Vector2(300, 600))
	await frames(3)
	d.player.linear_velocity = Vector2(100, 0)
	await frames(180)
	return d.player.linear_velocity.length()
func verify_effect(id: String, baseline_speed: float) -> void:
	match id:
		"launch_power":
			d.player.reset_body(Vector2(300, 600))
			await frames(3)
			check(d.launcher.launch_with_drag(Vector2(160, 0)), "Upgraded launch accepted")
			await frames(2)
			check(d.player.linear_velocity.x > 1180, "Power card produces larger physical velocity")
		"glide":
			var speed: float = await glide_sample()
			check(speed > baseline_speed + 1.0, "Glide physically retains more speed: %.4f -> %.4f" % [baseline_speed, speed])
		"cooldown":
			d.launcher.set_process(false)
			d.launcher.launch_with_drag(Vector2(160, 0))
			d.launcher.advance(1.94)
			check(not d.launcher.available(), "Cooldown unavailable before 1.95 seconds")
			d.launcher.advance(0.02)
			check(d.launcher.available(), "Cooldown ready after 1.95 seconds")
			d.launcher.set_process(true)
		"double_launch":
			check(d.launcher.launch_with_drag(Vector2(160, 0)) and d.launcher.launch_with_drag(Vector2(-160, 0)) and not d.launcher.launch_with_drag(Vector2(160, 0)), "Double grants exactly two immediate launches")
		"companion":
			check(d.companions.members.size() == 1, "Outsource creates actual companion")
		"follow":
			d.player.reset_body(Vector2(240, 550))
			await frames(3)
			d.player.freeze = true
			var member: DemoCompanion = d.companions.members[0]
			member.reset_body(Vector2(450, 550))
			await frames(3)
			var before: float = member.position.distance_to(d.player.position + member.follow_offset())
			await frames(120)
			check(member.follow_enabled and member.position.distance_to(d.player.position + member.follow_offset()) < before - 20, "Follow physically moves companion toward its slot")
			d.player.freeze = false
		"heal": check(d.health.hp == 4, "Heal actually restores two HP")
		"vigor": check(d.health.max_hp == 6 and d.health.hp == 6, "Fallback actually increases max HP and heals")
		"choices":
			d.rewards.pending = 1
			d.open_upgrade()
			check(d.current_choices.size() == 4 and d.hud.cards.get_child_count() == 4, "Choices produces four actual cards")
			d.choose_upgrade(d.current_choices[0].id, d._choice_revision)
		"shrink":
			d.spawn_enemy(0, Vector2(140, 220))
			check(d.enemies.get_child_count() == 1 and is_equal_approx(d.enemies.get_child(0).pulse_radius, 76.5), "Shrink applies to newly spawned real enemy")
		"heavy", "echo", "bowling", "explosion", "relay", "pulse":
			# 各战斗效果的命中、延迟、范围、伤害/速度变化及递归限制由独立
			# build/reward_effects夹具验证；此处专门检查卡选择后正式组件共享构筑。
			check(d.combat.build == d.build and d.assists.build == d.build and d.build.has_upgrade(id), "Selected combat effect reaches actual combat/assist components: " + id)
