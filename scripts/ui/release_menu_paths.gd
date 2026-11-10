extends Node
## 仅由含旁置模型的Windows导出副本启用，不改动既有Live2D适配器或模型。
var runtime_directory: String = ""

func _enter_tree() -> void:
	if OS.get_name() != "Windows" or DisplayServer.get_name() == "headless":
		return
	runtime_directory = OS.get_executable_path().get_base_dir().path_join("menu_character_runtime")
	if not FileAccess.file_exists(runtime_directory.path_join("model/runtime.model3.json")):
		return
	# 初始主场景可能先于autoload的_ready入树，必须在_enter_tree注册才能覆盖首屏。
	get_tree().node_added.connect(_bind_external_runtime)

func _bind_external_runtime(node: Node) -> void:
	var script: Script = node.get_script() as Script
	if script == null or script.resource_path != "res://scripts/ui/menu_character.gd":
		return
	node.set("model_path", runtime_directory.path_join("model/runtime.model3.json"))
	node.set("extension_path", runtime_directory.path_join("native/gd_cubism.gdextension"))
	node.set("profile_path", runtime_directory.path_join("menu_profile.json"))
