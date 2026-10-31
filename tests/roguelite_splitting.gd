extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Split timeout"); quit(1))
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var arena = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var d = arena.director
	d.set_process(false)
	arena.feedback.sound_enabled = false
	arena.get_node("AudioDirector").muted = true
	check(d.has_method("set_split_enabled"), "Optional splitting entry exists")
	if failures:
		quit(1)
		return
	check(not d.split_enabled, "Splitting defaults off")
	var option: CheckButton = arena.get_node("HUD/Controls/Split")
	check(not option.button_pressed, "Player split checkbox defaults off")
	option.button_pressed = true
	check(d.split_enabled, "Player checkbox actually enables split rules")
	option.button_pressed = false
	check(not d.split_enabled, "Player checkbox actually disables split rules")
	d.pending.clear()
	d.spawn_enemy(1, Vector2(640, 260), 6)
	var root_enemy = d.enemies.get_child(0)
	root_enemy.hurt(99)
	check(d.pending.is_empty() and d.kills == 1, "Off setting keeps one death with no split")
	d.restart()
	d.pending.clear()
	d.set_split_enabled(true)
	d.spawn_enemy(1, Vector2(640, 260), 6)
	var parent = d.enemies.get_child(0)
	parent.hurt(99)
	check(d.kills == 1 and d.wallet.balance == 1 and d.pending.size() == 2, "Family root grants one reward then two delayed children")
	check(d.pending.all(func(item): return item.hp_override == 3 and not item.family_reward and item.left >= 0.8), "Children have lower tier and full warning without duplicate reward")
	var queued: int = d.pending.size()
	parent.died.emit(parent)
	check(d.pending.size() == queued and d.kills == 1, "Repeated death signal cannot duplicate children or currency")
	await process_frame
	d.advance(0.4)
	check(d.alive_count() == 0 and d.pending.size() == 2, "No same-frame recursive spawn")
	d.advance(0.41)
	check(d.alive_count() == 2 and d.enemies.get_children().all(func(item): return item.hp == 3), "Warnings spawn two real three-health children")
	for child in d.enemies.get_children():
		child.hurt(99)
	check(d.pending.size() == 4 and d.kills == 1 and d.wallet.balance == 1, "Second generation is bounded and grants no extra family reward")
	await process_frame
	d.advance(0.81)
	# 两个父体的局部预警可能重叠，允许完整安全重预警后再检查实体。
	d.spawn_left = 999.0
	for retry in 5:
		if d.pending.is_empty():
			break
		d.advance(0.81)
	check(d.alive_count() == 4 and d.enemies.get_children().all(func(item): return item.hp == 1), "Final generation has one health")
	for child in d.enemies.get_children():
		child.hurt(99)
	check(d.pending.is_empty() and d.kills == 1, "One-health children terminate family")
	await process_frame
	d.spawn_enemy(1, Vector2(640, 260), 6)
	d.enemies.get_child(0).hurt(99)
	d.set_split_enabled(false)
	check(d.pending.size() == 2, "Disabling preserves existing child warnings")
	d.advance(0.81)
	for child in d.enemies.get_children():
		child.hurt(99)
	check(d.pending.is_empty(), "Disabling affects later child deaths")
	d.set_split_enabled(true)
	d.restart()
	check(d.split_enabled and d.pending.size() == 2 and d.kills == 0, "Restart preserves preference and clears old family economy")
	d.pending.clear()
	d.enemy_limit = 1
	d.spawn_enemy(1, Vector2(640, 260), 6)
	d.enemies.get_child(0).hurt(99)
	check(d.pending.size() == 1, "Splitting shares live-plus-warning budget")
	d.wave_elapsed = d.spawn_duration + 1.0
	d.advance(0.01)
	check(d.wave == 1, "Queued split children prevent premature clear")
	d.pending[0].point = d.player.position
	d.advance(0.81)
	check(d.alive_count() == 0 and d.pending.size() == 1, "Unsafe nearby split point repeats warning without face spawn")
	check(d.pending[0].origin.distance_to(Vector2(640, 260)) < 0.1, "Safety rewarning retains local family origin")
	for retry in 8:
		if d.pending.is_empty():
			break
		d.pending[0].point = d.player.position
		d.materialize_warning(d.pending.pop_front())
	check(d.pending.is_empty(), "Persistent unsafe split is cancelled after bounded retries")
	d.enemy_limit = 24
	d.debug_wave(4)
	var high_count: int = 0
	var heavy_count: int = 0
	for batch in 100:
		for warning in d.pending:
			if warning.kind == 1:
				heavy_count += 1
			if warning.get("hp_override", 0) == 6:
				high_count += 1
		d.pending.clear()
		d.queue_batch()
	check(high_count > 0 and high_count == heavy_count / 2, "Enabled late waves replace only every second heavy with six health")
	d.debug_wave(6)
	d.boss.hurt(999)
	check(d.state == d.State.VICTORY and d.pending.is_empty(), "Boss never splits")
	d.restart()
	check(d.pending.all(func(item): return item.get("family_reward", true)), "Restart leaves only fresh original warnings")
	d.pending.clear()
	d.spawn_enemy(1, Vector2(640, 260), 6)
	var stale_enemy = d.enemies.get_child(0)
	d.enemies.remove_child(stale_enemy)
	d.restart()
	d.enemies.add_child(stale_enemy)
	stale_enemy.hurt(999)
	check(d.pending.size() == 2 and d.kills == 0, "Old-run enemy callback cannot split or grant rewards after restart")
	arena.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("SPLITTING CHECKS PASSED: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)
