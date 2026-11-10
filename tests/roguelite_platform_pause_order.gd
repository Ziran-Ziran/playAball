extends SceneTree
## 验证平台通知不在通知栈恢复物理；Android self_list仍须真机/模拟器A/B验证。
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(25).timeout.connect(func(): quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	var game = load("res://scenes/ui/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	var d = game.director
	d.set_process(false)
	d.pending.clear()
	d.clear_container(d.enemies)
	game.set_paused(true)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(paused and d.state == d.State.PAUSED, "Back notification only queues resume; does not mutate paused within notification stack")
	check(game.has_method("_consume_platform_pause_intent"), "Platform intent has normal process consumer")
	if not game.has_method("_consume_platform_pause_intent"):
		paused = false
		game.free()
		quit(1)
		return
	await process_frame
	await process_frame
	check(not paused and d.state == d.State.BATTLE, "Queued Back resumes during normal idle process")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not paused, "Repeated Back notifications do not mutate tree before idle")
	await process_frame
	await process_frame
	check(paused and d.state == d.State.PAUSED, "Duplicate Back in one batch coalesces into one pause")
	game.set_paused(false)
	game.launcher.request_aim(Vector2(700, 450))
	game._touch_index = 0
	check(paused and game.launcher.aiming, "Fixture starts with real aim-owned pause")
	var shots: int = game.launcher.shots
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(paused and not game.launcher.aiming and not game.launcher.input_held, "Suspend cancels pointer synchronously without transient resume")
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = Vector2(900, 540)
	release.pressed = false
	game._input(release)
	game._unhandled_input(release)
	check(game.launcher.shots == shots, "Old touch release cannot fire while platform intent awaits idle")
	var press := InputEventScreenTouch.new()
	press.index = 1
	press.position = Vector2(700, 450)
	press.pressed = true
	game._unhandled_input(press)
	check(game._touch_index == -1 and not game.launcher.input_held, "New touch cannot take gesture ownership before pending suspend is consumed")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	await process_frame
	check(paused and d.state == d.State.PAUSED, "Suspend wins over Back in the same pending batch")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	d.restart()
	await process_frame
	await process_frame
	check(not paused and d.state == d.State.BATTLE, "Restart invalidates prior-run pending Back rather than pausing the new run")
	d.rewards.pending = 1
	d.open_upgrade()
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await process_frame
	await process_frame
	check(paused and d.state == d.State.UPGRADE and game.launcher.blocked, "Suspension preserves upgrade pause owner")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	paused = false
	root.remove_child(game)
	check(game._platform_pause_intents == 0, "Scene exit clears queued platform requests")
	game.free()
	await process_frame
	print("PLATFORM PAUSE ORDER CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)
