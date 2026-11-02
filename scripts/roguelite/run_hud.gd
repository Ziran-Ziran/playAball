extends CanvasLayer
signal upgrade_selected(id: String, offer_id: int)
signal restart_requested
@onready var panel: PanelContainer = $Overlay/Panel
@onready var title: Label = $Overlay/Panel/Content/Title
@onready var summary: Label = $Overlay/Panel/Content/Summary
@onready var cards: BoxContainer = $Overlay/Panel/Content/Cards
@onready var restart_button: Button = $Overlay/Panel/Content/Restart
@onready var health_view: DemoHealthView = $Overlay/PlayerPanel
## 保留旧脚本的只读节点路径兼容；实际刷新仍在 DemoHealthView。
@onready var health_bar: ProgressBar = $Overlay/PlayerPanel/Content/HealthBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(func(): restart_requested.emit())
	panel.hide()

func bind_health(health: DemoHealth) -> void:
	health_view.bind_source(health)

func health_snapshot() -> Dictionary:
	return health_view.snapshot()

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
		card.custom_minimum_size = Vector2(240 if choices.size() <= 3 else 215, 380)
		card.tooltip_text = choice.description
		var frame := StyleBoxTexture.new()
		frame.texture = load("res://assets/ui/upgrade_card_frame_v2.png")
		card.add_theme_stylebox_override("normal", frame)
		card.add_theme_stylebox_override("hover", frame)
		card.add_theme_stylebox_override("pressed", frame)
		var focus_style := StyleBoxFlat.new()
		focus_style.draw_center = false
		focus_style.set_border_width_all(2)
		focus_style.border_color = Color("b2f8d4")
		card.add_theme_stylebox_override("focus", focus_style)
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 24
		content.offset_right = -24
		content.offset_top = 50
		content.offset_bottom = -8
		var heading := Label.new()
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		var flow := Control.new()
		flow.set_script(load("res://scripts/ui/card_flow.gd"))
		card.add_child(flow)
		card.disabled = true
		card.modulate.a = 0.0
		_animate_card.call_deferred(card, float(cards.get_child_count() - 1) * 0.1)
	panel.show()

func _animate_card(card: Button, delay: float) -> void:
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	var target: Vector2 = card.position
	card.position.y += 24
	card.scale = Vector2(0.985, 0.985)
	card.pivot_offset = card.size * 0.5
	var entrance := card.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance.tween_interval(delay)
	entrance.tween_property(card, "modulate:a", 1.0, 0.42)
	entrance.parallel().tween_property(card, "position", target, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.parallel().tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.tween_callback(func(): card.disabled = false)

func show_result(won: bool, kills: int, longest: int) -> void:
	clear_cards()
	title.text = "拆迁完成！" if won else "这次先到这里"
	summary.text = "击破 %d · 最长接力 %d\nR 或按钮重新开局" % [kills, longest]
	restart_button.show()
	panel.show()

func close() -> void:
	clear_cards()
	panel.hide()
