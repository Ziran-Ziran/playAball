# 011：手绘碰撞风格素材、动画、音频与菜单角色互动

日期：2026-11-03。修订：R2，菜单角色优先Live2D，供原执行对话中断后续接。本规划对话只修改文档；用户报告另一个执行对话已运行一部分，其素材、调用和进度必须由原执行对话核验，不能沿用“尚未执行”当作全局状态。

用户已选择：**精致手绘、圆润可爱、荒诞幽默，并增强碰撞感；图片资源优先全部使用内置 image_gen。** 这项风格选择不等于已认可某张样图。本文提供开工依据，不授予 Git 提交、上传、PR、合并或无限生成预算。

## 0. R2修订与原对话恢复规则（优先于旧路线）

用户要求修改计划，停止当前执行后回到原对话继续；不是全部重做，也不是授权本规划对话接管生图或终止系统进程。

1. 原对话恢复后先停发新生成请求，清点已提交/等待返回/下载完成的请求、输出文件、认可结果、失败记录、已花费与剩余额度。中断聊天不代表云端请求取消或费用退回；结果未明时先查已有请求状态，不盲目重发。
2. 从原对话上下文和实际文件恢复，不批量扫描私人目录。保留已认可风格、卡牌、特效原画、音频及有效授权；原角色和兼容的拆层仍可复用。旧Godot角色绑定保留为实验草稿，暂停扩展，不删除、不覆盖。
3. **只改变菜单角色路线：优先Live2D Cubism绑定与Godot桥接；战斗特效继续Godot原生，卡牌继续内置生图，声音继续ElevenLabs。** 不把卡牌转成Live2D，不迁移引擎、不降级Godot。
4. 新增L0兼容性验证先于完整角色拆层与绑定；可交替推进不依赖Live2D的卡牌、音频任务。原对话已有预算与认可继续有效，不重问、不重花首轮配额；“最多6张/6个音频”是原首轮总上限，已产生输出计入，换路线不重置。
5. 如果原对话在另一checkout执行，先辨明实际目录与修改，不复制覆盖整个工程；不能假定本修订文档所在目录就是原执行目录。在原对话粘贴第11节即可，不需要创建第三个对话或自动化。
6. 本修订不授权购买软件、雇佣绑定师或增加付费生成。遇到预算、兼容、绑定技能阻塞时继续独立任务，并一次讲清需要用户做的具体动作。

## 1. 目标、事实与范围（初次调研快照，恢复时重核）

- 当前基线：main / a4926eb；保留原有 project.godot 修改。新会话必须重新核验设备、工作区与 Git，不能照抄本机事实。
- 当前菜单角色 `assets/ui/fat_fish_menu_character.png` 是蓝发、鲨鱼尾、抱饭碗的 Q 版角色；不能误认成战斗中的圆球鱼。默认保留其身份与主要造型，先用原图拆层试验，不擅自换角色。
- 当前菜单脚本 `scripts/ui/main_menu.gd` 只摆放静态 TextureRect、按钮及音量面板，没有角色互动。
- 现有普通成长 15 种、另有强身兜底。按有限等级分别出图、可重复项共用图，合计 **28 张基础卡面**；不是 16 张随意配图，也不是无穷生成饱餐/强身等级。
- `audio_palette.gd` 当前用程序合成 10 类短音，`audio_director.gd` 有声部上限、优先级和事件冷却。没有完整 BGM 管理层；素材替换不能假定现有接口已经支持外部采样或音乐。
- 原有素材被用户否定，不作为已批准母版；已有菜单身份可作参考，具体笔触、色板及新卡面仍需样张确定。
- 这轮目标是视听表现；不新增主动技能、不改变卡牌效果/等级/数值、碰撞形状或物理规则。

## 2. 制作路线与职责

推荐：**内置生图制作母版、卡面、可拆角色、纹理和特效关键形状；菜单角色用Live2D Cubism精细绑定，Godot负责输入/状态与运行时桥接；战斗特效用Godot原生动画/粒子/着色器；ElevenLabs负责音效与音乐。** 生图不能直接输出可用.moc3模型或音频。Live2D本身也不保证质量，拆层、网格/变形器、参数关键形和曲线都需制作与验收。

可选路线比较：

| 路线 | 优点 | 成本与适用范围 |
| --- | --- | --- |
| Live2D Cubism + Godot桥接，菜单角色优先 | 专门制作脸部转向、眼睑、嘴型、表情混合与头发/尾巴二级运动 | 社区桥接需验证4.7.1/Compatibility/导出；完整绑定可能需人工制作，先过L0与小样 |
| Godot原生分层/骨骼与逐帧 | 战斗碰撞、UI及简化角色仍适用 | 不再作为菜单最终默认路线；Live2D受阻时报告原因，不静默降级 |
| 全逐帧/预渲染视频 | 单个固定演出可以细腻 | 眼神追踪与任意位置触摸难以连续响应；帧数、漂移、体积成本高，适合胜利等固定片段 |
| 3D角色 | 能制作更大角度的姿态与空间运动 | 需要建模、材质与3D绑定，本轮不扩展 |

A 负责独立素材、表现组件和展示场景；B 负责混合 actor、HUD、run 接线整文件。沿用[计划008](008-parallel-development.md)与[教程020](../tutorials/020-parallel-workflow.md)。单 Agent 串行实施亦遵守整文件边界；涉及 B 文件先登记接管，不能把“A线生图”扩成随意改玩法。用户是最终审美验收人和仓库 owner。

## 3. 分阶段执行与验收

