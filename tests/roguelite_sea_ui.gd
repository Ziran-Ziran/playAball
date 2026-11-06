extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ",message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var rest = load("res://scenes/roguelite/rest_panel.tscn").instantiate()
	root.add_child(rest)
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1024,576)]:
		root.size = resolution
		rest.show_rest("阶段商店", "当前 12币 · 生命3/5\n选择补强，或保留金币继续航行。", [{"id":"buy","text":"购买成长奖励     10 币\n选择一次成长强化","enabled":true},{"id":"poor","text":"金币不足     20 币\n恢复2点生命","enabled":false},{"id":"sold","text":"已购买     本阶段已售罄","enabled":false},{"id":"skip","text":"保留金币 · 继续航行","enabled":true}],42)
		await process_frame
		await process_frame
		check(rest.actions.get_child(0).has_focus(),"First available action focused")
		check(rest.actions.get_child(1).disabled and rest.actions.get_child(2).disabled,"Unavailable states disabled")
		check(rest.panel.get_global_rect().end.x <= resolution.x and rest.panel.get_global_rect().end.y <= resolution.y,"Shop inside viewport")
		check(rest.actions.get_child(0).get_theme_stylebox("normal") != rest.actions.get_child(0).get_theme_stylebox("disabled"),"Disabled visually distinct")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/shop_%d.png" % resolution.x)
	rest.free()
	var hud = load("res://scenes/roguelite/run_hud.tscn").instantiate()
	root.add_child(hud)
	for won: bool in [true,false]:
		hud.show_result(won,18,6)
		await process_frame
		check(hud.restart_button.has_focus(),"Restart is primary focus")
		check(hud.panel.get_global_rect().end.x <= root.size.x,"Result centered in small viewport")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/result_%s.png" % str(won))
	hud.free()
	print("SEA UI: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
