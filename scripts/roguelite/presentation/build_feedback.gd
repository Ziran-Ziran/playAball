extends Control
## 只读构筑与成功事件提示；不统计尝试伤害，不回写伤害/经济/生成。
@export_range(0.3, 3.0) var notice_duration: float = 1.45
var director: Node
var combat: Node
var hud: Node
var notice_left: float = 0.0
var notice_kind: int = 0
var notices: int = 0
var trigger_counts: Dictionary = {"relay":0, "explosion":0, "bowling":0, "precision":0}
var _bar: Label
var _notice: Label
var _icon: TextureRect
var _art: Texture2D
var _last_levels: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar = Label.new()
	_bar.name = "BuildState"
	_bar.clip_text = true
	_bar.add_theme_font_size_override("font_size", 14)
	_bar.add_theme_color_override("font_color", Color("b7d5eb"))
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	_notice = Label.new()
	_notice.name = "SuccessNotice"
	_notice.add_theme_font_size_override("font_size", 20)
	_notice.add_theme_color_override("font_color", Color("f3e7b3"))
	_notice.add_theme_color_override("font_shadow_color", Color("101b31"))
	_notice.add_theme_constant_override("shadow_offset_x", 1)
	_notice.add_theme_constant_override("shadow_offset_y", 1)
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_notice)
	_icon = TextureRect.new()
	_icon.name = "StrategyBadge"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	if ResourceLoader.exists("res://assets/ui/build_feedback/strategy_badges.png"):
		_art = load("res://assets/ui/build_feedback/strategy_badges.png")
	_bind.call_deferred()

func _bind() -> void:
	hud = get_parent()
	var arena: Node = hud.get_parent()
	director = arena.get("director")
	if not is_instance_valid(director):
		return
	combat = director.get("combat")
	combat.relay.connect(_on_relay)
	combat.explosion_triggered.connect(_on_explosion)
	combat.bowling_surged.connect(_on_bowling)
	director.run_event.connect(_on_run_event)
	director.precision_rewarded.connect(_on_precision_rewarded)

func _on_run_event(event: String) -> void:
	if event == "reset":
		notice_left = 0.0
		notices = 0
		trigger_counts = {"relay":0, "explosion":0, "bowling":0, "precision":0}

func _on_relay(_point: Vector2, generation: int) -> void:
	# 一代基础传能不是深度兑现；二/三代成功才计一次接力触发。
	if generation < 2: return
	trigger_counts.relay += 1
	show_notice("%d代接力 · 阵型已串联" % generation, 0)

func _on_explosion(_point: Vector2, radius: float) -> void:
	trigger_counts.explosion += 1
	show_notice("连锁爆破 · 范围 %d" % roundi(radius), 1)

func _on_bowling(_point: Vector2, hit_count: int) -> void:
	if hit_count <= 0: return
	trigger_counts.bowling += 1
	show_notice("余势波及 · %d名敌人" % hit_count, 2)

func _on_precision_rewarded(_point: Vector2, refunded_seconds: float) -> void:
	# 玩法仅对实际退款发布成功；表现仍拒绝零/非法值，避免制造假回能。
	if not is_finite(refunded_seconds) or refunded_seconds <= 0.0: return
	trigger_counts.precision += 1
	var seconds: String = String.num(refunded_seconds, 2).rstrip("0").trim_suffix(".")
	if refunded_seconds < 0.01: seconds = "不足0.01"
	show_notice("精准连击 · 回能%s秒" % seconds, 0)

func show_notice(text: String, kind: int) -> void:
	# 只有一个复用控件，没有队列；高频事件覆盖旧提示，不产生无界节点。
	_notice.text = text
	notice_kind = clampi(kind, 0, 3)
	notice_left = notice_duration
	notices += 1
	if _art != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = _art
		var cell: Vector2 = _art.get_size() / 2.0
		atlas.region = Rect2(Vector2(notice_kind % 2, notice_kind / 2) * cell, cell)
		atlas.filter_clip = true
		_icon.texture = atlas

func _process(delta: float) -> void:
	if not is_instance_valid(director): return
	var arena: Node = hud.get_parent()
	var pause_menu: Control = arena.get_node_or_null("HUD/Menu")
	# 成长、商店、结算、暂停具有独占显示权；瞄准静止仍保留构筑信息。
	visible = director.state == director.State.BATTLE and not hud.panel.visible and not (pause_menu != null and pause_menu.visible)
	if is_instance_valid(director.rest_panel) and director.rest_panel.visible: visible = false
	if not get_tree().paused:
		notice_left = maxf(0.0, notice_left - delta)
	var viewport_size: Vector2 = get_viewport_rect().size
	_bar.position = Vector2(40, viewport_size.y - 29)
	_bar.size = Vector2(maxf(1, viewport_size.x - 80), 24)
	var levels: Dictionary = director.build.levels
	var state_text: String = "构筑  ·  伙伴%d/3  ·  强化接力%s  ·  爆破%s  ·  保龄%s" % [director.build.companion_count(), "已启用" if int(levels.get("relay",0)) > 0 else "未取得", "已启用" if int(levels.get("explosion",0)) > 0 else "未取得", "已启用" if int(levels.get("bowling",0)) > 0 else "未取得"]
	var skill_hint: String = state_text + "  ·  直撞3敌可回能"
	# 按真实字宽决定是否附加教学，窄屏优先保留玩家实际构筑。
	if _bar.get_theme_font("font").get_string_size(skill_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x <= _bar.size.x:
		state_text = skill_hint
	if state_text != _last_levels:
		_bar.text = state_text
		_last_levels = state_text
	_notice.position = Vector2(viewport_size.x - 326, 132)
	_icon.position = _notice.position - Vector2(40, 3)
	_icon.size = Vector2(34, 34)
	_notice.visible = notice_left > 0.0
	_icon.visible = _notice.visible
	# 减少动态保留静态成功文字，关闭渐隐；不隐藏必要状态信息。
	var alpha: float = 1.0 if OceanUi.reduced_motion else minf(1.0, notice_left / 0.22)
	_notice.modulate.a = alpha
	_icon.modulate.a = alpha
