class_name DemoTarget
extends StaticBody2D
signal broken(target: DemoTarget)
@export var hit_points: int = 3
var hp: int
var dead: bool = false
func _ready() -> void:
	add_to_group("demo_damageable")
	hp = hit_points
func hurt(amount: int) -> void:
	if dead or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	if hp == 0:
		dead = true
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		broken.emit(self)
	queue_redraw()
func reset_target() -> void:
	hp = hit_points
	dead = false
	collision_layer = 8
	collision_mask = 6
	queue_redraw()
func _draw() -> void:
	if dead:
		draw_rect(Rect2(-24, 22, 48, 4), Color("775044"))
		return
	draw_rect(Rect2(-26, -30, 52, 60), Color("dc8753"))
	draw_rect(Rect2(-26, -30, 52, 60), Color("ffdf9a"), false, 2)
	for index in hp:
		draw_circle(Vector2(-14 + 14 * index, 0), 3, Color("fff1c9"))
