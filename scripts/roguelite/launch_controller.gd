class_name DemoLaunch
extends Node
signal fired(chain: int)
signal recharged
@export var cooldown: float = 2.2
var player: DemoPlayer
var remaining: float = 0.0
var aiming: bool = false
var input_held: bool = false
var blocked: bool = false
var anchor: Vector2
var pointer: Vector2
var shots: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	advance(delta)

func advance(battle_delta: float) -> void:
	if blocked:
		return
	if not aiming and remaining > 0.0:
		remaining = maxf(0.0, remaining - battle_delta)
		if remaining == 0.0:
			finish_recharge()
	if is_instance_valid(player):
		player.energy_fraction = 1.0 - remaining / cooldown

func finish_recharge() -> void:
	recharged.emit()
	if input_held:
		var last_pointer: Vector2 = pointer
		begin(anchor)
		pointer = last_pointer

func refund_cooldown(seconds: float) -> void:
	if seconds <= 0.0 or remaining <= 0.0:
		return
	remaining = maxf(0.0, remaining - seconds)
	if remaining == 0.0:
		finish_recharge()
	if is_instance_valid(player):
		player.energy_fraction = 1.0 - remaining / cooldown

func begin(point: Vector2) -> bool:
	if blocked or aiming or remaining > 0.0:
		return false
	anchor = point
	pointer = point
	aiming = true
	input_held = true
	return true

func request_aim(point: Vector2) -> void:
	if blocked or input_held:
		return
	# 按下不会提前扣能或冻结战斗；保持按住时，就绪帧再进入瞄准。
	input_held = true
	anchor = point
	pointer = point
	if remaining == 0.0:
		begin(point)

func release(point: Vector2) -> bool:
	if not aiming:
		cancel()
		return false
	var drag: Vector2 = (anchor - point).limit_length(player.max_drag)
	cancel()
	if blocked or not player.launch(drag, shots + 1):
		return false
	shots += 1
	remaining = cooldown
	fired.emit(shots)
	return true

func cancel() -> void:
	aiming = false
	input_held = false

func set_blocked(value: bool) -> void:
	blocked = value
	cancel()

func reset_launch() -> void:
	cancel()
	remaining = 0.0
	shots = 0
	blocked = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel()
