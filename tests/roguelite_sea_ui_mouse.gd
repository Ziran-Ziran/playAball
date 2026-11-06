extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("UI mouse timeout"); quit(1))
func check(ok: bool, text: String) -> void:
	print("PASS " if ok else "FAIL ",text)
	if not ok: failures += 1
func click(button: Control) -> void:
	var point: Vector2 = root.get_screen_transform()*button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
		await process_frame
func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1024,576)
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var director = game.director
	director.set_paused(true)
	await process_frame
	check(not director.hud.get_node("Overlay").visible,"Pause isolates title from higher CanvasLayer health skin")
	var pause_title: Label = game.get_node("HUD/Menu/Buttons/Title")
	check(pause_title.is_visible_in_tree() and root.get_visible_rect().encloses(pause_title.get_global_rect()),"Pause title completely visible within viewport")
	await click(game.get_node("HUD/Menu/Buttons/Resume"))
	check(director.hud.get_node("Overlay").visible,"HUD restored after Resume")
	check(not paused and director.state == director.State.BATTLE,"actual mouse Resume crosses GUI into battle")
	director.state = director.State.SHOP
	director.launcher.set_blocked(true)
	paused = true
	director.wallet.balance = 12
	director.health.hp = 3
	director.refresh_rest()
	await process_frame
	await process_frame
	check(director.rest_panel.panel.get_global_rect().position.y >= 0 and director.rest_panel.panel.get_global_rect().end.y <= root.size.y,"First formal Game shop panel fits viewport after deferred layout")
	check(director.rest_panel.actions.get_child(0).get_global_rect().position.y >= 0,"First purchase button inside viewport")
	print("SHOP LAYOUT root=",root.get_visible_rect()," backdrop=",director.rest_panel.get_node("Backdrop").get_global_rect()," panel=",director.rest_panel.panel.get_global_rect())
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/formal_shop_mouse.png")
	await click(director.rest_panel.actions.get_child(0))
	print("SHOP AFTER hp=",director.health.hp," wallet=",director.wallet.balance," bought=",director.shop_bought," rect=",director.rest_panel.actions.get_child(0).get_global_rect())
	check(director.health.hp == 5 and director.wallet.balance == 8 and director.shop_bought.has("heal"),"actual mouse shop heal spends exact wallet amount once")
	await click(director.rest_panel.actions.get_child(0))
	check(director.health.hp == 5 and director.wallet.balance == 8,"actual mouse disabled bought offer cannot repeat transaction")
	director.rest_panel.hide()
	director.finish(false)
	await process_frame
	await process_frame
	await click(director.hud.restart_button)
	check(not paused and director.state == director.State.BATTLE and director.wallet.balance == 0,"actual mouse Restart crosses result UI into fresh battle")
	game.queue_free()
	await process_frame
	await process_frame
	# Restart可在本帧播放短音效，等音频线程完成释放再退出测试引擎。
	await create_timer(0.2).timeout
	print("SEA MOUSE FAILURES ",failures)
	quit(1 if failures else 0)
