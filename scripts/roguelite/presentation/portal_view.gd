extends Node2D
## 门的装饰与过门短环只消费最终实际搬移，不对请求播放假成功。
var source: Node2D
var _state: Dictionary = {}
var _clock: float = 0.0
var _pulses: Array[Dictionary] = []
func _ready() -> void:
	source = get_parent()
	source.traversed.connect(_on_traversed)
func _on_traversed(from_point: Vector2,to_point: Vector2) -> void:
	for point in [from_point,to_point]:
		_pulses.append({"point":to_local(point),"life":1.0})
	while _pulses.size()>12: _pulses.pop_front()
func _process(delta: float) -> void:
	_state = source.presentation_snapshot()
	_clock += delta if bool(_state.active) else 0.0
	for pulse in _pulses: pulse.life -= delta*5.0
	_pulses = _pulses.filter(func(pulse):return pulse.life>0.0)
	if not bool(_state.active): _pulses.clear()
	queue_redraw()
func _draw() -> void:
	if _state.is_empty(): return
	for index in 2:
		var point: Vector2 = _state.points[index]
		var normal: Vector2 = _state.normals[index]
		var radius: float = _state.radius
		var color: Color = Color("77dfd0") if index==0 else Color("94cee6")
		if not bool(_state.active): color.a=0.35
		draw_circle(point,radius,Color(0.12,0.35,0.36,0.28))
		draw_arc(point,radius,0,TAU,48,color,1.5,true)
		for angle in [0.0,PI]: draw_arc(point,radius-5,_clock*0.6+angle,_clock*0.6+angle+PI*0.45,16,Color(color,0.7*color.a),1,true)
		var tangent: Vector2 = normal.orthogonal()
		draw_polyline(PackedVector2Array([point+normal*4+tangent*5,point+normal*10,point+normal*4-tangent*5]),color,1.5,true)
	for pulse in _pulses:
		draw_arc(pulse.point,14+(1.0-pulse.life)*24,0,TAU,32,Color(0.6,1.0,0.88,pulse.life*0.65),1.5,true)
