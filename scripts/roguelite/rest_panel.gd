extends CanvasLayer
signal action_selected(action: String, revision: int)
var revision: int = 0
@onready var panel: PanelContainer = $Backdrop/Panel
@onready var heading: Label = $Backdrop/Panel/Content/Heading
@onready var detail: Label = $Backdrop/Panel/Content/Detail
@onready var actions: VBoxContainer = $Backdrop/Panel/Content/Actions
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
func show_rest(title: String, description: String, offers: Array, quote: int) -> void:
	revision = quote
	heading.text = title
	detail.text = description
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	for offer in offers:
		var button := Button.new()
		button.text = offer.text
		button.disabled = not offer.enabled
		button.custom_minimum_size = Vector2(0, 48)
		var id: String = offer.id
		var captured: int = revision
		button.pressed.connect(func(): action_selected.emit(id, captured))
		actions.add_child(button)
	show()
