# 058 · 触控、双平台release与有证据的性能改进

这一批让同一套RigidBody2D玩法可以用Windows鼠标和Android触屏操作。发射、伤害、伙伴、敌人数、难度和120Hz物理规则保持一致，平台层只把玩家输入送给原有DemoLaunch接口。

## 文件与输入流程

- `scripts/roguelite/arena.gd`：鼠标与手指入口。只有第一个未被GUI消费的手指可以开始瞄准；保存其index，后续拖动/释放必须匹配。其他手指不能抢发，但能按可见取消键。GUI仍使用系统触摸模拟鼠标；战场忽略DEVICE_ID_EMULATION，避免同一手势发两次。
- `scripts/ui/game.gd`：Android显示60逻辑像素高的取消按钮、加高暂停按钮及触屏提示。按钮只调用取消/暂停接口，不扣弹槽。安全区从显示坐标映射回固定1280×720画布，移动关键操作区和生命读数，不改刚体位置/世界缩放。
- `scripts/ui/main_menu.gd`：Android返回键关闭设置。其他主菜单行为与现有Live2D内容不改。
- `project.godot`：1.0.0，横屏、canvas_items保比例letterbox、关闭系统返回直接退出；导出Android需要ETC2/ASTC导入支持，Compatibility保持不变。
- `tests/platform_mobile.gd`：触摸归属、取消、模拟鼠标、等待回能、返回、后台、成长暂停、桌面鼠标、粒子满载与安全区映射回归。

按下 → GUI先处理按钮 → 空白未处理事件占有手指index → DemoLaunch.request_aim → 冷却时保持等待，就绪时冻结战斗 → 相同手指释放 → 原launch_with_drag校验并施加冲量。Android系统取消、可见取消键和切后台均清除占有，陈旧释放不会发射。

系统返回通过handle_back_request打开/关闭手动暂停；Director仍校验当前状态，因此不会跳过成长、商店或结算。后台进入暂停，返回应用不会自动恢复战斗；玩家明确继续。Windows失焦继续原来的取消手势语义。

## 性能改动为什么安全

旧的继承链会每帧按试验场、run、正式game格式依次写三次同一status。现在由arena调用可覆写battle_status_text，只生成最终入口的一份字符串，相同文字不再次提交Label。不同调试入口保留各自读数。

run_arena缓存音量/静音三元组；每帧兼容性同步仍存在，但没变化时不再遍历AudioDirector声部、写后端音量。控件及MusicManager信号改变时，现有尾音依然即时响应。

impact_feedback先请求声音，再检查18个粒子节点上限。音频自己的冷却/声部优先级继续生效；满粒子预算不会额外吞掉音效。不是无限增加声音或粒子。

不盲目降低纹理、敌人数量或物理Hz。图集的AtlasTexture用源像素裁切，不能随意改尺寸后不更新裁切区域。低端性能门槛仍要真实设备长局与峰值场景测量。

## 参数与扩展

检查器可继续调整DemoLaunch.cooldown和freeze_while_aiming；平台输入不保存一套不同数值。移动取消按钮的168×60与位置在game._ready/_apply_safe_layout中，修改时同时测试底部构筑条与触屏遮挡。新增触屏动作先定义唯一手指归属，不能把任意ScreenTouch释放直接接到发射函数。

安全区使用viewport.get_screen_transform而不是Camera2D变换，避免震屏引起按钮移动。当前横屏16:9世界保持固定；极窄设备、小于900×500逻辑安全区域及实机刘海仍需专项验证，不写成所有屏幕通过。

## Android导出

`export_presets.cfg`提供Android Release：ARM64与ARMv7，Compatibility，包名org.playaball.game，版本1.0.0，minSDK24/targetSDK36由本机固定引擎模板声明。最低声明Android7不等于已验证最旧设备。

```powershell
# 路径由当前机器实际调查提供；不要复制另一台机器的绝对路径。
./tools/export_android.ps1 -GodotExe $GodotExe -JavaSdkPath $JdkDirectory `
    -AndroidSdkPath $SdkDirectory -BuildName release-android-1_0_0 -Signed
