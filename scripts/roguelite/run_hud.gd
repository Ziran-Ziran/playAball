extends CanvasLayer
signal upgrade_selected(id: String)
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

func show_choices(choices: Array) -> void:
	clear_cards()
	title.text = "清场！选择一个升级"
	summary.text = "战斗已暂停 · 选完继续下一波"
	restart_button.hide()
	for choice in choices:
		var card := Button.new()
		card.text = "%s\n%s" % [choice.title, choice.description]
		card.custom_minimum_size = Vector2(520, 68)
		card.pressed.connect(func(): upgrade_selected.emit(choice.id))
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
