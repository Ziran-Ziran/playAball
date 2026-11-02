extends RefCounted
## 使用实际属性元数据生成全量目录；资源按编辑路径复制，绝不写回正式.tres。
const Codec = preload("res://scripts/roguelite/lab/tuning_variant.gd")
const EngineAdapter = preload("res://scripts/roguelite/lab/engine_tuning.gd")
const ZH: Dictionary = {"mass":"质量","inertia":"转动惯量","gravity_scale":"重力倍率","linear_damp":"线性阻尼","angular_damp":"角阻尼","friction":"摩擦","bounce":"弹性","continuous_cd":"连续碰撞检测","collision_layer":"碰撞层","collision_mask":"碰撞掩码","speed_limit":"速度上限","max_impulse":"发射冲量","max_drag":"最大拖拽","max_hp":"生命上限","hit_points_override":"初始生命","core_hit_points":"首领核心生命","warning_duration":"预警时长","attack_cooldown":"攻击冷却","approach_speed":"追踪速度","approach_force":"追踪力","charge_speed":"冲刺速度","hazard_speed":"炮弹速度","time_scale":"时间倍率","physics_ticks_per_second":"物理帧率","max_fps":"渲染帧率上限","spawn_interval":"生成间隔","cooldown":"发射冷却","radius":"半径","weight":"抽取权重","enabled":"启用","default_gravity":"默认重力"}
const INITIAL: Array[String] = ["hit_points_override","core_hit_points","module_hit_points","max_hp","kind"]
const TRANSIENT: Array[String] = ["position","global_position","rotation","global_rotation","transform","global_transform","linear_velocity","angular_velocity","sleeping"]
const IDENTITY: Array[String] = ["script","owner","name","resource_path","scene_file_path","unique_name_in_owner"]
var arena: Node2D
var rows: Array[Dictionary] = []
var targets: Dictionary = {}
var overrides: Dictionary = {}
var _index: Dictionary = {}
var engine = EngineAdapter.new()
var _prototype_root: SubViewport
var _owned_globals: Dictionary = {}
var _engine_baseline: Dictionary = {}
var _restoring: bool = false

func setup(owner_arena: Node2D) -> void:
	arena = owner_arena
	engine.space = arena.get_world_2d().space
	for property: Dictionary in Engine.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_EDITOR and Codec.allowed(Engine.get(property.name)):
			_engine_baseline[String(property.name)]=Engine.get(property.name)
	_register("engine","引擎 / Engine",Engine,"引擎")
	_register("project","全部工程设置 / ProjectSettings",ProjectSettings,"工程设置")
	_register("viewport","视口 / Viewport",arena.get_viewport(),"显示")
	for constant: String in ClassDB.class_get_enum_constants("PhysicsServer2D","SpaceParameter"):
		var value: int = ClassDB.class_get_integer_constant("PhysicsServer2D",constant)
		_add_row("space",constant,[],{"name":constant,"type":TYPE_FLOAT,"hint":0,"hint_string":"","usage":6},PhysicsServer2D.space_get_param(engine.space,value),"物理求解", "2D物理空间", value)
	_register("player","主球",arena.player,"主球")
	_register("launch","发射控制",arena.launcher,"发射")
	_register("combat","伤害与接力",arena.combat,"战斗")
	_register("director","整局 / 生成 / 商店",arena.director,"整局")
	_register("health","玩家生命",arena.director.health,"生命")
	_register("companions","伙伴管理",arena.companions,"伙伴")
	_register("rice_manager","白饭生成",arena.director.rice,"白饭")
	_register("assist","护身震退",arena.director.assists,"战斗")
	_register("feedback","碰撞 / 镜头 / 粒子",arena.feedback,"表现")
	_register("audio","音频导演",arena.audio,"表现")
	_register("camera","摄像机",arena.get_node("Camera2D"),"显示")
	_register("rewards","击杀奖励",arena.director.rewards,"奖励")
	for i in arena.director.build.definitions.size():
		arena.director.build.definitions[i] = arena.director.build.definitions[i].duplicate(true)
		var resource: Resource = arena.director.build.definitions[i]
		_register("upgrade_"+resource.id,"升级 / "+resource.title,resource,"奖励")
	for i in arena.director.flow.stages.size():
		arena.director.flow.stages[i] = arena.director.flow.stages[i].duplicate(true)
		_register("stage_"+str(i),"阶段资源 "+str(i+1),arena.director.flow.stages[i],"阶段")
	_prototype_root = SubViewport.new()
	_prototype_root.name = "TuningPrototypes"
	_prototype_root.world_2d = World2D.new()
	_prototype_root.process_mode = Node.PROCESS_MODE_DISABLED
	_prototype_root.render_target_update_mode = SubViewport.UPDATE_DISABLED
	arena.add_child(_prototype_root)
	for spec: Array in [["fragile","普通敌人", "enemy",0],["heavy","重型敌人","enemy",1],["turret","炮台","enemy",2],["boss","首领","boss",0],["companion","伙伴","companion_ball",0],["hazard","危险炮弹","hazard_ball",0],["rice","白饭吸引体","rice_lure",0]]:
		var prototype: Node = load("res://scenes/roguelite/%s.tscn" % spec[2]).instantiate()
		if prototype is DemoEnemy: prototype.kind = int(spec[3])
		_prototype_root.add_child(prototype)
		_register(spec[0],spec[1],prototype,spec[1])
	arena.get_node("Enemies").child_entered_tree.connect(_on_spawn)
	arena.get_node("Hazards").child_entered_tree.connect(_on_spawn)
	arena.companions.child_entered_tree.connect(_on_spawn)
	arena.director.rice.child_entered_tree.connect(_on_spawn)
	arena.director.run_event.connect(_on_run_event)
	# 其余实际场景节点也可检查，不把9项快捷面板当成引擎能力上限。
	_scan_scene(arena)
	rows.sort_custom(func(a: Dictionary,b: Dictionary): return (a.category+a.target+a.name)<(b.category+b.target+b.name))

