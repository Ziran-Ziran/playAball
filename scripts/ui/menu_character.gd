extends Node2D
## 菜单表现适配器：只写模型的已有输入，不读取或改变玩法状态。
signal reaction_started(kind: String)
signal reaction_rejected(reason: String)
signal reaction_finished

@export_file("*.model3.json") var model_path: String = "res://.local/menu_character_runtime/model/runtime.model3.json"
@export_file("*.gdextension") var extension_path: String = "res://.local/menu_character_runtime/native/gd_cubism.gdextension"
@export_file("*.json") var profile_path: String = "res://.local/menu_character_runtime/menu_profile.json"
@export var display_height: float = 690.0
@export_range(0.05,1.0) var head_follow_time: float = 0.24
@export_range(0.05,1.0) var eye_follow_time: float = 0.09
@export_range(0.0,30.0) var head_angle_limit: float = 22.0
@export_range(0.0,1.0) var eye_range: float = 0.65
@export_range(0.0,2.0) var idle_body_strength: float = 1.0
@export_range(4.0,18.0) var gesture_head_degrees: float = 12.0
@export_range(1.0,10.0) var gesture_body_strength: float = 5.0
var gesture_head: Vector3 = Vector3.ZERO
var gesture_body: Vector3 = Vector3.ZERO
@export var response_seconds: float = 2.1

var model: Node2D
var parameters: Dictionary = {}
var profile: Dictionary = {}
var loaded: bool = false
var load_error: String = ""
var state: String = "idle"
var blocked: bool = false
var reduced_motion: bool = false
var pointer_target: Vector2 = Vector2.ZERO
var head_target: Vector2 = Vector2.ZERO
var eye_target: Vector2 = Vector2.ZERO
var body_input: Vector3 = Vector3.ZERO
var elapsed: float = 0.0
var reaction_remaining: float = 0.0
var reaction_elapsed: float = 0.0
var reaction_count: int = 0
var cheek_side: float = 0.0
var click_times: Array[float] = []
var greeting_count: int = 0
const SAFE_REACTIONS: Array[String] = ["pet","cheek","greet","shy","surprised","wink","pet_sway"]
var runtime_resources: Array[Resource] = []

func _ready() -> void:
	# 无图形的CI只检查菜单导航，不启动依赖纹理/遮罩的Native渲染器。
	if DisplayServer.get_name() == "headless":
		load_error = "headless backend"
		return
	if not FileAccess.file_exists(model_path) or not FileAccess.file_exists(profile_path):
		load_error = "local character resources are unavailable"
		return
	if not ClassDB.class_exists("GDCubismUserModel"):
		if OS.get_name() != "Windows" or not FileAccess.file_exists(extension_path):
			load_error = "validated local Native runtime is unavailable"
			return
		# Native目录带.gdignore，避免其它主机/编辑器无条件加载本机DLL。
		var result: int = GDExtensionManager.load_extension(extension_path)
		if result != GDExtensionManager.LOAD_STATUS_OK and result != GDExtensionManager.LOAD_STATUS_ALREADY_LOADED:
			load_error = "Native extension load failed: %d" % result
			push_warning(load_error)
			return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
	if not parsed is Dictionary:
		load_error = "invalid local character profile"
		return
	profile = parsed
	if not _cache_runtime_resources(): return
	model = ClassDB.instantiate("GDCubismUserModel") as Node2D
	model.set("load_motions",true)
	model.set("load_expressions",true)
	model.set("physics_evaluate",true)
	model.set("pose_update",true)
	model.set("playback_process_mode",2)
	model.set("mask_viewport_size",512)
	add_child(model)
	model.set("assets",model_path)
	for parameter: Resource in model.call("get_parameters"):
		parameters[str(parameter.get("id"))] = parameter
	for id: String in ["AngleX","AngleY","PositionX","PositionY","PositionZ","ParamEyeLOpen","ParamEyeROpen"]:
		if not parameters.has(id):
			load_error = "selected character is missing required input: "+id
			model.queue_free()
			model = null
			parameters.clear()
			return
	var canvas: Dictionary = model.call("get_canvas_info")
	var canvas_size: Vector2 = canvas.get("size_in_pixels",Vector2.ONE)
	model.scale = Vector2.ONE * display_height / maxf(canvas_size.x,canvas_size.y)
	model.position = Vector2(360,360)
	loaded = true
	for frame: int in 60: model.call("advance",1.0/60.0)
	_reset_safe_face()
	_start_idle()

