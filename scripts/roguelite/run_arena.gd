extends "res://scripts/roguelite/arena.gd"
var director: Node
var _previous_hp: int = 5
var _hurt_flash: float = 0.0

func _ready() -> void:
	super._ready()
	if DisplayServer.get_name() != "headless":
		get_window().title = "玩个球 · 肥鱼碰撞 Demo"
	for target in $Targets.get_children():
		$Targets.remove_child(target)
		target.queue_free()
	$HUD/Controls/Count.hide()
	$HUD/Controls/Momentum.hide()
	var volume_label := Label.new()
	volume_label.text = "音量"
	$HUD/Controls.add_child(volume_label)
	var volume := HSlider.new()
	volume.custom_minimum_size = Vector2(110, 30)
	volume.min_value = 0
	volume.max_value = 100
	volume.value = 100
	volume.tooltip_text = "音效音量"
	volume.value_changed.connect(func(value: float): feedback.volume = value / 100.0)
	$HUD/Controls.add_child(volume)
	$HUD/Menu/Buttons/Reset.text = "重新开局"
	$HUD/Menu/Buttons/Title.text = "已暂停"
	$HUD/Hint.text = "空白拖动发射 · 空心预警/实心危险 · 小弟初始不跟随 · 白饭近处吸鱼，吃饭强化下一撞 · Esc 暂停"
	director = $RunDirector
	director.setup(self)
	director.health.changed.connect(func(hp: int):
		if hp < _previous_hp:
			_hurt_flash = 0.3
		_previous_hp = hp
	)
	director.restart()

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(director):
		status.text = director.status_text()
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
