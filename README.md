# 玩个球 / playAball

**验收状态：用户尚未验收本轮工作；当前生图明确不认可，留待后续对话修改。自动测试通过不代表用户认可。** 当前功能表及Buff效果见[项目概况](docs/PROJECT.md)。

PC 端俯视 2D 物理碰撞游戏。空白处拖动发射主球，通过撞击、伙伴接力和击杀奖励成长，经过三张普通地图与独立首领地图。

## 当前正式入口

2026-11-05：当前设备的F5开始界面已接入成年DeepSeek-chan Live2D，支持头眼分速注视、摸头/脸颊点击、连点回应与设置/失焦阻断。原开始/设置/退出和游戏流程保留。运行与调参见[教程040](docs/tutorials/040-live2d-start-menu.md)；第三方模型/Native资源仅在本机.local，未准备资源的checkout或普通包使用原静态角色，不代表取得发行授权。手臂自然度与完整L0内存问题尚未解决，3D封存。

在 Godot **4.7.1 stable 标准版**打开本目录的project.godot，F5进入肥鱼主菜单；开始后是零伙伴开局的完整流程。波1–2/3–4/5/6分别使用四张地图，保留成长、商店、补给、胜负、重开与回菜单。普通Windows包的当前版本与验证边界见[本地交付记录](docs/playtest/OVERNIGHT_DELIVERY.md)，解压后直接运行PlayABall.exe，不需安装Godot。

在战斗空白处按住左键，朝目标反方向拖动，松开发射；运动中可再次发射，右键取消，Esc暂停。基础冷却2.2秒，球外环显示恢复；青色双短弧只表示真实返回一格。普通包不含F1调参、实验室或评估脚本。

本轮翻转板轻碰/高速旋转修复、38套功能复验、71项挡板及98项成长接线证据见[功能复验记录](docs/reviews/2026-11-03-function-verification.md)；原理和参数见[教程033](docs/tutorials/033-paddle-response-and-feature-checks.md)。

## 修改与验证

- [项目概况](docs/PROJECT.md)、[最新状态](docs/STATUS.md)、[文件用途目录](docs/FILE_MAP.md)。
- [Buff与零伙伴](docs/tutorials/027-zero-companion-buffs.md)、[物理机关](docs/tutorials/028-map-mechanisms-portals.md)、[四图整局](docs/tutorials/029-four-map-run.md)。
- [数值评估](docs/tutorials/030-balance-evaluation.md)、[美术与反馈参数](docs/tutorials/031-fish-art-feedback.md)、[普通包验证](docs/tutorials/032-ordinary-export-validation.md)。
- 使用tools/verify.ps1并通过-GodotExe指定本机固定版本的实际路径。不要沿用另一台电脑的路径；[AGENTS](AGENTS.md)和[Git前最终Review](docs/REVIEW.md)说明接手及授权边界。

708次数值执行没有产生通过全部门槛的新默认值；失败候选未混入普通包。正常AI九局均在第三波死亡，没有人类/自然完整通关结论。已生成的鱼、箱子与装甲在实际游戏尺寸接入，内部保留版本仍需用户判断审美和手感；整夜批次的原生窗口激活限制在后续功能复验时未再出现，现已实测开始、发射、暂停和回菜单；未覆盖自然整局通关。

以下保留旧实验与开发阶段记录；其中旧F5、一个伙伴、几何占位和旧包入口的描述不代表当前正式入口。

## 开始玩旧实验原型

1. 安装 **Godot 4.7.1 stable 标准版**（无需 .NET）。两台电脑保持相同版本。
2. 克隆本仓库，在 Godot 项目管理器中导入根目录 `project.godot`。
3. 按 F6 运行当前场景，或 F5 运行整个项目。
4. 球停稳后，按住球向后拖拽，松开发射；右键取消；R 重置。窗口内按钮可切换机关实验模式。

## 开发入口

- [项目概况](docs/PROJECT.md)：目标、范围、设计决策。
- [当前状态](docs/STATUS.md)：已完成、未完成、下一步和验证证据。
- [项目文件目录](docs/FILE_MAP.md)：自动生成的文件树、每个文件的用途及主要调用关系。
- [Agent 规则](AGENTS.md)：所有 AI 接手必须先读。
- [Git 前最终 Review](docs/REVIEW.md)：开发者准备提交时，统一检查代码、功能、教程和目录；与开发中的局部 Review 独立。
- [Git 公约](CONTRIBUTING.md)：三人如何协作。
- [另一位开发者快速入门](docs/onboarding/DEVELOPER.md)。
- [交给另一台电脑的 AI](docs/onboarding/AI_SETUP.md)。
- [原型实现教程](docs/tutorials/001-prototype.md)。
- [目录维护与 Review 教程](docs/tutorials/002-project-map-and-review.md)。

基础游戏只依赖Godot内置功能；本机可选Live2D菜单通过已有Native桥接加载，缺资源时静态回退不影响游戏。MCP是可选的Agent辅助工具，没有MCP也能运行、修改和验证游戏。

新玩法入口为 `scenes/roguelite/arena.tscn`，在编辑器打开后按 F6；已迁移为俯视零重力 P0～P2 三靶场，可在窗口全屏空白处拖动发射，全程正常速度，待真实玩家复验。F5 的旧实验入口保持原样。操作与调参见 [教程 003](docs/tutorials/003-collision-roguelite.md)，后续按 [分阶段计划](docs/plans/003-collision-roguelite.md) 推进。

