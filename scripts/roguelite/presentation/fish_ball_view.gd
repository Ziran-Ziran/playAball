extends Node2D
## 肥鱼位图与轻量形变只消费只读快照和真实事件，不参与碰撞/伤害。
@export var sprite_extent: float = 58.0
@export_range(0.1,0.4) var recharge_pulse_duration: float = 0.24
var recharge_pulse_left: float = 0.0
var source: Node2D
var _base_scale: Vector2
var _squash: Vector2 = Vector2.ONE
var _flash_left: float = 0.0
var _snapshot: Dictionary = {}
@export var idle_period: float = 2.4
@export var idle_amplitude: float = 0.055
var _idle_clock: float = 0.0
var _pose_left: float = 0.0
var _pose: int = -1
@export var response_frequency: float = 22.0
var _elastic: float = 0.0
var _elastic_speed: float = 0.0
var _pose_duration: float = 0.0
var _framing: float = 1.0
var _launch_left: float = 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	source = get_parent()
	$Sprite.region_enabled = true
	$Sprite.region_rect = DemoBallArt.region_for($Sprite.texture)
	_base_scale = Vector2.ONE * sprite_extent / maxf($Sprite.region_rect.size.x, $Sprite.region_rect.size.y)
	$Sprite.scale = _base_scale
	if source.has_signal("visual_event"):
		source.visual_event.connect(_on_visual_event)
	if source.has_signal("impacted"):
		source.impacted.connect(func(_point: Vector2, speed: float): _on_visual_event(&"contact", {"speed": speed}))
func _on_visual_event(event: StringName, payload: Dictionary) -> void:
	if event == &"reset":
		_pose_left=0.0
		_pose=-1
		_idle_clock=0.0
		_framing=1.0
		_elastic=0.0
		_elastic_speed=0.0
		recharge_pulse_left=0.0
		_flash_left=0.0
		_squash=Vector2.ONE
		_launch_left=0.0
	elif event == &"charge_restored":
		recharge_pulse_left=recharge_pulse_duration
	elif event == &"launch":
		_elastic_speed += 1.5
		_launch_left = 0.18
	elif event == &"kill":
		_elastic_speed -= 1.8
		_launch_left = 0.22
	elif event in [&"damage", &"contact"]:
		_pose = 3 if event == &"damage" else 2
		_pose_duration = 0.34 if event == &"damage" else 0.24
		_pose_left = _pose_duration
		var strength: float = clampf(float(payload.get("speed", 0.0)) / 900.0, 0.0, 1.0)
		_elastic_speed += 1.8 if event == &"damage" else 0.8+1.0*strength
		if event == &"damage": _flash_left = 0.07
func _process(delta: float) -> void:
	if not is_instance_valid(source) or not source.has_method("presentation_snapshot"):
		return
	_idle_clock += delta
	_pose_left = maxf(0.0, _pose_left-delta)
	var breath: float = sin(_idle_clock * TAU / maxf(0.5,idle_period))
	# 待机不换图；避免不同alpha构图在阈值跳变。弹簧用解析更新，不依赖帧数。
	var omega: float = maxf(4.0,response_frequency)
	var decay: float = exp(-omega*delta)
	var spring_term: float = _elastic_speed+omega*_elastic
	_elastic = (_elastic+spring_term*delta)*decay
	_elastic_speed = (_elastic_speed-omega*spring_term*delta)*decay
	_elastic = clampf(_elastic,-0.18,0.18)
	var elapsed: float = _pose_duration-_pose_left
	var pose: int = _pose if _pose_left>0.045 and elapsed>0.035 else -1
	$Sprite.texture = DemoBallArt.animation_frame("hero",pose) if pose>=0 else DemoBallArt.texture_for("hero")
	$Sprite.region_rect = DemoBallArt.region_for($Sprite.texture)
	# 生成碰撞图有更宽的散发/尾鳍；按脸部比例校正，而不是把额外装饰挤进同一外框。
	var framing_target: float = 1.09 if pose==2 else (1.07 if pose==3 else 1.0)
	_framing = lerpf(_framing,framing_target,1.0-exp(-delta*12.0))
	var neutral_size: Vector2 = DemoBallArt.region_for(DemoBallArt.texture_for("hero")).size
	var target_size: Vector2 = neutral_size*sprite_extent/maxf(neutral_size.x,neutral_size.y)
	_base_scale = target_size*_framing/$Sprite.region_rect.size
	_snapshot = source.presentation_snapshot()
	visible = _snapshot.theme_id == &"fat_fish"
	_squash = Vector2(1.0+_elastic,1.0-_elastic)
	var velocity: Vector2 = _snapshot.velocity
	var motion: float = clampf(velocity.length() / 1500.0, 0.0, 1.0)
	$Sprite.scale = _base_scale * _squash * Vector2(1.0-breath*idle_amplitude,1.0+breath*idle_amplitude) * Vector2(1.0 + motion * 0.025, 1.0 - motion * 0.02)
	$Sprite.rotation = clampf(velocity.x / 1500.0 * 0.06, -0.06, 0.06)
	_flash_left = maxf(0.0, _flash_left - delta)
	_launch_left = maxf(0.0, _launch_left - delta)
	recharge_pulse_left=maxf(0.0,recharge_pulse_left-delta)
	$Sprite.modulate = Color(1.12, 1.12, 1.12) if _flash_left > 0.0 else Color.WHITE
	queue_redraw()
func _draw() -> void:
	var velocity: Vector2 = _snapshot.get("velocity", Vector2.ZERO)
	if velocity.length() > 180.0:
		var back: Vector2 = -velocity.normalized()
		var tangent: Vector2 = back.orthogonal()
		var strength: float = clampf(velocity.length() / 1200.0, 0.0, 1.0)
		for side: float in [-1.0, 1.0]:
			draw_polyline(PackedVector2Array([back*18+tangent*side*11,back*(26+strength*9)+tangent*side*8,back*(32+strength*13)+tangent*side*3]),Color(0.55,0.88,1.0,strength*0.35),1.5,true)
	if _launch_left > 0.0:
		var remaining: float = _launch_left / 0.18
		draw_arc(Vector2.ZERO,24.0+(1.0-remaining)*12.0,0,TAU,36,Color(0.65,0.95,1.0,remaining*0.45),1.5,true)
	if recharge_pulse_left>0.0:
		# 两段青色短弧与原冷却环区分；只表示真实返回一格，不制造护盾或伤害。
		var remaining: float=recharge_pulse_left/maxf(0.01,recharge_pulse_duration)
		var radius: float=32.0+(1.0-remaining)*6.0
		for angle: float in [0.0,PI]:
			draw_arc(Vector2.ZERO,radius,angle-0.65,angle+0.65,16,Color(0.5,0.95,0.85,remaining*0.7),2,true)
	if bool(_snapshot.get("well_fed", false)):
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color("ffdb78"), 1.5, true)
