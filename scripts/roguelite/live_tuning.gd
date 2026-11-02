extends Node
## 策划调参入口：只接受白名单物理量，不写正式资源，不复制战斗/成长规则。
const DEFAULTS: Dictionary = {
	"launch_impulse": 1050.0, "linear_damping": 0.12, "bounce": 0.85,
	"friction": 0.05, "enemy_mass_scale": 1.0, "impact_retention": 0.65,
	"stagger": 0.65, "cooldown": 2.2, "opposing_momentum": 0.0,
}
const SPECS: Array[Dictionary] = [
	{"id": "launch_impulse", "label": "发射冲量", "min": 300.0, "max": 2200.0, "step": 25.0, "hint": "越大越有力；下一次发射使用新值"},
	{"id": "linear_damping", "label": "主球阻尼", "min": 0.0, "max": 2.0, "step": 0.01, "hint": "越大停得越快，当前运动立即受影响"},
	{"id": "bounce", "label": "球的弹性", "min": 0.0, "max": 1.0, "step": 0.01, "hint": "主球与伙伴；越大碰撞后越弹"},
	{"id": "friction", "label": "球的摩擦", "min": 0.0, "max": 1.0, "step": 0.01, "hint": "主球与伙伴的接触摩擦"},
	{"id": "enemy_mass_scale", "label": "敌人质量倍率", "min": 0.25, "max": 3.0, "step": 0.05, "hint": "越小越容易推开；普通0.2/重敌0.55 × 此值"},
	{"id": "impact_retention", "label": "撞敌续力保留", "min": 0.0, "max": 1.0, "step": 0.01, "hint": "有效撞敌时的目标速度比例，保留原有限续力预算"},
	{"id": "stagger", "label": "敌人受击硬直 / 秒", "min": 0.0, "max": 1.5, "step": 0.05, "hint": "下次有效受击后暂停追踪的时长"},
	{"id": "cooldown", "label": "基础发射冷却 / 秒", "min": 0.3, "max": 4.0, "step": 0.05, "hint": "越小越能连续发射；现有恢复百分比保留"},
	{"id": "opposing_momentum", "label": "抵消反向动量比例", "min": 0.0, "max": 1.0, "step": 0.05, "hint": "0保留惯性；1消除旧速度中与新发射相反的分量"},
]
var values: Dictionary = DEFAULTS.duplicate()
var arena: Node2D
var panel: CanvasLayer
var pause_while_editing: bool = true
var _owns_pause: bool = false
var _comparison: Dictionary = DEFAULTS.duplicate()
var _refresh_left: float = 0.0
var full: RefCounted
var _full_comparison: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(owner_arena: Node2D, view: CanvasLayer) -> void:
	arena = owner_arena
	panel = view
	panel.configure(SPECS, values)
	panel.parameter_requested.connect(set_parameter)
	panel.action_requested.connect(_on_action)
	panel.pause_preference_changed.connect(set_pause_preference)
	full = load("res://scripts/roguelite/lab/full_tuning.gd").new()
	full.setup(arena)
	panel.attach_full(full)
	_apply_values()
	panel.set_status("拖动即生效 · F1展开/收起 · 参数随重开保留")

func _physics_process(_delta: float) -> void:
	# 正式成长/重开会从原基准重算；随后将本轮调参基准叠回，避免升级丢参数。
	if is_instance_valid(arena):
		_apply_values()

func _process(delta: float) -> void:
	if not is_instance_valid(arena):
		return
	if panel.is_open():
		_take_pause()
	if full != null: full.apply_maintained()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = 0.1
		panel.set_readout("实际冲量 %.0f · 阻尼 %.2f · 冷却 %.2fs\n敌人质量 普通%.2f / 重型%.2f · 当前速度 %.0f\n%s" % [
			arena.player.max_impulse, arena.player.linear_damp, arena.launcher.cooldown,
			0.2 * values.enemy_mass_scale, 0.55 * values.enemy_mass_scale,
			arena.player.linear_velocity.length(), "战斗已暂停，收起继续试" if _owns_pause else "同局实时调参，成长仍叠加",
		])

