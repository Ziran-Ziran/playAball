extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://scenes/roguelite/presentation/fish_ball_view.tscn"):
		push_error("Independent generated fish sprite scene missing")
		quit(1)
		return
	var player = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	root.add_child(player)
	player.freeze = true
	await process_frame
	var view: Node2D = player.get_node("Presentation")
	var before: Array = [player.mass, player.collision_layer, player.collision_mask, player.get_node("Shape").shape.radius, player.scale]
	player.visual_event.emit(&"damage", {"speed": 900.0, "amount": 3})
	await process_frame
	assert(view.get_node("Sprite").texture != null)
	assert(view.get_node("Sprite").scale.x != view.get_node("Sprite").scale.y)
	assert(before == [player.mass, player.collision_layer, player.collision_mask, player.get_node("Shape").shape.radius, player.scale])
	player.well_fed = true
	await process_frame
	assert(player.presentation_snapshot().well_fed)
	player.queue_free()
	await process_frame
	var enemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	root.add_child(enemy)
	if not enemy.presentation.has_method("material_for_kind"):
		push_error("Enemy views must expose the actual generated material used for each kind")
		quit(1)
		return
	enemy.set_physics_process(false)
	enemy.hurt(9)
	var floats: Array[Node] = get_nodes_in_group("demo_combat_floats")
	assert(floats.any(func(node): return node.effect == &"damage" and node.amount == 1))
	assert(floats.any(func(node): return node.effect == &"death"))
	await create_timer(0.45).timeout
	assert(get_nodes_in_group("demo_combat_floats").is_empty())
	for kind in [DemoEnemy.Kind.FRAGILE,DemoEnemy.Kind.HEAVY,DemoEnemy.Kind.TURRET]:
		var actor = load("res://scenes/roguelite/enemy.tscn").instantiate()
		actor.kind=kind
		actor.hit_points_override=6
		root.add_child(actor)
		actor.freeze=true
		actor.set_physics_process(false)
		var signature: Array=[actor.mass,actor.collision_layer,actor.collision_mask,actor.get_node("Shape").shape.radius,actor.scale]
		var art: Texture2D=actor.presentation.material_for_kind(kind)
		# 夹具出生HP为6，三种角色都应使用精英病毒身份，角色差异由喷口/铆钉表达。
		var expected_file: String="virus_high.png"
		assert(art!=null and art.resource_path.ends_with(expected_file))
		if not actor.presentation.has_method("material_region_for_kind"):
			push_error("Imported sprite crop must use runtime texture dimensions, not raw PNG pixels")
			quit(1)
			return
		var region: Rect2=actor.presentation.material_region_for_kind(kind)
		assert(region.position.x>=0 and region.position.y>=0 and region.end.x<=art.get_width() and region.end.y<=art.get_height())
		actor.hurt(1)
		await process_frame
		await process_frame
		assert(signature==[actor.mass,actor.collision_layer,actor.collision_mask,actor.get_node("Shape").shape.radius,actor.scale])
		actor.queue_free()
	await create_timer(0.4).timeout
	print("FISH VIEW CHECKS PASSED")
	quit()
