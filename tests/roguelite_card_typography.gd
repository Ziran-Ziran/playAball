extends SceneTree
## 用真实卡片节点验证字形、数字和四种窗口排版；--negative-font验证旧字体能被检出。
var failures: int = 0
var checks: int = 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/roguelite/upgrade_card_copy.json"))["cards"]
	for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1024,576)]:
		root.size = resolution
		for count: int in [3,4]:
			var stage := Control.new()
			root.add_child(stage)
			var margin: float = 32.0
			var gap: float = 14.0
			var card_width: float = (resolution.x - margin * 2 - gap * (count-1)) / count
			for index: int in count:
				var card: Button = load("res://scenes/roguelite/presentation/upgrade_card.tscn").instantiate()
				stage.add_child(card)
				card.position = Vector2(margin + index*(card_width+gap), 52)
				card.size = Vector2(card_width, resolution.y-84)
				var id: String = ["companion","bowling","cooldown","explosion"][index]
				var definition: DemoUpgrade = load("res://resources/roguelite/upgrades/%s.tres" % id).duplicate()
				if index == 0:
					definition.title = "鲸鱼娘外包协作计划"
				card.configure(definition, 1, "1.45 → 1.20 秒\n伤害 +1 · 半径80", copy[id], load("res://assets/cards/%s_lv1.png" % id))
				if OS.get_cmdline_user_args().has("--negative-font"):
					card.get_node("Content/Heading").remove_theme_font_override("font")
			await process_frame
			await process_frame
			for card: Button in stage.get_children():
				var heading: Label = card.get_node("Content/Heading")
				var font: Font = heading.get_theme_font("font")
				verify(font.resource_path.contains("ZCOOLKuaiLe"), "Bundled artistic title font")
				for character: String in heading.text:
					verify(font.has_char(character.unicode_at(0)), "Title glyph exists: " + character)
				for name: String in ["Heading","Preview","Detail","Level","Flavor"]:
					var label: Label = card.get_node("Content/"+name)
					verify(label.get_line_count() <= label.get_visible_line_count(), "%s %s all lines visible" % [resolution,name])
					verify(label.position.x >= 0 and label.position.x + label.size.x <= card.size.x + 1, name+" inside card width")
					verify(label.position.y + label.size.y <= card.size.y + 1, name+" inside card height")
				verify(card.get_node("Content/Preview").text.contains("1.20") and card.get_node("Content/Preview").text.contains("80"), "Exact numeric text retained")
			if not DisplayServer.get_name() == "headless":
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/art_pass_20261105/card/cards_%dx%d_%d.png" % [resolution.x,resolution.y,count])
			stage.queue_free()
			await process_frame
	# 全16种真实标题和规则在最窄四卡槽逐项检查，不用四张样例代替全量。
	root.size = Vector2i(1024,576)
	var ids: Array = copy.keys()
	verify(ids.size() == 16, "All 16 growth cards enumerated")
	for id: String in ids:
		var card: Button = load("res://scenes/roguelite/presentation/upgrade_card.tscn").instantiate()
		root.add_child(card)
		card.position = Vector2(32,52)
		card.size = Vector2(229.5,492)
		var definition: DemoUpgrade = load("res://resources/roguelite/upgrades/%s.tres" % id)
		card.configure(definition, 1, "精确数值 1.20 · 80", copy[id], null)
		await process_frame
		await process_frame
		verify(card.get_node("Content/Heading").text == definition.title, id+" original dynamic title")
		verify(card.get_node("Content/Detail").text == copy[id]["rules"], id+" complete rules retained")
		for name: String in ["Heading","Detail","Preview","Flavor"]:
			var label: Label = card.get_node("Content/"+name)
			verify(label.get_line_count() <= label.get_visible_line_count(), id+" "+name+" all lines visible in narrow slot")
			verify(label.position.y + label.size.y <= card.size.y + 1, id+" "+name+" inside height")
		verify(card.get_node("Content/Detail").position.y + card.get_node("Content/Detail").size.y < card.get_node("Content/Flavor").position.y, id+" rules and flavor separated")
		card.queue_free()
		await process_frame
	verify(str(copy["heavy"]["rules"]).begins_with("主球有效撞击"), "Heavy rules scope explicitly player ball")
	print("TYPOGRAPHY: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