| 阶段 | 工作及交付 | 验收/继续条件 |
| --- | --- | --- |
| P0 清点 | 从升级资源、真实事件及场景导出素材清单，登记尺寸、用途、等级、触发事件、负责人、现有接口、候选/认可状态 | 16 种卡与实际等级一致；拟新增事件明确标“待接线”；登记本轮生成数量和费用上限 |
| L0 Live2D技术验证（先于P4） | 在当前工程忽略的.local中建立最小兼容夹具，不clone游戏仓库；核验社区桥接、Cubism SDK/Core及示例的版本/授权，以允许本地测试的现成运行时模型验证 | 固定Godot4.7.1标准版、Compatibility；加载、透明/遮罩、参数驱动、Windows导出后独立运行、重复进入/释放都需实测。记录版本、构建与另一电脑复现方法；不要求先安装Editor |
| P1 风格小样 | 首轮最多 6 张图片输出：2 张风格候选板；选中方向后做“！？肥肥？！”、外包、快速上弦各 1 张样卡及 1 张重击特效关键形状图。先附原角色/候选风格参考 | 用户认可方向才扩批；对比原尺寸、实际卡面窗口、灰度轮廓和战斗缩略尺寸。每个阶段只锁定关键选择，不逐张反复索权 |
| P2 卡面生产 | 按母版完成 28 张（包含认可样卡，非额外重复生成）；同一卡所有等级对照；实际选卡面板显示当前→下一等级 | 主体身份/画法一致，等级差异不靠单纯换色，卡面不暗示不存在的规则；四卡最窄布局不压标题与收益 |
| P3 碰撞与技能动画 | 先精修重击、接力、炸鱼三种演示，再覆盖第5节清单；交关键图、纹理、可编辑 .tscn 与实际运行录像 | 有受力方向、压缩/爆发/回弹/消散层次；不覆盖危险区域与数值；真事件驱动，暂停、重开、切图无残留 |
| P4 菜单互动（L0通过后） | 复用可用拆层/PSD→Cubism绑定→转头追踪、眨眼、戳脸小样→认可后完善摸头/护食/尾巴及Godot交互 | Cubism与Godot分别检查；无五官穿帮、发片撕裂或僵硬贴片感，形变与触摸方向一致；美术验收独立于技术检查，保留模态/键盘边界 |
| P5 声音 | 权限和预算核验→6 个试听文件→选音色→生产全套事件采样、音乐与短乐句→混音 | 先辨清轻/重/击杀/受伤；密集战斗不过载；音乐真实循环接缝试听；API 失败不产生重复付费重试 |
| P6 集成及交付 | 保留旧版回退，按资源清单接线、Godot导入与回归、实际小窗口/密集战斗/菜单互动检查；更新教程、用途、目录与STATUS | 技术检查与用户审美/试听分开记录；仅准备进入Git阶段时按REVIEW做独立审查。无授权不commit/push/PR/merge |

P1 的六张是首轮上限，不是质量承诺或无限重试授权。全套费用上限由用户在开工时给定；缺少上限时先完成清点与提示词、整理现有参考，等预算回复再开始依赖该上限的批量调用。内置生图额度和 ElevenLabs 费用分别管理。

## 4. 卡牌清单与可直接组合的提示词

### P2返修登记（2026-11-04，用户否定整套同质化）

用户指出这批卡面姿势/构图重复，要求每张先有相应描述再生成。此前数量、等级和导入检查通过不代表画面设计通过。保留三张一级的历史母版认可记录，但当前整套恢复待审/返修；原28图和36次生成记录不删除、不归零，不覆盖正式HUD。

后续用户明确要求本对话持续做到卡图与文字实装，已依[计划012](012-card-art-integration.md)完成28图/16套文案的正式HUD和本地Windows包接线，新增图仍待审美验收。下段首批三张及旧P2记录保留为历史，不代表当前仍停在图鉴阶段；Live2D改交另一对话先讲解。

后续出图以[28张逐张描述R3](../art/card_briefs_r3.md)为当前内容依据：统一人物身份和手绘语言，不统一机位/姿势；同系列用不同受力阶段和视角区分，不只微调线条。先返修运筹、保龄球、饱餐三张，候选保存.local且分别审看，不因预算无限就再一口气扩满。该规则取代下文旧模板中“所有图锁定构图”的要求，旧生成prompt仍保留为历史证据。

### P2执行登记（2026-11-04，原执行对话）

用户在圆眼“奶凶”v2对照后回复“ok下一步”，确认人物表情方向并继续制作。此时首轮6张、眼神定向修改3张均有记录；P2沿用已明确的无限生成预算，不重置旧计数。复用heavy/companion/cooldown一级的圆眼v2，补齐其余25张，组成16种成长共28张基础插画。新图的技术检查与逐张审美认可分开。

- [x] 将已确认三张圆眼v2保存为一级素材，保留原版与失败候选；完整引用和提示词入清单。
- [x] 根据真实升级资源建立28项ID/等级索引，每项单独调用内置生图；同一等级系列以前一级为参考，数量/形变/时序逐级变化。卡牌改用拟人鲸鱼娘，旧表的“圆鱼主体”不再作为出图指令。
- [x] 建立独立CardArtGallery可编辑场景与小脚本、只读JSON索引。展示当前→下一等级收益、实际效果文案、三/四卡和1024/1280宽度；不修改B整文件负责的正式HUD、actor、run接线或成长规则。
- [x] 检查28项无漏/错级，按图核对伙伴数量、重复项和效果含义；导入设置/目录/教程/STATUS同步，生成原图、等级对照和实际Godot尺寸截图。
- [ ] 向用户交付整套候选及可打开的展示场景；未认可项、失败/未知请求如实列出，不盲目重发。此阶段不触发commit/push/PR/merge或自动化。

当前唯一写入者为本对话Codex，范围限assets/cards、独立素材清单/展示组件和文档；正式游戏混合文件只读。验证采用实际素材清点、语义自查、真实Godot导入/渲染与边界读数；展示样板是可逆的表现工作，不为它添加镜像实现的单元测试。

