extends Node2D
## 保留核心+四模块轮廓，读取只读状态，阶段预警绝不参与伤害判定。
const ARMOR_ART: Texture2D=preload("res://assets/roguelite/presentation/heavy_shell_v1.png")
@export_range(0.8,1.5) var armor_value_gain: float=1.2
var source: Node2D
var _state: Dictionary = {}
var _flash: float = 0.0
var module_flash_left: PackedFloat32Array=PackedFloat32Array([0.0,0.0,0.0,0.0])
var module_break_left: PackedFloat32Array=PackedFloat32Array([0.0,0.0,0.0,0.0])
func _ready() -> void:
	source = get_parent()
	source.presentation_event.connect(_on_event)
	source.died.connect(func(_boss): $Status.hide())
func _on_event(event: StringName,payload: Dictionary) -> void:
	if event==&"core_hurt":
		_flash=0.09
	elif event==&"module_hurt":
		var index: int=int(payload.get("index",-1))
		if index<0 or index>=4:return
		module_flash_left[index]=0.1
		# 伤害已结算，读取最新真实模块生命；旧绘制快照可能尚未刷新。
		if int(source.presentation_snapshot().modules[index].hp)<=0:module_break_left[index]=0.16
func _process(delta: float) -> void:
	_state = source.presentation_snapshot()
	_flash = maxf(0.0,_flash-delta)
	for index in 4:
		module_flash_left[index]=maxf(0.0,module_flash_left[index]-delta)
		module_break_left[index]=maxf(0.0,module_break_left[index]-delta)
	$Status.visible = not bool(_state.dead)
	var phase: int=int(_state.phase)
	var title: String=["蓄力","冲撞","破防","恢复"][phase]
	if phase in [0,2]:
		# 只显示精确可预期的预警/破防窗口，向上取十分位，避免仍有效时显示0.0。
		var remaining: float=maxf(0.1,ceilf(maxf(0.0,float(_state.phase_left))*10.0)/10.0)
		title+=" · %.1f秒"%remaining
	$Status/Label.text = "首领 · %s\n%d / %d"%[title,int(_state.hp),int(_state.max_hp)]
	$Status/Label.modulate = Color("ffe0aa") if int(_state.phase)==2 else Color("d1e5e2")
	$Status/Life.max_value = int(_state.max_hp)
	$Status/Life.value = int(_state.hp)
	queue_redraw()
func snapshot() -> Dictionary:
	return _state.duplicate(true)
func armor_material_region() -> Rect2:
	# 与普通重型共用中性装甲；裁切按实际导入尺寸换算，不依赖源PNG缓存。
	var ratio: Vector2=ARMOR_ART.get_size()/Vector2(1254,1254)
	return Rect2(Vector2(36,56)*ratio,Vector2(1175,1172)*ratio)
func _armor(point: Vector2,diameter: float,tint: Color) -> void:
	var value:=Color(tint.r*armor_value_gain,tint.g*armor_value_gain,tint.b*armor_value_gain,tint.a)
	draw_texture_rect_region(ARMOR_ART,Rect2(point-Vector2.ONE*diameter*0.5,Vector2.ONE*diameter),armor_material_region(),value)
func _draw() -> void:
	if _state.is_empty() or bool(_state.dead): return
	var phase: int = _state.phase
	var exposed: bool = phase == 2
	var core_color: Color = Color("e5b55b") if exposed else Color("35545e")
	if _flash > 0.0: core_color = core_color.lightened(0.22)
	draw_circle(Vector2.ZERO,43,Color("152b34"))
	_armor(Vector2.ZERO,84,core_color.lightened(0.22))
	draw_arc(Vector2.ZERO,42,0,TAU,48,Color("f6d786") if exposed else Color("80afb6"),2,true)
	for i in 8:
		var angle: float = TAU*i/8.0
		draw_line(Vector2.from_angle(angle)*37,Vector2.from_angle(angle)*42,Color("93bcc0"),2,true)
	# 破防环保留明确的金色阶段提示，纹理只提供材质层次。
	if exposed: draw_arc(Vector2.ZERO,27,0,TAU,40,Color("fff0c9"),2,true)
	for index in _state.modules.size():
		var module: Dictionary=_state.modules[index]
		var point: Vector2 = module.point
		if int(module.hp)<=0:
			if module_break_left[index]>0.0:
				var remaining: float=module_break_left[index]/0.16
				draw_arc(point,17.0+(1.0-remaining)*6.0,-PI*0.85,PI*0.85,24,Color(1.0,0.84,0.6,remaining*0.7),1.5,true)
			continue
		draw_line(point.normalized()*40,point,Color("759da5"),4,true)
		draw_circle(point,17,Color("263d46"))
		var tint: Color=Color("ba8e66").lightened(0.45) if module_flash_left[index]>0.0 else Color("ba8e66")
		_armor(point,32,tint)
		draw_arc(point,17,-PI/2,TAU*float(module.hp)/maxi(1,int(module.max_hp))-PI/2,24,Color("ffe0aa"),2,true)
	var direction: Vector2 = _state.charge_direction
	if phase == 0:
		draw_line(direction*50,direction*280,Color("ffbc77"),3,true)
		draw_circle(direction*290,12,Color("ffbc77"),false,3)
	if bool(_state.wave_active):
		var center: Vector2 = _state.wave_center
		var safe_direction: Vector2 = _state.safe_direction
		var half_gap: float = _state.wave_half_gap
		var warning: bool = float(_state.wave_warning_left) > 0.0
		draw_arc(center,float(_state.wave_radius),safe_direction.angle()+half_gap,safe_direction.angle()+TAU-half_gap,64,Color("ffb978") if warning else Color("ff586a"),2 if warning else 12,true)
		draw_line(center,center+safe_direction*120,Color("80e2c0"),2,true)
