# 021：玩法与表现的最小接口

本教程对应计划008的S1，只拆当前并行开发必需的接点，不把全部actor重写成一套框架。正式入口仍是`scenes/roguelite/run.tscn`；A负责独立表现组件，B负责规则、物理和正式接线。旧暖色UI样板仍是已否决方向，不作为默认视觉。

## 1. 已落地的两类接点

### 敌人actor → 敌人表现

`scripts/roguelite/enemy.gd`继续拥有敌人生命、索敌、预警、攻击、硬直和刚体。它新增：

- `presentation_snapshot()`：返回只读字典，含实体ID、类型、当前/最大生命、死亡、预警剩余、攻击状态、硬直、朝向、速度和实际攻击范围。
- `presentation_changed(snapshot)`：状态变化时发布新快照。
- `presentation_event(event, payload)`：发布`initialized`、`hurt`、`warning_started`、`attack_released`、`attack_cancelled`、`died`等真实事件。

默认`DemoEnemyView`在`scripts/roguelite/presentation/enemy_view.gd`和对应场景中。它每帧读取快照并消费事件，只绘制方形/圆形/三角身体、预警和生命数字。绘制不再藏在`enemy.gd`的`_draw()`中。

A替换视觉时：

1. 新建独立`Node2D`表现场景，不修改敌人物体的`Shape`、质量、碰撞层/掩码或物理材质。
2. 提供`bind_source(actor)`，保存actor并调用一次`presentation_snapshot()`。
3. 连接`presentation_changed`与`presentation_event`；或每帧只读快照。
4. 在`scenes/roguelite/enemy.tscn`中替换`Presentation`子节点，保留节点名为`Presentation`。
5. 用固定生命和真实碰撞回归确认换图前后刚体签名相同。

不要从绘制脚本调用`hurt()`、修改`hp`、施加冲量或改碰撞形状。隐藏、缩放和换色只能作用于绘图节点。

### 正式生命面板 → HUD

`DemoHealthView`已经拆到`scripts/roguelite/presentation/health_view.gd`和同名场景。它只读取`DemoHealth.hp/max_hp/invulnerability_left`，通过`bind_source()`连接`changed`信号。`RunHUD.bind_health()`现在只把生命源转交给该组件。

A可以重做`health_view.tscn`的布局和样式，只要保留`bind_source()`及`snapshot()`，或者由B做一次整文件接线。奖励卡、结算和重开仍由`run_hud.gd`管理。

## 2. UI请求不直接改规则

奖励卡发出`upgrade_selected(id, offer_id)`，由`RunDirector.choose_upgrade()`再次检查状态、报价版本和当前候选。结算面板发`restart_requested`，现由`RunDirector.request_restart()`确认处在胜利/失败状态后执行。按钮本身不扣钱、不加血或跳阶段。

实验室面板同样只发`action_requested(action, payload, revision)`。任一参数、夹具、发射和预设请求都经`GameplayLab`白名单校验；旧revision请求会被拒绝。

扩展UI时应先列出“显示数据、发生事件、玩家请求”三类信息，再改代码。若表现需要新字段，先由B在玩法快照中增加并补测试，不让A自己维护可变化的数据副本。

## 3. 事件和拒伤证据

`DemoBody.contact_sampled`提供所有真实接触的速度、点、来源、目标和当时攻击资格。`DemoCombat.contact_outcome`由实际判定分支产生：

- `no_attack_qualification`
- `target_not_damageable`
- `speed_below_minimum`
- `pair_cooldown`
- `projectile_target_repeat`
- `projectile_hit_budget_exhausted`
- `accepted / valid_damage`

`DemoHealth.damage_rejected`补充玩家已倒下、非法伤害和无敌保护。表现和实验室只显示这些结果，不重新执行一次伤害判断。完整正式运行时默认不打开无攻击资格接触诊断；实验室会显式打开。

## 4. 最小替换示例

敌人表现最小绑定方式：

```gdscript
func bind_source(actor: Node) -> void:
	if actor.presentation_changed.is_connected(_on_changed):
		actor.presentation_changed.disconnect(_on_changed)
	actor.presentation_changed.connect(_on_changed)
	_on_changed(actor.presentation_snapshot())

func _on_changed(snapshot: Dictionary) -> void:
	hp = int(snapshot.hp)
	queue_redraw()
```

示例只允许表现消费者存在。若需要死亡动画，消费`presentation_event(&"died", payload)`；实际奖励和清波仍由原死亡回调处理。

## 5. 验证与边界

定向回归：

```powershell
Godot --headless --path . --script tests/roguelite_presentation_interface.gd
Godot --headless --path . --script tests/roguelite_enemy_readability.gd
Godot --headless --path . --script tests/roguelite_hud.gd
```

接口测试验证：替换视图后生命快照仍更新、质量/碰撞/材质签名不变、拒伤原因来自实际战斗分支、生命面板只读且可热绑定。`tools/verify.ps1`会统一运行。

当前只迁移了敌人actor和生命面板。玩家、伙伴、首领、`impact_feedback.gd`、音频和运行入口仍按计划由B单写；未迁移不代表已拆分。