B线开发夹具入口为 `scenes/roguelite/gameplay_lab.tscn`，在编辑器打开后 F6；不替换正式 `run.tscn`。首版提供单敌、怪群、墙角、伙伴、范围、炮台、分裂和首领八种固定夹具，以及白名单参数、正式固定发射、读数、拒伤日志、本地预设和复现记录。操作见[教程 022](docs/tutorials/022-gameplay-lab.md)。

敌人默认绘制和正式生命面板已有最小可替换接口：玩法发布只读快照和真实事件，表现只消费；UI请求仍由规则层校验。A线接入边界与示例见[教程 021](docs/tutorials/021-gameplay-presentation-interface.md)。

## 试玩碰撞拆迁 Demo

打开 `scenes/roguelite/run.tscn` 后按 F6：五波敌人、击杀门槛领奖、十五项发育池、首领与胜负重开；默认肥鱼/小鱼几何主题，白饭局部吸引与饱饭撞已接入。窗口标题为“玩个球 · 击杀奖励 Demo”。旧三靶场仍是 `arena.tscn`，F5 默认侧视实验保持。

全屏空白处左键向后拖、松开发射；运动中每2.2秒可再发射，右键取消，Esc暂停/菜单重开。小弟初始不跟随，取得跟随升级才会归队；墙/挡板/箱体始终实体碰撞。空心预警后才有危险攻击，生命归零后R重开。白饭靠近会弯曲主球轨迹，吃到返还冷却并强化之后新发射的一次有效命中。

先读 [整局教程007](docs/tutorials/007-run-loop.md)，再看 [白饭008](docs/tutorials/008-rice.md)、[主题009](docs/tutorials/009-theme.md)。当前完成本地实现和自动检查，实际一局时长、难度、首领和白饭手感仍待玩家验收；不以headless状态测试冒充人工通关。

## 讨论中的想法

[开发路线与 Issue 草案](docs/ideas/ROADMAP_DRAFT.md) 是供团队挑选的创意池，不代表已批准的需求、排期或工程规则。

新版奖励：击杀6/8/10…只怪逐次获得三选一，运筹升级后四选一；同帧连锁可排队领奖，清波不重复赠奖。详见 [教程010](docs/tutorials/010-kill-rewards.md)。

计划006已进入本地功能实现：玩家生命面板、事件音组、三阶段商店/补给原型。打开 `scenes/roguelite/audio_preview.tscn` 后F6可单独试听；用户认为首版音色太温和，仍在整改，音质未验收。完整UI样板被用户否定，暂停全面美术替换，先完成功能。详见 [当前状态](docs/STATUS.md)、[生命面板011](docs/tutorials/011-health-panel.md)、[事件音频012](docs/tutorials/012-event-audio.md)、[阶段休息013](docs/tutorials/013-stage-rest.md)。此前开发阶段仅本地；最新用户已另行授权本批导出、分工文档与通过最终Review后的PR/merge，实际结果见STATUS/GitHub。

最新试玩整改：已放缓逐波刷怪与强敌加入，减少敌人质量/弹性并增加受击硬直和主球有限撞敌续力，详见[怪群碰撞014](docs/tutorials/014-crowd-impact.md)、[难度调参015](docs/tutorials/015-difficulty.md)。本次难度与手感仍待真人复玩。

最新敌人整改：修复橙色方块被撞飞却漏伤；出攻击范围立即取消蓄力，敌人按剩余生命青绿1／金黄2～3／紫红4～6并显示数字。顶栏可勾选“击破分裂”（默认关闭），规则与调参见[016](docs/tutorials/016-enemy-range-and-health.md)、[017](docs/tutorials/017-enemy-splitting.md)、[018](docs/tutorials/018-contact-damage.md)。

## 给策划试玩与下一阶段分工

Windows导出方法见[教程019](docs/tutorials/019-windows-export.md)，包内[试玩说明](docs/playtest/PLANNER_README.txt)面向策划，不需安装Godot。导出只在暂存副本切换到run入口，源码F5旧侧视保留，成品位于忽略的builds目录。

用户拟负责A线（美术/UI/粒子/声音表现）及最终审阅merge，B线负责玩法创新、实验室与集成协调。整文件所有权、接口契约、阶段计划与验收见[计划008](docs/plans/008-parallel-development.md)和[教程020](docs/tutorials/020-parallel-workflow.md)。S1最小表现接口和首版八类玩法实验室已实现；玩家/伙伴/首领等其余表现拆分及下一机制尚未实施，B不自动获得合并权限。

策划实时手感入口：`scenes/roguelite/tuning_run.tscn`，F1展开9项物理滑杆，同局即时应用、对照/恢复/保存参数。导出加`-LiveTuning`即可交给无需Godot的策划，见[教程024](docs/tutorials/024-live-feel-tuning.md)。策略/成长使用逐局反馈，手感直接现场调。

完整调参台已扩展到引擎/求解器/全部工程设置、刚体/材质/形状、各玩法actor和资源，支持分类、中文/原名搜索与分页，默认从F1进入。完整覆盖与重启配置见[教程025](docs/tutorials/025-full-engine-tuning.md)。

本轮整夜本地交付检查点见[普通包与证据说明](docs/playtest/OVERNIGHT_DELIVERY.md)，实际最新验证和未验项以[STATUS](docs/STATUS.md)顶部为准。普通包无F1调参入口。
