extends Node2D
## 只驱动模型已有参数；动作与鼠标跟随按状态仲裁，不改变整张图的位置冒充转头。
signal reaction_started(kind: String)
signal reaction_finished

@export_file("*.model3.json") var model_path: String = "res://models/DeepSeek-chan/runtime.model3.json"
@export var display_height: float = 690.0
@export_range(0.05, 1.0) var head_follow_time: float = 0.24
@export_range(0.05, 1.0) var eye_follow_time: float = 0.09
@export_range(0.0, 30.0) var head_angle_limit: float = 22.0
@export_range(0.0, 1.0) var eye_range: float = 0.65
@export var response_seconds: float = 2.1
@export_range(0.0, 2.0) var idle_body_strength: float = 1.0

var model: Node2D
var parameters: Dictionary = {}
var profile: Dictionary = {}
var state: String = "idle"
var blocked: bool = false
var pointer_target: Vector2 = Vector2.ZERO
var head_target: Vector2 = Vector2.ZERO
var eye_target: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var reaction_remaining: float = 0.0
var click_times: Array[float] = []
var reaction_count: int = 0
var loaded: bool = false
var load_error: String = ""
var cheek_side: float = 0.0
var reaction_elapsed: float = 0.0
var gesture_active: bool = false
var reduced_motion: bool = false
var body_input: Vector3 = Vector3.ZERO

func _ready() -> void:
	load_character()

func load_character() -> void:
	if is_instance_valid(model): return
	if not ClassDB.class_exists("GDCubismUserModel"):
		load_error = "缺少已验证的 gd_cubism 插件"
		return
	if not FileAccess.file_exists(model_path):
		load_error = "请先准备已获授权的 DeepSeek-chan 模型"
		return
	if not FileAccess.file_exists("res://model_profile.json"):
		load_error = "缺少模型动作配置，请重新准备隔离样板"
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://model_profile.json"))
	if parsed is Dictionary: profile = parsed
	model = ClassDB.instantiate("GDCubismUserModel") as Node2D
	model.set("load_motions", true)
	model.set("load_expressions", true)
	model.set("physics_evaluate", true)
	model.set("pose_update", true)
	model.set("playback_process_mode", 2)
	model.set("mask_viewport_size", 512)
	add_child(model)
	model.set("assets", model_path)
	for parameter: Resource in model.call("get_parameters"):
		parameters[str(parameter.get("id"))] = parameter
	loaded = not parameters.is_empty()
	if not loaded:
		load_error = "模型没有成功加载参数"
		return
	var canvas: Dictionary = model.call("get_canvas_info")
	var size: Vector2 = canvas.get("size_in_pixels", Vector2.ONE)
	model.scale = Vector2.ONE * (display_height / maxf(size.x, size.y))
	model.position = Vector2(360, 360)
	for step: int in 60: model.call("advance", 1.0 / 60.0)
	_start_idle()

func _process(delta: float) -> void:
	if not loaded: return
	step_character(minf(delta, 0.05))

