extends "res://scripts/roguelite/arena.gd"
## 独立开发夹具：不替换正式 run 入口，也不向正式运行注册快捷键。
enum Fixture { SINGLE, CROWD, CORNER, COMPANIONS, RANGE, TURRET, SPLIT, BOSS }
const FIXTURE_NAMES: Array[String] = ["1 单敌", "2 怪群", "3 墙角", "4 伙伴", "5 攻击范围", "6 炮台", "7 分裂", "8 首领"]
const BASELINE_SHA: String = "935b9b87abf39f719172b3e618ea3ecf672d9fc9"
const PRESET_PATH: String = "res://.local/gameplay_lab_preset.json"
const REPORT_PATH: String = "res://.local/gameplay_lab_report.txt"
const PLAYER_START: Vector2 = Vector2(420, 450)
const DEFAULTS: Dictionary = {
	"fixture": 0,
	"enemy_kind": 0,
	"build_preset": 0,
	"override_build_parameters": false,
	"enemy_count": 3,
	"enemy_hp": 0,
	"distance": 390,
	"angle_deg": 0,
	"power_pct": 100,
	"minimum_speed": 180,
	"pair_cooldown": 0.18,
	"cooldown_seconds": 2.2,
	"companion_count": 1,
	"follow_enabled": false,
	"split_enabled": false,
	"range_radius": 180,
	"ai_enabled": false,
	"seed": 31030,
	"impact_retention_pct": 65,
}
const PARAMETER_SPECS: Array = [
	{"id": "enemy_kind", "label": "敌人类型", "type": "option", "options": ["脆皮方块", "重型圆罐", "三角炮台"], "default": 0},
	{"id": "build_preset", "label": "初始构筑", "type": "option", "options": ["基础", "机动", "火力", "伙伴", "生存", "节奏"], "default": 0},
	{"id": "override_build_parameters", "label": "覆盖构筑冷却/伙伴", "type": "bool", "default": false},
	{"id": "enemy_count", "label": "敌数（怪群/范围/炮台/伙伴）", "type": "int", "min": 1, "max": 8, "step": 1, "default": 3},
	{"id": "enemy_hp", "label": "覆盖生命（0=默认）", "type": "int", "min": 0, "max": 30, "step": 1, "default": 0},
	{"id": "distance", "label": "目标距离（px）", "type": "int", "min": 80, "max": 700, "step": 10, "default": 390},
	{"id": "angle_deg", "label": "固定方向（度）", "type": "float", "min": -180, "max": 180, "step": 1, "default": 0},
	{"id": "power_pct", "label": "固定力度（%）", "type": "int", "min": 1, "max": 100, "step": 1, "default": 100},
	{"id": "minimum_speed", "label": "伤害速度门槛（px/s）", "type": "float", "min": 0, "max": 1200, "step": 10, "default": 180},
	{"id": "pair_cooldown", "label": "配对冷却（秒）", "type": "float", "min": 0, "max": 2, "step": 0.01, "default": 0.18},
	{"id": "cooldown_seconds", "label": "覆盖冷却（秒）", "type": "float", "min": 0.2, "max": 5, "step": 0.1, "default": 2.2},
	{"id": "companion_count", "label": "覆盖伙伴数（个）", "type": "int", "min": 1, "max": 4, "step": 1, "default": 1},
	{"id": "impact_retention_pct", "label": "撞击续力保留（%）", "type": "int", "min": 0, "max": 100, "step": 1, "default": 65},
	{"id": "range_radius", "label": "攻击/索敌范围（px）", "type": "float", "min": 30, "max": 700, "step": 10, "default": 180},
	{"id": "seed", "label": "固定种子", "type": "int", "min": 1, "max": 2147483647, "step": 1, "default": 31030},
	{"id": "follow_enabled", "label": "覆盖伙伴跟随", "type": "bool", "default": false},
	{"id": "split_enabled", "label": "击破分裂（仅夹具7）", "type": "bool", "default": false},
	{"id": "ai_enabled", "label": "敌人 AI", "type": "bool", "default": false},
]
const BUILD_PRESETS: Array = [
	[],
	["launch_power", "launch_power", "glide"],
	["heavy", "heavy", "echo", "bowling"],
	["companion", "follow", "relay"],
	["pulse", "shrink", "vigor"],
	["cooldown", "double_launch", "choices"],
]
const REASON_TEXT: Dictionary = {
	"invalid_actor": "来源无效",
	"invalid_target": "目标无效",
	"resetting": "正在复位或旧局事件",
	"no_attack_qualification": "没有攻击资格",
	"target_not_damageable": "目标不可受伤或已死亡",
	"speed_below_minimum": "接触速度不足",
	"pair_cooldown": "同一配对仍在冷却",
	"projectile_target_repeat": "投射物已命中该目标",
	"projectile_hit_budget_exhausted": "投射物命中资格耗尽",
	"already_dead": "玩家已倒下",
	"invalid_damage": "非法伤害值",
	"invulnerable": "玩家处于无敌",
	"out_of_range": "敌人离开实际攻击范围",
	"out_of_range_release": "过期攻击在范围外释放",
}

