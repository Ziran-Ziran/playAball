# 玩个球

一款 PC 端 2D 物理碰撞游戏。当前建设方向是俯视平面、零环境重力的碰撞拆迁肉鸽：主动发射主球，撞出小兵接力清场。旧横版解谜实验原型继续保留；新 Demo 尚在迁移阶段，规则与接手提示见 [设计方案](docs/ideas/COLLISION_ROGUELITE_DEMO.md)。

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

## 讨论中的想法

[开发路线与 Issue 草案](docs/ideas/ROADMAP_DRAFT.md) 是供团队挑选的创意池，不代表已批准的需求、排期或工程规则。
