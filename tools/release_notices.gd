extends SceneTree
## 从正在用于导出的引擎提取实际许可文本，不用手写列表猜测编译依赖。
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected release notices output directory")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	var file: FileAccess = FileAccess.open(args[0].path_join("Godot_and_dependencies.txt"), FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_line(Engine.get_license_text())
	var licenses: Dictionary = Engine.get_license_info()
	for name: String in licenses:
		file.store_line("\n--- " + name + " ---\n" + str(licenses[name]))
	file.close()
	print("RELEASE NOTICES WRITTEN")
	quit(0)
