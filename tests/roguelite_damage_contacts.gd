extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
 call_deferred("run")
 create_timer(30).timeout.connect(func(): quit(1))
func run() -> void:
 for reversed in [false,true]:
  for gap in [0.5, 4.0, 20.0, 100.0]:
   for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
    var world:=Node2D.new()
    root.add_child(world)
    var p: DemoPlayer=load("res://scenes/roguelite/player_ball.tscn").instantiate()
    var e: DemoEnemy=load("res://scenes/roguelite/enemy.tscn").instantiate()
    var combat:=DemoCombat.new()
    world.add_child(combat)
    p.position=Vector2(600,350)
    e.position=p.position+direction*(45+gap)
    if reversed:
     world.add_child(e)
     world.add_child(p)
    else:
     world.add_child(p)
     world.add_child(e)
    e.set_physics_process(false)
    p.contact_report.connect(combat.resolve)
    for i in 3: await physics_frame
    p.launch(direction*160,1)
    for i in 35: await physics_frame
    checks+=1
    if is_instance_valid(e) and not e.dead:
     failures+=1
     print("FAIL: fragile survives full frontal launch order=",reversed," gap=",gap," dir=",direction," v=",p.linear_velocity," enemy_v=",e.linear_velocity," hp=",e.hp," chain=",p.chain_id," events=",combat.events)
    world.queue_free()
    await process_frame
 for reversed in [false,true]:
  for passive in [false,true]:
   var world:=Node2D.new()
   root.add_child(world)
   var p: DemoPlayer=load("res://scenes/roguelite/player_ball.tscn").instantiate()
   var e: DemoEnemy=load("res://scenes/roguelite/enemy.tscn").instantiate()
   var combat:=DemoCombat.new()
   world.add_child(combat)
   p.position=Vector2(600,350)
   e.position=Vector2(646,350)
   if reversed:
    world.add_child(e)
    world.add_child(p)
   else:
    world.add_child(p)
    world.add_child(e)
   e.set_physics_process(false)
   p.contact_report.connect(combat.resolve)
   for i in 3: await physics_frame
   if passive:
    p.apply_central_impulse(Vector2(1050,0))
   else:
    p.max_impulse=80
    p.launch(Vector2(160,0),1)
   for i in 40: await physics_frame
   checks+=1
   if not is_instance_valid(e) or e.dead or e.hp!=1:
    failures+=1
    print("FAIL: low-speed or passive contact gained unintended damage passive=",passive)
   world.queue_free()
   await process_frame
 print("DAMAGE CONTACT CHECKS PASSED: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
