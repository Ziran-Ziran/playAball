# F5开始界面的Live2D角色与鼠标互动

## 现在怎样运行

Godot固定为4.7.1 stable标准版，Compatibility渲染。打开根`project.godot`按F5，仍是原来的开始/设置/退出菜单；右侧在本机资源准备好时显示成年DeepSeek-chan。移动鼠标时眼睛先转、头部随后跟随；点头顶闭眼回应，点脸颊短暂鼓脸，点身体微笑点头；连续点击会转为不满。设置打开、窗口失焦时不接收角色点击，回到菜单可重新互动。

本轮先接短回应，不默认播放尚未获认可的长抬手。完整手臂自然度不是本次已经解决的项目，3D样板继续封存。

本机已有原始模型和已验证桥接时，运行（Python 3.9 以上，无第三方包）：

```powershell
python -X utf8 tools/prepare_menu_live2d.py
```

准备工具只创建或补齐相同内容，不升级覆盖已有文件。来源缺 DLL/Shader、已修改文件、未登记同名冲突会拒绝并保留旧清单；自定义 profile 保留。首次复制中断若留下没有 preparation.json 的目录，也会拒绝自动接管：请先人工备份检查再选择新的准备时机，不删除未知资源来重试。

默认从已有`.local/art_audio_r2/deepseek_menu_visual_v2`准备至`.local/menu_character_runtime`。也可用`--source <已有夹具目录>`指定同结构来源。工具不下载、不安装、不接受许可，也不编译SDK。没有这些本机资源或使用headless后端时保留原静态角色，开始/设置/退出仍可使用，控制台记录回退原因。

角色、Native DLL、10份原着色器、JSON/moc3和图集均留在被忽略的.local目录。这样现有导出工具复制scripts/scenes/resources/assets时不会夹带模型；没有修改另一对话的导出工具或预设。当前F5本机效果不等于普通Windows发行包已含Live2D，更不代表取得模型/SDK再分发许可。需要交付带角色的游戏包时必须另行解决授权与平台包验证，不能手动把.local整个复制进公开发布。

## 文件与节点

| 文件 | 负责什么 |
| --- | --- |
| `scenes/ui/main_menu.tscn`、`scripts/ui/main_menu.gd` | 保留正式导航；挂角色组件，设置打开/关闭时传递阻断状态 |
| `scenes/ui/menu_character.tscn` | 可编辑的角色区域、透明SubViewport、Portrait与原PNG回退 |
| `scripts/ui/menu_character_view.gd` | 坐标换算、当前帧透明度命中、轻点/抚摸分类、焦点与遮挡仲裁 |
| `scripts/ui/menu_character.gd` | 加载现有Native模型，驱动头眼/身体输入、眨眼和短回应，不读写玩法 |
| `tools/prepare_menu_live2d.py` | 从已有夹具准备本机私有资源，保留源文件哈希，不获取新资源 |
| `tests/test_prepare_menu_live2d.py` | 准备工具的保护/缺资源/复制故障回归，不运行第三方资源 |
| `tests/menu_character_integration.gd` | 正式入口的引擎输入/释放/返回/不同分辨率与回退检查 |

MenuCharacter内的Stage为1440×1440透明渲染，逻辑画布仍是720×720。Character是Node2D，Native节点运行时创建；Portrait缩小显示ViewportTexture。头部转动来自原模型参数/变形器，角色根节点不会左右摇摆来冒充转头。

## 输入怎样变成画面

1. `_input`接收鼠标移动，即使鼠标在左侧按钮上也可以注视。菜单坐标先反算到组件，再映射到720逻辑画布，减去放大后真实脸部中心，得到-1～1目标。
2. 驱动器分别用0.09秒和0.24秒的响应时间平滑眼神和头部。写入AngleX/Y/Z、PositionX/Y/Z等输入，原Cubism物理继续求解耳鳍、发丝、尾部与身体输出。正常模式不强写ParamAngle/ParamBodyAngle或LArm等物理输出。
3. 点击走`_unhandled_input`，先让开始/设置/退出等GUI处理。只在当前渲染帧alpha>0.2处记录按下，松开仍需命中角色；透明空白不形成隐形按钮。
4. 放大后的命中点反算回角色原坐标。头顶或慢速头部划动为pet，脸颊为cheek，身体为greet。反应只写已有眼睑、微笑、鼓脸输入和作者表情，播完恢复待机。
5. 三次短时间点击升级一次annoyed，忙碌时不反复重启同一反应。设置或失焦取消按下状态、回望中心；焦点恢复也不会凭空补发一次点击。

## 为什么私有资源也能加载

Root工程不把本机插件加入全局自动加载列表。角色需要时才通过GDExtensionManager加载既有DLL，进程中不主动卸载仍可能被资源引用的扩展。

该版本桥接固定使用`res://addons/gd_cubism/res/shader/`查找着色器。驱动器从私有目录加载10份原Shader，再用Godot的`take_over_path`注册缓存别名；不改原着色器/DLL。图集优先复用夹具中已有、开启mipmap的`.ctex`，注册到模型预期纹理路径；没有导入缓存时从原PNG创建ImageTexture并生成mipmap。模型与Shader/Texture引用在菜单退出时释放，Native模块保留到进程退出。

这解决了正式工程找不到桥接固定着色器路径的问题，没有重新构建桥接。实际组合为 gd_cubism v0.9.1/60e9c61、godot-cpp/fbbf9ec、Native Framework 5-r.3/f2b858a 与 SDK 5-r.5 的 Core06.00.0001，已有库目录及渲染顺序适配；不能称为官方原包直接兼容。

## 在检查器里改什么

