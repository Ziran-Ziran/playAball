class_name DemoEnemyView
extends Node2D
@export_range(1.0,1.5) var armor_value_gain: float = 1.2
@export_range(13.0,18.0) var warning_meter_radius: float = 15.0
## 默认敌人表现只读取玩法快照并消费表现事件，不参与伤害或物理判定。
var source: Node
var _state: Dictionary = {}
var _last_event: StringName = &""
var _event_left: float = 0.0
const CRATE_ART: Texture2D = preload("res://assets/roguelite/presentation/fragile_crate_v1.png")
const HEAVY_ART: Texture2D = preload("res://assets/roguelite/presentation/heavy_shell_v1.png")
const TURRET_ART: Texture2D = preload("res://assets/roguelite/presentation/turret_base_v1.png")
# 生图边缘存在少量近透明噪点；显式裁掉透明留白，避免数字遮住整个箱面。
const CRATE_REGION := Rect2(160,170,935,920)
const HEAVY_REGION := Rect2(36,56,1175,1172)
const TURRET_REGION := Rect2(36,113,1179,1018)

func material_for_kind(kind: int) -> Texture2D:
	match kind:
		DemoEnemy.Kind.FRAGILE: return CRATE_ART
		DemoEnemy.Kind.HEAVY: return HEAVY_ART
		DemoEnemy.Kind.TURRET: return TURRET_ART
	return null

func material_region_for_kind(kind: int) -> Rect2:
	var texture: Texture2D=material_for_kind(kind)
	if texture==null: return Rect2()
	var raw_region: Rect2=[CRATE_REGION,HEAVY_REGION,TURRET_REGION][kind]
	# 导出/新鲜导入会应用size_limit；原PNG裁切按UV换算到实际导入尺寸。
	var ratio: Vector2=texture.get_size()/Vector2(1254,1254)
	return Rect2(raw_region.position*ratio,raw_region.size*ratio)

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

func _on_presentation_event(event: StringName, payload: Dictionary) -> void:
	_last_event = event
	_event_left = 0.12
	if event == &"hurt" and int(payload.get("effective_damage", 0)) > 0:
		_spawn_float(&"damage", int(payload.effective_damage))
	elif event == &"died":
		_spawn_float(&"death", 0)

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
	if _state.is_empty():
		return
	var hp: int = int(_state.get("hp", 0))
	var kind: int = int(_state.get("kind", 0))
	var color: Color = tier_color_for_hp(hp)
	var hit_fraction: float = clampf(_event_left / 0.12, 0.0, 1.0) if _last_event == &"hurt" else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + hit_fraction * 0.08, 1.0 - hit_fraction * 0.07))
	var body_color: Color = color.lightened(0.25) if hit_fraction > 0.65 else color
	var armor_tint: Color = body_color.lightened(0.14)
	armor_tint.r*=armor_value_gain
	armor_tint.g*=armor_value_gain
	armor_tint.b*=armor_value_gain
	var aim_direction: Vector2 = _state.get("aim_direction", Vector2.RIGHT)
	match kind:
		DemoEnemy.Kind.FRAGILE:
			draw_texture_rect_region(material_for_kind(kind), Rect2(-21,-21,42,42), material_region_for_kind(kind), body_color.lightened(0.14))
		DemoEnemy.Kind.HEAVY:
			draw_texture_rect_region(material_for_kind(kind), Rect2(-31,-31,62,62), material_region_for_kind(kind), armor_tint)
		DemoEnemy.Kind.TURRET:
			draw_texture_rect_region(material_for_kind(kind), Rect2(-24,-25,48,48), material_region_for_kind(kind), armor_tint)
			draw_line(Vector2.ZERO, aim_direction * 33, color.lightened(0.2), 9)
	draw_set_transform(Vector2.ZERO)
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
	if warning_left > 0.0 and not attack_active:
		# 小环只表达真实剩余预警，不缩放范围圈、不改释放时机，数字最后绘制。
		var fraction: float=clampf(float(_state.get("warning_fraction",0.0)),0.0,1.0)
		var tint: Color=Color("ffb36c") if fraction>0.25 else Color("ff8b73")
		draw_arc(Vector2.ZERO,warning_meter_radius,0,TAU,32,Color(tint,0.25),1,true)
		draw_arc(Vector2.ZERO,warning_meter_radius,-PI/2,-PI/2+TAU*fraction,32,tint,2,true)
	draw_string(font, Vector2(-text_width * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff7df"))

func last_event() -> StringName:
	return _last_event
