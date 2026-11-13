# 008：白饭吸力与回血

白饭是战斗中的生命补给：受伤时每 12 秒尝试生成一碗，吃到默认恢复 1 点生命，最多回到生命上限。满血和死亡时不生成，也不积攒刷新时间；重新受伤后等待完整周期。已经出现的白饭仍保留到拾取或 8 秒到期，满血拾取没有额外收益。原来的冷却返还和“饱饭撞”加伤已取消。

## 文件与节点

- `scripts/roguelite/rice_manager.gd`：运行时创建的 `RiceManager (Node2D)`，负责生命门槛、周期、安全位置、回血与重开清理。
- `scenes/roguelite/rice_lure.tscn`：`RiceLure (Area2D) → Shape (CollisionShape2D)`，负责真实身体接触。
- `scripts/roguelite/rice_lure.gd`：200 像素局部吸力、8 秒寿命、一次拾取和饭碗蒸汽绘制。
- `scripts/roguelite/run_director.gd`：将同一份主球、`DemoHealth`、敌人和地图绑定到管理器，连接吃饭反馈。
- `tests/roguelite_rice.gd`：满血/受伤/死亡门槛、回血上限、通知、吸力、障碍、过期、暂停和清理；整局接线另见 `tests/roguelite_run.gd`。

## 输入 → 逻辑 → 输出

`configure(player, health, enemies)` 接收主球、生命组件和敌人容器；也可在加入树之前直接绑定属性。定时器按战斗物理时间累积，`_needs_healing()` 确认生命存在且 `0 < hp < max_hp`。定时与直接 `spawn_rice()` 都经过门槛，防止其他调用绕过满血限制。

落点按候选顺序轮换，避开主球 180 像素内、边界、墙/箱体/挡板与敌方预警。地图通过 `point_safe()` 复核。候选都不安全就等下一周期；场上最多一碗。

饭碗每物理帧用 `apply_central_force()` 轻推主球朝碗移动，不修改位置、速度或碰撞层，不吸伙伴和敌人。刚体仍被墙挡住。拾取先置 `consumed=true` 去重停力，再发 `collected`；管理器再次核对当前碗、生命和场景有效性，执行 `min(max_hp, hp + heal_amount)`，发 `health.changed` 更新生命UI及 `eaten(point)` 反馈，不发受伤事件。饭碗延迟移除，避免在物理回调中直接移除碰撞体。

暂停会冻结刷新和饭碗寿命；重开、换图或休息通过 `reset_rice()` 清理碗与计时器。最后一秒只闪烁，不移动拾取区域。

## 调参与扩展

运行后在 Remote 场景树的 RunDirector/RiceManager 检查器调整 `heal_amount`（默认 1）、`spawn_interval`（12 秒）、`player_clearance`（180 像素）、`safe_bounds`、`spawn_points`。永久调整改脚本默认值；管理器由代码创建，Local 树没有这个节点。饭碗根节点的 `lifetime`、`attraction_radius`、`max_force` 可在 `rice_lure.tscn` 持久调整。

扩展治疗时保持生命上限和死亡门槛，不直接操作HUD。修改落点时同时检查地图障碍和预警范围。表现层仅消费信号，不计算治疗。

## 复现与验证

使用当前机器核实的 Godot 4.7.1 标准版路径：

```powershell
& $GodotExe --headless --path . --script tests/roguelite_rice.gd
& $GodotExe --headless --path . --script tests/roguelite_run.gd
```

手动运行完整局：满血等待至少 12 秒应无饭；受伤后等 12 秒，靠近饭碗检查物理吸引、碰碗回 1 血，冷却不变。另用其他治疗先回满血，已有饭不应超量回血。隔墙、暂停恢复和重开分别检查不穿墙、寿命冻结和无残留。自动测试不替代实际操作手感验收。

常见错误：只在定时器判断满血会让直接生成绕过规则；治疗后忘发 `changed` 会导致HUD不更新；复用 `damaged` 会误播放受伤动画；用真实时间计时会使暂停期间饭过期；在 `body_entered` 直接移除节点会触发物理回调错误。
