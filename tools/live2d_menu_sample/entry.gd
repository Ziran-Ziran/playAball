extends Node
## Release 模板不依赖编辑器 --script 开关，验证与试玩共用真正的发布入口。
func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--visual-review" in arguments:
		add_child(load("res://tools/live2d_menu_sample/verify_visual.gd").new())
		return
	var scene: String = "menu_sample.tscn"
	if "--lifecycle" in arguments: scene = "lifecycle.tscn"
	if "--verify" in arguments:
		var verification: Node = load("res://tools/live2d_menu_sample/verify_sample.gd").new()
		add_child(verification)
	else:
		add_child(load("res://tools/live2d_menu_sample/" + scene).instantiate())
