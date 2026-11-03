extends Node2D
@export var definition: Resource
const WALL_ART: Texture2D = preload("res://assets/ui/arena_skin.png")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("active_run_map")
	# 使用现有已接入墙条位图，视觉子节点跟随真实刚体/机关，不在背景留墙影。
	for visual: Polygon2D in find_children("Visual*", "Polygon2D", true, false):
		var rect := Rect2(visual.polygon[0], Vector2.ZERO)
		for point: Vector2 in visual.polygon:
			rect = rect.expand(point)
		var uv := PackedVector2Array()
		var polygon: PackedVector2Array = visual.polygon
		var arc_quad: bool = polygon.size() == 4 and absf(polygon[0].length() - polygon[1].length()) > 5.0 and absf(polygon[0].length() - polygon[3].length()) < 1.0
		if arc_quad:
			# 圆弧沿切线连续取墙条，不再把整条1480px纹理压进每个小弧段。
			var angle: float = fposmod(polygon[0].angle(), TAU)
			var radius: float = (polygon[0].length() + polygon[1].length()) * 0.5
			var length: float = polygon[0].angle_to(polygon[3]) * radius
			var start: float = 90.0 + fposmod(angle / TAU * 1480.0, 1400.0)
			var end: float = start + absf(length) * 1.55
			uv = PackedVector2Array([Vector2(start,188), Vector2(start,160), Vector2(end,160), Vector2(end,188)])
		else:
			for point: Vector2 in polygon:
				if rect.size.y > rect.size.x * 2.0:
					uv.append(Vector2(90 + (point.y - rect.position.y) / maxf(1.0, rect.size.y) * 1480, 160 + (point.x - rect.position.x) / maxf(1.0, rect.size.x) * 28))
				else:
					uv.append(Vector2(90 + (point.x - rect.position.x) / maxf(1.0, rect.size.x) * 1480, 160 + (point.y - rect.position.y) / maxf(1.0, rect.size.y) * 28))
		visual.texture = WALL_ART
		visual.uv = uv
		visual.color = Color.WHITE
