extends RefCounted
## 正式弹窗统一使用内置生图底图，所有文字和操作仍由原控件负责。
static func apply(control: Control) -> void:
	OceanUi.apply(control)

static func primary(button: Button) -> void:
	OceanUi.primary(button)
