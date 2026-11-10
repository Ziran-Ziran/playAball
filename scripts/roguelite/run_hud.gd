extends CanvasLayer
signal upgrade_selected(id: String, offer_id: int)
signal restart_requested
signal menu_requested
signal reroll_requested(offer_id: int)
const UPGRADE_CARD: PackedScene = preload("res://scenes/roguelite/presentation/upgrade_card.tscn")
var card_art: DemoCardArtLibrary = DemoCardArtLibrary.new()
var _showing_choices: bool = false
var _choice_count: int = 0
var _current_offer_id: int = -1
var reroll_row: HBoxContainer
var reroll_status: Label
var reroll_button: Button
var _reroll_available: bool = false
var _choice_scroll: ScrollContainer
@export var reward_panel_max_size: Vector2 = Vector2(1184.0, 640.0)
@export_range(240.0, 380.0, 1.0) var reward_card_max_width: float = 350.0
@onready var panel: PanelContainer = $Overlay/Panel
@onready var title: Label = $Overlay/Panel/Content/Title
@onready var summary: Label = $Overlay/Panel/Content/Summary
@onready var cards: BoxContainer = $Overlay/Panel/Content/Cards
@onready var restart_button: Button = $Overlay/Panel/Content/ResultActions/Restart
@onready var home_button: Button = $Overlay/Panel/Content/ResultActions/Home
@onready var result_body: DsResultBody = $Overlay/Panel/Content/ResultBody
@onready var result_actions: HBoxContainer = $Overlay/Panel/Content/ResultActions
@onready var health_view: DemoHealthView = $Overlay/PlayerPanel
## 保留旧脚本的只读节点路径兼容；实际刷新仍在 DemoHealthView。
@onready var health_bar: ProgressBar = $Overlay/PlayerPanel/Content/HealthBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.remove_theme_stylebox_override("panel")
	# 浅色弹窗主题只作用于弹窗，深色战斗HUD仍使用原来的浅色文字。
	preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").apply(panel)
	var pause_menu: Control = get_parent().get_node_or_null("HUD/Menu")
	if pause_menu != null:
		preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").apply(pause_menu)
		pause_menu.visibility_changed.connect(func():
			# 暂停菜单位于另一CanvasLayer；隐藏常驻HUD避免生命皮肤盖住标题。
			$Overlay.visible = not pause_menu.visible
			if pause_menu.visible:
				pause_menu.position = (get_viewport().get_visible_rect().size - pause_menu.size) * 0.5
				pause_menu.get_node("Buttons/Resume").grab_focus()
		)
	preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").primary(restart_button)
	restart_button.pressed.connect(func(): restart_requested.emit())
	home_button.pressed.connect(func(): menu_requested.emit())
	panel.z_index = 10
	OceanUi.bind_button(restart_button)
	OceanUi.bind_button(home_button)
	var scrim := ColorRect.new()
	scrim.color = Color(0.015,0.035,0.032,0.96)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.z_index = 9
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Overlay.add_child(scrim)
	scrim.visible = panel.visible
	panel.visibility_changed.connect(func(): scrim.visible = panel.visible)
	panel.hide()
	$Overlay.resized.connect(_on_overlay_resized)
	# 独立只读构筑反馈；不接管卡片信号、奖励入场或玩法判定。
	var feedback := preload("res://scenes/roguelite/presentation/build_feedback.tscn").instantiate()
	add_child(feedback)
	# 次级操作独立一行；卡片正文仍由原内容流测量，不删减规则。
	reroll_row = HBoxContainer.new()
	reroll_row.name = "RerollRow"
	reroll_row.add_theme_constant_override("separation", 12)
	$Overlay/Panel/Content.add_child(reroll_row)
	reroll_row.hide()
	reroll_status = Label.new()
	reroll_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll_status.add_theme_font_size_override("font_size", 16)
	reroll_row.add_child(reroll_status)
	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(160, 48)
	reroll_button.add_theme_font_size_override("font_size", 18)
	reroll_row.add_child(reroll_button)
	reroll_button.pressed.connect(func(): reroll_requested.emit(_current_offer_id))
	# 图鉴/独立展示也会直接show_choices；滚动结构始终一致，不依赖先报价一次。
	show_reroll(0, 0, 0, false)
	reroll_row.hide()

func bind_health(health: DemoHealth) -> void:
	health_view.bind_source(health)

func health_snapshot() -> Dictionary:
	return health_view.snapshot()

