# 原始框架实现计划

目标：交付能运行的单关卡物理实验原型和适合新手的协作流程。

架构：Ball(RigidBody2D) 发出碰撞事件；Main 组织场景与交互；Mechanism(Area2D) 改变区域物理；ImpactFeedback 独立播放表现。Godot 4.7.1 / GDScript，无第三方依赖。

- [x] 建立 `docs/PROJECT.md` 项目范围与设计，保留 README。
- [x] 建立 `AGENTS.md` 接手与教程规则。
- [x] 建立 `CONTRIBUTING.md`、忽略与换行规则、PR 模板。
- [x] 创建公开 GitHub 仓库并上传上述协作基线。
- [x] 先建立 `tests/smoke.gd` 行为检查，确认缺少原型时失败。
- [x] 创建 `project.godot`、`scenes/main.tscn`、球/机关场景与脚本、碰撞反馈脚本。
- [x] 使用 Godot headless 导入、运行 smoke，验证冲量、停稳、碰撞、机关、目标与重置。
- [x] 可视化运行检查，修正错误；记录主观手感仍需开发者试玩。
- [x] 完成教程、另一电脑 AI 环境清单、开发者入门、当前状态与 CI。
- [x] 提交并推送原型，核对远端状态。

验证命令（GODOT_EXE 由当前设备调查获得）：
```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/smoke.gd
```
两条命令退出码都应为 0；脚本输出 ALL CHECKS PASSED。导入日志不得有 SCRIPT ERROR。手动 F5：拖球松手、右键取消、R 重置、切换三种机关并观察，确认声音、粒子与目标提示。