### 4.1 风格母版提示词

> 为《玩个球》设计一套精致手绘的游戏美术风格候选。圆润可爱，带荒诞幽默，重点是扎实的碰撞、挤压与弹性：软身体受力变扁，重物有压迫感，清晰的斜向动势与回弹弧线。线条干净而有粗细变化，手绘明暗细腻，主轮廓在很小尺寸仍可辨认。用少量冷色主体与暖色撞击焦点组织层次，避免密集碎屑、满屏泛光和塑料质感。保持参考角色的蓝发、鲨鱼尾和饭碗身份；战斗鱼球是同一世界观的独立形象，不把它误画成同一具身体。展示角色、重击瞬间、伙伴接力与升级插画的统一视觉语言；这张是风格讨论板，不直接当游戏精灵切片。

色板是建议，需随用户选中的母版锁定。每个资产都使用同一张认可风格图及相应角色图作为参考，记录完整提示词与参考文件；不能只依赖相同文字或随机种子保证一致。

### 4.2 卡面通用前缀

> 为《玩个球》绘制单张升级卡插画，只生成插画区域，不画卡框、文字、等级数字、按钮、水印或 UI。严格沿用附带母版的角色比例、轮廓线粗细、材质、明暗和配色，同一主体不能换脸换服装。围绕一个清晰动作讲清升级含义，用接触形变、惯性、回弹和少量方向笔触表现碰撞感。主体集中，外围留出裁切安全边距；背景简洁，缩小后仍能识别。不能出现未设计的武器、伙伴数量或技能。下面是本张的内容与等级约束：

每次调用拼接：通用前缀 + R3中本张独立描述 + 对应真实等级约束。参考图只锁定身份、眼型、服装和笔触；本张机位、姿势、动作阶段按独立描述执行。构图比例先量实际卡框插画槽，再决定源图比例，不能用整张竖卡尺寸强塞现有槽。等级和收益由 Godot 字体绘制。下表为历史主题提案，涉及“圆鱼/同姿势”的句子不再直接用作出图命令。

| 名称 / 资源ID | 图数 | 主题与逐级变化提示词（提案，不能视为机制变化） |
| --- | ---: | --- |
| 保龄球 / bowling | 1 | 一条被撞扁的敌鱼沿清晰折线撞到另外两条敌鱼，三个接触点递进，末端停住，不继续无限传代。 |
| 运筹 / choices | 1 | 蓝发角色从容展开四张空白小卡，四个选择清晰分开，无第五张；表现多一个选择而不是伤害增加。 |
| 外包 / companion | 3 | 主鱼以相同姿势把冲量交给小伙伴；一级只出现1名伙伴，二级2名，三级3名。主鱼、伙伴造型、光向和构图固定，新增伙伴处留清晰负空间。 |
| 快速上弦 / cooldown | 4 | 鱼形弹射装置的弹簧逐步紧凑、回弹节奏更利落；一级单段回弹笔触，二级双段，三级三段，四级完整紧凑回旋。不能画成四个弹槽或连续无限开火。 |
| 双发 / double_launch | 1 | 同一弹射器两个明确的储能珠，前后两次弹射弧分开，不能出现两条永久同步主鱼或无限弹药。 |
| 补刀 / echo | 1 | 一次主撞击后接着一个更小的余震击点，前大后小且时序清楚，不画无限连锁。 |
| 炸鱼 / explosion | 1 | 被主球激活的小伙伴撞中目标，接触处爆出紧凑的暖色鱼鳍状冲击花，边缘稀疏，幽默而有重量，无血腥。 |
| 一键跟随 / follow | 1 | 小伙伴在主鱼身后沿弯曲路线有序归队，像松软小车厢，保留可见间隔，不能画成穿墙或瞬移。 |
| 逍遥游 / glide | 3 | 同一鱼球轻盈擦过水面般的平面；一级短滑痕，二级更连贯的长滑痕，三级完整舒展的弧形滑痕。鱼体大小不变，不添加翅膀与飞行含义。 |
| 饱餐 / heal | 1 | 蓝发角色满足地抱着一碗白饭，脸颊柔软鼓起，两枚温暖小光点贴近饭碗；不画生命上限增加。 |
| ！？肥肥？！ / heavy | 3 | 同一圆鱼压向可变形软垫，一级浅凹、二级深凹并明显压扁、三级强烈接触压缩与稳重回弹。角色身份和外形识别固定，不暗示碰撞体变大。 |
| 冲刺！冲刺！ / launch_power | 3 | 同一鱼球从弹性起点斜向冲出；三级依次增加起点压缩、短粗方向笔触与爆发层次，主鱼占画比例固定，不新增火箭武器。 |
| 退！退！退！ / pulse | 1 | 傲娇鱼以圆润弹性推力把周围敌人推开，敌人惊讶后仰而完整存活，不出现爆碎、掉血或无敌护盾。 |
| 接力 / relay | 1 | 主鱼与至少两名伙伴按清晰先后传递一道动能，交接点局部挤压，路线不交叉，不画无穷复制。 |
| 小小的也很可爱 / shrink | 2 | 敌人保持完全相同体型，外围危险波纹一级略收紧、二级更明显收紧；用外圈空间表达范围缩小，绝不缩小敌人身体。 |
| 强身 / vigor | 1 | 健康圆鱼与一个新增的心形容器，表现生命容量提升和恢复，温暖扎实，不画攻击爆炸。 |

### 4.3 等级一致性编辑提示词

> 附图只作主体身份、脸、服装、色板与笔触参考。按照本张预先写明的机位、动作阶段和主体层级重新构图；数量/受力/节奏要在小尺寸有明显区别，不照搬上一等级姿势后只加少量笔触。不得增加其他机制象征。输出完整独立插画，不含文字或卡框。同系列需要连贯主题，不需要相同机位。