func clear_cards() -> void:
	for card in cards.get_children():
		cards.remove_child(card)
		card.queue_free()

func show_choices(choices: Array, levels: Dictionary = {}, pending_count: int = 1, offer_id: int = 0) -> void:
	_current_offer_id = offer_id
	reroll_row.hide()
	_reroll_available = false
	clear_cards()
	result_body.hide()
	result_actions.hide()
	panel.remove_theme_stylebox_override("panel")
	_showing_choices = true
	_choice_count = choices.size()
	_layout_choices_panel()
	cards.show()
	home_button.hide()
	title.text = "击杀奖励 · 选择一项"
	summary.text = "战斗已暂停 · 选完继续当前战斗" if pending_count <= 1 else "战斗已暂停 · 本次选完还有%d次奖励" % (pending_count - 1)
	restart_button.hide()
	for choice: DemoUpgrade in choices:
		var next_level: int = int(levels.get(choice.id, 0)) + 1
		var card: DemoUpgradeCard = UPGRADE_CARD.instantiate()
		card.custom_minimum_size = Vector2(_card_width(), 0.0)
		if is_instance_valid(_choice_scroll):
			card.custom_minimum_size.y = 420.0
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cards.add_child(card)
		card.configure(choice, next_level, benefit_preview(choice.id, levels), card_art.copy_for(choice.id), card_art.texture_for(choice.id, next_level))
		card.set_meta("art_path", card_art.path_for(choice.id, next_level))
		card.pressed.connect(func():
			# Button仍提供轻点/键盘语义；拖动只滚正文，不提交不可撤销的升级请求。
			if card.can_submit_selection():
				upgrade_selected.emit(choice.id, offer_id))
		var flow: Control = Control.new()
		flow.set_script(load("res://scripts/ui/card_flow.gd"))
		card.add_child(flow)
		card.disabled = true
		card.modulate.a = 0.0
		_animate_card.call_deferred(card, float(cards.get_child_count() - 1) * 0.1, offer_id)
	panel.show()
	OceanUi.reveal(panel)

func _card_width() -> float:
	var slots: int = maxi(3, _choice_count)
	var padding: float = panel.get_theme_stylebox("panel").get_minimum_size().x
	# 容器会向上取整最小宽度；先按像素取整，避免四张半像素卡把面板反撑宽。
	var scroll_margin: float = 18.0 if is_instance_valid(_choice_scroll) else 0.0
	return floorf(minf(reward_card_max_width, (panel.size.x - padding - scroll_margin - float(slots - 1) * cards.get_theme_constant("separation")) / float(slots)))

func _layout_choices_panel() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(reward_panel_max_size.x, viewport_size.x - 64.0), minf(reward_panel_max_size.y, viewport_size.y - 64.0))
	panel.position = (viewport_size - panel.size) * 0.5
	for card: Control in cards.get_children():
		card.custom_minimum_size.x = _card_width()

func _on_overlay_resized() -> void:
	if _showing_choices:
		_layout_choices_panel()
	elif is_instance_valid(result_body) and result_body.visible:
		_layout_result_panel()

func _animate_card(card: Button, delay: float, offer_id: int) -> void:
	if not _card_belongs_to_offer(card, offer_id):
		return
	if OceanUi.reduced_motion:
		card.modulate.a = 1.0
		card.scale = Vector2.ONE
		card.disabled = false
		_refresh_reroll_enabled()
		return
	# HBoxContainer掌管位置；只动画视觉缩放和透明度，避免改坐标干扰布局。
	card.scale = Vector2(0.97, 0.97)
	var entrance: Tween = card.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance.tween_interval(delay)
	entrance.tween_property(card, "modulate:a", 1.0, 0.28)
	entrance.parallel().tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entrance.tween_callback(func():
		if _card_belongs_to_offer(card, offer_id):
			card.disabled = false
			_refresh_reroll_enabled())

func _card_belongs_to_offer(card: Button, offer_id: int) -> bool:
	return is_inside_tree() and is_instance_valid(card) and not card.is_queued_for_deletion() and card.get_parent() == cards and _showing_choices and _current_offer_id == offer_id

func choices_ready(offer_id: int) -> bool:
	return _showing_choices and panel.visible and offer_id == _current_offer_id and cards.get_child_count() > 0 and cards.get_children().all(func(card): return not card.disabled)

