extends SceneTree
## 原生窗口的Input.parse_input_event鼠标路径；不是直接发Button.pressed，也不是OS鼠标录制。
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(40).timeout.connect(func(): quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func click(control: Control) -> void:
	var point: Vector2 = root.get_screen_transform() * control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var reduced: bool = OceanUi.reduced_motion
	OceanUi.reduced_motion = false
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1024, 576)]:
		for count in [3, 4]:
			root.size = resolution
			var game = load("res://scenes/roguelite/run.tscn").instantiate()
			root.add_child(game)
			await process_frame
			var d = game.director
			d.set_process(false)
			d.pending.clear()
			d.clear_container(d.enemies)
			if count == 4: d.build.choose("choices")
			d.wallet.balance = 40
			d.rewards.pending = 1
			d.open_upgrade()
			await create_timer(0.9).timeout
			var hud = d.hud
			check(root.get_visible_rect().encloses(hud.panel.get_global_rect()), "Panel fits " + str(resolution) + " cards=" + str(count))
			check(root.get_visible_rect().encloses(hud.reroll_row.get_global_rect()), "Wallet/price/remaining row remains visible")
			check(hud.cards.get_child_count() == count and hud.choices_ready(d._choice_revision), "All cards ready after real entrance")
			for card: Control in hud.cards.get_children():
				for key in ["Category", "Heading", "Level", "Preview", "Detail", "Flavor"]:
					var text: Control = card.get_node("Content/" + key)
					check(text.get_rect().end.y <= card.size.y + 1, "Full text remains inside scrollable card: " + key)
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/economy-gui-%dx%d-%d.png" % [resolution.x, resolution.y, count])
			if resolution.y == 576:
				var scroll: ScrollContainer = hud._choice_scroll
				var point: Vector2 = root.get_screen_transform() * scroll.get_global_rect().get_center()
				for step in 12:
					var wheel := InputEventMouseButton.new()
					wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
					wheel.pressed = true
					wheel.position = point
					Input.parse_input_event(wheel)
					await process_frame
					wheel = wheel.duplicate()
					wheel.pressed = false
					Input.parse_input_event(wheel)
					await process_frame
				check(scroll.scroll_vertical > 0, "Actual wheel events reveal full lower card content on narrow viewport")
				for card: Control in hud.cards.get_children():
					check(scroll.get_global_rect().encloses(card.get_node("Content/Flavor").get_global_rect()), "Card final text can be fully reached by scrolling")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://.local/economy-gui-%dx%d-%d-bottom.png" % [resolution.x, resolution.y, count])
				scroll.scroll_vertical = 0
				await process_frame
				await process_frame
			var old_revision: int = d._choice_revision
			await click(hud.reroll_button)
			print("GUI REROLL ", resolution, " ", count, " wallet=", d.wallet.balance, " used=", d.rerolls_used, " ready=", hud.choices_ready(d._choice_revision), " button=", hud.reroll_button.get_global_rect())
			check(d.wallet.balance == 34 and d.rerolls_used == 1 and d._choice_revision != old_revision, "Real GUI reroll spends exact first price")
			await click(hud.reroll_button)
			await click(hud.cards.get_child(0))
			check(d.wallet.balance == 34 and d.rerolls_used == 1 and d.state == d.State.UPGRADE and d.rewards.pending == 1, "Refresh entrance blocks double charge and premature card selection")
			await create_timer(0.9).timeout
			await click(hud.cards.get_child(0))
			check(d.state == d.State.BATTLE and d.rewards.pending == 0 and d.chosen_rewards == 1, "New ready card accepts real mouse once")
			paused = false
			game.queue_free()
			await process_frame
	OceanUi.reduced_motion = reduced
	print("BUILD ECONOMY GUI CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)
