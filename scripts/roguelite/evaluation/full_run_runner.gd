extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass a full-run JSON config")
		quit(1)
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var output: String = config.output
	DirAccess.make_dir_recursive_absolute(output)
	var rows: Array[Dictionary] = []
	var profile: Resource = load(config.profile)
	for route: String in config.routes:
		for seed_value: int in config.seeds:
			var game = load("res://scenes/ui/game.tscn").instantiate()
			game.get_node("RunDirector").run_seed = seed_value
			root.add_child(game)
			current_scene = game
			game.feedback.sound_enabled = false
			var agent = load("res://scripts/roguelite/evaluation/full_run_agent.gd").new()
			game.add_child(agent)
			agent.bind(game, profile, route)
			var start: int = Time.get_ticks_usec()
			var steps: int = ceili(float(config.max_seconds) * Engine.physics_ticks_per_second)
			var samples: Array[Dictionary] = []
			var outcome: String = "censored"
			var completed_steps: int = 0
			var previous_state: int = -1
			for tick in steps:
				if game.director.state != previous_state:
					print("AGENT STATE t=", tick / 120.0, " state=", game.director.state, " wave=", game.director.wave)
					previous_state = game.director.state
				# 正式发射在物理步前；菜单由Agent正常_process处理，不能延后恢复暂停。
				if game.director.state == game.director.State.BATTLE:
					agent.drive(tick / float(Engine.physics_ticks_per_second), 1.0 / Engine.physics_ticks_per_second)
				else:
					agent.elapsed = tick / float(Engine.physics_ticks_per_second)
				await physics_frame
				completed_steps = tick + 1
				if tick % 60 == 0: samples.append({"time": agent.elapsed, "wave": game.director.wave, "map": game.director.maps.definition.map_id, "hp": game.director.health.hp, "position": [game.player.position.x, game.player.position.y], "kills": game.director.kills})
				if game.director.state == game.director.State.VICTORY:
					outcome = "victory"
					break
				if game.director.state == game.director.State.DEFEAT:
					outcome = "death"
					break
			agent.poll_boss_damage()
			var row: Dictionary = {"profile": profile.snapshot(), "route": route, "strategy": agent.policy.strategy, "seed": seed_value, "outcome": outcome, "seconds": agent.elapsed, "battle_seconds": agent.battle_seconds, "physics_steps": completed_steps, "physics_hz": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale, "wave": game.director.wave, "kills": game.director.kills, "hp": game.director.health.hp, "hp_lost": agent.hp_lost, "effective_damage": agent.effective_damage, "module_damage": agent.module_damage, "input_attempts": agent.metrics.input_attempts, "shots": game.launcher.shots, "build": game.director.build.levels.duplicate(), "wall_seconds": (Time.get_ticks_usec() - start) / 1000000.0, "normal_ai": true, "forced_clear_or_health": false}
			var file := FileAccess.open("%s/%s-%d.json" % [output, route, seed_value], FileAccess.WRITE)
			file.store_string(JSON.stringify({"summary": row, "recoveries": agent.recoveries, "choices": agent.choices, "stage_events": agent.stage_events, "events": agent.metrics.raw, "samples": samples}))
			file.close()
			rows.append(row)
			print("FULL RUN ", profile.profile_id, " ", route, " seed=", seed_value, " ", outcome, " wave=", row.wave, " kills=", row.kills, " simulated=", row.seconds, " wall=", row.wall_seconds)
			paused = false
			game.queue_free()
			await process_frame
			await physics_frame
	var summary := FileAccess.open(output + "/summary.json", FileAccess.WRITE)
	summary.store_string(JSON.stringify({"config": config, "rows": rows, "version": "full_agent_v3"}))
	summary.close()
	print("NATURAL FULL RUN MATRIX COMPLETE: ", rows.size())
	quit(0)
