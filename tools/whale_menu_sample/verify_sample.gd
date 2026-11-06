extends RefCounted
## 真实Godot输入→骨骼修饰→渲染图像检查；不作为用户审美验收。

var checks: Array[Dictionary] = []
var directory: String

func run(menu: Control) -> void:
	directory = OS.get_executable_path().get_base_dir().path_join("evidence") if OS.has_feature("template") else ProjectSettings.globalize_path("res://evidence")
	DirAccess.make_dir_recursive_absolute(directory)
	await menu.get_tree().create_timer(0.7).timeout
	var character: Node3D = menu.character
	_check("original_target_bones", character.skeleton.get_bone_count() == 25)
	_check("native_renderer", RenderingServer.get_current_rendering_method() == "gl_compatibility")
	_check("body_motion_mapped", character.motion.mapped_bone_count == 4)
	await _point(menu, Vector2(170, 150), 0.85)
	var left: Basis = character.gaze_motion.last_head_basis
	var left_image: Image = await _capture(menu, "look_left.png")
	await _point(menu, Vector2(1240, 150), 0.85)
	var right: Basis = character.gaze_motion.last_head_basis
	var right_image: Image = await _capture(menu, "look_right.png")
	var angle: float = left.get_rotation_quaternion().angle_to(right.get_rotation_quaternion())
	_check("real_head_turn", angle > deg_to_rad(12.0), {"degrees": rad_to_deg(angle)})
	_check("body_library_moves", character.motion.max_rotation > 0.003, {"max_degrees": rad_to_deg(character.motion.max_rotation)})
	if left_image != null and right_image != null:
		var rms: float = _image_difference(left_image, right_image)
		_check("rendered_head_changes", rms > 0.01, {"normalized_rgb_rms": rms})
	await _point(menu, Vector2(840, 280), 0.45)
	var before: int = character.reaction_count
	_click(menu, menu.head_screen_position())
	await menu.get_tree().create_timer(0.3).timeout
	_check("head_click_reacts", character.reaction_count == before + 1)
	await _capture(menu, "head_reaction.png")
	await menu.get_tree().create_timer(0.7).timeout
	await _capture(menu, "body_reaction.png")
	await menu.get_tree().create_timer(0.9).timeout
	menu.set_settings_open(true)
	before = character.reaction_count
	_click(menu, menu.head_screen_position())
	await menu.get_tree().create_timer(0.2).timeout
	_check("settings_block_character", character.reaction_count == before)
	await _capture(menu, "settings.png")
	menu.set_settings_open(false)
	character.reduced_motion = true
	await _point(menu, Vector2(170, 150), 1.0)
	var reduced_left: Basis = character.gaze_motion.last_head_basis
	await _point(menu, Vector2(1240, 150), 1.0)
	var reduced_right: Basis = character.gaze_motion.last_head_basis
	var reduced_angle: float = reduced_left.get_rotation_quaternion().angle_to(reduced_right.get_rotation_quaternion())
	_check("reduced_motion_limits_turn", reduced_angle < angle * 0.7, {"degrees": rad_to_deg(reduced_angle)})
	character.reduced_motion = false
	menu._toggle_zoom()
	await menu.get_tree().create_timer(0.8).timeout
	await _point(menu, Vector2(800, 220), 0.8)
	await _capture(menu, "close_up.png")
	_check("close_up_camera", absf(menu.camera.size - 0.85) < 0.01)
	character._blink_phase = 0.4
	await menu.get_tree().process_frame
	await _capture(menu, "blink.png")
	var metrics: Dictionary = {"fps": Engine.get_frames_per_second(), "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, "objects": Performance.get_monitor(Performance.OBJECT_COUNT), "video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	var failures: int = checks.filter(func(item: Dictionary) -> bool: return not item.passed).size()
	var file := FileAccess.open(directory.path_join("validation.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failed": failures, "engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(), "sample_metrics_not_benchmark": metrics, "limits": ["No independent eye/hair/finger rig", "Additive torso idle transfer only, no arm animation or full pose retargeting", "Not human visual acceptance or full lifecycle/memory clearance"]}, "  "))
	file.close()
	print("WHALE SAMPLE ", checks.size(), " CHECKS; FAILED ", failures)
	menu.get_tree().quit(0 if failures == 0 else 1)

func _check(name: String, passed: bool, evidence: Dictionary = {}) -> void:
	checks.append({"name": name, "passed": passed, "evidence": evidence})
	print("PASS " if passed else "FAIL ", name, " ", evidence)

func _point(menu: Control, position: Vector2, seconds: float) -> void:
	var event := InputEventMouseMotion.new()
	event.position = menu.get_viewport().get_final_transform() * position
	event.global_position = event.position
	Input.parse_input_event(event)
	await menu.get_tree().create_timer(seconds).timeout

func _click(menu: Control, position: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = menu.get_viewport().get_final_transform() * position
		event.global_position = event.position
		event.pressed = pressed
		Input.parse_input_event(event)

func _capture(menu: Control, name: String) -> Image:
	if DisplayServer.get_name() == "headless":
		return null
	await RenderingServer.frame_post_draw
	var image: Image = menu.get_viewport().get_texture().get_image()
	image.save_png(directory.path_join(name))
	return image

func _image_difference(left: Image, right: Image) -> float:
	var sum: float = 0.0
	var count: int = 0
	# 右侧头肩区域，排除左侧文字/按钮，使用实际输出像素。
	for y in range(int(left.get_height() * 0.08), int(left.get_height() * 0.48), 3):
		for x in range(int(left.get_width() * 0.53), int(left.get_width() * 0.85), 3):
			var a: Color = left.get_pixel(x,y)
			var b: Color = right.get_pixel(x,y)
			sum += (a.r-b.r)**2 + (a.g-b.g)**2 + (a.b-b.b)**2
			count += 3
	return sqrt(sum / maxf(count, 1))