@onready var enemies: Node2D = $Enemies
@onready var hazards: Node2D = $Hazards
@onready var lab_walls: Node2D = $LabWalls
@onready var player_health: DemoHealth = $PlayerHealth
@onready var health_panel: DemoHealthView = $HealthView
@onready var lab_panel: DemoLabPanel = $LabPanel
@onready var split_director = $SplitDirector
var _applied: Dictionary = DEFAULTS.duplicate(true)
var _fixture_revision: int = 0
var _fixture_started_msec: int = 0
var _fixture_elapsed: float = 0.0
var _reset_ready: bool = false
var _last_contact_speed: float = 0.0
var _last_contact_attacking: bool = false
var _last_source_id: int = 0
var _last_target_id: int = 0
var _valid_hits: int = 0
var _rejected_hits: int = 0
var _total_damage: int = 0
var _reason_counts: Dictionary = {}
var _log_entries: Array[String] = []
var _report_lines: Array[String] = []
var _boss: DemoBoss
var _visuals_visible: bool = true
var _lab_build: DemoBuild
var _assists: DemoAssistEffects
var _ever_spawned: bool = false
var _clear_time: float = -1.0

func _ready() -> void:
	super._ready()
	for target in $Targets.get_children():
		$Targets.remove_child(target)
		target.queue_free()
	status.hide()
	$HUD/Hint.hide()
	$HUD/Controls.hide()
	$HUD/Menu.hide()
	if DisplayServer.get_name() != "headless":
		get_window().title = "玩个球 · 玩法实验室"
	_lab_build = load("res://scripts/roguelite/run_build.gd").new()
	_assists = DemoAssistEffects.new()
	_assists.player = player
	_assists.enemies = enemies
	_assists.build = _lab_build
	add_child(_assists)
	player_health.max_hp = 5
	player_health.reset_health()
	health_panel.bind_source(player_health)
	player.contact_sampled.connect(_on_contact_sampled)
	player.contact_diagnostics_enabled = true
	combat.contact_outcome.connect(_on_contact_outcome)
	player_health.damage_rejected.connect(_on_player_damage_rejected)
	enemies.child_entered_tree.connect(_on_enemy_entered)
	companions.child_entered_tree.connect(_on_companion_entered)
	for member in companions.members:
		_on_companion_entered(member)
	lab_panel.configure(PARAMETER_SPECS, FIXTURE_NAMES)
	lab_panel.set_values(_applied)
	lab_panel.action_requested.connect(_on_lab_action)
	_configure_split_director()
	_request_reset(_applied)

func _process(delta: float) -> void:
	super._process(delta)
	if not get_tree().paused and _reset_ready:
		_fixture_elapsed += delta
		_advance_split_warnings(delta)
		if _ever_spawned and _clear_time < 0.0 and enemies.get_child_count() == 0 and split_director.pending.is_empty():
			_clear_time = _fixture_elapsed
	_update_readout()

