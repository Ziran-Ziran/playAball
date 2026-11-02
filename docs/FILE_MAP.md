# 项目文件目录

由 `tools/project_map.gd` 根据 Git 可见文件与 `docs/file_purposes.json` 生成。请修改用途清单后重新生成，不直接编辑此树。

覆盖已跟踪文件及未忽略的新文件；不包含 `.git/`、`.godot/`、`.local/` 等本机缓存。新增、删除、改名或职责变化后立即更新，交付前和 CI 检查是否过期。

```text
playAball/
├── .github/  # GitHub 协作模板与自动检查
│   ├── workflows/  # 提交/PR 触发的持续集成
│   │   └── godot.yml  # Linux固定引擎导入、目录与25套检查配置。
│   └── pull_request_template.md  # PR 的改动、测试、Review、教程和目录核对模板。
├── assets/  # 运行素材
│   └── ui/  # 用户认可的第一批UI素材；从文档样板复制用于运行
│       ├── arena_skin.png  # 用户认可的暗绿薄墙全景生图；正式运行仅裁取无字地面和四边墙纹理。
│       ├── arena_skin.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_exit_button_full.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_exit_button_full.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_menu_background.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_menu_background.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_menu_character.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_menu_character.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_menu_title.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_menu_title.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_settings_button_full.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_settings_button_full.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_start_button_full.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_start_button_full.png.import  # UI贴图导入配置，由Godot维护。
│       ├── health_skin.png  # 已生成红格HUD原图；正式Atlas裁取十字/红格/空格/金币/暂停等，不使用示例数字。
│       ├── health_skin.png.import  # UI贴图导入配置，由Godot维护。
│       ├── panel_base.png  # 已生成无字通用面板，Atlas去透明边距后用于暂停、选卡、商店与事件。
│       ├── panel_base.png.import  # UI贴图导入配置，由Godot维护。
│       ├── upgrade_card_frame_v2.png  # 第一批生图UI运行贴图。
│       └── upgrade_card_frame_v2.png.import  # UI贴图导入配置，由Godot维护。
├── docs/  # 项目现状、设计、教程与协作说明
│   ├── art/  # 视觉方向样板与用户反馈记录，未获认可的样板不用于全面替换
│   │   ├── fat_fish_exit_button_full.png  # 与开始同风格的完整退出按钮，门箭头和中文字整体生图，待评价。
│   │   ├── fat_fish_menu.html  # 角色/标题/背景/按钮分层组合的菜单小样，点击仅回显预览信息。
│   │   ├── fat_fish_menu_background.png  # 独立生图的菜单球类训练场景插画，不是正式战斗地图。
│   │   ├── fat_fish_menu_character.png  # 用户已认可的透明护饭碗/鼓脸鲸鱼娘菜单角色，内置生图，未替换正式actor。
│   │   ├── fat_fish_menu_preview.png  # 1280×720肥鱼主题分层菜单截图，新标题/背景/按钮组合待评价。
│   │   ├── fat_fish_menu_preview_v2.png  # 完整生图三按钮替换后的肥鱼菜单截图，无后加图标/文字覆盖。
│   │   ├── fat_fish_menu_title.png  # 独立生图的蓝白玩个球标题字形，菜单新方案待评价。
│   │   ├── fat_fish_settings_button_full.png  # 与开始同风格的完整设置按钮，齿轮和中文字整体生图，待评价。
│   │   ├── fat_fish_start_button.png  # 首版无字蓝白开始按钮底图，后加图标被否定，保留历史对照。
│   │   ├── fat_fish_start_button_full.png  # 按用户要求整体生图的开始按钮，含播放图标与开始游戏中文字，待评价。
│   │   ├── hud_health_flow.gif  # 用户已认可力度的红色血条逐格流光两秒循环参考；正式版本见health_skin.gd。
│   │   ├── hud_health_flow.html  # 用生成贴图演示红色有血格的逐格流光，不改变或接线玩法状态。
│   │   ├── hud_red_sample.png  # 内置生图的透明红色血条HUD概念图；文字数字为示例，未接正式游戏。
│   │   ├── menu_preview.html  # 生图按钮和面板的独立菜单/四态演示，点击仅显示预览反馈。
│   │   ├── menu_preview.png  # 1280×720开始/设置/退出菜单的美术组合截图，未接游戏功能。
│   │   ├── ui_button_base.png  # 内置生图的透明无字通用按钮底图，沿用已认可细边科幻卡框风格。
│   │   ├── ui_panel_base.png  # 内置生图的透明无字横向菜单面板底板，不含控件和具体流程。
│   │   ├── ui_sample.svg  # 已向用户展示且被否定的暖色UI布局样板，保留反馈上下文，不作为实施风格。
│   │   ├── ui_style_guide.md  # 记录样板来源、用户否定与停止全面美术替换的边界。
│   │   ├── upgrade_card_frame.png  # 首版厚切角成长卡框，用户评价太朋克，保留历史对照。
│   │   ├── upgrade_card_frame_v2.png  # 用户已认可的内置生图简约科幻细边柔角通用卡框，无字无具体卡面。
│   │   ├── upgrade_cards_entrance.gif  # 首版三张成长卡轻弹入场的历史预览，后续改为平滑流动风格。
│   │   ├── upgrade_cards_entrance.html  # v2细边卡框三/四张平滑入场及沿边流光独立演示，不接奖励状态。
│   │   └── upgrade_cards_entrance_v2.gif  # 用户已认可的v2三卡平滑滑入及沿边流光预览，正式游戏未接入。
│   ├── ideas/  # 设计方案与创意草案，各文件注明采纳状态
│   │   ├── COLLISION_ROGUELITE_DEMO.md  # 已确认的俯视零重力肉鸽方案、P0～P5 验收与分阶段建设边界。
│   │   └── ROADMAP_DRAFT.md  # 未采纳的开发里程碑、玩法脑洞与可转为 GitHub Issue 的草案。
│   ├── onboarding/  # 另一位开发者与另一台电脑 AI 的入门材料
│   │   ├── images/  # 交接说明配套的可维护流程图
│   │   │   ├── environment.svg  # 另一台电脑的必需环境与可选 MCP 的关系图。
│   │   │   └── workflow.svg  # 开发者从提出功能到 Review、授权提交和 PR 合并的流程图。
│   │   ├── AI_SETUP.md  # 另一电脑 AI 的环境调查、工具补齐、可选 MCP 和验证步骤。
│   │   ├── DEVELOPER.md  # 新开发者如何用 Agent、Git、GitHub、Godot 完成一次协作。
│   │   └── NEXT_SESSION.md  # 下一对话可复制提示词：现状、最新体验问题、实施顺序与环境/Git授权边界。
│   ├── plans/  # 具体工作的范围与执行清单
│   │   ├── 001-bootstrap.md  # 首次建仓、原型实现和交接的已执行计划。
│   │   ├── 002-workflow.md  # 本轮目录维护、Review、交接配图与路线草案的执行清单。
│   │   ├── 003-collision-roguelite.md  # P0～P2 俯视迁移执行清单、验证与玩家门槛。
│   │   ├── 004-roguelite-run.md  # P3并行分工、整局实现/验证清单与未完成人工验收。
│   │   ├── 005-kill-rewards.md  # 用户批准的击杀领奖/十五项发育池计划、并行分工与验收清单。
│   │   ├── 006-feedback-and-run-rhythm.md  # 音效/生命面板/阶段节奏计划与本地实施更新，音质与两局节奏待验收。
│   │   ├── 007-ui-art-direction.md  # UI美术方向与样板反馈；用户否定样板后暂停全面替换。
│   │   ├── 008-parallel-development.md  # A表现/B玩法实验室、用户owner合并权、整文件边界、S0～S4计划与当前最小接口/实验室实施进度。
│   │   └── 009-ui-game-integration.md  # 本轮集成范围、所有权、验证与Git授权边界。
│   ├── playtest/  # 面向策划/试玩者的启动操作、反馈与已知限制说明
│   │   ├── PLANNER_FEEDBACK.txt  # 只供策略、成长与节奏逐局反馈；手感改用实时面板并回传物理参数JSON。
│   │   └── PLANNER_README.txt  # 随Windows试玩包交给策划的操作、流程、版本反馈与限制说明。
│   ├── reviews/  # 重要改动的审查证据与交接
│   │   ├── 2026-10-28-workflow.md  # 本轮独立最终审查、测试证据、问题处理、用户授权与交接记录。
│   │   ├── 2026-10-31-feedback-export.md  # 当前反馈整改/导出/分工完整最终Review、独立审查与测试/未测证据。
│   │   ├── 2026-10-31-kill-rewards.md  # 击杀奖励原型最终独立Review、验证限制、最新体验缺陷与本轮上传范围。
│   │   ├── 2026-11-01-gameplay-lab.md  # 本批S1表现接口和B线玩法实验室的最终Review范围、独立审查、问题处理、验证证据、未测项与授权边界。
│   │   ├── 2026-11-02-ui-integration.md  # A/B快照集成与UI接线的验证/独立审查证据及未测项。
│   │   └── collision-demo-final.md  # 当前Demo最终独立Review、首领真实接触修复、验证与人工未测证据。
│   ├── tutorials/  # 每个功能的实现原理和手动修改教程
│   │   ├── 001-prototype.md  # 球发射、碰撞表现、机关、目标和手动调参的初始教程。
│   │   ├── 002-project-map-and-review.md  # 文件目录生成/检查的实现和 Review/授权流程的操作教程。
│   │   ├── 003-collision-roguelite.md  # 俯视 P0～P2 输入、冲量、接力、归队、检查器调参与玩家验收教程。
│   │   ├── 004-enemies.md  # 三敌人/生命/危险弹的状态、节点、检查器与回归教程。
│   │   ├── 005-build.md  # 十五项奖励候选/权重/等级与碰撞收益、资源调参和扩展教程。
│   │   ├── 006-boss.md  # 首领模块/弱点/危险弧、物理接口、调参与验证教程。
│   │   ├── 007-run-loop.md  # 完整战斗入口、波次/升级/结算、调试构筑及人工验证教程。
│   │   ├── 008-rice.md  # 白饭力场/周期/拾取/强化链路、调参与复现教程。
│   │   ├── 009-theme.md  # 几何肥鱼/小鱼、主题资源、饱饭外观与物理隔离教程。
│   │   ├── 010-kill-rewards.md  # 击杀奖励队列、三选四选、真实收益、调参与扩展教程。
│   │   ├── 011-health-panel.md  # 生命面板节点、信号与只读状态、调参、扩展及手动复现教程。
│   │   ├── 012-event-audio.md  # 原创事件音组、调度预算、独立音量、试听与打击感整改教程。
│   │   ├── 013-stage-rest.md  # 三阶段、钱包、商店/免费成长事件、状态清理与调参复现教程。
│   │   ├── 014-crowd-impact.md  # 扎堆撞停根因、敌人质量/硬直、有限续力与真物理回归及调参教程。
│   │   ├── 015-difficulty.md  # 逐波含预警预算、渐进间隔/强敌配额、检查器与新手试玩教程。
│   │   ├── 016-enemy-range-and-health.md  # 三敌人出范围取消/重新蓄力、剩余血量颜色和数字、检查器与回归教程。
│   │   ├── 017-enemy-splitting.md  # 玩家勾选分裂、两代次球、安全预警/预算和整族经济教程。
│   │   ├── 018-contact-damage.md  # 橙色方块漏伤根因、物理帧双快照与不同节点顺序真实接触回归教程。
│   │   ├── 019-windows-export.md  # 隔离导出Windows策划包、版本指纹、验证与跨电脑限制教程。
│   │   ├── 020-parallel-workflow.md  # 两电脑同基线、唯一文件owner、接口交接、文档集成与用户审阅merge操作教程。
│   │   ├── 021-gameplay-presentation-interface.md  # 敌人只读快照/事件、可替换表现、生命面板和UI请求校验的最小接口教程。
│   │   ├── 021-hud-health-flow.md  # 红色HUD生图来源、流光过程/参数、独立预览验证与B接线边界教程。
│   │   ├── 022-gameplay-lab.md  # 八类玩法夹具、白名单参数、正式固定发射、拒伤日志、预设与复现教程。
│   │   ├── 022-upgrade-card-frame.md  # 通用卡框来源、依次入场原理/参数、预览验证与B奖励接线边界。
│   │   ├── 023-menu-ui-assets.md  # 无字按钮/面板来源、四态组合、尺寸验证和B菜单接线边界教程。
│   │   ├── 024-fat-fish-menu.md  # 肥鱼菜单独立生图来源、图层/参数、浏览器验证及B接线边界教程。
│   │   ├── 024-live-feel-tuning.md  # 策划EXE现场调物理量的操作、生效语义、节点/源码、对照/存取与扩展验证教程。
│   │   ├── 025-full-engine-tuning.md  # 完整引擎/玩法调参台的覆盖、生效/重启、复合编辑、源码与验证教程。
│   │   └── 026-ui-game-integration.md  # A/B快照汇合、入口分离、UI运行接入、调参保留与验证教程。
│   ├── .gdignore  # 让 Godot 跳过文档目录的资源导入，避免把交接图当作游戏素材。
│   ├── FILE_MAP.md  # 自动生成的项目文件树、每个文件的用途及主要调用关系。
│   ├── PROJECT.md  # 已采纳的游戏目标、技术选择、原型范围与模块边界。
│   ├── REVIEW.md  # 开发者准备 Git 提交时发起的最终审查、测试和授权流程，与开发中的局部检查独立。
│   ├── STATUS.md  # 当前实际进展、验证证据、已知限制和下一步交接。
│   └── file_purposes.json  # 文件与目录用途的人工说明，作为文件树生成器的语义来源。
├── resources/  # Godot 可调数据资源
│   └── roguelite/  # 肉鸽构筑与主题数据
│       ├── audio/  # 原创事件音组与混音调参资源
│       │   └── default_palette.tres  # 默认原创音色合成增益资源。
│       ├── stages/  # 波次范围与阶段休息配置
│       │   ├── stage_1.tres  # 第一阶段波1～2及波末商店配置。
│       │   ├── stage_2.tres  # 第二阶段波3～4及波末补给事件配置。
│       │   └── stage_3.tres  # 第三阶段波5及首领、结束无额外休息配置。
│       ├── themes/  # 只影响绘图配色的角色主题资源
│       │   └── fat_fish.tres  # 肥鱼主球、小鱼、能量与饱饭符号的默认配色。
│       └── upgrades/  # 十五项普通奖励和独立强身兜底的说明、分类、权重与等级上限
│           ├── bowling.tres  # 升级 bowling 的标题、效果说明与等级上限。
│           ├── choices.tres  # 三选变四选的说明、类别与一级上限。
│           ├── companion.tres  # 升级 companion 的标题、效果说明与等级上限。
│           ├── cooldown.tres  # 升级 cooldown 的标题、效果说明与等级上限。
│           ├── double_launch.tres  # 双发容量的说明、类别与一级上限。
│           ├── echo.tres  # 有限二次撞击的说明、类别与一级上限。
│           ├── explosion.tres  # 升级 explosion 的标题、效果说明与等级上限。
│           ├── follow.tres  # 升级 follow 的标题、效果说明与等级上限。
│           ├── glide.tres  # 滑行的自身阻尼/摩擦增益、类别和三级上限。
│           ├── heal.tres  # 升级 heal 的标题、效果说明与等级上限。
│           ├── heavy.tres  # 升级 heavy 的标题、效果说明与等级上限。
│           ├── launch_power.tres  # 强力发射的冲量增益、类别、权重与三级上限。
│           ├── pulse.tres  # 无伤护身震退的说明、类别和一级上限。
│           ├── relay.tres  # 升级 relay 的标题、效果说明与等级上限。
│           ├── shrink.tres  # 敌人脉冲/首领震波缩范围的说明与两级上限。
│           └── vigor.tres  # 普通池耗尽时本局生命上限+1的独立可重复兜底。
├── scenes/  # Godot 可编辑场景与节点结构
│   ├── roguelite/  # 俯视零重力三靶场、正式整局与B线独立玩法夹具场景
│   │   ├── presentation/  # A可独立替换的敌人与生命面板表现场景
│   │   │   ├── enemy_view.tscn  # 默认敌人表现场景，只读取DemoEnemy快照并消费事件。
│   │   │   └── health_view.tscn  # 正式可替换生命面板场景，只读取DemoHealth数据。
│   │   ├── arena.tscn  # 可编辑俯视三靶场、四边围墙、斜切角、平面挡板与 HUD。
│   │   ├── audio_preview.tscn  # F6独立音效试听场景，不改变游戏进度。
│   │   ├── boss.tscn  # 同一刚体上的核心和四个可拆模块碰撞形状。
│   │   ├── companion_ball.tscn  # 零重力小兵、接力传感器及围墙/挡板/箱体实体碰撞配置。
│   │   ├── destructible.tscn  # 可复用的固定碰撞靶形状与受击脚本入口。
│   │   ├── enemy.tscn  # 三敌人共用刚体/碰撞形状和低弹性材质，并实例可替换表现组件。
│   │   ├── gameplay_lab.tscn  # B线独立八类玩法夹具入口，F6运行且不替换正式run。
│   │   ├── hazard_ball.tscn  # 危险弹刚体与玩家传感器，环境碰撞后消失。
│   │   ├── lab_panel.tscn  # 实验室可编辑开发控制根场景，运行时分栏显示白名单参数、读数和有界日志。
│   │   ├── player_ball.tscn  # 零重力主球刚体、圆形形状与弹性材质。
│   │   ├── rest_panel.tscn  # 商店、补给事件和3秒准备共用的可编辑功能面板。
│   │   ├── rice_lure.tscn  # 白饭Area2D与玩家拾取形状，不改变刚体碰撞。
│   │   ├── run.tscn  # 独立三阶段战斗入口，接合音频、商店/事件与首领，保留F5旧入口。
│   │   ├── run_hud.tscn  # 三/四选一、结算和重开面板，并实例独立可替换生命面板。
│   │   ├── tuning_panel.tscn  # 完整引擎/快捷模式的可编辑面板壳，暂停、分页区域与对照/存取容器。
│   │   └── tuning_run.tscn  # 策划完整属性调参入口，继承正式整局，含全量目录与原快捷面板。
│   ├── ui/  # 正式主菜单与完整战斗入口
│   │   ├── game.tscn  # 继承完整run的发布场景，无调参节点。
│   │   └── main_menu.tscn  # F5正式主菜单入口。
│   ├── ball.tscn  # 可复用的球刚体、圆形碰撞形状与物理材质。
│   ├── main.tscn  # 实验关卡的障碍、球、机关、目标、镜头和 HUD 节点布局。
│   └── mechanism.tscn  # 可复用的区域机关入口，运行时按参数生成检测形状。
├── scripts/  # 游戏逻辑与表现脚本
│   ├── roguelite/  # 新肉鸽物理、发射、碰撞、同伴逻辑与独立玩法实验室
│   │   ├── lab/  # B线玩法实验室的开发面板与请求界面
│   │   │   ├── engine_tuning.gd  # ProjectSettings与Engine/PhysicsServer热调适配及override.cfg保存/清除。
│   │   │   ├── engine_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── full_tuning.gd  # 实际属性/资源/原型全量目录，校验应用、复位、生成继承与跨别名全局恢复。
│   │   │   ├── full_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── full_tuning_view.gd  # 完整参数分类/搜索/每页20行及数字/开关/枚举/颜色/JSON编辑器。
│   │   │   ├── full_tuning_view.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── lab_panel.gd  # 实验室白名单参数表单、即时显示偏好和带revision的玩法请求；不直接修改战斗状态。
│   │   │   ├── lab_panel.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── tuning_panel.gd  # 纯界面：生成滑杆和数字框、F1显隐、发送参数/按钮请求并显示实际读数。
│   │   │   ├── tuning_panel.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── tuning_variant.gd  # 无对象Variant存取、可读JSON复合值转换、有限数和结构校验。
│   │   │   └── tuning_variant.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── presentation/  # 只读玩法状态并消费表现事件的可替换绘制组件
│   │   │   ├── enemy_view.gd  # 默认敌人绘制与生命数字，仅消费只读快照和表现事件。
│   │   │   ├── enemy_view.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── health_view.gd  # 只读生命条/数字/状态表现组件及热绑定入口。
│   │   │   └── health_view.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── arena.gd  # 全屏拖动与按钮隔离、HUD 就绪状态、暂停/重置与单球越界回收。
│   │   ├── arena.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── assist_effects.gd  # 可暂停的无伤护身震退、有限冲量与表现事件。
│   │   ├── assist_effects.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── audio_director.gd  # 多事件变体回避、限频与优先级声部、混音/暂停和重开清理。
│   │   ├── audio_director.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── audio_palette.gd  # 原创PCM音色合成与缓存，轻重多变体和各事件音组。
│   │   ├── audio_palette.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── audio_preview.gd  # 事件逐项与密集连锁真机试听入口，数字键/静音/重播。
│   │   ├── audio_preview.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── boss.gd  # 首领预警冲刺、真实撞墙弱点、可碎模块、缺口震波与召唤。
│   │   ├── boss.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── collision_combat.gd  # 碰撞伤害/接力去重与升级效果，发布实际接受或拒伤原因，主球有效撞普通敌人兑现有限续力。
│   │   ├── collision_combat.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── combat_body.gd  # 接触快照/冲量刚体基类，集中复位与一次性调试状态接口，拒绝旧局回调。
│   │   ├── combat_body.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── companion_ball.gd  # 默认不跟随的小鱼、接力/障碍碰撞与升级后的限力引导。
│   │   ├── companion_ball.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── companion_manager.gd  # 小弟数量上限、障碍外初始摆球、保留旧球的增员与跟随开关。
│   │   ├── companion_manager.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── destructible.gd  # 固定碰撞靶的生命、一次死亡事件、复位与占位绘图。
│   │   ├── destructible.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── enemy.gd  # 三类物理敌人的生命、范围攻击、硬直、死亡与只读表现快照/事件；不负责绘制。
│   │   ├── enemy.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── gameplay_lab.gd  # 独立八夹具、完整构筑/显式覆盖、生成校验、分裂AI策略、拒伤读数与预设迁移。
│   │   ├── gameplay_lab.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── hazard_ball.gd  # 慢危险弹、玩家检测、寿命和旧事件保护。
│   │   ├── hazard_ball.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── kill_rewards.gd  # 死亡去重、递增门槛、击杀溢出和排队奖励的独立资源。
│   │   ├── kill_rewards.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── launch_controller.gd  # 单发/双发容量、串行冷却、白饭返还、跨恢复输入手势及实验室正式固定发射入口。
│   │   ├── launch_controller.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── live_tuning.gd  # 快捷基线和完整属性覆盖协调、暂停/对照/F9、schema2含高级值存取。
│   │   ├── live_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── player_ball.gd  # 主球冲量/短时有限撞敌续力、升级物理参数、续力只读读数、能量环与肥鱼绘图。
│   │   ├── player_ball.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── player_health.gd  # 五格生命、统一受伤无敌、一次死亡、拒伤原因事件与整局重置。
│   │   ├── player_health.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── rest_panel.gd  # 可编辑休息面板的报价按钮、版本和倒计时显示。
│   │   ├── rest_panel.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── rice_lure.gd  # 白饭拾取区域、有限平面吸力、寿命/闪烁及物理锁外清理。
│   │   ├── rice_lure.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── rice_manager.gd  # 白饭周期/安全候选、一次冷却返还与新发射链饱饭绑定。
│   │   ├── rice_manager.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_arena.gd  # 整局输入与音频/生命HUD接线、生命色阶图例和玩家分裂开关。
│   │   ├── run_arena.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_build.gd  # 十五项候选的类别/权重/资格、等级与全部派生数值及强身兜底。
│   │   ├── run_build.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_director.gd  # 逐波预算/强敌配额、可选两代分裂/整族经济、阶段奖励与整局清理。
│   │   ├── run_director.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_hud.gd  # 委托独立生命视图，管理三四卡版本、结算和经玩法校验的重开请求。
│   │   ├── run_hud.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_wallet.gd  # 唯一死亡入账、余额校验扣款与整局钱包复位。
│   │   ├── run_wallet.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── stage_definition.gd  # 阶段波范围、休息类型与名称数据资源。
│   │   ├── stage_definition.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── stage_flow.gd  # 解析阶段资源与波末商店/事件边界。
│   │   ├── stage_flow.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── theme_definition.gd  # 肥鱼主题ID/名字/绘图配色数据，不携带物理参数。
│   │   ├── theme_definition.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── tuning_run.gd  # 策划完整调参接线、文本输入/鼠标隔离与普通暂停所有权交接。
│   │   ├── tuning_run.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── upgrade_definition.gd  # 升级数据资源：ID、标题、说明与等级上限。
│   │   └── upgrade_definition.gd.uid  # 关联GDScript稳定资源标识。
│   ├── ui/  # 发布入口、主菜单与表现外壳
│   │   ├── arena_skin.gd  # 按现有碰撞坐标绘制生成地面、四墙、斜坡与拐角贴图；不改物理。
│   │   ├── arena_skin.gd.uid  # 关联表现资源的稳定标识。
│   │   ├── card_flow.gd  # 暂停期间运行的卡框边缘流光，鼠标穿透且不发奖励。
│   │   ├── card_flow.gd.uid  # 关联GDScript的稳定资源标识。
│   │   ├── game.gd  # 正式完整游戏外壳，隐藏调试控件，显示正式进度与暂停返回。
│   │   ├── game.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── health_cell.gdshader  # 裁掉Atlas相邻像素，只保留斜切单个生命格。
│   │   ├── health_cell.gdshader.uid  # 关联表现资源的稳定标识。
│   │   ├── health_skin.gd  # 消费DemoHealthView真实状态，动态分格生命与逐格提亮，保留准确数字。
│   │   ├── health_skin.gd.uid  # 关联表现资源的稳定标识。
│   │   ├── main_menu.gd  # 完整贴图主菜单、开始/退出/音量设置，导航到完整游戏。
│   │   └── main_menu.gd.uid  # 关联GDScript稳定资源标识。
│   ├── ball.gd  # 控制球的停稳、冲量发射、刚体复位与真实接触事件。
│   ├── ball.gd.uid  # 关联GDScript稳定资源标识。
│   ├── impact_feedback.gd  # 共用亮环/震动/粒子；run音频路由独立调度，旧场景保留原声音接口。
│   ├── impact_feedback.gd.uid  # 关联GDScript稳定资源标识。
│   ├── main.gd  # 组织关卡输入、拖拽瞄准、杆数、HUD、目标胜利和重置。
│   ├── main.gd.uid  # 关联GDScript稳定资源标识。
│   ├── mechanism.gd  # 管理区域内的加速、粘滞或反向重力及离开后的恢复。
│   └── mechanism.gd.uid  # 关联GDScript稳定资源标识。
├── tests/  # 无需测试插件的游戏行为检查
│   ├── roguelite_audio.gd  # 音组变体、PCM余量、优先级预算、混音与生命周期调度回归。
│   ├── roguelite_audio.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_boss.gd  # 首领真实撞墙/模块接触、弱点时序、护甲、缺口与死亡回归。
│   ├── roguelite_boss.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_build.gd  # 十五项池资格/权重/上限、派生参数与碰撞升级预算边界回归。
│   ├── roguelite_build.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_crowd.gd  # 真实三重敌推进/后排受推/实体碰撞与续力限次/到期/重开预算回归。
│   ├── roguelite_crowd.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_damage_contacts.gd  # 四方向/四距离/两节点顺序真实击破及低速/被动无伤回归。
│   ├── roguelite_damage_contacts.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_difficulty.gd  # 五波30秒未清场压力上限、强敌配额与重开/直接生成预算回归。
│   ├── roguelite_difficulty.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_enemies.gd  # 三敌人预警/攻击、生命无敌、危险弹与旧事件回归。
│   ├── roguelite_enemies.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_enemy_readability.gd  # 三敌人范围即时取消/重新蓄力、生命覆盖和受伤跨颜色等级回归。
│   ├── roguelite_enemy_readability.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_feedback_integration.gd  # 整局真实事件到音效、静音/结算尾音与生命面板重开集成回归。
│   ├── roguelite_feedback_integration.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_full_tuning.gd  # 完整目录、真实引擎读回、资源隔离/新实体、别名恢复、类型与重启配置回归。
│   ├── roguelite_full_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_gameplay_lab.gd  # 八夹具真实发射/构筑与覆盖、阵型拒绝、分裂两代AI/经济、预设迁移/失败与输入隔离回归。
│   ├── roguelite_gameplay_lab.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_hud.gd  # 真实生命受伤/恢复/上限/无敌/死亡/复位与鼠标穿透回归。
│   ├── roguelite_hud.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_input_feedback.gd  # 全屏真实鼠标事件、冷却临界帧、正常速度、接触反馈位置与复位清理回归。
│   ├── roguelite_input_feedback.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_kill_rewards.gd  # 击杀门槛/溢出/去重/排队/复位与非法调参回归。
│   ├── roguelite_kill_rewards.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_kill_run.gd  # 真实死亡领奖、保留弹体暂停、连续奖励/旧卡保护、胜负和整局重置。
│   ├── roguelite_kill_run.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_launch_rewards.gd  # 双发容量/串行恢复/幂等应用与滑行独立材质回归。
│   ├── roguelite_launch_rewards.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_live_tuning.gd  # 实时滑杆/数字接线、真实冲量、成长/重开、已有/新敌人、暂停所有权与存取隔离回归。
│   ├── roguelite_live_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_presentation_interface.gd  # 敌人视图替换、生命面板、真实拒伤结果和物理签名不变回归。
│   ├── roguelite_presentation_interface.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_reward_effects.gd  # 分级重击、有限二连撞、攻击缩圈、无伤震退与旧局事件回归。
│   ├── roguelite_reward_effects.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_rice.gd  # 平面吸力限幅、生成/过期/暂停、冷却返还与强化链路检查。
│   ├── roguelite_rice.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_run.gd  # 整局清残敌、击杀升级/暂停优先级、五次清波到首领、胜负与十次重开检查。
│   ├── roguelite_run.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_shop_events.gd  # 钱包死亡去重、余额限购、旧报价、商店独立成长与重开回归。
│   ├── roguelite_shop_events.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_smoke.gd  # 俯视发射/接力、默认不跟随、三态障碍反弹、可选引导与回收检查。
│   ├── roguelite_smoke.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_splitting.gd  # 分裂勾选接线、两代生命/预算/整族经济、安全预警与旧局防重回归。
│   ├── roguelite_splitting.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_stage_flow.gd  # 清场阶段边界、危险清理、冷却暂停、准备、免费成长来源与旧点击回归。
│   ├── roguelite_stage_flow.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_theme.gd  # 主题替换/饱饭绘图不改变刚体签名或同伴状态的检查。
│   ├── roguelite_theme.gd.uid  # 关联GDScript稳定资源标识。
│   ├── smoke.gd  # 旧原型停稳、发射、真实接触点、机关、复位、鼠标与进球回归。
│   ├── smoke.gd.uid  # 关联GDScript稳定资源标识。
│   ├── ui_integration.gd  # 主菜单、开发隔离、真实血量、四卡和暂停重开的接线回归。
│   └── ui_integration.gd.uid  # 关联GDScript稳定资源标识。
├── tools/  # 开发辅助工具，不属于游戏玩法
│   ├── export_windows.ps1  # 隔离导出普通或-LiveTuning实时调参Windows EXE，附策略反馈/说明及源码指纹，保护原配置。
│   ├── project_map.gd  # 读取 Git 文件列表和用途清单，生成/检查项目文件目录。
│   ├── project_map.gd.uid  # 关联GDScript稳定资源标识。
│   └── verify.ps1  # 固定Godot导入、目录与27套新旧行为/完整引擎调参检查入口。
├── .editorconfig  # 统一编码、缩进、换行和文件末尾格式。
├── .gitattributes  # 统一 Git 文本换行，标记图片/音频为二进制。
├── .gitignore  # 排除引擎缓存、本机临时文件、凭据和导出成品。
├── AGENTS.md  # 接手/物理与Git授权规则、最终Review及双线唯一文件负责人和owner边界。
├── CONTRIBUTING.md  # Git分支/Review/授权与A/B独立checkout及用户最终审阅合并约定。
├── README.md  # 游戏介绍、运行方式和面向开发者的总入口。
├── export_presets.cfg  # Windows64内嵌资源试玩导出预设，由隔离脚本设置肉鸽入口，原F5保持。
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

scenes/roguelite/run.tscn → run_arena → run_director（阶段/击杀领奖/胜负）
  ├─ enemy / player_health / hazard_ball（三敌人与可预警危险）
  ├─ run_build → resources/roguelite/upgrades（十五项池/分类权重）
  ├─ boss（可碎模块/撞墙弱点/缺口震波）
  ├─ run_hud（生命/3/4选卡/结算/重开）
  ├─ stage_flow / run_wallet → rest_panel（商店/补给/准备）
  ├─ audio_director → audio_palette（事件音组/声部预算）
  └─ rice_manager → rice_lure / theme_definition（白饭平面力/肥鱼绘图）

tools/verify.ps1 / GitHub CI
  ├─ Godot 导入检查
  ├─ tools/project_map.gd --check（文件目录完整且最新）
  ├─ tests/smoke.gd（旧侧视行为回归）
  ├─ tests/roguelite_smoke.gd（俯视发射/碰撞/接力/归队）
  ├─ tests/roguelite_input_feedback.gd（全屏手势/冷却临界/反馈坐标）
  ├─ tests/roguelite_{enemies,build,boss,run,rice,theme}.gd（整局/白饭/主题规则）
  └─ tests/roguelite_{kill_rewards,kill_run,launch_rewards,reward_effects}.gd（击杀发育雏形）
  └─ tests/roguelite_{audio,hud,feedback_integration,stage_flow,shop_events}.gd（音效/生命/阶段经济）
  └─ tests/roguelite_{crowd,difficulty}.gd（怪群真物理/逐波压力预算）
  └─ tests/roguelite_{damage_contacts,enemy_readability,splitting}.gd（漏伤/范围与生命/可选分裂）
```

