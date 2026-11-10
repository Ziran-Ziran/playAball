extends Control
## 卡框边缘流光为独立表现层，在奖励暂停期间运行；不处理点击或发奖励。
var clock: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if OceanUi.reduced_motion:
		queue_redraw()
		return
	clock += delta
	queue_redraw()

func _draw() -> void:
	if OceanUi.reduced_motion:
		return
	var points := PackedVector2Array()
	var margin := Vector2(size.x * 0.065, size.y * 0.04)
	var rect := Rect2(margin, size - margin * 2)
	var radius: float = minf(15.0, rect.size.x * 0.1)
	for corner in range(4):
		var center: Vector2 = [Vector2(rect.end.x-radius, rect.position.y+radius), rect.end-Vector2(radius,radius), Vector2(rect.position.x+radius,rect.end.y-radius), rect.position+Vector2(radius,radius)][corner]
		for step in range(9):
			var angle: float = (-PI/2 + corner*PI/2) + step*PI/16
			points.append(center+Vector2.from_angle(angle)*radius)
	points.append(points[0])
	var path := Curve2D.new()
	for point in points:
		path.add_point(point)
	var length: float = path.get_baked_length()
	for index in range(12):
		var distance: float = fmod(clock / 2.4 * length + index*2.0, length)
		draw_line(path.sample_baked(distance), path.sample_baked(fmod(distance+2, length)), Color(0.35,0.48,0.92,float(index)/30.0),1.2,true)