func over_controls(point: Vector2) -> bool:
	if super.over_controls(point):
		return true
	for path: String in ["Control/ParameterPanel", "Control/ReadoutPanel", "Control/LogPanel"]:
		var panel: Control = lab_panel.get_node_or_null(path)
		if panel != null and panel.visible and panel.get_global_rect().has_point(point):
			return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not _editing_text():
		var handled: bool = true
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				_switch_fixture(int(event.keycode - KEY_1))
			KEY_R:
				_request_reset(lab_panel.values())
			KEY_T:
				_fixed_launch()
			KEY_L:
				_toggle_visuals()
			KEY_S:
				if event.ctrl_pressed:
					_save_preset()
				else:
					handled = false
			KEY_O:
				if event.ctrl_pressed:
					_load_preset()
				else:
					handled = false
			_:
				handled = false
		if handled:
			get_viewport().set_input_as_handled()
			return
	super._input(event)

func _editing_text() -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit

func _on_lab_action(action: String, payload: Dictionary, quote_revision: int) -> void:
	if quote_revision != lab_panel.revision:
		_append_log("旧面板请求已拒绝：revision %d != %d" % [quote_revision, lab_panel.revision])
		return
	match action:
		"apply":
			_request_reset(payload)
		"launch":
			_fixed_launch()
		"save":
			_save_preset()
		"load":
			_load_preset()
		"defaults":
			_restore_defaults()
		"record":
			_save_report()

func _switch_fixture(index: int) -> void:
	var values: Dictionary = lab_panel.values()
	values.fixture = clampi(index, 0, Fixture.size() - 1)
	lab_panel.set_values(values)
	_request_reset(values)

func _request_reset(requested: Dictionary) -> bool:
	var config: Dictionary = _sanitize_config(requested)
	var layout_error: String = _validate_layout(config)
	if not layout_error.is_empty():
		lab_panel.set_status("未应用：%s；请减小距离/数量，原实验保留" % layout_error, false)
		_append_log("RESET rejected: %s" % layout_error)
		return false
	_applied = config
	lab_panel.set_values(config)
	_fixture_revision += 1
	lab_panel.set_revision(_fixture_revision)
	_reset_ready = false
	_clear_fixture()
	_assists.reset_effects()
	_stat_reset()
	player.reset_body(PLAYER_START)
	_apply_build_preset(int(config.build_preset))
	player_health.max_hp = _lab_build.max_health()
	player_health.reset_health()
	launcher.reset_launch()
	launcher.set_capacity(_lab_build.launch_capacity())
	launcher.cooldown = float(config.cooldown_seconds) if config.override_build_parameters else _lab_build.launch_cooldown()
	player.apply_launch_stats(_lab_build.launch_multiplier(), _lab_build.damping_multiplier(), _lab_build.friction_multiplier())
	player.impact_drive_retention = clampf(float(config.impact_retention_pct) / 100.0, 0.0, 1.0)
	combat.minimum_speed = float(config.minimum_speed)
	combat.pair_cooldown = float(config.pair_cooldown)
	combat.reset_combat()
	companions.set_follow_enabled(bool(config.follow_enabled) if config.override_build_parameters else _lab_build.has_upgrade("follow"))
	companions.set_count(int(config.companion_count) if config.override_build_parameters else _lab_build.companion_count())
	split_director.split_enabled = bool(config.split_enabled)
	split_director.rng.seed = int(config.seed)
	split_director.pending.clear()
	split_director._run_revision += 1
	split_director.kills = 0
	split_director.rewards.reset_progress()
	split_director.wallet.reset_wallet()
	# 复位等物理状态接口真正落地后，才允许固定发射。
	_after_reset.call_deferred(_fixture_revision, config)
	return true

func _after_reset(revision: int, config: Dictionary) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if revision != _fixture_revision:
		return
	_build_fixture(config)
	_ever_spawned = enemies.get_child_count() > 0
	_reset_ready = true
	_fixture_started_msec = Time.get_ticks_msec()
	lab_panel.set_status("%s 已重建 · 参数已应用" % FIXTURE_NAMES[int(config.fixture)], true)
	_append_log("RESET fixture=%s seed=%d baseline=%s" % [FIXTURE_NAMES[int(config.fixture)], int(config.seed), BASELINE_SHA.left(8)])

