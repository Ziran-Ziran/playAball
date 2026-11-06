extends Node2D
## 原生模型资源重复创建／释放；每轮等待真实渲染与延迟删除。
var cycle_count: int = 30
var output: String = ""
var stage: SubViewport
var report: Dictionary = {"cycles":[],"scope":"DeepSeek-chan lifecycle; bounded observation is not leak-free proof"}

func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--cycles="): cycle_count = clampi(int(arg.trim_prefix("--cycles=")), 1, 200)
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	_run.call_deferred()

func settle(frames: int) -> void:
	for frame: int in frames: await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	stage = SubViewport.new()
	stage.size = Vector2i(720,720)
	stage.transparent_bg = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(stage)
	report.engine = Engine.get_version_info().string
	report.renderer = RenderingServer.get_current_rendering_method()
	report.editor_binary = OS.has_feature("editor")
	for cycle: int in cycle_count:
		var model: Node2D = ClassDB.instantiate("GDCubismUserModel") as Node2D
		model.set("load_motions", true)
		model.set("load_expressions", true)
		model.set("physics_evaluate", true)
		model.set("pose_update", true)
		model.set("playback_process_mode", 2)
		model.set("mask_viewport_size", 512)
		stage.add_child(model)
		model.set("assets", "res://models/DeepSeek-chan/runtime.model3.json")
		model.scale = Vector2.ONE * 0.1
		model.position = Vector2(360,360)
		model.call("advance", 1.0 / 60.0)
		await settle(3)
		var reference: WeakRef = weakref(model)
		model.queue_free()
		await settle(10)
		var sample: Dictionary = {"cycle":cycle,"released":reference.get_ref() == null,"children":stage.get_child_count(),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"texture_memory":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"buffer_memory":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"godot_static_memory":OS.get_static_memory_usage()}
		report.cycles.append(sample)
		print("CHAN_CYCLE ", JSON.stringify(sample))
	report.failures = (report.cycles as Array).filter(func(c: Dictionary) -> bool: return not c.released or c.children != 0).size()
	var file := FileAccess.open(output + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("CHAN_LIFECYCLE_RESULT ", report.failures)
	get_tree().quit(int(report.failures))
