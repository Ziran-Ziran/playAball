# 项目概况

## 技术与入口

Godot **4.7.1 stable标准版**，2D、GDScript、Compatibility，物理120Hz。球使用RigidBody2D和冲量，表现不修改碰撞形状、质量或伤害规则。

F5：`project.godot → scenes/ui/main_menu.tscn → scenes/ui/game.tscn`。正式Game继承run_arena，由RunDirector协调波次、成长、休息与胜负；MusicManager常驻根节点。可选Live2D缺资源时静态回退，不影响开始/设置/退出。

## 玩法与地图

零伙伴开局，按速度分档撞击、伙伴传能和击杀成长。基础发射冷却2.2秒；运动中可再发射，冷却时可提前按住等候。就绪瞄准暂停战场，合法释放/取消恢复；菜单/成长/失焦按各自暂停所有权处理。

| 波次 | 地图内容 |
| --- | --- |
| 1–2 | 左右固定斜板、上横下竖中心轴翻板，中央出生 |
| 3–4 | X形翻板、沿世界Y对称移动斜板，左右分散短浅刺 |
| 5 | 旋转缺口弧、沿世界X对称移动刺板、左右保速传送 |
| 6 | 完整内圈四刺、四开口外圈和四向翻板；绿门上下互传，黄门左右互传 |

击杀门槛递增触发三选一，运筹可四选一；同帧奖励排队。阶段之间有商店/补给，完整规则由玩法校验，卡牌只展示真实收益。地图参数/复现见[041](tutorials/041-map-blueprint-correction.md)，成长与卡片见[037](tutorials/037-integrated-upgrade-cards.md)、[049](tutorials/049-card-content-flow.md)。

## 表现与交互

- 内置生成角色/病毒素材；伙伴按槽位、病毒按出生最大生命选稳定身份，掉血不换皮。肥鱼逐帧连续形变，短表情使用生成姿势，见[042](tutorials/042-ball-art-and-effects.md)、[050](tutorials/050-smooth-hero-animation.md)。
- Kenney CC0单体箭头与轻尾迹；全场瞄准暂停见[043](tutorials/043-tactical-aim.md)。
- 深海商店/补给/结算/暂停主题，文字按内容高度排布；标题使用OFL字体，完整说明保留。
- 菜单原模型参数驱动头眼/头身动作，保护黑脸参数，设置/失焦/减少动态阻断互动；操作表见[051](tutorials/051-menu-visible-actions.md)。
- MusicManager单播放器/独立Music总线，用户原曲循环；主音量与全部静音覆盖音效和音乐，配置合并保存，见[052](tutorials/052-persistent-music.md)。

## 模块与协作边界

玩法发布快照/事件；表现只读、UI发请求，由玩法校验伤害、经济、成长与生成。混合actor/HUD/运行接线仍按B线整文件单写，不按文件上下半段并写。计划与教程以[008分工](plans/008-parallel-development.md)、[020工作流](tutorials/020-parallel-workflow.md)为准。

开发工具：玩法实验室、实时调参、卡图鉴、原生角色/动画专项及导出包探针。早期侧视/三靶场和3D/Live2D样板保留作独立实验，不是正式F5入口；文件职责见[目录](FILE_MAP.md)。

## 当前边界

Windows x86_64为已验证平台；安卓需触控、横屏安全区、分档性能和原生库适配，尚未交付APK。私有模型/DLL仅本机准备；Native完整L0内存与手臂自然度未完成验收。音乐进程退出仍偶发MP3/Playback两引用，固定50ms回收不是所有驱动的完成确认；未见运行中跨场景累积。

完整功能、审查和未测项见[STATUS](STATUS.md)。自动回归/原生截图不等于真人自然通关、平衡完成或用户审美认可。旧文档原文见[整理前快照](history/development_before_20261106.md)。
