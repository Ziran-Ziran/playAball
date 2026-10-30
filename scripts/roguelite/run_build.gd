class_name DemoBuild
extends RefCounted
const UPGRADE_IDS: Array[String] = ["companion", "cooldown", "follow", "heavy", "relay", "bowling", "explosion", "heal"]
var levels: Dictionary = {}
var definitions: Array[DemoUpgrade] = []

func _init() -> void:
	for id: String in UPGRADE_IDS:
		definitions.append(load("res://resources/roguelite/upgrades/%s.tres" % id) as DemoUpgrade)

func reset_build() -> void:
	levels.clear()

func companion_count() -> int:
	return 1 + mini(3, int(levels.get("companion", 0)))

func launch_cooldown() -> float:
	return maxf(1.7, 2.2 - 0.25 * int(levels.get("cooldown", 0)))

func has_upgrade(id: String) -> bool:
	return int(levels.get(id, 0)) > 0

func choose(id: String) -> bool:
	for upgrade: DemoUpgrade in definitions:
		if upgrade.id != id:
			continue
		var level: int = int(levels.get(id, 0))
		if upgrade.max_level > 0 and level >= upgrade.max_level:
			return false
		levels[id] = level + 1
		return true
	return false

func candidates(rng: RandomNumberGenerator, first_wave: bool, hp: int, max_hp: int) -> Array[DemoUpgrade]:
	var pool: Array[DemoUpgrade] = []
	var result: Array[DemoUpgrade] = []
	var heal: DemoUpgrade
	for upgrade: DemoUpgrade in definitions:
		if upgrade.id == "heal":
			heal = upgrade
			if hp >= max_hp:
				continue
		if upgrade.max_level > 0 and int(levels.get(upgrade.id, 0)) >= upgrade.max_level:
			continue
		if first_wave and upgrade.id == "companion":
			result.append(upgrade)
		else:
			pool.append(upgrade)
	while result.size() < 3 and not pool.is_empty():
		var index: int = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	# 池已耗尽时仍有一个可继续游戏的选择，不复制同一张卡填满三槽。
	if result.is_empty():
		result.append(heal)
	return result
