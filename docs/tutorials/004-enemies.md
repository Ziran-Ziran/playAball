# 004：三类敌人、攻击预警与玩家生命

本教程解释 P3 的敌人模块。它使用中性几何图形，不包含正式美术。整局刷怪、升级、首领与胜负流程由其他模块组织；这里的敌人只负责自己的受击与攻击，不重复结算球撞敌人的战斗伤害。

## 文件与节点

- `scripts/roguelite/enemy.gd`：`DemoEnemy` 继承共用物理刚体 `DemoBody`，包含三种 `Kind`、受击、一次死亡事件、AI 施力、预警与保龄球窗口。
- `scenes/roguelite/enemy.tscn`：可编辑的 `Enemy (RigidBody2D) → Shape (CollisionShape2D)`；默认圆形半径 22，重罐头实例单独复制形状后改为 30，不改其他实例共享的资源。
- `scripts/roguelite/player_health.gd`：`DemoHealth (Node)` 统一管理 5 格生命和 0.8 秒受伤无敌；`changed(hp)` 刷新 HUD，`died` 让整局组织者进入失败结算。
- `scenes/roguelite/hazard_ball.tscn` 和对应 `hazard_ball.gd`：`HazardBall (RigidBody2D) → Shape`，另有 `PlayerSensor (Area2D) → Shape`。刚体负责撞环境，传感器只检测主球。
- `tests/roguelite_enemies.gd`：不依赖整局刷怪的 headless 行为检查。

## 输入 → 逻辑 → 输出

场景组织者在把敌人加入树之前设置 `kind`、`player`、`health` 和 `hazards`。其中 `hazards` 是专门装危险弹的 `Node2D` 容器。敌人 `_ready()` 根据类型设置 1/4/2 HP，重罐头质量为 0.55，其他为 0.2（按扎堆撞停反馈下调，详见教程014）；所有敌人零重力、layer=8、mask=31，并进入 `demo_damageable` 组。

脆皮和重罐头通过 `apply_central_force()` 缓慢靠近主球，不每帧改位置。进入范围后保存当时方向，画空心橙色预警，等待 `warning_duration=0.8` 秒。脆皮在半径 90 内发出持续 0.16 秒的实心脉冲；重罐头一次注入冲量，开启 0.4 秒的接触危险窗口。普通身体接触不会伤主球。两者攻击后都有冷却，不能贴着玩家每帧开始新攻击。

炮手没有追踪引导力，停在炮位；它仍是可受撞击的物理刚体。炮手预警时锁定方向，预警后只发一枚 180 像素/秒的慢危险弹。危险弹离膛后不追踪玩家，碰玩家、碰环境或超过 5 秒寿命就消失。共同容器最多 12 个子节点，多个炮手共用同一上限；场景组织者在清波、失败、重开时统一清掉容器子节点。不要把临时敌人作为炮弹父节点，否则敌人死亡时会意外带走已发射的炮弹。

攻击通过同一 `health.hurt()` 请求伤害。函数只有在玩家存活、不处于无敌时间且伤害为正时返回 `true`；每次受伤先更新 HP，再发 `changed`，HP 归零只发一次 `died`。无敌计时在 `_physics_process` 中递减，因此应由游戏暂停一起停止，不另用真实时间后台计时。

## 关键接口与碰撞边界

球的碰撞伤害仍由统一 `collision_combat.gd` 解析后调用 `enemy.hurt(amount)`。有效命中会打断敌人预警和冲撞；HP 归零时先设置 `dead=true`，再发 `died(enemy)`，随后排队删除。整局统计应连接这个信号，不在多个接触回调中各数一次击破。

保龄球升级调用 `enemy.make_projectile(chain)`，仅存活敌人和正数来源编号有效。它给敌人 0.6 秒窗口和 2 次命中预算，清除当前敌方攻击；窗口内暂停 AI 施力，保留物理惯性。统一战斗解析器负责消耗 `projectile_hits_left`，限制不同目标与不传下一代。`attacking()` 同时检查存活、来源、窗口与预算，普通敌人不能因为移动得快就被当作友方攻击球。

