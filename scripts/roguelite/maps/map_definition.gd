extends Resource
## 出生/边界是玩法数据，不从场地背景图推算。
@export var map_id: String = "legacy"
@export var display_name: String = "原型围场"
@export var bounds: Rect2 = Rect2(40, 125, 1200, 553)
@export var player_spawn: Vector2 = Vector2(640, 540)
@export var boss_spawn: Vector2 = Vector2(640, 240)
@export var enemy_entrances: PackedVector2Array = PackedVector2Array([Vector2(140,220), Vector2(1140,220), Vector2(140,570), Vector2(1140,570)])
@export var safe_regions: Array[Rect2] = [Rect2(560, 480, 160, 140)]
