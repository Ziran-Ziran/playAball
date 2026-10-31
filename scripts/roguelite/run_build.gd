class_name DemoBuild
extends RefCounted
const UPGRADE_IDS: Array[String] = ["companion", "cooldown", "follow", "heavy", "relay", "bowling", "explosion", "heal", "launch_power", "glide", "echo", "double_launch", "choices", "shrink", "pulse"]
var levels: Dictionary = {}
var definitions: Array[DemoUpgrade] = []
var fallback: DemoUpgrade = preload("res://resources/roguelite/upgrades/vigor.tres")

func _init() -> void:
	for id: String in UPGRADE_IDS:
		definitions.append(load("res://resources/roguelite/upgrades/%s.tres" % id) as DemoUpgrade)

func reset_build() -> void:
	levels.clear()

func companion_count() -> int:
	return 1 + mini(3, int(levels.get("companion", 0)))

func launch_cooldown() -> float:
	return maxf(1.2, 2.2 - 0.25 * int(levels.get("cooldown", 0)))

func choice_count() -> int:
	return 4 if has_upgrade("choices") else 3

func launch_multiplier() -> float:
	return 1.0 + 0.15 * mini(3, int(levels.get("launch_power", 0)))

func damping_multiplier() -> float:
	return pow(0.75, mini(3, int(levels.get("glide", 0))))

func friction_multiplier() -> float:
	return pow(0.7, mini(3, int(levels.get("glide", 0))))

func attack_radius_scale() -> float:
	return 1.0 - 0.15 * mini(2, int(levels.get("shrink", 0)))

func launch_capacity() -> int:
	return 2 if has_upgrade("double_launch") else 1

func max_health() -> int:
	return 5 + int(levels.get("vigor", 0))

func has_upgrade(id: String) -> bool:
	return int(levels.get(id, 0)) > 0

func choose(id: String) -> bool:
	if id == fallback.id:
		levels[id] = int(levels.get(id, 0)) + 1
		return true
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
	for upgrade: DemoUpgrade in definitions:
		if upgrade.id == "heal":
			if hp >= max_hp:
				continue
		if upgrade.id == "relay" and companion_count() < 2:
			continue
		if upgrade.max_level > 0 and int(levels.get(upgrade.id, 0)) >= upgrade.max_level:
			continue
		if first_wave and upgrade.id == "companion":
			result.append(upgrade)
		else:
			pool.append(upgrade)
	while result.size() < choice_count() and not pool.is_empty():
		var diverse: Array[DemoUpgrade] = []
		var used_categories: Dictionary = {}
		for card: DemoUpgrade in result:
			used_categories[card.category] = true
		for card: DemoUpgrade in pool:
			if not used_categories.has(card.category):
				diverse.append(card)
		# 优先提供不同路线；类别不足时继续抽取，仍不重复ID。
		var chosen: DemoUpgrade = weighted_pick(diverse if not diverse.is_empty() else pool, rng)
		result.append(chosen)
		pool.erase(chosen)
	# 满血且普通池已耗尽时提供可增加生命上限的单张兜底。
	if result.is_empty():
		result.append(fallback)
	return result

func weighted_pick(pool: Array[DemoUpgrade], rng: RandomNumberGenerator) -> DemoUpgrade:
	var weights: Array[float] = []
	var total: float = 0.0
	for card: DemoUpgrade in pool:
		var invested: int = 0
		for upgrade: DemoUpgrade in definitions:
			if upgrade.category == card.category:
				invested += int(levels.get(upgrade.id, 0))
		# 同类投资最多加30%抽取权重，保留混搭机会，不锁定路线。
		var weight: float = maxf(0.01, card.weight) * (1.0 + 0.1 * mini(3, invested))
		weights.append(weight)
		total += weight
	var roll: float = rng.randf() * total
	for index: int in pool.size():
		roll -= weights[index]
		if roll < 0.0:
			return pool[index]
	return pool.back()
