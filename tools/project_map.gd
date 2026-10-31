extends SceneTree
## 根据 Git 可见文件和人工用途清单生成文件树；不依赖额外运行时。

const MAP_PATH: String = "res://docs/FILE_MAP.md"
const PURPOSES_PATH: String = "res://docs/file_purposes.json"
var _purposes: Dictionary = {}

func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 1 or arguments[0] not in ["--write", "--check"]:
		_fail("用法：godot --headless --path . --script tools/project_map.gd -- --write 或 --check")
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PURPOSES_PATH)) != OK or not parser.data is Dictionary:
		_fail("无法读取 docs/file_purposes.json，请检查 JSON 格式")
		return
	_purposes = parser.data
	if not _purposes.get("files") is Dictionary or not _purposes.get("directories") is Dictionary:
		_fail("用途清单必须包含 files 和 directories 对象")
		return
	var output: Array = []
	var root_path: String = ProjectSettings.globalize_path("res://")
	# Windows 的进程输出解码可能使用本机代码页；让 Git 输出 ASCII 转义后自行解码。
	var result: int = OS.execute("git", PackedStringArray(["-C", root_path, "-c", "core.quotepath=true", "ls-files", "--cached", "--others", "--exclude-standard"]), output, true)
	if result != 0:
		_fail("Git 文件列表读取失败：%s" % str(output))
		return
	var paths: Array[String] = []
	for line in str(output[0]).split("\n", false):
		var path: String = _decode_git_path(line.trim_suffix("\r"))
		if FileAccess.file_exists("res://" + path) and not paths.has(path):
			paths.append(path)
	# 首次生成时目录文件本身尚不存在，也应列入树中。
	if not paths.has("docs/FILE_MAP.md"):
		paths.append("docs/FILE_MAP.md")
	paths.sort()
	var issues: Array[String] = []
	for path in paths:
		if _file_purpose(path).strip_edges().is_empty():
			issues.append("缺少文件用途：" + path)
	for path in _purposes.files:
		if not paths.has(str(path)):
			issues.append("用途清单存在已删除/改名文件，请同步清理：" + str(path))
	if not issues.is_empty():
		_fail("\n".join(issues))
		return
	var content: String = "# 项目文件目录\n\n"
	content += "由 `tools/project_map.gd` 根据 Git 可见文件与 `docs/file_purposes.json` 生成。请修改用途清单后重新生成，不直接编辑此树。\n\n"
	content += "覆盖已跟踪文件及未忽略的新文件；不包含 `.git/`、`.godot/`、`.local/` 等本机缓存。新增、删除、改名或职责变化后立即更新，交付前和 CI 检查是否过期。\n\n"
	content += "```text\nplayAball/\n" + _tree(paths, "", "") + "```\n\n"
	content += "## 主要关系\n\n```text\nproject.godot → scenes/main.tscn → scripts/main.gd（组织关卡、输入、HUD）\n  ├─ scenes/ball.tscn → scripts/ball.gd（刚体与碰撞信号）\n  ├─ scenes/mechanism.tscn → scripts/mechanism.gd（区域机关）\n  └─ scripts/impact_feedback.gd ← impacted 信号（碰撞表现）\n\nscenes/roguelite/arena.tscn → arena.gd（独立俯视三靶场）\n  ├─ launch_controller → player_ball → combat_body（冲量/接触）\n  ├─ companion_manager → companion_ball（初始摆球/接力/可选跟随）\n  ├─ collision_combat → destructible（去重伤害）\n  └─ impact_feedback（共用表现，新场景粒子零重力）\n\nscenes/roguelite/run.tscn → run_arena → run_director（五波/击杀领奖/胜负）\n  ├─ enemy / player_health / hazard_ball（三敌人与可预警危险）\n  ├─ run_build → resources/roguelite/upgrades（十五项池/分类权重）\n  ├─ boss（可碎模块/撞墙弱点/缺口震波）\n  ├─ run_hud（3/4选卡/结算/重开）\n  └─ rice_manager → rice_lure / theme_definition（白饭平面力/肥鱼绘图）\n\ntools/verify.ps1 / GitHub CI\n  ├─ Godot 导入检查\n  ├─ tools/project_map.gd --check（文件目录完整且最新）\n  ├─ tests/smoke.gd（旧侧视行为回归）\n  ├─ tests/roguelite_smoke.gd（俯视发射/碰撞/接力/归队）\n  ├─ tests/roguelite_input_feedback.gd（全屏手势/冷却临界/反馈坐标）\n  ├─ tests/roguelite_{enemies,build,boss,run,rice,theme}.gd（整局/白饭/主题规则）\n  └─ tests/roguelite_{kill_rewards,kill_run,launch_rewards,reward_effects}.gd（击杀发育雏形）\n```\n\n"
	content += "图中关系是人工维护的架构摘要，文件树由工具生成；改变模块关系时也要更新生成器中的摘要，并通过 Review。维护方法见 [教程 002](tutorials/002-project-map-and-review.md)。\n"
	if arguments[0] == "--check":
		if not FileAccess.file_exists(MAP_PATH) or FileAccess.get_file_as_string(MAP_PATH).replace("\r\n", "\n") != content:
			_fail("FILE_MAP 已过期，请运行同一脚本 -- --write 后重新检查")
			return
		print("PROJECT MAP CHECK PASSED: ", paths.size(), " files")
	else:
		var file := FileAccess.open(MAP_PATH, FileAccess.WRITE)
		if file == null:
			_fail("无法写入 FILE_MAP，错误码：%s" % FileAccess.get_open_error())
			return
		file.store_string(content)
		file.close()
		print("PROJECT MAP UPDATED: ", paths.size(), " files")
	quit(0)

