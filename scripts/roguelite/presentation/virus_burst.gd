extends Node2D
## 只在真实击破事件后生成数据碎片；数量与寿命有界，不参与伤害。
var art_id: String = "virus_low"
var tint: Color = Color("87dfbd")
var _life: float = 0.32
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("virus_bursts")
func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var fraction: float = clampf(_life / 0.32, 0.0, 1.0)
	var texture: Texture2D = DemoBallArt.animation_frame(art_id,2 if fraction>0.5 else 3)
	draw_texture_rect_region(texture,DemoBallArt.rect_for(texture,52.0+(1.0-fraction)*22.0),DemoBallArt.region_for(texture),Color(1,1,1,fraction))
	draw_arc(Vector2.ZERO, 12.0 + (1.0-fraction)*12.0, 0.0, TAU, 24, Color(tint,fraction*0.35),1.0,true)