func _clear_fixture() -> void:
	_boss = null
	for container: Node in [enemies, hazards, lab_walls]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	split_director.pending.clear()
	player.cancel_opposing_momentum = 0.0
	player.chain_id = 0
	player.generation = 0

func _build_fixture(config: Dictionary) -> void:
	var fixture: int = int(config.fixture)
	var kind: int = int(config.enemy_kind)
	var hp: int = int(config.enemy_hp)
	var distance: float = float(config.distance)
	match fixture:
		Fixture.SINGLE:
			_spawn_enemy(kind, PLAYER_START + Vector2(distance, 0), hp, bool(config.ai_enabled))
		Fixture.CROWD:
			for index in int(config.enemy_count):
				_spawn_enemy(kind, PLAYER_START + Vector2(distance + index * 62.0, (index % 2) * 44.0 - 22.0), hp, bool(config.ai_enabled))
		Fixture.CORNER:
			_add_wall(Vector2(880, 390), Vector2(24, 220), 0.0)
			_add_wall(Vector2(790, 500), Vector2(210, 24), 0.0)
			_spawn_enemy(kind, PLAYER_START + Vector2(distance, 0), hp, bool(config.ai_enabled), float(config.range_radius))
		Fixture.COMPANIONS:
			for index in int(config.enemy_count):
				_spawn_enemy(kind, PLAYER_START + Vector2(distance + index * 64.0, (index % 2) * 40.0), hp, bool(config.ai_enabled))
		Fixture.RANGE:
			var range_count: int = int(config.enemy_count)
			for index in range_count:
				_spawn_enemy(kind, PLAYER_START + _equidistant_offset(distance, range_count, index), hp, bool(config.ai_enabled), float(config.range_radius))
		Fixture.TURRET:
			var turret_count: int = int(config.enemy_count)
			for index in turret_count:
				_spawn_enemy(DemoEnemy.Kind.TURRET, PLAYER_START + _equidistant_offset(distance, turret_count, index), hp, bool(config.ai_enabled), float(config.range_radius))
		Fixture.SPLIT:
			var root_hp: int = hp if hp >= 4 else 4
			split_director.split_enabled = bool(config.split_enabled)
			split_director.spawn_enemy(DemoEnemy.Kind.HEAVY, PLAYER_START + Vector2(distance, 0), root_hp, true, 0, false)
			if enemies.get_child_count() > 0:
				var root_actor: DemoEnemy = enemies.get_child(enemies.get_child_count() - 1)
				root_actor.set_physics_process(bool(config.ai_enabled))
		Fixture.BOSS:
			_boss = load("res://scenes/roguelite/boss.tscn").instantiate()
			_boss.player = player
			_boss.health = player_health
			_boss.position = PLAYER_START + Vector2(maxf(320.0, distance), 0)
			enemies.add_child(_boss)
			_boss.contact_report.connect(combat.resolve)
			_boss.contact_diagnostics_enabled = true
			_boss.apply_attack_scale(_lab_build.attack_radius_scale())
			_boss.set_physics_process(bool(config.ai_enabled))

func _spawn_enemy(kind: int, point: Vector2, hp_override: int, ai_enabled: bool, range_override: float = 0.0) -> DemoEnemy:
	var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	enemy.kind = kind
	enemy.hit_points_override = hp_override
	enemy.player = player
	enemy.health = player_health
	enemy.hazards = hazards
	enemy.position = point
	if range_override > 0.0:
		match kind:
			DemoEnemy.Kind.FRAGILE:
				enemy.pulse_radius = range_override
			DemoEnemy.Kind.HEAVY:
				enemy.charge_range = range_override
			DemoEnemy.Kind.TURRET:
				enemy.attack_range = range_override
	enemies.add_child(enemy)
	enemy.contact_report.connect(combat.resolve)
	if not ai_enabled:
		enemy.approach_force = 0.0
		enemy.set_physics_process(false)
	return enemy

