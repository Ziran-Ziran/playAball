extends Node3D
## 保留原始骨架，以动作微动、真实头颈旋转和作者形态键分别驱动。

const AdditiveMotion = preload("res://sample/additive_motion.gd")
const GazeMotion = preload("res://sample/gaze_motion.gd")
var model: Node3D
var skeleton: Skeleton3D
var source: Node3D
var source_player: AnimationPlayer
var source_skeleton: Skeleton3D
var motion: SkeletonModifier3D
var gaze_motion: SkeletonModifier3D
var meshes: Array[MeshInstance3D] = []
var ready_for_input: bool = false
var reduced_motion: bool = false
var settings_open: bool = false
var requested_gaze: Vector2 = Vector2.ZERO
var follow_amount: float = 1.0
var reaction_remaining: float = 0.0
var reaction_kind: String = ""
var reaction_count: int = 0
var elapsed: float = 0.0
var _blink_timer: float = 2.0
var _blink_phase: float = -1.0
var _rng := RandomNumberGenerator.new()
var _smile: float = 0.2
var _reaction_animation: bool = false

func _ready() -> void:
	_rng.randomize()
	model = load("res://models/whale_adult.glb").instantiate()
	model.position.x = 0.08
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		meshes.append(mesh)
		for surface in mesh.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface).duplicate()
			# 原颜色图包含明暗，菜单用原色避免额外高光把五官冲白。
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			if "UpperLid" in mesh.name:
				# 作者眼睑贴图为灰褐色，与原色脸部不匹配；仅替换样板材质颜色。
				material.albedo_texture = null
				material.albedo_color = Color("ffe1d9")
			if "Mouth_Quad" in mesh.name:
				# 补片图外侧为黑色；UV向内收，避免采到外侧产生黑圈。
				material.uv1_scale = Vector3(0.97, 0.97, 1.0)
				material.uv1_offset = Vector3(0.015, 0.015, 0.0)
			mesh.set_surface_override_material(surface, material)
	source = load("res://models/animations.glb").instantiate()
	add_child(source)
	source.hide()
	source_skeleton = source.find_children("*", "Skeleton3D", true, false)[0]
	source_player = source.find_children("*", "AnimationPlayer", true, false)[0]
	source_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	source_player.play("Idle")
	source_player.advance(0.0)
	var baseline: Array[Transform3D] = []
	for bone in source_skeleton.get_bone_count():
		baseline.append(source_skeleton.get_bone_global_pose(bone))
	motion = AdditiveMotion.new()
	skeleton.add_child(motion)
	motion.configure(source_skeleton, baseline)
	gaze_motion = GazeMotion.new()
	skeleton.add_child(gaze_motion)
	ready_for_input = true

func _process(delta: float) -> void:
	if not ready_for_input:
		return
	var step: float = minf(delta, 0.05)
	elapsed += step
	source_player.advance(step * (0.45 if reduced_motion else 0.8))
	motion.motion_strength = 0.15 if reduced_motion else (0.7 if reaction_remaining > 0.0 else 0.55)
	gaze_motion.reduced_motion = reduced_motion
	gaze_motion.target = Vector2.ZERO if settings_open else requested_gaze * follow_amount
	if reaction_remaining > 0.0:
		reaction_remaining = maxf(0.0, reaction_remaining - step)
		gaze_motion.reaction = 1.0 - reaction_remaining / 1.7
	else:
		gaze_motion.reaction = 0.0
		if _reaction_animation:
			source_player.play("Idle", 0.8)
			_reaction_animation = false
	var desired_smile: float = 0.8 if reaction_remaining > 0.0 else 0.2
	_smile = lerpf(_smile, desired_smile, 1.0 - exp(-5.0 * step))
	_blink_timer -= step
	if _blink_timer <= 0.0 and _blink_phase < 0.0:
		_blink_phase = 0.0
		_blink_timer = _rng.randf_range(2.4, 5.5)
	var blink: float = 0.0
	if _blink_phase >= 0.0:
		_blink_phase += step / 0.19
		blink = sin(minf(_blink_phase, 1.0) * PI)
		if _blink_phase >= 1.0:
			_blink_phase = -1.0
	_set_shape("Blink_R", blink)
	_set_shape("Blink_L", blink)
	_set_shape("Close", blink)
	_set_shape("Brows_Soft", 0.25 + _smile * 0.3)
	_set_shape("Smile", _smile)
	_set_shape("Mouth_A", sin(elapsed * 9.0) * 0.1 + 0.12 if reaction_remaining > 0.0 else 0.0)

func react(kind: String = "greet") -> bool:
	if not ready_for_input or settings_open or reaction_remaining > 0.25:
		return false
	reaction_kind = kind
	reaction_remaining = 1.7
	reaction_count += 1
	if not reduced_motion:
		source_player.play("Idle_Talking", 0.6)
		_reaction_animation = true
	return true

func _set_shape(shape: String, value: float) -> void:
	for mesh: MeshInstance3D in meshes:
		var index: int = mesh.find_blend_shape_by_name(shape)
		if index >= 0:
			mesh.set_blend_shape_value(index, clampf(value, 0.0, 1.0))

func head_world_position() -> Vector3:
	return skeleton.global_transform * (skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin + Vector3(0.0, 0.085, 0.12))