## 5. 特效动画：生产清单与提示词

共同规范：以接触点和真实法线/速度定方向；轻、重、击杀分级；危险预警与装饰分层。预警的半径、缺口、剩余时间必须来自玩法，不能烘焙进随机生图。Compatibility 下先验证普通 CanvasItem 材质、CPU 粒子与混合方式；不要假定高级屏幕后处理可用。

| 组 | 需要制作的状态 | 差异化设计 |
| --- | --- | --- |
| 碰撞 | 轻碰、重击、有效伤害、击杀、玩家受伤、装甲破裂 | 轻碰为短挤压气泡；重击为压扁菱形核+鱼鳍回弹；击杀是轮廓解体而非更大白闪；受伤用独立辨识语言 |
| 发射/成长 | 发射、冷却回一格、双发回槽、饱饭强化、追加补刀 | 发射有反向挤压与短尾迹；真实回能事件才亮起；补刀为延迟的小二拍 |
| 伙伴/技能 | 伙伴受撞激活、接力、跟随归队、炸鱼、无伤震退 | 接力交棒、炸鱼紧凑爆花、震退柔软压力波；三者轮廓和时序不能共用一种环 |
| 场景/敌人 | 饭吸引与拾取、传送进出、弹体/撞击、尖刺受伤、机关接触 | 吸引有稀疏向心弧；传送双端相位卷曲；机关反馈按材质区分，不能掩盖碰撞边界 |
| 首领 | 蓄力、冲撞、部位受击、模块破坏、破防、恢复、震波缺口 | 保留真实安全缺口，破防的脆裂与恢复的合拢可区分；标签不压危险圈 |
| UI/结算 | 卡牌入场/悬停/选中、升级、购买/失败、过波、胜利/失败 | 用纸张弹性、压印、短促光箔表达，不把长演出强塞每次碰撞 |

### 特效原画提示词（内置生图，透明输出）

> 为《玩个球》制作单个二维手绘重击特效关键形状，透明背景。冲量从左向右：接触中心是被压扁的短粗菱形亮核，两侧是像鱼鳍一样向后卷曲的短弧，外缘三到五枚大小有层次的碎光。重心紧凑，负空间充足，青蓝冷轮廓与少量奶油暖亮部，厚实、弹性、略带荒诞喜感。仅绘制特效，不画角色、地面、文字、完整光圈、背景和烘焙阴影。边缘干净，无黑底白边，实际小尺寸仍辨识出主方向。附带母版决定笔触和色彩。

### 炸鱼原画提示词

> 沿用认可的手绘母版，透明背景，只画炸鱼爆发的峰值关键形状。一个紧凑的不规则暖色爆心，外缘像三片胖鱼鳍向外翻弹，少量米粒般的短碎光，中心留出目标轮廓可见空间。与重击的单向压缩不同，这次有短促径向张开，但不要完整实心圆盘、巨大烟团或占满画面的光。无角色、无文字、无危险范围刻度。

### 接力原画提示词

> 沿用认可的手绘母版，透明背景，绘制一段从左向右交棒的动能笔触：前端像压缩的小鱼鳍，后端是一长一短两道弹性拖弧，中间留空，不连成实体管道；青蓝为主、接触端一点暖亮。仅一段可旋转的装饰纹理，不画角色、箭头文字、完整轨迹或圆形范围。

### 动画实施提示词（交给开发Agent，不是生图模型）

> 将认可特效关键图做成可编辑 Godot 表现组件。重击建议起始节奏：0–40ms视觉接触压缩，40–100ms峰值弹开，100–220ms弧线回卷，220–350ms稀疏消散；具体以真实速度和试玩调校。接触形变只作用于视图子节点，特效跟随真实接触方向。轻碰明显更短更小；补刀只响应真实延迟伤害事件；接力仅响应真实传能；炸鱼不能新增伤害。使用纹理、局部形变、少量粒子与有设计的缓动，不得把所有反馈替换成换色光圈。不要给每次碰撞添加战斗顿帧或改变物理时间。交付静态拆解、透明背景预览和游戏内录像；标注实际帧率与是否离线渲染。

如确需逐帧：先做 6–8 张关键帧小样，要求同画布、锚点、尺寸、姿态连续，逐帧检查与修图后再扩。生图的一张九宫格不等于可直接使用的精确序列帧；不自动引入视频模型。粒子纹理使用真实 alpha，发光纹理按混合模式检查黑白边。

## 6. 菜单肥鱼：类似米塔的互动感

### 调研结论与边界

玩家记录可证实 MiSide 主菜单对连续点击角色脸部等操作有反应；这不是对原作内部绑定/渲染技术的取证。本文不声称原作采用 Live2D。目标是借鉴“角色注意到玩家并回应”的体验，不复制原作人物或素材。

本修订优先Live2D精细绑定。Godot负责输入、状态和菜单导航，Live2D负责角色形变、表情和二级运动。原生骨骼继续用于战斗，不再凭“可以做”就视为达到菜单质量目标。

Live2D官方把Godot桥接列为社区SDK；候选gd_cubism是非官方项目，本计划未验证其与Godot4.7.1的兼容性。L0需核验Editor导出目标与Core匹配，并实际测试Windows导出，不能只验证编辑器显示。插件/SDK须有两台电脑可复现的配置；Core和示例素材按各自条款管理，不随意提交下载包或示例角色。

### 资产准备

