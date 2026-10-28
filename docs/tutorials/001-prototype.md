# 教程 001：从发射到碰撞的第一版原型

本版目的是验证“击球是否清楚、反弹是否有反馈”，还不是最终关卡或美术。只使用 Godot 自带组件；打开根目录 project.godot 后 F5。

## 1. 场景像搭积木

`scenes/main.tscn` 是主场景：地面/左右墙/障碍为 `StaticBody2D`，代表不移动的实体；球从 `scenes/ball.tscn` 实例化，使用 `RigidBody2D`；目标和机关是 `Area2D`，只检测进入，不挡住球；Camera2D 看世界，HUD 使用 CanvasLayer 固定在窗口上。

每个实体的 CollisionShape2D 决定碰撞形状。Polygon2D/Line2D 只负责外观，两者不会自动同步。初始坐标范围 1280×720，Y 向下增加，所以负 Y 方向是向上。

如何改障碍：在左侧场景树选择 Obstacle，用移动工具改位置；修改其 Shape 的 RectangleShape2D.size 改实体尺寸，同时修改 Visual 的多边形和 Edge 的点。建议先复制一个完整 Obstacle 节点，再移动它，避免只复制了外观而没有碰撞。不要在运行时随意移动静态障碍。

## 2. 球为什么能动

`scripts/ball.gd` 继承 RigidBody2D。引擎计算重力、速度和碰撞，代码负责何时给它冲量。`can_launch()` 要求球速度低于 stop_speed 且连续维持 settle_time；这避免玩家在飞行途中追加无限动力。

`main.gd` 捕获鼠标：按下时确认点在球附近；拖拽方向为“球位置减鼠标位置”，所以向左下拉会向右上打。松手调用 `ball.launch(drag)`，成功后才增加杆数；右键、失去焦点或 R 会取消拖拽。点击位置使用事件自身坐标转换到世界，避免快速输入时读到另一位置。

核心公式：
```gdscript
drag.limit_length(max_drag) * max_impulse / max_drag
```
先把拖拽长度限制在 max_drag 内，再按比例换算冲量。最后使用 `apply_central_impulse()`；只在松手时调用一次。刚体质量越大，同样冲量带来的速度越小。

如何调：打开 ball.tscn，选择根 Ball，在检查器的脚本导出项调整 Max Impulse（最大力度，默认 1050）、Max Drag（拖满距离 180）、Stop Speed（停稳阈值 22）和 Settle Time（0.3 秒）。Physics Material Override 下的 Bounce 是反弹，Friction 是摩擦；Base Damping 控制运动衰减。每次只改一个值并试玩比较。

力度条显示当前拖拽百分比，虚线点是无阻尼、无障碍、正常重力的短期抛物线提示，**不是准确落点预测**，不预测碰撞或机关。

## 3. 碰撞如何变得“有感觉”

`ball.gd` 在 `_integrate_forces()` 里读取真实接触，开启 contact_monitor/max_contacts_reported 和连续碰撞检测。用接触冲量/质量与上一物理帧的入射法线速度取较大值，作为表现强度估计。当前后端的接触冲量读数不能单独保证触发效果；速度补足解决这一点。它不是精确测量的物理能量。

超过 impact_threshold 才发出 impacted 信号，0.09 秒冷却抑制重复触发。信号延后发出，让物理回调里不直接添加节点。`main.gd` 把此信号连接到 `impact_feedback.gd`，后者播放：扩散亮环、CPUParticles2D 火花、Camera2D 轻震动、合成短碰撞音。临时节点播放完会释放。

如何改：Ball → Impact Threshold 控制触发门槛；Main → ImpactFeedback → Shake Amount 控制震动。游戏内可关闭声音/震动。亮环是绘制的发光感占位表现，不是真实 PointLight2D 灯光。要换正式音效，把授权的 wav/ogg 放入 `assets/audio/`，将 feedback 的 `_sound` 从生成 WAV 改为 preload 资源，保留强度对音量/音高的映射。不要把音效逻辑写进球的物理公式。

## 4. 机关如何影响球

`scenes/mechanism.tscn` 根节点 Area2D 使用 `scripts/mechanism.gd`。进入时记录球，离开时恢复默认阻尼和正常重力。每个物理帧根据 Kind 选择：Boost 连续施力向右；Sticky 增大 linear_damp；Reverse Gravity 将 gravity_scale 设为负数。

在 Main 选择 Mechanism，改 Boost Force、Sticky Damping、Reversed Gravity 或 Zone Size 即可调参。Shape 会根据 Zone Size 在运行时生成，所以编辑器内看不到最终区域图形；运行后会看到。游戏下拉框切换模式时自动重置本轮。

扩展：新增枚举值，在 match 分支写入作用，更新区域颜色/符号和下拉选项，然后添加测试与教程。当前只设计了一个区域；多个区域重叠时，退出恢复逻辑会互相覆盖。要做组合机关，先实现统一的状态叠加规则，再复制多区域。

## 5. 目标、重置与防卡住

球进入右侧 Goal 的 Area2D 后设置 won/completed，延后冻结球，并显示进球提示。判定为接触目标区域即可，不要求停留或整球落入。这一规则后续可改成“低速停留若干秒”。

R/重置按钮清空杆数和拖拽。球通过 reset_ball 请求复位，在 `_integrate_forces()` 中设置 transform 和速度，避免在普通帧回调里硬改刚体位置。越出安全边界自动重置，防止重力机关把球永久送走。球使用连续形状检测和 120 Hz 物理来减少高速穿透，速度上限 1500。

如何改目标位置：目前同时改 `Goal.position` 与 main.gd 中 `_draw()` 的目标环位置；视觉和传感器尚未封装为目标独立场景。下一次关卡编辑工作优先做这项封装。

## 6. 验证自己的修改

Windows 用 `tools/verify.ps1 -GodotExe '实际绝对路径'`。它导入工程、检查日志和运行 `tests/smoke.gd`，不要求安装测试插件。Godot 有时会在脚本导入报错后仍返回 0，所以脚本额外检查 ERROR 字样。GitHub Actions 在 Linux 用相同版本自动检查。

smoke 验证停稳、零拖拽、冲量上限、飞行中禁止发射、真实落地碰撞事件、复位、三种区域进入/离开、目标和胜利后禁止发射。它不代替人耳听音和主观手感判断。

人工清单：F5 → 停稳后拖球发射 → 观察力度/方向 → 碰撞有闪光/火花 → R 可反复重试 → 切换三种机关 → 进入目标显示胜利 → 关闭声音/震动可生效。提交前按 `CONTRIBUTING.md` 更新状态和教程。

继续学习可阅读 Godot 官方 [RigidBody2D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody2d.html) 和 [Area2D](https://docs.godotengine.org/en/4.7/classes/class_area2d.html) 文档；注意选择与工程一致的 4.7 文档版本。
