class_name DsResultBody
extends HBoxContainer
## 只展示整局传入的真实记录；胜负不由插画或UI动画判断。
@onready var portrait: TextureRect = $Portrait
@onready var defeats: Label = $Records/Values/Defeats/Value
@onready var relay: Label = $Records/Values/Relay/Value
@onready var note: Label = $Records/Note

func configure(won: bool, kills: int, longest: int) -> void:
	portrait.texture = load("res://assets/ui/ds_console/result_victory.png" if won else "res://assets/ui/ds_console/result_retry.png")
	defeats.text = str(kills)
	relay.text = str(longest)
	note.text = "这一局，值得多吃一碗。" if won else "休息一下，下一局继续陪你。"

func fit_width(content_width: float) -> void:
	note.size.x = maxf(1.0, content_width - portrait.custom_minimum_size.x - get_theme_constant("separation"))
	note.update_minimum_size()
	$Records.update_minimum_size()
	update_minimum_size()
