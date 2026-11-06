extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
	create_timer(25).timeout.connect(func(): quit(1))
func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(640,576)
	var hud = load("res://scripts/roguelite/run_hud.gd").new()
	var copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/roguelite/upgrade_card_copy.json"))["cards"]
	for id: String in copy:
		var card = load("res://scenes/roguelite/presentation/upgrade_card.tscn").instantiate()
		root.add_child(card)
		card.position = Vector2(175,40)
		card.size = Vector2(290,480)
		var definition = load("res://resources/roguelite/upgrades/%s.tres" % id)
		card.configure(definition,1,("生命 3 → 5 / 5\n本次恢复 2" if id == "heal" else hud.benefit_preview(id,{})),copy[id],load("res://assets/cards/%s_%s.png" % [id,"repeat" if definition.max_level == 0 else "lv1"]))
		var flow := Control.new()
		flow.set_script(load("res://scripts/ui/card_flow.gd"))
		card.add_child(flow)
		card.mouse_entered.emit()
		await process_frame
		await process_frame
		var end: float = 0
		for key: String in ["Category","Heading","Illustration","Level","Preview","Detail","Flavor"]:
			var child: Control = card.get_node("Content/"+key)
			if child.position.x < 19 or child.position.y < end or child.get_rect().end.x > card.size.x-19 or child.get_rect().end.y > card.size.y-19:
				failures += 1
				print("FAIL ",id," ",key," ",child.get_rect())
			end = child.get_rect().end.y
		if DisplayServer.get_name() != "headless" and id in ["companion","relay"]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/flow_290_%s.png" % id)
		card.queue_free()
		await process_frame
	hud.free()
	print("CONTENT FLOW 16 cards failures ",failures)
	quit(1 if failures else 0)
