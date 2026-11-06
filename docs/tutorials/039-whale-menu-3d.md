## 2026-11-05追加：用正式VRM插件接发裙尾动态

Manny旧样板保留失败边界。新对照使用正常比例tegnike VRM及已有VRMA，入口`.local/art_audio_r2/vrm_release_compare_20261105/启动物理对照.cmd`。顶部切换片段、近景；勾选“VRM弹簧动态”可比较原生modifier开关，“插件轻风”使用插件自带环境力。此窗口未接正式入口/玩法，未实现完整视线/表情/脚部IK。尾是被动响应，不是假称已制作专业主动摆尾；3D原资产缺独立耳骨。

来源固定[AzPepoze/godot-vrm v2.6.1](https://github.com/AzPepoze/godot-vrm/releases/tag/v2.6.1)，目录必须保持addons/vrm和addons/mtoon。当前已在Godot4.7.1标准版/Compatibility导入、运行；使用发布包附带Windows DLL，不安装OS软件、不编译/修改solver。Release ZIP的三个SVG实际是Git LFS指针，已从同tag官方media补齐，并按指针SHA验证；GD/DLL与ZIP一致，MIT许可在UPSTREAM_LICENSE。不要用这项补图标的事实混称“修改过碰撞算法”。

输入→输出：编辑器启用两插件，把`.vrm`导入PackedScene→loader实例化导入结果→现有人形旋转重定向播放真实VRMA→插件VRMSpringBoneSimulation在SkeletonModifier阶段算原40条spring、4组/11碰撞资源→原始蒙皮及MToon实际渲染。人物规范骨名如Head，机位正面为-Z；不能沿用原raw loader的小写head/+Z。`verify_secondary.gd`记录实际资源40/11，`runtime_secondary_counts.log`无ERROR。不能只拿model JSON数目冒充运行数量。

调用根目录`audit_vrm.gd`可复现：`--clip=natural-standing --start=50 --seconds=4 --capture-every-frame --out=<本机绝对输出>`；加`--no-springs`关闭native modifier，保持同动作/机位。`--capture-stride=30`用于全170秒1fps留帧。`--face`已修正规范骨/机位并重测正脸、闭眼、笑及转头；不等于运行表情/注视接线完成。使用既有Godot4.7.1 `--script audit_vrm.gd --fixed-fps 30 --log-file <绝对日志> -- ...`，核验完成标记和ERROR，而非只看OS退出码。

骨骼物理输出应在native modifier的modification_processed信号中采样；帧末pose可能已reset，读到0不是物理没运行。对照视频vrm_physics_on_off_30fps.mp4左关闭/右开启，同原片50～54秒120帧30fps。全170秒确定步长连续模拟完成，171张1fps留帧；这不是实时FPS测试，也不声称人工看完每帧或完整无穿模。

完整布料与弹簧骨不同：代理点/胶囊体不能保证所有布料三角形、衣物自碰撞或手袖相交都避开。按成熟资产流程校准碰撞包络、使用合适裙骨/权重和动作、必要时对被覆盖身体做局部mask；本轮未对AI混合网格做无根据裁切。原模型不含耳骨，不能靠物理插件自动生出专业耳绑定，后续可选更成熟资产。候选模型仍非商业许可，未正式实装。旧V-Sekai master对照裙形异常，保留失败目录，未自行修solver。

# 成年鲸鱼娘原生3D互动样板：准备、动作微动与真实注视

日期：2026-11-05。当前设备LAPTOP-8GS4N5SG，Godot4.7.1.stable.official.a13da4feb标准版，Compatibility。此文解释独立样板及实际限制；**尚未达到米塔或专业Live2D展示水准，没有接正式菜单**。用户最新要求优先最终效果，不固定2D/3D；不把此前“先讨论”当成继续禁止已授权的本地实现。

## 1. 能试玩什么

样板使用用户更喜欢的Manny成年鲸鱼娘外观，提供小幅身体待机、连续头颈注视、眨眼/眉嘴形态、点头回应、尾巴小幅动态、近景切换、跟随幅度和减少动态。鼠标移向左侧按钮或右侧空白，真实头部骨骼转动；点击头部或“打个招呼”触发表情与回应。设置打开时阻断角色触摸，Esc返回。

这不是一张PNG摇摆或预录视频。另一方面，**眼球尚不能独立转动，长发随头部整体移动，没有完整手指/发丝绑定、方向性戳脸或高质量挥手**。3D原始发束有融合/低质量几何，大角度时会显露；抗锯齿无法修复这些几何结构。最终用户观感未验收。

## 2. 来源、取得和保留

- 模型：[Manny发布仓库](https://github.com/ningfangtianwai-pixel/ai-girls-3d)，只采用[成年版v1.0.0](https://github.com/ningfangtianwai-pixel/ai-girls-3d/releases/download/v1.0.0/whale-adult.zip)，不是child。作者标CC BY4.0，说明AI辅助网格与基础绑定限制，来源说明未作独立权利链审计。原ZIP38253857字节，SHA256为`fa858f370ca4a485e9512d11514fb15ecafc7a6645d03aefa668bc6613f8c171`。
- 动作：[Quaternius作者在OpenGameArt的Standard分发](https://opengameart.org/content/universal-animation-library)，CC0。取得的是作者2025页面的45动作版本，实际GLB含46个动画名（含A_TPose），不是付费Pro/Source，也不是声称全系列120+免费。itch页面此次返回429，未绕过登录/付款，改用作者已公开分发文件。
- 原始下载保存在`.local/art_audio_r2/model_3d_research/`。准备脚本只从ZIP取GLB/许可，不执行包内任何程序。原始模型GLB字节不改；样板更改的是运行时材质与驱动逻辑。原始说明、完整CC BY许可和署名、CC0说明同时复制到夹具/导出旁的notices。

## 3. 文件和节点

源码在`tools/whale_menu_sample/`，`.gdignore`使正式工程不扫描它；不要直接在正式工程F6运行这个隔离目录中的场景。先按下一节准备独立工程，再在那里打开`sample/menu.tscn`，该场景可编辑。

| 文件 | 作用 |
| --- | --- |
| `prepare.py` | 从已有ZIP创建新的.local独立工程、导出配置、原始资源/许可及哈希清单；拒绝覆盖已有夹具 |
| `menu.tscn` | Control、透明TextureRect、2倍分辨率SubViewport、固定Camera3D和Character |
| `menu.gd` | 菜单按钮、实际输入坐标、命中、设置阻断和近景相机过渡 |
| `character.gd` | 原GLB/源动画加载、手动推进源动画、形态键、回应时序与材质调整 |
| `additive_motion.gd` | 只把源Idle/Idle_Talking相对Idle首帧的旋转差传给原始spine/chest/neck/head |
| `gaze_motion.gd` | 身体之后叠加头颈注视、回应点头与小幅尾巴运动；保存真正处理后的头部Basis |
| `verify_sample.gd` | Godot输入→骨骼→实际渲染图像的检查与截图，不冒充人类试玩 |
| `verify_lifecycle.gd` | 20轮headless实例化/释放与弱引用/对象回收；不证明GPU或私有内存无泄漏 |

运行链为：`menu.tscn → menu.gd → character.gd → 源AnimationPlayer → AdditiveMotion → GazeMotion → Skeleton3D蒙皮/形态键 → 透明SubViewport → TextureRect`。源动作人偶隐藏，显示的是Manny原始模型。

## 4. 在本机复现

新设备必须先按AGENTS确认实际主机、用户、工作目录与Godot路径/版本；下列绝对引擎路径只是本次设备的命令证据，不在运行代码中硬编码。已有ZIP可以保留使用，不重复取得Live2D SDK或接受其许可；本3D样板不使用Cubism/Core/GDExtension。

在工程根目录执行，fixture-name换一个未存在的名字：

```powershell
python tools/whale_menu_sample/prepare.py --model-archive .local/art_audio_r2/model_3d_research/whale-adult-v1.0.0.zip --animation-archive .local/art_audio_r2/model_3d_research/quaternius-standard-oga.zip --fixture-name whale_menu_3d_repro
```

使用实际核验的Godot4.7.1导入该夹具：

```powershell
& 'C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe' --headless --editor --path .local/art_audio_r2/whale_menu_3d_repro --import
& 'C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe' --path .local/art_audio_r2/whale_menu_3d_repro
```

GUI版EXE由某些Shell调用时可能提前返回，不能据Shell立即exit0推定运行结束；本轮命令由Python的`subprocess.run(..., timeout=...)`等待真实Godot进程，并读取日志/报告。若脚本出错，查看SCRIPT ERROR而不是只看进程码。

测试主场景可加`-- --validate`；需要真实窗口渲染，不加headless。报告及PNG写入夹具`evidence/`，导出包写入EXE旁的`evidence/`。两种窗口尺寸分别运行，证据目录另存，避免第二次覆盖第一次：

```powershell
& 'C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe' --path .local/art_audio_r2/whale_menu_3d_repro --resolution 1280x720 -- --validate
& 'C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe' --headless --path .local/art_audio_r2/whale_menu_3d_repro --script sample/verify_lifecycle.gd
```

安装着同版Windows导出模板时，可在夹具内选择Windows Whale Sample预设导出。原始数据不上传，正式游戏导出工具不修改。当前成品是`.local/art_audio_r2/whale_menu_3d_export/WhaleMenu.exe`，可独立启动。

## 5. 为什么没有直接套整个人形动作

最初实际尝试了Godot原生BoneMap/SkeletonProfileHumanoid、统一轴向与轮廓修正。把源动作整套交给此模型后，截图发现手指拉丝、裙摆撕开；去掉位置/缩放轨道、限制部分骨骼与关闭轮廓修正仍不能交付。失败夹具/日志保存在`.local/art_audio_r2/whale_menu_3d/`，没有当成成功结果。

当前保留原始骨架、骨长、蒙皮、静止姿态，选择Idle首帧作参考，只传递少量旋转差。例如源胸部相比参考帧转了2度，就给目标胸部叠加缩小后的差值。它不会把Manny的肩、手、腿拉到源人偶的位置。这是**上身微动的加性转移，不是整套动作重定向完成**。Idle_Talking只提供回应时的有限头肩变化；实际试过手臂参与后仍暴露原始手部蒙皮问题，因此当前不搬运四肢动作，四肢随躯干继承运动。

`AdditiveMotion`按父先子后的顺序求局部旋转，避免子骨重复继承父骨。`GazeMotion`在其后执行，给颈部25%、头部75%的水平注视角，再按父骨当前Basis转回局部旋转；这使待机与注视能并存。它是实际3D骨骼转头，原模型没有独立眼骨，所以不伪称眼球先动。

原生动作重定向能力见[Godot文档](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)；修饰器顺序见[SkeletonModifier3D文档](https://docs.godotengine.org/en/stable/classes/class_skeletonmodifier3d.html)。成熟引擎能力不能补齐资产本身缺少的专业绑定。

## 6. 输入、画质与调参

- `menu.gd._input`记录进入视口的MouseMotion坐标，转换到菜单画布；不逐帧轮询系统鼠标覆盖事件。头部投影点通过相机换算到TextureRect，用于注视参照和头部命中。root及显示TextureRect忽略GUI拾取，按钮先消费点击，未消费的点击才到角色；settings_open阻断角色回应。
- 测试注入接收的是窗口像素，因此逻辑点需乘视口的最终变换；1280和1024实际窗口都检查，不能只在1280下通过就推定缩放正确。
- Stage为1520×1440，显示760×720，8倍MSAA加2倍内部渲染/线性缩小，真实3D纹理有mipmap。它改善采样边缘，有GPU/内存开销；不解决原几何中的破洞/粘连。
- 原图已含明暗，样板材质用unshaded保留原色，避免第二次强光冲白。嘴补片UV向内收3%，避开图外围黑色；眼睑原图灰褐，样板替换为接近脸部的颜色。原PNG/GLB字节不改，闭眼仍是作者提供的基础形态，不宣称专业面部重制。
- 在隔离工程打开`sample/menu.tscn`可改相机的size/位置和Stage分辨率；脚本中的导出字段可调整头部水平/俯仰上限、跟随速度与微动强度。默认22度水平/12度俯仰、四个上身骨小幅运动；不要未经截图检查就增加手臂、裙摆或大角度转头。

## 7. 真实验证与后续门槛

源码与Windows Release均做真实Compatibility窗口验证。1280×720和1024×576分别10项检查，包括25根原始骨骼、四骨动作微动、真实左右头部Basis变化、头肩图像RGB差分、点击回应、设置阻断、减少动态与近景。初次鼠标测试只有约2度且点击失败：根Control吃掉点击，且系统鼠标轮询覆盖分发事件；修正后真实左右角差约37度，头肩图像差分RMS约0.18。旧失败日志保留；测试通过不代表自然程度或审美通过。

另外通过Windows computer-use实际打开独立包、点击设置、Esc返回、近景切换与招呼按钮，观察到对应面板/相机/回应文案变化；这是原生输入检查，不是人类试玩。20轮headless加载释放单列报告，不把它扩大成完整L0或无泄漏证明。此前Live2D内存未归因状态没有被本样板覆盖。

要达到用户指定的专业观感，还必须完善独立眼神、发丝次级运动、手部/肩部与裙摆权重，以及自然动作的实际演出设计；同一外观静态好看不等于动画资产完成。当前交付用于真实观察与继续制作，尚未满足完整效果验收。没有修改正式入口、HUD/卡片/文案、玩法/Buff/物理，没有Git上传、安装/购买软件、接受额外SDK许可或雇人。
