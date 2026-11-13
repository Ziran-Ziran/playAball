extends SceneTree
## 从真实HUD检查下一等级插画、重复卡和实际生命收益，不用图鉴代替正式接线。
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()
	create_timer(25.0).timeout.connect(func(): push_error("Card art check timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var hud: CanvasLayer = load("res://scenes/roguelite/run_hud.tscn").instantiate()
	var health: DemoHealth = DemoHealth.new()
	root.add_child(health)
	root.add_child(hud)
	hud.bind_health(health)
	var expected_cards: int = 0
	for id: String in DemoBuild.UPGRADE_IDS + ["vigor"]:
		var definition: DemoUpgrade = load("res://resources/roguelite/upgrades/%s.tres" % id)
		var count: int = maxi(1, definition.max_level)
		for rank: int in range(1, count + 1):
			expected_cards += 1
			var levels: Dictionary = {"companion": 2}
			levels[id] = rank - 1
			hud.show_choices([definition], levels, 1, 77)
			await process_frame
			await process_frame
			var card: Button = hud.cards.get_child(0)
			var illustration: TextureRect = card.get_node_or_null("Content/Illustration")
			check(illustration != null, "%s rank%d: formal card has illustration" % [id, rank])
			if illustration != null:
				var suffix: String = "repeat" if definition.max_level == 0 else "lv%d" % rank
				var expected_path: String = "res://assets/cards/%s_%s.png" % [id, suffix]
				if id == "companion":
					expected_path = "res://assets/cards/release_r5/companion_%s.png" % suffix
				check(illustration.texture != null and illustration.texture.resource_path == expected_path, "%s rank%d: uses next-rank asset" % [id, rank])
			check(card.get_node("Content/Heading").text.contains(definition.title), id + ": real title")
			check(not card.get_node("Content/Preview").text.is_empty(), id + ": actual benefit")
			check(not card.get_node("Content/Detail").text.is_empty(), id + ": rules visible")
	check(expected_cards == 28, "Exactly 16 growths / 28 level images exercised")
	var heal: DemoUpgrade = load("res://resources/roguelite/upgrades/heal.tres")
	health.hp = 4
	health.changed.emit(4)
	hud.show_choices([heal], {"heal": 99})
	await process_frame
	var repeat_card: Button = hud.cards.get_child(0)
	check(repeat_card.get_node("Content/Preview").text.contains("4 → 5 / 5"), "Heal uses real near-cap HP")
	check(repeat_card.get_node("Content/Preview").text.contains("恢复 1"), "Heal does not promise overflowing recovery")
	if repeat_card.has_node("Content/Level"):
		check(repeat_card.get_node("Content/Level").text.contains("可重复") and not repeat_card.get_node("Content/Level").text.contains("100"), "Repeat card has no fake finite level")
	else:
		check(false, "Separate readable level label exists")
	hud.close()
	hud.free()
	health.free()
	await process_frame
	print("CARD ART CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