func _cache_runtime_resources() -> bool:
	# 桥接固定按addons路径查找着色器；缓存别名保持其原代码，DLL和资源仍留在私有目录。
	var shader_directory: String = extension_path.get_base_dir().path_join("res/shader")
	var shader_count: int = 0
	for file: String in DirAccess.get_files_at(shader_directory):
		if not file.ends_with(".gdshader"): continue
		var shader: Shader = load(shader_directory.path_join(file)) as Shader
		if shader == null:
			load_error = "local renderer shader is unavailable"
			return false
		shader.take_over_path("res://addons/gd_cubism/res/shader/"+file)
		runtime_resources.append(shader)
		shader_count += 1
	if shader_count != 10:
		load_error = "local renderer shader set is incomplete"
		return false
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(model_path))
	if not manifest is Dictionary:
		load_error = "invalid local model manifest"
		return false
	var caches: Dictionary = profile.get("texture_cache",{})
	for relative: String in manifest.get("FileReferences",{}).get("Textures",[]):
		var path: String = model_path.get_base_dir().path_join(relative)
		var texture: Texture2D
		var cached_path: String = profile_path.get_base_dir().path_join(str(caches.get(relative,"")))
		if caches.has(relative) and FileAccess.file_exists(cached_path):
			texture = load(cached_path) as Texture2D
		else:
			var image: Image = Image.load_from_file(path)
			if image == null or image.is_empty():
				load_error = "local model texture is unavailable"
				return false
			image.generate_mipmaps()
			texture = ImageTexture.create_from_image(image)
		if texture == null:
			load_error = "local model texture failed to load"
			return false
		texture.take_over_path(path)
		runtime_resources.append(texture)
	return true

func _process(delta: float) -> void:
	if loaded: step_character(minf(delta,0.05))

func _set_parameter(id: String, value: float) -> void:
	if not parameters.has(id): return
	var parameter: Resource = parameters[id]
	parameter.set("hold",true)
	parameter.set("value",clampf(value,float(parameter.get("minimum_value")),float(parameter.get("maximum_value"))))

