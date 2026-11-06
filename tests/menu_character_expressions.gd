extends SceneTree
var failures: int = 0
var checks: int = 0
var output: String = "res://.local/menu_expression_20261106"
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)
func frames(count: int) -> void:
	for index: int in count: await process_frame
func snapshot(view: Node, label: String) -> void:
	await RenderingServer.frame_post_draw
	view.get_node("Stage").get_texture().get_image().save_png(output.path_join(label+".png"))
	root.get_texture().get_image().save_png(output.path_join(label+"_menu.png"))
func value(actor: Node, id: String) -> float:
	return float(actor.parameters[id].get("value"))
func run() -> void:
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await frames(8)
	var view: Control = menu.get_node("MenuCharacter")
	var actor: Node = view.character
	if not actor.loaded:
		check(DisplayServer.get_name() == "headless", "live backend required for native expression evidence")
		menu.queue_free()
		await frames(3)
		quit(failures)
		return
	actor.set_reduced_motion(false)
	root.focus_entered.emit()
	actor.request_reaction("pet")
	actor.request_reaction("pet")
	actor.request_reaction("pet")
	for index: int in 20: actor.step_character(1.0/60.0)
	await snapshot(view,"rapid_repeat")
	check(is_zero_approx(value(actor,"key1")), "rapid repeat must never activate authored black-face key1")
	check(is_zero_approx(value(actor,"key6")), "rapid repeat must never activate sinister-eye key6")
	actor.set_blocked(true)
	check(actor.state == "idle" and actor.reaction_remaining == 0.0, "blocking must immediately clear active expression")
	check(is_zero_approx(value(actor,"key1")), "blocking must immediately clear black face")
	actor.set_blocked(false)
	actor.set_reduced_motion(true)
	check(not actor.request_reaction("pet"), "reduced motion must block reaction requests")
	actor.set_reduced_motion(false)
	var signatures: Array[String] = []
	for kind: String in ["pet", "cheek", "greet", "shy", "surprised"]:
		actor.set_blocked(true)
		actor.set_blocked(false)
		check(actor.request_reaction(kind), "accept safe expression " + kind)
		for index: int in 18: actor.step_character(1.0/60.0)
		var values: Array[float] = []
		for id: String in ["ParamEyeLOpen","ParamEyeROpen","EyeSmile","ParamMouthForm","ParamMouthOpenY","CheeckPuff","key7"]:
			values.append(snappedf(value(actor,id),0.01))
		signatures.append(str(values))
		check(is_zero_approx(value(actor,"key1")) and is_zero_approx(value(actor,"key6")), "safe face parameters " + kind)
		await snapshot(view,kind)
		for index: int in 150: actor.step_character(1.0/60.0)
		check(actor.state == "idle", "short recovery " + kind)
	var unique: Dictionary = {}
	for signature: String in signatures: unique[signature] = true
	check(unique.size() >= 4, "at least four visibly distinct real parameter sets")
	actor.set_blocked(true)
	await snapshot(view,"safe_neutral")
	menu.queue_free()
	await frames(8)
	print("MENU EXPRESSION CHECKS ",checks," failures ",failures)
	quit(1 if failures else 0)
