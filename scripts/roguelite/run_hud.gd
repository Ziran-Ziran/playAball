extends CanvasLayer
signal upgrade_selected(id: String, offer_id: int)
signal restart_requested
@onready var panel: PanelContainer = $Overlay/Panel
@onready var title: Label = $Overlay/Panel/Content/Title
@onready var summary: Label = $Overlay/Panel/Content/Summary
@onready var cards: VBoxContainer = $Overlay/Panel/Content/Cards
@onready var restart_button: Button = $Overlay/Panel/Content/Restart
@onready var health_bar: ProgressBar = $Overlay/PlayerPanel/Content/HealthBar
@onready var health_value: Label = $Overlay/PlayerPanel/Content/Heading/HealthValue
@onready var health_state: Label = $Overlay/PlayerPanel/Content/HealthState
@export var health_feedback_seconds: float = 0.7
var _health: DemoHealth
var _previous_health: int = -1
var _feedback_left: float = 0.0
var _feedback_text: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(func(): restart_requested.emit())
	panel.hide()

func bind_health(health: DemoHealth) -> void:
	# 血量只读取生命组件；换局或更换组件时不能留下旧信号连接。
	if is_instance_valid(_health) and _health.changed.is_connected(_on_health_changed):
		_health.changed.disconnect(_on_health_changed)
	_health = health
	_previous_health = -1
	_feedback_left = 0.0
	if is_instance_valid(_health):
		_health.changed.connect(_on_health_changed)
		_on_health_changed(_health.hp)

func _on_health_changed(hp: int) -> void:
	_feedback_text = ""
	_feedback_left = 0.0
	if _previous_health > 0 and hp != _previous_health:
		_feedback_text = "受伤 -%d" % (_previous_health - hp) if hp < _previous_health else "恢复 +%d" % (hp - _previous_health)
		_feedback_left = health_feedback_seconds
	_previous_health = hp
	_refresh_health()

func _process(delta: float) -> void:
	if not get_tree().paused:
		_feedback_left = maxf(0.0, _feedback_left - delta)
	# 无敌倒计时没有 changed 信号，每帧只读，HUD 不推进游戏生命计时。
	_refresh_health()

func _refresh_health() -> void:
	if not is_instance_valid(_health):
		return
	health_bar.max_value = maxi(1, _health.max_hp)
	health_bar.value = _health.hp
	health_value.text = "%d / %d" % [_health.hp, _health.max_hp]
	var low: bool = _health.hp > 0 and _health.hp * 3 <= _health.max_hp
	health_bar.modulate = Color("ffad90") if low else Color.WHITE
	if _health.hp <= 0:
		health_state.text = "已倒下 · R 重新开局"
		health_state.modulate = Color("ffad90")
	elif _health.invulnerability_left > 0.0:
		health_state.text = ("%s · " % _feedback_text if _feedback_left > 0.0 else "") + "无敌保护"
		health_state.modulate = Color("ffcfba")
	elif _feedback_left > 0.0:
		health_state.text = _feedback_text
		health_state.modulate = Color("bce9da") if _feedback_text.begins_with("恢复") else Color("ffcfba")
	else:
		health_state.text = "生命偏低 · 留意危险预警" if low else "生命充足" if _health.hp == _health.max_hp else "留意危险预警"
		health_state.modulate = Color("ffcfba") if low else Color("a9bec4")

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
