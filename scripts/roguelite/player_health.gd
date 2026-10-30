class_name DemoHealth
extends Node
## 同一玩家共用受伤无敌时间，多个危险来源不会在一帧扣空生命。
signal changed(hp: int)
signal died
@export var max_hp: int = 5
@export var invulnerability: float = 0.8
var hp: int = 5
var invulnerability_left: float = 0.0

func _ready() -> void:
	reset_health()

func _physics_process(delta: float) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)

func hurt(amount: int = 1) -> bool:
	if hp <= 0 or amount <= 0 or invulnerability_left > 0.0:
		return false
	hp = maxi(0, hp - amount)
	invulnerability_left = invulnerability
	changed.emit(hp)
	if hp == 0:
		died.emit()
	return true

func reset_health() -> void:
	hp = maxi(1, max_hp)
	invulnerability_left = 0.0
	changed.emit(hp)