func set_parameter(id: String, amount: float) -> bool:
	if not DEFAULTS.has(id) or is_nan(amount) or is_inf(amount):
		return false
	for spec: Dictionary in SPECS:
		if spec.id == id:
			values[id] = clampf(amount, float(spec.min), float(spec.max))
			break
	arena.launcher.cancel()
	_apply_values()
	panel.set_values(values)
	panel.set_status("已生效：%s · 无需重开" % _label_for(id))
	return true

func _label_for(id: String) -> String:
	for spec: Dictionary in SPECS:
		if spec.id == id:
			return String(spec.label)
	return id

func _apply_values() -> void:
	var build: DemoBuild = arena.director.build
	var player: DemoPlayer = arena.player
	player.max_impulse = _picked("player","max_impulse",float(values.launch_impulse) * build.launch_multiplier())
	player.linear_damp = _picked("player","linear_damp",float(values.linear_damping) * build.damping_multiplier())
	player.impact_drive_retention = _picked("player","impact_drive_retention",float(values.impact_retention))
	player.cancel_opposing_momentum = _picked("player","cancel_opposing_momentum",float(values.opposing_momentum))
	_apply_material(player, float(values.friction) * build.friction_multiplier())
	for member: DemoCompanion in arena.companions.members:
		_apply_material(member, float(values.friction))
	var launcher: DemoLaunch = arena.launcher
	var cooldown: float = _picked("launch","cooldown",float(values.cooldown) * build.launch_cooldown() / float(DEFAULTS.cooldown))
	if not is_equal_approx(launcher.cooldown, cooldown):
		launcher.remaining *= cooldown / maxf(0.001, launcher.cooldown)
		launcher.cooldown = cooldown
	for body in arena.get_node("Enemies").get_children():
		if body is DemoEnemy and not body.dead:
			var role: String = full._role_for(body) if full != null else ""
			var mass: float = _picked(role,"mass",(0.55 if body.kind == DemoEnemy.Kind.HEAVY else 0.2) * float(values.enemy_mass_scale))
			if not is_equal_approx(body.mass, mass):
				body.mass = mass
				body.sleeping = false
			body.hit_stagger = _picked(role,"hit_stagger",float(values.stagger))
	if full != null: full.apply_maintained()

func _picked(role: String,key: String,fallback: float) -> float:
	return float(full.picked(role,key,fallback)) if full != null else fallback

func _apply_material(body: RigidBody2D, friction: float) -> void:
	# 各实例独享材质；调参不能污染同场景资源或之后的正式run。
	if not body.has_meta("live_tuning_material"):
		body.physics_material_override = body.physics_material_override.duplicate()
		body.set_meta("live_tuning_material", true)
	var role: String = "player" if body==arena.player else "companion"
	var bounce: float = _picked(role,"physics_material_override/bounce",float(values.bounce))
	friction = _picked(role,"physics_material_override/friction",friction)
	if not is_equal_approx(body.physics_material_override.bounce, bounce):
		body.physics_material_override.bounce = bounce
	if not is_equal_approx(body.physics_material_override.friction, friction):
		body.physics_material_override.friction = friction

func set_panel_open(open: bool) -> void:
	panel.set_open(open)
	arena.launcher.cancel()
	if open:
		_take_pause()
	else:
		_release_pause()

func _take_pause() -> void:
	if pause_while_editing and not get_tree().paused and arena.director.state == arena.director.State.BATTLE:
		arena.director.set_paused(true)
		arena.menu.hide()
		_owns_pause = true

func _release_pause() -> void:
	if _owns_pause and arena.director.state == arena.director.State.PAUSED:
		arena.director.set_paused(false)
	_owns_pause = false

func relinquish_pause() -> void:
	# 玩家随后提出普通菜单暂停时，恢复权交回菜单，收起调参不能替它继续。
	_owns_pause = false

