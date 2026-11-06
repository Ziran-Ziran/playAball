## 2026-11-05最新试验：复用官方Mao多关节曲线

用户否决上一版只有节奏变化后，进一步检查了本机SDK原有Natori、Mao、Ren及鲸鱼娘手臂控制。现在可运行`.local/art_audio_r2/live2d_gesture_sources_20261105/启动官方动作适配试验.cmd`，或在原动作对照入口点“官方Mao关节动作（适配试验）”。新入口支持`--clip=GestureAudit_Mao04_Calibrated`，原默认片段未替换。它是局部适配试验，仍待用户判断自然度。

动作输入→处理→输出：`build_mao_candidate.py`读取已有官方Mao04曲线，保留肩部附近大臂转动/肘/腕的相对时序，以显式比例和偏移写入当前模型Param62/60/61；同一来源的头身映射Angle/Position输入，耳/发/尾等仍由原物理求解。外层拼接原作者起手/收手，总长7.5秒。这个过程没有新增绑定关键形、掌心/手指姿态或独立左右耸肩，也没有解决原始抬手的姿态切换限制，不能把结果称为完整通用动作库。

复现与调参文件都在被忽略的.local目录：构造脚本的`arm_mapping`明确列出三个通道的比例/偏移；调参前先查看`control_audit`静态控制范围和源动作实机画面，再改比例，不能将-30～30度原值直接写入-1～1的控制，也不能强写LArm/LForearm/LWrist等物理输出。`gesture_source_probe.gd`在夹具根负责原动作/目标的同机位渲染；可用`--model=res://models/DeepSeek-chan/audit.model3.json --group=GestureAudit_Mao04_Calibrated --index=0 --frames=225 --height=1138.5 --once --out=<绝对输出目录>`，配合Godot4.7.1的`--fixed-fps 30 --resolution 1280x720 --log-file <日志>`；检查退出码、无SCRIPT ERROR及完成标记。20通道有限性/时间/范围、225帧/30fps视频解码、候选播放后返回Idle均有记录；这仍不是完整人工按钮/自然度验收。

`before_after_official_gesture_30fps.mp4`左旧右新，两侧相机/比例一致，旧版约5秒结束后保持末帧至7.5秒。它仅将实际Godot帧裁切缩放并排，不在游戏播放视频。Natori依赖替换手臂姿态、Ren在当前桥接出现异常图层的原始证据也留存，不通过反复修桥接扩大本轮任务。完整L0/商业发布范围尚未通过，3D封存、正式入口与卡片边界不变。

## 2026-11-05历史：只优化Live2D抬手，3D封存

用户认可当前Live2D整体，授权局部改抬手。入口`.local/art_audio_r2/deepseek_menu_visual_v2/启动Live2D动作对照.cmd`现默认近景，有“抬手回应（调整后）”和“抬手回应（原版对照）”，各播一次后回待机。此窗口仍不启用鼠标注视；不是正式游戏入口。

旧版从作者“举手保持强调”起手，缺专用手腕过渡且举手时间偏长。新版只替换`Movement2/Param59/Param60/Param61/Param62`五条手势曲线：作者“默认手切举手”从0.30秒开始，原1.133秒曲线完整保留；最终姿态停留0.42秒，经0.08秒衔接进入作者“举手切默认手”，其时间放大1.25倍，约3.204秒完成。余下时间保持作者收手终值。17条头身/脸曲线与旧版解析对象相等，未触碰耳鳍/发/尾物理输出或模型网格；没有新造手势关键姿态，也不需要Editor或用户手搓动画。延后手势本身不等于已经设计头部先行。

本机复现脚本在`.local/art_audio_r2/live2d_hand_refine_20261105`：`build_soft_greeting.py`负责拼接/时间缩放并注册新组；`verify_hand_timeline.py`比较头身曲线和手势时间/腕部范围/数据有效性，旧版负对照失败、新版7项通过。调整节奏优先改构造脚本中的起手、停留、收手时长，再生成并运行此检查，不直接改moc3或物理参数。

