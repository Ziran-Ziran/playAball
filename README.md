# 玩个球

一款 PC 端 2D 横版物理解谜游戏。像打台球一样选择方向和力度发射球，让球经过障碍和机关进入目标。当前阶段：单关卡碰撞手感原型。

## 开始玩

1. 安装 **Godot 4.7.1 stable 标准版**（无需 .NET）。两台电脑保持相同版本。
2. 克隆本仓库，在 Godot 项目管理器中导入根目录 `project.godot`。
3. 按 F6 运行当前场景，或 F5 运行整个项目。
4. 球停稳后，按住球向后拖拽，松开发射；右键取消；R 重置。窗口内按钮可切换机关实验模式。

## 开发入口

- [项目概况](docs/PROJECT.md)：目标、范围、设计决策。
- [当前状态](docs/STATUS.md)：已完成、未完成、下一步和验证证据。
- [项目文件目录](docs/FILE_MAP.md)：自动生成的文件树、每个文件的用途及主要调用关系。
- [Agent 规则](AGENTS.md)：所有 AI 接手必须先读。
- [Review 与测试流程](docs/REVIEW.md)：如何检查代码、功能、教程和文件目录，以及何时请求提交授权。
- [Git 公约](CONTRIBUTING.md)：三人如何协作。
- [另一位开发者快速入门](docs/onboarding/DEVELOPER.md)。
- [交给另一台电脑的 AI](docs/onboarding/AI_SETUP.md)。
- [原型实现教程](docs/tutorials/001-prototype.md)。
- [目录维护与 Review 教程](docs/tutorials/002-project-map-and-review.md)。

工程只依赖 Godot 内置功能；MCP 是可选的 Agent 辅助工具。没有 MCP 也能运行、修改和验证游戏。

## 讨论中的想法

[开发路线与 Issue 草案](docs/ideas/ROADMAP_DRAFT.md) 是供团队挑选的创意池，不代表已批准的需求、排期或工程规则。
