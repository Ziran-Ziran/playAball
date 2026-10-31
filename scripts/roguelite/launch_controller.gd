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
var capacity: int = 1
var charges: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	advance(delta)

func advance(battle_delta: float) -> void:
	if blocked:
		return
	_sync_single_charge()
	if not aiming and remaining > 0.0:
		var elapsed: float = maxf(0.0, battle_delta)
		# 缺少多格时逐格恢复；一次长帧可结算多格，但接上瞄准后停止恢复。
		while remaining > 0.0 and elapsed >= remaining and not aiming:
			elapsed -= remaining
			remaining = 0.0
			finish_recharge()
		if remaining > 0.0 and not aiming:
			remaining = maxf(0.0, remaining - elapsed)
	_update_energy()

func _sync_single_charge() -> void:
	# 保留旧单发接口：测试/调试直接设置 remaining 时，它仍是可用性的权威来源。
	if capacity == 1:
		charges = 1 if remaining <= 0.0 else 0

func available() -> bool:
	return remaining <= 0.0 if capacity == 1 else charges > 0

func _update_energy() -> void:
	if is_instance_valid(player):
		player.energy_fraction = 1.0 if available() else clampf(1.0 - remaining / maxf(cooldown, 0.001), 0.0, 1.0)

func set_capacity(value: int) -> void:
	_sync_single_charge()
	var new_capacity: int = clampi(value, 1, 2)
	# 升级只授予新槽位；重复应用同一个构筑不会重新填弹。
	charges = mini(new_capacity, charges + maxi(0, new_capacity - capacity))
	capacity = new_capacity
	if charges == capacity:
		remaining = 0.0
	elif remaining <= 0.0:
		remaining = maxf(cooldown, 0.001)
	_update_energy()

func finish_recharge() -> void:
	charges = mini(capacity, charges + 1)
	remaining = maxf(cooldown, 0.001) if charges < capacity else 0.0
	recharged.emit()
	if input_held:
		var last_pointer: Vector2 = pointer
		begin(anchor)
		pointer = last_pointer

func refund_cooldown(seconds: float) -> void:
	if seconds <= 0.0 or remaining <= 0.0:
		return
	_sync_single_charge()
	remaining = maxf(0.0, remaining - seconds)
	if remaining == 0.0:
		finish_recharge()
	_update_energy()

func begin(point: Vector2) -> bool:
	_sync_single_charge()
	if blocked or aiming or not available():
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
	if available():
		begin(point)

func release(point: Vector2) -> bool:
	if not aiming:
		cancel()
		return false
	var drag: Vector2 = (anchor - point).limit_length(player.max_drag)
	cancel()
	_sync_single_charge()
	if blocked or not available() or not player.launch(drag, shots + 1):
		return false
	shots += 1
	charges -= 1
	if remaining <= 0.0:
		remaining = maxf(cooldown, 0.001)
	_update_energy()
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
	capacity = 1
	charges = 1
	shots = 0
	blocked = false
	_update_energy()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel()