func step_character(delta: float) -> void:
	if not loaded: return
	elapsed += delta
	reaction_elapsed += delta
	if reaction_remaining > 0.0:
		reaction_remaining = maxf(0.0,reaction_remaining-delta)
		if reaction_remaining == 0.0:
			state = "idle"
			model.call("stop_expression")
			reaction_finished.emit()
	var target: Vector2 = Vector2.ZERO if blocked else pointer_target
	head_target = head_target.lerp(target,1.0-exp(-delta/head_follow_time))
	eye_target = eye_target.lerp(target,1.0-exp(-delta/eye_follow_time))
	var weight: float = 0.3 if reduced_motion else 1.0
	var envelope: float = minf(1.0,reaction_elapsed/0.15) * minf(1.0,reaction_remaining/0.35)
	var progress: float = clampf(reaction_elapsed/maxf(0.7,response_seconds),0.0,1.0)
	var head_motion := Vector3.ZERO
	var body_motion := Vector3.ZERO
	match state:
		"pet":
			head_motion.y = -sin(progress*TAU*2.0)*gesture_head_degrees
			body_motion.y = -sin(progress*TAU)*gesture_body_strength*0.3
		"wink":
			head_motion.z = -sin(progress*PI)*gesture_head_degrees
			head_motion.x = -sin(progress*PI)*gesture_head_degrees*0.4
			body_motion.z = -sin(progress*PI)*gesture_body_strength*0.5
		"cheek":
			head_motion.x = sin(progress*TAU*1.5)*gesture_head_degrees
			head_motion.z = sin(progress*TAU*1.5)*gesture_head_degrees*0.25
		"greet":
			head_motion.y = -sin(progress*PI)*gesture_head_degrees
			body_motion.y = -sin(progress*PI)*gesture_body_strength
			body_motion.z = sin(progress*TAU)*gesture_body_strength*0.6
		"shy":
			head_motion.z = sin(progress*PI)*gesture_head_degrees*0.7
		"surprised":
			head_motion.y = sin(progress*PI)*gesture_head_degrees
			body_motion.y = sin(progress*PI)*gesture_body_strength*0.8
		"pet_sway":
			head_motion.z = sin(progress*TAU)*gesture_head_degrees
			body_motion.x = sin(progress*TAU)*gesture_body_strength
	gesture_head = gesture_head.lerp(head_motion*envelope,1.0-exp(-delta/0.07))
	gesture_body = gesture_body.lerp(body_motion*envelope,1.0-exp(-delta/0.12))
	# 动作期间降低鼠标头部跟随权重，避免点头/歪头被追鼠标抵消；眼神仍先行。
	var follow_weight: float = lerpf(1.0,0.2,envelope) if state != "idle" else 1.0
	_set_parameter("AngleX",(head_target.x*head_angle_limit*follow_weight+gesture_head.x)*weight)
	_set_parameter("AngleY",(-head_target.y*head_angle_limit*0.65*follow_weight+gesture_head.y)*weight)
	_set_parameter("AngleZ",(head_target.x*-1.5*follow_weight+gesture_head.z)*weight)
	# Angle/Position是输入；ParamAngle/ParamBodyAngle为原物理输出，正常模式不强写。
	if reduced_motion:
		_set_parameter("ParamAngleX",head_target.x*head_angle_limit*weight)
		_set_parameter("ParamAngleY",-head_target.y*head_angle_limit*0.65*weight)
		_set_parameter("ParamAngleZ",head_target.x*-1.5*weight)
	_set_parameter("ParamEyeBallX",(eye_target.x-head_target.x*0.35)*eye_range)
	_set_parameter("ParamEyeBallY",-(eye_target.y-head_target.y*0.35)*eye_range)
	var idle_weight: float = 0.0 if reduced_motion or blocked else idle_body_strength
	if state != "idle": idle_weight *= 0.4
	var desired := Vector3(2.2*sin(elapsed*0.62)+0.7*sin(elapsed*0.31+0.8),0.4*sin(elapsed*1.45-0.4),1.3*sin(elapsed*0.49+0.6)+0.35*sin(elapsed*0.93))*idle_weight
	body_input = body_input.lerp(desired,1.0-exp(-delta/0.5))
	_set_parameter("PositionX",body_input.x+gesture_body.x)
	_set_parameter("PositionY",body_input.y+gesture_body.y)
	_set_parameter("PositionZ",body_input.z+gesture_body.z)
	var phase: float = fmod(elapsed,4.3)
	var openness: float = absf(phase/0.085-1.0) if phase < 0.17 else 1.0
	# 短反应两端平滑收回；所有参数均来自当前作者模型，不播放不受控表情文件。
	var left_open: float = openness
	var right_open: float = openness
	var smile: float = 0.0
	var mouth: float = 0.0
	var mouth_open: float = 0.0
	var blush: float = 0.0
	var puff: float = 0.0
	match state:
		"pet", "pet_sway":
			left_open = lerpf(openness,0.10,envelope)
			right_open = left_open
			smile = 0.85 * envelope
			mouth = 0.65 * envelope
			blush = 0.3 * envelope
		"cheek":
			puff = 0.65 * envelope
			mouth = -0.12 * envelope
			blush = 0.25 * envelope
		"greet", "wink":
			left_open = lerpf(openness,0.05,envelope)
			smile = 0.3 * envelope
			mouth = 0.75 * envelope
			mouth_open = 0.12 * envelope
		"shy":
			left_open = lerpf(openness,0.65,envelope)
			right_open = left_open
			smile = 0.25 * envelope
			mouth = 0.35 * envelope
			blush = 0.8 * envelope
		"surprised":
			left_open = lerpf(openness,1.15,envelope)
			right_open = left_open
			mouth_open = 0.32 * envelope
	_set_parameter("ParamEyeLOpen",left_open)
	_set_parameter("ParamEyeROpen",right_open)
	_set_parameter("EyeSmile",smile)
	_set_parameter("ParamMouthForm",mouth)
	_set_parameter("ParamMouthOpenY",mouth_open)
	_set_parameter("key7",blush)
	_set_parameter("BrowInnerUp",0.3 * envelope if state == "surprised" else 0.0)
	_set_parameter("ParamBreath",0.5 if reduced_motion or blocked else 0.5+sin(elapsed*1.45)*0.32)
	_set_parameter("CheeckPuff",puff)
	_set_parameter("MouthX",cheek_side*puff*0.35)
	# key1是作者黑脸、key6是屑屑眼；禁止旧profile或待机动作重新激活它们。
	_set_parameter("key1",0.0)
	_set_parameter("key6",0.0)
	model.call("advance",delta)

