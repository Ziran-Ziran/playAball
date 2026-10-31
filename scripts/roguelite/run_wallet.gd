extends Resource
## 钱包单独去重，商店不会消费击杀领奖进度。
var balance: int = 0
var credited: Dictionary = {}
func credit_kill(instance_id: int) -> bool:
	if credited.has(instance_id):
		return false
	credited[instance_id] = true
	balance += 1
	return true
func spend(price: int) -> bool:
	if price < 0 or balance < price:
		return false
	balance -= price
	return true
func reset_wallet() -> void:
	balance = 0
	credited.clear()
