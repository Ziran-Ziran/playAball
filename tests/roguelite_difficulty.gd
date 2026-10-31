extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Difficulty timeout"); quit(1))
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
	arena.get_node("AudioDirector").muted = true
	check(d.has_method("wave_budget"), "Wave difficulty has explicit editable population budgets")
	if failures:
		quit(1)
		return
	var limits: Array[int] = [6, 8, 10, 12, 14]
	var intervals: Array[float] = [5.5, 5.2, 4.9, 4.6, 4.3]
	var heavy_caps: Array[float] = [0, 0.15, 0.20, 0.25, 0.30]
	var turret_caps: Array[float] = [0, 0, 0.10, 0.15, 0.20]
	for wave in range(1, 6):
		d.debug_wave(wave)
		check(d.pending.size() == 2, "Wave %d keeps two opening warnings" % wave)
		check(d.wave_budget() == limits[wave - 1] and is_equal_approx(d.wave_interval(), intervals[wave - 1]), "Wave %d ramps budget and interval gradually" % wave)
		var bounded: bool = true
		for tick in 300:
			d.advance(0.1)
			bounded = bounded and d.alive_count() + d.pending.size() <= limits[wave - 1]
		check(bounded, "Wave %d remains within live plus warning limit for 30 uncleared seconds" % wave)
		check(d.alive_count() <= limits[wave - 1] and d.wave == wave, "Wave %d cannot advance while survivors remain" % wave)
		var counts: Array[int] = [0, 0, 0]
		var quota_bounded: bool = true
		for trial in 1000:
			# 清理而不制造击杀奖励，单测刷怪的累计出场构成。
			d.clear_container(d.enemies)
			d.pending.clear()
			d.queue_batch()
			for warning in d.pending:
				counts[warning.kind] += 1
			quota_bounded = quota_bounded and float(counts[1]) <= float((trial + 1) * 2) * heavy_caps[wave - 1] + 1.0
		check(quota_bounded, "Wave %d heavy quota remains bounded across short prefixes" % wave)
		check(float(counts[1]) / 2000.0 <= heavy_caps[wave - 1] + 0.005 and float(counts[2]) / 2000.0 <= turret_caps[wave - 1] + 0.005, "Wave %d strong enemy ratios stay under configured caps" % wave)
	d.restart()
	var first: Array[int] = []
	for warning in d.pending:
		first.append(warning.kind)
	check(first == [0, 0] and d.wave == 1 and d.wave_budget() == 6, "Restart restores gentle fragile opening and first-wave budget")
	d.enemy_limit = 3
	d.debug_wave(5)
	d.queue_batch()
	check(d.pending.size() == 3, "Global enemy limit still constrains per-wave budget")
	d.player.position = Vector2(640, 540)
	d.pending.clear()
	for trial in 8:
		d.spawn_enemy(0, Vector2(140, 220))
	check(d.alive_count() == 3, "Direct spawning also respects current population cap")
	d.clear_container(d.enemies)
	d.pending.clear()
	d.spawn_enemy(0, d.player.position)
	for retry in 10:
		if not d.pending.is_empty():
			d.pending[0].point = d.player.position
		d.advance(0.81)
	check(d.pending.size() <= 3 and d.alive_count() + d.pending.size() <= 3, "Repeated unsafe spawn warnings never duplicate population slots")
	arena.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("DIFFICULTY CHECKS PASSED: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)
