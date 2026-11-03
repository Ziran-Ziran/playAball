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
func _ready() -> void:
	source = get_parent()
	_base_scale = Vector2.ONE * sprite_extent / maxf(1.0, $Sprite.texture.get_width())
	$Sprite.scale = _base_scale
	if source.has_signal("visual_event"):
		source.visual_event.connect(_on_visual_event)
	if source.has_signal("impacted"):
		source.impacted.connect(func(_point: Vector2, speed: float): _on_visual_event(&"contact", {"speed": speed}))
func _on_visual_event(event: StringName, payload: Dictionary) -> void:
	if event == &"reset":
		recharge_pulse_left=0.0
		_flash_left=0.0
		_squash=Vector2.ONE
	elif event == &"charge_restored":
		recharge_pulse_left=recharge_pulse_duration
	elif event == &"launch":
		_squash = Vector2(1.08, 0.94)
	elif event in [&"damage", &"contact"]:
		var strength: float = clampf(float(payload.get("speed", 0.0)) / 900.0, 0.0, 1.0)
		_squash = Vector2(1.0 + 0.12 * strength, 1.0 - 0.10 * strength)
		if event == &"damage": _flash_left = 0.07
func _process(delta: float) -> void:
	if not is_instance_valid(source) or not source.has_method("presentation_snapshot"):
		return
	_snapshot = source.presentation_snapshot()
	visible = _snapshot.theme_id == &"fat_fish"
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-delta * 22.0))
	var velocity: Vector2 = _snapshot.velocity
	var motion: float = clampf(velocity.length() / 1500.0, 0.0, 1.0)
	$Sprite.scale = _base_scale * _squash * Vector2(1.0 + motion * 0.025, 1.0 - motion * 0.02)
	$Sprite.rotation = clampf(velocity.x / 1500.0 * 0.06, -0.06, 0.06)
	_flash_left = maxf(0.0, _flash_left - delta)
	recharge_pulse_left=maxf(0.0,recharge_pulse_left-delta)
	$Sprite.modulate = Color(1.12, 1.12, 1.12) if _flash_left > 0.0 else Color.WHITE
	queue_redraw()
func _draw() -> void:
	if recharge_pulse_left>0.0:
		# 两段青色短弧与原冷却环区分；只表示真实返回一格，不制造护盾或伤害。
		var remaining: float=recharge_pulse_left/maxf(0.01,recharge_pulse_duration)
		var radius: float=32.0+(1.0-remaining)*6.0
		for angle: float in [0.0,PI]:
			draw_arc(Vector2.ZERO,radius,angle-0.65,angle+0.65,16,Color(0.5,0.95,0.85,remaining*0.7),2,true)
	if bool(_snapshot.get("well_fed", false)):
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color("ffdb78"), 1.5, true)
