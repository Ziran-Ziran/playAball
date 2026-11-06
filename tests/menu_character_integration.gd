extends SceneTree
## 直接经过正式菜单与Godot输入分发检查；图形模式验证真实模型，headless只验证回退导航。
var failures: int = 0
var checks: Array[Dictionary] = []
var output: String = ""
var expect_live: bool = false
var missing_runtime: bool = false
var saved_settings: PackedByteArray
var had_settings: bool = false
var finished: bool = false

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg == "--expect-live2d": expect_live = true
		if arg == "--missing-runtime": missing_runtime = true
	call_deferred("run")
	create_timer(35.0).timeout.connect(func(): _check(false,"bounded test timeout"); finish())

func _check(ok: bool, label: String, evidence: Dictionary = {}) -> void:
	checks.append({"passed":ok,"label":label,"evidence":evidence})
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label," ",evidence)

func frames(count: int) -> void:
	for frame: int in count: await process_frame

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_screen_transform() * point
	Input.parse_input_event(event)

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = root.get_screen_transform() * point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)

func click(point: Vector2) -> void:
	motion(point)
	mouse(point,true)
	await frames(2)
	mouse(point,false)
	await frames(2)

func settle_actor(actor: Node2D, count: int = 90) -> void:
	for frame: int in count: actor.call("step_character",1.0/60.0)
	await frames(3)

func capture(view: Control, name: String) -> Image:
	if DisplayServer.get_name() == "headless": return null
	await RenderingServer.frame_post_draw
	var image: Image = view.get_node("Stage").get_texture().get_image()
	if not output.is_empty():
		image.save_png(output.path_join(name+".png"))
		root.get_texture().get_image().save_png(output.path_join(name+"_menu.png"))
	return image

