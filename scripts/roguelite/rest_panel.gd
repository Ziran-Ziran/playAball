extends CanvasLayer
signal action_selected(action: String, revision: int)
var revision: int = 0
@onready var panel: PanelContainer = $Backdrop/Panel
@onready var heading: Label = $Backdrop/Panel/Content/Heading
@onready var detail: Label = $Backdrop/Panel/Content/Detail
@onready var actions: VBoxContainer = $Backdrop/Panel/Content/Body/Scroll/Actions
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").apply($Backdrop)
	$Backdrop.resized.connect(func(): if visible: _fit_panel.call_deferred())
	hide()
func show_rest(title: String, description: String, offers: Array, quote: int) -> void:
	# 正式Game可能在父_ready覆盖大纹理；首次展示前恢复由本组件掌管的实色面板。
	panel.remove_theme_stylebox_override("panel")
	preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").apply($Backdrop)
	revision = quote
	heading.text = title
	detail.text = description
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	# 整备先陈列，免费离场随后；原id和revision仍原样交给玩法校验。
	var ordered: Array = offers.duplicate()
	if offers.any(func(offer): return str(offer.id).begins_with("paid_")):
		ordered = offers.filter(func(offer): return str(offer.id).begins_with("paid_"))
		ordered.append_array(offers.filter(func(offer): return not str(offer.id).begins_with("paid_")))
	$Backdrop/Panel/Content/Body/Scroll.scroll_vertical = 0
	for offer in ordered:
		var button := Button.new()
		var id: String = offer.id
		var explanation: String = _offer_note(id)
		if not offer.enabled and id.begins_with("paid_") and not "已购" in str(offer.text):
			explanation = ("暂不可选：金币不足" if id == "paid_upgrade" else "暂不可选：生命已满或金币不足") + " · 免费补给仍保留"
		button.text = str(offer.text)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not offer.enabled
		button.custom_minimum_size = Vector2(0, 72 if not explanation.is_empty() else 58)
		button.tooltip_text = str(offer.text)
		button.set_meta("offer_id", id)
		var captured: int = revision
		button.pressed.connect(func(): action_selected.emit(id, captured))
		actions.add_child(button)
		OceanUi.bind_button(button)
		if id in ["continue", "skip", "next"] and not button.disabled:
			OceanUi.primary(button)
		if not explanation.is_empty():
			_style_offer(button, str(offer.text), explanation, id in ["continue", "skip", "next"] and not button.disabled)
	show()
	OceanUi.reveal(panel)
	_fit_panel.call_deferred()
	for button: Button in actions.get_children():
		if not button.disabled:
			button.grab_focus()
			break

func _offer_note(id: String) -> String:
	match id:
		"paid_heal": return "可选金币整备 · 不离场，免费补给保留"
		"paid_upgrade": return "可选金币整备 · 选卡后返回，免费补给保留"
		"heal": return "免费恢复后立即进入下一阶段" if heading.text == "路边补给摊" else "恢复生命，最多补到生命上限"
		"upgrade": return "免费选卡后进入下一阶段；想整备请先购买上方项目" if heading.text == "路边补给摊" else "从当前可用成长中选择一项"
		"continue", "next": return "保留剩余金币，继续下一阶段"
		"skip": return "保留当前状态，继续下一阶段"
	return ""

func _style_offer(button: Button, text: String, explanation: String, primary: bool) -> void:
	# 保留Button真实文字语义，以子标签区分价格标题和较小的辅助说明。
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(key, Color.TRANSPARENT)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 20
	margin.offset_top = 10
	margin.offset_right = -20
	margin.offset_bottom = -10
	button.add_child(margin)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)
	var title_color := Color.WHITE if primary else Color("29385d") if not button.disabled else Color("8792a9")
	var note_color := Color("edf2ff") if primary else Color("5c6e91") if not button.disabled else Color("8792a9")
	var title_label: Label = OceanUi.label(text, 18, title_color)
	var note_label: Label = OceanUi.label(explanation, 14, note_color)
	for label: Label in [title_label, note_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)

func _fit_panel() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var width: float = minf(880, viewport_size.x - 64)
	# 自动换行必须先知道真实可用宽度；否则首帧会按接近零宽度算成几十行。
	panel.size.x = width
	detail.size.x = width - panel.get_theme_stylebox("panel").get_minimum_size().x
	detail.update_minimum_size()
	$Backdrop/Panel/Content.update_minimum_size()
	panel.update_minimum_size()
	# 按可视高度限制弹窗；五选项在独立滚动区内，不把确认按钮挤出屏幕。
	var target_height: float = minf(640.0, viewport_size.y - 48.0)
	$Backdrop/Panel/Content/Body/Character.visible = viewport_size.y >= 650.0 and width >= 760.0
	panel.size = Vector2(width, target_height)
	panel.position = (viewport_size - panel.size) * 0.5
