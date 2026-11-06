extends CanvasLayer
signal upgrade_selected(id: String, offer_id: int)
signal restart_requested
signal menu_requested
const UPGRADE_CARD: PackedScene = preload("res://scenes/roguelite/presentation/upgrade_card.tscn")
var card_art: DemoCardArtLibrary = DemoCardArtLibrary.new()
var _showing_choices: bool = false
var _choice_count: int = 0
@export var reward_panel_max_size: Vector2 = Vector2(1184.0, 640.0)
@export_range(240.0, 380.0, 1.0) var reward_card_max_width: float = 350.0
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
	preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").apply($Overlay)
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
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cards.add_child(card)
		card.configure(choice, next_level, benefit_preview(choice.id, levels), card_art.copy_for(choice.id), card_art.texture_for(choice.id, next_level))
		card.set_meta("art_path", card_art.path_for(choice.id, next_level))
		card.pressed.connect(func(): upgrade_selected.emit(choice.id, offer_id))
		var flow: Control = Control.new()
		flow.set_script(load("res://scripts/ui/card_flow.gd"))
		card.add_child(flow)
		card.disabled = true
		card.modulate.a = 0.0
		_animate_card.call_deferred(card, float(cards.get_child_count() - 1) * 0.1)
	panel.show()

func _card_width() -> float:
	var slots: int = maxi(3, _choice_count)
	return minf(reward_card_max_width, (panel.size.x - 48.0 - float(slots - 1) * cards.get_theme_constant("separation")) / float(slots))

func _layout_choices_panel() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(reward_panel_max_size.x, viewport_size.x - 64.0), minf(reward_panel_max_size.y, viewport_size.y - 64.0))
	panel.position = (viewport_size - panel.size) * 0.5
	for card: Control in cards.get_children():
		card.custom_minimum_size.x = _card_width()

func _on_overlay_resized() -> void:
	if _showing_choices:
		_layout_choices_panel()

func _animate_card(card: Button, delay: float) -> void:
	if not is_instance_valid(card):
		return
	# HBoxContainer掌管位置；只动画视觉缩放和透明度，避免改坐标干扰布局。
	card.scale = Vector2(0.97, 0.97)
	var entrance: Tween = card.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance.tween_interval(delay)
	entrance.tween_property(card, "modulate:a", 1.0, 0.42)
	entrance.parallel().tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_callback(func(): card.disabled = false)

func show_result(won: bool, kills: int, longest: int) -> void:
	_showing_choices = false
	clear_cards()
	cards.hide()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(580,viewport_size.x-64), 310)
	panel.position = (viewport_size-panel.size)*0.5
	title.text = "拆迁完成！" if won else "这次先到这里"
	summary.text = "击破 %d · 最长接力 %d\nR 或按钮重新开局" % [kills, longest]
	restart_button.show()
	home_button.visible = not menu_requested.get_connections().is_empty()
	panel.show()
	restart_button.grab_focus()

func close() -> void:
	_showing_choices = false
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
		"heavy": return "主球额外撞伤 +%d → +%d\n低速仍不造成伤害" % [int(levels.get(id,0)),int(after.levels.get(id,0))]
		"echo": return "有效命中追加 1 点\n延迟 0.12 秒，不递归"
		"bowling": return "受撞敌人可再撞伤2名敌人\n0.6秒内 · 不传代"
		"explosion": return "伙伴首击触发爆炸\n半径 80 · 伤害 1"
		"companion": return "外包 %d → %d / 3 个\n受撞后短时出击" % [current.companion_count(),after.companion_count()]
		"follow": return "待命跟随 关闭 → 开启\n出击结束后归队"
		"relay": return "基础传能 → 强化接力\n每球每链只强化一次"
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
