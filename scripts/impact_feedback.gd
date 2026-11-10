extends Node2D
## 碰撞表现独立于物理；所有临时节点会自动释放。

@export var shake_amount: float = 5.0
@export var sound_enabled: bool = true
@export var shake_enabled: bool = true
@export var particle_gravity: Vector2 = Vector2(0, 450)
@export_range(0.0, 1.0) var volume: float = 1.0
@export_range(1, 16) var max_sound_voices: int = 8
var _rings: Array[Dictionary] = []
var _shake: float = 0.0
var _sound: AudioStreamWAV
var audio_director: Node
@onready var camera: Camera2D = $"../Camera2D"

func _ready() -> void:
	_sound = AudioStreamWAV.new()
	_sound.format = AudioStreamWAV.FORMAT_16_BITS
	_sound.mix_rate = 22050
	var samples := PackedByteArray()
	# 短促衰减正弦：原型占位音，后续可替换成导入的 wav/ogg。
	for index in 2205:
		var time: float = float(index) / 22050.0
		var envelope: float = pow(1.0 - float(index) / 2205.0, 3.0)
		var sample: int = int(sin(TAU * (150.0 * time + 30.0 * time * time)) * envelope * 18000)
		samples.append(sample & 255)
		samples.append((sample >> 8) & 255)
	_sound.data = samples

func play_impact(point: Vector2, strength: float) -> void:
	_burst(point, strength, true)

func play_contact(point: Vector2, strength: float) -> void:
	# 普通实体接触不冒充有效伤害：小火星、短环与有限震动。
	_burst(point, strength, false)

func play_relay(point: Vector2, generation: int) -> void:
	_append_ring({"point":point,"life":1.0,"intensity":0.4,"kind":&"relay","radius":18.0+mini(generation,3)*4.0})

func play_explosion(point: Vector2, radius: float) -> void:
	# 边界提示真实80半径；不使用实心闪光遮住攻击预警。
	_append_ring({"point":point,"life":1.0,"intensity":0.6,"kind":&"explosion","radius":radius})

func _append_ring(ring: Dictionary) -> void:
	_rings.append(ring)
	if _rings.size() > 64: _rings.pop_front()

func _burst(point: Vector2, strength: float, damaging: bool) -> void:
	var intensity: float = clampf(strength / 800.0, 0.12, 1.0)
	_append_ring({"point": point, "life": 1.0, "intensity": intensity if damaging else intensity*0.35, "kind":&"damage" if damaging else &"contact"})
	_shake = maxf(_shake, intensity * shake_amount * (1.0 if damaging else 0.16))
	# 声音由独立预算校验，不因粒子上限而吞掉有效撞击。
	if sound_enabled:
		if is_instance_valid(audio_director):
			audio_director.play_event(&"heavy" if strength >= 500.0 else &"light", intensity)
		else:
			play_sound(point, intensity, lerpf(1.5, 0.7, intensity))

	var particle_count: int = 0
	for child in get_children():
		if child is CPUParticles2D: particle_count += 1
	if particle_count >= 18: return
	var sparks := CPUParticles2D.new()
	sparks.position = point
	sparks.one_shot = true
	sparks.amount = int(4 + intensity * 8) if damaging else int(2 + intensity * 4)
	sparks.lifetime = 0.22 if damaging else 0.14
	sparks.explosiveness = 1.0
	sparks.direction = Vector2.UP
	sparks.spread = 150.0
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 75.0 + intensity * (130.0 if damaging else 45.0)
	sparks.gravity = particle_gravity
	sparks.color = Color("b9ffe1") if damaging else Color("749b99")
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.2 if damaging else 1.4
	add_child(sparks)
	sparks.finished.connect(sparks.queue_free)
	sparks.emitting = true

func play_cue(point: Vector2) -> void:
	# 食物消耗轻提示，不生成看起来像碰撞的粒子。
	if sound_enabled:
		if is_instance_valid(audio_director):
			audio_director.play_event(&"rice")
		else:
			play_sound(point, 0.35, 2.0)

func play_sound(point: Vector2, intensity: float, pitch: float) -> void:
	if volume <= 0.0:
		return
	var voices: int = 0
	for child in get_children():
		if child is AudioStreamPlayer2D:
			voices += 1
	if voices >= max_sound_voices:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = _sound
	player.position = to_local(point)
	player.volume_db = lerpf(-25.0, -10.0, intensity) + linear_to_db(maxf(0.0001, volume))
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func reset_feedback() -> void:
	# 浮字挂在本局根节点以跨越敌人删除；重开时也必须清除旧局残影。
	for visual in get_tree().get_nodes_in_group("demo_combat_floats"):
		if get_parent().is_ancestor_of(visual):
			visual.get_parent().remove_child(visual)
			visual.queue_free()
	if is_instance_valid(audio_director):
		audio_director.reset_audio()
	_rings.clear()
	_shake = 0.0
	camera.offset = Vector2.ZERO
	for child in get_children():
		if child is AudioStreamPlayer2D:
			child.stop()
		remove_child(child)
		child.queue_free()
	queue_redraw()

func _process(delta: float) -> void:
	for ring in _rings:
		ring.life -= delta * 3.5
	_rings = _rings.filter(func(ring: Dictionary) -> bool: return ring.life > 0.0)
	_shake = move_toward(_shake, 0.0, delta * 24.0)
	camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if shake_enabled else Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	for ring in _rings:
		var kind: StringName = ring.get("kind", &"damage")
		if kind == &"relay":
			var relay_radius: float = 9.0 + (1.0-ring.life)*float(ring.radius)
			for angle in [0.0,PI]:
				draw_arc(ring.point,relay_radius,angle,angle+PI*0.65,12,Color(0.45,1.0,0.85,ring.life),1.5,true)
			continue
		if kind == &"explosion":
			draw_arc(ring.point,float(ring.radius)*(0.5+0.5*(1.0-ring.life)),0,TAU,48,Color(1.0,0.75,0.38,ring.life*0.65),1.5,true)
			continue
		var radius: float = (1.0 - ring.life) * 55.0 * ring.intensity + 8.0
		if kind == &"damage": draw_circle(ring.point, radius, Color(0.4, 0.85, 1.0, ring.life * 0.07))
		draw_arc(ring.point, radius, 0, TAU, 32, Color(0.7, 0.95, 1.0, ring.life*(0.45 if kind==&"contact" else 0.8)), 1.0 if kind==&"contact" else 1.5, true)
