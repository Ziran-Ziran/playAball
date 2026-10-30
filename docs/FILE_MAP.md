# 项目文件目录

由 `tools/project_map.gd` 根据 Git 可见文件与 `docs/file_purposes.json` 生成。请修改用途清单后重新生成，不直接编辑此树。

覆盖已跟踪文件及未忽略的新文件；不包含 `.git/`、`.godot/`、`.local/` 等本机缓存。新增、删除、改名或职责变化后立即更新，交付前和 CI 检查是否过期。

```text
playAball/
├── .github/  # GitHub 协作模板与自动检查
│   ├── workflows/  # 提交/PR 触发的持续集成
│   │   └── godot.yml  # Linux 固定版本导入、目录与新旧行为检查；新增新玩法检查尚未上传运行。
│   └── pull_request_template.md  # PR 的改动、测试、Review、教程和目录核对模板。
├── docs/  # 项目现状、设计、教程与协作说明
│   ├── ideas/  # 设计方案与创意草案，各文件注明采纳状态
│   │   ├── COLLISION_ROGUELITE_DEMO.md  # 已确认的俯视零重力肉鸽方案、P0～P5 验收与分阶段建设边界。
│   │   └── ROADMAP_DRAFT.md  # 未采纳的开发里程碑、玩法脑洞与可转为 GitHub Issue 的草案。
│   ├── onboarding/  # 另一位开发者与另一台电脑 AI 的入门材料
│   │   ├── images/  # 交接说明配套的可维护流程图
│   │   │   ├── environment.svg  # 另一台电脑的必需环境与可选 MCP 的关系图。
│   │   │   └── workflow.svg  # 开发者从提出功能到 Review、授权提交和 PR 合并的流程图。
│   │   ├── AI_SETUP.md  # 另一电脑 AI 的环境调查、工具补齐、可选 MCP 和验证步骤。
│   │   └── DEVELOPER.md  # 新开发者如何用 Agent、Git、GitHub、Godot 完成一次协作。
│   ├── plans/  # 具体工作的范围与执行清单
│   │   ├── 001-bootstrap.md  # 首次建仓、原型实现和交接的已执行计划。
│   │   ├── 002-workflow.md  # 本轮目录维护、Review、交接配图与路线草案的执行清单。
│   │   └── 003-collision-roguelite.md  # P0～P2 俯视迁移执行清单、验证与玩家门槛。
│   ├── reviews/  # 重要改动的审查证据与交接
│   │   └── 2026-10-28-workflow.md  # 本轮独立最终审查、测试证据、问题处理、用户授权与交接记录。
│   ├── tutorials/  # 每个功能的实现原理和手动修改教程
│   │   ├── 001-prototype.md  # 球发射、碰撞表现、机关、目标和手动调参的初始教程。
│   │   ├── 002-project-map-and-review.md  # 文件目录生成/检查的实现和 Review/授权流程的操作教程。
│   │   └── 003-collision-roguelite.md  # 俯视 P0～P2 输入、冲量、接力、归队、检查器调参与玩家验收教程。
│   ├── .gdignore  # 让 Godot 跳过文档目录的资源导入，避免把交接图当作游戏素材。
│   ├── FILE_MAP.md  # 自动生成的项目文件树、每个文件的用途及主要调用关系。
│   ├── PROJECT.md  # 已采纳的游戏目标、技术选择、原型范围与模块边界。
│   ├── REVIEW.md  # 开发者准备 Git 提交时发起的最终审查、测试和授权流程，与开发中的局部检查独立。
│   ├── STATUS.md  # 当前实际进展、验证证据、已知限制和下一步交接。
│   └── file_purposes.json  # 文件与目录用途的人工说明，作为文件树生成器的语义来源。
├── scenes/  # Godot 可编辑场景与节点结构
│   ├── roguelite/  # 俯视零重力三靶场与可复用刚体场景
│   │   ├── arena.tscn  # 可编辑俯视三靶场、四边围墙、斜切角、平面挡板与 HUD。
│   │   ├── companion_ball.tscn  # 零重力小兵、接力传感器及围墙/挡板/箱体实体碰撞配置。
│   │   ├── destructible.tscn  # 可复用的固定碰撞靶形状与受击脚本入口。
│   │   └── player_ball.tscn  # 零重力主球刚体、圆形形状与弹性材质。
│   ├── ball.tscn  # 可复用的球刚体、圆形碰撞形状与物理材质。
│   ├── main.tscn  # 实验关卡的障碍、球、机关、目标、镜头和 HUD 节点布局。
│   └── mechanism.tscn  # 可复用的区域机关入口，运行时按参数生成检测形状。
├── scripts/  # 游戏逻辑与表现脚本
│   ├── roguelite/  # 新肉鸽物理、发射、碰撞与同伴逻辑
│   │   ├── arena.gd  # 全屏拖动与按钮隔离、HUD 就绪状态、暂停/重置与单球越界回收。
│   │   ├── arena.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── collision_combat.gd  # 按法线接近速度结算伤害、碰撞去重、有限接力与链路记录。
│   │   ├── collision_combat.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── combat_body.gd  # 零重力刚体接触报告、世界接触点、复位事件失效与物理状态接口。
│   │   ├── combat_body.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── companion_ball.gd  # 默认不跟随的小兵、撞击出击、实体障碍碰撞及可选跟随升级引导。
│   │   ├── companion_ball.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── companion_manager.gd  # 同伴四颗上限、初始摆球与跟随升级开关传播。
│   │   ├── companion_manager.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── destructible.gd  # 固定碰撞靶的生命、一次死亡事件、复位与占位绘图。
│   │   ├── destructible.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── launch_controller.gd  # 正常速度发射控制、冷却按住接续、手势取消与能量状态。
│   │   ├── launch_controller.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   │   ├── player_ball.gd  # 主球冲量发射、全方向反向动量 A/B 与能量环。
│   │   └── player_ball.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   ├── ball.gd  # 控制球的停稳、冲量发射、刚体复位与真实接触事件。
│   ├── ball.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   ├── impact_feedback.gd  # 亮环/合成音/震动、场景粒子重力与复位时清理粒子及音源。
│   ├── impact_feedback.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   ├── main.gd  # 组织关卡输入、拖拽瞄准、杆数、HUD、目标胜利和重置。
│   ├── main.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   ├── mechanism.gd  # 管理区域内的加速、粘滞或反向重力及离开后的恢复。
│   └── mechanism.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
├── tests/  # 无需测试插件的游戏行为检查
│   ├── roguelite_input_feedback.gd  # 全屏真实鼠标事件、冷却临界帧、正常速度、接触反馈位置与复位清理回归。
│   ├── roguelite_input_feedback.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   ├── roguelite_smoke.gd  # 俯视发射/接力、默认不跟随、三态障碍反弹、可选引导与回收检查。
│   ├── roguelite_smoke.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   ├── smoke.gd  # 旧原型停稳、发射、真实接触点、机关、复位、鼠标与进球回归。
│   └── smoke.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
├── tools/  # 开发辅助工具，不属于游戏玩法
│   ├── project_map.gd  # 读取 Git 文件列表和用途清单，生成/检查项目文件目录。
│   ├── project_map.gd.uid  # 关联 GDScript 的稳定资源标识，由 Godot 维护，不手动修改。
│   └── verify.ps1  # Windows 固定版本、导入、目录及新旧行为检查入口。
├── .editorconfig  # 统一编码、缩进、换行和文件末尾格式。
├── .gitattributes  # 统一 Git 文本换行，标记图片/音频为二进制。
├── .gitignore  # 排除引擎缓存、本机临时文件、凭据和导出成品。
├── AGENTS.md  # 所有 Agent 接手、实现、Review、教程/目录维护和提交授权规则。
├── CONTRIBUTING.md  # 三人团队的 Git 分支、提交、PR 与合并公约。
├── README.md  # 游戏介绍、运行方式和面向开发者的总入口。
└── project.godot  # Godot 工程入口：主场景、窗口、渲染、物理和碰撞层设置。
```