实际画面复现沿用下文`motion_audit.gd`，将`--clip`设为`AuditBank_AuthoredGreetingSoft`，输出150帧/30fps；检查退出码、日志无SCRIPT ERROR及完成标记。`optimized_render.log`、`timeline_red.json`、`timeline_green.json`和`video_checks.json`保留证据。`hand_before_after_30fps.mp4`左旧右新，仅将真实Godot帧裁切缩放并排；`hand_optimized_30fps.mp4`为新版单独片段。检查不能替代用户对自然度的验收；原生按钮本轮未完整人工验收。完整L0内存、再分发授权未因此解决，3D旧记录与额外动作候选仅保留，Ko-fi领取暂停。

## 2026-11-05历史：现成动作曲线对照，不要求从零做动画

新的本机入口为`.local/art_audio_r2/deepseek_menu_visual_v2/启动Live2D动作对照.cmd`。只比较已有绑定/曲线，非正式菜单；旧可交互样板仍保留。四按钮比较现成待机、作者手部组合、m20与m26；表演一次后返回Idle，只有Idle循环，近景按钮可放大。此对照关闭旧_input和_unhandled_input，不会被旧触摸/设置打断；也没有开启鼠标注视。

数据来自本机原Haru27动作与当前模型作者片段。`.local/art_audio_r2/live2d_motion_audit_20261105/build_authored_bank.py`做参数ID映射、筛选与已有片段时间偏移，生成28个实验组，不重制原手部关键帧。Haru头角映射AngleXYZ、身体映射PositionXYZ，物理输出不写。m26+作者强调0～3.6秒＋收手3.72～4.737秒作为新约4.97秒基线；m19整段闭眼低头，原失败基线归档，不再默认展示。其它组保留作者收手终值，避免切组残留手势；m20非闭合只作单次表演。

验证器`motion_audit.gd`在夹具根，支持`--clip=AuditBank_AuthoredGreeting --frame-count=150 --capture-every-frame --out=<本机绝对输出目录>`，以已有Godot4.7.1运行`--script motion_audit.gd --fixed-fps 30 --resolution 1280x720 -- ...`。配合`--log-file`，必须检查退出码、日志无SCRIPT ERROR和MOTION_AUDIT_COMPLETE；Cubism弃用WARNING仍保留。视频`live2d_m26_and_author_hand_30fps.mp4`来自150张实际帧、30fps，只裁切/缩放/编码。28组仅准备，当前实际比过Idle、m19、m20、m26和新组合，不能说全库验收。

此阶段不需要Cubism Editor/cmo3，只使用已有输入参数、手势与物理。耳鳍/发/尾的表现依赖原绑定，不能跨模型直接复用全部手势。Otra Nico现成舞蹈/睡眠尚待邮箱完成免费领取，没拿到原文件/许可，不能算适配完成。完整L0/内存问题未因动画变好而解决。

# DeepSeek 鲸鱼娘菜单互动样板

2026-11-04，设备 `LAPTOP-8GS4N5SG`。这是用户看过作者动态演示、认可成年比例 DeepSeek 鲸鱼娘后授权制作的第一版。正式游戏入口仍不改变；本样板不读取玩法、不发放 Buff、不接触 HUD 或卡片文件。

## 2026-11-05：停止扩展Manny 3D，复验精细Live2D与身体待机

用户在Manny 3D样板指出肩胸断痕、大小眼和补片怪异，随后明确要求换模型或验证Live2D，验收仍按米塔/Iron Vertex视频的实际效果。本轮停止扩展该3D资产，不将原模型问题继续包装成“动作能播放”。保留原3D包、19组固定相机拆层对照及原始数据。当前使用已有神宫凉子／霓虹猫精细Live2D成年默认体型做本机复验；不是切回旧Godot简易骨骼，也未下载/接受新的SDK许可。

新的干净夹具为`.local/art_audio_r2/deepseek_menu_visual_v2`；可独立运行包为`.local/art_audio_r2/deepseek_chan/export_visual_v2/DeepSeekMenuVisual.exe`，同目录DLL必须保留。旧feedback/export包不覆盖。仍是Godot4.7.1标准版/Compatibility及教程034的已适配Native组合，未改模型moc3/PNG或绑定源工程。

