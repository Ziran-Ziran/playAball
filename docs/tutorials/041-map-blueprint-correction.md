# 按四张示意图修改地图

## 为什么需要这次修正

旧地图实现了机关组件，但布局沿用过旧版取舍。本轮以用户重新给出的四图为准：第一图左右板固定；第二图只有两侧短浅刺；第三图从环心出发；Boss 绿门上下互传、黄门左右互传。入口仍是 F5 主菜单→开始，波1–2/3–4/5/6依次使用四图。

## 文件、节点与输入输出

`resources/roguelite/maps/*.tres`决定出生点；同名`scenes/roguelite/maps/*.tscn`决定真实几何。`RunDirector.start_wave`→`MapController.select_wave`加载场景，再通过物理状态接口把主球、伙伴放到安全位置。不要只移动贴图。

| 场景 | 主要节点与含义 |
| --- | --- |
| map_01 | LeftPaddle/RightPaddle为StaticBody2D固定斜板；UpperPaddle/LowerPaddle为中心轴真实翻板；主球(640,350)，位于上横板和下竖板之间。 |
| map_02 | CrossPivot初始45°，两根340长的臂共用一个刚体；MovingLeft/Right上下对称移动；仅保留左下(55,560)和右上(1225,240)两处36长、8深的短刺；主球在X上方(640,245)。 |
| map_03 | TwinArcs中心(640,400)也是出生点；初始角45°使缺口在左上、右下；两块水平刺板左右往返，上板刺朝下、下板刺朝上；Portals连接左右入口。 |
| boss_map | InnerRing为半径60、厚18的完整圆周，带四处向外短刺；OuterRing半径180、厚18，四个30°开口；四块翻板在上下左右。主球(150,590)、Boss(1110,230)分开出生。GreenPortals连接上下，YellowPortals连接左右。 |

固定板受撞后仍保持位置；翻板收到真实冲量后由RigidBody2D和PinJoint2D解算转动；尖刺接触主球后由共享生命组件决定扣血和无敌时间。移动板仍是AnimatableBody2D，不逐帧搬动动态刚体。

## 为什么以前会斜着运动

`moving_barrier.gd`用`Body.position = travel * sin(...)`运动，`position`是相对父节点的局部坐标。如果把整个MovingLeft旋转45°，它的局部“上下”也跟着旋转。

现在移动根节点保持0°，需要倾斜时只改其`Body.rotation`。这样第二图的`travel = Vector2(0,40)`保持世界上下，第三图的`Vector2(55,0)`保持世界左右；另一块使用相反travel，整个周期都中心对称，而不是只在初始帧对称。

## 检查器中如何调参数

- 翻板根节点：`length`、`initial_angle`、`initial_angular_velocity`、`angle_limit`；Paddle上的`max_angular_speed`控制转速上限，`angular_damp`控制停转。图一LowerPaddle保持中心轴`pivot_offset = (0,0)`；左右固定板没有旋转逻辑。
- 移动板：根节点的`travel`是行程半幅，`period`是一个往返周期；第二图倾斜只改Body，第三图Body保持水平。调整一侧时同步镜像另一侧。
- 尖刺：`length`和`tooth_depth`决定绘制与运行时伤害矩形；每个实例创建独立形状，避免调一处影响其他刺带。可编辑场景中的Shape也应保持相同尺寸及中心偏移。矩形尺寸为`(length,tooth_depth+5)`，中心Y为`(5-tooth_depth)/2`。空档必须用独立刺带，不要在长伤害矩形上只隐藏几个齿。
- 圆环：`angular_speed`是弧度/秒，`initial_angle`是初始角度。修改半径、厚度或开口时，同时修改每段CollisionPolygon2D和Visual的点。内外圈分别为0.07和-0.045弧度/秒；第三图为0.1。
- Boss上下翻板：长度70，轴心Y为170/630。含板厚的完整扫掠半径约36.14，距环心230，外环外半径189，保留约4.86像素实体净空，且不越过外墙。图示本身允许调整上下比例；不能简单把180长横板旋转90°塞进去。
- 两组门：入口位置在A/B标记；`a_color/b_color`让同组同色，颜色仅供表现读取，不决定目的地。目的地始终为本组件内另一标记。门位于环间，出口法线沿切向留位，避免把身体放到封闭内圈或旋转外墙中；出口仍会二次复核堵塞。

传送只改变位置，保留速度、角速度、攻击链和伙伴状态；白名单仍为肥鱼、伙伴、普通敌人，不包含Boss和弹体。暂停、选卡或换图仍取消旧请求。

## 如何验证

使用本机实际Godot4.7.1路径运行：

```powershell
./tools/verify.ps1 -GodotExe '<本机Godot4.7.1可执行文件>'
```

新`tests/roguelite_map_blueprints.gd`先在旧布局上复现47项中43项失败；修正后94项通过，包括实际两组门的双向、三种身体搬移与保速，以及上下板完整扫掠净空。它已经加入verify与CI配置；本地运行不等于远端CI已执行。

`roguelite_map_navigation.gd`在真实碰撞空间采样0–88秒的12个角度：第三图从环心走到环外；Boss图从出生区走到环间，并确认不能走入封闭内圈。检查完整Boss的右上出生净空及圈外路线。它是离散静态快照，不是所有拥挤状态或自然通关的证明。

修改实例内部节点后保留`[editable path]`；maps用PackedScene重打包检查子节点，实包探针同步检查两处侧刺、四处Boss刺和两组门。本轮不重新发布EXE；已存在的builds成品不会自动更新。

手动复验时依次检查出生位置、轻撞翻板/固定板、第二图安全墙段与尖刺扣血、第三图环内外通行和双向传送、Boss同色互传、暂停恢复和重开。玩家仍需判断两侧短刺难度及完整Boss战手感，自动测试不替代这部分验收。
