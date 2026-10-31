extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Shop test timeout"); quit(1))
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var arena = load("res://scenes/roguelite/run.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var d = arena.director
	arena.get_node("AudioDirector").muted = true
	d.set_process(false)
	check(d.has_method("buy_shop"), "Shop transaction entry exists")
	if failures:
		quit(1)
		return
	d.pending.clear()
	d.enter_rest("shop")
	var quote: int = d.rest_revision
	check(not d.buy_shop("heal", quote), "Insufficient funds reject purchase")
	for id in range(10000, 10012):
		d.wallet.credit_kill(id)
	d.wallet.credit_kill(10000)
	check(d.wallet.balance == 12, "Kill income is unique")
	check(not d.buy_shop("heal", quote), "Full health rejects healing")
	d.health.hp = 2
	check(d.buy_shop("heal", quote) and d.health.hp == 4 and d.wallet.balance == 8, "Healing charges exact price and restores once")
	check(not d.buy_shop("heal", quote), "Healing stock cannot be purchased twice")
	var pending_before: int = d.rewards.pending
	check(d.buy_shop("upgrade", quote), "Upgrade purchase opens legal choice")
	check(d.state == d.State.UPGRADE and d.rewards.pending == pending_before and d.wallet.balance == 0, "Shop upgrade leaves kill queue intact")
	d.choose_upgrade(d.current_choices[0].id, d._choice_revision)
	check(d.state == d.State.SHOP and paused, "Shop reward returns to rest")
	check(d.chosen_rewards == 0 and d.rewards.progress == 0, "Shop reward preserves first kill reward guarantee and kill progress")
	check(not d.buy_shop("upgrade", quote), "Upgrade stock cannot repeat")
	d.restart()
	check(not d.buy_shop("heal", quote), "Old quote rejected after restart")
	arena.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("SHOP EVENT CHECKS PASSED: ", checks, " failures: ", failures)
	quit(0 if failures == 0 else 1)
