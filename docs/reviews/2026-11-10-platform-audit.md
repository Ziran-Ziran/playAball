# 双平台发布与代码性能只读审查

日期：2026-11-10。审查 Agent：platform_audit。基线：`a494ad2`；本报告属于开发期调查，不是整批最终 Review，也不代表实际真机验收通过。仅写此报告与 `.local/` 调查产物，未修改玩法、表现、Live2D 或发布配置。

## 当前设备与工具证据

| 项目 | 本机实际结果 |
| --- | --- |
| 主机 / 系统 | `LAPTOP-8GS4N5SG` / Windows NT 10.0.26200 |
| 用户 / 目录 | `LAPTOP-8GS4N5SG\Ziran` / `C:\Users\Ziran\playAball` |
| CPU / RAM | Intel Core Ultra 9 275HX，24逻辑处理器；33737986048 bytes物理内存 |
| GPU | RTX 5070 Ti Laptop GPU、Intel Graphics；Win32接口的AdapterRAM不是可靠独显显存容量，本报告不据此声明显存规格 |
| 引擎 | `C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe`，实际执行 `--version` 得到 `4.7.1.stable.official.a13da4feb` |
| 模板 | `%APPDATA%/Godot/export_templates/4.7.1.stable/` 含Windows x86_64 release模板、android_debug.apk、android_release.apk与android_source.zip |
| adb | `C:\platform-tools_r20-windows\platform-tools\adb.exe`，`devices -l` 列表为空；调用启动了adb本地后台服务，未连接或安装设备 |
| Android SDK | 编辑器当前设置指向默认用户SDK目录，但该目录不存在；不能据此断言整台电脑没有SDK |
| JDK | `java`不在PATH，常见Program Files安装目录及指定的C:/sdkdata、C:/leidian未找到java.exe/javac.exe |

轻量查找仅涉及工具目录，没有读取签名密钥。版本证据：`.local/platform-engine-version.out`。脚本清单与行数：`.local/platform-script-scan.tsv`。以上本机绝对路径是调查记录，不应写入游戏运行代码。

## 审查覆盖与限制

扫描 `scripts/` 全部83份GDScript、约8550行（PowerShell Measure-Object统计口径），检查输入事件、通知、逐帧更新、组查询、实例创建、动态加载和重绘模式。深读正式入口 `ui/game.gd`、`roguelite/arena.gd`、`run_arena.gd`、`launch_controller.gd`、`run_director.gd` 的主要流程、`combat_body.gd` 的物理状态与延后事件接口，以及enemy、companion、collision_combat、audio_director、impact_feedback、map_controller、portal_pair、ball_art、fish_ball_view、enemy_view、music_manager、menu_character与menu_character_view相关路径。也核对了project.godot、export_presets.cfg、Windows导出脚本、平台教程048。

不是83份脚本的逐行独立正确性证明；未深读的实验室、调参和评估代码不能写成“全部代码已审核通过”。本阶段没有跑完整回归、真实Windows正式包、Android运行、长期内存/温升与低端设备性能采样。当前笔记本不能代表低配置门槛。

## 必须补齐的Android发布条件

1. **P1：尚无Android preset与导出流程。** `export_presets.cfg:1`仅Windows Planner，`tools/export_windows.ps1`仅调用Windows导出；现有工程不能依此交付APK。新增Android arm64发布preset、隔离暂存导出脚本、包资源检查与来源指纹；签名通过环境变量输入，禁止把密钥/密码写入仓库。
2. **P1：没有明确触屏手势归属与取消路径。** `scripts/roguelite/arena.gd:51–77`仅MouseButton/MouseMotion，取消依赖右键，暂停依赖Esc。触摸模拟鼠标可提供基本点击，但代码没有`InputEventScreenTouch`/`InputEventScreenDrag`手指index追踪，不能证明多指不抢发、拖入按钮不误发、屏幕取消与失焦不残留。建议共用DemoLaunch规则接口，仅在输入适配层管理活动手指；加可见取消与暂停控件，保持Windows鼠标行为。模拟鼠标与原生触摸需择一路处理，避免一次手势触发两次。
3. **P1：Android返回键与切后台未适配。** `arena.gd:154`和`launch_controller.gd:152`只取消窗口失焦手势，没处理Android `NOTIFICATION_WM_GO_BACK_REQUEST`、应用暂停/焦点通知。应在战斗返回时取消手势并打开暂停，恢复不自动发射；成长、商店和结算暂停所有权不能被返回键解除。要防止默认系统返回直接退出。
4. **P1：横屏/安全区与触控尺寸缺乏保证。** `project.godot`仅1280×720和canvas_items；正式HUD大量固定坐标，`ui/game.gd:43`暂停按钮高40逻辑像素。未限制横屏，未读取安全区；宽屏和刘海设备不能直接按桌面截图宣称可用。建议保持16:9世界物理坐标，UI使用逻辑安全边距，Android横屏，实测手指尺寸和窄屏四卡布局。
5. **发布签名与真机证据缺失。** 本机未验证release keystore，不读已有密钥、不擅自替换发行身份。可以先交付明确标识的本地侧载包；商店AAB、发布签名和渠道验收单列。ADB为空，所以即使APK导出成功也不能称真机验证通过。

