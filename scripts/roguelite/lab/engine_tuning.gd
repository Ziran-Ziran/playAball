extends RefCounted
## 工程设置与运行时接口不同：只有已映射的项才声称即时生效。
const ENGINE_MAP: Dictionary = {
	"physics/common/physics_ticks_per_second":"physics_ticks_per_second",
	"physics/common/max_physics_steps_per_frame":"max_physics_steps_per_frame",
	"physics/common/physics_jitter_fix":"physics_jitter_fix", "application/run/max_fps":"max_fps",
}
const AREA_MAP: Dictionary = {
	"physics/2d/default_gravity":PhysicsServer2D.AREA_PARAM_GRAVITY,
	"physics/2d/default_gravity_vector":PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR,
	"physics/2d/default_linear_damp":PhysicsServer2D.AREA_PARAM_LINEAR_DAMP,
	"physics/2d/default_angular_damp":PhysicsServer2D.AREA_PARAM_ANGULAR_DAMP,
}
var space: RID
var originals: Dictionary = {}
var project_changes: Dictionary = {}

func live_project(key: String) -> bool:
	return ENGINE_MAP.has(key) or AREA_MAP.has(key)

func apply(key: String, value: Variant) -> void:
	if not originals.has(key): originals[key] = ProjectSettings.get_setting(key)
	ProjectSettings.set_setting(key,value)
	project_changes[key] = value
	if ENGINE_MAP.has(key): Engine.set(ENGINE_MAP[key],value)
	elif AREA_MAP.has(key): PhysicsServer2D.area_set_param(space,AREA_MAP[key],value)

func restore(key: String) -> void:
	if originals.has(key):
		var value: Variant = originals[key]
		apply(key,value)
		project_changes.erase(key)

func restore_all() -> void:
	for key: String in originals: restore(key)

func save_restart_settings(directory: String) -> Error:
	var config := ConfigFile.new()
	var path: String = directory.path_join("override.cfg")
	var error: Error = config.load(path)
	if error not in [OK,ERR_FILE_NOT_FOUND]: return error
	var previous: Array = config.get_value("live_tuning","keys",[])
	for key: String in previous:
		var slash: int = key.find("/")
		if slash > 0 and config.has_section_key(key.left(slash),key.substr(slash+1)):
			config.erase_section_key(key.left(slash),key.substr(slash+1))
	for key: String in project_changes:
		var slash: int = key.find("/")
		if slash > 0: config.set_value(key.left(slash),key.substr(slash+1),project_changes[key])
	config.set_value("live_tuning","keys",Array(project_changes.keys()))
	return config.save(path)

func clear_restart_settings(directory: String) -> Error:
	var config := ConfigFile.new()
	var path: String = directory.path_join("override.cfg")
	var error: Error = config.load(path)
	if error==ERR_FILE_NOT_FOUND: return OK
	if error!=OK: return error
	for key: String in config.get_value("live_tuning","keys",[]):
		var slash: int=key.find("/")
		if slash>0 and config.has_section_key(key.left(slash),key.substr(slash+1)):
			config.erase_section_key(key.left(slash),key.substr(slash+1))
	config.set_value("live_tuning","keys",[])
	return config.save(path)