func _equidistant_offset(distance: float, count: int, index: int) -> Vector2:
	# 多目标夹具保持同一中心距，避免纵向排布把边缘目标意外推出攻击半径。
	if count <= 1:
		return Vector2(distance, 0.0)
	var half_span: float = minf(195.0, distance * 0.55)
	var y: float = lerpf(-half_span, half_span, float(index) / float(count - 1))
	var x: float = sqrt(maxf(0.0, distance * distance - y * y))
	return Vector2(x, y)

func _connect_enemy_diagnostics(enemy: DemoEnemy) -> void:
	if enemy.has_meta("lab_diagnostics"):
		return
	enemy.set_meta("lab_diagnostics", true)
	enemy.contact_diagnostics_enabled = true
	enemy.contact_sampled.connect(_on_contact_sampled)
	enemy.presentation_event.connect(_on_enemy_presentation_event)
	enemy.died.connect(func(defeated: DemoEnemy):
		_append_log("DIE id=%d kind=%d" % [defeated.get_instance_id(), int(defeated.kind)])
	)

func _on_enemy_entered(node: Node) -> void:
	if node is DemoEnemy:
		_connect_enemy_diagnostics(node)
		# 所有代数都经过此入口；ready后应用，避免被actor初始化覆盖。
		if node.is_node_ready():
			_apply_enemy_policy(node)
		else:
			node.ready.connect(_apply_enemy_policy.bind(node), CONNECT_ONE_SHOT)

func _apply_enemy_policy(enemy: DemoEnemy) -> void:
	enemy.apply_attack_scale(_lab_build.attack_radius_scale())
	if int(_applied.fixture) in [Fixture.CORNER, Fixture.RANGE, Fixture.TURRET]:
		match enemy.kind:
			DemoEnemy.Kind.FRAGILE:
				enemy.pulse_radius = float(_applied.range_radius) * _lab_build.attack_radius_scale()
			DemoEnemy.Kind.HEAVY:
				enemy.charge_range = float(_applied.range_radius)
			DemoEnemy.Kind.TURRET:
				enemy.attack_range = float(_applied.range_radius)
	enemy.set_physics_process(bool(_applied.ai_enabled))

func _validate_layout(config: Dictionary) -> String:
	var points: Array[Vector2] = []
	var distance: float = float(config.distance)
	var fixture: int = int(config.fixture)
	var radius: float = 30.0 if int(config.enemy_kind) == DemoEnemy.Kind.HEAVY or fixture == Fixture.SPLIT else 22.0
	match fixture:
		Fixture.CROWD, Fixture.COMPANIONS:
			for index in int(config.enemy_count):
				var spacing: float = 62.0 if fixture == Fixture.CROWD else 64.0
				var y: float = (index % 2) * 44.0 - 22.0 if fixture == Fixture.CROWD else (index % 2) * 40.0
				points.append(PLAYER_START + Vector2(distance + index * spacing, y))
		Fixture.RANGE, Fixture.TURRET:
			for index in int(config.enemy_count):
				points.append(PLAYER_START + _equidistant_offset(distance, int(config.enemy_count), index))
		Fixture.BOSS:
			radius = 96.0
			points.append(PLAYER_START + Vector2(maxf(320.0, distance), 0))
		_:
			points.append(PLAYER_START + Vector2(distance, 0))
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 17
	for index in points.size():
		var point: Vector2 = points[index]
		if point.x - radius < 40.0 or point.x + radius > 1240.0 or point.y - radius < 125.0 or point.y + radius > 678.0:
			return "目标%d超出围场边界" % (index + 1)
		for previous in index:
			if point.distance_to(points[previous]) < radius * 2.0:
				return "目标%d与目标%d初始重叠" % [previous + 1, index + 1]
		query.transform = Transform2D(0.0, point)
		for hit in get_world_2d().direct_space_state.intersect_shape(query):
			if not lab_walls.is_ancestor_of(hit.collider):
				return "目标%d与固定墙/挡板重叠" % (index + 1)
		if fixture == Fixture.CORNER and (Rect2(868, 280, 24, 220).grow(radius).has_point(point) or Rect2(685, 488, 210, 24).grow(radius).has_point(point)):
			return "目标与墙角夹具重叠"
	return ""

