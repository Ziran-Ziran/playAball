extends Node
## 大比例脸部/肩胸/发丝的实际渲染复验；技术读数不代替审美判断。
var checks: Array[Dictionary] = []
var prefix: String
var sample: Control
var inventory: Dictionary = {}

func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			prefix = arg.trim_prefix("--out=")
	_run.call_deferred()

func _check(ok: bool, description: String, evidence: Dictionary = {}) -> void:
	checks.append({"passed":ok,"description":description,"evidence":evidence})
	print("PASS " if ok else "FAIL ", description, " ", evidence)

func _settle(frames: int = 5) -> void:
	for frame in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _settle()
	get_tree().root.get_texture().get_image().save_png(prefix + "_" + name + ".png")

func _run() -> void:
	sample = load("res://tools/live2d_menu_sample/menu_sample.tscn").instantiate()
	add_child(sample)
	await _settle(20)
	var character: Node2D = sample.character
	for id: String in ["PositionX","PositionY","PositionZ","LeanInput","ParamBodyAngleX","ParamBodyAngleZ"]:
		if character.parameters.has(id):
			var parameter: Resource = character.parameters[id]
			inventory[id] = {"minimum":parameter.get("minimum_value"),"maximum":parameter.get("maximum_value"),"value":parameter.get("value")}
	_check(character.loaded,"Selected adult Live2D model loaded")
	_check(sample.has_method("set_closeup"),"Close-up mode is available for actual-size face inspection")
	if not sample.has_method("set_closeup"):
		_finish()
		return
	character.set_process(false)
	if "--idle-disabled-control" in OS.get_cmdline_user_args():
		character.idle_body_strength = 0.0
		character.body_input = Vector3.ZERO
	sample.set_closeup(true)
	await get_tree().create_timer(0.8).timeout
	_check(character.model.scale.x > sample.base_model_scale.x * 1.6,"Close-up enlarges actual model, keeps render sampling")
	character.set_pointer(Vector2.ZERO)
	for frame in 120:
		character.step_character(1.0/60.0)
	await _capture("front")
	var first_position: Vector2 = character.model.position
	var positions: Array[float] = []
	var torso_a: Dictionary = {}
	var torso_b: Dictionary = {}
	for frame in 300:
		character.step_character(1.0/60.0)
		positions.append(float(character.parameters.PositionX.get("value")))
		if frame == 30 or frame == 240:
			await _settle()
			if frame == 30:
				torso_a = _torso_vertices(character)
			else:
				torso_b = _torso_vertices(character)
	var input_span: float = positions.max() - positions.min()
	var squared: float = 0.0
	var count: int = 0
	for key: String in torso_a:
		if torso_b.has(key):
			squared += (float(torso_a[key]) - float(torso_b[key])) ** 2
			count += 1
	var torso_rms: float = sqrt(squared / maxf(count,1))
	_check(input_span > 0.02,"Neutral-pointer idle drives authored body input", {"input_span":input_span})
	# 桥接Resource中的输出值是缓存，物理会在其后更新；直接读取渲染网格证明变化。
	_check(torso_rms > 0.25,"Authored physics changes real torso mesh", {"torso_x_rms_pixels":torso_rms,"vertices":count})
	_check(character.model.position.is_equal_approx(first_position),"Idle never translates the whole model node")
	await _capture("idle_body")
	for direction: String in ["left","right"]:
		var stage_point: Vector2 = Vector2(40,155) if direction == "left" else Vector2(680,155)
		var logical_point: Vector2 = sample.portrait.position + stage_point / Vector2(720,720) * sample.portrait.size
		var event := InputEventMouseMotion.new()
		event.position = sample.get_viewport().get_screen_transform() * sample.get_global_transform_with_canvas() * logical_point
		Input.parse_input_event(event)
		await _settle()
		_check(character.pointer_target.x < -0.95 if direction == "left" else character.pointer_target.x > 0.95,"Zoomed actual input reaches " + direction)
		for frame in 90:
			character.step_character(1.0/60.0)
		_check(absf(float(character.parameters.AngleX.get("value"))) > 18.0,"Real head input turns " + direction)
		await _capture(direction)
	character.set_pointer(Vector2.ZERO)
	for frame in 120:
		character.step_character(1.0/60.0)
	_check(character.request_reaction("pet"),"Authored eye closure reaction starts")
	for frame in 10:
		character.step_character(1.0/60.0)
	await _capture("closed_eyes")
	_check(float(character.parameters.ParamEyeLOpen.get("value")) < 0.2 and float(character.parameters.ParamEyeROpen.get("value")) < 0.2,"Both real eyelid parameters close")
	for frame in 150:
		character.step_character(1.0/60.0)
	_check(character.request_reaction("greet"),"Authored hand gesture starts")
	for frame in 80:
		character.step_character(1.0/60.0)
	await _capture("gesture")
	_check(float(character.parameters.Movement2.get("value")) > 0.8,"Authored hand pose actually active")
	sample.set_closeup(false)
	await get_tree().create_timer(0.8).timeout
	_check(character.model.scale.distance_to(sample.base_model_scale) < 0.001,"Full-body view restores original scale")
	await _capture("full_body")
	_finish()

func _torso_vertices(character: Node2D) -> Dictionary:
	var result: Dictionary = {}
	var meshes: Dictionary = character.model.call("get_meshes")
	for key: Variant in meshes:
		var mesh: MeshInstance2D = meshes[key]
		if not mesh.visible or mesh.mesh.get_surface_count() == 0:
			continue
		var arrays: Array = mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
		for index in vertices.size():
			var point: Vector2 = mesh.get_global_transform() * vertices[index]
			if point.y > 260 and point.y < 475 and point.x > 240 and point.x < 475:
				result[str(key)+":"+str(index)] = point.x
	return result

func _finish() -> void:
	var failures: int = checks.filter(func(c: Dictionary) -> bool: return not c.passed).size()
	var file := FileAccess.open(prefix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failures,"body_parameter_ranges":inventory,"scope":"Local Live2D visual review only; no aesthetic approval, no full L0 or release-rights clearance"},"  "))
	file.close()
	print("LIVE2D VISUAL REVIEW ",checks.size()," failed=",failures)
	get_tree().quit(1 if failures else 0)