```

签名要求调用环境设置GODOT_ANDROID_KEYSTORE_RELEASE_PATH、GODOT_ANDROID_KEYSTORE_RELEASE_USER与GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD；脚本不打印值、不把它们写入preset。密钥和口令保存在私有位置，并由owner单独备份；删除密钥可能无法给已安装用户更新。不带-Signed只产未签名release，不能直接安装或称商店发行包。

helper每次在.local创建独立源码暂存和APPDATA，写最小EditorSettings，仅指定JDK/SDK；原用户全局配置通过前后哈希核对。固定4.7.1模板通过暂存custom_template路径使用；不修改工程或全局路径。产物在builds，含APK、真实Manifest、源指纹/包SHA256、签名状态和日志位置。构建目录已存在就拒绝覆盖。

APK使用模板导出再由apksigner签名和verify。Manifest用aapt2检查真实ABI/minSDK/targetSDK；aapt1不能解析当前exporter的部分字符串布尔属性。正式默认不带x86；-EmulatorX64额外加入x86_64，仅用于模拟器测试，不能冒充ARM真机结果。

helper另外从真实APK的assets目录提取资源为ZIP，用同版编辑器在空成品目录执行package_probe，检查实际地图、成长、音源、重开和排除清单。不能把--path指向源码，否则源码可能补齐漏包资源，造成假通过。失败日志保留，只有签名、Manifest和包内行为探针均通过才打印READY。

## 验证与已知限制

专项先红灯（取消/返回/后台接口缺失），再headless和原生GUI21项0失败；原战术瞄准0失败、输入反馈49项通过。日志`.local/p3-platform_mobile.*`、`.local/p3-gui.*`；1024×576暂停界面截图`.local/platform-mobile-gui.png`已实际检查。Windows鼠标左键瞄准/右键取消保留。

测试用正式游戏APK完成隔离release导出、临时证书签名、Android15/API35 x86_64模拟器安装与Compatibility启动。WHPX+host NVIDIA渲染可显示菜单、进入战斗、拖拽与系统返回暂停；Home后恢复仍暂停。截图`.local/p3-android-battle.png`、`.local/p3-android-finalpause.png`，日志`.local/p3-android-host.log`。这是旧catalog测试构建，最终统一发布包需再次导出并核验指纹。

SwiftShader模拟器初次运行出现基础CanvasShader的uniform261上限错误；切换host GPU后同一APK运行无该错误。没有为绕过模拟器修改画质。ARM真机与低端GLES设备尚未实测，不能认为所有硬件兼容。模拟器单次战斗暂停采样PSS约196MiB、RSS约299MiB（dumpsys，非GPU显存/峰值/长局温升），不作为最低硬件保证。独立ADB端口5038避免本机旧ADB和新ADB争抢。

本机另做18敌人+3伙伴的合成压力夹具，360个原生渲染帧、前60帧预热；仅夹具把HP设1000保持采样存活，明确不是正常策略局。物理帧时中位0.973ms/P95 1.426ms，process中位8.341ms/P95 32.514ms，静态内存141.4MiB；当时模拟器与部分回归并行运行，process还含同步影响，不能据此宣称稳定120fps或降低最低设备需求。原始`.local/p3-native-perf.json`与夹具`.local/p3_perf.gd`。

常见错误：Release签名漏环境变量；SDK只有platform-tools没有build-tools36；模板不是4.7.1；误用Godot内部GodotApp Activity启动。实际可导出启动入口是GodotAppLauncher，命令应以真实Manifest为准。当前Android没有原生Live2D，沿原有静态人物回退；Windows私有运行资源的打包由独立流程管理。

官方依据：[触摸与模拟](https://docs.godotengine.org/en/stable/classes/class_input.html)、[安全区](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)、[Android导出](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)、[平台标签区分大小写](https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html)。在线stable会变，实施以固定引擎实测为准。

## 1.0.0候选1实际APK复验

2026-11-10在同机WHPX+host NVIDIA、Android15/API35 x86_64模拟器，卸载本任务旧probe签名包后，实际安装 `builds/release-1-0-0-android-universal-candidate1/PlayABall.apk`。该候选使用owner的新发行证书，非临时probekey。源指纹 `3C63156B78C1BFE5BFB3F8D64A1CFF0BA2AAE201E751B7F7C3C1CA17D8EE5E55`；APK SHA256 `C54029E883D6BA850F9EBCBAA74CE6B8A47AE2329F51CD4E3940A164057C1A20`。这些标识只对应候选1，后续修订需重导出复验，不是最终发行声明。

原生Android输入实际检查：菜单进设置；制作与来源显示中文来源和许可；手指滑动能滚到后续英文OFL；系统Back只关闭来源、保留下层设置，第二次Back才回主菜单。进入战斗后以原生DOWN/MOVE维持瞄准，能看见箭头与取消键；拖入取消键后UP撤销，Back打开暂停；恢复后普通swipe发射，Home切后台，再启动应用仍是暂停界面。桌面圆形adaptive图标遮罩显示人物完整，无裁掉脸部。

来源另外拖动滚动条至全文末尾，实际看到最后Zlib第3条版权限制，返回按钮仍可见，证据`candidate1-android-license-end.png`。正文允许选择，长拖有时进入文本选择；滚动条能稳定到末尾，不能把文本选择误当界面卡死。

截图均在`.local/`：`candidate1-android-menu.png`、`candidate1-android-settings.png`、`candidate1-android-credits-top.png`、`candidate1-android-credits-scroll.png`、`candidate1-android-credits-back.png`、`candidate1-android-aim.png`、`candidate1-android-cancel-pause.png`、`candidate1-android-background-resume.png`和`candidate1-android-launcher.png`。实际查看后记录，不以源代码截图代替Android画面。`.local/candidate1-android.log`本次未检出Godot ERROR/FATAL/SCRIPT ERROR；单次dumpsys内存PSS208371KiB/RSS314168KiB，仍不是峰值、ARM设备或长局温升证据。

候选1发现的待复核问题：设置和来源文本的部分全角标点显示方框，中文主体可读；已交owner/独立审查判定，未在平台测试中私改冻结源码。屏幕字体修订后应重新导出并复验来源可读性，不能把此问题省略成“所有界面无问题”。

## Noto兜底版实际升级复验

后续实际安装`builds/release-1-0-0-android-verified/PlayABall.apk`，`adb install -r`从候选1成功升级，证明该测试路径沿用相同发行身份。源指纹`6DBC69146C09BD7E380884FDA5527EE9B9D08205960AB5F737152FA6B0AB1DB4`，APK SHA256`DC1A6DB36A67E61CEA722617334C2A811C0D550B6EFADD7C3D82F72618380876`。

实际Android设置中“Let Me Go（共创版）”的全角括号、来源中的《》、（）、中文逗号和句号均恢复，Noto来源行可见：候选1方框问题在此包关闭，不是通过把中文换成英文来规避。截图`.local/verified-android-settings.png`、`verified-android-credits-top.png`。本次字重仍偏细，已反馈owner，若后续调整字重并重导出，此哈希不能代替新包复验。

来源能滚至末尾Zlib第3条、Back只返回下层设置（`verified-android-license-end.png`、`verified-android-credits-back.png`）。原生瞄准有箭头/取消，拖入取消释放后可正常发射，球实际移动（`verified-android-aim.png`、`verified-android-battle.png`）。没有注入生命/钱币/奖励；这次短程原生输入到4/6击杀，未自然进入三/四卡面板，Android卡片新滚动边界未在此短程验收，不能以脚本布局通过替代。

本包运行观察到一次引擎时序错误：swipe后Back紧接Home/恢复组合附近，日志同时间7条`Condition "p_elem->_root" is true`（`core/templates/self_list.h:46`），没有GDScript堆栈，进程仍可操作。完整首次证据`.local/verified-android.log`；分离Back两次、Home恢复、24次Back压力及8次Home恢复未再次出现（`verified-back-isolated.log`、`verified-home-isolated.log`、`verified-back-stress.log`、`verified-home-stress.log`）。首次组合恢复截图仍显示战斗，后续独立Back/后台检查可显示暂停。已交根Agent按既有正常_process暂停边界诊断，不在测试中私改源码。另有一次shader缓存失效重编译WARNING。该包不能记录为零运行错误或完整平台通过。

后续8轮原生发射/Back/Home混合重试无新ERROR（`verified-mixed-stress.log`），并自然达到6击杀进入真实三选一，未加HP/钱币/奖励。`verified-android-final-state.png`中外包/补刀/危险范围缩小三卡中文全文可见；Back/Home未跳过成长模态。随后尝试中卡从(650,550)向(650,250)滑动，实际被当作选卡提交，返回战斗、成长变0/8、余额仍6（`verified-android-card-scroll.png`）。这次三卡短文案无溢出，不能据此断言四卡溢出拖动也会误选；但页脚的统一可滚提示会诱导尝试，已交owner评估大位移抑制选卡或条件提示。四卡仍未自然进入，未宣称实际Android四卡验收。首次self_list错误证据继续保留，不用成功重试覆盖。

## 卡片滑动误选修复

真实Android发现的问题通过发布前补丁修复：`upgrade_card.gd`只观察`_input`中的原生手指和真实鼠标，保存按下的视口逻辑坐标；任意移动或最后释放距离大于18像素即把本次标记为拖动。模拟鼠标事件不重置原生手势；释放后保留标记，下一次真实按下才重新开始。键盘ui_accept保留正常选择。

`run_hud.gd`仍连接原Button.pressed，但先检查`card.can_submit_selection()`，只有轻点/键盘才发原`upgrade_selected(id, offer_id)`。Director原来的候选、revision、交易与入场校验不改。卡片观察不调用accept_event、不移动滚动条，外层ScrollContainer继续处理滚动；动态正文最小卡高和始终Scroll结构均保留。页脚改为“轻点选择 · 长卡可上下滚动”。

新增`tests/roguelite_card_gestures.gd`先验证缺提交guard的红灯，最终headless14项、Windows原生GUI16项0失败。覆盖触摸drag/release、最后释放才产生位移、模拟鼠标重复、零位移tap、鼠标drag/click、键盘、viewport真实touch拖动不提交与下一tap恰好一次；长说明不裁切、滚轮仍到达ScrollContainer。桌面DisplayServer不是Android触屏设备，长卡原生触屏滚动另在重导APK上复验，不能用桌面滚轮结论代替。日志`.local/card-gesture-headless.*`、`.local/card-gesture-gui.*`；headless明确跳过native GUI tap命中，保留显式事件单元检查。原16卡内容流、484项排版、鼠标UI与平台21回归也通过。

## 带手势修复的final命名包：真实通过项与阻塞项

文件名包含final不等于发布验收通过。实际包`builds/release-1-0-0-android-final/PlayABall.apk`，SHA256 `C7770AF9BF274A3B438DCF3BBAF81B176B141F7706B1CEDE7989DC390EDCD5DA`，源码指纹`61AD0F0E7BA9D6738EB7D45DCB50F2E93348A05239F59329D0AD28846408026D`。同签名升级安装成功；实际设置图`final-android-settings.png`确认Noto400字重与全角标点正常。

通过原生瞄准/发射自然达到6击杀、HP仍5，不注入HP、钱币或奖励。真实三卡中卡上划后仍保持同一面板，未提交升级（`final-android-three-before.png`与`final-android-three-after-swipe.png`）。随后合法6币重选：余额6→0、余次3→2、下一价格10且禁用；再轻点补刀只提交一次回战斗，之后自然额外击杀1，显示金币1、成长1/8（`final-android-reroll-settled.png`、`final-android-wallet-after.png`）。初次对页脚数值读图误判为未刷新，经owner与同图复核撤回，没有因此改源。四卡/实际溢出长卡仍未自然进入，保留未测，不把桌面回归冒充Android原生验收。

**发布阻塞仍存在：** final同一包8轮“Back恢复→原生swipe→等1秒→Back紧接Home→恢复”带marker混合复验，再现10条引擎self_list.h:46错误。Mixed-1-resume 09:46:06.390后23ms出现4条，Mixed-2-resume 09:46:08.738后354ms出现6条，均早于下一BackHome标记。无SCRIPT ERROR/FATAL，进程仍能显示暂停，但不能把该结果写成零错误或发布通过。证据`.local/final-android.log`，SHA256 `03C57857EFD5874E8525FBF69B69CF84A672A28AB25D552EE49F582705AB70AC`；结构化记录`.local/final-android-evidence.json`。旧7条日志完整保留，根Agent与独立审查已接到复现并继续处理。

进一步基线定位使用`.local/reproduce_android_pause.ps1`，每轮额外保存swipe后1秒的HUD截图，防止把死亡或成长模态的拒绝恢复算作有效。连续两组各6轮：第一组13条self_list，5轮明确有效战斗/发射、1轮仍普通暂停；第二组6轮全部HP5正常战斗，球/敌/翻板位置持续变化，0ERROR。合计12尝试/11明确有效恢复发射，不把12全部算有效，仍不代表没有物理异常。日志`baseline-pause-six.log` SHA256 `628F5E9458948BE03D6735B100443AF9DCAF2B7ECD02EBE190BBE8A088CD5503`及`baseline-pause-six-b.log` SHA256 `A1372A9653B65F5E739629795E552B702F8EE87EB98A7616849210617E11976D`。

模拟器时区实际为GMT（日志09:55对应本机17:55+08），前后动作毫秒差只比较同一logcat时间。两组错误既在BackHome后也在恢复后出现，不预先认定唯一触发点；A候选仅改通知暂停意图消费时序，由另一Agent单写，待签名APK按相同脚本、存活/有敌人的相近场景对照。

候选A后续对照已完成：同发行签名包`release-1-0-0-android-pause-a/PlayABall.apk`，SHA256 `6719F495EBCDBF5EF57672514246C3523B9EB8D5E9A5475C27234C2992F51EFC`，source `86356E510DE428E38CCFA2A8307FF1C236DAFD3561ADDE7BB9AA5B0DB9520D61`。两新局同脚本14尝试/13逐图明确有效恢复发射，HP5、2–6活敌，0ERROR/script/fatal；1次仍普通暂停列未确认，没从分母删除。另GUI继续、瞄准撤销/正常再发射未观察卡死。日志、逐组SHA和作废冷启动菜单批次见[教程062](062-platform-pause-order.md)原生对照节；本机汇总`.local/pause-a-comparison.json`。只称候选在此范围未复现，不删除旧包错误或宣称所有平台彻底修复。
