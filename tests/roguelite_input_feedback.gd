extends SceneTree
## 回归玩家发现的问题：真实视口输入、接触反馈坐标和冷却临界帧。
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(20.0).timeout.connect(func(): push_error("Input feedback timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame
	await process_frame

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var arena = load("res://scenes/roguelite/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.feedback.sound_enabled = false
	arena.feedback.shake_enabled = false
	await frames(3)
	var launch: DemoLaunch = arena.launcher
	var player: DemoPlayer = arena.player
	launch.set_process(false)
	# 不把冷却完成、发射当成撞击；就绪只更新 UI。
	arena.feedback.set_process(false)
	arena.feedback._rings.clear()
	launch.remaining = 0.01
	launch.advance(0.02)
	check(arena.feedback._rings.is_empty(), "Recharge never creates phantom collision particles")
	launch.remaining = 0.04
	arena._process(0.0)
	check(not arena.status.text.contains("冷却 0.0"), "Cooldown display never rounds unavailable energy to zero")
	launch.reset_launch()
	arena.get_node("Camera2D").offset = Vector2(12, -7)
	await frames(2)
	# 全屏包括围场边缘及顶栏空白；按钮点击由 GUI 独占。
	for point: Vector2 in [Vector2(15, 400), Vector2(1260, 400), Vector2(1000, 65), Vector2(800, 705)]:
		mouse(point, true)
		await frames(1)
		check(launch.aiming, "Viewport drag begins away from ball at %s" % point)
		motion(point + Vector2(0, -40))
		await frames(1)
		check(launch.pointer.distance_to(point + Vector2(0, -40)) < 0.1, "Drag pointer uses screen coordinates independent of camera")
		mouse(point + Vector2(0, -40), false)
		await frames(1)
		check(launch.shots == 1, "Viewport release fires exactly once")
		launch.reset_launch()
		player.reset_body(Vector2(640, 540))
		await frames(2)
	# 冷却结束前先按住，跨过就绪时刻后继续拖动，不要求重新按下。
	launch.remaining = 0.03
	mouse(Vector2(900, 440), true)
	await frames(1)
	launch.advance(0.04)
	motion(Vector2(800, 440))
	await frames(1)
	check(launch.aiming, "Held drag starts when cooldown completes")
	mouse(Vector2(800, 440), false)
	await frames(1)
	check(launch.shots == 1, "Buffered drag fires once after recharge")
	launch.reset_launch()
	for attempt in 10:
		mouse(Vector2(15, 400), true)
		await frames(1)
		motion(Vector2(15, 450))
		await frames(1)
		mouse(Vector2(15, 450), false)
		await frames(1)
		check(launch.shots == attempt + 1, "Repeated full-screen drag %d fires reliably" % (attempt + 1))
		launch.advance(launch.cooldown)
		player.reset_body(Vector2(640, 540))
		await frames(2)
	launch.reset_launch()
	launch.remaining = 0.2
	mouse(Vector2(900, 440), true)
	await frames(1)
	mouse(Vector2(800, 440), false)
	await frames(1)
	launch.advance(0.3)
	check(not launch.aiming and launch.shots == 0, "Early release cancels buffered drag without ghost firing")
	var button_point: Vector2 = arena.get_node("HUD/Controls/Shake").get_global_rect().get_center()
	mouse(button_point, true)
	await frames(1)
	check(not launch.aiming, "HUD button press does not also aim")
	mouse(button_point, false)
	await frames(1)
	launch.reset_launch()
	# 只有松手才允许额外冲量，按住/取消均不得改变物理速度。
	player.linear_velocity = Vector2(230, -70)
	var velocity: Vector2 = player.linear_velocity
	launch.begin(Vector2(900, 400))
	check(Engine.time_scale == 1.0, "Aiming always keeps normal time scale")
	launch.advance(0.8)
	check(Engine.time_scale == 1.0, "Long drag never slows or accelerates battle time")
	launch.cancel()
	check(player.linear_velocity.is_equal_approx(velocity), "Begin and cancel never modify rigid-body velocity")
	# 接触点必须贴着实际右边界，不能再次乘主球 transform。
	var impacts: Array[Vector2] = []
	player.impacted.connect(func(point: Vector2, _strength: float): impacts.append(point))
	player.reset_body(Vector2(1100, 250))
	await frames(3)
	player.launch(Vector2(160, 0), 9)
	await frames(30)
	check(not impacts.is_empty(), "Real wall collision produces feedback")
	var aligned: bool = not impacts.is_empty()
	for point in impacts:
		aligned = aligned and absf(point.x - 1240.0) < 6.0 and absf(point.y - 250.0) < 6.0
	check(aligned, "Collision feedback lies on actual wall contact")
	impacts.clear()
	player.publish_impact.call_deferred(Vector2(1240, 250), 300.0, player._reset_revision)
	player.reset_body(Vector2(640, 540))
	await frames(2)
	check(impacts.is_empty(), "Reset discards deferred feedback from previous physics state")
	arena.feedback.play_impact(Vector2(400, 400), 400.0)
	arena.reset_range()
	await frames(1)
	check(arena.feedback._rings.is_empty() and arena.feedback.get_child_count() == 0, "Range reset clears lingering particles and audio nodes")
	check(launch.has_method("refund_cooldown"), "Rice cooldown refund API exists")
	if launch.has_method("refund_cooldown"):
		launch.remaining = 0.4
		launch.request_aim(Vector2(900, 400))
		launch.pointer = Vector2(820, 400)
		launch.refund_cooldown(0.6)
		check(launch.remaining == 0.0 and launch.aiming and launch.pointer == Vector2(820, 400), "Refund reaching ready continues held drag without losing pointer")
		launch.cancel()
	arena.feedback.sound_enabled = true
	for index in 20:
		arena.feedback.play_cue(player.position)
	check(arena.feedback.get_children().filter(func(child): return child is AudioStreamPlayer2D).size() <= 8, "Simultaneous sound voices are bounded")
	arena.feedback.reset_feedback()
	arena.feedback.volume = 0.0
	arena.feedback.play_cue(player.position)
	check(arena.feedback.get_child_count() == 0, "Zero volume allocates no audible voice")
	arena.feedback.sound_enabled = false
	arena.queue_free()
	await process_frame
	if failures == 0:
		print("INPUT FEEDBACK CHECKS PASSED: ", checks)
	quit(0 if failures == 0 else 1)