## 主要关系

```text
project.godot → scenes/main.tscn → scripts/main.gd（组织关卡、输入、HUD）
  ├─ scenes/ball.tscn → scripts/ball.gd（刚体与碰撞信号）
  ├─ scenes/mechanism.tscn → scripts/mechanism.gd（区域机关）
  └─ scripts/impact_feedback.gd ← impacted 信号（碰撞表现）

scenes/roguelite/arena.tscn → arena.gd（独立俯视三靶场）
  ├─ launch_controller → player_ball → combat_body（冲量/接触）
  ├─ companion_manager → companion_ball（初始摆球/接力/可选跟随）
  ├─ collision_combat → destructible（去重伤害）
  └─ impact_feedback（共用表现，新场景粒子零重力）

tools/verify.ps1 / GitHub CI
  ├─ Godot 导入检查
  ├─ tools/project_map.gd --check（文件目录完整且最新）
  ├─ tests/smoke.gd（旧侧视行为回归）
  ├─ tests/roguelite_smoke.gd（俯视发射/碰撞/接力/归队）
  └─ tests/roguelite_input_feedback.gd（全屏手势/冷却临界/反馈坐标）
```

图中关系是人工维护的架构摘要，文件树由工具生成；改变模块关系时也要更新生成器中的摘要，并通过 Review。维护方法见 [教程 002](tutorials/002-project-map-and-review.md)。
