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
func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame
func run() -> void:
	check(ResourceLoader.exists("res://scripts/roguelite/presentation/ball_art.gd"), "Generated ball art catalog exists")
	if failures:
		print("BALL ART CHECKS: %d failures: %d" % [checks, failures])
		quit(1)
		return
	var art = load("res://scripts/roguelite/presentation/ball_art.gd")
	for id: String in ["hero", "gpt", "claude", "qwen", "virus_low", "virus_mid", "virus_high"]:
		var texture: Texture2D = art.texture_for(id)
		check(texture != null, "Generated texture exists: " + id)
		var image: Image = texture.get_image()
		check(image.get_pixel(0, 0).a < 0.01 and image.get_pixel(image.get_width()-1,image.get_height()-1).a < 0.01, "Sprite has real alpha: " + id)
		var region: Rect2 = art.region_for(texture)
		check(region.has_area() and region.position.x >= 0 and region.position.y >= 0 and region.end.x <= texture.get_width() and region.end.y <= texture.get_height(), "Imported crop stays inside runtime texture")
	var companion_paths: Array[String] = []
	for slot in 3:
		var companion: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
		companion.slot = slot
		root.add_child(companion)
		companion.freeze = true
		await frames(2)
		companion_paths.append(companion.get_node("Presentation/Sprite").texture.resource_path)
		check(companion.get_node("Shape").shape.radius == 14.0 and companion.scale == Vector2.ONE and is_equal_approx(companion.mass,0.65), "Companion skin leaves physics unchanged")
		companion.queue_free()
		await frames(2)
	check(companion_paths[0] != companion_paths[1] and companion_paths[1] != companion_paths[2] and companion_paths[0] != companion_paths[2], "Three companion slots have stable distinct AI identities")
	for max_hp in [1, 3, 6]:
		for kind in [DemoEnemy.Kind.FRAGILE, DemoEnemy.Kind.HEAVY, DemoEnemy.Kind.TURRET]:
			var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
			enemy.kind = kind
			enemy.hit_points_override = max_hp
			root.add_child(enemy)
			enemy.freeze = true
			enemy.set_physics_process(false)
			await frames(2)
			var view: Node2D = enemy.get_node("Presentation")
			var signature: Array = [enemy.mass,enemy.collision_layer,enemy.collision_mask,enemy.get_node("Shape").shape.radius,enemy.scale]
			check(view.material_for_kind(kind) == art.texture_for(art.enemy_id(max_hp)), "Enemy skin follows its spawn tier across all roles")
			var before: Texture2D = view.material_for_kind(kind)
			if max_hp > 1:
				enemy.hurt(1)
				await frames(2)
				check(view.material_for_kind(kind) == before, "Damage retains enemy spawn identity")
			check(signature == [enemy.mass,enemy.collision_layer,enemy.collision_mask,enemy.get_node("Shape").shape.radius,enemy.scale], "Virus art leaves role collision and mass unchanged")
			enemy.queue_free()
			await frames(2)
	await create_timer(0.5).timeout
	await check_battle_effect_pause()
	print("BALL ART CHECKS: %d failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check_battle_effect_pause() -> void:
	# 模拟正式Run的ALWAYS父节点，不能在默认暂停父节点下漏掉继承模式问题。
	var holder := Node2D.new()
	holder.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(holder)
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	holder.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.hurt(99)
	await process_frame
	var bursts: Array[Node] = get_nodes_in_group("virus_bursts")
	var floats: Array[Node] = get_nodes_in_group("demo_combat_floats")
	check(bursts.size() == 1 and not floats.is_empty(), "Actual death produces bounded battle effects")
	var life: float = bursts[0]._life
	var age: float = floats[0].age
	paused = true
	await create_timer(0.1,true).timeout
	check(is_equal_approx(bursts[0]._life,life) and is_equal_approx(floats[0].age,age), "All battle particles and damage floats freeze under ALWAYS parent")
	paused = false
	await create_timer(0.5).timeout
	check(get_nodes_in_group("virus_bursts").is_empty() and get_nodes_in_group("demo_combat_floats").is_empty(), "Resumed effects clean up after actual lifetime")
	holder.queue_free()
	await process_frame