func _on_companion_entered(node: Node) -> void:
	if not node is DemoCompanion or node.has_meta("lab_diagnostics"):
		return
	node.set_meta("lab_diagnostics", true)
	node.contact_diagnostics_enabled = true
	node.contact_sampled.connect(_on_contact_sampled)

func _add_wall(point: Vector2, size: Vector2, rotation_radians: float) -> void:
	var wall := StaticBody2D.new()
	wall.position = point
	wall.rotation = rotation_radians
	wall.collision_layer = 16
	wall.collision_mask = 6
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	wall.add_child(shape)
	lab_walls.add_child(wall)

func _configure_split_director() -> void:
	split_director.player = player
	split_director.enemies = enemies
	split_director.hazards = hazards
	split_director.health = player_health
	split_director.combat = combat
	split_director.build = _lab_build
	split_director.combat.build = split_director.build
	split_director.wave = 1
	split_director.wave_enemy_limits = PackedInt32Array([32, 32, 32, 32, 32])
	split_director.set_process(false)
	split_director.set_physics_process(false)

func _apply_build_preset(index: int) -> void:
	_lab_build.reset_build()
	var ids: Array = BUILD_PRESETS[clampi(index, 0, BUILD_PRESETS.size() - 1)]
	for id: String in ids:
		_lab_build.choose(id)
	combat.build = _lab_build
	if is_instance_valid(split_director):
		split_director.build = _lab_build
		split_director.combat.build = _lab_build

func _advance_split_warnings(delta: float) -> void:
	if not is_instance_valid(split_director):
		return
	for warning: Dictionary in split_director.pending:
		warning.left -= delta
	for index in range(split_director.pending.size() - 1, -1, -1):
		if float(split_director.pending[index].left) > 0.0:
			continue
		var warning: Dictionary = split_director.pending[index]
		split_director.pending.remove_at(index)
		split_director.materialize_warning(warning)

func _fixed_launch() -> bool:
	if not _reset_ready:
		_append_log("LAUNCH rejected: fixture not reset")
		return false
	var direction: Vector2 = Vector2.from_angle(deg_to_rad(float(_applied.angle_deg)))
	var power_ratio: float = clampf(float(_applied.power_pct) / 100.0, 0.0, 1.0)
	var drag_length: float = 8.0 + (player.max_drag - 8.0) * power_ratio
	var drag: Vector2 = direction * drag_length
	var available_before: bool = launcher.available()
	var success: bool = launcher.launch_with_drag(drag)
	var reason: String = "formal_launch" if success else ("cooldown_or_blocked" if not available_before or launcher.blocked else "launch_rule_rejected")
	_append_log("LAUNCH result=%s reason=%s chain=%d angle=%.0f power=%.0f%%" % [str(success), reason, player.chain_id, float(_applied.angle_deg), float(_applied.power_pct)])
	return success

func _on_contact_sampled(actor: DemoBody, other: Node, speed: float, _point: Vector2, attacking: bool) -> void:
	_last_contact_speed = speed
	_last_contact_attacking = attacking
	_last_source_id = actor.get_instance_id()
	_last_target_id = other.get_instance_id() if is_instance_valid(other) else 0
	if actor == player or (actor is DemoCompanion and actor.mode == DemoCompanion.Mode.ACTIVE):
		_append_log("CONTACT src=%d dst=%d speed=%.1f attacking=%s" % [_last_source_id, _last_target_id, speed, str(attacking)])

