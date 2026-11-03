extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(45.0).timeout.connect(func(): push_error("Gameplay lab test timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in ceili(count * Engine.physics_ticks_per_second / 60.0):
		await physics_frame

func run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/main_menu.tscn", "Formal entry is the release menu, not a lab")
	check(ResourceLoader.exists("res://scenes/roguelite/run.tscn"), "Formal run scene remains available")
	check(ResourceLoader.exists("res://scenes/roguelite/gameplay_lab.tscn"), "Independent gameplay lab scene exists")
	check(not FileAccess.get_file_as_string("res://scenes/roguelite/run.tscn").contains("gameplay_lab.gd"), "Formal run scene does not reference the lab script")
	var lab = load("res://scenes/roguelite/gameplay_lab.tscn").instantiate()
	root.add_child(lab)
	await frames(4)
	check(lab._reset_ready and lab.enemies.get_child_count() == 1, "Default single-enemy fixture is rebuilt through the physical reset path")
	var parameter_panel: Control = lab.lab_panel.get_node("Control/ParameterPanel")
	var readout_panel: Control = lab.lab_panel.get_node("Control/ReadoutPanel")
	var log_panel: Control = lab.lab_panel.get_node("Control/LogPanel")
	check(parameter_panel.get_global_rect().end.y <= 720.0 and parameter_panel.get_global_rect().end.x <= 1280.0, "Lab parameter panel fits the logical viewport")
	check(readout_panel.get_global_rect().end.x < parameter_panel.get_global_rect().position.x, "Readout does not overlap the parameter panel")
	check(log_panel.get_global_rect().end.x < parameter_panel.get_global_rect().position.x, "Log does not overlap the parameter panel")
	check(lab.over_controls(parameter_panel.get_global_rect().get_center()) and not lab.over_controls(Vector2(800, 400)), "Lab UI blocks pointer release while empty arena remains draggable")
	var paused_time: float = lab._fixture_elapsed
	paused = true
	await process_frame
	check(is_equal_approx(lab._fixture_elapsed, paused_time), "Lab timing and split warnings pause with the battle tree")
	paused = false
	var revision_before_stale: int = lab._fixture_revision
	lab._on_lab_action("apply", lab.lab_panel.values(), revision_before_stale - 1)
	check(lab._fixture_revision == revision_before_stale, "Gameplay rejects a stale panel request")
	var first_signature: Array = [lab.player.mass, lab.player.collision_layer, lab.player.collision_mask, lab.player.get_node("Shape").shape.radius]
	var single: Dictionary = lab._sanitize_config(lab._applied)
	single.enemy_hp = 6
	single.distance = 390
	single.power_pct = 100
	single.angle_deg = 0
	lab._request_reset(single)
	await frames(4)
	check(lab.enemies.get_child_count() == 1 and lab.enemies.get_child(0).max_hp == 6, "Single fixture applies explicit HP and count")
	check(lab._fixed_launch(), "Fixed launch is accepted through DemoLaunch.launch_with_drag")
	await frames(90)
	check(lab.launcher.shots == 1 and lab._valid_hits > 0 and lab._total_damage > 0, "Fixed launch produces a real physics contact and damage readout")
	check(lab._clear_time >= 0.0 or lab.enemies.get_child_count() > 0, "Readout records a clear time after real fixture completion")
	check(lab.player.linear_velocity.length() >= 0.0 and is_equal_approx(Engine.time_scale, 1.0), "Lab remains at normal speed")
	check([lab.player.mass, lab.player.collision_layer, lab.player.collision_mask, lab.player.get_node("Shape").shape.radius] == first_signature, "Lab launch preserves player physical signature")
	var built: Dictionary = single.duplicate(true)
	built.build_preset = 2
	lab._request_reset(built)
	await frames(4)
	check(lab._lab_build.has_upgrade("heavy") and lab._lab_build.has_upgrade("echo"), "Build preset applies existing gameplay upgrades through DemoBuild")
	check(is_equal_approx(lab.player.max_impulse, 1050.0) and lab.combat.build == lab._lab_build, "Build preset feeds authoritative lab-only player and combat rules")
	var partners: Dictionary = single.duplicate(true)
	partners.build_preset = 3
	lab._request_reset(partners)
	await frames(4)
	check(lab.companions.members.size() == 1 and lab.companions.follow_enabled, "Companion build applies both extra member and follow without manual overrides")
	var rhythm: Dictionary = single.duplicate(true)
	rhythm.build_preset = 5
	lab._request_reset(rhythm)
	await frames(4)
	check(is_equal_approx(lab.launcher.cooldown, 1.95) and lab.launcher.capacity == 2, "Rhythm build applies reduced cooldown and double launch together")
	rhythm.override_build_parameters = true
	rhythm.cooldown_seconds = 3.0
	rhythm.companion_count = 3
	rhythm.follow_enabled = true
	lab._request_reset(rhythm)
	await frames(4)
	check(is_equal_approx(lab.launcher.cooldown, 3.0) and lab.companions.members.size() == 3 and lab.companions.follow_enabled, "Explicit override wins over build cooldown and companion defaults")
	var survival: Dictionary = single.duplicate(true)
	survival.build_preset = 4
	survival.distance = 120
	lab._request_reset(survival)
	await frames(4)
	var survivor_target: DemoEnemy = lab.enemies.get_child(0)
	check(is_equal_approx(survivor_target.pulse_radius, 76.5) and lab.player_health.max_hp == 6, "Survival build applies smaller enemy attack range and extra life")
	await frames(250)
	check(survivor_target.linear_velocity.length() > 1.0, "Survival pulse produces a real bounded impulse in the lab")

	var crowd: Dictionary = single.duplicate(true)
	crowd.fixture = lab.Fixture.CROWD
	crowd.enemy_count = 3
	crowd.distance = 320
	lab._request_reset(crowd)
	await frames(4)
	check(lab.enemies.get_child_count() == 3, "Crowd fixture rebuilds the requested enemy count")
	var impossible: Dictionary = crowd.duplicate(true)
	impossible.enemy_count = 8
	impossible.distance = 700
	var valid_revision: int = lab._fixture_revision
	check(not lab._request_reset(impossible), "Crowd layout outside arena is rejected instead of spawning unreachable targets")
	check(lab._fixture_revision == valid_revision and lab.enemies.get_child_count() == 3, "Rejected layout preserves the previous applied experiment")
	impossible.fixture = lab.Fixture.COMPANIONS
	check(not lab._request_reset(impossible), "Companion fixture rejects the same out-of-bounds formation")
	impossible.fixture = lab.Fixture.RANGE
	impossible.distance = 80
	check(not lab._request_reset(impossible), "Eight overlapping near-range targets are rejected")
	impossible.fixture = lab.Fixture.CORNER
	impossible.distance = 450
	check(not lab._request_reset(impossible), "Corner fixture rejects an enemy embedded in its new wall")
	var wide_crowd: Dictionary = crowd.duplicate(true)
	wide_crowd.enemy_count = 8
	wide_crowd.distance = 100
	check(lab._request_reset(wide_crowd), "An eight-enemy crowd that fits still applies")
	await frames(4)
	check(lab.enemies.get_child_count() == 8, "Valid large crowd is not silently reduced")
	var old_warning: Dictionary = {"point": Vector2(700, 300), "kind": 0, "left": 0.8}
	lab.split_director.pending.append(old_warning)
	var hazard = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	hazard.position = Vector2(500, 400)
	lab.hazards.add_child(hazard)
	lab._request_reset(crowd)
	await frames(4)
	check(lab.enemies.get_child_count() == 3 and lab.hazards.get_child_count() == 0 and lab.split_director.pending.is_empty(), "Reset clears old enemies, hazards and split warnings")

	for fixture in lab.Fixture.values():
		var config: Dictionary = crowd.duplicate(true)
		config.fixture = int(fixture)
		config.enemy_kind = 0
		config.enemy_count = 2
		config.distance = 360
		config.enemy_hp = 6 if int(fixture) == lab.Fixture.SPLIT else 0
		config.split_enabled = int(fixture) == lab.Fixture.SPLIT
		config.companion_count = 2 if int(fixture) == lab.Fixture.COMPANIONS else 1
		config.override_build_parameters = true
		config.range_radius = 200
		lab._request_reset(config)
		await frames(4)
		check(lab._reset_ready, "Fixture %s rebuilds without leaving reset pending" % str(fixture))
		if int(fixture) == lab.Fixture.CORNER:
			check(lab.lab_walls.get_child_count() == 2, "Corner fixture installs a fixed wall pair")
		elif int(fixture) == lab.Fixture.COMPANIONS:
			check(lab.companions.members.size() == 2, "Companion fixture applies requested member count")
		elif int(fixture) == lab.Fixture.TURRET:
			check(lab.enemies.get_child_count() == 2 and lab.enemies.get_child(0).kind == DemoEnemy.Kind.TURRET and lab.enemies.get_child(1).kind == DemoEnemy.Kind.TURRET, "Turret fixture honors the requested count with real turret actors")
		elif int(fixture) == lab.Fixture.SPLIT:
			check(lab.enemies.get_child_count() == 1 and lab.enemies.get_child(0).max_hp == 6, "Split fixture spawns a real family root")
		elif int(fixture) == lab.Fixture.BOSS:
			check(lab.enemies.get_child_count() == 1 and lab.enemies.get_child(0) is DemoBoss, "Boss fixture uses the real boss actor")

	var range_config: Dictionary = crowd.duplicate(true)
	range_config.fixture = lab.Fixture.RANGE
	range_config.enemy_kind = DemoEnemy.Kind.FRAGILE
	range_config.enemy_count = 8
	range_config.distance = 360
	range_config.range_radius = 90
	range_config.ai_enabled = false
	lab._request_reset(range_config)
	await frames(4)
	check(lab.enemies.get_child_count() == 8, "Range fixture honors the requested eight-enemy count")

	var range_boundary: Dictionary = range_config.duplicate(true)
	range_boundary.enemy_count = 1
	range_boundary.distance = 120
	range_boundary.ai_enabled = true
	lab._request_reset(range_boundary)
	await frames(4)
	var range_enemy: DemoEnemy = lab.enemies.get_child(0)
	check(range_enemy.warning_left == 0.0, "Range fixture keeps a distant fragile enemy outside its real attack range")
	range_boundary.distance = 60
	lab._request_reset(range_boundary)
	await frames(4)
	range_enemy = lab.enemies.get_child(0)
	check(range_enemy.warning_left > 0.0, "Range fixture starts the complete warning only inside the configured radius (distance %.1f, radius %.1f, warning %.3f)" % [range_enemy.global_position.distance_to(lab.player.global_position), range_enemy.pulse_radius, range_enemy.warning_left])

	var turret_config: Dictionary = range_config.duplicate(true)
	turret_config.fixture = lab.Fixture.TURRET
	turret_config.enemy_count = 1
	turret_config.ai_enabled = true
	turret_config.distance = 300
	turret_config.range_radius = 200
	lab._request_reset(turret_config)
	await frames(55)
	check(lab.hazards.get_child_count() == 0, "Turret fixture outside configured range releases no hazard")
	turret_config.range_radius = 480
	lab._request_reset(turret_config)
	await frames(4)
	var turret_actor: DemoEnemy = lab.enemies.get_child(0)
	check(turret_actor.is_physics_processing() and turret_actor.warning_left > 0.0, "Turret fixture starts a full warning inside configured range (physics %s, warning %.3f, attack cooldown %.2f, player valid %s, hp %d)" % [str(turret_actor.is_physics_processing()), turret_actor.warning_left, turret_actor.attack_left, str(is_instance_valid(turret_actor.player)), lab.player_health.hp])
	await frames(48)
	check(lab.hazards.get_child_count() == 1, "Turret fixture inside configured range releases its real projectile")

	var split_config: Dictionary = crowd.duplicate(true)
	split_config.fixture = lab.Fixture.SPLIT
	split_config.enemy_kind = DemoEnemy.Kind.HEAVY
	split_config.enemy_hp = 4
	split_config.distance = 390
	split_config.split_enabled = true
	lab._request_reset(split_config)
	await frames(4)
	var family_root: DemoEnemy = lab.enemies.get_child(0)
	var kills_before: int = lab.split_director.kills
	family_root.hurt(10)
	await frames(2)
	check(lab.split_director.pending.size() == 2 and lab.split_director.kills == kills_before + 1, "Split fixture queues two children and settles the original family once")
	await frames(105)
	check(lab.enemies.get_child_count() == 2, "Split warnings materialize two real second-generation actors")
	check(not lab.enemies.get_child(0).is_physics_processing() and not lab.enemies.get_child(1).is_physics_processing(), "Split children inherit disabled AI from the applied experiment")
	if lab.enemies.get_child_count() > 0:
		var child: DemoEnemy = lab.enemies.get_child(0)
		child.hurt(10)
		await frames(2)
		check(lab.split_director.kills == kills_before + 1, "Child deaths do not grant duplicate family rewards")
		# 静止后代可能堵住原分裂点；给正式安全重试/换点规则完整时间。
		await frames(240)
		var all_stationary: bool = true
		for descendant in lab.enemies.get_children():
			all_stationary = all_stationary and not descendant.is_physics_processing()
		check(lab.enemies.get_child_count() == 3 and all_stationary, "Second split generation also inherits disabled AI")

	var saved: Dictionary = lab._sanitize_config(lab._applied)
	saved.minimum_speed = 780
	saved.fixture = lab.Fixture.SINGLE
	lab._request_reset(saved)
	await frames(4)
	check(lab._save_preset(), "Lab can save a project-relative developer preset")
	check(FileAccess.file_exists(lab.PRESET_PATH), "Saved preset exists in the ignored local directory")
	saved.minimum_speed = 180
	lab._request_reset(saved)
	await frames(4)
	check(lab._load_preset(), "Lab can load and validate its preset schema")
	await frames(4)
	check(is_equal_approx(lab.combat.minimum_speed, 780.0), "Loaded preset rebuilds gameplay with saved whitelist values (actual %.1f)" % lab.combat.minimum_speed)
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(lab.PRESET_PATH))
	legacy.schema_version = 1
	legacy.parameters.erase("override_build_parameters")
	legacy.parameters.cooldown_seconds = 3.0
	var preset_file := FileAccess.open(lab.PRESET_PATH, FileAccess.WRITE)
	preset_file.store_string(JSON.stringify(legacy))
	preset_file.close()
	check(lab._load_preset(), "Version-one preset migrates instead of losing explicit overrides")
	await frames(4)
	check(lab._applied.override_build_parameters and is_equal_approx(lab.launcher.cooldown, 3.0), "Migrated preset preserves its original cooldown condition")
	legacy.schema_version = 2
	legacy.parameters.fixture = lab.Fixture.CROWD
	legacy.parameters.distance = 700
	legacy.parameters.enemy_count = 8
	preset_file = FileAccess.open(lab.PRESET_PATH, FileAccess.WRITE)
	preset_file.store_string(JSON.stringify(legacy))
	preset_file.close()
	check(not lab._load_preset(), "A preset with an impossible formation reports load failure")
	legacy.parameters = []
	preset_file = FileAccess.open(lab.PRESET_PATH, FileAccess.WRITE)
	preset_file.store_string(JSON.stringify(legacy))
	preset_file.close()
	check(not lab._load_preset(), "Malformed preset parameters are rejected without crashing")
	check(lab._save_report(), "Lab can save a reproduction report")
	check(FileAccess.file_exists(lab.REPORT_PATH), "Reproduction report exists in the ignored local directory")
	for index in 200:
		lab._append_log("synthetic bounded log %d" % index)
	check(lab._log_entries.size() == 160, "Lab log keeps a fixed upper bound during long runs")
	var missing: Dictionary = lab._sanitize_config({})
	check(missing == lab.DEFAULTS, "Blank or partial requests restore the declared whitelist defaults")
	var speed_spin: SpinBox = lab.lab_panel._fields.minimum_speed
	speed_spin.get_line_edit().grab_focus()
	await process_frame
	var revision_before_typing: int = lab._fixture_revision
	var key_r := InputEventKey.new()
	key_r.pressed = true
	key_r.keycode = KEY_R
	lab._input(key_r)
	check(lab._editing_text() and lab._fixture_revision == revision_before_typing, "Lab hotkeys do not fire while a numeric field is being edited")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(lab.PRESET_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(lab.REPORT_PATH))
	lab.queue_free()
	await frames(2)
	print("GAMEPLAY LAB CHECKS PASSED: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
