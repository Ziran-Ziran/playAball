extends SceneTree
## 用实际主球碰撞验证转速、摆角与停转，不用直接改挡板位置来制造结果。
var checks: int = 0
var failures: int = 0
var results: Array[Dictionary] = []
func _initialize() -> void:
	call_deferred("run")
	create_timer(240).timeout.connect(func(): push_error("Paddle response timeout"); quit(1))
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for tick in count:
		await physics_frame
	await process_frame
func run() -> void:
	for offset: float in [0.0, 55.0]:
		for direction: float in [-1.0, 1.0]:
			for speed: float in [80.0, 300.0, 1050.0]:
				await collision_case(offset, direction, speed)
	# 限位必须相对实例初始角度，且受力端不能在限位后继续绕整圈。
	for initial: float in [-0.45, 0.45]:
		await impulse_case(initial)
	await repeated_limit_case()
	# 实包的res目录查询走虚拟PCK；先转成绝对磁盘路径再创建诊断目录。
	var output_dir := ProjectSettings.globalize_path("res://.local")
	check(DirAccess.make_dir_recursive_absolute(output_dir) == OK, "Diagnostic directory is writable")
	var file := FileAccess.open(output_dir.path_join("paddle_response.json"), FileAccess.WRITE)
	check(file != null, "Raw paddle measurements can be saved")
	if file != null:
		file.store_string(JSON.stringify(results, "\t"))
	print("PADDLE_RESULTS: ", JSON.stringify(results))
	print("PADDLE RESPONSE CHECKS PASSED: %d failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
func collision_case(offset: float, direction: float, speed: float) -> void:
	var pivot = load("res://scenes/roguelite/mechanisms/pivot_paddle.tscn").instantiate()
	pivot.position = Vector2(640, 400)
	pivot.pivot_offset = Vector2(offset, 0)
	root.add_child(pivot)
	await frames(3)
	var body: RigidBody2D = pivot.get_node("Paddle")
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = body.global_position + Vector2(-70 if offset > 0 else 70, -direction * 65)
	root.add_child(player)
	player.linear_velocity = Vector2(0, direction * speed)
	var contacted: bool = false
	var peak: float = 0.0
	var angle: float = 0.0
	var anchor_error: float = 0.0
	for tick in 840:
		await physics_frame
		contacted = contacted or player.get_colliding_bodies().has(body)
		peak = maxf(peak, absf(body.angular_velocity))
		angle = maxf(angle, absf(angle_difference(pivot.initial_angle, body.rotation)))
		anchor_error = maxf(anchor_error, body.to_global(pivot.pivot_offset).distance_to(pivot.global_position))
	var row := {"offset": offset, "direction": direction, "speed": speed, "contact": contacted, "peak_spin": peak, "max_angle": angle, "anchor_error": anchor_error, "end_spin": absf(body.angular_velocity)}
	results.append(row)
	var label := JSON.stringify(row)
	check(contacted, "Real ball touches paddle: " + label)
	check(peak <= (0.5 if speed == 80 else 1.45), "Touch/launch has bounded rotation: " + label)
	check(angle <= pivot.angle_limit + 0.05, "Physical collision respects angular travel: " + label)
	check(anchor_error < 5.0, "Center/eccentric anchor stays attached: " + label)
	check(absf(body.angular_velocity) < 0.06, "Rotation settles after collision: " + label)
	player.queue_free()
	pivot.queue_free()
	await frames(2)
func repeated_limit_case() -> void:
	var pivot = load("res://scenes/roguelite/mechanisms/pivot_paddle.tscn").instantiate()
	pivot.position = Vector2(640, 400)
	pivot.rotation = 0.3
	pivot.initial_angle = -0.45
	pivot.angle_limit = 0.25
	root.add_child(pivot)
	await frames(3)
	var body: RigidBody2D = pivot.get_node("Paddle")
	var rest: float = body.global_rotation
	var excursion: float = 0.0
	for tick in 600:
		if tick % 12 == 0:
			body.apply_torque_impulse(1500)
		await physics_frame
		excursion = maxf(excursion, absf(angle_difference(rest, body.global_rotation)))
	results.append({"repeated_limit": pivot.angle_limit, "max_angle": excursion, "parent_rotation": pivot.rotation})
	check(excursion <= 0.27, "Repeated impacts cannot cross limit on rotated parent")
	check(angle_difference(rest, body.global_rotation) > 0.23, "Repeated pushes actually reach the stop")
	body.apply_torque_impulse(-12000)
	await frames(30)
	check(angle_difference(rest, body.global_rotation) < 0.20, "Opposite impact frees the stopped paddle")
	pivot.set_active(false)
	await frames(2)
	var frozen: float = body.global_rotation
	await frames(30)
	check(is_equal_approx(frozen, body.global_rotation), "Inactive paddle remains frozen")
	pivot.reset_mechanism()
	pivot.set_active(true)
	await frames(4)
	check(absf(angle_difference(rest, body.global_rotation)) < 0.01 and absf(body.angular_velocity) < 0.01, "Reset after freeze restores initial angle and clears spin")
	pivot.queue_free()
	await frames(2)
func impulse_case(initial: float) -> void:
	var pivot = load("res://scenes/roguelite/mechanisms/pivot_paddle.tscn").instantiate()
	pivot.position = Vector2(640, 400)
	pivot.initial_angle = initial
	root.add_child(pivot)
	await frames(3)
	var body: RigidBody2D = pivot.get_node("Paddle")
	body.apply_impulse(Vector2(0, 1050), Vector2(70, 0))
	var peak: float = 0.0
	var excursion: float = 0.0
	for tick in 600:
		await physics_frame
		peak = maxf(peak, absf(body.angular_velocity))
		excursion = maxf(excursion, absf(angle_difference(initial, body.rotation)))
	results.append({"initial": initial, "impulse": 1050, "peak_spin": peak, "max_angle": excursion})
	check(peak <= 1.45 and excursion <= pivot.angle_limit + 0.05, "Rotated instance stays within configured speed and angle: " + str(initial))
	check(excursion > 0.02, "Paddle still responds to real impulse: " + str(initial))
	pivot.queue_free()
	await frames(2)
