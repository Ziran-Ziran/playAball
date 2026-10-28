extends Node2D

@export var spawn_point: Vector2 = Vector2(240, 604)
@onready var ball: PlayBall = $Ball
@onready var zone: Area2D = $Mechanism
@onready var feedback: Node2D = $ImpactFeedback
@onready var status: Label = $HUD/Panel/Content/Status
@onready var counter: Label = $HUD/Panel/Content/Counter
@onready var power: ProgressBar = $HUD/Panel/Content/Power

var won: bool = false
var shots: int = 0
var _dragging: bool = false
var _drag: Vector2 = Vector2.ZERO

func _ready() -> void:
	ball.impacted.connect(feedback.play_impact)
	$Goal.body_entered.connect(_on_goal_entered)
	$HUD/Panel/Content/Buttons/Reset.pressed.connect(reset_round)
	$HUD/Panel/Content/Buttons/Mode.item_selected.connect(set_mode)
	$HUD/Panel/Content/Buttons/Mute.toggled.connect(func(value: bool): feedback.sound_enabled = not value)
	$HUD/Panel/Content/Buttons/Shake.toggled.connect(func(value: bool): feedback.shake_enabled = not value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		reset_round()
	if event is InputEventMouseButton:
		var mouse_point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_dragging = false
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and ball.can_launch() and mouse_point.distance_to(ball.position) < 40.0:
				_dragging = true
			elif not event.pressed and _dragging:
				_drag = (ball.position - mouse_point).limit_length(ball.max_drag)
				if ball.launch(_drag):
					shots += 1
				_dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_dragging = false

func _process(_delta: float) -> void:
	if _dragging and not ball.can_launch():
		_dragging = false
	_drag = (ball.position - get_global_mouse_position()).limit_length(ball.max_drag) if _dragging else Vector2.ZERO
	power.value = _drag.length() / ball.max_drag * 100.0
	counter.text = "击球 %02d  /  R 重置  /  右键取消" % shots
	if won:
		status.text = "进球！本轮 %d 杆 · R 再试一次" % shots
	elif _dragging:
		status.text = "向后拖拽蓄力 · 松开发射"
	elif ball.can_launch():
		status.text = "准备就绪 · 按住球向后拖拽"
	else:
		status.text = "球运动中 · 等待停稳"
	if ball.position.y > 850 or ball.position.y < -180 or ball.position.x < -180 or ball.position.x > 1460:
		reset_round()
	queue_redraw()

func reset_round() -> void:
	_dragging = false
	_drag = Vector2.ZERO
	won = false
	shots = 0
	ball.reset_ball(spawn_point)

func set_mode(index: int) -> void:
	zone.set_kind(index)
	reset_round()

func _on_goal_entered(body: Node2D) -> void:
	if body != ball or won:
		return
	won = true
	_dragging = false
	ball.completed = true
	ball.set_deferred("freeze", true)
	feedback.play_impact(ball.position, 650.0)

func _draw() -> void:
	for x in range(0, 1281, 40):
		draw_line(Vector2(x, 300), Vector2(x, 640), Color(0.13, 0.23, 0.32, 0.22))
	for y in range(320, 641, 40):
		draw_line(Vector2(40, y), Vector2(1240, y), Color(0.13, 0.23, 0.32, 0.22))
	# 目标光环与地面装饰不参与物理。
	draw_circle(Vector2(1110, 590), 42, Color(0.4, 1.0, 0.72, 0.08))
	draw_arc(Vector2(1110, 590), 32, 0, TAU, 64, Color("77e6b4"), 3, true)
	draw_line(Vector2(1080, 638), Vector2(1140, 638), Color("77e6b4"), 4)
	if _dragging:
		var destination: Vector2 = ball.position + _drag
		draw_line(ball.position, destination, Color("f6b965"), 3, true)
		draw_circle(destination, 5, Color("f6b965"))
		# 仅作初始方向提示；不预测障碍反弹或机关效果。
		var velocity: Vector2 = ball.impulse_for_drag(_drag) / ball.mass
		for index in range(1, 19):
			var time: float = float(index) * 0.035
			var point: Vector2 = ball.position + velocity * time + Vector2(0, 490) * time * time
			if point.y > 620 or point.y < 280:
				break
			draw_circle(point, 2.0, Color(0.6, 0.9, 1.0, 0.6))
