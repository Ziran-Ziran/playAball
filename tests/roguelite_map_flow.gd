extends SceneTree
## 明确的流程夹具：主动清场/到期只验状态接线，不冒充自然玩家通关。
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(40.0).timeout.connect(func(): push_error("Map flow timeout"); quit(1))
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame
func run() -> void:
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.start_game()
	await frames(4)
	var game = current_scene
	check(game.name == "Game" and game.director.maps.definition.map_id == "map_01", "Menu starts the real four-map game entry")
	var d = game.director
	d.set_process(false)
	for id in range(1, 7):
		d.register_kill(700000 + id)
	d.advance(0.01)
	check(d.state == d.State.UPGRADE and not d.maps.active, "Growth pauses actual map mechanisms")
	d.choose_upgrade("companion")
	check(d.companions.members.size() == 1 and d.state == d.State.BATTLE and d.maps.active, "Legal outsource choice grows the party and resumes map")
	for wave in range(1, 6):
		check(d.wave == wave, "Fixture reaches normal wave %d without debug_wave" % wave)
		d.pending.clear()
		d.clear_container(d.enemies)
		d.wave_elapsed = d.spawn_duration + 1.0
		d.advance(0.01)
		if wave == 2:
			check(d.state == d.State.SHOP and paused and not d.maps.active, "Wave two clear enters frozen-map shop")
			d.wallet.balance = 20
			check(d.buy_shop("upgrade", d.rest_revision), "Shop accepts one paid legal upgrade")
			var chosen: String = d.current_choices[0].id
			d.choose_upgrade(chosen)
			check(d.state == d.State.SHOP and d.wallet.balance == 12, "Shop growth returns to the shop and charges once")
			d.continue_stage(d.rest_revision)
			d.advance_transition(3.1)
			check(d.maps.definition.map_id == "map_02" and d.maps.active and not paused, "Shop countdown switches to map two")
		elif wave == 4:
			check(d.state == d.State.EVENT and not d.maps.active, "Wave four enters frozen-map supply event")
			d.resolve_event("upgrade", d.rest_revision)
			d.choose_upgrade(d.current_choices[0].id)
			d.advance_transition(3.1)
			check(d.maps.definition.map_id == "map_03" and d.maps.active, "Supply growth and countdown reach map three")
		await frames(3)
	check(d.wave == 6 and d.maps.definition.map_id == "boss_map" and d.boss != null, "Normal wave flow reaches the dedicated boss map")
	d.boss.hurt(999)
	await frames(2)
	check(d.state == d.State.VICTORY and paused and not d.maps.active, "Boss defeat opens victory and stops mechanisms")
	d.restart()
	await frames(3)
	check(d.maps.definition.map_id == "map_01" and d.companions.members.is_empty(), "Victory restart restores first map and zero party")
	d.health.hurt(999)
	check(d.state == d.State.DEFEAT and not d.maps.active, "Defeat stops mechanisms and exposes restart")
	d.restart()
	d.debug_build(PackedStringArray(["companion", "companion", "companion"]))
	d.debug_wave(5)
	await frames(3)
	var portals = d.maps.current_map.get_node("Portals")
	portals.set_physics_process(false)
	game.player.reset_body(portals.get_node("A").global_position)
	await frames(3)
	check(portals.try_teleport(game.player, 0), "Formal-map portal request can be queued")
	d.set_paused(true)
	check(game.player._teleport_request.is_empty(), "Formal pause cancels pending map transfer")
	var arc = d.maps.current_map.get_node("TwinArcs")
	var phase: float = arc.elapsed
	await create_timer(0.12).timeout
	check(arc.elapsed == phase, "Formal pause leaves rotating map phase unchanged")
	d.restart()
	await frames(3)
	check(get_nodes_in_group("active_run_map").size() == 1 and get_nodes_in_group("map_spikes").is_empty(), "Restart from portal map removes old spikes, locks and map")
	game.return_to_menu()
	await frames(3)
	check(current_scene.has_node("Start") and get_nodes_in_group("active_run_map").is_empty(), "Return to menu frees every active map")
	current_scene.queue_free()
	await frames(3)
	await paddle_boss_contact()
	print("MAP FLOW CHECKS PASSED: ", checks) if failures == 0 else print("MAP FLOW FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
func paddle_boss_contact() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	var paddle = load("res://scenes/roguelite/mechanisms/pivot_paddle.tscn").instantiate()
	paddle.position = Vector2(700, 350)
	paddle.initial_angle = PI * 0.5
	paddle.angle_limit = 0.0
	fixture.add_child(paddle)
	var boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	boss.position = Vector2(500, 350)
	fixture.add_child(boss)
	boss.set_physics_process(false)
	await frames(3)
	boss.phase = boss.Phase.CHARGE
	boss.phase_left = 2.0
	boss.charge_direction = Vector2.RIGHT
	boss.linear_velocity = Vector2(800, 0)
	await frames(60)
	check(boss.phase == boss.Phase.EXPOSED, "Real charge collision with a map rigid paddle opens boss weak point")
	fixture.queue_free()
	await frames(3)
