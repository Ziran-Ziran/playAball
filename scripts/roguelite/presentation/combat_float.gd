extends Node2D
## 短时浮字/死亡碎光只消费已结算事件，绝不再次调用伤害。
var effect: StringName = &"damage"
var amount: int = 0
var tint: Color = Color("c6ffe0")
var age: float = 0.0
var lifetime: float = 0.34
func _ready() -> void:
	# 正式Run为ALWAYS；战场浮字须显式暂停，不能在决策静止期间悄悄消退。
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("demo_combat_floats")
	z_index = 8
func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
	else:
		queue_redraw()
func _draw() -> void:
	var ratio: float = clampf(age / lifetime, 0.0, 1.0)
	var color := Color(tint, 1.0 - ratio)
	if effect == &"damage":
		var font: Font = ThemeDB.fallback_font
		var text: String = str(amount)
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		var point := Vector2(-width * 0.5, -23.0 - ratio * 18.0)
		draw_string(font, point + Vector2(1,1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.03,0.07,0.08,1.0-ratio))
		draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, color)
	else:
		# 最后一帧仍可能被排队绘制；极小菱形无法稳定三角化，透明尾端直接结束。
		if 2.4 * (1.0 - ratio) < 0.15:
			return
		for index in 4:
			var point: Vector2 = Vector2.from_angle(PI * 0.25 + index * PI * 0.5) * (5.0 + ratio * 16.0)
			var size: float = 2.4 * (1.0 - ratio)
			draw_colored_polygon(PackedVector2Array([point+Vector2(-size,0),point+Vector2(0,-size),point+Vector2(size,0),point+Vector2(0,size)]), color)