先以菜单现有蓝发角色为身份参考。分组建议：后发、尾巴、躯干/裙子、左右手臂、饭碗、脸底、左右眼白、左右瞳孔与高光、上下眼睑、眉毛、嘴、前发、发饰。最终层数按遮挡关系确定，不为凑数机械拆分。各层需要：统一画布、基准姿态、层叠顺序、支点、遮挡后补画区域；不能从整图硬切后留下眼洞或关节空隙。嘴型至少平静/鼓嘴/微笑，眼睑有开/半闭/闭眼。

### 分层编辑提示词（内置生图）

> 编辑附带的蓝发鲨鱼尾抱饭碗Q版角色，为二维互动绑定制作【本次指定部件】独立图层。严格保持原图角色身份、姿态、透视、线条、服装、比例、光向与颜色。透明背景，只保留指定部件；补画被邻近部件遮住的自然延伸区域，便于移动后不露洞。保持参考画布比例和定位，不能自动居中放大或改变缩放。不要增加文字、编号、棋盘底、额外肢体或背景。若输出位置或画布无法精确保持，交付时明确标注，并在绑定前按参考锚点重新校准，不能假装已经无缝对齐。

每次只处理一个部件或明确相关的一组；拆层叠回原图验证后才用于绑定。生图不保证直接得到可用PSD、精确对齐或Cubism模型。先复用已有可用层，补齐遮挡区域，按Cubism导入规范组织统一画布的分层PSD，再制作网格、变形器和参数关键形。不能将PNG改名为PSD或.moc3冒充模型。

### Live2D绑定任务提示词（交给实际绑定操作者）

> 为蓝发鲨鱼尾抱饭碗Q版角色制作精细Live2D模型。先做小幅连续左右/上下转头、自然五官透视、协调的眼球和眼睑、完全闭合的眨眼、轻呼吸和前后发不同延迟惯性；戳左/右脸时局部压缩，并联动嘴角/眉眼情绪后平滑恢复。避免同步摆动、瞳孔越界、转头拉长脸、发片露洞与关节硬折。保留原身份与造型。检查参数极值、组合极值和中间值；小样认可后扩摸头闭眼、护食、甩尾与不满恢复。交参数表（包括自定义触摸参数）、图层/变形器说明、可编辑.cmo3及实际动画源、完整运行时model3.json/moc3/纹理、物理/表情/动作文件，未用项说明。附Cubism预览与Godot实际互动录像，分别标明来源。

Agent先检查实际可用的Cubism操作和绑定能力；没有可靠制作途径就明确用户或绑定师需要完成的步骤，同时继续原画、PSD、参数设计和接入。不得承诺自动产出专业绑定，亦不因缺绑定师停止所有工作。需要委托时先准备交付需求和成本范围，用户决定后才行动，不代发消息或下单。

### 交互脚本提示词

> 为《玩个球》建立独立Godot菜单交互组件，加载已验证的Live2D模型，沿用菜单布局。按实际参数表映射鼠标与触摸，协调Cubism眨眼/呼吸/物理/表情/动作更新顺序，避免相互覆盖。缺少模型参数时补绑定，不用整图缩放/旋转冒充完成。空闲时轻呼吸、眨眼、头发与尾巴有延迟跟随；鼠标靠近时眼睛先注意到光标、头部小幅跟随，瞳孔在眼白遮罩内移动，不越界。头顶慢速连续划动触发闭眼享受与发梢回弹；快速戳脸触发受力方向的脸颊压缩和短暂鼓嘴；点饭碗触发护食抱紧与小幅饭粒跳动；点尾巴触发甩尾和回弹；连续乱点后进入短暂不满再恢复，避免声音叠爆。不要整张图僵硬摇摆来冒充这些动作。
>
> 使用可调支点、眼动幅度、跟随时间、触摸距离/速度阈值、反应冷却和动作优先级。角色与光标统一到局部坐标，支持1280×720与1024×576。以每个部位的实际可见形状命中，透明空白不拦截菜单；一次点击只触发一个部位，不穿透到开始/设置/退出。设置面板打开时停止角色输入和触摸音；鼠标离开窗口后平滑回中；失焦、切场景、回菜单正确复位。提供减少动态效果选项，键盘操作不依赖摸鱼才能开始。只实现菜单表现，不接触战斗物理。

L0通过后先做转头追踪、眨眼、戳脸小样，附轻呼吸和头发惯性；认可后补摸头、饭碗、尾巴与连续点击。无需摄像头、麦克风、VTube Studio或在线对话服务；最终交可编辑模型源与运行时资源，不能只交录像。

## 7. 音效与背景音乐

### 7.1 生成与接入方式

- 图片走内置生图；音频走 ElevenLabs 的 Sound Effects 与 Music 两条独立能力，不能用TTS假装打击音，也不能把音效loop当成整首BGM。
- 声效初版范围：轻碰/重击/击杀/发射各4个变体，受伤3个，白饭拾取3个；补刀、炸鱼、接力、震退、传送进出、冷却回槽、首领蓄力/冲撞/破防/模块破坏各2个；UI悬停/确认/取消/购买成功/购买失败/升级/过波各2个；菜单摸头/戳脸/饭碗/尾巴各2个非语言反应。P0依真实接线去重，不为了凑数量补无用音。
- 音乐初版：菜单约60秒、普通战斗约90秒、首领约90秒、商店/补给约45秒；另胜利/失败短乐句。普通战斗先做一首，高压变奏与分轨是后续选项，不擅自翻倍预算。
- 首轮最多6个试听输出：轻碰、重击、受伤、炸鱼各1个，以及菜单和战斗各1段15–20秒配器样例。只在获认可后制作正式长度。
- 高频短音先生成API允许的长度，再剪出干净的0.05–0.4秒有效音；提示词写瞬态长度，不把API duration设为不支持的0.1秒。当前官方文档声效时长范围为0.5–30秒，开工再次核对。
- 不承诺所有套餐都可直接生成48k WAV。以账号实际允许的最高合适输出保存原始文件；必要时本地剪辑/转换成游戏WAV（短音）和Ogg（长音乐），转码不能提升原始音质。保留原始输出。
- 采样应有多种演奏变化，不能只变播放速度；削除多余前导静音、避免剪切爆音、密集混音留余量。受伤/危险提示优先于击杀碎音；保留当前声部预算原则。
- 新增独立音乐播放器/资源和 Music 总线，SFX/UI/Music分控并尊重现有静音设置；不能因为主音量已存在就认为音乐设置接线已经完成。换场景淡入淡出，暂停行为明确、可复现。
- 乐曲提示词描述配器、速度、结构与频谱空间，不指定现成歌曲或艺术家。循环需要按节拍剪辑、尾音处理并连续试听至少三遍，不能仅凭提示词含“seamless”就宣称无缝。

