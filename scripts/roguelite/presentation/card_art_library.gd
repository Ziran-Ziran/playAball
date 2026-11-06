class_name DemoCardArtLibrary
extends RefCounted
## 只读显示索引，不决定候选、等级上限或效果；重复项始终复用一级插画。
const CATALOG_PATH: String = "res://resources/roguelite/card_art_catalog.json"
const COPY_PATH: String = "res://resources/roguelite/upgrade_card_copy.json"
var _by_id: Dictionary = {}
var _copy: Dictionary = {}
var _textures: Dictionary = {}

func _init() -> void:
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if catalog is Dictionary:
		for entry: Dictionary in catalog.get("cards", []):
			var id: String = str(entry.id)
			if not _by_id.has(id):
				_by_id[id] = {}
			_by_id[id][int(entry.level)] = str(entry.path)
	var copy_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(COPY_PATH))
	if copy_data is Dictionary:
		_copy = copy_data.get("cards", {})

func path_for(id: String, next_level: int) -> String:
	var ranks: Dictionary = _by_id.get(id, {})
	if ranks.is_empty():
		return ""
	return str(ranks.get(clampi(next_level, 1, ranks.size()), ""))

func texture_for(id: String, next_level: int) -> Texture2D:
	var path: String = path_for(id, next_level)
	if path.is_empty():
		return null
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]

func copy_for(id: String) -> Dictionary:
	return _copy.get(id, {}).duplicate()
