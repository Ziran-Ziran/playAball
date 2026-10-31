extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(20.0).timeout.connect(func(): quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func run() -> void:
	var hud = load("res://scenes/roguelite/run_hud.tscn").instantiate()
	root.add_child(hud)
	var health = load("res://scripts/roguelite/player_health.gd").new()
	root.add_child(health)
	check(hud.has_method("bind_health"), "HUD binds to the existing health source")
	if failures:
		hud.free()
		health.free()
		quit(1)
		return
	hud.bind_health(health)
	var bar: ProgressBar = hud.get_node("Overlay/PlayerPanel/Content/HealthBar")
	var number: Label = hud.get_node("Overlay/PlayerPanel/Content/Heading/HealthValue")
	var state: Label = hud.get_node("Overlay/PlayerPanel/Content/HealthState")
	check(bar.value == 5 and bar.max_value == 5 and number.text == "5 / 5", "Full health displays bar and numeric current/max")
	health.hurt(2)
	check(bar.value == 3 and number.text == "3 / 5" and state.text.contains("受伤"), "Damage updates immediately with a readable hurt status")
	health.invulnerability_left = 0.0
	await process_frame
	await process_frame
	check(not state.text.contains("无敌"), "Invulnerability status expires with the health source")
	health.hp = 5
	health.changed.emit(health.hp)
	check(bar.value == 5 and state.text.contains("恢复"), "Healing updates the panel and feedback")
	health.max_hp = 6
	health.hp = 6
	health.changed.emit(health.hp)
	check(bar.max_value == 6 and bar.value == 6 and number.text == "6 / 6", "Maximum health growth updates both bar range and value")
	health.hurt(99)
	check(bar.value == 0 and state.text.contains("倒下"), "Death remains explicit at zero health")
	health.max_hp = 5
	health.reset_health()
	check(bar.max_value == 5 and bar.value == 5 and not state.text.contains("倒下"), "Restart clears death and restores the base maximum")
	health.hurt(4)
	health.invulnerability_left = 0.0
	await create_timer(0.8).timeout
	check(state.text.contains("生命偏低") and number.text == "1 / 5", "Low health has an explicit warning beyond bar color")
	health.reset_health()
	var panel: Control = hud.get_node("Overlay/PlayerPanel")
	check(_all_ignore(panel), "Every passive health panel control passes mouse input")
	var other = load("res://scripts/roguelite/player_health.gd").new()
	root.add_child(other)
	hud.bind_health(other)
	health.hurt(1)
	check(bar.value == 5, "Rebinding disconnects the previous health source")
	other.hurt(1)
	check(bar.value == 4, "Rebound source updates the panel")
	paused = true
	other.invulnerability_left = 0.4
	await process_frame
	check(bar.value == 4 and state.text.contains("无敌"), "Paused HUD still reflects health without advancing immunity")
	paused = false
	var pool = load("res://scripts/roguelite/run_build.gd").new()
	var rng := RandomNumberGenerator.new()
	var choices: Array = pool.candidates(rng, true, 4, 5)
	hud.show_choices(choices)
	await process_frame
	check(hud.cards.get_child_count() == 3 and hud.panel.visible, "Health panel coexists with three reward cards")
	pool.choose("choices")
	choices = pool.candidates(rng, false, 4, 5)
	hud.show_choices(choices)
	await process_frame
	await process_frame
	check(hud.cards.get_child_count() == 4, "Four-choice reward remains intact beside health panel")
	check(hud.cards.get_global_rect().end.y <= root.get_visible_rect().size.y, "Four reward cards fit the logical viewport height")
	hud.close()
	check(panel.visible and not hud.panel.visible, "Closing rewards retains the health panel")
	hud.free()
	health.free()
	other.free()
	if failures == 0:
		print("HUD CHECKS PASSED: ", checks)
	quit(0 if failures == 0 else 1)

func _all_ignore(node: Node) -> bool:
	if node is Control and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
	for child in node.get_children():
		if not _all_ignore(child):
			return false
	return true