- 打开`menu_character.tscn`，选MenuCharacter：`camera_scale`和`camera_position`决定全身/近景构图。视图与命中共用这组参数，改构图后仍需跑输入检查。
- 选Stage/Character：`head_angle_limit`限制转头幅度；`head_follow_time`、`eye_follow_time`调整跟随延迟；`eye_range`调整眼神幅度；`idle_body_strength`调整身体原物理输入；`response_seconds`调整短回应时长。
- 设置中的“减少动态效果”会停止身体微动与次级物理，并降低跟随幅度；音量与该选项分别保存到原`user://ui_settings.cfg`，互不覆盖。角色本身不保存游戏规则。
- 反应表情名称来自本机`menu_profile.json`。若换模型，必须先核对其真实输入/输出和表情，不能只改模型文件名就套用当前配置。

## 验证与常见问题

先用固定Godot导入工程。图形模式检查必须真实加载本机模型，headless只检查无图形回退；不要把headless写成Live2D画面验收。

```powershell
python -X utf8 -m unittest discover -s tests -p test_prepare_menu_live2d.py
& $GodotExe --path . --script tests/menu_character_integration.gd --fixed-fps 60 --resolution 1280x720 --log-file <日志绝对路径> -- --expect-live2d --out=<证据目录>
& $GodotExe --path . --script tests/menu_character_integration.gd --fixed-fps 60 --resolution 1024x576 --log-file <日志绝对路径> -- --expect-live2d --out=<证据目录>
& $GodotExe --headless --path . --script tests/menu_character_integration.gd
& $GodotExe --path . --script tests/menu_character_integration.gd -- --missing-runtime
```

`$GodotExe`应先设为当前主机核验过的Godot4.7.1路径。Windows GUI程序应等待进程结束并检查日志，不能只看PowerShell调用是否返回。通过条件为退出码0、无ERROR/SCRIPT ERROR及`MENU CHARACTER CHECKS`零失败。带out时保存Stage截图、合成主菜单截图和JSON；测试模拟窗口焦点信号，不冒充真人整局试玩。

首轮测试虽然反应计数通过，但遗漏着色器使日志报错，该轮不能算画面通过。修复缓存别名后再运行；原失败日志保留。首次直接导入大图集曾耗时超限，最终私有加载方式不依赖根工程扫描这些图片。资源缺失检查只给第一个实例注入缺失路径，回菜单后恢复正常配置，不能误期望新实例也永久缺失。

完整L0/进程私有内存增长尚未归因；菜单模型Node释放检查不证明没有GPU/Native泄漏。自然度和全部极值仍待用户体验。此改动没有修改HUD/卡片、Buff、经济、发射/碰撞或战斗物理。

2026-11-05最终审查修复后：图形1280×720、1024×576各28项零失败；headless为12项、故意缺模型为13项零失败；准备工具8项测试通过。所有最终日志无ERROR/SCRIPT ERROR。初版的verify.ps1导入/目录/39套行为回归已通过，修复后重跑受影响检查，不冒充再次全量回归。Windows窗口实际点过头顶、设置/遮挡、返回、开始、暂停和回主菜单，未进行真人自然整局。完整证据位于`.local/art_audio_r2/menu_integration_20261105`；审查问题、复查及公开提交范围见[最终Review记录](../reviews/2026-11-05-live2d-start-menu.md)。

## 本机 Windows Release 体验包（2026-11-05）

用户要求一份发布版后，另做了包含当前 Live2D 的本机 Release 模板构建：`builds/playaball-live2d-release-20261105-215502/PlayABall.exe`，同名 ZIP 是整个目录的压缩包。采用当前工作区，包含另一对话已接入但尚未提交的卡面，不是仅从 cfe31a2 还原的纯提交包。源码指纹、EXE 哈希与验证边界见包内 build_info.json。

默认共享导出器继续排除 .local，不改另一线的 export_windows.ps1、export_presets.cfg、project.godot 或 HUD。此次只在独立导出暂存副本中，把 menu_character.gd 的 model_path、extension_path、profile_path 三个默认值改为基于 `OS.get_executable_path().get_base_dir()` 拼接旁置 `menu_character_runtime`。其余游戏代码和物理不改，也没有重新构建 C++ 桥接。旁置目录包含已有模型、原 Shader、mipmap 图集缓存和 Native DLL，JSON 相对路径仍保持；不复制含原来源绝对路径的 preparation.json。

因此从系统临时目录作为工作目录启动实际 Release EXE 也能加载角色，不依赖工程 .local 路径。EXE 内嵌主游戏资源；请完整解压并保留旁置目录，不能只搬一个 EXE。原始模型条款和引擎/桥接/Core 通知在包中保留。这仍是当前用户本机体验包，未解决公开/商业发行授权，不上传或公开分发模型；Release 模板不等于已取得商业发行许可。

验证分为两层：同版编辑器用 `--main-pack <实际EXE>` 运行原 package_probe.gd，326 项资源清单、28 张卡面及实际包内导航/物理/合法发射等探针通过；真正 Release 窗口确认从旁置目录加载 release DLL，并实际检查左右注视、摸头、设置阻断、开始、失败重开、回 Live2D 菜单。UI 自动操作的等待期间到达失败，未完成人工自然战斗/整局通关，不将包内探针冒充 Release 模板内自动脚本。

生成与检查日志、源文件快照、独立进程记录保存在 `.local/art_audio_r2/menu_release_20261105-215502`；本机一次性准备脚本为 `.local/art_audio_r2/build_current_live2d_release.py`。脚本只建唯一暂存/构建目录，不覆盖交付，不改原工程；压缩时须递归包含旁置资源。正式复用导出能力仍需由导出工具当前负责人协调接入，不能把这次暂存修改误写成共享导出器已有功能。
