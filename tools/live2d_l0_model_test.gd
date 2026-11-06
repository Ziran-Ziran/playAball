extends Node2D
## L0真实模型测试夹具；只运行在.local，不参与正式游戏。
var output_prefix: String = "user://live2d_l0"
var cycle_count: int = 40
var stage: SubViewport
var report: Dictionary = {"checks": [], "cycles": [], "scope": "Haru sample only"}

func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output_prefix = argument.trim_prefix("--out=").trim_suffix(".json")
		if argument.begins_with("--cycles="):
			cycle_count = clampi(int(argument.trim_prefix("--cycles=")), 1, 200)
	_run.call_deferred()

func record(condition: bool, description: String) -> void:
	report.checks.append({"pass": condition, "description": description})
	if not condition:
		push_error(description)

func make_model() -> Node2D:
	var model: Node2D = ClassDB.instantiate("GDCubismUserModel") as Node2D
	model.set("load_motions", false)
	model.set("load_expressions", false)
	model.set("physics_evaluate", false)
	model.set("pose_update", true)
	model.set("playback_process_mode", 2)
	stage.add_child(model)
	model.set("assets", "res://models/Haru/Haru.model3.json")
	var info: Dictionary = model.call("get_canvas_info")
	if not info.is_empty():
		var canvas: Vector2 = info.size_in_pixels
		model.scale = Vector2.ONE * (590.0 / maxf(canvas.x, canvas.y))
	model.position = Vector2(320, 320)
	model.call("advance", 0.5)
	return model

func settle(frames: int = 3) -> void:
	for index: int in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	report.engine = Engine.get_version_info().string
	report.renderer = RenderingServer.get_current_rendering_method()
	report.editor_binary = OS.has_feature("editor")
	report.pid = OS.get_process_id()
	record(ClassDB.class_exists("GDCubismUserModel"), "GDExtension class loaded")
	if not ClassDB.class_exists("GDCubismUserModel"):
		finish()
		return
	stage = SubViewport.new()
	stage.size = Vector2i(640, 640)
	stage.transparent_bg = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(stage)
	var preview: Sprite2D = Sprite2D.new()
	preview.texture = stage.get_texture()
	preview.centered = false
	preview.scale = Vector2.ONE * 0.55
	add_child(preview)
	var model: Node2D = make_model()
	report.core = model.call("csm_get_version")
	report.moc_version = model.call("csm_get_moc_version")
	report.canvas = model.call("get_canvas_info")
	var params: Array = model.call("get_parameters")
	report.parameters = []
	var by_id: Dictionary = {}
	for parameter: Resource in params:
		var parameter_id: String = str(parameter.get("id"))
		by_id[parameter_id] = parameter
		report.parameters.append({"id": parameter_id, "min": parameter.get("minimum_value"), "max": parameter.get("maximum_value"), "default": parameter.get("default_value")})
	record(not params.is_empty(), "Haru model has parameters")
	for required: String in ["ParamAngleX", "ParamAngleY", "ParamEyeLOpen", "ParamEyeROpen"]:
		record(by_id.has(required), "Parameter exists: " + required)
	for pose: Dictionary in [{"name":"neutral","x":0.0,"eyes":1.0},{"name":"left","x":-25.0,"eyes":1.0},{"name":"right","x":25.0,"eyes":1.0},{"name":"blink","x":0.0,"eyes":0.0}]:
		for parameter_id: String in ["ParamAngleX", "ParamEyeLOpen", "ParamEyeROpen"]:
			if by_id.has(parameter_id):
				var parameter: Resource = by_id[parameter_id]
				parameter.set("hold", true)
				parameter.set("value", pose.x if parameter_id == "ParamAngleX" else pose.eyes)
		model.call("advance", 1.0 / 60.0)
		await settle()
		var capture: Image = stage.get_texture().get_image()
		record(capture.save_png(output_prefix + "_" + str(pose.name) + ".png") == OK, "Saved " + str(pose.name))
		if by_id.has("ParamAngleX"):
			record(is_equal_approx(float(by_id.ParamAngleX.get("value")), float(pose.x)), "Angle parameter retained: " + str(pose.name))
	params.clear()
	by_id.clear()
	model.queue_free()
	await settle(4)
	record(stage.get_child_count() == 0, "Initial model removed")
	for cycle: int in cycle_count:
		model = make_model()
		model.call("advance", 1.0 / 60.0)
		await settle(2)
		var reference: WeakRef = weakref(model)
		model.queue_free()
		await settle(4)
		var sample: Dictionary = {"cycle": cycle, "released": reference.get_ref() == null, "children": stage.get_child_count(), "objects": Performance.get_monitor(Performance.OBJECT_COUNT), "static_memory": OS.get_static_memory_usage()}
		report.cycles.append(sample)
		record(bool(sample.released) and int(sample.children) == 0, "Model released in cycle " + str(cycle))
		print("L0_CYCLE ", cycle)
	finish()

func finish() -> void:
	var failures: int = 0
	for check: Dictionary in report.checks:
		if not bool(check["pass"]):
			failures += 1
	report.failures = failures
	var file: FileAccess = FileAccess.open(output_prefix + ".json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("L0_RESULT ", failures)
	get_tree().quit(0 if failures == 0 and file != null else 1)
