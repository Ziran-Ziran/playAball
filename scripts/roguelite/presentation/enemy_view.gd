class_name DemoEnemyView
extends Node2D
@export_range(13.0,18.0) var warning_meter_radius: float = 15.0
## 默认敌人表现只读取玩法快照并消费表现事件，不参与伤害或物理判定。
@export var idle_period: float = 2.6
var _idle_clock: float = 0.0
var source: Node
var _state: Dictionary = {}
var _last_event: StringName = &""
var _event_left: float = 0.0
func material_for_kind(_kind: int) -> Texture2D:
	var id: String = DemoBallArt.enemy_id(int(_state.get("max_hp",1)))
	return DemoBallArt.texture_for(id)

func material_region_for_kind(kind: int) -> Rect2:
	return DemoBallArt.region_for(material_for_kind(kind))

func bind_source(actor: Node) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
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
	_idle_clock += delta
	if is_instance_valid(source) and source.has_method("presentation_snapshot"):
		_state = source.call("presentation_snapshot")
	_event_left = maxf(0.0, _event_left - delta)
	queue_redraw()

func _on_presentation_changed(snapshot: Dictionary) -> void:
	_state = snapshot
	queue_redraw()

func _on_presentation_event(event: StringName, payload: Dictionary) -> void:
	_last_event = event
	_event_left = 0.12
	if event == &"hurt" and int(payload.get("effective_damage", 0)) > 0:
		_spawn_float(&"damage", int(payload.effective_damage))
	elif event == &"died":
		_spawn_float(&"death", 0)
		_spawn_burst()

func _spawn_burst() -> void:
	if not is_instance_valid(source) or not source.is_inside_tree() or get_tree().get_nodes_in_group("virus_bursts").size() >= 12:
		return
	var holder: Node = source.get_parent()
	while holder.get_parent() is Node2D:
		holder = holder.get_parent()
	var visual := Node2D.new()
	visual.set_script(load("res://scripts/roguelite/presentation/virus_burst.gd"))
	visual.art_id = DemoBallArt.enemy_id(int(_state.get("max_hp",1)))
	visual.tint = tier_color_for_hp(int(_state.get("max_hp",1)))
	visual.position = holder.to_local(source.global_position) if holder is Node2D else source.global_position
	holder.add_child(visual)

func _spawn_float(effect: StringName, amount: int) -> void:
	if not is_instance_valid(source) or not source.is_inside_tree() or get_tree().get_nodes_in_group("demo_combat_floats").size() >= 20:
		return
	var holder: Node = source.get_parent()
	while holder.get_parent() is Node2D:
		holder = holder.get_parent()
	var point: Vector2 = source.global_position
	var visual := Node2D.new()
	visual.set_script(load("res://scripts/roguelite/presentation/combat_float.gd"))
	visual.effect = effect
	visual.amount = amount
	visual.tint = Color("fff3bb") if amount >= 3 else Color("c6ffe0")
	visual.position = holder.to_local(point) if holder is Node2D else point
	holder.add_child(visual)

func tier_color_for_hp(hp: int) -> Color:
	# 颜色只是表现映射；准确生命仍显示数字并来自快照。
	if hp <= 1:
		return Color("62d6ac")
	if hp <= 3:
		return Color("f3c568")
	return Color("d78ad8")

func _draw() -> void:
	if _state.is_empty() or bool(_state.get("dead",false)):
		return
	var hp: int = int(_state.get("hp", 0))
	var kind: int = int(_state.get("kind", 0))
	var color: Color = tier_color_for_hp(hp)
	var hit_fraction: float = clampf(_event_left / 0.12, 0.0, 1.0) if _last_event == &"hurt" else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + hit_fraction * 0.12-sin(_idle_clock*TAU/idle_period)*0.045, 1.0 - hit_fraction * 0.10+sin(_idle_clock*TAU/idle_period)*0.045))
	var aim_direction: Vector2 = _state.get("aim_direction", Vector2.RIGHT)
	var radius: float = [20.0,31.0,24.0][kind]
	var texture: Texture2D = material_for_kind(kind)
	if _last_event==&"hurt" and _event_left>0.0:
		texture = DemoBallArt.animation_frame(DemoBallArt.enemy_id(int(_state.get("max_hp",1))),0 if _event_left>0.06 else 1)
	draw_texture_rect_region(texture,DemoBallArt.rect_for(texture,radius*2.0+2.0),DemoBallArt.region_for(texture),Color(1.15,1.15,1.15) if hit_fraction > 0.65 else Color.WHITE)
	# 角色身份仍可分辨：重型有铆钉，炮台有真实朝向喷口；不改变碰撞。
	if kind == DemoEnemy.Kind.HEAVY:
		for side: float in [-1.0,1.0]:
			draw_circle(Vector2(side*radius*0.62,radius*0.4),2.0,Color("f5d9a5"))
	elif kind == DemoEnemy.Kind.TURRET:
		draw_line(aim_direction*radius*0.7,aim_direction*(radius+8.0),Color("273348"),6.0,true)
		draw_circle(aim_direction*(radius+8.0),3.0,color)
	draw_set_transform(Vector2.ZERO)
	draw_arc(Vector2.ZERO,radius+1.0,0,TAU,36,Color(color,0.7),1.0,true)
	var warning_left: float = float(_state.get("warning_left", 0.0))
	var attack_active: bool = bool(_state.get("attack_active", false))
	if warning_left > 0.0 or attack_active:
		var warning_radius: float = float(_state.get("pulse_radius", 90.0)) if kind == DemoEnemy.Kind.FRAGILE else 40.0
		draw_circle(Vector2.ZERO, warning_radius, Color(1, 0.35, 0.25, 0.22) if attack_active else Color("ffac64"), attack_active, -1.0 if attack_active else 2.0, true)
		if kind != DemoEnemy.Kind.FRAGILE:
			draw_line(aim_direction * 40, aim_direction * 115, Color("ffac64"), 3)
	var font: Font = ThemeDB.fallback_font
	var text: String = str(hp)
	var font_size: int = 18
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var badge := Vector2(0.0,radius+7.0)
	draw_circle(badge, maxf(10.0, text_width * 0.5 + 3.0), Color("17232d"))
	if warning_left > 0.0 and not attack_active:
		# 小环只表达真实剩余预警，不缩放范围圈、不改释放时机，数字最后绘制。
		var fraction: float=clampf(float(_state.get("warning_fraction",0.0)),0.0,1.0)
		var tint: Color=Color("ffb36c") if fraction>0.25 else Color("ff8b73")
		draw_arc(Vector2.ZERO,warning_meter_radius,0,TAU,32,Color(tint,0.25),1,true)
		draw_arc(Vector2.ZERO,warning_meter_radius,-PI/2,-PI/2+TAU*fraction,32,tint,2,true)
	draw_string(font, badge+Vector2(-text_width * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff7df"))

func last_event() -> StringName:
	return _last_event