func show_reroll(balance: int, price: int, remaining_count: int, available: bool) -> void:
	if not is_instance_valid(_choice_scroll):
		# 窄屏增加操作行时滚动完整卡片，保持正文和卡片点击范围，不缩掉规则。
		var content: VBoxContainer = $Overlay/Panel/Content
		var old_index: int = cards.get_index()
		content.remove_child(cards)
		_choice_scroll = ScrollContainer.new()
		_choice_scroll.name = "ChoiceScroll"
		_choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_choice_scroll.custom_minimum_size.y = 120.0
		_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_choice_scroll.follow_focus = true
		content.add_child(_choice_scroll)
		content.move_child(_choice_scroll, old_index)
		_choice_scroll.add_child(cards)
		cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for card: Control in cards.get_children(): card.custom_minimum_size.y = 420.0
	if is_instance_valid(_choice_scroll):
		_choice_scroll.show()
		_choice_scroll.scroll_vertical = 0
	_reroll_available = available
	reroll_status.text = "余额 %d币 · 重选余%d次\n轻点选择 · 长卡可上下滚动" % [balance, remaining_count]
	reroll_button.text = "重选 · %d币" % price if remaining_count > 0 else "重选已用完"
	reroll_row.show()
	_layout_choices_panel()
	_refresh_reroll_enabled()

func _refresh_reroll_enabled() -> void:
	if is_instance_valid(reroll_button):
		reroll_button.disabled = not _reroll_available or not choices_ready(_current_offer_id)

func show_result(won: bool, kills: int, longest: int) -> void:
	reroll_row.hide()
	if is_instance_valid(_choice_scroll): _choice_scroll.hide()
	_showing_choices = false
	clear_cards()
	cards.hide()
	title.text = "这局，打得漂亮！" if won else "先吃口饭，再来一次"
	summary.text = "R 快速重开 · 也可以返回主菜单"
	result_body.configure(won, kills, longest)
	result_body.show()
	result_actions.show()
	restart_button.show()
	home_button.visible = not menu_requested.get_connections().is_empty()
	panel.show()
	_layout_result_panel.call_deferred()
	OceanUi.reveal(panel)
	restart_button.grab_focus()

func _layout_result_panel() -> void:
	# 结算后的同帧Home可能已卸载场景；旧deferred布局不能再访问Viewport。
	if not is_inside_tree() or get_viewport() == null or not is_instance_valid(result_body) or _showing_choices or not result_body.visible:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.size.x = minf(760, viewport_size.x - 64)
	result_body.fit_width(panel.size.x - panel.get_theme_stylebox("panel").get_minimum_size().x)
	$Overlay/Panel/Content.update_minimum_size()
	panel.update_minimum_size()
	panel.size.y = panel.get_combined_minimum_size().y
	panel.position = (viewport_size - panel.size) * 0.5

func close() -> void:
	_current_offer_id = -1
	reroll_row.hide()
	if is_instance_valid(_choice_scroll): _choice_scroll.hide()
	_showing_choices = false
	clear_cards()
	result_body.hide()
	result_actions.hide()
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
		"heavy": return "主球额外撞伤 +%d → +%d\n低速仍不造成伤害" % [int(levels.get(id,0)),int(after.levels.get(id,0))]
		"echo": return "有效命中追加 1 点\n延迟 0.12 秒，不递归"
		"bowling": return "撞杀后余势波及最多2敌\n存活敌人短时投射 · 不传代"
		"explosion": return "每链一次爆破 · 伤害1\n1/2/3代半径80/96/112"
		"companion": return "外包 %d → %d / 3 个\n受撞后短时出击" % [current.companion_count(),after.companion_count()]
		"follow": return "待命跟随 关闭 → 开启\n出击结束后归队"
		"relay": return "2/3代直撞额外 +1/+2\n每球每链一次续力"
		"shrink": return "危险波范围 %.0f%% → %.0f%%\n实体尺寸保持不变" % [current.attack_radius_scale()*100,after.attack_radius_scale()*100]
		"pulse": return "每4战斗秒震退一次\n半径150 · 不直接伤害"
		"heal":
			var hp: Dictionary = health_snapshot()
			var before: int = int(hp.get("hp",0))
			var maximum: int = int(hp.get("max_hp",5))
			return "生命 %d → %d / %d\n本次恢复 %d" % [before,mini(maximum,before+2),maximum,mini(2,maximum-before)]
		"choices": return "后续成长\n3 选 1 → 4 选 1"
		"vigor": return "生命上限 %d → %d\n同时恢复 1 点生命" % [current.max_health(),after.max_health()]
	return ""
