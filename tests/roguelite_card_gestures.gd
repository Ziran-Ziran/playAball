extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func finger(index: int, point: Vector2, down: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index=index
	event.position=point
	event.pressed=down
	return event
func mouse(point: Vector2, down: bool, device: int = 0) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position=point
	event.pressed=down
	event.button_index=MOUSE_BUTTON_LEFT
	event.device=device
	return event
func run() -> void:
	var game=load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame
	var hud=game.director.hud
	# 真实奖励会阻断战场输入；夹具也必须保留该边界，否则拖动会被战场抢走。
	game.director.state=game.director.State.UPGRADE
	game.launcher.set_blocked(true)
	paused=true
	OceanUi.reduced_motion=true
	hud.show_choices([load("res://resources/roguelite/upgrades/echo.tres")],{},1,901)
	hud.show_reroll(6,6,3,true)
	await process_frame
	await process_frame
	var card: Button=hud.cards.get_child(0)
	check(card.has_method("can_submit_selection"),"gesture submission guard exists")
	if not card.has_method("can_submit_selection"):
		game.queue_free()
		await process_frame
		quit(1)
		return
	var selected: Array=[]
	hud.upgrade_selected.connect(func(id: String,offer: int):selected.append([id,offer]))
	var origin: Vector2=card.get_global_rect().get_center()
	card._input(finger(2,origin,true))
	var drag:=InputEventScreenDrag.new()
	drag.index=2
	drag.position=origin+Vector2(0,-200)
	card._input(drag)
	card._input(finger(2,drag.position,false))
	card._input(mouse(drag.position,false,InputEvent.DEVICE_ID_EMULATION))
	card.pressed.emit()
	check(selected.is_empty(),"touch drag followed by release cannot commit")
	check(not card.can_submit_selection(),"release preserves rejection until next real press")
	card._input(mouse(origin,true,InputEvent.DEVICE_ID_EMULATION))
	check(not card.can_submit_selection(),"synthetic mouse press cannot reset native drag")
	card._input(finger(4,origin,true))
	card._input(finger(4,origin,false))
	card.pressed.emit()
	check(selected.size()==1,"stationary native tap commits once")
	card._input(mouse(origin,true))
	var motion:=InputEventMouseMotion.new()
	motion.position=origin+Vector2(70,0)
	card._input(motion)
	card._input(mouse(motion.position,false))
	card.pressed.emit()
	check(selected.size()==1,"real mouse drag cannot commit")
	var accept:=InputEventKey.new()
	accept.keycode=KEY_ENTER
	accept.physical_keycode=KEY_ENTER
	accept.pressed=true
	card._input(accept)
	card.pressed.emit()
	check(selected.size()==2,"keyboard accept works after pointer drag")
	card._input(mouse(origin,true))
	card._input(mouse(origin,false))
	card.pressed.emit()
	check(selected.size()==3,"stationary mouse click works")
	card._input(finger(5,origin,true))
	card._input(finger(5,origin+Vector2(19,0),false))
	card.pressed.emit()
	check(selected.size()==3,"release displacement is checked without motion event")
	check(is_instance_valid(hud._choice_scroll),"shared scroll wrapper retained")
	selected.clear()
	Input.emulate_mouse_from_touch=true
	Input.parse_input_event(finger(0,origin,true))
	var native_drag:=InputEventScreenDrag.new()
	native_drag.index=0
	native_drag.position=origin+Vector2(0,-100)
	native_drag.relative=Vector2(0,-100)
	Input.parse_input_event(native_drag)
	Input.parse_input_event(finger(0,native_drag.position,false))
	await process_frame
	check(selected.is_empty(),"actual viewport touch drag never submits card")
	Input.parse_input_event(finger(0,origin,true))
	Input.parse_input_event(finger(0,origin,false))
	await process_frame
	if DisplayServer.get_name()!="headless":
		check(selected.size()==1,"actual viewport tap submits exactly once after drag")
	else:
		print("SKIP native GUI tap hit-test on headless backend; explicit event guard checks remain active")
	# 内容超过视窗时，原滚动容器仍拥有运动；测试只加长说明，不修改玩法数值。
	card.get_node("Content/Detail").text="长卡滚动检查。\n".repeat(40)
	card._layout()
	await process_frame
	await process_frame
	selected.clear()
	var visible_point:=Vector2(card.get_global_rect().get_center().x,hud._choice_scroll.get_global_rect().get_center().y)
	Input.parse_input_event(finger(0,visible_point,true))
	await process_frame
	for step: int in [1,2,3]:
		native_drag.position=visible_point+Vector2(0,-40*step)
		native_drag.relative=Vector2(0,-40)
		Input.parse_input_event(native_drag)
		await process_frame
	Input.parse_input_event(finger(0,native_drag.position,false))
	await process_frame
	check(selected.is_empty(),"long content touch drag cannot commit")
	check(card.custom_minimum_size.y>hud._choice_scroll.size.y,"long content remains taller than scroll viewport")
	if DisplayServer.get_name()!="headless":
		# 桌面DisplayServer不是触屏设备；验证原滚轮传播，安卓原生滑动另做包上复验。
		var wheel:=mouse(visible_point,true)
		wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
		Input.parse_input_event(wheel)
		await process_frame
		check(hud._choice_scroll.scroll_vertical>0,"long-card mouse wheel still reaches scroll container")
	card._input(finger(0,visible_point,true))
	card._input(finger(0,visible_point,false))
	card.pressed.emit()
	check(selected.size()==1,"new tap remains available on long content after dragging")
	game.queue_free()
	await process_frame
	print("CARD GESTURE CHECKS ",checks," failures ",failures)
	quit(1 if failures else 0)
