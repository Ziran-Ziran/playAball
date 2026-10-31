extends Resource
const STAGES: Array[String] = ["res://resources/roguelite/stages/stage_1.tres", "res://resources/roguelite/stages/stage_2.tres", "res://resources/roguelite/stages/stage_3.tres"]
var stages: Array[Resource] = []
func _init() -> void:
	for path in STAGES:
		stages.append(load(path))
func rest_after(wave: int) -> String:
	for stage in stages:
		if stage.last_wave == wave and stage.rest != "finish":
			return stage.rest
	return ""
func stage_number(wave: int) -> int:
	for index in stages.size():
		if wave >= stages[index].first_wave and wave <= stages[index].last_wave:
			return index + 1
	return 3
