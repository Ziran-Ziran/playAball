extends SceneTree
var failures: int = 0
var checks: int = 0
var events: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL ",label)
func frames(count: int) -> void:
	for index: int in count: await physics_frame
	await process_frame
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/ball_animation_review_"+label+".png")
func run() -> void:
	for id: String in ["hero","virus_low","virus_mid","virus_high"]:
		for frame in 4:
			var texture: Texture2D = DemoBallArt.animation_frame(id,frame)
			check(texture is AtlasTexture,id+" uses real sheet frame "+str(frame))
			var image: Image = texture.get_image()
			var region: Rect2 = DemoBallArt.region_for(texture)
			check(region.has_area() and region.end.x <= texture.get_width()+1 and region.end.y <= texture.get_height()+1,id+" cropped region stays inside frame")
			check(image.get_used_rect().has_area(),id+" frame contains alpha pixels")
			print("FRAME ",id," ",frame," texture=",texture.get_size()," used=",region)
	var grid := Node2D.new()
	root.add_child(grid)
	var row: int = 0
	for id: String in ["hero","virus_low","virus_mid","virus_high"]:
		for frame in 4:
			var sprite := Sprite2D.new()
			sprite.texture = DemoBallArt.animation_frame(id,frame)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.position = Vector2(150+frame*250,90+row*160)
			sprite.scale = Vector2.ONE*130.0/maxf(sprite.texture.get_width(),sprite.texture.get_height())
			grid.add_child(sprite)
		row += 1
	await process_frame
	await capture("atlas_grid")
	grid.free()
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	var director = game.director
	var player = game.player
	var view = player.get_node("Presentation")
	player.visual_event.connect(func(kind: StringName,_payload: Dictionary): events[kind] = int(events.get(kind,0))+1)
	var signature: Array = [player.mass,player.collision_layer,player.collision_mask,player.get_node("Shape").shape.radius,player.scale]
	director.health.reset_health()
	check(int(events.get(&"damage",0)) == 0,"health reset never emits damage")
	check(director.health.hurt(1),"actual health accepts effective damage")
	check(view._pose == 3 and int(events.get(&"damage",0)) == 1,"director effective damage drives real pain pose once")
	var pain_left: float = view._pose_left
	check(not director.health.hurt(1) and view._pose_left == pain_left and int(events.get(&"damage",0)) == 1,"invulnerability rejection never retriggers pain")
	await process_frame
	await capture("pain")
	director.health.hp += 1
	director.health.changed.emit(director.health.hp)
	check(int(events.get(&"damage",0)) == 1,"healing does not emit pain")
	director.register_kill(987654)
	var kills: int = int(events.get(&"kill",0))
	director.register_kill(987654)
	check(kills == 1 and int(events.get(&"kill",0)) == 1,"register_kill deduplicates actual kill reaction")
	check(view._launch_left > 0.0,"actual unique kill starts elastic response")
	var before: float = view._idle_clock
	var pose_before: float = view._pose_left
	paused = true
	await create_timer(0.12,true).timeout
	check(view._idle_clock == before and view._pose_left == pose_before,"aim pause freezes idle and pain clocks")
	paused = false
	await frames(25)
	player.reset_body(Vector2(640,350))
	await frames(3)
	check(view._pose_left == 0.0 and view._pose == -1,"body reset clears animation pose")
	# 使用真正物理墙接触，不伪造impacted事件。
	player.reset_body(Vector2(91,350))
	await frames(3)
	player.linear_velocity = Vector2(-700,0)
	var contact_seen: bool = false
	for index in 16:
		await frames(1)
		if int(events.get(&"contact",0)) > 0 or view._pose == 2:
			contact_seen = true
			break
	check(contact_seen and view._pose == 2,"real wall collision produces contact pose distinct from damage")
	await capture("contact")
	check(signature == [player.mass,player.collision_layer,player.collision_mask,player.get_node("Shape").shape.radius,player.scale],"animation does not alter physical shape mass or layers")
	var companion: DemoCompanion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	game.add_child(companion)
	companion.position = Vector2(500,350)
	companion.freeze = true
	var companion_view = companion.get_node("Presentation")
	await frames(3)
	var companion_scale: Vector2 = companion_view.get_node("Sprite").scale
	await create_timer(0.12).timeout
	check(companion_view.get_node("Sprite").scale != companion_scale,"companion idle has actual vertical elastic scale")
	var companion_clock: float = companion_view._idle_clock
	paused = true
	await create_timer(0.1,true).timeout
	check(companion_view._idle_clock == companion_clock,"companion elastic clock freezes under actual tree pause")
	paused = false
	var boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	game.add_child(boss)
	boss.position = Vector2(950,350)
	boss.freeze = true
	boss.set_physics_process(false)
	await frames(2)
	var boss_view = boss.get_node("Presentation")
	boss.hurt_at(1,boss.to_global(boss.get_node("Module0").position))
	check(boss_view.module_flash_left[0] > 0.0,"actual boss module damage starts its hit animation")
	boss.hurt(1)
	check(boss_view._flash > 0.0,"actual boss core damage starts atlas hit frame")
	await process_frame
	await capture("boss")
	var boss_clock: float = boss_view._idle_clock
	paused = true
	await create_timer(0.1,true).timeout
	check(boss_view._idle_clock == boss_clock,"boss animation clock freezes during actual tree pause")
	paused = false
	for index in 15:
		var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
		enemy.position = Vector2(250+index*35,460)
		enemy.hit_points_override = 3
		game.get_node("Enemies").add_child(enemy)
		enemy.set_physics_process(false)
		enemy.hurt(99)
	check(get_nodes_in_group("virus_bursts").size() == 12,"death burst concurrency bounded at twelve")
	await process_frame
	await capture("burst")
	var burst = get_nodes_in_group("virus_bursts")[0]
	var life: float = burst._life
	paused = true
	await create_timer(0.1,true).timeout
	check(burst._life == life,"death atlas animation freezes during pause")
	paused = false
	await create_timer(0.5).timeout
	check(get_nodes_in_group("virus_bursts").is_empty(),"death atlas animation frees after bounded lifetime")
	game.queue_free()
	await frames(4)
	print("BALL ANIMATION INDEPENDENT ",checks," checks failures ",failures)
	quit(1 if failures else 0)