func _register(id: String,label: String,object: Object,category: String) -> void:
	targets[id] = {"object":object,"label":label,"category":category}
	_scan(id,object,[],{},0)

func _scan_scene(node: Node) -> void:
	for child in node.get_children():
		if child.name in ["LiveTuning","TuningPanel","TuningPrototypes","Enemies","Hazards","CompanionManager"] or child==arena.director.rice: continue
		var registered: bool = false
		for target: Dictionary in targets.values():
			if target.object == child: registered=true; break
		if not registered: _register("scene/"+str(arena.get_path_to(child)),str(arena.get_path_to(child)),child,"场景节点")
		_scan_scene(child)

func _scan(role: String, object: Object, path: Array, ancestors: Dictionary, depth: int) -> void:
	if depth>5 or ancestors.has(object.get_instance_id()): return
	ancestors = ancestors.duplicate()
	ancestors[object.get_instance_id()] = true
	for property: Dictionary in object.get_property_list():
		if (role!="project" and not int(property.usage) & PROPERTY_USAGE_EDITOR) or int(property.type)==TYPE_NIL: continue
		property=property.duplicate()
		property["owner_class"]=object.get_class()
		var value: Variant = object.get(property.name)
		var next: Array = path+[String(property.name)]
		if value is Resource and not value is Script:
			_scan(role,value,next,ancestors,depth+1)
		else:
			_add_row(role,"/".join(next),next,property,value,targets[role].category,targets[role].label)
	if object is Node and role in ["player","fragile","heavy","turret","boss","companion","hazard","rice"]:
		for child in object.get_children(): _scan(role,child,path+["@"+String(child.name)],ancestors,depth+1)

func _add_row(role: String,name: String,path: Array,meta: Dictionary,value: Variant,category: String,label: String,server_param: int = -1) -> void:
	name=name.replace("@","")
	var id: String = role+"::"+name
	if _index.has(id): return
	var editable: bool = Codec.allowed(value) and not String(meta.name) in IDENTITY and not int(meta.usage)&PROPERTY_USAGE_READ_ONLY
	var effect: String = "即时生效"
	if role=="project" and not engine.live_project(name): effect="保存后重启生效 / 部分设置取决于平台"
	elif String(meta.name) in INITIAL: effect="新生成 / 重开生效"
	elif String(meta.name) in TRANSIENT: effect="下一物理帧 / 暂停时需先恢复"
	elif role.begins_with("upgrade_") or role.begins_with("stage_"): effect="后续抽取 / 阶段读取生效"
	var row: Dictionary = {"id":id,"role":role,"name":name,"path":path,"meta":meta,"default":value.duplicate(true) if value is Array or value is Dictionary else value,"category":category,"target":label,"label":ZH.get(String(meta.name),String(meta.name).capitalize()),"editable":editable,"effect":effect,"server_param":server_param}
	rows.append(row)
	_index[id]=row

func find_id(role: String,name: String) -> String:
	var id: String = role+"::"+name
	return id if _index.has(id) else ""

