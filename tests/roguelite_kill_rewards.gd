extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func run() -> void:
	check(ResourceLoader.exists("res://scripts/roguelite/kill_rewards.gd"), "Kill reward progress resource exists")
	if failures:
		quit(1)
		return
	var progress = load("res://scripts/roguelite/kill_rewards.gd").new()
	check(progress.next_target() == 6, "First reward requires six kills")
	for id in range(1, 6):
		progress.add_kill(id)
	check(progress.pending == 0 and progress.progress == 5, "Fewer than threshold kills do not award")
	progress.add_kill(6)
	check(progress.pending == 1 and progress.progress == 0 and progress.next_target() == 8, "Threshold earns one reward and advances target")
	check(not progress.add_kill(6) and progress.kills == 6, "Duplicate death never counts twice")
	for id in range(7, 19):
		progress.add_kill(id)
	check(progress.pending == 2 and progress.progress == 4 and progress.next_target() == 10, "Burst kills preserve overflow and queue multiple rewards")
	check(progress.consume_reward() and progress.pending == 1, "Selecting consumes exactly one pending reward")
	check(progress.consume_reward() and not progress.consume_reward(), "No pending reward can be consumed twice")
	for id in range(19, 220):
		progress.add_kill(id)
	check(progress.next_target() == 16, "Reward threshold has bounded growth")
	progress.reset_progress()
	check(progress.kills == 0 and progress.pending == 0 and progress.progress == 0 and progress.earned == 0, "Restart clears kill reward economy")
	check(progress.add_kill(6), "New run does not inherit death deduplication")
	progress.first_target = 0
	progress.increment = -2
	progress.target_cap = 0
	check(progress.next_target() >= 1, "Invalid tuning cannot create a zero-cost reward loop")
	if not failures:
		print("KILL REWARD CHECKS PASSED: ", checks)
	quit(0 if not failures else 1)
