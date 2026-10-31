class_name DemoUpgrade
extends Resource
## 数据资源只描述卡片；选择后的生命与节点变化由竞技场统一应用。
@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var max_level: int = 1
@export_enum("机动", "火力", "伙伴", "生存", "节奏") var category: String = "火力"
@export_range(0.01, 10.0) var weight: float = 1.0
