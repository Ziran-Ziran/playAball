extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): push_error("Enemy test timeout"); quit(1))

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in ceili(count * Engine.physics_ticks_per_second / 60.0):
		await physics_frame

func run() -> void:
	for path in ["res://scripts/roguelite/player_health.gd", "res://scenes/roguelite/enemy.tscn", "res://scenes/roguelite/hazard_ball.tscn"]:
		check(ResourceLoader.exists(path), "P3 resource exists: " + path)
	if failures > 0:
		quit(1)
		return
	var arena := Node2D.new()
	root.add_child(arena)
	var health = load("res://scripts/roguelite/player_health.gd").new()
	arena.add_child(health)
	check(health.hp == 5 and health.max_hp == 5, "Health starts with five cells")
	check(health.hurt() and health.hp == 4, "Attack removes one cell")
	check(not health.hurt() and health.hp == 4, "Invulnerability blocks immediate duplicate attack")
	health._physics_process(0.81)
	check(health.hurt(10) and health.hp == 0, "Damage clamps at zero")
	check(not health.hurt(), "Dead player cannot take damage again")
	health.reset_health()
	var health_deaths: Array = []
	health.died.connect(func(): health_deaths.append(true))
	health.hurt(20)
	health.hurt(20)
	check(health_deaths.size() == 1, "Health death signal fires exactly once")
	health.reset_health()
	check(health.hp == 5 and health.hurt(), "Reset clears invulnerability and restores health")
	health.reset_health()
	var player: DemoPlayer = load("res://scenes/roguelite/player_ball.tscn").instantiate()
	player.position = Vector2(300, 300)
	player.freeze = true
	arena.add_child(player)
	var hazards := Node2D.new()
	arena.add_child(hazards)
	var enemies: Array = []
	for kind in 3:
		var enemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
		enemy.kind = kind
		enemy.player = player
		enemy.health = health
		enemy.hazards = hazards
		enemy.position = Vector2(900 + 150 * kind, 300)
		arena.add_child(enemy)
		enemies.append(enemy)
	await frames(2)
	check(enemies[0].hp == 1 and enemies[1].hp == 4 and enemies[2].hp == 2, "Three kinds have 1/4/2 HP")
	check(enemies[1].mass > enemies[0].mass, "Heavy enemy has greater mass")
	check(enemies[0].gravity_scale == 0 and enemies[0].collision_layer == 8 and enemies[0].collision_mask == 31, "Enemy uses zero gravity and combat obstacle layers")
	var turret_start: Vector2 = enemies[2].position
	await frames(35)
	check(enemies[0].linear_velocity.x < -1, "Fragile enemy approaches by physical force")
	check(enemies[2].position.distance_to(turret_start) < 0.1, "Turret stays at its gun position without self propulsion")
	check(hazards.get_child_count() == 0 and health.hp == 5, "Warning has no damaging projectile before 0.8 seconds")
	await frames(30)
	check(hazards.get_child_count() == 1, "Turret emits one slow hazard after warning")
	var shot = hazards.get_child(0)
	var locked_direction: Vector2 = shot.linear_velocity.normalized()
	player.position = Vector2(300, 500)
	await frames(4)
	check(shot.linear_velocity.normalized().dot(locked_direction) > 0.999, "Hazard direction stays locked after target moves")
	check(shot.gravity_scale == 0, "Hazard has no environment gravity")
	enemies[2].set_physics_process(false)
	player.freeze = false
	shot.queue_free()
	var contact_shot = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	contact_shot.health = health
	contact_shot.position = player.position - Vector2(80, 0)
	contact_shot.linear_velocity = Vector2(180, 0)
	hazards.add_child(contact_shot)
	await frames(25)
	check(health.hp == 4, "Real hazard overlap damages player once")
	for enemy in enemies:
		enemy.set_physics_process(false)
	var fragile = enemies[0]
	fragile.make_projectile(7)
	check(fragile.attacking() and fragile.projectile_hits_left == 2, "Bowling window carries chain and two hit budget")
	fragile.projectile_hits_left = 0
	check(not fragile.attacking(), "Bowling cannot attack after hit budget is exhausted")
	fragile._physics_process(0.61)
	check(not fragile.attacking(), "Bowling attack expires after 0.6 seconds")
	fragile.make_projectile(0)
	check(not fragile.attacking(), "Missing source chain never enables enemy attack")
	var deaths: Array = []
	fragile.died.connect(func(enemy): deaths.append(enemy))
	fragile.hurt(1)
	fragile.hurt(1)
	fragile.make_projectile(9)
	check(fragile.dead and deaths.size() == 1, "Death signal fires once")
	check(not fragile.attacking(), "Dead enemy cannot become bowling projectile")
	# 单独检验近身预警，不依赖整局刷怪或碰撞解析器。
	var close_enemy = load("res://scenes/roguelite/enemy.tscn").instantiate()
	close_enemy.player = player
	close_enemy.health = health
	close_enemy.hazards = hazards
	close_enemy.position = player.position + Vector2(45, 0)
	arena.add_child(close_enemy)
	health.reset_health()
	await frames(30)
	check(health.hp == 5, "Ordinary close body contact does not hurt during warning")
	await frames(30)
	check(health.hp == 4, "Fragile pulse damages only after visible warning")
	close_enemy.queue_free()
	# 重罐头冲撞先警告，再产生有限时间危险窗口。
	var heavy = enemies[1]
	heavy.reset_body(player.position + Vector2(150, 0))
	await frames(3)
	heavy.set_physics_process(true)
	await frames(35)
	check(not heavy.attack_active, "Heavy charge is harmless during warning")
	await frames(18)
	check(heavy.attack_active and heavy.linear_velocity.x < -100, "Heavy charge releases physical impulse after warning")
	await frames(35)
	check(not heavy.attack_active, "Heavy damaging charge has a bounded duration")
	heavy.set_physics_process(false)
	heavy.warning_left = 0.5
	heavy.hurt(1)
	check(heavy.warning_left == 0.0 and not heavy.attack_active, "Valid hit interrupts enemy warning and attack")
	for child in hazards.get_children():
		child.free()
	for index in 12:
		var filler := Node2D.new()
		hazards.add_child(filler)
	enemies[2].attack_left = 0.0
	enemies[2].warning_left = 0.01
	enemies[2]._physics_process(0.02)
	check(hazards.get_child_count() == 12, "Turret respects shared twelve-hazard cap")
	for child in hazards.get_children():
		child.free()
	hazards.position = Vector2(20, 30)
	var entered_positions: Array[Vector2] = []
	var entered_velocities: Array[Vector2] = []
	hazards.child_entered_tree.connect(func(child): entered_positions.append(child.global_position); entered_velocities.append(child.linear_velocity))
	enemies[2].attack_left = 0.0
	enemies[2].warning_left = 0.01
	enemies[2]._physics_process(0.02)
	check(entered_positions[0].distance_to(enemies[2].global_position + enemies[2].aim_direction * 43.0) < 0.1 and entered_velocities[0].length() > 100, "Hazard enters transformed container with final initial physics state")
	var detached_shot = hazards.get_child(0)
	hazards.remove_child(detached_shot)
	health.reset_health()
	detached_shot._on_player_entered(player)
	check(health.hp == 5, "Removed hazard cannot damage reset run through stale callback")
	detached_shot.free()
	var expiring = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	expiring.position = Vector2(100, 100)
	expiring.lifetime = 0.02
	hazards.add_child(expiring)
	await frames(4)
	check(not is_instance_valid(expiring), "Hazard lifetime cleans up missed projectiles")
	var wall := StaticBody2D.new()
	wall.position = Vector2(150, 100)
	wall.collision_layer = 16
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20, 100)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	arena.add_child(wall)
	var wall_shot = load("res://scenes/roguelite/hazard_ball.tscn").instantiate()
	wall_shot.position = Vector2(100, 100)
	wall_shot.linear_velocity = Vector2(180, 0)
	hazards.add_child(wall_shot)
	await frames(20)
	check(not is_instance_valid(wall_shot), "Hazard hitting internal obstacle cleans itself up")
	arena.queue_free()
	await frames(2)
	if failures == 0:
		print("ENEMY CHECKS PASSED: ", checks)
	quit(0 if failures == 0 else 1)
