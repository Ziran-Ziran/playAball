class_name DemoEnemyView
extends Node2D
## 默认敌人表现只读取玩法快照并消费表现事件，不参与伤害或物理判定。
var source: Node
var _state: Dictionary = {}
var _last_event: StringName = &""
var _event_left: float = 0.0

func bind_source(actor: Node) -> void:
	if is_instance_valid(source):
		if source.presentation_changed.is_connected(_on_presentation_changed):
			source.presentation_changed.disconnect(_on_presentation_changed)
		if source.presentation_event.is_connected(_on_presentation_event):
			source.presentation_event.disconnect(_on_presentation_event)
	source = actor
	if is_instance_valid(source):
		if source.has_signal("presentation_changed"):
			source.presentation_changed.connect(_on_presentation_changed)
		if source.has_signal("presentation_event"):
			source.presentation_event.connect(_on_presentation_event)
		_state = source.call("presentation_snapshot")
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(source) and source.has_method("presentation_snapshot"):
		_state = source.call("presentation_snapshot")
	_event_left = maxf(0.0, _event_left - delta)
	queue_redraw()

func _on_presentation_changed(snapshot: Dictionary) -> void:
	_state = snapshot
	queue_redraw()

func _on_presentation_event(event: StringName, _payload: Dictionary) -> void:
	_last_event = event
	_event_left = 0.12

func tier_color_for_hp(hp: int) -> Color:
	# 颜色只是表现映射；准确生命仍显示数字并来自快照。
	if hp <= 1:
		return Color("62d6ac")
	if hp <= 3:
		return Color("f3c568")
	return Color("d78ad8")

func _draw() -> void:
	if _state.is_empty():
		return
	var hp: int = int(_state.get("hp", 0))
	var kind: int = int(_state.get("kind", 0))
	var color: Color = tier_color_for_hp(hp)
	var aim_direction: Vector2 = _state.get("aim_direction", Vector2.RIGHT)
	match kind:
		DemoEnemy.Kind.FRAGILE:
			draw_rect(Rect2(-19, -19, 38, 38), color)
			draw_line(Vector2(-14, -14), Vector2(14, 14), Color("203139"), 3)
		DemoEnemy.Kind.HEAVY:
			draw_circle(Vector2.ZERO, 30, color)
			draw_rect(Rect2(-23, -11, 46, 22), color.darkened(0.4))
		DemoEnemy.Kind.TURRET:
			draw_colored_polygon(PackedVector2Array([Vector2(-22, 20), Vector2(22, 20), Vector2(0, -25)]), color)
			draw_line(Vector2.ZERO, aim_direction * 33, color.lightened(0.2), 9)
	var warning_left: float = float(_state.get("warning_left", 0.0))
	var attack_active: bool = bool(_state.get("attack_active", false))
	if warning_left > 0.0 or attack_active:
		var radius: float = float(_state.get("pulse_radius", 90.0)) if kind == DemoEnemy.Kind.FRAGILE else 40.0
		draw_circle(Vector2.ZERO, radius, Color(1, 0.35, 0.25, 0.22) if attack_active else Color("ffac64"), attack_active, -1.0 if attack_active else 2.0, true)
		if kind != DemoEnemy.Kind.FRAGILE:
			draw_line(aim_direction * 40, aim_direction * 115, Color("ffac64"), 3)
	var font: Font = ThemeDB.fallback_font
	var text: String = str(hp)
	var font_size: int = 18
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_circle(Vector2.ZERO, maxf(11.0, text_width * 0.5 + 3.0), Color("17232d"))
	draw_string(font, Vector2(-text_width * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff7df"))

func last_event() -> StringName:
	return _last_event