新增“靠近看看/退远一点”：平滑放大实际模型1.65倍并调整Stage内位置，保留1440渲染/720逻辑与mipmap。命中分类反算到原角色画布；视线以放大后的脸部位置为参照，仍能跟随按钮上方鼠标。连续点击近景按钮会终止旧Tween再过渡，避免多个相机动作争抢。原有触摸、设置阻断、减少动态和作者抬/收手继续保留。

身体僵硬定位到真实接线缺失：原实现只有ParamBreath，而作者身体物理需要`PositionX/Y/Z`输入，这三项此前保持0；它们输出到`ParamBodyAngleX/Y/Z`、腰、袖口及发丝链。当前以小幅、不同周期的输入驱动原作者物理，动作/设置/减少动态时平滑减弱；**不修改model节点位置来冒充身体运动，也不直接强写物理输出**。`idle_body_strength`导出字段可调强度，默认1.0，输入峰值约为其±30范围的十分之一；不要未经画面检查就大幅增加。现成3D动作库没有被直接套进moc3。

验证先发现近景方法缺失而失败，再实现；身体输入接线前为0而失败，接线后输入跨度约4.5，实际躯干渲染网格横向RMS约1.9像素。进一步用关闭身体微动的负对照，输入跨度为0，原呼吸仍带来约0.33像素网格变化。第一次读ParamBodyAngleX的Resource缓存误判为0，已改读实际MeshInstance2D渲染顶点，不把缓存当最终物理结果。负对照的失败是预期结果，单列保存，不当作最终通过报告。

`verify_visual.gd`经发布入口`--visual-review --out=<文件前缀>`运行，保存正脸、左右转头、闭眼、抬手、身体待机和全身截图；15项检查验证近景、缩放后的真实鼠标输入、身体渲染变化及原有眼/手姿态，**不自动评判好看或达到参考**。原`--verify`45项回归仍保留，源码与Windows Release均检查；发布版分别使用1280×720和1024×576。已有Cubism弃用WARNING保留，不声称无警告。

7秒动态证据来自105张实际Godot窗口帧（固定步长运行，15fps取样），只裁切角色侧并等比缩小编码为APNG，位于`.local/art_audio_r2/live2d_visual_review_20261105/live2d_actual_runtime.png`。游戏运行的是moc3参数/物理/网格，这个录制文件不参与游戏播放。记录和各失败/成功报告在同一目录。

尚未通过用户观感、完整自然演出、正式游戏接线、完整L0及正式随游戏再分发范围核验。此次面部、肩胸、闭眼与发丝复验未见Manny样板那类补片叠层/接缝断裂，不扩大为所有极值无穿帮。旧Live2D私有内存增长未归因状态仍保留；新外观检查不代替120轮内存测试。

## 用户试玩后的更正：跟随错误、清晰度与目标差距

用户实际试玩后明确指出：动作僵硬、鼠标跟随没有或不明显、锯齿严重，远未达到《米塔》菜单的目标。此前40项检查不能作为这些效果的合格证明，更不能算用户认可样板。原包和旧EXE保留。

鼠标跟随找到实际接线错误：此模型 physics3 的第一、二组以 `AngleX/Y` 为输入，输出到 `ParamAngleX/Y`。旧代码写后者，而 gd_cubism 在写入之后才求解物理，因此最终值被覆盖。旧检查只读取桥接Resource缓存，错过了这一点。已改驱动 `AngleX/Y`；普通模式不再占有物理输出，仅在“减少动态”关闭物理时直接写输出，恢复物理时释放占有。反应过程中也继续接收视线目标，避免每次点击强行回正。

新增检查走真实 `InputEventMouseMotion` → `_input` → 参数输入 → 物理 → 渲染网格；比较实际头部区域约1.8万个顶点，而不只比较缓存值。修复前左右差异RMS约0.69像素，修复后约17.7像素（720逻辑画布），另保存左右转头实际截图。失败证据 `feedback_red.json` 有4项失败，随后同一检查通过，不删除失败报告。

