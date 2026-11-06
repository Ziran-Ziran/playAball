extends CanvasLayer
signal action_selected(action: String, revision: int)
var revision: int = 0
@onready var panel: PanelContainer = $Backdrop/Panel
@onready var heading: Label = $Backdrop/Panel/Content/Heading
@onready var detail: Label = $Backdrop/Panel/Content/Detail
@onready var actions: VBoxContainer = $Backdrop/Panel/Content/Actions
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").apply($Backdrop)
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
	for offer in offers:
		var button := Button.new()
		button.text = offer.text
		button.disabled = not offer.enabled
		button.custom_minimum_size = Vector2(0, 58)
		var id: String = offer.id
		var captured: int = revision
		button.pressed.connect(func(): action_selected.emit(id, captured))
		actions.add_child(button)
	show()
	_fit_panel.call_deferred()
	for button: Button in actions.get_children():
		if not button.disabled:
			preload("res://scripts/roguelite/presentation/sea_ui_theme.gd").primary(button)
			button.grab_focus()
			break

func _fit_panel() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(minf(640, viewport_size.x - 64), panel.get_combined_minimum_size().y)
	panel.position = (viewport_size - panel.size) * 0.5
