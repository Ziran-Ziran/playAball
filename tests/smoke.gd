extends SceneTree
## 无第三方测试插件；真实物理帧测试，失败以非零状态退出。

var failures: int = 0
var impact_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func _run() -> void:
	if not ResourceLoader.exists("res://scenes/main.tscn"):
		check(false, "Prototype main scene must exist")
		quit(1)
		return
	var level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(160)
	var ball = level.ball
	check(ball.can_launch(), "Ball settles on floor and becomes launchable")
	check(not ball.launch(Vector2.ZERO), "Zero drag cannot fire")
	check(ball.launch(Vector2(1000, -500)), "A settled ball accepts a shot")
	check(not ball.launch(Vector2(100, 0)), "Cannot fire again during flight")
	await frames(1)
	check(ball.linear_velocity.length() <= ball.max_impulse / ball.mass + 20.0, "Shot strength is capped")
	ball.impacted.connect(func(_point, _strength): impact_count += 1)
	await frames(360)
	ball.reset_ball(Vector2(240, 400))
	await frames(180)
	check(impact_count > 0, "Real physics collision emits impact event")
	await frames(300)
	var settled_impacts: int = impact_count
	await frames(120)
	check(impact_count == settled_impacts, "Resting contact does not repeat impact feedback")
	ball.reset_ball(Vector2(240, 604))
	await frames(180)
	check(ball.can_launch(), "Reset returns ball to launchable state")
	check(ball.gravity_scale == 1.0, "Reset restores gravity")
	# 真实进入传感器区域，验证重叠期间和离开之后的状态。
	for mode in [0, 1, 2]:
		level.set_mode(mode)
		ball.reset_ball(Vector2(760, 480))
		await frames(12)
		if mode == 0:
			check(ball.linear_velocity.x > 10.0, "Boost zone accelerates rightward")
		elif mode == 1:
			check(ball.linear_damp > 3.0, "Sticky zone increases damping")
		else:
			check(ball.gravity_scale < 0.0, "Gravity zone reverses gravity")
		ball.reset_ball(Vector2(240, 604))
		await frames(30)
		check(ball.gravity_scale == 1.0 and ball.linear_damp < 1.0, "Leaving zone restores normal physics")
	level.set_mode(0)
	await frames(180)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = level.get_global_transform_with_canvas() * ball.position
	level._unhandled_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = press.position - Vector2(120, -80)
	level._unhandled_input(release)
	check(level.shots == 1, "Mouse events fire using their own coordinates")
	level.reset_round()
	ball.reset_ball(Vector2(1110, 590))
	await frames(20)
	check(level.won, "Entering goal wins")
	check(not ball.launch(Vector2(100, -100)), "Winning disables shooting")
	level.queue_free()
	await process_frame
	if failures == 0:
		print("ALL CHECKS PASSED")
	quit(0 if failures == 0 else 1)
