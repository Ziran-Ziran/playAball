extends "res://scripts/roguelite/run_arena.gd"
## 策划EXE专用入口；正式run场景不加载调参组件。
@onready var live_tuning: Node = $LiveTuning
@onready var tuning_panel: CanvasLayer = $TuningPanel

func _ready() -> void:
	super._ready()
	live_tuning.setup(self, tuning_panel)
	live_tuning.set_panel_open(true)
	if DisplayServer.get_name() != "headless":
		get_window().title = "玩个球 · 完整引擎调参 · F1"

func over_controls(point: Vector2) -> bool:
	return (is_instance_valid(tuning_panel) and tuning_panel.covers_point(point)) or super.over_controls(point)

func set_paused(value: bool) -> void:
	if is_instance_valid(live_tuning):
		live_tuning.relinquish_pause()
	super.set_paused(value)

func _input(event: InputEvent) -> void:
	var focus: Control = get_viewport().gui_get_focus_owner()
	if tuning_panel.is_open() and event is InputEventKey and (focus is LineEdit or focus is TextEdit):
		# 搜索/编辑中的R属于文字，不应在结算态偷偷重开游戏。
		return
	super._input(event)
