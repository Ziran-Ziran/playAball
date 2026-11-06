extends Node
## 真实模型、引擎输入分发和释放检查；不冒充真人试玩。
var report: Dictionary = {"checks": [], "scope":"engine input dispatch / real DeepSeek-chan / not human playtest"}
var sample: Control
var output: String = ""

func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	report.checks.append({"pass":condition,"description":description})
	if not condition: push_error(description)

func settle(frames: int = 4) -> void:
	for frame: int in frames: await get_tree().process_frame
	await RenderingServer.frame_post_draw

func send_mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	# parse_input_event 接收窗口像素；先应用拉伸，不能把逻辑画布坐标直接注入。
	event.position = sample.get_viewport().get_screen_transform() * sample.get_global_transform_with_canvas() * point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	await settle()

func send_motion(normalized: Vector2) -> void:
	var canvas_point: Vector2 = Vector2(360, 155) + normalized * Vector2(320, 300)
	var local_point: Vector2 = sample.portrait.position + canvas_point / 720.0 * sample.portrait.size
	var event := InputEventMouseMotion.new()
	event.position = sample.get_viewport().get_screen_transform() * sample.get_global_transform_with_canvas() * local_point
	Input.parse_input_event(event)
	await settle()

func head_vertices(character: Node2D) -> Dictionary:
	# 比较渲染用网格，而非桥接 Resource 的缓存参数；物理会在其后再次写参数。
	var points: Dictionary = {}
	var meshes: Dictionary = character.model.call("get_meshes")
	for key: Variant in meshes:
		var instance: MeshInstance2D = meshes[key]
		if not instance.visible or instance.mesh.get_surface_count() == 0: continue
		var arrays: Array = instance.mesh.surface_get_arrays(0)
		var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
		var selected: Dictionary = {}
		for index: int in vertices.size():
			var point: Vector2 = instance.get_global_transform() * Vector2(vertices[index].x, vertices[index].y)
			if point.y > 80 and point.y < 230: selected[index] = point
		if not selected.is_empty(): points[key] = selected
	return points

func mesh_motion(before: Dictionary, after: Dictionary) -> Dictionary:
	var squared: float = 0.0
	var count: int = 0
	var maximum: float = 0.0
	for key: Variant in before:
		if not after.has(key): continue
		for index: Variant in before[key]:
			if not after[key].has(index): continue
			var distance: float = (before[key][index] as Vector2).distance_to(after[key][index])
			squared += distance * distance
			maximum = maxf(maximum, distance)
			count += 1
	return {"vertex_count": count, "rms_pixels": sqrt(squared / maxi(count, 1)), "max_pixels": maximum}

