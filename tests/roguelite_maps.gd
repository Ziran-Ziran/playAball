extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func run() -> void:
	# 导出会重新打包实例；未声明可编辑的实例子节点在源码可见，却会被打包丢弃。
	var nested_paths: Dictionary={
		"map_01":["LeftPaddle/Shape","UpperPaddle/Paddle/Shape","LowerPaddle/Paddle/Shape"],
		"map_02":["CrossPivot/Paddle/VerticalShape","CrossPivot/Paddle/VisualVertical"],
		"map_03":["MovingLeft/Body/MovingLeftSpikes","MovingRight/Body/MovingRightSpikes"],
		"boss_map":["InnerRing/Body/InnerSpikes0","InnerRing/Body/InnerSpikes1","InnerRing/Body/InnerSpikes2","InnerRing/Body/InnerSpikes3","GreenPortals/A","YellowPortals/B"]}
	for id: String in nested_paths:
		var original: Node=load("res://scenes/roguelite/maps/%s.tscn"%id).instantiate()
		var packed:=PackedScene.new()
		check(packed.pack(original)==OK,"Map can be repacked: "+id)
		var restored: Node=packed.instantiate()
		for path: String in nested_paths[id]:
			check(restored.has_node(path),"Repacking retains nested physical/visual mechanism: "+id+"/"+path)
			if restored.has_node(path) and original.get_node(path) is Area2D:
				check(original.get_node(path+"/Shape").shape.size==restored.get_node(path+"/Shape").shape.size,"Repacking retains authored spike collision dimensions: "+path)
		if id=="map_03":
			check(restored.get_node("Portals/A").position==Vector2(-500,0) and restored.get_node("Portals/B").position==Vector2(500,0),"Repacking preserves portal endpoint overrides")
		if id=="boss_map":
			check(restored.get_node("GreenPortals/A").position==Vector2(0,-115) and restored.get_node("GreenPortals/B").position==Vector2(0,115),"Repacking preserves vertical green portal pairing")
			check(restored.get_node("YellowPortals/A").position==Vector2(-115,0) and restored.get_node("YellowPortals/B").position==Vector2(115,0),"Repacking preserves horizontal yellow portal pairing")
			check(restored.get_node("GreenPortals").a_color==restored.get_node("GreenPortals").b_color and restored.get_node("GreenPortals").a_color!=restored.get_node("YellowPortals").a_color,"Repacking preserves same-color pair identification")
		for spike: Node in original.find_children("*","Area2D",true,false):
			if spike.has_method("_currently_touching_player"):
				var restored_spike: Node = restored.get_node(original.get_path_to(spike))
				check(restored_spike.get_node("Shape").shape.size==Vector2(spike.length,spike.tooth_depth+5.0),"Repacking retains visible spike dimensions: "+str(spike.name))
		original.free()
		restored.free()
	if failures:
		quit(1)
		return
	# 原主球位置会落在新首领图尖刺附近；复位后缓存重叠不得远程扣血。
	var entry_game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(entry_game)
	entry_game.director.set_process(false)
	entry_game.director.debug_build(PackedStringArray(["companion","companion","companion","follow"]))
	entry_game.director.debug_wave(6)
	for tick in 12:
		await physics_frame
		await process_frame
	check(entry_game.director.health.hp == 5,"Fresh boss map entry never damages the safely relocated player through stale spike overlap")
	entry_game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	check(ResourceLoader.exists("res://scripts/roguelite/maps/map_controller.gd"), "Map controller interface exists")
	for name in ["map_01", "map_02", "map_03", "boss_map"]:
		check(ResourceLoader.exists("res://scenes/roguelite/maps/%s.tscn" % name), "Full-run map scene exists: " + name)
	if failures:
		quit(1)
		return
	var game = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	var maps = game.director.maps
	check(maps.definition.map_id == "map_01", "Formal run starts on the first physical map")
	check(maps.definition.bounds.has_point(game.player.position), "Player starts inside declared combat bounds")
	check(maps.obstacles().size() >= 4, "Map obstacles are discoverable without fixed visual assumptions")
	check(not maps.point_safe(Vector2(45, 130), 23.0), "Safety query accounts for body radius at boundary")
	var excluded: Array[RID] = [game.player.get_rid()]
	check(maps.point_safe(maps.definition.player_spawn, 23.0, excluded), "Declared player spawn is physically safe")
	check(maps.definition.enemy_entrances.size() == 4, "Definition exposes enemy entrances")
	check(maps.find_safe_point(Vector2(220, 400), 23.0, excluded).is_finite(), "Occupied preferred position can find a nearby safe point")
	game.director.set_process(false)
	game.director.wallet.balance = 17
	game.director.health.hp = 3
	game.director.debug_build(PackedStringArray(["companion", "heavy"]))
	game.player.request_debug_state("global_position", Vector2(1500, 900))
	for tick in 5:
		await physics_frame
		await process_frame
	check(maps.definition.bounds.has_point(game.player.position), "Player out-of-bounds recovery uses a typed map-safety exclusion array")
	game.companions.members[0].request_debug_state("global_position", Vector2(1500, 900))
	for tick in 5:
		await physics_frame
		await process_frame
	check(maps.definition.bounds.has_point(game.companions.members[0].position), "Companion out-of-bounds recovery safely returns through physics interface")
	for wave: int in [2, 3, 4, 5, 6]:
		game.director.debug_wave(wave)
		for tick in 4:
			await physics_frame
		await process_frame
		var expected: String = "map_01" if wave <= 2 else ("map_02" if wave <= 4 else ("map_03" if wave == 5 else "boss_map"))
		check(maps.definition.map_id == expected, "Wave %d selects %s" % [wave, expected])
		check(game.director.wallet.balance == 17 and game.director.health.hp == 3 and game.director.build.has_upgrade("heavy"), "Map transition preserves economy, health and build")
		check(game.companions.members.size() == 1, "Map transition retains exactly the earned companion")
		check(maps.point_safe(game.player.position, 23.0, excluded), "Map transition places player outside walls and spikes")
		check(game.get_tree().get_nodes_in_group("active_run_map").size() == 1, "Old map is removed before replacement")
		if wave == 6:
			check(game.director.boss != null and game.director.boss.position.distance_to(maps.definition.boss_spawn) < 3.0, "Boss uses independent map spawn")
	game.director.restart()
	await physics_frame
	await physics_frame
	check(maps.definition.map_id == "map_01" and game.companions.members.is_empty() and game.director.health.hp == 5, "Restart restores first map, zero companions and base health")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("MAP CHECKS PASSED: ", checks) if failures == 0 else print("MAP FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
