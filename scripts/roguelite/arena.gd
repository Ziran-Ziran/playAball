extends Node2D
@onready var player: DemoPlayer = $PlayerBall
@onready var launcher: DemoLaunch = $LaunchController
@onready var combat: DemoCombat = $CollisionCombat
@onready var companions: DemoCompanions = $CompanionManager
@onready var status: Label = $HUD/Status
@onready var menu: PanelContainer = $HUD/Menu
@onready var feedback: Node2D = $ImpactFeedback
var aim_indicator: Node2D
var _aim_phase: float = 0.0
var _aim_recoil: float = 0.0
var _last_aim_drag: Vector2
var companion_count: int = 1
var paused: bool = false
var map_provider: Node
var _touch_index: int = -1
const PLATFORM_BACK: int = 1
const PLATFORM_SUSPEND: int = 2
var _platform_pause_intents: int = 0
var _platform_intent_context: int = -1
var _range_context_revision: int = 0

func _ready() -> void:
	launcher.player = player
	aim_indicator = Node2D.new()
	aim_indicator.name = "AimIndicator"
	aim_indicator.set_script(load("res://scripts/roguelite/presentation/aim_indicator.gd"))
	add_child(aim_indicator)
	launcher.aim_cancelled.connect(_clear_aim_feedback)
	launcher.aim_cancelled.connect(func(): _touch_index = -1)
	player.visual_event.connect(func(event: StringName, _payload: Dictionary):
		if event == &"reset":
			_clear_aim_feedback()
	)
	launcher.fired.connect(func(_chain: int):
		_last_aim_drag = launcher.last_fired_drag
		_aim_recoil = 0.22
	)
	# 回能只发布表现事件，不能复用撞击粒子或改变真实弹槽/冷却。
	launcher.recharged.connect(func(): player.visual_event.emit(&"charge_restored",{"charges":launcher.charges,"capacity":launcher.capacity}))
	companions.player = player
	companions.combat = combat
	companions.set_count(companion_count)
	player.contact_report.connect(combat.resolve)
	player.impacted.connect(feedback.play_contact)
	combat.hit.connect(feedback.play_impact)
	combat.relay.connect(feedback.play_relay)
	combat.explosion_triggered.connect(feedback.play_explosion)
	# 发射/回能不冒充实体碰撞；能量环与 HUD 表达可发射状态。
	$HUD/Controls/Count.item_selected.connect(change_count)
	$HUD/Controls/Momentum.toggled.connect(func(value: bool): player.cancel_opposing_momentum = 0.6 if value else 0.0)
	$HUD/Controls/Mute.toggled.connect(func(value: bool): feedback.sound_enabled = not value)
	$HUD/Controls/Shake.toggled.connect(func(value: bool): feedback.shake_enabled = not value)
	$HUD/Controls/Pause.pressed.connect(func(): set_paused(true))
	$HUD/Menu/Buttons/Resume.pressed.connect(func(): set_paused(false))
	$HUD/Menu/Buttons/Reset.pressed.connect(reset_range)

