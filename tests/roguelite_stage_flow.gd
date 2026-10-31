extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Stage test timeout"); quit(1))
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var arena = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var d = arena.director
	arena.get_node("AudioDirector").muted = true
	d.set_process(false)
	check(d.has_method("continue_stage"), "Stage rest flow exists")
	if failures:
		quit(1)
		return
	d.enter_rest("shop")
	check(d.state == d.State.BATTLE, "Spawn warnings block rest")
	d.pending.clear()
	d.rewards.pending = 1
	d.enter_rest("shop")
	check(d.state == d.State.BATTLE, "Queued kill reward blocks rest")
	d.rewards.pending = 0
	var hazard = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	hazard.health = d.health
	d.hazards.add_child(hazard)
	d.combat.pending_echoes.append({"left": 10.0})
	d.rice.stored_bonus = true
	d.player.chain_id = 9
	d.launcher.remaining = 1.0
	d.pending.clear()
	d.wave_elapsed = d.spawn_duration + 1
	d.advance(0.01)
	check(d.wave == 2, "First wave continues inside stage")
	d.pending.clear()
	d.wave_elapsed = d.spawn_duration + 1
	d.advance(0.01)
	check(d.state == d.State.SHOP and paused, "Stage one ends in paused shop")
	check(d.hazards.get_child_count() == 0 and d.combat.pending_echoes.is_empty() and not d.rice.stored_bonus and not d.player.attacking(), "Stage rest clears dangerous leftovers and temporary attacks")
	d.launcher.advance(10.0)
	check(is_equal_approx(d.launcher.remaining, 1.0), "Rest does not recharge launches")
	var rest_quote: int = d.rest_revision
	d.enter_rest("shop")
	check(d.rest_revision == rest_quote, "Repeated stage clear cannot reopen rest")
	d.set_paused(false)
	check(d.state == d.State.SHOP and paused, "Escape cannot bypass shop")
	var offer: int = d.rest_revision
	d.continue_stage(offer)
	check(d.state == d.State.TRANSITION and paused, "Continue enters safe countdown")
	d.advance_transition(3.1)
	check(d.wave == 3 and not paused, "Countdown resumes wave three")
	d.debug_wave(4)
	d.pending.clear()
	d.wave_elapsed = d.spawn_duration + 1
	d.advance(0.01)
	check(d.state == d.State.EVENT, "Stage two ends in event")
	var event_quote: int = d.rest_revision
	var progress_before: int = d.rewards.progress
	var pending_before: int = d.rewards.pending
	d.resolve_event("upgrade", event_quote)
	check(d.state == d.State.UPGRADE and not d.current_choices.is_empty(), "Event opens one free legal growth choice")
	if d.current_choices.is_empty():
		quit(1)
		return
	var event_choice: String = d.current_choices[0].id
	var old_level: int = int(d.build.levels.get(event_choice, 0))
	var card_revision: int = d._choice_revision
	d.choose_upgrade(event_choice, card_revision)
	check(d.state == d.State.TRANSITION and int(d.build.levels.get(event_choice, 0)) == old_level + 1, "Event growth applies before safe countdown")
	check(d.rewards.progress == progress_before and d.rewards.pending == pending_before and d.chosen_rewards == 0, "Event growth never consumes kill reward economy")
	d.resolve_event("upgrade", event_quote)
	d.choose_upgrade(event_choice, card_revision)
	check(int(d.build.levels.get(event_choice, 0)) == old_level + 1 and d.wallet.balance == 0, "Repeated event and stale card cannot grant extra growth")
	d.advance_transition(3.1)
	check(d.wave == 5, "Final stage starts at fifth wave")
	d.pending.clear()
	d.wave_elapsed = d.spawn_duration + 1
	d.advance(0.01)
	check(d.wave == 6 and d.boss != null, "Final wave proceeds to boss without extra rest")
	d.health.hurt(999)
	check(d.state == d.State.DEFEAT, "Death remains highest priority")
	d.restart()
	check(d.wallet.balance == 0 and d.state == d.State.BATTLE and not paused, "Restart clears rest and currency")
	d.continue_stage(offer)
	check(d.wave == 1 and d.state == d.State.BATTLE, "Old rest button cannot affect new run")
	arena.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("STAGE FLOW CHECKS PASSED: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)
