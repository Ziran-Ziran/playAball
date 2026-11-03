extends Node2D
@export_range(-1.0, 1.0) var angular_speed: float = 0.12
@export var initial_angle: float = 0.0
var elapsed: float = 0.0
var active: bool = true
func set_active(value: bool) -> void:
	active = value
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	reset_mechanism()
func _physics_process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	$Body.rotation = initial_angle + elapsed * clampf(angular_speed, -1.0, 1.0)
func reset_mechanism() -> void:
	elapsed = 0.0
	$Body.rotation = initial_angle