## 代码与性能发现

| 等级 | 位置 / 证据 | 影响与建议 | 复现 / 验收 |
| --- | --- | --- | --- |
| P2，确定行为缺陷 | `scripts/impact_feedback.gd:55` 粒子数量达到18立即return，声音调用在73行之后 | 视觉粒子预算耗尽会同时丢弃碰撞音，即使独立AudioDirector尚有声部预算；连锁高峰的反馈被意外削弱。将声音请求与粒子创建预算分离，继续由音频自己的优先级和冷却限流 | 填充18个CPUParticles2D子节点，调用play_impact，监听AudioDirector事件；粒子不增加且合法声音仍请求；普通/静音/声部满载回归 |
| P2，确定冗余更新 | `arena.gd:93`、`run_arena.gd:61`、`ui/game.gd:182` 在同一正式帧顺序写三次status.text | 前两次文本立即被子类覆盖；构造/提交多份字符串没有玩家收益。将状态文本生成拆成可覆写函数或只在最终层写一次，并按显示读数变化更新 | 正式HUD每帧最终文字一致；试验场与run独立入口仍显示原数据；以调用计数或Profiler证实减少格式化 |
| P2，确定冗余更新 | `run_arena.gd:63`每帧sync_audio_mix，而控件回调和MusicManager信号已有同步；`audio_director.gd:set_mix`每次遍历声部更新音量 | 无音量变化也产生主线程与AudioServer属性写入。缓存最后mix三元组或删除无必要逐帧同步，保留现存声部即时响应 | 音效/提示/静音全部入口变化后现存声部正确响应；无变化时不重复set_mix |
| 建议测量 | `presentation/enemy_view.gd:35–39`每只敌人每渲染帧建立完整快照Dictionary与动态call | 上限敌人数量有限，不能未经测量称严重瓶颈；但可缓存常量/仅传动态状态，避免动画要求迫使全量快照分配。不要把警告进度改成只在攻击开始刷新 | 固定种子拥挤场景记录优化前后CPU帧时/分配；预警、硬直、击杀、出生身份视觉一致 |
| 建议测量 | `portal_pair.gd:61/149`每物理步枚举demo_bodies，出口查询创建CircleShape2D/Query；map_controller安全点回退最多128次查询 | 保持120Hz与真实出口占用规则，先缓存查询对象/形状并只在需要时更新；不可删除待命伙伴占用检查来省时 | 两对门多人同帧争出口、不重叠、保速、锁与地图切换回归；记录物理峰值 |
| 建议测量 | impact_feedback每次新建CPUParticles2D；AudioDirector每次new/free播放器 | 已有粒子18、声部8、爆裂12和浮字20预算，避免无证据重写为池；若Profiler证实创建峰值，再实现小型预热池，回收不得带上局状态 | 长局/重开无节点累积，静音与暂停正确，冲撞高峰帧时改善 |

现有正向边界：刚体复位/传送通过物理状态接口，接触延后事件带revision检查；延迟回声队列也有重置revision；伤害/音效/图层基本分离；敌人、弹体与视觉已有上限。应保留这些设计，不以“优化”之名改变物理频率、敌人数或关卡难度。

## Live2D边界

`menu_character.gd:49–59`在缺资源时回退，只有Windows才主动加载已验证扩展。普通Windows导出暂存不包含`.local`私有资源；安卓普通包可沿现有静态回退，不需要也不应该复制DLL改后缀。遵守用户要求，本批不修改现有Live2D内容；新Android包装/输入适配仅在外围新增。