func run() -> void:
	had_settings = FileAccess.file_exists("user://ui_settings.cfg")
	if had_settings: saved_settings = FileAccess.get_file_as_bytes("user://ui_settings.cfg")
	var settings_fixture := ConfigFile.new()
	settings_fixture.load("user://ui_settings.cfg")
	settings_fixture.set_value("visual","reduced_motion",true)
	settings_fixture.save("user://ui_settings.cfg")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	_check(menu.has_node("MenuCharacter"),"F5 menu contains interactive character component")
	if not menu.has_node("MenuCharacter"):
		menu.free()
		finish()
		return
	if missing_runtime:
		menu.get_node("MenuCharacter/Stage/Character").set("model_path","res://.local/menu_character_runtime/missing.model3.json")
	root.add_child(menu)
	current_scene = menu
	await frames(8)
	var view: Control = menu.get_node("MenuCharacter")
	var actor: Node2D = view.get_node("Stage/Character")
	var persisted := ConfigFile.new()
	persisted.load("user://ui_settings.cfg")
	_check(bool(persisted.get_value("visual","reduced_motion",false)),"menu startup preserves reduced-motion preference")
	menu.call("apply_volume",0.37)
	persisted.load("user://ui_settings.cfg")
	_check(bool(persisted.get_value("visual","reduced_motion",false)),"changing volume preserves visual settings")
	menu.call("apply_reduced_motion",false)
	persisted.load("user://ui_settings.cfg")
	_check(is_equal_approx(float(persisted.get_value("audio","volume",0.0)),0.37),"changing visual settings preserves volume")
	menu.call("apply_reduced_motion",true)
	# 注视范围在正常动态模式下验证，不依赖这台电脑原来的用户偏好。
	actor.call("set_reduced_motion",false)
	# 自动输入检查独立于窗口是否被别的应用遮住；另测真实焦点信号造成的阻断。
	root.focus_entered.emit()
	await frames(2)
	var live: bool = bool(actor.get("loaded"))
	_check(live == (expect_live and not missing_runtime),"expected runtime availability",{"live":live,"reason":actor.get("load_error")})
	_check(view.get_node("Fallback").visible != live,"static fallback and live portrait are exclusive")
	_check(menu.get_node("Start") is TextureButton,"existing Start button retained")
	if live:
		motion(Vector2(15,145))
		await frames(2)
		await settle_actor(actor)
		var left: float = float(actor.get("parameters")["AngleX"].get("value"))
		var left_image: Image = await capture(view,"look_left")
		motion(Vector2(1270,145))
		await frames(2)
		await settle_actor(actor)
		var right: float = float(actor.get("parameters")["AngleX"].get("value"))
		var right_image: Image = await capture(view,"look_right")
		_check(left < -12.0 and right > 12.0,"mouse moves real head input both directions",{"left":left,"right":right})
		_check(left_image.get_data() != right_image.get_data(),"rendered model responds to gaze")
		motion(view.call("logical_to_menu",Vector2(360,155)))
		await frames(2)
		await settle_actor(actor)
		var count: int = int(actor.get("reaction_count"))
		await click(Vector2(605,30))
		_check(int(actor.get("reaction_count")) == count,"transparent empty area does not trigger character")
		var head: Vector2 = view.call("canonical_to_menu",Vector2(360,110))
		_check(bool(view.call("hits_character",head)),"scaled head coordinate hits actual opaque pixels")
		await click(head)
		await settle_actor(actor,4)
		_check(str(actor.get("state")) == "pet","head click triggers pet response")
		_check(float(actor.get("parameters")["ParamEyeLOpen"].get("value")) < 0.25,"pet response uses real eyelid parameter")
		await capture(view,"pet")
		await settle_actor(actor,160)
		var cheek: Vector2 = view.call("canonical_to_menu",Vector2(375,185))
		await click(cheek)
		await settle_actor(actor,4)
		_check(str(actor.get("state")) == "cheek","face click triggers cheek response")
		_check(float(actor.get("parameters")["CheeckPuff"].get("value")) > 0.02,"cheek response drives authored puff input")
		await capture(view,"cheek")
		await settle_actor(actor,160)
		var body: Vector2 = view.call("canonical_to_menu",Vector2(360,310))
		await click(body)
		_check(str(actor.get("state")) == "greet","body click triggers short greeting")
		await settle_actor(actor,160)
		for index: int in 3: await click(head)
		_check(str(actor.get("state")) == "surprised","rapid repeat clicks produce gentle surprise once")
		count = int(actor.get("reaction_count"))
		menu.call("show_settings")
		await click(head)
		_check(int(actor.get("reaction_count")) == count and bool(actor.get("blocked")),"settings blocks character input")
		_check(menu.get_node("Start").disabled,"settings still disables Start")
		menu.call("close_settings")
		root.focus_exited.emit()
		await click(head)
		_check(int(actor.get("reaction_count")) == count and bool(actor.get("blocked")),"focus loss cancels interaction")
		root.focus_entered.emit()
		await settle_actor(actor,160)
		await click(head)
		_check(int(actor.get("reaction_count")) > count,"focus return restores interaction")
		actor.call("set_reduced_motion",true)
		_check(not bool(actor.get("model").get("physics_evaluate")),"reduced motion disables secondary motion")
		actor.call("set_reduced_motion",false)
		_check(bool(actor.get("model").get("physics_evaluate")),"restoring motion resumes authored physics")
	else:
		menu.call("show_settings")
		_check(menu.get_node("Start").disabled,"fallback settings still disables Start")
		menu.call("close_settings")
	var model_reference: WeakRef = weakref(actor.get("model")) if live else null
	await click(Vector2(330,425))
	await frames(5)
	_check(is_instance_valid(current_scene) and current_scene.name == "Game","Start enters existing game scene")
	if live: _check(model_reference.get_ref() == null,"menu model node releases on entering game")
	if is_instance_valid(current_scene) and current_scene.name == "Game":
		current_scene.call("return_to_menu")
		await frames(8)
		_check(current_scene.name == "MainMenu","existing return-to-menu restores F5 menu")
		# 缺失路径只注入首个组件；正常返回菜单应重新使用已准备的资源。
		var restored: Node2D = current_scene.get_node("MenuCharacter/Stage/Character")
		if not missing_runtime or expect_live:
			_check(bool(restored.get("loaded")) == expect_live,"return menu restores expected backend")
		else:
			_check(not str(restored.get("model_path")).contains("missing.model3.json"),"missing path injection is scoped to first menu")
			_check(current_scene.get_node("MenuCharacter/Fallback").visible != bool(restored.get("loaded")),"return menu backend and fallback remain consistent")
		_check(bool(restored.get("reduced_motion")),"reduced-motion preference survives returning to menu")
	if is_instance_valid(current_scene): current_scene.queue_free()
	await frames(4)
	finish()

func finish() -> void:
	if finished: return
	finished = true
	if had_settings:
		var file: FileAccess = FileAccess.open("user://ui_settings.cfg",FileAccess.WRITE)
		file.store_buffer(saved_settings)
		file.close()
	elif FileAccess.file_exists("user://ui_settings.cfg"):
		# 只删除本测试在原本无设置时创建的这一份配置，不触碰其它用户数据。
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ui_settings.cfg"))
	if not output.is_empty():
		var file: FileAccess = FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"backend":DisplayServer.get_name()},"  "))
		file.close()
	print("MENU CHARACTER CHECKS: ",checks.size()," failures: ",failures)
	quit(1 if failures else 0)
