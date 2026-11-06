extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Formal Game UI timeout"); quit(1))
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; print("FAIL ",label)
func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1024,576)
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var director = game.director
	var ids: Array = director.hud.card_art.copy_data.keys() if "copy_data" in director.hud.card_art else []
	var copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/roguelite/upgrade_card_copy.json"))["cards"]
	ids = copy.keys()
	for index in range(0,ids.size(),4):
		var choices: Array = []
		for id in ids.slice(index,index+4): choices.append(load("res://resources/roguelite/upgrades/%s.tres" % id))
		director.hud.show_choices(choices,{},1,42)
		await create_timer(0.9).timeout
		for card in director.hud.cards.get_children():
			var id: String = card.get_meta("upgrade_id")
			for name: String in ["Heading","Preview","Detail","Flavor"]:
				var label: Label = card.get_node("Content/"+name)
				var text_height: float = label.get_line_count()*label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))
				print(id," ",name," card=",card.size," rect=",label.get_rect()," text_height=",text_height)
				check(text_height <= label.size.y+1.0,id+" "+name+" actual text within allocated height")
			var detail: Label = card.get_node("Content/Detail")
			var flavor: Label = card.get_node("Content/Flavor")
			check(detail.position.y+detail.get_line_count()*detail.get_theme_font("font").get_height(detail.get_theme_font_size("font_size")) < flavor.position.y,id+" actual text does not collide flavor")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/formal_game_%d.png" % index)
	director.hud.close()
	director.set_paused(true)
	check(paused and game.menu.visible,"formal Game pause opens")
	check(not director.hud.get_node("Overlay").visible,"Pause isolates title from higher CanvasLayer health skin")
	var pause_title: Label = game.get_node("HUD/Menu/Buttons/Title")
	check(pause_title.is_visible_in_tree() and root.get_visible_rect().encloses(pause_title.get_global_rect()),"Pause title completely visible within viewport")
	game.get_node("HUD/Menu/Buttons/Resume").pressed.emit()
	check(director.hud.get_node("Overlay").visible,"HUD restored after Resume")
	check(not paused,"formal Game resumes")
	director.state = director.State.SHOP
	director.wallet.balance = 0
	director.health.hp = 3
	director.refresh_rest()
	var hp: int = director.health.hp
	director.rest_panel.actions.get_child(0).pressed.emit()
	check(director.wallet.balance == 0 and director.health.hp == hp,"forged disabled purchase cannot bypass wallet")
	director.finish(false)
	director.hud.restart_button.pressed.emit()
	check(director.state == director.State.BATTLE and not paused,"formal Game result restart returns battle")
	game.queue_free()
	# Restart刚发出音频事件；等待节点释放与音频线程交接，不在同一帧结束进程。
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	print("FORMAL GAME REGRESSION FAILURES ",failures)
	quit(1 if failures else 0)
