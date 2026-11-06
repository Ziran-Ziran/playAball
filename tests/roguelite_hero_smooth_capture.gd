extends SceneTree
class Actor extends Node2D:
	signal visual_event(kind: StringName,payload: Dictionary)
	func presentation_snapshot() -> Dictionary: return {"theme_id":&"fat_fish","velocity":Vector2.ZERO}
func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("HERO CAPTURE: native rendering required; no screenshot generated")
		quit()
		return
	create_timer(20.0).timeout.connect(func(): push_error("Hero capture timeout"); quit(1))
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var a:=Actor.new()
	root.add_child(a)
	a.position=Vector2(-1000,-1000)
	var v=load("res://scenes/roguelite/presentation/fish_ball_view.tscn").instantiate()
	a.add_child(v)
	v.set_process(false)
	v.hide()
	for row in 3:
		a.visual_event.emit(&"reset",{})
		if row==1:a.visual_event.emit(&"contact",{"speed":900.0})
		if row==2:a.visual_event.emit(&"damage",{"effective_damage":1})
		for frame in 12:
			v._process(0.12 if row==0 else 1.0/30.0)
			var original: Sprite2D=v.get_node("Sprite")
			for zoom in 2:
				var s:=Sprite2D.new()
				s.texture=original.texture
				s.region_enabled=true
				s.region_rect=original.region_rect
				s.scale=original.scale*(1.0 if zoom==0 else 1.6)
				s.position=Vector2(55+frame*105,50+row*230+zoom*105)
				root.add_child(s)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/hero_smooth_sequence.png")
	for child in root.get_children():
		if child!=a: child.queue_free()
	a.position=Vector2(640,360)
	v.set_process(true)
	for frame in 36:
		if frame==8:a.visual_event.emit(&"contact",{"speed":900.0})
		if frame==22:a.visual_event.emit(&"damage",{"effective_damage":1})
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/hero_native_frame_%02d.png"%frame)
	quit()
