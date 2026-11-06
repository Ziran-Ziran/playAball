extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func frames(count: int) -> void:
	for index in count: await process_frame
func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_screen_transform()*point
	Input.parse_input_event(event)
func click(point: Vector2) -> void:
	motion(point)
	for pressed: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = root.get_screen_transform()*point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
func value(actor: Node,id: String) -> float: return float(actor.parameters[id].get("value"))
func mesh_points(actor: Node, region: Rect2) -> Dictionary:
	var result: Dictionary = {}
	var meshes: Dictionary = actor.model.call("get_meshes")
	for key: Variant in meshes:
		var mesh: MeshInstance2D = meshes[key]
		if not mesh.visible or mesh.mesh.get_surface_count()==0: continue
		var vertices: PackedVector2Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for index in vertices.size():
			var point: Vector2 = mesh.get_global_transform()*vertices[index]
			if region.has_point(point): result[str(key)+":"+str(index)] = point
	return result
func mesh_displacement(before: Dictionary, after: Dictionary) -> float:
	var largest: float = 0.0
	for key: String in before:
		if after.has(key): largest = maxf(largest,before[key].distance_to(after[key]))
	return largest
func run() -> void:
	if "--small" in OS.get_cmdline_user_args(): root.size = Vector2i(1024,576)
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await frames(8)
	var view = menu.character_view
	var actor = view.character
	if not actor.loaded:
		check(DisplayServer.get_name()=="headless","native renderer required when graphics backend exists")
		menu.queue_free()
		await frames(4)
		quit(failures)
		return
	actor.set_reduced_motion(false)
	root.focus_entered.emit()
	var point: Vector2 = view.canonical_to_menu(Vector2(360,110))
	motion(point)
	await create_timer(0.8).timeout
	check(view.hits_character(point),"actual head target hits alpha silhouette")
	var count: int = actor.reaction_count
	var head_region := Rect2(220,40,280,210)
	var head_before: Dictionary = mesh_points(actor,head_region)
	var head_shift: float = 0.0
	await click(point)
	check(actor.reaction_count==count+1,"GUI head click reaches real model reaction")
	var low: float = 100.0
	var high: float = -100.0
	var root_position: Vector2 = actor.model.position
	for sample in 45:
		await create_timer(0.025).timeout
		var y: float = value(actor,"AngleY")
		low = minf(low,y)
		high = maxf(high,y)
		if sample in [8,20,32]:
			head_shift = maxf(head_shift,mesh_displacement(head_before,mesh_points(actor,head_region)))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/menu_actions_20261106/head_%d.png" % sample)
	check(head_shift > 1.0,"actual Cubism head mesh vertices visibly deform after GUI nod")
	print("HEAD MESH SHIFT ",head_shift)
	check(high-low > 9.0,"head click produces clearly visible nod over time")
	check(actor.model.position == root_position,"response changes model parameters not whole portrait position")
	check(value(actor,"key1")==0.0 and value(actor,"key6")==0.0,"black face remains forbidden throughout action")
	print("NOD RANGE ",low," .. ",high)
	await create_timer(1.0).timeout
	for item: Dictionary in [{"name":"left_cheek","point":Vector2(340,185),"state":"wink","parameter":"AngleZ","span":5.0},{"name":"right_cheek","point":Vector2(380,185),"state":"cheek","parameter":"AngleX","span":10.0},{"name":"upper_body","point":Vector2(360,310),"state":"greet","parameter":"PositionY","span":2.0}]:
		point = view.canonical_to_menu(item.point)
		motion(point)
		await create_timer(0.8).timeout
		count = actor.reaction_count
		var region: Rect2 = Rect2(240,250,240,240) if item.name == "upper_body" else head_region
		var vertices_before: Dictionary = mesh_points(actor,region)
		var mesh_shift: float = 0.0
		await click(point)
		check(actor.state==item.state and actor.reaction_count==count+1,"GUI fixed region maps to "+item.name)
		low = 100.0
		high = -100.0
		var samples: Array = []
		for sample in 45:
			await create_timer(0.025).timeout
			var parameter: float = value(actor,item.parameter)
			low = minf(low,parameter)
			high = maxf(high,parameter)
			samples.append({"time":actor.reaction_elapsed,"input":parameter,"head_x":value(actor,"ParamAngleX"),"head_y":value(actor,"ParamAngleY"),"head_z":value(actor,"ParamAngleZ")})
			check(value(actor,"key1")==0.0 and value(actor,"key6")==0.0,"safe parameters during "+item.name)
			if sample in [8,20,32]:
				mesh_shift = maxf(mesh_shift,mesh_displacement(vertices_before,mesh_points(actor,region)))
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/menu_actions_20261106/%s_%d.png" % [item.name,sample])
		check(mesh_shift > 1.0,"actual Cubism mesh moves for "+item.name)
		print("MESH SHIFT ",item.name," ",mesh_shift)
		check(high-low > item.span,"visible model input variation "+item.name)
		var file: FileAccess = FileAccess.open("res://.local/menu_actions_20261106/"+item.name+"_samples.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(samples,"  "))
		file.close()
		await create_timer(1.0).timeout
	point = view.canonical_to_menu(Vector2(360,110))
	await click(point)
	await click(point)
	await click(point)
	check(actor.state=="surprised","three actual GUI clicks map to gentle surprise")
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/menu_actions_20261106/triple.png")
	menu.show_settings()
	check(actor.state=="idle" and actor.gesture_head==Vector3.ZERO and actor.gesture_body==Vector3.ZERO,"settings cancels visible action immediately")
	menu.close_settings()
	actor.set_reduced_motion(true)
	count = actor.reaction_count
	await click(point)
	check(actor.reaction_count==count and menu.interaction_status.text.contains("减少动态"),"reduced-motion click explains why action is disabled")
	actor.set_reduced_motion(false)
	root.focus_exited.emit()
	check(actor.state=="idle" and actor.gesture_head==Vector3.ZERO,"focus loss clears body action")
	root.focus_entered.emit()
	await create_timer(0.3).timeout
	var stroke_start: Vector2 = view.canonical_to_menu(Vector2(340,110))
	var stroke_end: Vector2 = view.canonical_to_menu(Vector2(380,110))
	motion(stroke_start)
	var press := InputEventMouseButton.new()
	press.position = root.get_screen_transform()*stroke_start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await create_timer(0.3).timeout
	motion(stroke_end)
	await frames(2)
	var release := InputEventMouseButton.new()
	release.position = root.get_screen_transform()*stroke_end
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await frames(2)
	check(actor.state=="pet_sway","actual held head stroke maps to closed-eye sway")
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/menu_actions_20261106/stroke.png")
	await click(view.canonical_to_menu(Vector2(380,185)))
	check(actor.state=="cheek","new region can interrupt a response after short cooldown")
	var labels: Array[Control] = []
	for child in menu.get_children():
		if child is Label and child.position.y >= 600.0: labels.append(child)
	for index in labels.size():
		check(root.get_visible_rect().encloses(labels[index].get_global_rect()),"interaction guide stays inside visible viewport")
		for other in range(index+1,labels.size()):
			check(not labels[index].get_global_rect().intersects(labels[other].get_global_rect()),"interaction guide status and credits do not overlap")
	menu.queue_free()
	await frames(8)
	print("MENU ACTION CHECKS ",checks," failures ",failures)
	quit(1 if failures else 0)
