extends SceneTree
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int = 3) -> void:
	for _i in count: await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	game.get_node("AudioDirector").muted = true
	var d = game.director
	d.set_process(false)
	var feedback = game.get_node("RunHUD/BuildFeedback")
	check(feedback.director == d, "Deferred binding finds director")
	check(feedback.visible and feedback._bar.text.contains("伙伴0/3"), "Fresh run reads actual build")
	feedback._on_relay(Vector2.ZERO,1)
	check(feedback.notices == 0, "First generation does not fake deep relay")
	game.combat.relay.emit(Vector2.ZERO,3)
	await frames()
	check(feedback._notice.text.contains("3代") and feedback.trigger_counts.relay == 1, "Relay success uses real signal")
	game.combat.explosion_triggered.emit(Vector2.ZERO,112.0)
	await frames()
	check(feedback._notice.text.contains("112"), "Explosion uses actual radius")
	game.combat.bowling_surged.emit(Vector2.ZERO,2)
	await frames()
	check(feedback._notice.text.contains("2名"), "Bowling uses actual affected count")
	d.precision_rewarded.emit(Vector2.ZERO, 0.5)
	await frames()
	check(feedback._notice.text == "精准连击 · 回能0.5秒" and feedback.trigger_counts.precision == 1, "Precision consumes real successful refund signal")
	check(feedback.notice_kind == 0, "Precision reuses relay badge rather than explosion")
	d.precision_rewarded.emit(Vector2.ZERO, 0.25)
	await frames()
	check(feedback._notice.text == "精准连击 · 回能0.25秒", "Partial refund shows actual amount")
	var precision_before: int = feedback.notices
	d.precision_rewarded.emit(Vector2.ZERO, 0.0)
	d.precision_rewarded.emit(Vector2.ZERO, -0.5)
	await frames()
	check(feedback.notices == precision_before and feedback.trigger_counts.precision == 2, "Zero or negative refund does not fake success")
	paused = true
	var precision_left: float = feedback.notice_left
	await frames(10)
	check(is_equal_approx(precision_left, feedback.notice_left), "Precision feedback freezes during decision pause")
	paused = false
	var child_count: int = feedback.get_child_count()
	for _i in 1000: feedback.show_notice("聚合",1)
	check(feedback.get_child_count() == child_count, "Burst reuses bounded controls")
	paused = true
	var before: float = feedback.notice_left
	await frames(10)
	check(is_equal_approx(before,feedback.notice_left), "Decision pause freezes notice lifetime")
	OceanUi.reduced_motion = true
	await frames()
	check(feedback._notice.modulate.a == 1.0, "Reduced motion retains static feedback")
	OceanUi.reduced_motion = false
	paused = false
	game.get_node("RunHUD").panel.show()
	await frames()
	check(not feedback.visible, "Reward modal owns screen")
	game.get_node("RunHUD").panel.hide()
	game.get_node("HUD/Menu").show()
	await frames()
	check(not feedback.visible, "Pause modal owns screen")
	game.get_node("HUD/Menu").hide()
	d.restart()
	d.set_process(false)
	await frames()
	check(feedback.notices == 0 and feedback.trigger_counts.bowling == 0 and feedback.trigger_counts.precision == 0, "Restart clears counters and notice")
	var offers: Array = [{"id":"heal","text":"免费恢复2点生命","enabled":true},{"id":"upgrade","text":"免费成长","enabled":true},{"id":"paid_heal","text":"整备恢复2点 · 4币（已购）","enabled":false},{"id":"paid_upgrade","text":"整备成长 · 8币","enabled":true},{"id":"skip","text":"跳过并继续","enabled":true}]
	var rest = d.rest_panel
	for dimensions in [Vector2i(1280,720),Vector2i(1024,576),Vector2i(1600,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await frames()
		check(feedback._bar.position.x + feedback._bar.size.x <= dimensions.x, "Build hint fits actual viewport width")
		rest.show_rest("路边补给摊","当前12币 · 生命3/5\n可先整备，再选免费补给。",offers,42)
		await frames(8)
		await create_timer(0.45).timeout
		check(rest.actions.get_child_count()==5,"All five offers available")
		check(rest.actions.get_child(0).get_meta("offer_id")=="paid_heal","Optional preparations precede departure")
		check(rest.actions.get_child(0).disabled,"Disabled state preserved")
		check(rest.panel.position.y>=0 and rest.panel.get_rect().end.y<=dimensions.y+1,"Rest inside viewport")
		var scroll: ScrollContainer = rest.actions.get_parent()
		check(scroll.get_global_rect().end.y<=dimensions.y,"Scrolling actions stay inside viewport")
		var last: Button = rest.actions.get_child(4)
		scroll.ensure_control_visible(last)
		await frames(3)
		check(last.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1, "Continue remains reachable by scrolling")
		scroll.scroll_vertical = 0
		await frames(3)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://.local/p2-ui")
			root.get_texture().get_image().save_png("res://.local/p2-ui/rest-%dx%d.png"%[dimensions.x,dimensions.y])
	root.content_scale_size = Vector2i(1280,720)
	root.size = Vector2i(1280,720)
	rest.hide()
	d.state = d.State.BATTLE
	feedback.show_notice("3代接力 · 阵型已串联",0)
	await frames(4)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/p2-ui/feedback.png")
	d.precision_rewarded.emit(Vector2.ZERO, 0.5)
	await frames(4)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/p2-ui/feedback-precision.png")
	check(game.get_node("RunHUD").benefit_preview("relay",{}).contains("+1/+2"),"Relay preview matches growth rule")
	check(game.get_node("RunHUD").benefit_preview("explosion",{}).contains("80/96/112"),"Explosion preview matches generation radii")
	paused = false
	game.queue_free()
	await frames()
	print("BUILD FEEDBACK CHECKS PASSED: ",checks," failures: ",failures)
	quit(0 if failures==0 else 1)
