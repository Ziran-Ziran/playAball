extends Control
## 复用已生成框/十字/红格/空格，数字和格数由真实生命源驱动。
const ART = preload("res://assets/ui/health_skin.png")
var source: DemoHealthView
var _hp: Label
var _state: Label
var _clips: Array[Control] = []
var _fills: Array[TextureRect] = []
var _count: int = 0
var _clock: float = 0.0

func atlas(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ART
	texture.region = region
	texture.filter_clip = true
	return texture

func label_at(text: String, point: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func cell_material(region: Rect2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/ui/health_cell.gdshader")
	material.set_shader_parameter("region_uv", Vector4(region.position.x / ART.get_width(), region.position.y / ART.get_height(), region.size.x / ART.get_width(), region.size.y / ART.get_height()))
	return material

func _ready() -> void:
	name = "HealthSkin"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(24, 8)
	size = Vector2(430, 104)
	label_at("生命", Vector2(310, 8), 16)
	_hp = label_at("", Vector2(308, 29), 27)
	_state = label_at("", Vector2(73, 78), 15)
	_rebuild(5)

func _rebuild(count: int) -> void:
	for child in get_children():
		if child is TextureRect or child in _clips:
			child.queue_free()
	_clips.clear()
	_fills.clear()
	_count = count
	var step: float = 225.0 / count
	for index in count:
		var empty := TextureRect.new()
		empty.texture = atlas(Rect2(438,79,78,56))
		empty.material = cell_material(Rect2(438,79,78,56))
		empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		empty.position = Vector2(73 + index * step, 27)
		empty.size = Vector2(step, 39)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(empty)
		var clip := Control.new()
		clip.position = empty.position
		clip.size = empty.size
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clip)
		var fill := TextureRect.new()
		fill.texture = atlas(Rect2(176,79,78,56))
		fill.material = cell_material(Rect2(176,79,78,56))
		fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill.size = empty.size
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(fill)
		_clips.append(clip)
		_fills.append(fill)

func _process(delta: float) -> void:
	if not is_instance_valid(source):
		return
	var data: Dictionary = source.snapshot()
	if data.is_empty(): return
	var maximum: int = maxi(1, int(data.max_hp))
	var count: int = mini(maximum, 12)
	if count != _count: _rebuild(count)
	_hp.text = "%d / %d" % [data.hp, data.max_hp]
	_state.text = str(data.state_text)
	if not get_tree().paused: _clock += delta
	var phase: float = fmod(_clock, 2.0)
	for index in count:
		var fraction: float = clampf(float(data.hp) / maximum * count - index, 0, 1)
		_clips[index].size.x = 225.0 / count * fraction
		var distance: float = absf(phase / 0.65 * count - index - 0.5)
		var peak: float = maxf(0, 1.0 - distance) if phase < 0.65 else 0.0
		_fills[index].self_modulate = Color(1 + peak * 0.7, 1 + peak * 0.5, 1 + peak * 0.4)
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,16),Vector2(16,0),Vector2(402,0),Vector2(424,19),Vector2(424,80),Vector2(405,102),Vector2(16,102),Vector2(0,86)]),Color("111b23"))
	draw_texture_rect_region(ART, Rect2(1,13,65,65), Rect2(37,37,145,145))
	draw_texture_rect_region(ART, Rect2(70,17,230,10), Rect2(172,55,359,23))
	draw_texture_rect_region(ART, Rect2(70,66,230,9), Rect2(172,134,359,24))
