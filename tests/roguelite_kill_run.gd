extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Kill run timeout"); quit(1))
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
	await process_frame
func run() -> void:
	var arena = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await frames(3)
	arena.feedback.sound_enabled = false
	var director = arena.director
	director.set_process(false)
	check(director.has_method("register_kill"), "Run has a unified kill reward entry")
	if failures:
		arena.queue_free()
		await process_frame
		quit(1)
		return
	director.reward_first = 2
	director.reward_increment = 2
	director.reward_cap = 6
	director.restart()
	director.advance(0.81)
	await frames(2)
	var shot = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	shot.health = director.health
	shot.position = Vector2(900, 300)
	shot.linear_velocity = Vector2(-180, 0)
	director.hazards.add_child(shot)
	for enemy in director.enemies.get_children():
		enemy.hurt(999)
	await frames(2)
	check(director.kills == 2 and director.rewards.pending == 1, "Real enemy deaths count once toward reward threshold")
	director.advance(0.1)
	check(director.state == director.State.UPGRADE and director.wave_elapsed < director.spawn_duration, "Reward opens during battle without waiting for wave clear")
	check(paused and arena.launcher.blocked and director.hazards.get_child_count() == 1, "Reward pauses and preserves dangerous projectiles")
	var saved_position: Vector2 = shot.position
	var saved_velocity: Vector2 = shot.linear_velocity
	await frames(8)
	check(shot.position.distance_to(saved_position) < 0.1 and shot.linear_velocity.is_equal_approx(saved_velocity), "Reward pause preserves projectile motion state")
	director.choose_upgrade("companion")
	check(director.wave == 1 and director.state == director.State.BATTLE and not paused, "Reward resumes same wave")
	check(director.chosen_rewards == 1 and director.companions.members.size() == 2, "Exactly one chosen reward applies")
	for id in range(10000, 10010):
		director.register_kill(id)
	director.advance(0.01)
	check(director.rewards.pending == 2 and director.state == director.State.UPGRADE, "Burst kills queue two rewards")
	var old_offer: int = director._choice_revision
	var old_choice: String = director.current_choices[0].id
	director.choose_upgrade(old_choice, old_offer)
	check(director.rewards.pending == 1 and paused and director.state == director.State.UPGRADE, "First choice does not discard queued reward or resume early")
	director.choose_upgrade(old_choice, old_offer)
	check(director.rewards.pending == 1, "Old card click cannot consume the next queued reward")
	director.choose_upgrade(director.current_choices[0].id)
	check(director.rewards.pending == 0 and not paused and director.chosen_rewards == 3, "All queued rewards are chosen separately")
	director.wave_elapsed = director.spawn_duration + 1.0
	director.pending.clear()
	director.advance(0.1)
	check(director.wave == 2 and director.state == director.State.BATTLE and director.chosen_rewards == 3, "Wave clear advances without duplicating reward")
	director.build.choose("choices")
	director.apply_build()
	for id in range(20000, 20006):
		director.register_kill(id)
	director.advance(0.01)
	check(director.current_choices.size() == 4 and arena.get_node("RunHUD").cards.get_child_count() == 4, "Choices upgrade creates four actual cards")
	var selected: String = director.current_choices[0].id
	director.choose_upgrade(selected)
	var chosen_before: int = director.chosen_rewards
	director.choose_upgrade(selected)
	check(director.chosen_rewards == chosen_before, "Repeated click cannot choose a completed reward again")
	for id in range(30000, 30006):
		director.register_kill(id)
	director.health.hurt(99)
	director.advance(0.01)
	check(director.state == director.State.DEFEAT and director.rewards.pending == 0, "Death wins priority over pending reward")
	director.restart()
	check(director.kills == 0 and director.chosen_rewards == 0 and director.rewards.pending == 0 and director.rewards.progress == 0, "Restart resets entire reward economy")
	check(arena.launcher.capacity == 1 and arena.launcher.charges == 1, "Restart clears double-launch capacity")
	await frames(3)
	arena.launcher.remaining = 1.1
	director.build.choose("cooldown")
	director.apply_build()
	check(is_equal_approx(arena.launcher.remaining, 0.975), "Cooldown upgrade preserves current recharge percentage")
	director.apply_build()
	check(is_equal_approx(arena.launcher.remaining, 0.975), "Repeated build application never refunds recharge twice")
	arena.queue_free()
	await process_frame
	check(not paused and Engine.time_scale == 1.0, "Leaving kill reward run restores global state")
	if not failures:
		print("KILL RUN CHECKS PASSED: ", checks)
	quit(0 if not failures else 1)
