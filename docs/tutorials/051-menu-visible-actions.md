# 051 菜单点击部位与明显短动作

## 本轮解决什么

用户反馈“怎么点都不动”，本次检查的是正式菜单实际GUI点击，不把直接调用request_reaction当成端到端验证。本机LAPTOP-8GS4N5SG，Godot4.7.1标准版/Compatibility。当前用户配置只有音量0.8，没有减少动态选项，因此不能把这次现象归因于用户开启了减少动态。

原路径能命中角色，Native模型也能加载，但点击主要只改眼睑/嘴/腮红；除了招呼约3度的头部附加输入，其他反应没有明显头身动作。原生鼠标点头顶测试测得旧AngleY从2.823至2.896，约0.07度，肉眼几乎不可见。另外旧2.1秒忙碌期会静默忽略多数新点击，提示也没有明确部位与回应。

现有原motion只包括Idle和较长举手/狗尾草/竖指切换，不适合直接当短点击动作。驱动又每帧hold Angle/Position，直接播放同ID motion会争抢。没有强行接长举手，也没有下载新SDK、模型或改.local资源。沿用作者已验证的AngleX/Y/Z与PositionX/Y/Z输入，让原Cubism物理/变形器负责真实头身输出；没有移动角色根节点、旋转整张立绘或自建骨骼solver。

## 玩家怎样操作

左右以玩家看屏幕的方向为准，映射固定，不再随机轮替。

| 输入位置/方式 | 可见回应 |
| --- | --- |
| 点头顶/头发上部 | 闭眼笑，两次短点头 |
| 点屏幕左侧脸颊 | 单眨眼、向左歪头 |
| 点屏幕右侧脸颊 | 鼓脸、轻轻摇头 |
| 点上半身衣服 | 微笑鞠躬招呼，身体轻摆 |
| 1.4秒内连点三次 | 温和惊讶，轻后仰再回正 |
| 按住头发超过0.2秒，横向抚摸后松开 | 闭眼随抚摸轻摆 |

菜单左下两行列出这些操作，下面显示“点头微笑”等已收到的回应。连点太快会显示“已经收到啦”；减少动态开启时显示原因并指引去设置关闭。说明没有包含源码/导出等实现细节。

## 文件与流程

menu_character_view.gd继续把菜单坐标映射到720逻辑画布，并检查当前帧真实alpha。点击必须从角色不透明区域按下，并在角色上松开；透明空白和左侧导航按钮不会变成角色热区。脸颊进一步按canonical x=360区分左右；头顶/脸/上半身保留原有y分区。抚摸使用真实按住时间及超过16逻辑像素的位移，优先映射pet_sway。

menu_character.gd把安全状态映射到短的头/身体输入曲线，使用0.15秒淡入、0.35秒淡出和0.07/0.12秒平滑。反应期间头部跟随权重降到20%，避免追鼠标抵消点头；眼神仍独立跟随。新点击在0.22秒短冷却后可打断上一个回应，三连点惊讶可即时升级，但不会反复重启同一惊讶。默认2.1秒后回idle。

main_menu.gd只新增固定操作说明和回应状态，没有改变开始/设置/退出导航。设置、失焦和减少动态立即清gesture_head/gesture_body与安全表情，连点队列也清空；恢复后不补发旧动作。key1黑脸与key6阴沉眼继续强制归零，旧危险profile不再接回。

## 检查器调参

MenuCharacter/Stage/Character的Gesture Head Degrees默认12度，控制点头、歪头、摇头；Gesture Body Strength默认5，控制作者身体输入。Response Seconds默认2.1秒。Head Follow Time与Eye Follow Time仍只控制跟随速度，角色根节点position不参与动作。修改幅度后要同时检查作者参数范围、头发/脸/手臂是否自然，不应为了更显眼解除黑脸保护或强写手臂输出。

## 验证证据

`tests/menu_character_actions.gd`使用Input.parse_input_event输入真实鼠标移动、按下、抬起，再经过GUI、透明命中和映射到Native模型；没有直接request_reaction。旧版原生先红灯1项，检出头顶没有明显点头。新版检查头部输入变化约22度、根节点位置不变、左右脸/上半身固定映射与参数时序，三连点、按住拖抚、短冷却打断、设置/失焦/减少动态，以及说明/状态/署名入屏且不相交。1280与1024窗口均原生通过。旧菜单28项、五表情21项原生回归也通过。

本机证据在.local/menu_actions_20261106：red.log、actions_final.log、actions_small.log、actions_mesh_final.log；head_8/20/32.png、left_cheek_*、right_cheek_*、upper_body_*、triple.png、stroke.png为真实菜单渲染帧；*_samples.json记录输入与桥接可读参数的时序。Native parameter Resource的ParamAngle等输出value不自动反映当前Cubism物理值，不能把它读0当成头没动，也不能伪造输出曲线。专项进一步读取model.get_meshes的真实头部/躯干网格顶点差异，配合截图核实渲染确有形变。测试日志中的MESH SHIFT是同一真实网格顶点的最大位移，不是立绘根节点平移。

运行方式（路径要在当前设备核实）：

```powershell
# $GodotExe使用当前机器已核实的4.7.1标准版绝对路径。
$probe = Start-Process -FilePath $GodotExe -ArgumentList '--path . --script tests/menu_character_actions.gd' -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput menu_actions.out -RedirectStandardError menu_actions.err
Get-Content menu_actions.out,menu_actions.err
if ($probe.ExitCode -ne 0) { throw '菜单动作专项失败' }
# 小窗口复验在ArgumentList末尾加： -- --small
```

此改动在源工程F5生效；旧EXE是旧快照，不会因源码更新自动变化。新的含Live2D本机体验包由根Agent单独构建验证。headless只能验证回退，不能替代Native动作观感。真实鼠标事件和截图仍不等于用户审美认可、真人连续长时间互动或解决既有完整L0内存/发行授权问题。