func step_character(delta: float) -> void:
	elapsed += delta
	if reaction_remaining > 0.0:
		reaction_remaining = maxf(0.0, reaction_remaining - delta)
		if reaction_remaining == 0.0:
			var returning: Dictionary = profile.get("return_gesture", {})
			if gesture_active and not returning.is_empty():
				gesture_active = false
				state = "returning"
				reaction_remaining = float(returning.get("duration", 1.2)) + 0.15
				model.call("start_motion", str(returning.group), int(returning.index), 3)
			else:
				state = "idle"
				model.call("stop_expression")
				model.call("stop_motion")
				_start_idle()
				reaction_finished.emit()
	reaction_elapsed += delta
	var target: Vector2 = pointer_target if not blocked else Vector2.ZERO
	head_target = head_target.lerp(target, 1.0 - exp(-delta / head_follow_time))
	eye_target = eye_target.lerp(target, 1.0 - exp(-delta / eye_follow_time))
	# 明确占有跟随参数；不覆盖作者动作里的手臂、嘴形和身体姿态。
	var motion_amount: float = 0.3 if reduced_motion else 1.0
	# PositionX/Y/Z是作者的身体物理输入；ParamBodyAngle*是其输出，不能反过来强写。
	# 不移动模型Node；不同频率的小幅输入让胸腔、腰、袖口与发丝按原绑定联动。
	var idle_weight: float = 0.0 if reduced_motion or blocked else idle_body_strength
	if state != "idle":
		idle_weight *= 0.4
	var desired_body := Vector3(
		2.2 * sin(elapsed * 0.62) + 0.7 * sin(elapsed * 0.31 + 0.8),
		0.4 * sin(elapsed * 1.45 - 0.4),
		1.3 * sin(elapsed * 0.49 + 0.6) + 0.35 * sin(elapsed * 0.93)) * idle_weight
	body_input = body_input.lerp(desired_body, 1.0 - exp(-delta / 0.5))
	_set_parameter("PositionX", body_input.x)
	_set_parameter("PositionY", body_input.y)
	_set_parameter("PositionZ", body_input.z)
	# 此模型 AngleX/Y 是输入，ParamAngleX/Y 是物理输出；强写输出会在 advance 中被覆盖。
	_set_parameter("AngleX", head_target.x * head_angle_limit * motion_amount)
	_set_parameter("AngleY", -head_target.y * head_angle_limit * 0.65 * motion_amount)
	if reduced_motion:
		# 关闭物理时才直接驱动输出，避免头停在关闭前的角度。
		_set_parameter("ParamAngleX", head_target.x * head_angle_limit * motion_amount)
		_set_parameter("ParamAngleY", -head_target.y * head_angle_limit * 0.65 * motion_amount)
	_set_parameter("ParamEyeBallX", (eye_target.x - head_target.x * 0.35) * eye_range)
	_set_parameter("ParamEyeBallY", -(eye_target.y - head_target.y * 0.35) * eye_range)
	# 自然眨眼只占眼睑参数，抬手等动作不争抢跟随更新。
	var blink_phase: float = fmod(elapsed, 4.3)
	var openness: float = 1.0
	if blink_phase < 0.17:
		openness = absf(blink_phase / 0.085 - 1.0)
	if state == "pet": openness = 0.12
	_set_parameter("ParamEyeLOpen", openness)
	_set_parameter("ParamEyeROpen", openness)
	_set_parameter("ParamBreath", 0.5 if reduced_motion else 0.5 + sin(elapsed * 1.45) * 0.32)
	# 鼓脸是作者的输入参数；左右脸晃动由原物理配置接续，避免强写物理输出。
	var puff: float = 0.0
	if state == "cheek": puff = sin(minf(reaction_elapsed * 7.0, PI)) * 0.55
	if state == "annoyed": puff = sin(minf(reaction_elapsed * 2.0, PI)) * 0.3
	_set_parameter("CheeckPuff", maxf(puff, 0.0))
	_set_parameter("MouthX", cheek_side * maxf(puff, 0.0) * 0.35)
	model.call("advance", delta)

func _set_parameter(id: String, value: float) -> void:
	if not parameters.has(id): return
	var parameter: Resource = parameters[id]
	parameter.set("hold", true)
	parameter.set("value", clampf(value, float(parameter.get("minimum_value")), float(parameter.get("maximum_value"))))

func set_pointer(normalized: Vector2) -> void:
	pointer_target = normalized.clamp(Vector2(-1, -1), Vector2.ONE)

func set_blocked(value: bool) -> void:
	blocked = value
	if value:
		pointer_target = Vector2.ZERO

func request_reaction(kind: String, side: float = 0.0) -> bool:
	if not loaded or blocked: return false
	# 短时间连点只升级一次不满，不重复启动动作造成抖动。
	while not click_times.is_empty() and elapsed - click_times[0] > 1.4: click_times.pop_front()
	click_times.append(elapsed)
	if click_times.size() >= 3: kind = "annoyed"
	if reaction_remaining > 0.0 and (kind != "annoyed" or state == "annoyed"): return false
	state = kind
	cheek_side = clampf(side, -1.0, 1.0)
	reaction_elapsed = 0.0
	reaction_remaining = response_seconds
	reaction_count += 1
	model.call("stop_expression")
	var expression: String = str(profile.get("reactions", {}).get(kind, ""))
	if not expression.is_empty(): model.call("start_expression", expression)
	var motion: Dictionary = profile.get("gesture", {})
	if kind == "greet" and not motion.is_empty():
		gesture_active = true
		model.call("start_motion", str(motion.group), int(motion.index), 3)
	reaction_started.emit(kind)
	return true

func _start_idle() -> void:
	var idle: Dictionary = profile.get("idle", {})
	if not reduced_motion and not idle.is_empty(): model.call("start_motion_loop", str(idle.group), int(idle.index), 1, true, true)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if not loaded: return
	model.set("physics_evaluate", not value)
	if not value:
		for id: String in ["ParamAngleX", "ParamAngleY"]:
			parameters[id].call("reset")
	if value and state == "idle": model.call("stop_motion")
	elif state == "idle": _start_idle()

func release_character() -> WeakRef:
	loaded = false
	parameters.clear()
	var reference: WeakRef = weakref(model)
	if is_instance_valid(model): model.queue_free()
	model = null
	return reference

func snapshot() -> Dictionary:
	return {"loaded":loaded,"state":state,"blocked":blocked,"head":head_target,"eyes":eye_target,"reaction_count":reaction_count,"remaining":reaction_remaining}
