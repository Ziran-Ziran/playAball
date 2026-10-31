extends Resource
## 阶段仅组织现有波次；难度仍由波次的敌人组合与刷怪间隔决定。
@export var title: String = "初出鱼塘"
@export_range(1, 6) var first_wave: int = 1
@export_range(1, 6) var last_wave: int = 2
@export_enum("shop", "event", "finish") var rest: String = "shop"