func _input(event: InputEvent) -> void:
	if _platform_pause_intents != 0:
		# 通知已到但尚未进入idle交易；旧手指释放/新按下都不能穿过这道屏障。
		get_viewport().set_input_as_handled()
		return
	# GUI仍使用系统触摸模拟鼠标；战场只认原生手指，防止同次手势双发。
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_cancel_at(event.position):
			cancel_pointer_gesture()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			if event.canceled or over_controls(event.position):
				cancel_pointer_gesture()
			else:
				launcher.release(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		if event.index == _touch_index:
			launcher.pointer = event.position
			get_viewport().set_input_as_handled()
		return
	# 右键也先于 GUI 取消，避免鼠标移到按钮后留下拉动状态。
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		launcher.cancel()
	if event is InputEventMouseMotion:
		launcher.pointer = event.position
	# 拖拽是屏幕上的手势，不能受镜头震动或主球移动影响。
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and launcher.input_held:
		if over_controls(event.position):
			launcher.cancel()
		else:
			launcher.release(event.position)
		get_viewport().set_input_as_handled()
	# Esc 先于 GUI 处理，按钮聚焦时仍能取消暂停。
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		set_paused(not paused)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _platform_pause_intents != 0:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0 and not launcher.blocked and not over_controls(event.position):
			_touch_index = event.index
			launcher.request_aim(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			launcher.cancel()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not over_controls(event.position):
				launcher.request_aim(event.position)

func over_controls(point: Vector2) -> bool:
	for control: Control in $HUD/Controls.get_children():
		if control.get_global_rect().has_point(point):
			return true
	return menu.visible and menu.get_global_rect().has_point(point)

func _process(_delta: float) -> void:
	_consume_platform_pause_intent()
	_aim_phase = fmod(_aim_phase + _delta * 1.8, 1.0)
	_aim_recoil = maxf(0.0, _aim_recoil - _delta)
	# 继承层只生成最终入口的一份文案；相同读数不反复触发布局。
	var next_status: String = battle_status_text()
	if status.text != next_status:
		status.text = next_status
	check_player_bounds()
	queue_redraw()

func battle_status_text() -> String:
	var destroyed: int = 0
	for target: DemoTarget in $Targets.get_children():
		if target.dead:
			destroyed += 1
	var availability: String = "就绪" if launcher.remaining == 0.0 else "冷却 %.1fs" % (ceilf(launcher.remaining * 10.0) / 10.0)
	if launcher.input_held and not launcher.aiming:
		availability += " · 按住等待"
	return "碰撞试验场 P0–P2   发射 %d   %s   击破 %d/3   接力 %d/3" % [launcher.shots, availability, destroyed, combat.longest_chain]

func check_player_bounds() -> void:
	var outside: bool = player.position.y > 820 or player.position.y < -100 or player.position.x < -100 or player.position.x > 1380
	if is_instance_valid(map_provider):
		outside = not map_provider.definition.bounds.grow(100.0).has_point(player.position)
	if outside:
		launcher.cancel()
		var reset_point: Vector2 = Vector2(640, 540)
		if is_instance_valid(map_provider):
			var exclusions: Array[RID] = [player.get_rid()]
			reset_point = map_provider.find_safe_point(map_provider.definition.player_spawn, 23.0, exclusions)
		if reset_point.is_finite():
			if is_instance_valid(map_provider):
				map_provider.recovery_requested.emit(player, player.position, reset_point)
			player.reset_body(reset_point)

func set_paused(value: bool) -> void:
	paused = value
	launcher.set_blocked(value)
	get_tree().paused = value
	menu.visible = value

func reset_range() -> void:
	_range_context_revision += 1
	_platform_pause_intents = 0
	set_paused(false)
	feedback.reset_feedback()
	launcher.reset_launch()
	player.reset_body(Vector2(640, 540))
	combat.reset_combat()
	companions.set_follow_enabled(false)
	companions.set_count(companion_count)
	for target: DemoTarget in $Targets.get_children():
		target.reset_target()

func change_count(index: int) -> void:
	launcher.cancel()
	companion_count = [1, 2, 4][index]
	companions.set_count(companion_count)

func _draw() -> void:
	# 物理边界位于四边，轮廓让俯视围场可读；角部三角与碰撞形状一致。
	draw_rect(Rect2(40, 125, 1200, 553), Color("37616c"), false, 4)
	for corner: CollisionPolygon2D in $Corners.get_children():
		draw_colored_polygon(corner.polygon, Color("37616c"))
	for x in range(40, 1241, 40):
		draw_line(Vector2(x, 125), Vector2(x, 680), Color(0.12, 0.24, 0.30, 0.35))
	for y in range(160, 681, 40):
		draw_line(Vector2(40, y), Vector2(1240, y), Color(0.12, 0.24, 0.30, 0.35))
	_draw_aim_feedback()

func _clear_aim_feedback() -> void:
	_aim_recoil = 0.0
	_last_aim_drag = Vector2.ZERO
	if is_instance_valid(aim_indicator):
		aim_indicator.hide()

func _draw_aim_feedback() -> void:
	if is_instance_valid(launcher) and launcher.aiming:
		_last_aim_drag = (launcher.anchor - launcher.pointer).limit_length(player.max_drag)
	if is_instance_valid(aim_indicator):
		aim_indicator.update_indicator()

func _notification(what: int) -> void:
	if not is_instance_valid(launcher):
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_queue_platform_pause_intent(PLATFORM_BACK)
	elif what == NOTIFICATION_APPLICATION_PAUSED or (OS.has_feature("android") and what == NOTIFICATION_APPLICATION_FOCUS_OUT):
		_queue_platform_pause_intent(PLATFORM_SUSPEND)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if OS.has_feature("android"):
			_queue_platform_pause_intent(PLATFORM_SUSPEND)
		else:
			cancel_pointer_gesture()

func cancel_pointer_gesture(release_owned_pause: bool = true) -> void:
	_touch_index = -1
	launcher.cancel(release_owned_pause)

func _platform_context_revision() -> int:
	return _range_context_revision

func _queue_platform_pause_intent(intent: int) -> void:
	var context: int = _platform_context_revision()
	if _platform_intent_context != context:
		_platform_pause_intents = 0
	_platform_intent_context = context
	_platform_pause_intents |= intent
	# 只取消输入资格，不在通知栈释放aim暂停；整笔所有权切换由正常_process消费。
	cancel_pointer_gesture(false)

func _consume_platform_pause_intent() -> void:
	if _platform_pause_intents == 0:
		return
	var intents: int = _platform_pause_intents
	var context: int = _platform_intent_context
	_platform_pause_intents = 0
	if not is_inside_tree() or is_queued_for_deletion() or context != _platform_context_revision():
		return
	# 挂起优先，Back+Home同批不先恢复一次；重复Back通知合并为一次意图。
	if intents & PLATFORM_SUSPEND:
		handle_application_suspended()
	elif intents & PLATFORM_BACK:
		handle_back_request()

func handle_back_request() -> void:
	cancel_pointer_gesture(false)
	# Director会拒绝在成长/商店/结算中转移暂停所有权。
	set_paused(not paused)

func handle_application_suspended() -> void:
	cancel_pointer_gesture(false)
	set_paused(true)

func touch_cancel_at(_point: Vector2) -> bool:
	return false

func _exit_tree() -> void:
	_platform_pause_intents = 0
	get_tree().paused = false
	Engine.time_scale = 1.0