func _on_contact_outcome(event: Dictionary) -> void:
	var result: String = String(event.result)
	if result == "accepted":
		_valid_hits += 1
		_total_damage += int(event.damage)
	else:
		_rejected_hits += 1
		var reason: String = String(event.reason)
		_reason_counts[reason] = int(_reason_counts.get(reason, 0)) + 1
	_append_log("COMBAT %s reason=%s src=%d dst=%d speed=%.1f damage=%d" % [result, String(event.reason), int(event.source), int(event.target), float(event.speed), int(event.damage)])

func _on_player_damage_rejected(reason: StringName, amount: int) -> void:
	var key: String = String(reason)
	_reason_counts[key] = int(_reason_counts.get(key, 0)) + 1
	_append_log("PLAYER_HURT rejected reason=%s amount=%d" % [key, amount])

func _on_enemy_presentation_event(event: StringName, payload: Dictionary) -> void:
	if event in [&"attack_cancelled", &"attack_released", &"warning_started"]:
		_append_log("ENEMY_EVENT event=%s reason=%s" % [String(event), String(payload.get("reason", ""))])

func _update_readout() -> void:
	if not is_instance_valid(lab_panel):
		return
	var hp_texts: Array[String] = []
	var warnings_pending: int = split_director.pending.size() if is_instance_valid(split_director) else 0
	for child in enemies.get_children():
		if child is DemoEnemy and not child.dead:
			hp_texts.append("%d/%d" % [child.hp, child.max_hp])
		elif child is DemoBoss and not child.dead:
			hp_texts.append("B%d" % child.hp)
		if hp_texts.size() >= 5:
			break
	var reasons: Array[String] = []
	for key: String in _reason_counts:
		reasons.append("%s:%d" % [REASON_TEXT.get(key, key), int(_reason_counts[key])])
	var launch_state: String = "就绪" if launcher.available() else "冷却 %.2fs" % launcher.remaining
	var clear_text: String = "-" if _clear_time < 0.0 else "%.2fs" % _clear_time
	lab_panel.set_readout(
		"时间 %.2fs · 清场 %s · 构筑 %s · 发射链 %d/%d · %s · 续力保留 %.0f%%\n"
		% [_fixture_elapsed, clear_text, PARAMETER_SPECS[1].options[int(_applied.build_preset)], player.chain_id, player.generation, launch_state, player.impact_drive_retention * 100.0]
		+ "玩家速度 %.1f px/s · 最近接触 %.1f px/s（%s）· 续力剩余 %.1f / %.2fs\n"
		% [player.linear_velocity.length(), _last_contact_speed, "有资格" if _last_contact_attacking else "无资格", player.impact_drive_remaining(), player.impact_drive_time_remaining()]
		+ "有效 %d · 拒伤 %d · 伤害 %d · 危险弹 %d · 分裂预警 %d\n" % [_valid_hits, _rejected_hits, _total_damage, hazards.get_child_count(), warnings_pending]
		+ "目标生命：%s · 实际冷却 %.2fs · 伙伴 %d/跟随%s\n" % [", ".join(hp_texts) if not hp_texts.is_empty() else "无", launcher.cooldown, companions.members.size(), str(companions.follow_enabled)]
		+ "拒伤原因：%s" % ("；".join(reasons) if not reasons.is_empty() else "尚无")
	)

func _append_log(text: String) -> void:
	var line: String = "[%7.2fs] %s" % [_fixture_elapsed, text]
	_log_entries.append(line)
	_report_lines.append(line)
	while _log_entries.size() > 160:
		_log_entries.pop_front()
	while _report_lines.size() > 320:
		_report_lines.pop_front()
	if is_instance_valid(lab_panel):
		lab_panel.set_log("\n".join(_log_entries.slice(maxi(0, _log_entries.size() - 40))))

func _stat_reset() -> void:
	_fixture_elapsed = 0.0
	_last_contact_speed = 0.0
	_last_contact_attacking = false
	_last_source_id = 0
	_last_target_id = 0
	_valid_hits = 0
	_rejected_hits = 0
	_total_damage = 0
	_reason_counts.clear()
	_log_entries.clear()
	_report_lines.clear()
	_ever_spawned = false
	_clear_time = -1.0