func _file_purpose(path: String) -> String:
	if _purposes.files.has(path):
		var purpose: Variant = _purposes.files[path]
		return purpose if purpose is String else ""
	if path.ends_with(".gd.uid"):
		return "关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。"
	if path.ends_with(".import"):
		return "同名素材的 Godot 导入配置，应随素材一起维护。"
	return ""

func _decode_git_path(value: String) -> String:
	if not value.begins_with('"') or not value.ends_with('"'):
		return value
	var encoded: String = value.substr(1, value.length() - 2)
	var bytes := PackedByteArray()
	var index: int = 0
	var escapes: Dictionary = {"a": 7, "b": 8, "t": 9, "n": 10, "v": 11, "f": 12, "r": 13, "\\": 92, '"': 34}
	while index < encoded.length():
		if encoded.substr(index, 1) != "\\":
			bytes.append(encoded.unicode_at(index))
			index += 1
			continue
		index += 1
		var digits: String = encoded.substr(index, 3)
		if digits.length() == 3 and digits[0] in "01234567" and digits[1] in "01234567" and digits[2] in "01234567":
			bytes.append(int(digits[0]) * 64 + int(digits[1]) * 8 + int(digits[2]))
			index += 3
		else:
			bytes.append(int(escapes.get(encoded.substr(index, 1), 63)))
			index += 1
	return bytes.get_string_from_utf8()

func _tree(paths: Array[String], directory: String, indent: String) -> String:
	var children: Array[String] = []
	for path in paths:
		if not path.begins_with(directory):
			continue
		var tail: String = path.trim_prefix(directory)
		var child: String = tail.get_slice("/", 0) + ("/" if tail.contains("/") else "")
		if not children.has(child):
			children.append(child)
	children.sort_custom(func(a: String, b: String) -> bool:
		if a.ends_with("/") != b.ends_with("/"):
			return a.ends_with("/")
		return a < b)
	var text: String = ""
	for index in children.size():
		var child: String = children[index]
		var last: bool = index == children.size() - 1
		var full_path: String = directory + child
		var folder: bool = child.ends_with("/")
		var purpose: String = str(_purposes.directories.get(full_path, "项目子目录")) if folder else _file_purpose(full_path)
		text += indent + ("└── " if last else "├── ") + child + "  # " + purpose + "\n"
		if folder:
			text += _tree(paths, full_path, indent + ("    " if last else "│   "))
	return text

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
