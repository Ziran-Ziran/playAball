class_name DemoUpgradeCard
extends Button
## 单张卡只展示传入的数据、纹理和收益，不应用升级、不读取或修改物理。
@export_group("插画与文字布局")
@export_range(18, 28, 1) var title_font_size: int = 20
@export_range(13, 18, 1) var detail_font_size: int = 13

func _ready() -> void:
	resized.connect(_layout)
	mouse_entered.connect(func(): self_modulate = Color(1.10, 1.10, 1.10))
	mouse_exited.connect(func(): self_modulate = Color.WHITE)
	_layout.call_deferred()

func configure(definition: DemoUpgrade, next_level: int, benefit: String, copy: Dictionary, art: Texture2D) -> void:
	$Content/Category.text = definition.category
	$Content/Heading.text = definition.title
	$Content/Illustration.texture = art
	$Content/Level.text = "%d → %d 级 / %d" % [next_level - 1, next_level, definition.max_level] if definition.max_level > 0 else "可重复 · 本局成长" if definition.id == "vigor" else "可重复 · 即时恢复"
	$Content/Preview.text = benefit
	$Content/Detail.text = str(copy.get("rules", definition.description))
	$Content/Flavor.text = str(copy.get("flavor", ""))
	tooltip_text = definition.description
	set_meta("upgrade_id", definition.id)
	set_meta("next_level", next_level)
	_layout()

func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	pivot_offset = size * 0.5
	# 所有文字先按实际宽度测量，再给插画剩余空间；文字不再依赖卡高百分比。
	var inset: float = 20.0
	var width: float = maxf(1.0, size.x - inset * 2)
	$Content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var heights: Dictionary = {}
	for key: String in ["Category","Heading","Level","Preview","Detail","Flavor"]:
		var label: Label = get_node("Content/"+key)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		label.size.x = width
		var font_size: int = {"Category":11,"Heading":title_font_size,"Level":11,"Preview":20 if size.x >= 260 else 17,"Detail":detail_font_size,"Flavor":10}[key]
		label.add_theme_font_size_override("font_size",font_size)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heights[key] = maxf(label.get_minimum_size().y,label.get_line_count() * label.get_theme_font("font").get_height(font_size) + 2.0)
	var text_total: float = 0.0
	for value: float in heights.values(): text_total += value
	var gap: float = 5.0
	var image_height: float = maxf(24.0,size.y-inset*2-text_total-gap*6)
	var y: float = inset
	for key: String in ["Category","Heading","Illustration","Level","Preview","Detail","Flavor"]:
		var height: float = image_height if key == "Illustration" else float(heights[key])
		_place(get_node("Content/"+key),Rect2(inset,y,width,height))
		y += height + gap

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