## 工具链准备方案（尚未执行）

已于审查时访问官方当前页面。在线stable会变化，下面版本仍需由固定4.7.1模板的实际导出要求校准。

- JDK17：官方Temurin API返回17.0.21+9 Windows x64 ZIP，191117380 bytes，SHA256 `98518ecf554465057ee5509462631deeee374bc368c12a411d225cd29381f84b`。使用便携解压，不必安装Android Studio或修改全机PATH。[官方API](https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse)
- Android command-line tools：官方页面当前列 `commandlinetools-win-15859902_latest.zip`，155.7MB，SHA256 `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`。[下载页](https://developer.android.com/studio#command-line-tools-only)
- 标准预编译APK先准备 `platform-tools`、`build-tools;35.0.1`、`platforms;android-35`。此最小方案下载总量估计小于1GB，建议预留2GB；这是实施估计，非已量得安装大小。若模板要求更新平台，以实际错误修正；不能仅因为在线文档当前数字就假定模板兼容。
- 使用预编译模板且不编译原生扩展时，可先不装NDK/CMake；如需要Gradle/原生构建，官方完整清单还列NDK28.1.13356709、CMake3.10.2.4988404。[Godot Android导出说明](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- 密钥路径、别名和密码可由 `GODOT_ANDROID_KEYSTORE_RELEASE_*` 环境变量传入；不写回preset、不出现在命令日志。上述官方导出说明同时支持这些环境变量。

## 建议验收顺序

1. 先由玩法实现者完成策略/经济改动并跑相关回归，再由美术实现者完成补强；当前只读调查不打乱用户要求的实施顺序。
2. 新增失败用例覆盖：活动手指、多指、取消、按住等充能、成长弹出、后台/恢复、系统返回、模态暂停所有权。再实施外围输入适配。
3. 解决上述确定反馈缺陷和冗余更新，保留120Hz，使用同种子完整局/峰值场景对比，不将headless FPS当GPU成绩。
4. Windows实际导出并启动，核对包资源、实际渲染和输入、重开/回菜单。Android导出APK并检查包结构/签名/Manifest，连接真机后安装启动，完成系统返回、后台、多指、刘海和长局测试。
5. 低端Windows与Android的CPU/GPU帧时、常驻内存、峰值内存、长局温升证据不足时，明确设备范围；目标60fps不能写成所有设备保证。

API核对：[Android返回通知](https://docs.godotengine.org/en/stable/classes/class_node.html)、[安全区坐标](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)、[触摸模拟鼠标设置](https://docs.godotengine.org/en/stable/classes/class_input.html)。安全区返回显示坐标，需正确映射至游戏逻辑画布，不能直接当1280×720像素用。

## 后续本机工具准备实证（仍未改运行内容）

主 Agent 安装并校验便携JDK17.0.21+9、SDK命令行工具、platform-tools37.0.1、build-tools35.0.1和android35平台。实测Java、ADB版本和SDK jar存在。位置均在忽略的`.local/android-toolchain/`，没有改全机PATH。

`.local/platform-export-probe/`空项目已用固定引擎实际导出未签名release APK，Godot退出0、stderr空，约78MB，包含ARMv7/ARM64/x86_64。它是工具链探针，不是游戏发布包。步骤证据 `.local/platform-export-probe.out/.err`。

- 引擎`--help`没有`--editor-settings`参数。实测子进程APPDATA隔离有效：EditorInterface报告配置目录落在探针内，能读到独立EditorSettings的Java/SDK路径；用户全局editor_settings哈希前后相同。导出暂存preset指定现有模板绝对路径，仅影响本地构建，不写入运行代码。
- Compatibility导出Android也要求`rendering/textures/vram_compression/import_etc2_astc=true`，缺少时导出明确拒绝。
- 4.7.1本机模板的实际Manifest为compileSdk36、targetSdk36、minSdk24。最低声明Android7并不等于已验证最低设备。非Gradle预编译模板不允许覆写target SDK；配置35会被拒绝。原先在线stable文档35的准备清单只能作为起点，应补齐匹配36工具；这验证了前文“以实际模板校准”的必要性。
- 35.0.1 aapt读取当前模板Manifest时有attribute类型读取报错，不能将该错误误判成游戏资源错误；继续安装36工具核验。
- 官方Android emulator已安装，`emulator -accel-check`退出0，报告WHPX(10.0.26200)可用；API35 google_apis x86_64镜像仍在安装，尚未声称启动成功。模拟器仅补启动/触控证据，不能替代ARM真机性能。
- 当前65张PNG按导入尺寸、RGBA8与mipmap全部同时驻留的估计上界约156.6MiB，细项`.local/platform-texture-budget.json`。不是Profiler实测，也不含其他纹理、引擎、音频、物理和私有Live2D。大UI图集裁切仍使用源像素坐标，不能不核对region便盲目降导入尺寸。

工具链准备最终结果：API36平台和build-tools36已补齐；Google官方API35镜像ZIP的1738815903字节和SHA1 `0103e6dab21290c4b9d16550a3ce99476f884eef`均校验一致。sdkmanager部分下载长期停在0字节，因此在核验路径后只结束本次两个Java进程，改用同一Google官方URL直接下载并按官方repository XML校验、注册包元信息。没有接触其他SDK。

Android15/API35、x86_64、WHPX+SwiftShader模拟器已实际启动，日志记录首次启动53秒；空项目release APK用独立临时测试证书签名后安装成功，Godot原生引擎启动，PID存在。初次尝试直接启动内部GodotApp Activity被系统拒绝，改用Manifest可导出的GodotAppLauncher后成功。证据`.local/platform-probe-android.log`和`.local/platform-probe-package.txt`。探针已停止，模拟器保留供正式游戏测试；使用新ADB的独立服务器端口5038，避免本机旧版ADB31和新版41反复重启彼此。

继续保留：aapt1在36工具下仍无法解析exporter写入的字符串型android:required；aapt2可正常检查。缺Android自适应/主题图标时aapt2提示themed_icon资源路径缺失，正式preset应配置并实测。空项目探针没有设置mobile renderer覆盖，实际使用Forward Mobile Vulkan；不把这次结果冒充正式游戏Compatibility渲染验收。该探针验证了导出、签名、包安装和原生启动路径，不代表游戏触控或ARM设备性能通过。

## 候选1包上复验（2026-11-10）

实际包`builds/release-1-0-0-android-universal-candidate1/PlayABall.apk`：源码指纹`3C63156B78C1BFE5BFB3F8D64A1CFF0BA2AAE201E751B7F7C3C1CA17D8EE5E55`，APK SHA256`C54029E883D6BA850F9EBCBAA74CE6B8A47AE2329F51CD4E3940A164057C1A20`。signed=true，包含ARMv7/ARM64/x86_64，使用owner新发行证书；实际测试仅x86_64 Android15模拟器，不能外推ARM性能。

卸载本任务旧probe签名包、安装候选成功，Compatibility host NVIDIA正常启动。原生触控实际执行并查看截图：设置/来源打开、来源文字滑动到后续OFL、Back只关顶层来源而保留设置；主菜单启动；原生DOWN/MOVE瞄准出现取消键、UP至取消区撤销；Back暂停；swipe发射；Home后台后重新启动仍停在暂停。Android桌面圆形adaptive遮罩内人物脸部完整。本次logcat未发现Godot ERROR/FATAL/SCRIPT ERROR，证据`.local/candidate1-android.log`。截图清单在[教程058](../tutorials/058-mobile-input-and-release.md)候选1节。单次PSS208371KiB/RSS314168KiB，不是峰值或硬件要求保证。

审查发现：候选1设置/来源的部分全角括号和标点显示方框，中文主体可读。已报根Agent与独立审查处理；平台测试不越权改冻结源码。该问题应保留或复验后关闭，不能无条件宣称全部视觉通过。多指归属主要证据仍是脚本专项，ADB此次单指注入不替代真人双指测试；刘海、最旧Android7和ARM真机仍未验收。

来源全长补验：滚动条可定位最后Zlib条款，最后第3条版权限制和返回按钮均可见（`.local/candidate1-android-license-end.png`）。RichTextLabel允许选择，长拖部分时候选中文本，滚动条仍可操作。该观察不替代字体方框问题的修订复验。

## Noto兜底版包上复验

包`builds/release-1-0-0-android-verified/PlayABall.apk`，APK SHA256`DC1A6DB36A67E61CEA722617334C2A811C0D550B6EFADD7C3D82F72618380876`，源码指纹`6DBC69146C09BD7E380884FDA5527EE9B9D08205960AB5F737152FA6B0AB1DB4`。从候选1同签名升级安装成功；实际Android截图确认全角括号、书名号、中文标点均有正确字形，Noto来源可见，候选1字体方框项关闭。末尾Zlib条款/Back只关来源、关键触控取消和球移动复验有效；字体字重偏细建议已反馈。

保留新发现：一次“swipe→Back→Home→恢复”组合附近出现同时间7条引擎self_list.h:46 `Condition p_elem->_root is true`，无GDScript栈、进程仍工作（`.local/verified-android.log`）。分离Back/Home以及24次Back、8次Home压力没再复现，不能确定唯一触发动作，也不能写零ERROR。已由根Agent接手平台暂停时序诊断。自然输入短程到4/6击杀，未注入奖励，三四卡实际Android新滚动边界未在该短程验收。完整新包证据与限制见教程058的Noto兜底节。

继续混合8轮原生输入未再现self_list错误，自然达到6击杀、真实三卡弹出。三卡当前短文案全文可见，原生在中卡向上大幅滑动时却当作选卡提交，成长归0/8、余额未变。三卡无溢出，不推断四卡真实溢出时一定同样；统一“可上下滚动”提示与手势提交可能误导，已报owner，未改冻结源码。四卡仍未实测。详情与前后截图见教程058追加记录。

## 手势修复后final包的实际验收（仍阻塞）

包`builds/release-1-0-0-android-final/PlayABall.apk`，SHA256 `C7770AF9BF274A3B438DCF3BBAF81B176B141F7706B1CEDE7989DC390EDCD5DA`，源指纹`61AD0F0E7BA9D6738EB7D45DCB50F2E93348A05239F59329D0AD28846408026D`。Noto400全角标点/常规字重实际正常；自然6击杀/HP5进入三卡，上划不再提交，随后6币重选扣至0、余3→2、下一价10；下一轻点只提交一次回战斗。截图`final-android-three-before/three-after-swipe/reroll-settled/wallet-after.png`位于.local，详见058。四卡与溢出长卡Android原生仍未测。

final八轮带marker混合Back/swipe/Home重试再现10条self_list.h:46，分别在第1/2轮恢复后、下一后台动作前出现4/6条。`.local/final-android.log` SHA256 `03C57857EFD5874E8525FBF69B69CF84A672A28AB25D552EE49F582705AB70AC`；`.local/final-android-evidence.json`记录包、通过项与错误计数。无脚本错误或FATAL，但此结果按owner约定继续阻塞发布，不能只保留旧包rare风险后宣称final未复现。已同时告知根Agent和独立审查；没有私改冻结运行源码。

有界稳定基线再测两组各6轮，逐轮保存并查看真实HUD：第一组13条self_list、5轮明确有效战斗恢复/发射与1轮普通暂停未恢复；第二组6轮全部正常HP5战斗、物理位置变化，0ERROR。总12尝试/11明确有效，不以死亡/成长模态假充恢复。精确脚本`.local/reproduce_android_pause.ps1`，两组日志/哈希/时区和A候选比较要求见教程058追加基线段。平台Agent不改候选源码，等待根Agent签名A包后相同行为对照。

## A候选对照结果（有限范围未复现）

实际同签名升级的`release-1-0-0-android-pause-a/PlayABall.apk` SHA256 `6719F495EBCDBF5EF57672514246C3523B9EB8D5E9A5475C27234C2992F51EFC`，源`86356E510DE428E38CCFA2A8307FF1C236DAFD3561ADDE7BB9AA5B0DB9520D61`。两次可见新局、相同marker动作/时长，共14尝试：6/6、5/6及补样2/2，13次逐图明确有效恢复/发射；另1次普通暂停未恢复列未确认，不推断原因。有效轮HP5、2–6活敌，球/敌/翻板位置变化，0self_list/脚本/FATAL。额外GUI继续与瞄准撤销后再发射未卡死。首个冷启动仍菜单的6轮作废，不计有效。全部原始日志、SHA、截图命名、限制和`.local/pause-a-comparison.json`见[教程062](../tutorials/062-platform-pause-order.md)原生候选A对照节。

本结论不覆盖ARM真机，不证明唯一根因，也不将基线偶发错误改写为从未出现。旧final包再现的阻塞证据保留；候选A在该范围未复现，交由独立最终Review和owner决定是否按有保留技术结果交付。平台Agent没有修改候选A运行源码。