## 策划实时手感

```text
tuning_run.tscn → 正式run + live_tuning + full_tuning（完整属性/快捷基线/存取）
  ├─ tuning_panel + full_tuning_view（F1分类/搜索/分页/各类型编辑）
  └─ tests/roguelite_{live_tuning,full_tuning}.gd（实时物理/全局恢复/类型/资源隔离）
```

## 玩法实验室与表现接口

```text
scenes/roguelite/gameplay_lab.tscn → gameplay_lab（B线完整夹具）
  ├─ DemoLaunch.launch_with_drag → player_ball → combat_body（正式固定发射/真实接触）
  ├─ RunDirector.spawn_enemy/queue_split（正式敌人与分裂规则）
  ├─ boss / player_health / hazard_ball（范围、炮台和首领夹具）
  └─ DemoLabPanel → GameplayLab（白名单请求、读数、有界日志、本地预设）

enemy.tscn → DemoEnemy（玩法状态/事件）
  └─ DemoEnemyView（只读快照与绘制替换）
run_hud.tscn → RunHUD（奖励/结算）
  └─ DemoHealthView（只读生命面板替换）

tests/roguelite_presentation_interface.gd（换图不改物理/面板请求）
tests/roguelite_gameplay_lab.gd（固定发射/八类夹具/预设/日志边界）
```

图中关系是人工维护的架构摘要，文件树由工具生成；改变模块关系时也要更新生成器中的摘要，并通过 Review。维护方法见 [教程 002](tutorials/002-project-map-and-review.md)。