### 7.2 声效提示词

通用尾句（与下面任一条组合）：`One isolated game sound, dry close-miked studio quality, clean onset, no voice, no music, no background ambience, short controlled tail, no harsh clipping.`

| 用途 | 英文提示词主体 |
| --- | --- |
| 轻碰 | A plump rubbery fish gently bumping a wooden rim: a crisp tiny tok followed by a soft elastic wobble, tactile and playful, a very short transient, no deep explosion. |
| 重击 | A heavy rounded body slamming into a compact armored target: a sharp woody crack, a weighty mid-low thump and a short rubber recoil, punchy and slightly absurd, controlled bass, readable through busy combat. |
| 击杀 | A brittle toy-like armor shell snapping into a few small pieces, a tight pop followed by tiny dry fragments, satisfying and brief, clearly different from player injury. |
| 玩家受伤 | A short unmistakable warning impact: compressed soft body thud with a rough descending tonal scrape, urgent but not piercing, distinct from reward and enemy destruction, no human scream. |
| 发射 | A soft elastic body pulled tight and released with a fast whip, a compact rising swish ending in a tiny rubber snap, energetic rather than airy. |
| 炸鱼 | A compact cartoon fish-shaped burst: tight bass pop, papery crack and three tiny rice-like ticks, explosive yet controlled, no cinematic rumble. |
| 补刀 | A tiny delayed follow-up snap, crisp and dry, deliberately smaller and higher than the first heavy impact, one secondary hit only. |
| 接力 | A kinetic baton handed from one soft body to another: two closely spaced elastic clicks and a brief upward gliss, directional and nimble, not a reward chime. |
| 震退 | A short expanding puff of elastic pressure, rounded low-mid push with soft radial air, no cracking, no destruction, no magical shield hum. |
| 白饭拾取 | A tiny ceramic tick, a soft rice pop and a restrained warm two-note sparkle, delicious and tactile, no chewing voice. |
| 回能 | A compact mechanical slot settling into place followed by a tiny bright dot, short and neutral, not a full upgrade fanfare. |
| 传送 | A brief folded-air curl that tightens and disappears; create an entry version with falling motion and an exit version with a compact outward release, without long sci-fi drones. |
| 首领 | For [charge / dash / armor break / module destruction], create a distinct compact heavy-toy mechanism cue: [tightening creak / fast mass swish / brittle layered crack / short collapsing clatter]. Preserve midrange clarity, no trailer boom. |
| UI | A [hover / confirm / cancel / purchase / denied / upgrade / stage-clear] cue made from [tiny paper brush / rounded ceramic click / muted wooden tap / warm double clink / dry low knock / short rising pluck / relaxed three-note resolve], restrained and tactile. |
| 菜单角色 | A tiny [soft pleased elastic squeak / annoyed rubber puff / ceramic bowl clink / flexible tail flick], expressive and charming, one short gesture, nonverbal, no spoken syllables, no baby voice. |

首领/UI/菜单模板每次只替换一个用途和其对应声源，一次生成一个声音；不要让API把整个列表串成一条。

### 7.3 音乐提示词

菜单：

> Original instrumental game menu music, about 60 seconds, 92 BPM, whimsical and slightly cheeky. Rounded pizzicato bass, dry brushed percussion, playful clarinet-like phrases and sparse glassy mallet accents. A blue-haired shark-tailed mascot guards a rice bowl; the mood is cozy, bouncy and a little smug. Introduce a short original rhythmic motif, keep the arrangement spacious, use an eight-bar repeating structure, stable dynamics, loop-friendly opening and ending with matching harmony, no vocals, no sung syllables, no abrupt finale, no imitation of an existing soundtrack.

普通战斗：

> Original instrumental soundtrack for a top-down elastic collision roguelite, about 90 seconds, 126 BPM. Punchy syncopated wooden percussion, rounded plucked bass, nimble mallets and short mischievous wind phrases. Convey weight, bounce, chain reactions and playful absurdity. Leave space for impact effects, avoid sustained sub-bass, piercing leads and constant crash cymbals. Reuse the approved original menu rhythmic motif while increasing momentum. Clear eight-bar phrases, controlled intensity, loop-friendly harmonic ending, no vocals and no dramatic final stop.

首领：普通战斗配器与原创动机的基础上改为 `about 90 seconds, 138 BPM, heavier low-mid percussion, tense short ostinatos, alternating pressure and brief breathing space, readable warning cues must remain audible, no cinematic wall of sound`。

商店/补给：菜单动机基础上改为 `about 45 seconds, 80 BPM, sparse ceramic taps, warm plucked chords, relaxed offbeat humor, very light percussion, no urgency, loop-friendly`。

胜利/失败：分别生成 `an original 3–5 second instrumental victory tag, rounded upward three-note motif, confident soft final landing` 与 `an original 3–5 second instrumental defeat tag, a gently deflating descending motif, humorous rather than tragic`。短乐句走音乐或合适的音效能力，记录实际采用方式。

