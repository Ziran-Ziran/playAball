extends CanvasLayer
signal upgrade_selected(id: String, offer_id: int)
signal restart_requested
@onready var panel: PanelContainer = $Overlay/Panel
@onready var title: Label = $Overlay/Panel/Content/Title
@onready var summary: Label = $Overlay/Panel/Content/Summary
@onready var cards: VBoxContainer = $Overlay/Panel/Content/Cards
@onready var restart_button: Button = $Overlay/Panel/Content/Restart

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(func(): restart_requested.emit())
	panel.hide()

func clear_cards() -> void:
	for card in cards.get_children():
		cards.remove_child(card)
		card.queue_free()

func show_choices(choices: Array, levels: Dictionary = {}, pending_count: int = 1, offer_id: int = 0) -> void:
	clear_cards()
	title.text = "击杀奖励 · 选择一项"
	summary.text = "战斗已暂停 · 选完继续当前战斗" if pending_count <= 1 else "战斗已暂停 · 本次选完还有%d次奖励" % (pending_count - 1)
	restart_button.hide()
	for choice in choices:
		var card := Button.new()
		var level: int = int(levels.get(choice.id, 0))
		var limit: String = str(choice.max_level) if choice.max_level > 0 else "可重复"
		card.custom_minimum_size = Vector2(650, 90)
		card.tooltip_text = choice.description
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 12
		content.offset_right = -12
		content.offset_top = 8
		content.offset_bottom = -8
		var heading := Label.new()
		heading.text = "【%s】%s  %d→%d / %s" % [choice.category, choice.title, level, level + 1, limit]
		heading.add_theme_font_size_override("font_size", 18)
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(heading)
		var detail := Label.new()
		detail.text = choice.description
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 17)
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(detail)
		card.pressed.connect(func(): upgrade_selected.emit(choice.id, offer_id))
		cards.add_child(card)
	panel.show()

func show_result(won: bool, kills: int, longest: int) -> void:
	clear_cards()
	title.text = "拆迁完成！" if won else "这次先到这里"
	summary.text = "击破 %d · 最长接力 %d\nR 或按钮重新开局" % [kills, longest]
	restart_button.show()
	panel.show()

func close() -> void:
	clear_cards()
	panel.hide()