func _run() -> void:
	report.engine = Engine.get_version_info().string
	report.renderer = RenderingServer.get_current_rendering_method()
	report.editor_binary = OS.has_feature("editor")
	report.window_size = str(get_window().size)
	report.screen_transform = str(get_viewport().get_screen_transform())
	sample = load("res://tools/live2d_menu_sample/menu_sample.tscn").instantiate()
	get_tree().root.add_child(sample)
	await settle(15)
	var character: Node2D = sample.character
	check(character.loaded, "Selected DeepSeek-chan model loaded")
	if not character.loaded:
		finish()
		return
	character.set_process(false)
	for id: String in ["ParamAngleX", "ParamAngleY", "ParamEyeBallX", "ParamEyeBallY", "ParamEyeLOpen", "ParamEyeROpen"]:
		check(character.parameters.has(id), "Real model parameter: " + id)
	report.parameter_count = character.parameters.size()
	report.motions = character.model.call("get_motions")
	report.expressions = character.model.call("get_expressions")
	await send_motion(Vector2(1, 0.4))
	check(character.pointer_target.distance_to(Vector2(1, 0.4)) < 0.02, "Engine mouse motion reaches character follow target")
	character.step_character(0.1)
	check(character.eye_target.x > character.head_target.x and character.head_target.x > 0, "Eyes notice cursor before head follows")
	for frame: int in 90: character.step_character(1.0 / 60.0)
	check(float(character.parameters.AngleX.get("value")) > 15.0, "Follow drives author's AngleX input rather than physics output")
	var right_mesh: Dictionary = head_vertices(character)
	await settle()
	check(sample.stage.get_texture().get_image().save_png(output + "_look_right.png") == OK, "Captured actual physics-enabled right turn")
	character.set_pointer(Vector2(99, -99))
	check(character.pointer_target == Vector2(1, -1), "Pointer target clamped at window extremes")
	await send_motion(Vector2(-1, 0))
	for frame: int in 90: character.step_character(1.0 / 60.0)
	check(float(character.parameters.AngleX.get("value")) < -15.0, "Head input follows continuously in opposite direction")
	report.head_geometry = mesh_motion(right_mesh, head_vertices(character))
	check(report.head_geometry.vertex_count > 100 and report.head_geometry.rms_pixels > 1.0, "Physics-enabled head render geometry visibly changes between left/right")
	await settle()
	check(sample.stage.get_texture().get_image().save_png(output + "_look_left.png") == OK, "Captured actual physics-enabled left turn")
	var first_mesh: MeshInstance2D = character.model.call("get_meshes").values()[0]
	var atlas: Texture2D = (first_mesh.material as ShaderMaterial).get_shader_parameter("tex_main")
	check(atlas.get_image().has_mipmaps(), "4096 atlas has real mip levels for minification")
	sample.show_settings(true)
	check(not character.request_reaction("cheek"), "Settings reject character interaction")
	for frame: int in 90: character.step_character(1.0 / 60.0)
	check(absf(float(character.parameters.AngleX.get("value"))) < 1, "Settings return gaze input to neutral")
	sample.show_settings(false)
	check(character.request_reaction("cheek"), "First reaction accepted")
	check(not character.request_reaction("cheek"), "Repeated click does not restart active reaction")
	check(character.request_reaction("cheek") and character.state == "annoyed", "Rapid third click escalates to annoyed")
	check(not character.request_reaction("cheek"), "Annoyed response cannot be restarted each click")
	for frame: int in 160: character.step_character(1.0 / 60.0)
	check(character.state == "idle", "Reaction returns to idle automatically")
	check(character.request_reaction("pet"), "Pet reaction accepted after recovery")
	character.step_character(0.05)
	check(float(character.parameters.ParamEyeLOpen.get("value")) < 0.2, "Pet uses real eyelid parameter")
	for frame: int in 160: character.step_character(1.0 / 60.0)
	check(character.request_reaction("greet"), "Author hand gesture accepted")
	for frame: int in 80: character.step_character(1.0 / 60.0)
	var raised: float = float(character.parameters.Movement2.get("value"))
	check(raised > 0.8, "Author motion actually raises hand parameter")
	await settle()
	check(sample.stage.get_texture().get_image().save_png(output + "_greet.png") == OK, "Captured author hand gesture")
	for frame: int in 160: character.step_character(1.0 / 60.0)
	check(character.state == "idle", "Hand gesture and return finish in idle")
	check(float(character.parameters.Movement2.get("value")) < 0.1, "Return motion restores hand instead of leaving it raised")
	check(float(character.parameters.Clothes2.get("value")) < 0.1, "Original adult body proportions remain unchanged")
	character.set_reduced_motion(true)
	check(not bool(character.model.get("physics_evaluate")), "Reduced motion disables secondary physics")
	character.set_pointer(Vector2.ONE)
	for frame: int in 90: character.step_character(1.0 / 60.0)
	check(float(character.parameters.AngleX.get("value")) < 7.0, "Reduced motion limits head movement")
	character.set_reduced_motion(false)
	check(bool(character.model.get("physics_evaluate")), "Normal secondary physics can be restored")
	check(character.request_reaction("cheek", 1.0), "Cheek reaction accepted")
	character.step_character(0.15)
	check(float(character.parameters.CheeckPuff.get("value")) > 0.3, "Cheek uses authored puff input parameter")
	await settle()
	check(sample.stage.get_texture().get_image().save_png(output + "_cheek.png") == OK, "Captured authored cheek deformation")
	for frame: int in 160: character.step_character(1.0 / 60.0)
	check(absf(float(character.parameters.CheeckPuff.get("value"))) < 0.01, "Cheek puff returns to neutral")
	await settle()
	var pixels: Image = sample.stage.get_texture().get_image()
	var hit: Vector2i = Vector2i(-1, -1)
	var pixel_scale: int = pixels.get_width() / 720
	for y: int in range(100 * pixel_scale, 550 * pixel_scale, 4 * pixel_scale):
		if hit.x >= 0: break
		for x: int in range(240 * pixel_scale, 480 * pixel_scale, 4 * pixel_scale):
			if pixels.get_pixel(x,y).a > 0.85:
				hit = Vector2i(x,y)
				break
	check(hit.x >= 0, "Actual render contains visible character pixels")
	var click_point: Vector2 = sample.portrait.position + Vector2(hit) / Vector2(pixels.get_size()) * sample.portrait.size
	check(sample.hits_character(click_point), "Visible character accepts alpha hit")
	check(not sample.hits_character(sample.portrait.position + Vector2(2, 2)), "Transparent corner rejects hit")
	var before: int = character.reaction_count
	await send_mouse(click_point, true)
	await send_mouse(click_point, false)
	check(character.reaction_count == before + 1, "Engine mouse press/release triggers exactly one reaction")
	sample.show_settings(true)
	before = character.reaction_count
	await send_mouse(click_point, true)
	await send_mouse(click_point, false)
	check(character.reaction_count == before, "Modal intercepts dispatched mouse input")
	sample.show_settings(false)
	report.capture = output + "_menu.png"
	check(get_tree().root.get_texture().get_image().save_png(str(report.capture)) == OK, "Saved real menu screenshot")
	var reference: WeakRef = character.release_character()
	await settle(10)
	check(reference.get_ref() == null, "Model releases after UI teardown request")
	sample.queue_free()
	await settle(5)
	finish()

func finish() -> void:
	report.failures = (report.checks as Array).filter(func(c: Dictionary) -> bool: return not c["pass"]).size()
	var file := FileAccess.open(output + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("DEEPSEEK_SAMPLE_RESULT ", report.checks.size(), " / ", report.failures)
	get_tree().quit(int(report.failures))
