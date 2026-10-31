extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(20.0).timeout.connect(func(): quit(1))

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1

func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var health := DemoHealth.new()
	world.add_child(health)
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.freeze = true
	world.add_child(player)
	var hazards := Node2D.new()
	world.add_child(hazards)
	var probe: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	check(probe.has_method("tier_color"), "Enemy exposes remaining-health tier display")
	probe.free()
	if failures:
		world.free()
		quit(1)
		return
	for kind in 3:
		var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
		enemy.kind = kind
		enemy.freeze = true
		enemy.player = player
		enemy.health = health
		enemy.hazards = hazards
		enemy.set_physics_process(false)
		world.add_child(enemy)
		check(enemy.hp == [1, 4, 2][kind], "Kind %d preserves default health" % kind)
		var radius: float = [enemy.pulse_radius, enemy.charge_range, enemy.get("attack_range")][kind]
		player.position = Vector2(radius + 10.0, 0)
		enemy._physics_process(1.0)
		check(enemy.warning_left == 0.0 and not enemy.attack_active, "Kind %d cannot begin warning outside range" % kind)
		player.position = Vector2(radius - 1.0, 0)
		enemy._physics_process(0.01)
		check(is_equal_approx(enemy.warning_left, enemy.warning_duration), "Kind %d enters a complete warning inside range" % kind)
		enemy._physics_process(0.25)
		player.position = Vector2(radius + 1.0, 0)
		enemy._physics_process(0.01)
		check(enemy.warning_left == 0.0 and not enemy.attack_active and enemy.charge_left == 0.0, "Kind %d immediately cancels warning outside range" % kind)
		var shots: int = hazards.get_child_count()
		enemy._release_attack(Vector2(radius + 1.0, 0))
		check(not enemy.attack_active and enemy.charge_left == 0.0 and hazards.get_child_count() == shots, "Kind %d cannot release a stale out-of-range attack" % kind)
		player.position = Vector2(radius - 1.0, 0)
		enemy._physics_process(0.01)
		check(is_equal_approx(enemy.warning_left, enemy.warning_duration), "Kind %d reentry restarts the full warning" % kind)
		enemy._physics_process(enemy.warning_duration - 0.01)
		check(not enemy.attack_active and hazards.get_child_count() == shots, "Kind %d reentry never inherits elapsed warning" % kind)
		# 已经生效的近战窗口同样必须当帧取消；发出的炮弹仍独立飞行。
		enemy.warning_left = 0.0
		enemy._release_attack(Vector2(radius - 1.0, 0))
		var emitted: int = hazards.get_child_count()
		check(emitted == shots + 1 if kind == DemoEnemy.Kind.TURRET else enemy.attack_active, "Kind %d control attack really releases before cancellation" % kind)
		player.position = Vector2(radius + 1.0, 0)
		enemy._physics_process(0.01)
		check(not enemy.attack_active and enemy.charge_left == 0.0, "Kind %d cancels active attack outside range" % kind)
		check(hazards.get_child_count() == emitted, "Kind %d leaving range does not delete existing hazards" % kind)
		enemy.make_projectile(8)
		enemy._physics_process(0.01)
		check(enemy.attacking(), "Kind %d friendly bowling window survives distance checks" % kind)
		enemy.free()
	var tough: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	tough.set("hit_points_override", 6)
	tough.set_physics_process(false)
	world.add_child(tough)
	check(tough.hp == 6, "Explicit six-health override is applied before gameplay")
	var high: Color = tough.call("tier_color")
	tough.hurt(2)
	check(tough.hp == 4 and tough.call("tier_color") == high, "Six to four HP remains in the high tier")
	tough.hurt(1)
	var medium: Color = tough.call("tier_color")
	check(tough.hp == 3 and medium != high, "Three HP changes to the medium tier")
	tough.hurt(1)
	check(tough.call("tier_color") == medium, "Two HP remains in the medium tier")
	tough.hurt(1)
	check(tough.hp == 1 and tough.call("tier_color") != medium and tough.call("tier_color") != high, "One HP has a distinct low tier")
	world.free()
	print("ENEMY READABILITY CHECKS PASSED: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
