extends Control
## 独立只读素材样板；不发升级请求，不加入正式run或HUD。
@export_file("*.json") var catalog_path: String = "res://resources/roguelite/card_art_catalog.json"
@export var card_scene: PackedScene = preload("res://scenes/roguelite/presentation/card_art_card.tscn")
@export_range(3, 4) var columns: int = 4
@onready var row: HBoxContainer = $Margin/Content/Cards
@onready var filter: OptionButton = $Margin/Content/Toolbar/Filter
@onready var footer: Label = $Margin/Content/Footer
var entries: Array = []
var selected_id: String = ""
var page: int = 0
var filter_ids: Array[String] = [""]
var benefit_source: CanvasLayer
var capture_path: String = ""

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	if not parsed is Dictionary or not parsed.get("cards") is Array:
		push_error("Card art catalog is missing or invalid")
		get_tree().quit(1)
		return
	entries = parsed.cards
	# 复用现有纯收益算法；不把HUD节点加入树或调用其生命面板。
	benefit_source = load("res://scripts/roguelite/run_hud.gd").new()
	filter.add_item("全部成长 · 28张")
	for entry: Dictionary in entries:
		var id: String = entry.id
		if not filter_ids.has(id):
			filter_ids.append(id)
			var definition: DemoUpgrade = load("res://resources/roguelite/upgrades/%s.tres" % id)
			filter.add_item(definition.title)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--card-gallery-id="):
			selected_id = argument.trim_prefix("--card-gallery-id=")
		elif argument.begins_with("--card-gallery-columns="):
			columns = clampi(int(argument.trim_prefix("--card-gallery-columns=")), 3, 4)
		elif argument.begins_with("--card-gallery-page="):
			page = maxi(0, int(argument.trim_prefix("--card-gallery-page=")))
		elif argument.begins_with("--card-gallery-capture="):
			capture_path = argument.trim_prefix("--card-gallery-capture=")
	filter.select(maxi(0, filter_ids.find(selected_id)))
	filter.item_selected.connect(func(index: int): selected_id = filter_ids[index]; page = 0; _rebuild())
	$Margin/Content/Toolbar/Columns.pressed.connect(func(): columns = 7 - columns; page = 0; _rebuild())
	$Margin/Content/Toolbar/Previous.pressed.connect(func(): page -= 1; _rebuild())
	$Margin/Content/Toolbar/Next.pressed.connect(func(): page += 1; _rebuild())
	_rebuild()
	if not capture_path.is_empty():
		_capture.call_deferred()

func _selected() -> Array:
	return entries.filter(func(entry: Dictionary) -> bool: return selected_id.is_empty() or entry.id == selected_id)

func _rebuild() -> void:
	for child: Node in row.get_children():
		row.remove_child(child)
		child.queue_free()
	var visible_entries: Array = _selected()
	var pages: int = maxi(1, ceili(float(visible_entries.size()) / columns))
	page = posmod(page, pages)
	for index: int in range(page * columns, mini(visible_entries.size(), (page + 1) * columns)):
		_add_card(visible_entries[index])
	# 系列不足三/四张时仍维持同一槽宽，方便比较画中人物大小。
	for index: int in range(row.get_child_count(), columns):
		var blank: Control = Control.new()
		blank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(blank)
	footer.text = "%d / %d 页 · ← / → 翻页 · 3 / 4切换 · 插画候选，效果文字来自正式规则" % [page + 1, pages]

func _add_card(entry: Dictionary) -> void:
	var card: PanelContainer = card_scene.instantiate()
	row.add_child(card)
	card.set_meta("asset_id", entry.asset_id)
	var content: VBoxContainer = card.get_node("Margin/Content")
	var definition: DemoUpgrade = load("res://resources/roguelite/upgrades/%s.tres" % entry.id)
	content.get_node("Category").text = definition.category
	content.get_node("Title").text = definition.title
	var texture: TextureRect = content.get_node("Illustration")
	if FileAccess.file_exists(entry.path):
		texture.texture = load(entry.path)
	else:
		texture.tooltip_text = "待制作的插画"
	var level: int = int(entry.level)
	content.get_node("Level").text = "%d → %d / %d" % [level - 1, level, definition.max_level] if definition.max_level > 0 else "可重复 · 共用插画"
	var levels: Dictionary = {"companion": 2}
	levels[entry.id] = maxi(0, level - 1)
	var benefit: String = "生命 3 → 5 / 5\n示例：恢复2格，不超过上限" if entry.id == "heal" else str(benefit_source.call("benefit_preview", entry.id, levels))
	content.get_node("Benefit").text = benefit
	content.get_node("Description").text = definition.description
	content.get_node("Status").text = "母版已确认" if bool(entry.get("approved", false)) else "插画候选 · 待审"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_RIGHT: page += 1
			KEY_LEFT: page -= 1
			KEY_3: columns = 3; page = 0
			KEY_4: columns = 4; page = 0
			_: return
		_rebuild()
		get_viewport().set_input_as_handled()

func _capture() -> void:
	for index: int in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var evidence: Dictionary = {"window": [get_window().size.x, get_window().size.y], "columns": columns, "id": selected_id, "page": page, "cards": [], "problems": []}
	for card: Control in row.get_children():
		if not card.has_meta("asset_id"):
			continue
		var item: Dictionary = {"asset_id": card.get_meta("asset_id"), "bounds": str(card.get_global_rect()), "labels": []}
		if not get_viewport_rect().grow(1).encloses(card.get_global_rect()):
			evidence.problems.append(str(card.get_meta("asset_id")) + ": card exceeds viewport")
		var content: VBoxContainer = card.get_node("Margin/Content")
		var illustration: TextureRect = content.get_node("Illustration")
		item.texture_size = str(illustration.texture.get_size()) if illustration.texture != null else "missing"
		item.texture_filter = illustration.texture_filter
		if illustration.texture == null:
			evidence.problems.append(str(card.get_meta("asset_id")) + ": missing illustration")
		for child: Node in content.get_children():
			if child is Label:
				var bounds: Rect2 = child.get_global_rect()
				item.labels.append({"node": child.name, "bounds": str(bounds), "lines": child.get_line_count(), "text": child.text})
				if not card.get_global_rect().grow(1).encloses(bounds):
					evidence.problems.append(str(card.get_meta("asset_id")) + ": " + child.name + " exceeds card")
		evidence.cards.append(item)
	var result: Error = get_viewport().get_texture().get_image().save_png(capture_path)
	evidence.capture_result = result
	var file: FileAccess = FileAccess.open(capture_path + ".json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(evidence, "\t"))
		file.close()
	print("CARD GALLERY CAPTURE ", evidence.problems)
	get_tree().quit(0 if result == OK and evidence.problems.is_empty() else 1)

func _exit_tree() -> void:
	if is_instance_valid(benefit_source):
		benefit_source.free()
