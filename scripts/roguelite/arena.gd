extends Node2D
@onready var player: DemoPlayer = $PlayerBall
@onready var launcher: DemoLaunch = $LaunchController
@onready var combat: DemoCombat = $CollisionCombat
@onready var companions: DemoCompanions = $CompanionManager
@onready var status: Label = $HUD/Status
@onready var menu: PanelContainer = $HUD/Menu
@onready var feedback: Node2D = $ImpactFeedback
var companion_count: int = 1
var paused: bool = false
var map_provider: Node

func _ready() -> void:
	launcher.player = player
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
	var destroyed: int = 0
	for target: DemoTarget in $Targets.get_children():
		if target.dead:
			destroyed += 1
	var availability: String = "就绪" if launcher.remaining == 0.0 else "冷却 %.1fs" % (ceilf(launcher.remaining * 10.0) / 10.0)
	if launcher.input_held and not launcher.aiming:
		availability += " · 按住等待"
	status.text = "碰撞试验场 P0–P2   发射 %d   %s   击破 %d/3   接力 %d/3" % [launcher.shots, availability, destroyed, combat.longest_chain]
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
	queue_redraw()

func set_paused(value: bool) -> void:
	paused = value
	launcher.set_blocked(value)
	get_tree().paused = value
	menu.visible = value

func reset_range() -> void:
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
	if is_instance_valid(launcher) and launcher.aiming:
		var drag: Vector2 = (launcher.anchor - launcher.pointer).limit_length(player.max_drag)
		# 屏幕手势方向映射到世界，仅用于画箭头，物理仍在松手时注入冲量。
		var world_drag: Vector2 = get_global_transform_with_canvas().affine_inverse().basis_xform(drag)
		var end: Vector2 = player.position + world_drag
		draw_line(player.position, end, Color("fff1ad"), 4, true)
		if drag.length() >= 8.0:
			draw_line(end, end - drag.normalized().rotated(0.5) * 18, Color("fff1ad"), 4, true)
			draw_line(end, end - drag.normalized().rotated(-0.5) * 18, Color("fff1ad"), 4, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(launcher):
		launcher.cancel()

func _exit_tree() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


