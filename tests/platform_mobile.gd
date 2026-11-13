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
func touch(index: int, point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	return event
func run() -> void:
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame
	check(game.has_method("cancel_pointer_gesture"), "shared pointer cancellation exists")
	check(game.has_method("handle_back_request"), "Android back has explicit handler")
	check(game.has_method("handle_application_suspended"), "background cancellation exists")
	if not game.has_method("cancel_pointer_gesture"):
		game.queue_free()
		await process_frame
		quit(1)
		return
	game._unhandled_input(touch(3,Vector2(700,450),true))
	check(game.launcher.aiming and paused,"first finger owns frozen aim")
	game._unhandled_input(touch(7,Vector2(900,450),true))
	game._input(touch(7,Vector2(800,450),false))
	check(game.launcher.aiming and game.launcher.shots==0,"second finger cannot release or steal")
	var drag := InputEventScreenDrag.new()
	drag.index=3
	drag.position=Vector2(550,450)
	game._input(drag)
	check(game.launcher.pointer==drag.position,"owned drag updates screen-space pointer")
	game._input(touch(3,Vector2(550,450),false))
	check(game.launcher.shots==1 and not paused,"one gesture fires exactly once")
	game.launcher.remaining=0
	game._unhandled_input(touch(5,Vector2(700,450),true))
	var canceled := touch(5,Vector2(500,450),false)
	canceled.canceled=true
	game._input(canceled)
	check(not paused and not game.launcher.input_held and game.launcher.shots==1,"OS-canceled gesture never fires")
	game._unhandled_input(touch(6,Vector2(700,450),true))
	var synthetic := InputEventMouseButton.new()
	synthetic.device=InputEvent.DEVICE_ID_EMULATION
	synthetic.button_index=MOUSE_BUTTON_LEFT
	synthetic.pressed=false
	synthetic.position=Vector2(400,450)
	game._input(synthetic)
	check(game.launcher.aiming and game.launcher.shots==1,"emulated mouse release cannot duplicate native touch")
	game.cancel_pointer_gesture()
	game.launcher.remaining=0.1
	game._unhandled_input(touch(8,Vector2(700,450),true))
	check(game.launcher.input_held and not paused,"touch waits during cooldown")
	game.launcher.advance(0.2)
	check(game.launcher.aiming and paused,"held finger starts aim when charge ready")
	game.mobile_controls=true
	game._process(0)
	game._input(touch(9,game._cancel_button.position+Vector2(10,10),true))
	check(not paused and not game.launcher.input_held,"second finger may use explicit cancel button")
	var desktop := InputEventMouseButton.new()
	desktop.button_index=MOUSE_BUTTON_LEFT
	desktop.pressed=true
	desktop.position=Vector2(700,450)
	game._unhandled_input(desktop)
	check(game.launcher.aiming,"desktop left mouse still aims")
	desktop.button_index=MOUSE_BUTTON_RIGHT
	game._input(desktop)
	check(not paused and not game.launcher.input_held,"desktop right mouse still cancels")
	game.launcher.remaining=0
	game._unhandled_input(touch(1,Vector2(700,450),true))
	game.handle_application_suspended()
	check(game.paused and paused and not game.launcher.input_held,"background enters explicit pause")
	game._input(touch(1,Vector2(500,450),false))
	check(game.launcher.shots==1,"stale release after background cannot fire")
	game.handle_back_request()
	check(not paused,"back resumes explicit pause")
	game.director.rewards.pending=1
	game.director.open_upgrade()
	game.handle_back_request()
	check(paused and game.director.state==game.director.State.UPGRADE,"back preserves reward pause owner")
	check(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")==120,"physics rate retained")
	var feedback: Node = game.feedback
	game.audio.reset_audio()
	game.audio.set_mix(0.65,0.65,false)
	game.audio.set_audio_paused(false)
	feedback.sound_enabled=true
	for i in 18:
		feedback.add_child(CPUParticles2D.new())
	var sounds: Array = []
	game.audio.event_played.connect(func(event: StringName,_variant: int,_db: float): sounds.append(event))
	feedback.play_impact(Vector2(600,400),600)
	check(not sounds.is_empty(),"particle budget does not suppress legal sound")
	if game.has_method("logical_safe_rect"):
		var safe: Rect2 = game.logical_safe_rect(Rect2(30,0,1220,720),Transform2D.IDENTITY)
		check(safe==Rect2(30,0,1220,720),"safe-area conversion keeps physics coordinates")
	if DisplayServer.get_name()!="headless":
		game.director.restart()
		await process_frame
		game.mobile_controls=true
		game.set_paused(true)
		root.size=Vector2i(1024,576)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/platform-mobile-gui.png")
	game.queue_free()
	await process_frame
	print("PLATFORM MOBILE CHECKS ",checks," failures ",failures)
	quit(1 if failures else 0)
