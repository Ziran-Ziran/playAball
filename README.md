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

当前音效单一且体验不合格，生命仅有文字、缺少血条，UI/主题仍是占位。下一轮优先按 [音效/生命面板/阶段节奏计划006](docs/plans/006-feedback-and-run-rhythm.md)整改，[UI与美术计划007](docs/plans/007-ui-art-direction.md)另行推进；阶段商店/事件尚未实现。可复制 [下一对话提示词](docs/onboarding/NEXT_SESSION.md)接手。
