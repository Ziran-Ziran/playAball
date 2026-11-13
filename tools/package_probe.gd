extends SceneTree
## 同版编辑器引擎以--main-pack读取EXE内嵌资源执行外部探针；不打进普通包。
var failures: Array[String] = []
var manifest: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
	create_timer(25).timeout.connect(func():push_error("Package probe timeout");quit(1))
func check(ok: bool,message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures.append(message)
func walk(path: String) -> void:
	for filename in DirAccess.get_files_at(path): manifest.append(path.path_join(filename))
	for directory in DirAccess.get_directories_at(path): walk(path.path_join(directory))
func mouse(point: Vector2,pressed: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.position=point
	event.pressed=pressed
	Input.parse_input_event(event)
func validate_physical_maps() -> void:
	# 导出重打包曾丢失实例内部添加的节点和端点覆盖，必须检查实际包而非仅资源存在。
	var counts: Dictionary={"map_01":0,"map_02":2,"map_03":2,"boss_map":4}
	for id: String in counts:
		var map: Node=load("res://scenes/roguelite/maps/%s.tscn"%id).instantiate()
		var spikes: Array[Node]=[]
		for node: Node in map.find_children("*","Area2D",true,false):
			if node.has_method("_currently_touching_player"):spikes.append(node)
		check(spikes.size()==counts[id],"Packaged map retains exact spike count: "+id)
		for spike: Node in spikes:
			var length: float=26.0 if id=="boss_map" else (36.0 if id=="map_02" else 180.0)
			check(is_equal_approx(spike.length,length) and spike.get_node("Shape").shape.size==Vector2(length,spike.tooth_depth+5.0) and spike.collision_mask==2,"Packaged authored spike shape/length/mask retained: "+id+"/"+str(spike.name))
		if id=="map_02":
			check(map.has_node("CrossPivot/Paddle/VerticalShape") and map.has_node("CrossPivot/Paddle/VisualVertical"),"Packaged cross paddle retains vertical physical and visual arm")
		if id=="map_03":
			check(map.get_node("Portals/A").position==Vector2(-500,0) and map.get_node("Portals/B").position==Vector2(500,0),"Packaged portal endpoints retain authored overrides")
		if id=="boss_map":
			check(map.get_node("GreenPortals/A").position==Vector2(0,-115) and map.get_node("GreenPortals/B").position==Vector2(0,115),"Packaged green portals pair vertically")
			check(map.get_node("YellowPortals/A").position==Vector2(-115,0) and map.get_node("YellowPortals/B").position==Vector2(115,0),"Packaged yellow portals pair horizontally")
		map.free()
func run() -> void:
	walk("res://")
	manifest.sort()
	check(str(ProjectSettings.get_setting("application/run/main_scene"))=="res://scenes/ui/main_menu.tscn","Ordinary package starts at main menu")
	for path: String in ["credits.txt", "music.txt", "ZCOOL_OFL.txt", "Noto_OFL.txt", "Kenney_CC0.txt"]:
		check(FileAccess.file_exists("res://resources/legal/" + path), "Packaged readable credits/license: " + path)
	for path in ["scenes/roguelite/audio_preview.tscn","scenes/main.tscn","scenes/ball.tscn","scenes/mechanism.tscn"]:
		check(not ResourceLoader.exists("res://"+path),"Excluded prototype/preview: "+path)
	for path in ["scenes/roguelite/tuning_run.tscn","scenes/roguelite/tuning_panel.tscn","scenes/roguelite/gameplay_lab.tscn","scenes/roguelite/lab_panel.tscn","scripts/roguelite/live_tuning.gd","scripts/roguelite/evaluation/scenario_runner.gd","resources/roguelite/balance/baseline.tres","assets/roguelite/presentation/generation_metadata.json"]:
		check(not ResourceLoader.exists("res://"+path) and not FileAccess.file_exists("res://"+path),"Excluded: "+path)
	for path in manifest:
		if path.begins_with("res://tests/") or path.begins_with("res://docs/") or path.begins_with("res://.local/") or path.contains("handfeel_preset"):
			check(false,"Unexpected private/developer content: "+path)
	validate_physical_maps()
	# 音频在导出后通常只保留导入资源；必须从实际PCK验证音乐，而非检查源码文件。
	check(ResourceLoader.exists("res://assets/music/let_me_go.mp3"),"Packaged supplied Let Me Go audio resource exists")
	var music: Node = root.get_node_or_null("MusicManager")
	check(music != null,"Packaged persistent MusicManager autoload exists")
	var music_player_id: int = -1
	if music != null:
		await create_timer(0.12,true).timeout
		var music_state: Dictionary = music.call("snapshot")
		music_player_id = int(music_state.player_id)
		check(music_state.available and music_state.playing and float(music_state.length)>120.0,"Packaged full supplied track decodes and plays")
		check(float(music_state.position)>0.0,"Packaged music playback actually advances")
	var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	menu.show_settings()
	menu.credits_panel.call("open")
	check(menu.credits_panel.visible and menu.credits_panel.body.text.contains("Kenney") and menu.credits_panel.body.text.contains("SIL"), "Packaged settings can read full credits and license text")
	menu.call("_notification", Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not menu.credits_panel.visible and menu.settings_panel.visible, "Back handler closes credits before underlying settings")
	menu.close_settings()
	await process_frame
	menu.get_node("Start").pressed.emit()
	await process_frame
	await process_frame
	var game=current_scene
	if music != null:
		check(int(music.call("snapshot").player_id)==music_player_id,"Packaged menu to Game keeps one music player")
	check(game.has_node("RunDirector"),"Menu Start enters actual packaged Game")
	if not game.has_node("RunDirector"):
		quit(1)
		return
	game.director.set_process(false)
	game.feedback.sound_enabled=false
	check(game.director.wave==1 and game.companions.members.is_empty(),"Formal first map has zero starting companions")
	check(game.player.get_node("Presentation").recharge_pulse_left==0.0,"Packaged fresh spawn has no false recharge cue")
	check(game.director.build.definitions.size()==15,"All dynamic upgrade resources exist")
	# 正式卡面通过FileAccess读JSON；必须检查真实导出包，不能仅验证编辑器文件。
	check(FileAccess.file_exists("res://resources/roguelite/card_art_catalog.json") and FileAccess.file_exists("res://resources/roguelite/upgrade_card_copy.json"),"Packaged card art index and copy JSON exist")
	var card_library: DemoCardArtLibrary = DemoCardArtLibrary.new()
	var card_images: int = 0
	for definition: DemoUpgrade in game.director.build.definitions + [game.director.build.fallback]:
		for rank: int in range(1,maxi(1,definition.max_level)+1):
			card_images += 1
			check(card_library.texture_for(definition.id,rank)!=null,"Packaged next-rank illustration: %s/%d"%[definition.id,rank])
	check(card_images==28,"Packaged all 28 level illustrations load")
	var bowling_copy: String = card_library.copy_for("bowling").get("rules", "")
	check(bowling_copy.contains("不会继续传代") and bowling_copy.contains("最多对2"),"Packaged bowling copy retains bounded non-recursive projectile and finish payoff")
	for id in ["map_01","map_02","map_03","boss_map"]:
		check(ResourceLoader.exists("res://scenes/roguelite/maps/%s.tscn"%id),"Packaged physical map exists: "+id)
	for path in ["fat_fish_ball_v1.png","fragile_crate_v1.png"]:
		check(load("res://assets/roguelite/presentation/"+path)!=null,"Packaged imported sprite exists: "+path)
	for kind in 3:
		var actor=load("res://scenes/roguelite/enemy.tscn").instantiate()
		actor.kind=kind
		root.add_child(actor)
		actor.freeze=true
		actor.set_physics_process(false)
		var art: Texture2D=actor.presentation.material_for_kind(kind)
		var region: Rect2=actor.presentation.material_region_for_kind(kind)
		check(region.position.x>=0 and region.position.y>=0 and region.end.x<=art.get_width() and region.end.y<=art.get_height(),"Actual imported crop fits texture pixels: "+str(kind))
		var img: Image=art.get_image()
		check(img.get_pixelv(Vector2i(region.get_center())).a>0.9,"Actual crop center contains opaque enemy material: "+str(kind))
		actor.queue_free()
	for tick in 3: await physics_frame
	check(game.get_node("HUD/Hint").visible,"Packaged first launch has a passive instruction")
	check(is_equal_approx(game.combat.transfer_retention,0.85),"Rejected transfer candidates did not change formal default")
	mouse(Vector2(600,55),true)
	await process_frame
	await process_frame
	# Headless导出包读取的UI更新可能晚于连续process_frame信号，给实际更新50ms。
	await create_timer(0.05).timeout
	check(game.launcher.aiming and not game.get_node("HUD/Hint").visible,"Hint area passes pointer gesture and clears during aim")
	mouse(Vector2(720,55),false)
	await process_frame
	await process_frame
	check(game.launcher.shots==1,"Packaged pointer drag performs a real legal launch")
	await create_timer(game.launcher.cooldown+0.02).timeout
	check(game.launcher.available() and game.player.get_node("Presentation").recharge_pulse_left>0.0,"Natural packaged cooldown completion triggers its separate readiness cue")
	# 明确的地图/成长夹具：检查动态载入后的实际节点，不冒充自然奖励或通关。
	game.director.debug_build(PackedStringArray(["companion","companion","companion"]))
	game.director.wallet.balance=17
	for wave in [3,5,6]:
		game.director.debug_wave(wave)
		game.director.pending.clear()
		for tick in 10:
			await physics_frame
			await process_frame
		check(game.companions.members.size()==3 and game.director.wallet.balance==17,"Packaged map transition preserves earned party/economy: "+str(wave))
		check(game.director.health.hp==5,"Packaged safe map entry has no phantom spike damage: "+str(wave))
	check(game.director.boss.get_node_or_null("Presentation/Status/Label")!=null,"Packaged boss view and phase HUD instantiate")
	var boss_view: Node2D=game.director.boss.get_node("Presentation")
	check(boss_view.get_node("Status/Label").text.contains("秒"),"Packaged boss warning displays remaining real time")
	var armor: Texture2D=boss_view.ARMOR_ART
	var region: Rect2=boss_view.armor_material_region()
	check(region.end.x<=armor.get_width() and region.end.y<=armor.get_height() and armor.get_image().get_pixelv(Vector2i(region.get_center())).a>0.9,"Packaged boss armor crop has actual opaque imported material")
	game.set_paused(true)
	check(paused and game.launcher.blocked,"Packaged pause blocks launch")
	game.set_paused(false)
	game.director.health.hurt(99)
	check(game.director.state==game.director.State.DEFEAT,"Actual health death opens defeat state")
	game.get_node("RunHUD").restart_button.pressed.emit()
	await process_frame
	check(not paused and game.director.wave==1 and game.director.health.hp==5 and game.companions.members.is_empty(),"Packaged result restart restores clean first run")
	check(game.player.get_node("Presentation").recharge_pulse_left==0.0,"Packaged restart clears previous readiness presentation")
	# 胜利界面入口是明确的状态夹具，不冒充自然打赢首领。
	game.director.finish(true)
	game.get_node("RunHUD").home_button.pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.has_node("Start") and not paused,"Packaged result returns to main menu")
	current_scene.queue_free()
	await create_timer(0.4).timeout
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():
		var file:=FileAccess.open(args[0],FileAccess.WRITE)
		file.store_string(JSON.stringify({"manifest":manifest,"failures":failures,"engine":Engine.get_version_info().string},"\t"))
	print("PACKAGE PROBE PASSED" if failures.is_empty() else "PACKAGE PROBE FAILED")
	quit(0 if failures.is_empty() else 1)
