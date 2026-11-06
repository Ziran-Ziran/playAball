extends SceneTree
## 检查重复实例化/释放的对象回收；headless结果不证明GPU或私有内存无泄漏。

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: PackedScene = load("res://sample/menu.tscn")
	var records: Array[Dictionary] = []
	var failed: int = 0
	for cycle in 20:
		var menu: Control = scene.instantiate()
		root.add_child(menu)
		for frame in 8:
			await process_frame
		var model_ref: WeakRef = weakref(menu.character.model)
		var source_ref: WeakRef = weakref(menu.character.source)
		menu.queue_free()
		for frame in 4:
			await process_frame
		var released: bool = model_ref.get_ref() == null and source_ref.get_ref() == null
		if not released:
			failed += 1
		records.append({"cycle": cycle + 1, "nodes_released": released, "objects": Performance.get_monitor(Performance.OBJECT_COUNT)})
	var baseline: int = int(records[5].objects)
	var last: int = int(records[-1].objects)
	if last != baseline:
		failed += 1
	var directory: String = ProjectSettings.globalize_path("res://evidence")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory.path_join("lifecycle_headless.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed": failed,"cycles":records,"warmed_object_count":baseline,"last_object_count":last,"scope":"Headless object/node cleanup only; not full L0, GPU or private-memory leak proof"},"  "))
	file.close()
	print("WHALE LIFECYCLE HEADLESS cycles=20 failed=",failed," objects ",baseline," -> ",last)
	quit(0 if failed == 0 else 1)
