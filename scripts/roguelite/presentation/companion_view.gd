extends Node2D
## 同伴按只读slot选择AI身份；缩放、状态环与尾迹只影响视觉。
@export var sprite_extent: float = 36.0
@export var idle_period: float = 2.7
var _idle_clock: float = 0.0
var source: Node2D
var _state: Dictionary = {}
var _base_scale: Vector2
var _pulse: float = 0.0
var _last_mode: int = -1
var skin_id: String = "gpt"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	source = get_parent()
	skin_id = DemoBallArt.companion_id(int(source.presentation_snapshot().get("slot",0)))
	$Sprite.texture = DemoBallArt.texture_for(skin_id)
	$Sprite.region_enabled = true
	$Sprite.region_rect = DemoBallArt.region_for($Sprite.texture)
	_base_scale = Vector2.ONE*sprite_extent/maxf($Sprite.region_rect.size.x,$Sprite.region_rect.size.y)
	$Sprite.scale = _base_scale
func _process(delta: float) -> void:
	_idle_clock += delta
	_state = source.presentation_snapshot()
	visible = _state.theme_id == &"fat_fish"
	var mode: int = _state.mode
	if mode != _last_mode:
		_pulse = 1.0 if mode == 1 else 0.0
		_last_mode = mode
	_pulse = maxf(0.0,_pulse-delta*8.0)
	$Sprite.scale = _base_scale*Vector2(1.0-sin(_idle_clock*TAU/idle_period)*0.05,1.0+sin(_idle_clock*TAU/idle_period)*0.05)*Vector2(1.0+_pulse*0.09,1.0-_pulse*0.06)
	# 保留黑白/橙/紫身份配色，资格用真实状态环表达，不整图染成同一种青色。
	$Sprite.modulate = Color.WHITE
	queue_redraw()
func snapshot() -> Dictionary:
	return _state.duplicate(true)
func _draw() -> void:
	if _state.is_empty(): return
	var mode: int = _state.mode
	var color: Color = {"gpt":Color("a7ffd3"),"claude":Color("f5a273"),"qwen":Color("c5a2fa")}[skin_id]
	if mode == 1:
		var velocity: Vector2 = _state.velocity
		draw_line(Vector2.ZERO,-velocity.normalized()*minf(30.0,velocity.length()*0.025),Color(color,0.65),2.0,true)
		draw_arc(Vector2.ZERO,18,-PI/2,TAU*clampf(float(_state.active_left)/maxf(0.01,float(_state.active_duration)),0,1)-PI/2,28,color,2,true)
	elif mode == 2:
		for angle in [0.0,PI]: draw_arc(Vector2.ZERO,18,angle,angle+PI*0.65,12,color,1,true)
	else:
		draw_arc(Vector2.ZERO,18,0,TAU,28,Color(color,0.5),1,true)
