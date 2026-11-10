# 物理回调中的地图暂停

## 问题与真实触发链

发布前自然局`release-payoff-r1/baseline-fire-123456`出现Godot物理锁错误：危险弹的Area2D触碰玩家→扣最后一血→同步死亡→RunDirector.finish→MapController.set_active(false)→翻板的freeze写入。Godot正在刷新碰撞查询，不能在这个阶段改变刚体模式。原翻板set_active在基线`a494ad2`已是相同实现，因此是本批自然局新暴露的旧缺陷，不能把带ERROR的自然局写成通过。

## 文件、节点和修复过程

`scripts/roguelite/mechanisms/pivot_paddle.gd`控制PivotPaddle下的`Paddle`刚体与`Pin`关节。地图控制器仍同步广播活动状态：玩家死亡、地图active=false、整局结算和SceneTree暂停立即生效，不延后一帧死亡。

翻板收到停用时同步更新`active`，保存当前线速度/角速度，递增`_activation_revision`，然后用`_apply_active.call_deferred(revision)`排队改变物理模式。延后调用检查版本和节点生命周期，再写`Paddle.freeze`。只有物理刚体确实从冻结恢复时才还原保存动量；停→开在同一帧抵消时不会给仍活动的刚体重置速度。

为什么不能直接`set_deferred("freeze", true)`：同一帧可能已经恢复或换图，旧请求必须被取消；带revision的函数可以在执行前判断请求是否仍有效。已经退出场景树/排队删除的翻板也不再执行旧请求。

其他机关无需延后整套set_active：MovingBarrier、RotatingArc、SpikeStrip只改逻辑布尔值；PortalPair还同步撤销尚未积分的传送请求，不在这里改物理mode/monitoring。它们立即停逻辑是正确行为。以后给这些接口加物理属性修改时，应保持逻辑同步、只把受物理锁限制的部分延后。

## 调参与扩展

本修复没有改翻板质量、关节、角度范围和转速。仍可在检查器调整`length`、`angle_limit`、`initial_angle`及刚体脚本`max_angular_speed`。不要为了绕过锁把整个死亡/finish推迟，也不要用每帧改角度替代真实刚体。

需要增加暂停动画时，读取`active`发出只读表现请求；不要让动画结束回调解除整局暂停。新增reset/切图路径应保留版本检查，过期恢复请求不得复活旧机关。

## 复现与验证

本机引擎`C:/Users/Ziran/Desktop/Godot_v4.7.1-stable_win64.exe`，4.7.1.stable.official.a13da4feb。运行参数：`--headless --path C:/Users/Ziran/playAball --script tests/roguelite_pause_physics.gd`。使用当前机器核验后的路径，不把此开发机绝对路径写入游戏代码。

新增测试实例正式run场景，分别进入四张图（波1、3、5、6），把正式危险弹放在玩家处，由真实Area2D传感器造成最后一血死亡。检查死亡与逻辑暂停同步、物理freeze延后且在树暂停时完成、死亡拒绝后续伤害、所有机关逻辑停止，以及同帧停→开→停的版本处理。测试使用测试夹具设置生命和选地图，不冒充自然完整通关。

修复前最小测试7断言1失败、退出1，stderr稳定复现两次`body_set_mode`物理锁；日志`.local/pause-physics-red.out/.err`。修复后扩展到四图51断言0失败、退出0，无错误警告；日志`.local/pause-physics-green.out/.err`。

相关回归使用`--headless --fixed-fps 120 --path ... --script tests/<脚本>.gd`：map_mechanisms21、portals31、maps77、map_flow24、map_navigation50、map_blueprints85、paddle_response71全部退出0。日志`.local/pause-roguelite_<脚本名>.out/.err`。maps、map_flow、map_navigation仍可有既有ObjectDB2/4退出警告，未隐藏。全量回归和出错自然局的重跑结果由主Agent最终Review记录；此处不提前宣称通过。

## 常见错误

- 测试打印“通过”但stderr含ERROR：仍然失败，必须检查引擎日志。
- 把`finish`整体延后：死亡前后同帧可能继续触发玩法，扩大状态竞态。
- 只读freeze判断重复请求：freeze是延后应用的物理状态，不能当最新逻辑意图；使用active和revision。
- 解冻后速度变了：确认只在真实冻结→活动时还原保存动量，而不是每次set_active(true)都覆盖刚体速度。
