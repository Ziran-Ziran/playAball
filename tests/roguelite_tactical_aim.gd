extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var arena = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	check(arena.get_node_or_null("AimIndicator") != null, "formal Game must use single textured aim indicator")
	if "--navigation" in OS.get_cmdline_user_args():
		arena.aim_indicator.arrow_style = 1
	var launch = arena.launcher
	var director = arena.director
	await physics_frame
	await physics_frame
	arena.player.linear_velocity = Vector2(75, -30)
	launch.request_aim(Vector2(700, 450))
	check(paused, "ready aim must pause battlefield")
	launch.pointer = Vector2(600, 510)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var first_image: Image = root.get_texture().get_image()
		first_image.save_png("res://.local/tactical_aim.png")
		await create_timer(0.07, true).timeout
		await RenderingServer.frame_post_draw
		var next_image: Image = root.get_texture().get_image()
		next_image.save_png("res://.local/tactical_aim_flow.png")
		check(first_image.get_data() != next_image.get_data(), "formal Game paused rendering must animate between frames")
	check("_draw_aim_feedback()" in FileAccess.get_file_as_string("res://scripts/ui/game.gd"), "formal Game must delegate shared animated aim drawing")
	arena._hurt_flash = 0.3
	arena._process(0.1)
	check(arena._hurt_flash == 0.3, "paused world hurt flash must retain lifetime")
	director._pulse_left = 0.3
	director._process(0.1)
	check(director._pulse_left == 0.3, "paused battle pulse must retain lifetime")
	check(arena.aim_indicator.get_node("SingleArrowHead") is Sprite2D, "one textured head must be wired")
	check(arena.aim_indicator.get_child_count() == 3, "single head plus only two soft trail sprites")
	arena.rotation = 0.2
	arena.scale = Vector2(1.2, 1.2)
	arena._draw_aim_feedback()
	check(Vector2.RIGHT.rotated(arena.aim_indicator.global_rotation).dot(arena._last_aim_drag.normalized()) > 0.999, "rotated scaled parent must preserve actual world direction")
	arena.rotation = 0.0
	arena.scale = Vector2.ONE
	arena._draw_aim_feedback()
	var position_before: Vector2 = arena.player.position
	var velocity_before: Vector2 = arena.player.linear_velocity
	var spawn_before: float = director.spawn_left
	var elapsed: float = director.wave_elapsed
	await create_timer(0.12, true).timeout
	check(arena.player.position == position_before, "paused physics must retain position")
	check(arena.player.linear_velocity == velocity_before, "paused physics must retain velocity")
	check(director.spawn_left == spawn_before, "paused spawner must retain countdown")
	director.advance(0.5)
	check(director.wave_elapsed == elapsed, "aim must freeze battle clock")
	var phase_before: float = arena._aim_phase
	arena._process(0.05)
	check(arena._aim_phase != phase_before, "aim animation must continue during pause")
	launch.cancel()
	check(not paused, "cancel must resume own pause")
	launch.remaining = 0.2
	launch.request_aim(Vector2(700, 450))
	check(not paused and not launch.aiming, "waiting must not freeze cooldown")
	launch.advance(0.3)
	check(paused and launch.aiming, "ready held input must enter pause")
	director.set_paused(true)
	launch.cancel()
	check(paused, "cancel must preserve menu pause")
	director.set_paused(false)
	launch.set_capacity(2)
	launch.charges = 1
	launch.remaining = 1.0
	launch.request_aim(Vector2(700, 450))
	launch.advance(5.0)
	check(launch.charges == 1 and launch.remaining == 1.0, "aim cannot refill second charge")
	launch.cancel()
	launch.request_aim(Vector2(700, 450))
	check(not launch.release(Vector2(701, 451)) and not paused, "tiny release must resume without firing")
	launch.request_aim(Vector2(700, 450))
	launch._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not paused and not launch.input_held, "focus loss must cancel and resume owned pause")
	launch.request_aim(Vector2(700, 450))
	check(launch.release(Vector2(600, 450)) and not paused, "valid release must fire and resume")
	check(arena._aim_recoil > 0.0, "valid release must trigger recoil animation")
	check(arena._last_aim_drag == Vector2(100, 0), "recoil must use actual release direction")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/tactical_aim_recoil.png")
		check(arena._aim_recoil > 0.0, "formal Game must retain visible recoil on release frame")
	director.restart()
	check(arena._aim_recoil == 0.0 and arena._last_aim_drag == Vector2.ZERO and not arena.aim_indicator.visible, "restart must clear released aim presentation immediately")
	check(not paused and not launch.input_held and launch.charges == 1, "restart must reset aim pause and charges")
	await physics_frame
	await physics_frame
	launch.request_aim(Vector2(700, 450))
	check(launch.release(Vector2(600, 450)), "fresh run release must fire")
	director.set_paused(true)
	check(paused and arena._aim_recoil == 0.0 and not arena.aim_indicator.visible, "external menu must immediately clear release trail without resuming")
	director.set_paused(false)
	arena.queue_free()
	await process_frame
	# 发射音的混音线程晚于树节点释放；等其回收，避免测试退出留下WAV播放引用。
	await create_timer(0.15).timeout
	print("tactical aim failures: ", failures)
	quit(1 if failures else 0)