清晰度方面：原5张4096²图集未生成mipmap；新增夹具导入配置开启真实mip层。Stage改为1440²渲染、720²逻辑坐标，外层线性缩小显示，点击命中另从逻辑画布换算到纹理像素。该超采样增加渲染开销，不写成免费优化。Compatibility不支持2D MSAA，未切换渲染器，依据[Godot官方说明](https://docs.godotengine.org/en/stable/tutorials/2d/2d_antialiasing.html)。源PNG、模型绑定与DLL均未改。

当前修正版：`.local/art_audio_r2/deepseek_menu_feedback_repro`；发布包 `deepseek_chan/export_feedback/DeepSeekMenu.exe`。`feedback_final_release_1280.json`、`feedback_final_release_1024.json`记录两种尺寸各45项检查。该修正版解决具体跟随错误并改善采样，**没有因此完成自然全身动作设计、原生桌面鼠标验收、内存归因或用户审美验收**；旧120轮数据来自旧画质构建，不能冒充新画质内存测试。

对《米塔》的技术调查也需更正此前过早的路线判断：可查的[民间Demo还原工程 MenuMita](https://github.com/yenichw/MiSide-Demo-Unity-Project/blob/main/Assets/Scripts/MenuMita.cs)使用Unity Animator、头/眼LookAtIK、三维目标；[MenuMitaDance](https://github.com/yenichw/MiSide-Demo-Unity-Project/blob/main/Assets/Scripts/MenuMitaDance.cs)有音乐频谱驱动。它支持Demo菜单走3D的判断，不是正式版官方公开源码，不能当作最新正式版逐行实现证明。只读查阅，没有下载或挪用米塔角色/动画资产。

现成动作库确实存在：[Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html)提供120+人形骨骼动作、Godot版本，页面标CC0；[Mixamo官方说明](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)允许个人/商业游戏使用，但账户地区、尾巴/大头发服装等自动绑定限制需留意，未登录或上传角色。它们的3D骨骼动作不能直接套在此moc3上。Godot原生有[骨骼重定向](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)与[LookAtModifier3D](https://docs.godotengine.org/en/stable/classes/class_lookatmodifier3d.html)，因此接近原作的3D菜单角色方案不必换Godot或把2D战斗改3D。

现有9组motion主要是道具/手势切换；名为IDLE的曲线实际集中在汗、闪光等效果参数，不包含完整的自然身体待机，不能按“9组”数字宣称已有成熟待机库。更接近米塔的完整动作方案仍待模型与路线确认，未静默迁移。另只读找到猫伊cat的[DeepSeek VRM配布线索](https://www.bilibili.com/video/BV1Zsb96dEDX/)，作者明确非商业；未核验成年比例外观、未下载、不列为已选用模型。

## 1. 先试玩

本机修正版位于工程的 `.local/art_audio_r2/deepseek_chan/export_feedback/DeepSeekMenu.exe`。同目录的 `libgd_cubism.windows.release.x86_64.dll` 需要一起保留。旧 `export/` 仍保留供比较。直接打开 EXE 即可，不需要 Cubism Editor、Python 或 Godot 编辑器。

- 移动鼠标：眼睛先注意光标，头部平滑跟随，头发和裙摆使用作者的物理设置。
- 轻点角色头部：脸红和短促鼓脸；连续快速点击三次会切换为不满，稍后恢复。
- 按住头部缓慢划动后松开：闭眼回应。按下超过 200 毫秒、移动超过模型画布 16 像素才算摸头。
- 点身体或“打个招呼”：播放作者已有抬手至胸前的动作，然后播放收手动作。
- “设置”或 Esc：打开设置时停止角色触摸并回正视线；“减少动态效果”关闭次级物理、减小转头，仍保留眼睛跟随和眨眼。
- “退出样板”：只退出此独立程序。设置不写入正式游戏。

这里的触摸是透明度命中后按头部高度区间分类；没有声称已有精确的脸颊网格碰撞区。鼓脸使用作者已有输入关键形和物理，尚不是专业绑定师针对手指方向制作的局部脸颊挤压。该模型的默认成年比例保持不变，不启用其他体型开关。

实际发布版截图在 `.local/art_audio_r2/deepseek_chan/menu_1280.png` 和 `menu_1024.png`。这些是 Godot 真实运行画面，不是美术概念图。

## 2. 文件与节点

可维护源码在 `tools/live2d_menu_sample/`。该目录有 `.gdignore`，因此正式工程不会导入或打包这个开发样板；准备工具复制源码到独立夹具时不复制 `.gdignore`。

| 文件 | 负责什么 |
| --- | --- |
| `prepare.py` | 从已在本机的模型与已验证插件创建新隔离目录，核验引用，生成派生 model3 和动作配置；不下载或接受许可 |
| `entry.gd/.tscn` | 独立运行入口；普通试玩、`--verify`、`--lifecycle` 三种模式 |
| `menu_sample.gd/.tscn` | 背景、按钮、透明渲染容器、输入坐标和设置模态；不负责玩法 |
| `character.gd` | 模型加载、参数平滑、反应状态、作者动作/表情调用和释放 |
| `verify_sample.gd` | 真实模型、引擎输入分发、动作恢复和释放检查；不是人类试玩 |
| `lifecycle.gd/.tscn` | 独立创建/释放模型并输出对象、资源和显存缓冲统计 |
| `verify_windows.py` | 等待真正的 Windows 子进程，保留日志/报告，并在生命周期模式采样进程私有内存 |

```text
entry.tscn
  ├─ 普通：menu_sample.tscn / Control
  │   ├─ Stage / SubViewport，1440×1440渲染、720×720逻辑、透明
  │   │   └─ Character / Node2D + character.gd
  │   │       └─ 运行时创建 GDCubismUserModel
  │   ├─ TextureRect，显示 Stage 的透明纹理
  │   ├─ 左侧按钮与状态说明
  │   └─ 设置面板
  ├─ --verify：verify_sample.gd
  └─ --lifecycle：lifecycle.tscn
```

当前可编辑夹具为 `.local/art_audio_r2/deepseek_menu_feedback_repro/project.godot`。用当前设备核验过的 Godot 4.7.1 标准版导入它，可以选中 `menu_sample.tscn` 中的 `Stage/Character`，在检查器调整导出属性。

## 3. 输入怎样变成动作

1. `_input()`观察鼠标移动，包含按钮上方；把窗口坐标换成 720×720 的模型画布坐标，再归一化到 -1～1。
2. 眼睛以较快速度接近目标，头部以较慢速度接近目标。当前驱动作者输入 `AngleX/Y`、`ParamEyeBallX/Y`，头部输出交给physics3；不是移动整张人物贴图。
3. 点击先通过界面。只有未被按钮处理的按下/松开才进角色交互；读取已渲染纹理的 alpha，透明空白不会触发。
4. 状态从 `idle` 进入 `cheek / pet / annoyed / greet`。活动反应不被每次点击重复启动；第三次快速点击只升级一次不满。
5. 打招呼使用作者“默认手切举手”动作。时间到后进入 `returning` 播放“举手切默认手”，再回 `idle`，避免手臂一直停在胸前。
6. 跟随、眨眼和呼吸只占有明确的输入参数；`CheeckPuff`、`MouthX` 提供短促脸部输入，脸颊左右晃动等输出仍由作者 physics3 求解。

Native Core 负责网格计算，Framework 负责动作、表情和物理，gd_cubism 把这些接口交给 GDScript。SDK 是运行工具，不是人物本身。这次已有作者制作好的 moc3、纹理和配置，所以不必先买 Editor 或重新绑定。[架构教程035](035-live2d-architecture.md)有制作链路说明。

根 Control、左侧容器和 TextureRect 都设为 `MOUSE_FILTER_IGNORE`；按钮自己处理点击。这是针对实际引擎输入检查发现的吞事件问题所作修复。设置打开时另外显式阻断角色，取消尚未结束的按压，避免关设置时误触。

合成输入也必须换坐标：测试从画布命中点出发，用 `get_screen_transform()` 和 `get_global_transform_with_canvas()` 换成窗口像素后再注入。缩小窗口时直接注入逻辑坐标会偏位，先前1024检查因此失败，已保留失败报告并修正测试。该转换依据[Godot官方坐标与合成输入说明](https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html)。正常鼠标事件进入 `_input()` 后已由引擎换算，业务代码不重复拉伸。

## 4. 怎样调参数、扩展或换模型

| `Character` 检查器属性 | 当前值 | 调大后的变化 |
| --- | --- | --- |
| `display_height` | 690 | 人物在 720 画布内更大，过大会裁切；位置仍以画布中心为基准 |
| `head_follow_time` | 0.24 秒 | 头跟随更慢、更柔和 |
| `eye_follow_time` | 0.09 秒 | 眼睛响应更慢 |
| `head_angle_limit` | 22 度 | 左右转头更明显；不要超过模型参数范围，需检查眼嘴穿帮 |
| `eye_range` | 0.65 | 眼球偏转更大 |
| `response_seconds` | 2.1 秒 | 一次反应保持更久 |

动作和表情对应关系在隔离工程 `model_profile.json`。新增反应应先核对模型确有对应形变/动作，补配置、状态恢复与验收；不能靠给任意参数起名字就获得新形变。新增专业的方向性戳脸，需要源工程与实际绑定制作，此样板没有虚构这项能力。

原包没有在 model3 中登记现有动作和表情。`prepare.py` 保留原入口与全部作者文件，另生成 `runtime.model3.json` 登记现有 23 表情、9 动作组；所有被引用文件必须存在且留在模型目录内。返回动作时长从原 motion3 的 `Meta.Duration` 读取，不猜测结束时间。

不要把这份准备工具直接用于其他模型：它会检查当前选定模型特有的表情和动作名。换模型时需要另行确认外观、授权、参数范围、遮罩、动作优先级和恢复，不能沿用这次的测试结论。

## 5. 当前设备复现

本轮核验：Windows 11 build 26200，用户 `LAPTOP-8GS4N5SG\Ziran`，Godot 实际路径 `C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe`，版本 `4.7.1.stable.official.a13da4feb`，Compatibility。另一台电脑必须重新调查，不复制这些路径作为事实。

桥接仍为 gd_cubism v0.9.1 / `60e9c61` + godot-cpp / `fbbf9ec` + Native Framework 5-r.3 / `f2b858a` + SDK 5-r.5 中的 Core `06.00.0001`。已有库目录和渲染顺序本地补丁；没有重新下载 SDK、重新接受其许可或把组合说成官方原包直接兼容。完整构建复现见[教程034](034-live2d-l0-and-audio-samples.md)。本次复用既有 Debug/Release DLL，没有重新编译桥接。

以下 PowerShell 命令从工程根目录运行。`$Python`、`$Godot` 必须改成当前主机实际调查的路径；当前环境已有 Python，不要求试玩者安装它。

```powershell
$Python = 'C:\Users\Ziran\AppData\Local\Programs\Python\Python314\python.exe'
$Godot = 'C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe'
$Repo = (Get-Location).Path

# 使用一个尚不存在的实验目录名；已有目录会拒绝覆盖。
& $Python tools/live2d_menu_sample/prepare.py `
  --model-directory '.local/art_audio_r2/deepseek_chan/original/DeepSeek-chan' `
  --addon-directory '.local/art_audio_r2/model_fixture/addons/gd_cubism' `
  --fixture-name deepseek_menu_another
$Sample = Join-Path $Repo '.local/art_audio_r2/deepseek_menu_another'

# 首次导入需真正等待 GUI 子进程退出；也可以从编辑器项目管理器导入。
$Import = Start-Process -FilePath $Godot -ArgumentList @(
  '--headless', '--path', ('"' + $Sample + '"'), '--editor', '--import'
) -PassThru -Wait -WindowStyle Hidden
if ($Import.ExitCode -ne 0) { throw '样板导入失败，先检查日志' }

& $Python tools/live2d_menu_sample/verify_windows.py `
  --program $Godot --project $Sample --mode verify `
  --out '.local/art_audio_r2/deepseek_chan/another_verify'
```

准备工具只拷贝当前选中模型数据、已编译 addon 和这几个源码文件，不另建游戏 clone/worktree，不安装或执行镜像仓库的桌宠/Electron 插件。`preparation.json` 保存原文件与 DLL 的 SHA256，以及复制时源码哈希；后续编辑夹具后，应重新核对哈希，不能把旧清单当成未改动的证明。

导出时只修改隔离工程自己的预设。它显式包含 `*.json,*.moc3,*.txt`，否则发布版可能缺模型元数据。可用夹具编辑器“Windows DeepSeek Sample”预设，或：

```powershell
$ExportDir = Join-Path $Repo '.local/art_audio_r2/deepseek_chan/export_another'
New-Item -ItemType Directory -Force -Path $ExportDir | Out-Null
$Exe = Join-Path $ExportDir 'DeepSeekMenu.exe'
$Export = Start-Process -FilePath $Godot -ArgumentList @(
  '--headless', '--path', ('"' + $Sample + '"'),
  '--export-release', '"Windows DeepSeek Sample"', ('"' + $Exe + '"')
) -PassThru -Wait -WindowStyle Hidden
if ($Export.ExitCode -ne 0) { throw '样板导出失败' }

# 不传 --project，工作目录由工具设为 EXE 所在目录。
& $Python tools/live2d_menu_sample/verify_windows.py `
  --program $Exe --mode verify --out '.local/art_audio_r2/deepseek_chan/another_release'
& $Python tools/live2d_menu_sample/verify_windows.py `
  --program $Exe --mode lifecycle --cycles 120 `
  --out '.local/art_audio_r2/deepseek_chan/another_lifecycle'
& $Python tools/live2d_menu_sample/verify_windows.py `
  --program $Exe --mode capture --resolution 1024x576 `
  --out '.local/art_audio_r2/deepseek_chan/another_1024'
```

每次选择新的证据前缀；工具拒绝覆盖已有 `_process.json`。Release 使用自带 `--verify / --lifecycle` 入口，不依赖编辑器的 `--script`。先前只传 `--script` 的 Release 尝试没有进入测试，被主动结束，不能算通过证据。

## 6. 来源、模型清点与发布边界

选中的是[神宫凉子作者 VGen 页面](https://vgen.co/KAMIYA/product/deepseek-chan-deepseek-free-live2d-model-layered-psd-psd/1c55a71a-2747-4616-819d-2dc0a934089d)展示的 DeepSeek-chan；绑定署名为霓虹猫_NeonNeko。[作者动态演示](https://www.youtube.com/watch?v=Jkz2Pio5NBA)已给用户审看并获认可。此前幼态候选不再推进。

本次从[有原作者分发授权记录的公开 Release](https://github.com/hjw200775-ops/dsh-live2d-pet/releases/tag/v0.6.5)只取模型数据 ZIP；对应[授权记录](https://github.com/hjw200775-ops/dsh-live2d-pet/blob/63acf4143ff8f5547a0f980fb91f4f45e1ce73ea/docs/permission.md)。记录不等于给本游戏的再次分发许可，作者新页面与包内较早条款也不能互相简单替代。

- ZIP：`DeepSeek-chan_model_for_dsh-live2d-pet_v1.zip`，50,024,237 字节。
- SHA256：`e661bad675bc1d29213b2906dde8a1e1069ee5b721e9c06a71b6e9317db892bc`。
- 实际加载：509 参数、715 网格、5 张 4096² 纹理、23 表情、9 动作组、131 物理组。
- 此镜像运行包没有 PSD/cmo3。作者页面另外提供分层 PSD，不把它误写成已取得 cmo3。
- 原始条款、NOTICE、分发记录和原文件均在本机保留。没有 VGen 下单、购买 Editor、联系作者或启动专业绑定。

现在只作本机技术评估；模型、Core、DLL、导出包都留在忽略目录，不上传。正式游戏随包分发，特别是收费产品，仍需核清模型与 Core 的适用授权；不能以“免费”或桌宠仓库的代码许可代替。

## 7. 第一版历史验证与未完成（不能代替上方试玩反馈）

所有证据位于 `.local/art_audio_r2/deepseek_chan/`。机器检查和截图是本 Agent 技术自查，不冒充用户审美验收、人工试玩或独立 Review。

| 项目 | 实际证据与结果 |
| --- | --- |
| 模型初次探针 | `probe.json`：5项文件保存/释放检查通过；当时没有比较画面或最终网格，不能证明左右转头成功 |
| 源码历史检查 | `final_source_verify.json`、`scaled_source_verify.json`：1280/1024 各40 项机器检查通过；其中头部检查只读缓存，已确认漏掉物理覆盖错误，不再作为最终跟随有效证据。去重/恢复、体型、设置阻断、点击分发和释放等结果保留 |
| 独立 Windows Release | 最终 `scaled_release_1280.json`、`scaled_release_1024.json`：两种尺寸各40 项通过，`editor_binary=false`、`gl_compatibility`，从 EXE 目录运行；旧 `final_release_verify_1024.json` 的一次测试坐标失败保留，未冒充通过 |
| 两种尺寸 | `menu_1280.png`、`menu_1024.png`：实际 Release 渲染，界面和人物完整 |
| 反复释放 | `release_cycles120.json`：120 轮释放成功，子节点清空，对象数 1406、资源数 3、纹理统计 11,548,963 字节保持不变 |
| 进程内存 | `release_cycles120_memory.json`：652,472,320 → 1,047,191,552 字节；末 20 轮 1,011,482,624～1,047,191,552，不能称为恒定或无泄漏 |
| 缓冲统计 | 同期 Godot buffer memory 25,582,360 → 221,560,024 字节；增长是 2,130,192 的整数倍，末期仍出现新台阶；Release 的 static memory 为 0，不能拿它证明无增长 |

120轮来自本轮较早的发布构建，后续只补了缺资源保护和测试注入坐标；生命周期脚本、插件和模型未变。采样工具另通过 `final_runner_lifecycle3.json` 的3轮检查，短测不能代替120轮数据或使内存门槛通过。

Godot 此版本的 [GLES3 canvas 源码](https://github.com/godotengine/godot/blob/a13da4feb/drivers/gles3/rasterizer_canvas_gles3.cpp)中有等待 GPU fence 与扩展实例缓冲池的路径，可作为缓冲阶梯增长的调查方向；**尚无分配级证据把全部进程增长归因于此**，GPU 负载也没有隔离。真实模型比 Haru 更复杂，不可把 Haru 的内存数字直接当本模型数字。

因此完整 L0 仍未通过。下一项技术工作是对渲染缓冲池、遮罩视口与驱动/原生分配做对照归因，再决定正式接入；不通过缓存模型或减少检查轮数掩盖疑点。

Debug 日志包含 Cubism 启停信息和 `IsLoop / IsLoopFadeIn` 弃用警告，保留原日志；不是无 WARNING 运行。Release 日志未报告脚本错误，仍不能因此推断视觉完全正确。没有验证所有 509 个参数极值、新式混合/离屏特性、另一电脑或长时间后台运行。

Windows Computer Use 曾找到样板窗口，但无法可靠激活，重新截图也未呈现可确认的样板内容，已停止桌面输入。因此原生鼠标/键盘人工试玩仍未完成；40 项检查中的鼠标是 Godot `Input.parse_input_event()` 合成输入分发，不能混淆。

## 8. 常见问题

- **正式菜单没变**：本轮交付是独立样板，正式入口、HUD、卡片和物理均未改动。
- **找不到 gd_cubism 类**：准备时指向教程034已经编译过的完整 addon，不要只复制 gdextension 文本或一个 DLL。
- **模型出现但没有表情/动作**：确认加载派生 `runtime.model3.json`，并包含 `model_profile.json`。
- **发布版缺文件**：检查隔离预设的 JSON/moc3/txt include filter 与同目录 Release DLL；不要改另一对话维护的正式预设。
- **能运行却没生成测试报告**：使用 EXE 后的 `-- --verify --out=绝对前缀`，不要只依赖 `--script`。
- **能鼓脸，不能像手指按住一样挤压**：现有绑定的关键形与碰撞分区决定上限；这需要专门设计与绑定，不能把程序参数插值描述为已完成专业绑定。
- **另一台电脑想试玩**：先核验设备与 Godot；使用模型须遵守作者条款，不把本机导出包擅自上传分享。

没有 commit、push、PR、merge、购买、雇人、代发消息或新自动化；此阶段未进入 Git 最终 Review。