func filtered(category: String,query: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in rows:
		var haystack: String = (row.target+row.name+row.label+row.category).to_lower()
		if (category.is_empty() or row.category==category) and (query.is_empty() or query.to_lower() in haystack): result.append(row)
	return result

func _objects(role: String) -> Array:
	var result: Array = []
	if targets.has(role) and is_instance_valid(targets[role].object): result.append(targets[role].object)
	var members: Array = []
	if role in ["fragile","heavy","turret","boss"]: members=arena.get_node("Enemies").get_children()
	elif role=="companion": members=arena.companions.get_children()
	elif role=="hazard": members=arena.get_node("Hazards").get_children()
	elif role=="rice": members=arena.director.rice.get_children()
	for node in members:
		if _role_for(node)==role: result.append(node)
	return result

func _role_for(node: Node) -> String:
	if node.has_meta("full_tuning_role"): return node.get_meta("full_tuning_role")
	if node is DemoEnemy: return ["fragile","heavy","turret"][node.kind]
	if node is DemoBoss: return "boss"
	if node is DemoCompanion: return "companion"
	if node is DemoHazard: return "hazard"
	if node is DemoRice: return "rice"
	return ""

func _resolve(object: Object,path: Array,copy_resources: bool=false) -> Object:
	for segment: String in path.slice(0,-1):
		if segment.begins_with("@"):
			if not object is Node: return null
			object=object.get_node_or_null(segment.substr(1))
		else:
			var resource: Variant = object.get(segment)
			if not resource is Object: return null
			if copy_resources and resource is Resource and not resource.has_meta("full_tuning_local"):
				resource=resource.duplicate()
				resource.set_meta("full_tuning_local",true)
				object.set(segment,resource)
			object=resource
		if not is_instance_valid(object): return null
	return object

func current_value(id: String) -> Variant:
	if overrides.has(id): return overrides[id]
	if not _index.has(id): return null
	var row: Dictionary = _index[id]
	if row.role=="space": return PhysicsServer2D.space_get_param(engine.space,row.server_param)
	var objects: Array = _objects(row.role)
	if objects.is_empty(): return row.default
	var object: Object = _resolve(objects[0],row.path)
	return object.get(row.path[-1]) if is_instance_valid(object) else row.default

func _valid(row: Dictionary,value: Variant) -> bool:
	if not row.editable or not Codec.allowed(value): return false
	if typeof(value)!=int(row.meta.type) and not (typeof(value) in [TYPE_INT,TYPE_FLOAT] and int(row.meta.type) in [TYPE_INT,TYPE_FLOAT]): return false
	var name: String = String(row.meta.name)
	if name in ["mass","radius","height","width","physics_ticks_per_second","max_physics_steps_per_frame"] or name=="SPACE_PARAM_SOLVER_ITERATIONS":
		if float(value)<=0: return false
	if int(row.meta.hint)==PROPERTY_HINT_RANGE and int(row.meta.type) in [TYPE_FLOAT,TYPE_INT]:
		var parts: PackedStringArray = String(row.meta.hint_string).split(",")
		if parts.size()>=2:
			if not "or_less" in parts and float(value)<float(parts[0]): return false
			if not "or_greater" in parts and float(value)>float(parts[1]): return false
	if int(row.meta.hint)==PROPERTY_HINT_ENUM and int(row.meta.type)==TYPE_INT:
		var choices: Array[int] = []
		var next: int = 0
		for entry: String in String(row.meta.hint_string).split(","):
			var tokens: PackedStringArray = entry.split(":")
			if tokens.size()>1: next=int(tokens[-1])
			choices.append(next)
			next+=1
		if not int(value) in choices: return false
	if name=="max_drag" and float(value)<=8.0: return false
	if int(row.meta.hint)==PROPERTY_HINT_ENUM and value is String and not value in String(row.meta.hint_string).split(","): return false
	if name=="zoom" and value is Vector2 and (is_zero_approx(value.x) or is_zero_approx(value.y)): return false
	if name in ["time_scale","max_fps","friction","bounce"] and float(value)<0.0: return false
	if name=="size" and String(row.meta.get("owner_class","")).ends_with("Shape2D") and value is Vector2 and (value.x<=0 or value.y<=0): return false
	if name=="size" and String(row.meta.get("owner_class",""))=="Window" and value is Vector2i and (value.x<=0 or value.y<=0): return false
	return true

func _aliases(row: Dictionary) -> Array[String]:
	var result: Array[String] = [row.id]
	for key: String in engine.ENGINE_MAP:
		var native: String = String(engine.ENGINE_MAP[key])
		if (row.role=="project" and row.name==key) or (row.role=="engine" and row.name==native):
			for id: String in ["project::"+key,"engine::"+native]:
				if _index.has(id) and not result.has(id): result.append(id)
	return result

func set_value(id: String,value: Variant) -> bool:
	if not _index.has(id) or not _valid(_index[id],value): return false
	var row: Dictionary = _index[id]
	value=type_convert(value,int(row.meta.type))
	for alias: String in _aliases(row): overrides[alias]=value
	arena.launcher.cancel()
	if row.role=="engine":
		for key: String in engine.ENGINE_MAP:
			if engine.ENGINE_MAP[key]==row.name: engine.apply(key,value)
	_apply(row,value,false)
	return true

func _apply(row: Dictionary,value: Variant,pre_ready: bool) -> void:
	if row.role=="project": engine.apply(row.name,value); return
	if row.role=="space":
		if not _owned_globals.has(row.id): _owned_globals[row.id]=PhysicsServer2D.space_get_param(engine.space,row.server_param)
		PhysicsServer2D.space_set_param(engine.space,row.server_param,float(value))
		return
	if row.role=="engine" and not _owned_globals.has(row.id): _owned_globals[row.id]=Engine.get(row.name)
	for root in _objects(row.role): _apply_object(root,row,value,pre_ready)

func _apply_object(root: Object,row: Dictionary,value: Variant,pre_ready: bool) -> void:
	var property: String = row.path[-1]
	if property in INITIAL and root is Node and root.is_node_ready() and root.get_parent()!=_prototype_root and not pre_ready: return
	var object: Object = _resolve(root,row.path,true)
	if not is_instance_valid(object): return
	if object is DemoBody and property in TRANSIENT and object.is_inside_tree():
		object.request_debug_state(property,value)
		return
	if row.role=="launch" and property=="cooldown":
		arena.launcher.remaining *= maxf(float(value),0.001)/maxf(arena.launcher.cooldown,0.001)
	object.set(property,value)
	if root is CanvasItem: root.queue_redraw()

func picked(role: String,name: String,fallback: Variant) -> Variant:
	return overrides.get(role+"::"+name,fallback)

func apply_maintained() -> void:
	# 只维护配置值；位置/速度是一次性操作，不会每帧把运动钉死。
	for id: String in overrides:
		var row: Dictionary = _index[id]
		if row.role in ["project","space","engine"] or String(row.meta.name) in TRANSIENT or String(row.meta.name) in INITIAL: continue
		for root in _objects(row.role):
			var object: Object = _resolve(root,row.path)
			if is_instance_valid(object) and object.get(row.path[-1])!=overrides[id]: _apply_object(root,row,overrides[id],false)

func _on_spawn(node: Node) -> void:
	var role: String = _role_for(node)
	if role.is_empty(): return
	node.set_meta("full_tuning_role",role)
	for id: String in overrides:
		if _index[id].role==role: _apply_object(node,_index[id],overrides[id],true)
	if not node.is_node_ready(): node.ready.connect(func():
		for id: String in overrides:
			if _index[id].role==role and not String(_index[id].meta.name) in INITIAL: _apply_object(node,_index[id],overrides[id],false)
	,CONNECT_ONE_SHOT)

func _after_restart() -> void:
	if not is_instance_valid(arena): return
	var id: String = find_id("health","max_hp")
	if overrides.has(id):
		arena.director.health.max_hp=int(overrides[id])
		arena.director.health.reset_health()
	apply_maintained()

func _on_run_event(event: String) -> void:
	if event == "reset": _after_restart.call_deferred()

func reset_value(id: String) -> void:
	if not _index.has(id): return
	var row: Dictionary = _index[id]
	for alias: String in _aliases(row): overrides.erase(alias)
	if row.role=="project": engine.restore(row.name)
	else: _apply(row,row.default,false)
	for key: String in engine.ENGINE_MAP:
		if (row.role=="engine" and row.name==engine.ENGINE_MAP[key]) or (row.role=="project" and row.name==key):
			engine.restore(key)
			Engine.set(engine.ENGINE_MAP[key],_engine_baseline[engine.ENGINE_MAP[key]])

func reset_all() -> void:
	for id: String in overrides.keys(): reset_value(id)

func record() -> Dictionary:
	var result: Dictionary = {}
	for id: String in overrides: result[id]=Codec.pack(overrides[id])
	return result

func load_record(record_data: Dictionary) -> bool:
	var decoded: Dictionary = {}
	for id: String in record_data:
		var value: Variant = Codec.unpack(record_data[id])
		if not _index.has(id) or not _valid(_index[id],value): return false
		decoded[id]=value
	for id: String in decoded:
		for alias: String in _aliases(_index[id]):
			if decoded.has(alias) and decoded[alias]!=decoded[id]: return false
	reset_all()
	for id: String in decoded: set_value(id,decoded[id])
	return true

func cleanup() -> void:
	engine.restore_all()
	for id: String in _owned_globals:
		var row: Dictionary = _index[id]
		if row.role=="space": PhysicsServer2D.space_set_param(engine.space,row.server_param,_owned_globals[id])
	for property: String in _engine_baseline: Engine.set(property,_engine_baseline[property])
	# 断开捕获自身的回调，避免RefCounted与场景信号形成闭环。
	for node: Node in [arena.get_node("Enemies"),arena.get_node("Hazards"),arena.companions,arena.director.rice]:
		if node.child_entered_tree.is_connected(_on_spawn): node.child_entered_tree.disconnect(_on_spawn)
	if arena.director.run_event.is_connected(_on_run_event): arena.director.run_event.disconnect(_on_run_event)
