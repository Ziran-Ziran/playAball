extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
 call_deferred("run")
 create_timer(20).timeout.connect(func(): quit(1))
func check(ok: bool, message: String) -> void:
 checks += 1
 print("PASS: " if ok else "FAIL: ", message)
 if not ok: failures += 1
func run() -> void:
 var world := Node2D.new()
 root.add_child(world)
 var health := DemoHealth.new()
 world.add_child(health)
 var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
 player.position = Vector2(400, 350)
 world.add_child(player)
 var combat := DemoCombat.new()
 world.add_child(combat)
 player.contact_report.connect(combat.resolve)

 var targets: Array[DemoEnemy] = []
 for i in 3:
  var enemy: DemoEnemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
  enemy.kind = DemoEnemy.Kind.HEAVY
  enemy.position = Vector2(575 + i * 62, 350)
  enemy.player = player
  enemy.health = health
  world.add_child(enemy)
  enemy.attack_left = 10.0
  targets.append(enemy)
 await physics_frame
 player.launch(Vector2(160,0), 1)
 var furthest: float = player.position.x
 for i in 60:
  await physics_frame
  furthest = maxf(furthest, player.position.x)
 print("MEASURE crowd max_x=", furthest, " final_velocity=",player.linear_velocity, " hits=",combat.events.size())
 check(furthest > 600.0, "Full launch drives into three heavy enemies instead of stopping at first contact")
 check(targets[2].position.x > 759.0, "Rear enemy is physically pushed by the packed group")
 check(player.position.x < targets[0].position.x, "Player stays behind the front enemy instead of tunneling through solids")
 check(not combat.events.is_empty(), "Real contact still applies collision damage")
 var enemy: DemoEnemy = targets[2] if is_instance_valid(targets[2]) else null
 if enemy != null:
  enemy.hurt(1)
  enemy.linear_velocity = Vector2.ZERO
  enemy._physics_process(0.05)
  check(enemy.get("stagger_left") != null and float(enemy.get("stagger_left")) > 0.0, "Hit enemy remains staggered rather than immediately chasing into player")
 check(player.has_method("sustain_enemy_impact"), "Player exposes bounded enemy impact drive")
 if player.has_method("sustain_enemy_impact"):
  player.reset_body(Vector2(400,350))
  await physics_frame
  check(not player.sustain_enemy_impact(123, Vector2.RIGHT), "Reset clears collision propulsion budget")
  player.freeze = true
  player.launch(Vector2(160,0), 2)
  player.linear_velocity = Vector2.ZERO
  var budget_before: float = player._drive_budget
  check(not player.sustain_enemy_impact(124, Vector2.LEFT), "Backwards contact cannot redirect launch propulsion")
  check(player.sustain_enemy_impact(125, Vector2.RIGHT), "Forward enemy contact can spend finite propulsion")
  var budget_after: float = player._drive_budget
  check(budget_after < budget_before and budget_after >= 0, "Collision propulsion consumes rather than replenishes budget")
  check(not player.sustain_enemy_impact(125, Vector2.RIGHT) and is_equal_approx(player._drive_budget, budget_after), "Same enemy cannot repeatedly grant propulsion")
  player._physics_process(0.7)
  check(not player.sustain_enemy_impact(126, Vector2.RIGHT), "Expired launch cannot gain late propulsion")
  player.launch(Vector2(160,0), 3)
  for id in range(200,210):
   player.linear_velocity = Vector2(-1000, 0)
   player.sustain_enemy_impact(id, Vector2.RIGHT)
  check(is_zero_approx(player._drive_budget), "Many distinct contacts exhaust the total impulse budget")
 world.queue_free()
 await process_frame
 print("CROWD CHECKS PASSED: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