## 8. 开工前配置：已查事实与用户需要准备的事项

本次只读核验设备为 LAPTOP-8GS4N5SG、Windows10.0.26200、用户Ziran、工作区C:/Users/Ziran/playAball。已发现Git2.53、Node24.19、Python3.14；桌面Godot实际输出4.7.1.stable.official.a13da4feb，不能把本机路径写进运行代码。

1. **内置生图：无需额外配置 OPENAI_API_KEY 或安装绘图软件。** 开工时确认当前会话仍提供image_gen即可。若不可用，报告阻塞，先整理素材和提示词，不擅自改用Seedream、付费API或用程序占位图冒充完成。
2. **ElevenLabs Key已检测到：** 当前进程与当前用户环境都存在 `ELEVENLABS_API_KEY`，没有打印或保存其值，未请求API；ARK_API_KEY亦存在，但依用户偏好不作为本批默认图片通道。存在不等于有效，且不代表拥有SFX、Music和所需输出格式权限。
3. 用户登录ElevenLabs检查Key允许Sound Effects与Music、剩余额度与消费上限；不必把Key贴到聊天。Music API权限、费用和游戏分发许可按当时账号/条款核验，不能由“有Key”推断。官方Music条款当前区分独立游戏等用途；正式发布前留存适用条款与生成记录。
4. **额度沿用原对话已明确的预算、上限与已消耗数量，不能重置。** 没有明确预算才问一次，继续免费清点/L0调研。Editor购买、绑定委托和付费素材的成本另列，不能混入原音频预算。
5. 可选参考：喜欢的2–3张卡牌/碰撞动画/角色互动片段；提供米塔某段具体互动时间点可进一步对齐节奏。没有参考也能按本计划先做小样，不把补参考变成强制前置。
6. **现在：** 用户在原执行对话停止当前轮，确认停止后发送第11节接续词；不需要杀Godot/系统进程。此规划对话不接管实施，原对话恢复后是实现唯一写入者。
7. **Cubism Editor稍后准备：** L0先用现成运行时模型，不要求用户先购买或学绑定。L0通过、准备自有模型绑定时，再核验是否已安装Editor；缺少时从官方页安装与已测SDK/Core兼容的版本。官方提供42天PRO试用，自首次激活计时，建议准备绑定时再启用；先不买长期订阅。安装与许可接受由用户处理或明确授权。
8. **用户需参与：** 选择已生成样张、确认剩余额度；到了软件安装/SDK许可或绑定能力缺口时按Agent给出的具体步骤操作。如考虑专业绑定师，只需先决定是否采用及预算，Agent负责准备需求与交付清单，不要求用户立即学完整绑定。
9. 无需Spine、Blender、VTube Studio、摄像头或麦克风。FFmpeg初次未在PATH发现，原对话应重新确认已有工具，不重复安装。

## 9. 文件落点、清单和验证

拟新增目录（初次规划，恢复时先检查是否已创建）：`assets/cards/`、`assets/vfx/`、`assets/ui/menu_character/`、`assets/audio/sfx/`、`assets/audio/music/`；按导入器实际限制确定最终尺寸，不把2K源图无脑作为游戏纹理。

拟新增独立组件：Live2D菜单交互适配器.tscn/.gd、VFX展示场景、外部采样资源和音乐管理组件；已有对应实现则增量修改。自有Live2D资源建议放assets/ui/menu_character/live2d/，可编辑源按体积及协作需要登记。L0测试位于.local，不擅自改正式入口或全局渲染设置。接线可能涉及 `scripts/ui/main_menu.gd`、`scripts/roguelite/run_hud.gd`、`scripts/impact_feedback.gd`、`scripts/roguelite/audio_palette.gd`、`scripts/roguelite/audio_director.gd` 和对应场景；开工读实际接口后登记唯一写入者，不在本计划中虚构现有API。

每项素材记录asset_id、卡ID/等级或事件、用途、源文件、实际像素/时长/采样率、alpha/锚点、母版参考、完整提示词、生成工具及实际模型（如返回）、请求/生成记录、用户认可状态、授权说明和接入位置。提示词与索引入库，密钥不入库；候选和失败输出放忽略的.local，正式采用素材与.import按项目规则管理，清单不引用只在某台电脑存在的绝对路径。

验证分四层：

- 素材：28张映射无漏项，等级/身份一致，透明边缘和缩图可读，原画与游戏槽匹配；音频无削波/截断/错误格式。
- 行为：菜单真实鼠标与键盘、模态拦截、失焦/离窗、重开；VFX真事件、暂停冻结、生命周期与并发预算；音乐静音/音量/切场景和循环。
- 工程：固定Godot导入、受影响回归及必要时tools/verify.ps1；目录--write再--check；玩法物理签名和同输入对照保持一致，不能用动画回调结算伤害。
- 体验：1280×720、1024×576、四卡长文、密集战斗、低血/首领预警、耳机/扬声器试听。用户尚未认可时明确标候选；headless通过不等于精致、好听或手感验收。

后续交付教程需说明：卡面等级映射与扩展、特效受力/时间参数、Live2D插件/SDK/Core版本与双机复现、模型导出/参数/动作与Godot命中/状态优先级、音频采样与混音/循环修改方法。更新file_purposes.json、FILE_MAP、STATUS；临近Git阶段才触发整套最终Review。

## 10. 调研来源

