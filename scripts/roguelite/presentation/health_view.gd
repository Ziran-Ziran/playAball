class_name DemoHealthView
extends PanelContainer
## 可替换生命面板：只读取 DemoHealth 的生命状态，不保存可扣血的第二份数据。
@onready var health_bar: ProgressBar = $Content/HealthBar
@onready var health_value: Label = $Content/Heading/HealthValue
@onready var health_state: Label = $Content/HealthState
@export var health_feedback_seconds: float = 0.7
var _health: DemoHealth
var _previous_health: int = -1
var _feedback_left: float = 0.0
var _feedback_text: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func bind_source(health: DemoHealth) -> void:
	# 换局或更换组件时断开旧信号，避免旧生命源继续刷新新面板。
	if is_instance_valid(_health) and _health.changed.is_connected(_on_health_changed):
		_health.changed.disconnect(_on_health_changed)
	_health = health
	_previous_health = -1
	_feedback_left = 0.0
	if is_instance_valid(_health):
		_health.changed.connect(_on_health_changed)
		_on_health_changed(_health.hp)

func _on_health_changed(hp: int) -> void:
	_feedback_text = ""
	_feedback_left = 0.0
	if _previous_health > 0 and hp != _previous_health:
		_feedback_text = "受伤 -%d" % (_previous_health - hp) if hp < _previous_health else "恢复 +%d" % (hp - _previous_health)
		_feedback_left = health_feedback_seconds
	_previous_health = hp
	_refresh_health()

func _process(delta: float) -> void:
	if not get_tree().paused:
		_feedback_left = maxf(0.0, _feedback_left - delta)
	# 无敌倒计时没有独立信号，这里只读刷新，不推进玩法计时。
	_refresh_health()

func _refresh_health() -> void:
	if not is_instance_valid(_health):
		return
	health_bar.max_value = maxi(1, _health.max_hp)
	health_bar.value = _health.hp
	health_value.text = "%d / %d" % [_health.hp, _health.max_hp]
	var low: bool = _health.hp > 0 and _health.hp * 3 <= _health.max_hp
	health_bar.modulate = Color("ffad90") if low else Color.WHITE
	if _health.hp <= 0:
		health_state.text = "已倒下 · R 重新开局"
		health_state.modulate = Color("ffad90")
	elif _health.invulnerability_left > 0.0:
		health_state.text = ("%s · " % _feedback_text if _feedback_left > 0.0 else "") + "无敌保护"
		health_state.modulate = Color("ffcfba")
	elif _feedback_left > 0.0:
		health_state.text = _feedback_text
		health_state.modulate = Color("bce9da") if _feedback_text.begins_with("恢复") else Color("ffcfba")
	else:
		health_state.text = "生命偏低 · 留意危险预警" if low else "生命充足" if _health.hp == _health.max_hp else "留意危险预警"
		health_state.modulate = Color("ffcfba") if low else Color("a9bec4")

func snapshot() -> Dictionary:
	if not is_instance_valid(_health):
		return {}
	return {
		"hp": _health.hp,
		"max_hp": _health.max_hp,
		"invulnerability_left": _health.invulnerability_left,
		"display": health_value.text,
		"state_text": health_state.text,
	}
