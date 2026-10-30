# 009：肥鱼几何主题与机制分离

本篇介绍默认肥鱼的几何占位外观。没有使用网络图片、原作贴图或语音素材；白饭吸力与饱饭强化由独立机制管理，换色不改变物理行为。

## 文件与职责

- `scripts/roguelite/theme_definition.gd`：`DemoTheme` Resource，只存主题标识、名字与配色。
- `resources/roguelite/themes/fat_fish.tres`：默认资源，id 为 `fat_fish`，显示名为“肥鱼”。
- `scripts/roguelite/player_ball.gd` 的 `_draw()`：蓝色圆鱼、白肚、眼睛、尾鳍、碰撞表情、饱饭提示与能量环。
- `scripts/roguelite/companion_ball.gd` 的 `_draw()`：小鱼团子、出击尾迹和状态外圈。
- `tests/roguelite_theme.gd`：原有物理参数、资源引用、饱饭及主题替换的隔离检查。

场景的 RigidBody2D、Shape、Sensor 和 PhysicsMaterial 均保留原值。主球半径 23，小弟半径 14、传感器半径 17；主球 layer/mask 为 2/29，待命小弟为 0/25，环境重力为零。出击与跟随的状态逻辑不属于主题代码。

## 数据 → 绘图 → 玩家看到什么

主球和小弟各有 `@export var theme: DemoTheme`，默认加载同一个 fat_fish.tres。`_draw()` 读颜色并绘制，外部将 theme 设成 null 时回退默认资源。主题里没有质量、半径、冲量、伤害或冷却字段。

主球蓝色圆身、白肚与两个眼睛始终正向。速度只产生很轻的 X/Y 绘图拉伸，碰撞反馈期间短暂挤压并眯眼；调用 `draw_set_transform` 的作用域只覆盖鱼身，然后立刻恢复绘图变换，再画半径 29 的能量环。没有更改节点 scale、刚体 rotation、碰撞形状或位置。尾鳍限制在能量环内部，确保“就绪”和充能比例仍可见。

`well_fed: bool = false` 是主球的视觉接口。白饭机制把它设为 true 时，鱼肚出现饱饭弧线与金色闪点；机制消费强化后再改回 false。主题不返还冷却、不添加冲量、不扣敌人生命，也不自行消费此状态。设置后可调用 `queue_redraw()`；正常物理帧也会请求重绘。

小弟沿用待命的较暗配色，出击时改成暖色亮圈并显示朝速度反方向的短尾迹，取得跟随后处于 RETURNING 时用腹部小折线提示。脸不随尾迹旋转；小弟一直明显小于主球，不会通过换主题获得自动跟随。

## 检查器调节与扩展

在文件系统中选中 fat_fish.tres，在 Inspector 修改 player_color、belly_color、outline_color、energy_color、companion_color、active_color、well_fed_color。主球亮、小弟暗、敌方危险红的区分应保留，不要把暖色出击尾迹改成与敌方危险完全相同。

制作配色变体时复制 `.tres`，修改 id、display_name 和颜色，拖到主球、小弟的 Theme 属性。这里的 Theme 是 DemoTheme 资源，不是 Control UI 的 Godot Theme。运行时若只想改一个实例，应先 `duplicate()` 资源，避免修改共享资源后所有球同时变色。赋值或修改资源后请求重绘。

以后替换美术，可以继续让 `_draw()` 读取同一套语义色，或增加独立 Visual 子节点；保持脸朝向、能量环、受击表情和物理形状分离。维维美、呆猫仅是未来扩展方向，本次没有实现其外观或专属机制。

## 验证与复现

当前电脑先查明 Godot 4.7.1 stable 路径，保存为 `$godotExe`，在工程根目录运行：

```powershell
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --script tests/roguelite_theme.gd
& $godotExe --headless --path . --script tests/roguelite_smoke.gd
```

主题测试先检查原有物理基线，再检查资源、默认引用和饱饭状态。随后切换饱饭提示与替换配色，比较质量、重力、层、mask、阻尼、半径、材质、位置、朝向、缩放和速度，确认主题不修改这些数据，也不改变待命/跟随状态。测试不把配色检查当作玩家视觉验收。

在编辑器运行主球接力场景，观察蓝色大鱼、较小鱼团子和外侧能量环；向上下左右发射，检查脸不随运动翻转、尾迹与速度一致、外圈仍清晰。再撞墙查看短暂眯眼/挤压，在完整局中吃白饭观察金色饱饭提示与实际强化消费保持一致。声音与震动关闭不应改变任何主题机制；该行为由对应机制测试验证。

## 常见问题

- 看不到配色变更：确认改的是实例引用的 DemoTheme，并请求了重绘；运行中对共享资源的更改会影响所有引用者。
- 鱼脸翻转：不要根据 linear_velocity 设置刚体 rotation；本实现只让尾迹沿速度，不让脸跟着转。
- 能量环变椭圆：检查画鱼后的 `draw_set_transform(Vector2.ZERO)` 是否保留，不能把环画在鱼身缩放作用域内。
- 饱饭图案不消失：检查白饭控制器是否在消费/重开后恢复 well_fed；主题只显示传入状态。
- 换外观后穿墙或小弟跟随：检查是否误改 Shape、mask 或 follow_enabled，主题替换本来只读配色。
