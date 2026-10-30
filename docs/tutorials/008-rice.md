# 008：白饭吸力与一次“饱饭撞”

白饭把肥鱼主题变成一个可以主动利用的物理机制：主球路过时被轻轻吸偏，碰碗后返还部分发射冷却，下一次主动发射的首次有效命中额外增加 1 伤害。它不改变环境重力，不让初始小弟自动跟随，也不越过墙壁替玩家修正位置。

## 文件、节点与职责

- `scripts/roguelite/rice_manager.gd`：`RiceManager (Node2D)` 管生成周期、安全落点、最多一碗、强化绑定和重开清理。
- `scenes/roguelite/rice_lure.tscn`：`RiceLure (Area2D) → Shape (CollisionShape2D)`，半径 23 的拾取传感器，mask=2 只检查主球。
- `scripts/roguelite/rice_lure.gd`：`DemoRice` 管 200 像素范围的平面吸力、8 秒寿命、一次消耗、几何饭碗和蒸汽绘图。
- `tests/roguelite_rice.gd`：生成、真实物理吸力/挡墙、冷却、链路强化、暂停和移除清理的独立测试。

管理器通过 `configure(player, launcher, enemies)` 接收主球、发射控制器和敌人容器。也可以在加入场景之前直接设置同名公开属性。整局组织者连接 `launcher.fired` 到 `rice_manager.bind_launch`，有效主球或同伴命中时调用 `consume_bonus(chain)`，并把返回的 0 或 1 加到该次伤害。

## 输入 → 逻辑 → 输出

管理器按战斗物理时间累计 `elapsed`，每 12 秒尝试生成一碗。候选点在竞技场中部，依次轮换，避开主球 180 像素以内、地图边角、墙/箱体/挡板以及已激活的敌方预警方向。脆皮使用脉冲半径加安全余量；重罐头、炮手和首领用朝向走廊排除候选；首领震波预警也排除相应区域。所有点都不安全时，本次不生成，等下一周期，绝不把饭贴到主球身上。

`DemoRice.pull_force(point)` 计算“当前位置朝向饭碗”的向量，200 像素以外为零；范围内越接近饭碗，力越接近 `max_force=180`。每物理帧只调用主球的 `apply_central_force()`，不写 `position`、`linear_velocity` 或碰撞层。主球仍然受既有刚体碰撞约束，饭在墙另一边时吸力可能把鱼压在墙边，不会穿墙。小弟和敌人不收到这份力。

玩家传感器碰到主球时，先设置 `consumed=true`，立即停止吸力和重复拾取，再通知管理器。管理器调用 `launcher.refund_cooldown(0.6)`，发出 `eaten(point)` 供整局播放轻音，并储存一层强化。饭碗的物理节点延后退出场景，避免在 Area2D 接触回调中直接移除碰撞对象导致引擎报错。饭没有碰撞伤害，不应把吃饭音效伪装成撞击反馈。

8 秒到期也会停止吸力并移除饭碗。最后一秒只闪动透明度，不移动饭碗，不关闭拾取，已接近的玩家仍可碰到它。

## 强化为什么绑定发射链

`stored_bonus` 表示还有一层饱饭撞，`bound_chain` 表示它属于哪次新主动发射。吃饭时 `stored_bonus=true`、`bound_chain=0`，已有飞行链不能消费。

下一次实际发射后，`bind_launch(chain)` 才设置来源。统一战斗解析器在已经确认有效命中后调用 `consume_bonus(chain)`；只有来源匹配且还存有强化时，返回 1 并清空强化。主球和由它击出的同伴共享这一来源，所以同伴可先消费；其他旧同伴不行。若整条链没命中，下次实际发射会重新绑定同一层强化。按下瞄准、取消瞄准、静止接触和低于伤害阈值的碰撞都不消费。

再吃一碗仍然只储存一层，并要求新的主动发射；不能叠成无限额外伤害。整局重开或结算调用 `reset_rice()`，同时清除饭碗、周期计时、强化和绑定；管理器退出场景也会清理。旧饭碗的延后回调检查是否仍在场景树和是否仍为当前饭碗，不能给新局加成。

## 检查器调参和地图扩展

选择挂有 `rice_manager.gd` 的节点：

- `Spawn Interval`：尝试生成间隔，默认 12 秒。
- `Safe Bounds`：允许区域，默认 `Rect2(140,190,1000,430)`，把竞技场角落留在范围外。
- `Player Clearance`：距主球的最低生成距离，默认 180。
- `Spawn Points`：世界坐标候选数组；改地图时逐一移动到开放路线，再验证形状查询和敌方预警仍会排除危险点。

打开 `rice_lure.tscn` 选择根节点，可调 `Lifetime`、`Attraction Radius`、`Max Force`、`Show Radius`。先保留淡色调试圈，看鱼什么时候开始偏航；觉得控制被抢时先降力或半径，再观察路线。不要用增力来绕过墙壁，不要给同伴加入吸饭力来替代跟随升级。

饭碗和蒸汽由脚本绘制，替换主题外观时保持 Area2D 的形状、范围与主球物理逻辑。外观闪动只改显示，不能提前让碰碗失效。

## 复现与验证

Godot 固定 4.7.1 stable 标准版，先在当前电脑确认实际路径，再执行：

```powershell
$engine = '本机实际 Godot 4.7.1 标准版 exe 路径'
$process = Start-Process -FilePath $engine -ArgumentList '--headless --path . --script tests/roguelite_rice.gd' -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput '.local/rice.out' -RedirectStandardError '.local/rice.err'
$process.ExitCode
Get-Content .local/rice.out,.local/rice.err
```

新脚本首次导入使用 `--headless --path . --editor --import`。验收必须同时看到实际进程退出码 0、`RICE CHECKS PASSED` 和无 `SCRIPT ERROR/ERROR` 的日志；测试通过文字不能覆盖引擎错误。脚本会按实际物理频率换算等待，不能把 120 Hz 的帧数当成 60 Hz。

手动试玩时先等饭出现，观察主球经过淡圈时是否弯向碗，隔着内部挡板时是否被墙挡住；碰碗后观察发射冷却缩短，下一次发射命中时强化只用一次。再试先把同伴撞飞、随后吃饭，让那颗旧同伴命中，确认它不会消费新强化。暂停几秒再继续，饭的剩余寿命应保留；重开后不应残留饭或饱饭状态。自动测试不替代玩家判断偏航是否舒服、是否能主动利用饭碗。

## 常见错误

- 每次 `_process` 都设置球速度：会抢方向并覆盖物理结果；只施力。
- 吃饭后马上绑定 `player.chain_id`：会把强化交给旧飞行链；等待新的 `launcher.fired`。
- 还没确认有效伤害就调用 `consume_bonus()`：会在墙面或静止接触浪费强化；由统一战斗解析器在实际有效命中时调用。
- 用独立真实时间 Timer：会让暂停期间饭过期；管理器明确 `PROCESS_MODE_PAUSABLE`，饭随管理器暂停。
- 在 `body_entered` 里直接移除物理节点：引擎会报错；立即置 `consumed`，延后移除。
- 地图变化后只移动饭的默认点：还要复核安全矩形、障碍覆盖和敌方预警走廊。

RiceManager 由 RunDirector 在运行时创建，Local 场景树中没有该节点。可在运行后的 Remote 场景树临时修改检查器参数；持久调整生成周期/候选点应改 rice_manager.gd 的默认值，或今后保存为场景/资源。饭碗自身的力、范围和寿命可在 rice_lure.tscn 的根节点持久调整。