危险弹使用 layer=32、mask=17（外围墙 1 与内部挡板 16）；玩家传感器 mask=2，只消费 `DemoPlayer`。小兵没有独立生命，不替主球挡伤害。危险弹被无敌玩家碰到也会消失，不在原地等待无敌结束后再次扣血。

## 在检查器中调参

打开 `enemy.tscn` 选择根节点。在实例上改 `Kind` 可切换剪影、HP、质量与攻击方式。`Warning Duration` 改预警时长，`Attack Cooldown` 改攻击间隔，`Approach Force/Speed` 改追踪力度与目标速度，`Pulse Radius` 改脉冲范围，`Charge Range/Speed` 改冲撞启动距离与冲量，`Hazard Speed/Limit` 改慢弹速度与容器上限（硬上限 12）。

打开 `hazard_ball.tscn` 可调 `Lifetime`、形状与环境碰撞。`DemoHealth` 可在检查器调 `Max Hp` 与 `Invulnerability`，修改最大 HP 后调用 `reset_health()` 开始新局。改参数后先观察预警能否读懂，再调整强度，避免直接加满敌人来测试难度。

## 扩展、复现与验证

增加敌人行为时，先加一个 `Kind`，给它独立剪影，再在 `_release_attack()` 添加预警结束后的动作。仍然共用 `hurt`、`DemoHealth` 和容器上限；不要新建另一套玩家扣血回调。加入新的危险弹形状时保留实心危险符号，使预警空心、攻击实心的语言一致。

本机验证命令（Godot 路径须在各电脑重新确认）：

```powershell
# Windows GUI 引擎必须等待实际进程，不能只根据 shell 启动成功判断通过。
$engine = '本机实际 Godot 4.7.1 标准版 exe 路径'
$process = Start-Process -FilePath $engine -ArgumentList '--headless --path . --script tests/roguelite_enemies.gd' -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput '.local/enemies.out' -RedirectStandardError '.local/enemies.err'
$process.ExitCode
Get-Content .local/enemies.out,.local/enemies.err
```

首次运行新脚本前先用 `--headless --path . --editor --import` 生成脚本 UID。完成标志为 `ENEMY CHECKS PASSED`，退出码 0，日志不能出现 `SCRIPT ERROR` 或 `ERROR`。测试将逻辑帧换算成实际物理频率，当前工程 120 Hz，不能把 48 个物理帧误认为 0.8 秒。

手动观察：先贴近脆皮，确认预警期间不扣血、实心脉冲才扣一格；观察胖罐头是否先指方向再直冲，绕开后不会在冲撞中继续追踪；让炮手先瞄准再横向移动主球，确认危险弹沿原方向飞行。主动撞击胖罐头应打断预警，重开后生命和危险弹恢复初始状态。headless 检查不代表这些可读性、手感或整局难度已经由玩家验收。

## 常见错误

- 没设置 `player/health/hazards`：敌人无法正常攻击；生成时在加入树之前注入引用。
- 绕过 `health.hurt()` 直接减 HP：会丢失无敌时间和一次死亡保证。
- 逐帧改敌人位置或炮弹方向：会绕过物理反弹，并破坏方向预警的承诺。
- 各炮手新建自己的容器：12 上限会变成每炮手 12；应共用整局 `Hazards`。
- 测试把玩家 `freeze=true` 又继续运行危险弹：冻结刚体不等同正常游戏状态，Area2D 不保证检测它；暂停应暂停战斗进程，清波/结算应清危险物。

生命组件由 RunDirector 在运行时创建。调试时使用 Godot 的 Remote 场景树找到该节点，在远程检查器调整只能临时生效；持久修改 max_hp/invulnerability 应改 player_health.gd 的导出默认值，或今后将节点序列化进场景。Local 场景树目前没有这个生命节点。

有效受伤后默认0.65秒硬直，暂不追踪/攻击，保留击退惯性。主球主动撞击另有短时有限续力，规则和调参见[014](014-crowd-impact.md)。

最新：离开各自攻击范围立即取消蓄力与危险窗口，重新进入完整蓄力；生命按剩余值分色并显示数字，详见[016](016-enemy-range-and-health.md)。普通敌人被撞飞不扣血的帧顺序问题见[018](018-contact-damage.md)。
