# 043 瞄准决策静止与流动箭头

## 目的与文件

准备好的一次发射进入瞄准后，战场真正静止，给玩家决策时间。`launch_controller.gd`管理暂停所有权与输入；`run_director.gd`阻止一直运行的导演推进战斗时钟；`arena.gd`组织单体箭头组件与松手缩回。正式`scripts/ui/game.gd._draw()`调用相同`_draw_aim_feedback()`委托，不能保留另一份旧绘制覆盖新效果。没有清零刚体速度，也没有修改Engine.time_scale。

## 输入 → 暂停/恢复 → 输出

左键请求先记录屏幕锚点。冷却未好时只保留按住状态，冷却继续；就绪回调才进入aiming并暂停SceneTree。球、敌人、机关、弹体与地图使用PAUSABLE，暂停后物理服务器保留现有动量。导演是ALWAYS节点，所以advance另检查树暂停，刷怪和预警计时不会偷偷推进。发射器也检查树暂停，第二发储能不能在决策时间内恢复。

输入和HUD保持ALWAYS。右键取消释放本次瞄准拥有的暂停；松手先取消再沿原规则注入冲量。Esc、成长或结算通过set_blocked(true)接管暂停，取消不能把它们解除。失焦取消瞄准；重开由既有流程重置。离开战场沿原出口清理暂停。

用户否定了最初五个重复小V的外观，本轮改为Kenney CC0单体素材：仅一个圆角粗实心箭头，配低透明柔和尾流和滑动亮点。组件为scripts/roguelite/presentation/aim_indicator.gd；正式Game与试验场共享接线。镜头统一负责缩放和旋转，松手后0.22秒缩回。新外观仍待用户审美评审。

## 检查器和修改

选择LaunchController，`Freeze While Aiming`默认开启，可关闭以比较旧玩法；`Cooldown`继续决定基础回能时间。在运行时检查器选择AimIndicator，`arrow_style`为Rounded默认圆角版或Navigation对照版；`face_clearance`控制头像留白，`arrow_size`等比缩放箭头。arena.gd中的`_aim_phase`推进速度为1.8，回弹时间为0.22；修改回弹时间须同时修改初始化值和归一化除数。视觉参数不应接入伤害、速度或发射次数。

新增战斗节点须使用PAUSABLE或继承可暂停父节点；ALWAYS仅用于输入和界面。如果增加必须ALWAYS的战斗协调器，要像导演一样显式检查树暂停。外部暂停入口应先set_blocked(true)，再设置自己的暂停状态，解除时由该入口恢复，不能直接调用launch.cancel冒充解除菜单。

## 验证与限制

使用Godot4.7.1标准版：`--headless --path . --script tests/roguelite_tactical_aim.gd`。初次红灯三项：就绪瞄准未暂停、导演时钟推进、按住就绪未暂停。实现后退出0，覆盖真实运行帧内球位置/速度、刷怪时钟不变、取消恢复、等待不自锁、菜单接管和双发不回能。另运行roguelite_input_feedback（49项）与roguelite_launch_rewards（25项）均退出0。

手动检查：F5开始，空白长拖观察敌人与机关停住而箭头流动，右键恢复；发射后冷却中按住等待；再测试Esc、失焦、成长、重开和回菜单。自动状态测试不能替代完整人工试玩、审美验收或不同镜头配置下的截图检查；本子任务尚未完成这些人工项。

独立审查补充：导演的战斗脉冲寿命也必须在暂停时保留，不能只有战斗时钟停止而让脉冲消失。新增该断言先退出1，修复后退出0；正式测试同时覆盖箭头相位继续、短拖取消、有效发射及回弹、失焦与重开。

正式入口接线曾有两处漏项：Game的旧_draw覆盖实验场动画、受击闪光在ALWAYS节点下继续消退。正式Game回归先复现失败，再共用组件并冻结闪光。回弹方向使用本次实际release向量，不依赖上一渲染帧的pointer。

Kenney素材记录与许可见[素材来源](../../assets/ui/aim_kenney/SOURCE.md)。新增单头/原图朝向/旋转缩放/两款对照检查，并用真实Compatibility输出`.local/aim_rounded_game.png`及`aim_navigation_game.png`。发射后立即重开曾残留约0.2秒旧箭头，复位事件及aim_cancelled通知现统一清掉回弹、方向并隐藏；外部暂停接管也会清理，不能在新出生点播放上一局的发射。箭头资源是成熟外部素材，技术验收仍不等于用户审美认可。
