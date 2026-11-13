extends SceneTree
## 真正Area2D回调触发死亡/机关停用；错误日志也必须由运行器视为失败。
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(30).timeout.connect(func(): push_error("Pause physics timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	for wave in [1, 3, 5, 6]:
		await case_wave(wave)
	print("PAUSE PHYSICS CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)

func case_wave(wave: int) -> void:
	var game = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame
	var director = game.director
	director.set_process(false)
	director.debug_wave(wave)
	await physics_frame
	await physics_frame
	director.pending.clear()
	director.health.hp = 1
	var pivots: Array[Node] = director.maps.current_map.find_children("*", "Node2D", true, false).filter(func(node): return node.has_node("Paddle") and node.has_method("set_active"))
	check(not pivots.is_empty() or wave == 5, "Formal map contains expected rigid-body pivots")
	var body: RigidBody2D = pivots[0].get_node("Paddle") if not pivots.is_empty() else null
	var observations: Array[bool] = []
	director.health.died.connect(func():
		observations.append(director.state == director.State.DEFEAT and not director.maps.active and paused)
		# 状态同步停止，物理mode只能延后改；原实现此处同步写freeze并报物理锁。
		observations.append(not body.freeze if body != null else true))
	var hazard: DemoHazard = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	hazard.health = director.health
	hazard.position = game.player.position
	director.hazards.add_child(hazard)
	for frame in 10: await physics_frame
	check(observations.size() == 2 and observations[0], "Real sensor death immediately owns defeat and logical map pause")
	check(observations.size() == 2 and observations[1], "Physics freeze mutation deferred out of query-flush callback")
	check(body.freeze if body != null else true, "Deferred freeze completes even while scene tree paused")
	for mechanism in director.maps.current_map.find_children("*", "Node2D", true, false):
		if mechanism.has_method("set_active"):
			check(not mechanism.active, "Logical mechanism immediately stopped: " + mechanism.name)
	check(not director.health.hurt() and director.health.hp == 0, "Dead state rejects any following damage synchronously")
	paused = false
	# 同帧的旧停用请求不得盖过新恢复请求，动量恢复只在真实解冻时结算。
	if body != null:
		var pivot = pivots[0]
		pivot.set_active(true)
		pivot.set_active(false)
		pivot.set_active(true)
		await process_frame
		check(not body.freeze, "Newest activation wins over stale deferred freeze requests")
		pivot.set_active(false)
		await process_frame
		check(body.freeze, "Newest freeze request applies once")
	game.queue_free()
	await process_frame
	await physics_frame
