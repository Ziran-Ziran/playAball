extends SceneTree
var failures: int = 0
class Actor extends Node2D:
	signal visual_event(kind: StringName,payload: Dictionary)
	func presentation_snapshot() -> Dictionary:
		return {"theme_id":&"fat_fish","velocity":Vector2.ZERO}
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func run() -> void:
	var actor:=Actor.new()
	root.add_child(actor)
	var view=load("res://scenes/roguelite/presentation/fish_ball_view.tscn").instantiate()
	if "--legacy" in OS.get_cmdline_user_args(): view.set_script(load("res://.local/hero_legacy_fixture.gd"))
	actor.add_child(view)
	view.set_process(false)
	var sprite: Sprite2D=view.get_node("Sprite")
	for hz in [30,60,120,144]:
		actor.visual_event.emit(&"reset",{})
		var previous:=Vector2.ZERO
		var max_step: float=0.0
		for frame in hz*3:
			view._process(1.0/hz)
			var size: Vector2=sprite.region_rect.size*sprite.scale
			if frame>0: max_step=maxf(max_step,size.distance_to(previous))
			previous=size
			check(sprite.texture==DemoBallArt.texture_for("hero"),"idle must never switch identity texture")
			check(sprite.position==Vector2.ZERO,"stable visual origin")
		check(max_step<0.7,"idle adjacent size motion bounded at "+str(hz)+"Hz: "+str(max_step))
		for event: StringName in [&"contact",&"damage",&"launch",&"kill"]:
			var before: Vector2=sprite.scale
			actor.visual_event.emit(event,{"speed":900.0,"effective_damage":1,"count":1})
			check(sprite.scale==before,"event does not instantly mutate visible transform")
			var event_previous: Vector2=sprite.region_rect.size*sprite.scale
			var max_event_step: float=0.0
			for frame in hz:
				view._process(1.0/hz)
				var event_size: Vector2=sprite.region_rect.size*sprite.scale
				max_event_step=maxf(max_event_step,event_size.distance_to(event_previous))
				event_previous=event_size
				check(absf(view._elastic)<=0.18,"bounded spring")
			print("EVENT ",event," HZ ",hz," idle ",max_step," event ",max_event_step," velocity ",max_event_step*hz)
			check(max_event_step*hz<190.0,"event visible bounds displacement stays bounded at "+str(hz)+"Hz: "+str(max_event_step))
			check(absf(view._elastic)<0.001,"spring converges")
	actor.queue_free()
	print("SMOOTH HERO failures ",failures)
	quit(1 if failures else 0)
