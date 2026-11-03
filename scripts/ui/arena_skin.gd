extends Node2D
## 从已认可全景中取无字地面/墙条，按真实碰撞坐标绘制；不复制图中的示例HUD。
var art: Texture2D = preload("res://assets/ui/arena_skin.png")

func _ready() -> void:
	z_index = -10
	var source_uvs: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(35,160),Vector2(85,160),Vector2(35,210)]),
		PackedVector2Array([Vector2(1585,160),Vector2(1637,160),Vector2(1637,210)]),
		PackedVector2Array([Vector2(35,825),Vector2(85,875),Vector2(35,875)]),
		PackedVector2Array([Vector2(1585,875),Vector2(1637,825),Vector2(1637,875)])]
	var corners := get_parent().get_node("Corners")
	for index in corners.get_child_count():
		var visual := Polygon2D.new()
		visual.polygon = corners.get_child(index).polygon
		visual.texture = art
		visual.uv = source_uvs[index]
		add_child(visual)

func _draw() -> void:
	draw_texture_rect_region(art, Rect2(40,125,1200,553), Rect2(100,250,1400,500))
	draw_texture_rect_region(art, Rect2(40,101,1200,24), Rect2(90,160,1480,28))
	draw_texture_rect_region(art, Rect2(40,678,1200,24), Rect2(90,848,1480,28))
	draw_texture_rect_region(art, Rect2(16,125,24,553), Rect2(35,220,28,580))
	draw_texture_rect_region(art, Rect2(1240,125,24,553), Rect2(1610,220,28,580))
	for key in ["LeftRamp", "RightRamp"]:
		var ramp := get_parent().get_node(key) as Node2D
		if ramp.get_node("Shape").disabled:
			continue
		draw_set_transform(ramp.position, ramp.rotation)
		draw_texture_rect_region(art, Rect2(-100,-11,200,22), Rect2(90,160,1480,28))
	draw_set_transform(Vector2.ZERO)
