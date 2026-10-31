# 玩个球

一款 PC 端 2D 物理碰撞游戏。当前 Demo 是俯视平面、零环境重力的碰撞拆迁肉鸽：主动发射主球，撞出小兵接力清场，击杀领奖成长。旧横版解谜实验原型继续保留；完整规则见 [设计方案](docs/ideas/COLLISION_ROGUELITE_DEMO.md)。

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

工程只依赖 Godot 内置功能；MCP 是可选的 Agent 辅助工具。没有 MCP 也能运行、修改和验证游戏。

新玩法入口为 `scenes/roguelite/arena.tscn`，在编辑器打开后按 F6；已迁移为俯视零重力 P0～P2 三靶场，可在窗口全屏空白处拖动发射，全程正常速度，待真实玩家复验。F5 的旧实验入口保持原样。操作与调参见 [教程 003](docs/tutorials/003-collision-roguelite.md)，后续按 [分阶段计划](docs/plans/003-collision-roguelite.md) 推进。

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

用户拟负责A线（美术/UI/粒子/声音表现）及最终审阅merge，B线负责玩法创新/实验室与集成协调。整文件所有权、接口契约、阶段计划与验收见[计划008](docs/plans/008-parallel-development.md)和[教程020](docs/tutorials/020-parallel-workflow.md)。目前只落文档，表现拆分/实验室/下一机制尚未实现；B不自动获得合并权限。