func _sanitize_config(source: Dictionary) -> Dictionary:
	var output: Dictionary = DEFAULTS.duplicate(true)
	for spec in PARAMETER_SPECS + [{"id": "fixture", "type": "int", "min": 0, "max": Fixture.size() - 1, "step": 1, "default": 0}]:
		var id: String = String(spec.id)
		if not source.has(id):
			continue
		match String(spec.type):
			"bool":
				output[id] = bool(source[id])
			"option":
				output[id] = clampi(int(source[id]), 0, spec.options.size() - 1)
			"int":
				output[id] = clampi(int(source[id]), int(spec.min), int(spec.max))
			"float":
				output[id] = clampf(float(source[id]), float(spec.min), float(spec.max))
	return output

func _save_preset() -> bool:
	var directory: String = ProjectSettings.globalize_path("res://.local")
	DirAccess.make_dir_recursive_absolute(directory)
	var record: Dictionary = {
		"schema_version": 2,
		"baseline_sha": BASELINE_SHA,
		"fixture": String(FIXTURE_NAMES[int(_applied.fixture)]),
		"parameters": lab_panel.values(),
		"applied": _applied,
		"fixed_launch": {
			"angle_deg": _applied.angle_deg,
			"power_pct": _applied.power_pct,
			"uses_formal_launch_contract": true,
		},
	}
	var file: FileAccess = FileAccess.open(PRESET_PATH, FileAccess.WRITE)
	if file == null:
		_append_log("PRESET save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(record, "\t"))
	_append_log("PRESET saved: %s" % PRESET_PATH)
	return true

func _load_preset() -> bool:
	if not FileAccess.file_exists(PRESET_PATH):
		_append_log("PRESET load failed: file not found")
		return false
	var file: FileAccess = FileAccess.open(PRESET_PATH, FileAccess.READ)
	if file == null:
		_append_log("PRESET load failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) not in [1, 2]:
		_append_log("PRESET load rejected: schema mismatch")
		return false
	if String(parsed.get("baseline_sha", "")) != BASELINE_SHA:
		_append_log("PRESET baseline differs: %s" % String(parsed.get("baseline_sha", "")))
	if not parsed.get("parameters", {}) is Dictionary:
		_append_log("PRESET load rejected: parameters must be an object")
		return false
	var values: Dictionary = parsed.get("parameters", {})
	if int(parsed.schema_version) == 1:
		# 旧预设的旋钮始终覆盖构筑；迁移时保留其明确记录的物理条件。
		values.override_build_parameters = true
	if not _request_reset(values):
		return false
	_append_log("PRESET loaded: %s" % PRESET_PATH)
	return true

func _restore_defaults() -> void:
	_request_reset(DEFAULTS)
	_append_log("PRESET defaults restored")

func _toggle_visuals() -> void:
	_visuals_visible = not _visuals_visible
	lab_panel.set_visuals_visible(_visuals_visible)

func _save_report() -> bool:
	var directory: String = ProjectSettings.globalize_path("res://.local")
	DirAccess.make_dir_recursive_absolute(directory)
	var header: String = "\n".join([
		"# playAball gameplay lab report",
		"baseline: %s" % BASELINE_SHA,
		"godot: %s" % String(Engine.get_version_info().string),
		"platform: %s / %s" % [OS.get_name(), DisplayServer.get_name()],
		"fixture: %s" % FIXTURE_NAMES[int(_applied.fixture)],
		"parameters: %s" % JSON.stringify(_applied),
		"expected: fixed launch uses formal launch, then physics contact and gameplay damage validation.",
		"actual_summary: valid=%d rejected=%d damage=%d elapsed=%.2f" % [_valid_hits, _rejected_hits, _total_damage, _fixture_elapsed],
		"steps: 1) apply/reset 2) wait for RESET status 3) press T 4) inspect readout/log",
		"",
		"## log",
	])
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_append_log("REPORT save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(header + "\n" + "\n".join(_report_lines))
	_append_log("REPORT saved: %s" % REPORT_PATH)
	return true
