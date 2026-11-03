extends Node2D
@export var travel: Vector2 = Vector2(0, 65)
@export_range(0.2, 60.0) var period: float = 6.0
@export var initial_phase: float = 0.0
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
	$Body.position = travel * sin(initial_phase + elapsed * TAU / maxf(0.2, period))
func reset_mechanism() -> void:
	elapsed = 0.0
	$Body.position = travel * sin(initial_phase)
