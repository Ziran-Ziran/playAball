extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ",text)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var run = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(run)
	await process_frame
	await process_frame
	var director = run.get_node("RunDirector")
	for width: int in [1280,1024]:
		root.size = Vector2i(width,720 if width == 1280 else 576)
		for count: int in [3,4]:
			var choices: Array = []
			for id: String in ["companion","bowling","relay","explosion"].slice(0,count):
				choices.append(load("res://resources/roguelite/upgrades/%s.tres" % id))
			director.hud.show_choices(choices,{"companion":2},1,42)
			await create_timer(1.0).timeout
			check(director.hud.cards.get_child_count() == count,"Actual reward card count")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/actual_cards_%d_%d.png" % [width,count])
			director.hud.close()
		director.set_paused(true)
		await process_frame
		check(run.menu.visible and paused,"Pause opens existing menu")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/pause_%d.png" % width)
		run.get_node("HUD/Menu/Buttons/Resume").pressed.emit()
		check(not paused,"Resume signal resumes actual battle")
		for state: String in ["available","poor","bought","supply"]:
			director.state = director.State.EVENT if state == "supply" else director.State.SHOP
			director.wallet.balance = 0 if state == "poor" else 12
			director.health.hp = 3
			director.shop_bought = {"heal":true,"upgrade":true} if state == "bought" else {}
			director.refresh_rest()
			await process_frame
			await process_frame
			var actions = director.rest_panel.actions
			check(actions.get_child(0).disabled == (state in ["poor","bought"]),state+" actual offer enabled")
			check(director.rest_panel.detail.text.contains(str(director.wallet.balance)),"Actual wallet shown")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/actual_%s_%d.png" % [state,width])
			director.rest_panel.hide()
		director.state = director.State.BATTLE
	run.queue_free()
	paused = false
	await process_frame
	print("ACTUAL UI: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