- [Live2D社区SDK列表](https://docs.live2d.com/cubism-sdk-tutorials/community-sdk/)、[gd_cubism项目](https://github.com/MizunagiKB/gd_cubism)：Godot接入候选，未实测本项目兼容性。
- [Cubism Editor下载](https://www.live2d.com/en/cubism/download/editor/)、[激活说明](https://docs.live2d.com/en/cubism-editor-manual/cubism-editor-activation/)：Editor与42天试用的依据。
- [Live2D表情制作](https://docs.live2d.com/en/cubism-editor-tutorials/expression/)：模型需制作表情参数与形变，非导入单图自动完成。

- [Godot：剪纸动画](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html)、[2D骨骼](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html)：原生分层、骨骼、逐帧混用的依据，教程有4.7适配提示。
- [MiSide 玩家实录指南](https://steamcommunity.com/sharedfiles/filedetails/?id=3383429998&l=english)：连续点击脸部等菜单互动的玩家记录，不是原作内部实现文档。
- [ElevenLabs 声效API](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert)：声效、loop、时长和套餐输出格式限制。
- [ElevenLabs 音乐API](https://elevenlabs.io/docs/api-reference/music/compose)、[Music quickstart](https://elevenlabs.io/docs/eleven-api/guides/cookbooks/music)：独立音乐接口、纯器乐参数和接入。
- [ElevenLabs Music条款](https://elevenlabs.io/music-terms)：按方案/用途核验游戏分发权限。本文不是法律结论或已取得账号权限的声明。

## 11. 原执行对话接续提示词（替代旧开工词）

```text
继续当前《玩个球》任务，但先读取我刚修订的 docs/plans/011-art-audio-interactive-menu.md（R2，尤其第0/3/6/8节）。这是对现有任务的路线调整，不是从头开工。若你当前checkout读不到R2，不切换或覆盖整个工程，以本消息新路线为准并告诉我实际目录。按AGENTS核验环境、Git与实际进度，保留他人修改；不要另建游戏clone/worktree，不commit/push/PR/merge或创建自动化。

先暂缓新生成请求，恢复并汇报你已完成的图片、音频、代码、用户已认可结果、尚未返回的请求和预算余额。已有素材与认可全部保留；结果未明的云端请求先查状态，不能因中断盲目重发。已明确预算/数量上限继续生效，已花费计入，不重新索权或重置首轮额度。缺少信息只问必要问题，并继续独立工作。

整体方向不变：精致手绘、圆润可爱、荒诞幽默，加强碰撞重量、挤压与弹性；图片优先全部用内置image_gen，音效/音乐用ElevenLabs。卡牌仍按实际16种成长、28张基础图与等级对应；现有认可母版继续使用，不重做整套。

本次关键变更：菜单蓝发鲨鱼尾抱饭碗角色优先采用Live2D Cubism精细绑定。停止扩展旧Godot原生角色绑定，保留其草稿及可复用拆层；战斗特效继续Godot原生。不要用整张图摆动、瞳孔平移或视频冒充精细角色互动，不擅自降级/迁移引擎。

先做L0：核验gd_cubism等社区桥接、Cubism SDK/Core版本、许可和当前工具链；在本工程.local内做最小验证，不改正式入口。以允许本地测试的现成运行时模型验证Godot4.7.1标准版+Compatibility下加载、透明/遮罩、参数控制、Windows导出后独立运行与重复释放，记录版本和双机复现方法。此阶段不要求我先买Editor或学绑定。失败时报告具体阻塞与选项，不能静默回退旧方案；卡牌/特效/声音等独立工作继续。

L0通过后整理已有拆层，补画并组织符合Cubism导入规范的PSD，先做连续转头追踪、眨眼、戳脸、轻呼吸和头发惯性的小样，认可后再扩摸头、护食、尾巴与连续点击。先说明你是否实际能操作Cubism并完成可靠绑定；需要我安装、接受许可、操作或找绑定师时，给出具体步骤和交付文件要求，不能承诺一键自动专业绑定，也不能把整个任务丢给我。先不购买软件、不雇人、不替我发消息。

现在先给简短恢复摘要与下一步，然后继续可执行工作；保留所有已有有效进度。质量以可见结果、实际互动与试听评价，技术验证和审美验收分开。更新教程、资源清单、用途目录与STATUS；不改变物理或Buff规则，Git动作等我另行授权。
```

## 2026-11-04 用户确认后的范围变更：现成 DeepSeek-chan 样板

用户明确暂不处理抱饭碗角色，改为成年比例的 DeepSeek 鲸鱼娘；审看神宫凉子／霓虹猫动态演示后说“完全可以！可以正式开工了”。据此先完成独立可运行菜单样板，不改正式入口、不推进自有PSD/绑定、不触碰卡片对话整文件负责的HUD/素材/文案。现有Native桥接不变，模型与DLL留.local；采用不等于取得游戏再次分发许可。

源码、发布包、40项输入/动作恢复检查与两种尺寸见[教程038](../tutorials/038-deepseek-live2d-menu-sample.md)。新模型120轮对象释放稳定但进程/缓冲内存仍增长，完整L0未通过；不能据可玩样板越过该门槛直接宣称正式接入完成。后续先实际试玩与内存归因，再核清正式分发范围。卡片另一线进度保持原记录，未改变其预算或审美验收状态。

## 2026-11-04 样板试玩未达标后的更正

用户否定第一版动作/跟随/清晰度。已查明作者输入AngleX/Y被误接到物理输出ParamAngleX/Y，旧缓存参数检查漏检，新增真实网格检查后修复；同时补mipmap、2倍内部渲染与对应命中换算，旧模型与包不删除。详见教程038最新段落。

米塔Demo菜单的可查民间还原工程使用3D Animator和头眼IK。现成3D动作库与Godot重定向/LookAtModifier3D可作为更贴近原作的方案，但需要匹配且授权清楚的成年比例DeepSeek 3D模型；当前moc3不能直接重定向骨骼动作。不得把修清晰度/跟随等于自然全身动作已达标，不自动把正式入口、玩法或渲染器改掉，不静默转回此前旧Godot原生二维绑定。
