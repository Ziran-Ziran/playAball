extends "res://scripts/roguelite/arena.gd"
var director: Node
@onready var audio: Node = $AudioDirector
var sfx_volume: float = 0.65
var ui_volume: float = 0.65
var _previous_hp: int = 5
var _hurt_flash: float = 0.0

func _ready() -> void:
	super._ready()
	if DisplayServer.get_name() != "headless":
		get_window().title = "玩个球 · 击杀奖励 Demo"
	for target in $Targets.get_children():
		$Targets.remove_child(target)
		target.queue_free()
	$HUD/Controls/Count.hide()
	$HUD/Controls/Momentum.hide()
	# 基础生命面板占左侧，原控制与进度移到右侧，空白仍穿透输入。
	status.position = Vector2(320, 10)
	status.add_theme_font_size_override("font_size", 17)
	$HUD/Hint.position = Vector2(320, 65)
	$HUD/Hint.add_theme_font_size_override("font_size", 14)
	$HUD/Controls.position = Vector2(320, 90)
	feedback.audio_director = audio
	$HUD/Controls/Mute.toggled.connect(func(_value: bool): sync_audio_mix())
	add_volume_control("音效", false)
	add_volume_control("提示", true)
	sync_audio_mix()
	$HUD/Menu/Buttons/Reset.text = "重新开局"
	$HUD/Menu/Buttons/Title.text = "已暂停"
	$HUD/Hint.text = "空白拖动 · 右键取消 · Esc 暂停 · 敌方生命：绿1 / 黄2–3 / 紫4–6"
	director = $RunDirector
	director.setup(self)
	var split_option := CheckButton.new()
	split_option.name = "Split"
	split_option.text = "击破分裂"
	split_option.tooltip_text = "可选：较高生命敌人击破后分裂为次级敌人；不额外刷取击杀奖励和钱币。"
	split_option.button_pressed = director.split_enabled
	split_option.toggled.connect(director.set_split_enabled)
	$HUD/Controls.add_child(split_option)
	$RunHUD.bind_health(director.health)
	director.run_event.connect(on_run_event)
	launcher.fired.connect(func(_chain: int): audio.play_event(&"launch"))
	director.health.changed.connect(func(hp: int):
		if hp < _previous_hp:
			_hurt_flash = 0.3
			audio.play_event(&"hurt")
		_previous_hp = hp
	)
	director.restart()

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(director):
		status.text = "阶段%d/3 · 第%s波 · %d/%d 次可发 · 冷却 %.1fs · 发射%d · 钱币%d\n击杀%d · 奖励 %d/%d · 待选%d" % [director.flow.stage_number(director.wave), "首领" if director.wave == 6 else str(director.wave), launcher.charges, launcher.capacity, ceilf(launcher.remaining * 10.0) / 10.0, launcher.shots, director.wallet.balance, director.kills, director.rewards.progress, director.rewards.next_target(), director.rewards.pending]
		if director.rice.stored_bonus:
			status.text += " · 饱饭"
		audio.set_audio_paused(get_tree().paused)
		sync_audio_mix()
		_hurt_flash = maxf(0.0, _hurt_flash - delta)
		player.modulate = Color.WHITE.lerp(Color("ff776b"), _hurt_flash / 0.3)
		player.well_fed = director.rice.stored_bonus
		player.queue_redraw()

func set_paused(value: bool) -> void:
	if is_instance_valid(director):
		director.set_paused(value)
	else:
		super.set_paused(value)

func reset_range() -> void:
	if is_instance_valid(director):
		director.restart()
	else:
		super.reset_range()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and is_instance_valid(director):
		if director.state in [director.State.VICTORY, director.State.DEFEAT]:
			director.restart()
			get_viewport().set_input_as_handled()
			return
	super._input(event)

func add_volume_control(label_text: String, is_ui: bool) -> void:
	var label := Label.new()
	label.text = label_text
	$HUD/Controls.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(100, 30)
	slider.max_value = 100
	slider.value = 65
	slider.tooltip_text = label_text + "音量"
	slider.value_changed.connect(func(value: float):
		if is_ui:
			ui_volume = value / 100.0
		else:
			sfx_volume = value / 100.0
		sync_audio_mix()
	)
	$HUD/Controls.add_child(slider)

func sync_audio_mix() -> void:
	audio.set_mix(sfx_volume, ui_volume, not feedback.sound_enabled)

func on_run_event(event: String) -> void:
	if event == "reset":
		audio.reset_audio()
		audio.set_audio_paused(false)
	elif event == "pause":
		audio.set_audio_paused(get_tree().paused)
	else:
		audio.play_event(StringName(event))