func set_pointer(value: Vector2) -> void:
	pointer_target = value.clamp(Vector2(-1,-1),Vector2.ONE)

func set_blocked(value: bool) -> void:
	blocked = value
	if value:
		pointer_target = Vector2.ZERO
		_reset_safe_face()

func _reset_safe_face() -> void:
	state = "idle"
	reaction_remaining = 0.0
	reaction_elapsed = 0.0
	click_times.clear()
	gesture_head = Vector3.ZERO
	gesture_body = Vector3.ZERO
	head_target = Vector2.ZERO
	eye_target = Vector2.ZERO
	if not loaded: return
	model.call("stop_expression")
	for id: String in ["key1","key6","key7","EyeSmile","ParamMouthForm","ParamMouthOpenY","BrowInnerUp","CheeckPuff","MouthX"]:
		_set_parameter(id,0.0)
	for id: String in ["AngleX","AngleY","AngleZ","PositionX","PositionY","PositionZ"]:
		_set_parameter(id,0.0)
	_set_parameter("ParamEyeLOpen",1.0)
	_set_parameter("ParamEyeROpen",1.0)

func request_reaction(kind: String, side: float = 0.0) -> bool:
	if not loaded or blocked or not kind in SAFE_REACTIONS: return false
	if reduced_motion:
		reaction_rejected.emit("减少动态已开启；在设置中关闭后可互动")
		return false
	while not click_times.is_empty() and elapsed-click_times[0] > 1.4: click_times.pop_front()
	click_times.append(elapsed)
	if click_times.size() >= 3: kind = "surprised"
	if reaction_remaining > 0.0 and reaction_elapsed < 0.22 and kind != "surprised":
		reaction_rejected.emit("已经收到啦，稍等一下再点")
		return false
	if kind == "surprised" and state == "surprised" and reaction_remaining > 0.0: return false
	state = kind
	cheek_side = clampf(side,-1.0,1.0)
	reaction_elapsed = 0.0
	reaction_remaining = response_seconds
	reaction_count += 1
	# 无论本机旧profile是否仍写annoyed=黑脸，都不再调用start_expression。
	model.call("stop_expression")
	reaction_started.emit(kind)
	return true

func _start_idle() -> void:
	var idle: Dictionary = profile.get("idle",{})
	if not reduced_motion and not idle.is_empty():
		model.call("start_motion_loop",str(idle.group),int(idle.index),1,true,true)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value: _reset_safe_face()
	if not loaded: return
	model.set("physics_evaluate",not value)
	if value:
		model.call("stop_motion")
	else:
		for id: String in ["ParamAngleX","ParamAngleY","ParamAngleZ"]:
			if parameters.has(id):
				parameters[id].set("hold",false)
				parameters[id].call("reset")
		_start_idle()

func _exit_tree() -> void:
	loaded = false
	parameters.clear()
	runtime_resources.clear()
