extends Node2D
## 碰撞表现独立于物理；所有临时节点会自动释放。

@export var shake_amount: float = 5.0
@export var sound_enabled: bool = true
@export var shake_enabled: bool = true
@export var particle_gravity: Vector2 = Vector2(0, 450)
var _rings: Array[Dictionary] = []
var _shake: float = 0.0
var _sound: AudioStreamWAV
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
	var intensity: float = clampf(strength / 800.0, 0.12, 1.0)
	_rings.append({"point": point, "life": 1.0, "intensity": intensity})
	_shake = maxf(_shake, intensity * shake_amount)
	var sparks := CPUParticles2D.new()
	sparks.position = point
	sparks.one_shot = true
	sparks.amount = int(6 + intensity * 18)
	sparks.lifetime = 0.32
	sparks.explosiveness = 1.0
	sparks.direction = Vector2.UP
	sparks.spread = 150.0
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 100.0 + intensity * 230.0
	sparks.gravity = particle_gravity
	sparks.color = Color("a4efff")
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 3.5
	add_child(sparks)
	sparks.finished.connect(sparks.queue_free)
	sparks.emitting = true
	if sound_enabled:
		var player := AudioStreamPlayer2D.new()
		player.stream = _sound
		player.position = point
		player.volume_db = lerpf(-25.0, -10.0, intensity)
		player.pitch_scale = lerpf(1.5, 0.7, intensity)
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()

func reset_feedback() -> void:
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
		var radius: float = (1.0 - ring.life) * 55.0 * ring.intensity + 8.0
		draw_circle(ring.point, radius, Color(0.4, 0.85, 1.0, ring.life * 0.12))
		draw_arc(ring.point, radius, 0, TAU, 40, Color(0.7, 0.95, 1.0, ring.life), 2.0, true)
