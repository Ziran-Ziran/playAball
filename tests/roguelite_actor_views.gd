extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for name in ["companion","boss"]:
		if not ResourceLoader.exists("res://scenes/roguelite/presentation/%s_view.tscn"%name):
			push_error("Missing independent actor view: "+name)
			quit(1)
			return
	var companion = load("res://scenes/roguelite/companion_ball.tscn").instantiate()
	root.add_child(companion)
	companion.freeze = true
	var before: Array = [companion.mass,companion.collision_layer,companion.collision_mask,companion.get_node("Shape").shape.radius,companion.scale]
	await process_frame
	assert(companion.get_node("Presentation/Sprite").texture != null)
	assert(companion.presentation_snapshot().mode == 0)
	companion.mode = 1
	await process_frame
	assert(companion.get_node("Presentation").snapshot().mode == 1)
	assert(before == [companion.mass,companion.collision_layer,companion.collision_mask,companion.get_node("Shape").shape.radius,companion.scale])
	companion.queue_free()
	var boss = load("res://scenes/roguelite/boss.tscn").instantiate()
	root.add_child(boss)
	boss.freeze = true
	boss.set_physics_process(false)
	var boss_before: Array = [boss.mass,boss.collision_layer,boss.collision_mask,boss.get_node("Core").shape.radius,boss.get_node("Module0").position,boss.scale]
	var view: Node2D=boss.get_node("Presentation")
	if not view.has_method("armor_material_region"):
		push_error("Boss armor material must use actual imported dimensions")
		quit(1)
		return
	var armor: Texture2D=view.ARMOR_ART
	var region: Rect2=view.armor_material_region()
	assert(region.position.x>=0 and region.position.y>=0 and region.end.x<=armor.get_width() and region.end.y<=armor.get_height())
	assert(armor.get_image().get_pixelv(Vector2i(region.get_center())).a>0.9)
	var events: Array[StringName] = []
	boss.presentation_event.connect(func(event: StringName,_payload: Dictionary):events.append(event))
	for phase in 4:
		boss.phase = phase
		boss.phase_left=0.001
		await process_frame
		assert(boss.get_node("Presentation").snapshot().phase == phase)
		var title: Label=boss.get_node("Presentation/Status/Label")
		if phase in [0,2] and not title.text.contains("0.1秒"):
			push_error("Active warning/exposure must show its real final tenth without false zero")
			quit(1)
			return
		if phase in [1,3]:assert(not title.text.contains("秒"))
		var font: Font=title.get_theme_font("font")
		for line: String in title.text.split("\n"):
			assert(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,title.get_theme_font_size("font_size")).x<=title.size.x)
	assert(boss.get_node("Presentation/Status/Label").get_global_rect().end.y < 125)
	var isolated: Dictionary = boss.presentation_snapshot()
	isolated.modules[0].hp = 999
	assert(boss.module_hp[0] == boss.module_hit_points)
	boss.phase = boss.Phase.EXPOSED
	boss.hurt_at(1,boss.to_global(boss.get_node("Module0").position))
	assert(events.has(&"module_hurt"))
	if view._flash>0.0:
		push_error("A module hit must never flash the untouched boss core")
		quit(1)
		return
	assert(view.module_flash_left[0]>0.0 and view.module_flash_left[1]==0.0)
	await create_timer(0.15).timeout
	boss.hurt(2)
	assert(events.has(&"core_hurt"))
	assert(view._flash>0.0 and view.module_flash_left[0]==0.0)
	boss.hurt_at(9,boss.to_global(boss.get_node("Module0").position))
	assert(boss.module_hp[0]==0 and view.module_break_left[0]>0.0)
	assert(view.snapshot().modules.size()==4)
	assert(boss_before == [boss.mass,boss.collision_layer,boss.collision_mask,boss.get_node("Core").shape.radius,boss.get_node("Module0").position,boss.scale])
	boss.queue_free()
	await create_timer(0.4).timeout
	print("ACTOR VIEW CHECKS PASSED")
	quit()
