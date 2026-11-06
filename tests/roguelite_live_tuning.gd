extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Live tuning timeout"); quit(1))

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

func run() -> void:
	var path: String = "res://scenes/roguelite/tuning_run.tscn"
	check(ResourceLoader.exists(path), "Planner build has an in-game live tuning entry")
	if not ResourceLoader.exists(path):
		quit(1)
		return
	var arena = load(path).instantiate()
	root.add_child(arena)
	arena.feedback.sound_enabled = false
	arena.sync_audio_mix()
	await frames(4)
	var tuning = arena.get_node("LiveTuning")
	var director = arena.director
	check(tuning.panel.is_open() and paused, "Planner starts with the panel open and battle paused")
	tuning.set_panel_open(false)
	director.spawn_left = 999.0
	director.spawn_duration = 999.0
	var revision: int = director._run_revision
	var hp: int = director.health.hp
	var shape = arena.player.get_node("Shape").shape
	check(tuning.set_parameter("launch_impulse", 1400.0), "Live impulse slider request is accepted")
	check(tuning.set_parameter("linear_damping", 0.3), "Live damping request is accepted")
	check(tuning.set_parameter("bounce", 0.5), "Live restitution request is accepted")
	check(tuning.set_parameter("friction", 0.2), "Live friction request is accepted")
	check(tuning.set_parameter("cooldown", 1.0), "Live launch cooldown request is accepted")
	check(tuning.set_parameter("enemy_mass_scale", 2.0), "Live enemy mass scale is accepted")
	check(tuning.set_parameter("stagger", 1.0), "Live stagger request is accepted")
	check(tuning.set_parameter("impact_retention", 0.9), "Live impact retention request is accepted")
	check(tuning.set_parameter("opposing_momentum", 0.5), "Live reverse-momentum cancellation is accepted")
	await frames(2)
	check(is_equal_approx(arena.player.max_impulse, 1400.0) and is_equal_approx(arena.player.linear_damp, 0.3), "Current player gets new impulse and damping without restart")
	check(is_equal_approx(arena.player.physics_material_override.bounce, 0.5) and is_equal_approx(arena.player.physics_material_override.friction, 0.2), "Current ball material updates immediately")
	check(director._run_revision == revision and director.health.hp == hp and arena.player.get_node("Shape").shape == shape, "Tuning preserves the run, health and collision shape")
	check(is_equal_approx(arena.player.cancel_opposing_momentum, 0.5), "Current player receives reverse-momentum parameter")
	check(not tuning.set_parameter("hp", 999.0) and not tuning.set_parameter("bounce", INF), "Unknown and non-finite requests are rejected")
	director.clear_container(arena.get_node("Enemies"))
	director.spawn_enemy(DemoEnemy.Kind.HEAVY, Vector2(1000, 570))
	await frames(2)
	var enemy: DemoEnemy = arena.get_node("Enemies").get_child(0)
	enemy.set_physics_process(false)
	check(is_equal_approx(enemy.mass, 1.1) and is_equal_approx(enemy.hit_stagger, 1.0), "New enemy inherits live mass and stagger")
	var enemy_id: int = enemy.get_instance_id()
	tuning.set_parameter("enemy_mass_scale", 0.5)
	await frames(2)
	check(enemy.get_instance_id() == enemy_id and is_equal_approx(enemy.mass, 0.275), "Existing enemy changes mass without replacement")
	arena.launcher.remaining = 0.5
	arena.launcher.set_blocked(true)
	tuning.set_parameter("cooldown", 2.0)
	await frames(2)
	check(is_equal_approx(arena.launcher.remaining, 1.0), "Cooldown tuning preserves recharge percentage")
	arena.launcher.set_blocked(false)
	director.build.choose("launch_power")
	director.build.choose("glide")
	director.build.choose("cooldown")
	director.apply_build()
	await frames(2)
	check(is_equal_approx(arena.player.max_impulse, 1610.0) and is_equal_approx(arena.player.linear_damp, 0.225), "Growth applies on top of tuned impulse and damping")
	check(is_equal_approx(arena.launcher.cooldown, 2.0 * 1.95 / 2.2), "Growth applies on top of tuned cooldown")
	tuning.set_panel_open(true)
	check(paused and director.state == director.State.PAUSED and arena.launcher.blocked, "Opening tuner pauses battle and cancels launch input")
	tuning.set_parameter("launch_impulse", 1000.0)
	await frames(2)
	check(is_equal_approx(arena.player.max_impulse, 1150.0), "Paused tuning applies to the current actor before resuming")
	check(arena.over_controls(tuning.panel_rect().get_center()), "Tuning panel consumes release events instead of firing the ball")
	check(tuning.panel_rect().end.x <= 1280.0 and tuning.panel_rect().end.y <= 720.0, "Tuning panel fits the logical game viewport")
	var slider: HSlider = tuning.panel._fields.launch_impulse[0]
	var spin: SpinBox = tuning.panel._fields.launch_impulse[1]
	slider.value = 1500.0
	check(is_equal_approx(arena.player.max_impulse, 1725.0) and is_equal_approx(spin.value, 1500.0), "Slider changes gameplay immediately and synchronizes numeric entry")
	spin.value = 1000.0
	check(is_equal_approx(slider.value, 1000.0) and is_equal_approx(arena.player.max_impulse, 1150.0), "Numeric entry changes gameplay immediately and synchronizes slider")
	tuning.set_panel_open(false)
	check(not paused and director.state == director.State.BATTLE, "Closing owned tuning pause resumes battle")
	director.set_paused(true)
	tuning.set_panel_open(true)
	tuning.set_panel_open(false)
	check(paused and director.state == director.State.PAUSED, "Closing tuner cannot resume a pause owned by the normal menu")
	director.set_paused(false)
	tuning.set_panel_open(true)
	arena.set_paused(true)
	tuning.set_panel_open(false)
	check(paused and arena.menu.visible, "A normal pause requested after tuning pause keeps its menu and pause ownership")
	director.set_paused(false)
	tuning.set_panel_open(true)
	tuning.set_pause_preference(false)
	check(not paused and tuning.panel.is_open(), "Optional unpaused mode permits changing values while battle runs")
	tuning.set_panel_open(false)
	tuning.set_pause_preference(true)
	tuning.remember_comparison()
	tuning.set_parameter("launch_impulse", 1600.0)
	tuning.swap_comparison()
	check(is_equal_approx(tuning.values.launch_impulse, 1000.0), "Comparison recalls the stored parameter set")
	tuning.swap_comparison()
	check(is_equal_approx(tuning.values.launch_impulse, 1600.0), "Comparison can toggle back to the alternative")
	var preset_path: String = "user://live_tuning_test.json"
	check(tuning.save_preset(preset_path), "Current physical values can be saved")
	tuning.restore_defaults()
	check(tuning.load_preset(preset_path) and is_equal_approx(tuning.values.launch_impulse, 1600.0), "Saved values load without restarting the run")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(preset_path))
	director.restart()
	await frames(4)
	check(is_equal_approx(arena.player.max_impulse, 1600.0) and is_equal_approx(arena.launcher.cooldown, 2.0), "Restart retains tuned physical baseline without retaining upgrades")
	tuning.restore_defaults()
	await frames(2)
	check(is_equal_approx(arena.player.max_impulse, 1050.0) and is_equal_approx(arena.launcher.cooldown, 2.2), "One click restores the checked-in physical baseline")
	tuning.set_parameter("launch_impulse", 1400.0)
	tuning.set_parameter("linear_damping", 0.0)
	# 发射测速应从当前地图安全出生点开始；旧(640,540)现在是下方实体翻板轴心。
	arena.player.reset_body(director.maps.definition.player_spawn)
	await frames(3)
	check(arena.launcher.launch_with_drag(Vector2(160, 0)), "Tuned impulse still uses the formal launch contract")
	await frames(2)
	check(arena.player.linear_velocity.x > 1100.0, "Tuned value produces stronger real physical motion, beyond baseline full launch")
	arena.queue_free()
	await frames(2)
	var formal = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(formal)
	await frames(3)
	check(formal.get_node_or_null("LiveTuning") == null and is_equal_approx(formal.player.max_impulse, 1050.0), "Formal run remains isolated from the planner tuning scene")
	formal.queue_free()
	await frames(2)
	print("LIVE TUNING CHECKS PASSED: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
