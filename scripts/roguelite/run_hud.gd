extends CanvasLayer
signal upgrade_selected(id: String, offer_id: int)
signal restart_requested
signal menu_requested
@onready var panel: PanelContainer = $Overlay/Panel
@onready var title: Label = $Overlay/Panel/Content/Title
@onready var summary: Label = $Overlay/Panel/Content/Summary
@onready var cards: BoxContainer = $Overlay/Panel/Content/Cards
@onready var restart_button: Button = $Overlay/Panel/Content/Restart
@onready var home_button: Button = $Overlay/Panel/Content/Home
@onready var health_view: DemoHealthView = $Overlay/PlayerPanel
## 保留旧脚本的只读节点路径兼容；实际刷新仍在 DemoHealthView。
@onready var health_bar: ProgressBar = $Overlay/PlayerPanel/Content/HealthBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(func(): restart_requested.emit())
	home_button.pressed.connect(func(): menu_requested.emit())
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
	panel.position = Vector2(80,130)
	panel.size = Vector2(1120,530)
	cards.show()
	home_button.hide()
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
		var content := Control.new()
		content.name = "Content"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 24
		content.offset_right = -24
		content.offset_top = 0
		content.offset_bottom = 0
		var heading := Label.new()
		heading.name = "Heading"
		heading.position = Vector2(0,38)
		heading.size = Vector2(192 if choices.size() <= 3 else 167,72)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.text = "【%s】\n%s\n%d→%d / %s" % [choice.category, choice.title, level, level + 1, limit]
		heading.add_theme_font_size_override("font_size", 18)
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(heading)
		var detail := Label.new()
		detail.name = "Detail"
		detail.position = Vector2(0,223)
		detail.size = Vector2(192 if choices.size() <= 3 else 167,136)
		detail.text = choice.description
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 14)
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(detail)
		var preview := Label.new()
		preview.name = "Preview"
		preview.position = Vector2(0,122)
		preview.size = Vector2(192 if choices.size() <= 3 else 167,65)
		preview.text = benefit_preview(choice.id, levels)
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview.add_theme_font_size_override("font_size",15)
		preview.add_theme_color_override("font_color",Color("b8f4d5"))
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(preview)
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
	cards.hide()
	panel.position = Vector2(350,205)
	panel.size = Vector2(580,310)
	title.text = "拆迁完成！" if won else "这次先到这里"
	summary.text = "击破 %d · 最长接力 %d\nR 或按钮重新开局" % [kills, longest]
	restart_button.show()
	home_button.visible = not menu_requested.get_connections().is_empty()
	panel.show()

func close() -> void:
	clear_cards()
	panel.hide()

func benefit_preview(id: String, levels: Dictionary) -> String:
	var current := DemoBuild.new()
	current.levels = levels.duplicate()
	var after := DemoBuild.new()
	after.levels = levels.duplicate()
	after.choose(id)
	match id:
		"launch_power": return "主动冲量 %.0f%% → %.0f%%" % [current.launch_multiplier()*100,after.launch_multiplier()*100]
		"glide": return "阻尼 %.0f%% → %.0f%%\n摩擦 %.0f%% → %.0f%%" % [current.damping_multiplier()*100,after.damping_multiplier()*100,current.friction_multiplier()*100,after.friction_multiplier()*100]
		"cooldown": return "冷却 %.2f → %.2f 秒\n本次减少 %.2f 秒" % [current.launch_cooldown(),after.launch_cooldown(),current.launch_cooldown()-after.launch_cooldown()]
		"double_launch": return "储存 %d → %d 次\n冷却逐次恢复" % [current.launch_capacity(),after.launch_capacity()]
		"heavy": return "额外撞伤 +%d → +%d\n低速仍不造成伤害" % [int(levels.get(id,0)),int(after.levels.get(id,0))]
		"echo": return "有效命中追加 1 点\n延迟 0.12 秒，不递归"
		"bowling": return "投射可撞另外 2 敌人\n有效 0.6 秒，不传代"
		"explosion": return "伙伴首击触发爆炸\n半径 80 · 伤害 1"
		"companion": return "外包 %d → %d / 3 个\n受撞后短时出击" % [current.companion_count(),after.companion_count()]
		"follow": return "待命跟随 关闭 → 开启\n出击结束后归队"
		"relay": return "基础传能 → 强化接力\n每球每链一次补偿"
		"shrink": return "攻击范围 %.0f%% → %.0f%%\n实体尺寸保持不变" % [current.attack_radius_scale()*100,after.attack_radius_scale()*100]
		"pulse": return "每 4 秒震退一次\n半径 150 · 不直接伤害"
		"heal":
			var hp: Dictionary = health_snapshot()
			var before: int = int(hp.get("hp",0))
			var maximum: int = int(hp.get("max_hp",5))
			return "生命 %d → %d / %d\n本次恢复 %d" % [before,mini(maximum,before+2),maximum,mini(2,maximum-before)]
		"choices": return "后续成长\n3 选 1 → 4 选 1"
		"vigor": return "生命上限 %d → %d\n同时恢复 1 点生命" % [current.max_health(),after.max_health()]
	return ""