func set_pause_preference(enabled: bool) -> void:
	pause_while_editing = enabled
	if panel.is_open():
		if enabled:
			_take_pause()
		else:
			_release_pause()

func panel_rect() -> Rect2:
	return panel.panel_rect()

func restore_defaults() -> void:
	if full != null: full.reset_all()
	values = DEFAULTS.duplicate()
	_apply_values()
	panel.set_values(values)
	panel.set_status("已恢复全部物理基线；当前局与成长保留")

func remember_comparison() -> void:
	_comparison = values.duplicate()
	_full_comparison = full.record() if full != null else {}
	panel.set_status("已记住这组参数；改动后点“切换对照”比较")

func swap_comparison() -> void:
	var previous: Dictionary = values.duplicate()
	values = _comparison.duplicate()
	_comparison = previous
	if full != null:
		var previous_full: Dictionary = full.record()
		full.load_record(_full_comparison)
		_full_comparison = previous_full
	_apply_values()
	panel.set_values(values)
	panel.set_status("已切换对照参数；再点一次可切回来")

func _preset_path() -> String:
	# EXE旁便于策划回传；编辑器运行不向Godot安装目录写文件。
	return "user://handfeel_preset.json" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("handfeel_preset.json")

func preset_record() -> Dictionary:
	return {"schema_version": 2, "parameters": values.duplicate(), "full_parameters": full.record() if full != null else {}, "upgrades_at_save": arena.director.build.levels.duplicate(), "note": "快捷项为成长前基线，完整属性为明确覆盖；工程项按生效时机标识"}

func save_preset(path: String = "") -> bool:
	var target: String = _preset_path() if path.is_empty() else path
	var file: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		panel.set_status("保存失败：%s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(preset_record(), "\t"))
	file.close()
	if full != null and not OS.has_feature("editor"):
		var error: Error = full.engine.save_restart_settings(target.get_base_dir())
		if error != OK:
			panel.set_status("参数已存，但重启配置保存失败：%s" % error_string(error))
			return false
	panel.set_status("已保存：%s" % ProjectSettings.globalize_path(target))
	return true

func load_preset(path: String = "") -> bool:
	var target: String = _preset_path() if path.is_empty() else path
	if not FileAccess.file_exists(target):
		panel.set_status("还没有保存的handfeel_preset.json")
		return false
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(target))
	if not record is Dictionary or int(record.get("schema_version",0)) not in [1,2] or not record.get("parameters") is Dictionary:
		panel.set_status("加载失败：文件格式不正确；当前参数保留")
		return false
	var candidate: Dictionary = DEFAULTS.duplicate()
	for id: String in record.parameters:
		var value: Variant = record.parameters[id]
		if not DEFAULTS.has(id) or typeof(value) not in [TYPE_INT, TYPE_FLOAT] or is_nan(float(value)) or is_inf(float(value)):
			panel.set_status("加载失败：参数不在允许范围；当前参数保留")
			return false
		for spec: Dictionary in SPECS:
			if spec.id == id:
				candidate[id] = clampf(float(value), float(spec.min), float(spec.max))
	if full != null:
		var advanced: Variant = record.get("full_parameters",{})
		if not advanced is Dictionary or not full.load_record(advanced):
			panel.set_status("加载失败：完整属性不匹配；当前参数保留")
			return false
	values = candidate
	_apply_values()
	panel.set_values(values)
	panel.set_status("参数已加载；按各项标注生效，重启项需先保存再重启")
	return true

func _on_action(action: String) -> void:
	match action:
		"toggle": set_panel_open(not panel.is_open())
		"defaults": restore_defaults()
		"remember": remember_comparison()
		"compare": swap_comparison()
		"save": save_preset()
		"load": load_preset()
		"copy":
			DisplayServer.clipboard_set(JSON.stringify(preset_record(), "\t"))
			panel.set_status("参数已复制，可以直接粘贴给开发者")

func _exit_tree() -> void:
	if full != null: full.cleanup()
