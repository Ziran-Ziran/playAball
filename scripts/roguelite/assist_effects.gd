class_name DemoAssistEffects
extends Node
signal pulsed(point: Vector2, radius: float)
## 护身震退只有有限冲量，不调用战斗解析或改变攻击归属。
@export var interval: float = 4.0
@export var radius: float = 150.0
@export var impulse_speed: float = 250.0
var player: DemoPlayer
var enemies: Node2D
var build: DemoBuild
var elapsed: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func reset_effects() -> void:
	elapsed = 0.0

func _physics_process(delta: float) -> void:
	if build == null or not build.has_upgrade("pulse"):
		elapsed = 0.0
		return
	if not is_instance_valid(player) or player.reset_pending or not is_instance_valid(enemies):
		return
	elapsed += delta
	if elapsed < maxf(0.1, interval):
		return
	elapsed = fmod(elapsed, maxf(0.1, interval))
	var affected: bool = false
	for enemy in enemies.get_children():
		if not (enemy is DemoEnemy or enemy is DemoBoss) or enemy.dead or enemy.is_queued_for_deletion():
			continue
		var offset: Vector2 = enemy.global_position - player.global_position
		if offset.length() > radius:
			continue
		var direction: Vector2 = offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
		enemy.apply_central_impulse(direction * minf(maxf(0.0, impulse_speed), 250.0) * enemy.mass)
		affected = true
	if affected:
		pulsed.emit(player.global_position, radius)

func _exit_tree() -> void:
	reset_effects()
