extends SceneTree
## 运行独立真实物理矩阵；关闭渲染可提速，但物理步长和time_scale保持项目值。
const VERSION: String = "evaluation_v4_partner_attribution"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Usage: --script scenario_runner.gd -- config.json")
		quit(1)
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if config.is_empty() or Engine.physics_ticks_per_second != 120 or Engine.time_scale != 1.0:
		push_error("Evaluation requires explicit config and unchanged120Hz/time_scale1")
		quit(1)
		return
	var profile: Resource = load(config.profile)
	var output: String = config.output
	DirAccess.make_dir_recursive_absolute(output)
	var results: Array[Dictionary] = []
	var total_start: int = Time.get_ticks_usec()
	for scenario: String in config.scenarios:
		for strategy: String in config.strategies:
			for rng_seed: int in config.seeds:
				var fixture = load("res://scripts/roguelite/evaluation/evaluation_fixture.gd").new()
				root.add_child(fixture)
				fixture.configure(scenario, rng_seed, PackedStringArray(config.get("build_ids", [])))
				profile.apply(fixture)
				for warmup in 4:
					await physics_frame
				await process_frame
				fixture.begin_measurement()
				var policy = load("res://scripts/roguelite/evaluation/input_policy.gd").new()
				policy.strategy = strategy
				var start: int = Time.get_ticks_usec()
				var seconds: float = float(config.seconds)
				var steps: int = ceili(seconds * Engine.physics_ticks_per_second)
				for tick in steps:
					policy.update(fixture, tick / float(Engine.physics_ticks_per_second), 1.0 / Engine.physics_ticks_per_second)
					await physics_frame
				await process_frame
				var row: Dictionary = fixture.metrics.summary()
				row.scenario = scenario
				row.build_ids = config.get("build_ids", [])
				row.strategy = strategy
				row.seed = rng_seed
				row.profile = profile.snapshot()
				row.applied = {"impulse": fixture.player.max_impulse, "opposing_cancel": fixture.player.cancel_opposing_momentum, "cooldown": fixture.launcher.cooldown,"transfer_retention":fixture.combat.transfer_retention}
				row.wall_seconds = (Time.get_ticks_usec() - start) / 1000000.0
				row.physics_steps = steps
				row.physics_hz = Engine.physics_ticks_per_second
				row.time_scale = Engine.time_scale
				row.evaluation_version = VERSION
				row.source_id = config.get("source_id", "local_probe")
				var filename: String = "%s/%s-%s-%d.json" % [output, scenario, strategy, rng_seed]
				write_json(filename, {"summary": row, "events": fixture.metrics.raw, "samples": fixture.metrics.samples})
				results.append(row)
				write_json(output + "/progress.json", {"completed": results.size(), "last": filename, "profile": profile.profile_id})
				print("TRIAL ", profile.profile_id, " ", scenario, " ", strategy, " ", rng_seed, " damage=", row.effective_damage, " kills=", row.kills, " wall=", row.wall_seconds, " simulated=", row.seconds)
				fixture.queue_free()
				await process_frame
				await physics_frame
	write_json(output + "/summary.json", {"config": config, "version": VERSION, "wall_seconds": (Time.get_ticks_usec() - total_start) / 1000000.0, "rows": results})
	print("BALANCE MATRIX COMPLETE: ", results.size(), " trials")
	quit(0)
func write_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write evaluation result: " + path)
		quit(1)
		return
	file.store_string(JSON.stringify(data))
	file.close()
