# 发布构建独立Review

审查者：`independent_review` Agent。日期：2026-11-10。设备实测 `LAPTOP-8GS4N5SG` / Windows NT 10.0.26200 / `Ziran` / `C:/Users/Ziran/playAball`。基线 `a494ad2`，范围为 `feat/release-experience` 本轮完整本地差异及新增文件。本人未参与实现、未修改运行代码或测试；本文件是唯一允许写入的仓库文件。用户只授权本地commit，不授权push、PR或合并。

## 代码与功能结论

源码主体审查未发现额外可证实P1/P2问题。最终Android原生验收发现的滑动卡片被误当选择，已作为必须修复的核心输入问题修正；新final APK已补实际滑动不选、合法重选及tap选择验证，见末尾。这是有范围的独立审查，不是全部代码无缺陷证明。分阶段已经复现并确认修复两项生命周期问题：附加伤害首目标死亡仅复位来源时仍继续伤害后续目标；退款信号回调移除/释放来源后仍发旧成功信号。实现者补入来源与局/链版本守卫，本人复测原探针和扩充专项通过。

逐脚本覆盖清单保存在忽略的 `.local/independent_script_coverage.json`，明确区分完整精读、任务路径精读和风险扫描。重点核对Build唯一资格源、候选替换、首奖保证、金币6/10/14与三次上限、面板入场与revision归属、原奖励来源/pending/商店库存、同步重开、实伤归因、三不同普通敌同发一次退款、双弹槽不溢出、附加伤害/伙伴/敌投射物不冒领。没有为覆盖率机械重构未发现问题的代码。

表现只消费真实事件及构筑状态，未回写玩法；暂停、重开、模态与减少动态经专项验证。独立输入探针在1024×576验证禁用按钮不响应、付费按钮发正确id/revision、滚动后继续可点。新卡片按全文测高并用Scroll承载；`ocean_ui`的断言从整卡必须塞入视口改为滚动视窗/完整横向/全部文字仍在卡内，没有删除全文边界校验。固定seed与卡图路径的旧测试更新均符合正式随机模式及实际资源变更，不是跳过失败。

Android原生手指index、取消、模拟鼠标隔离、返回与后台暂停、固定世界坐标及安全区映射已读审并独立跑21项通过。状态文本单入口和混音缓存保留原入口数据，粒子预算不再吞音效。翻板物理模式延后且有revision守卫，保持同步死亡与逻辑暂停。独立重跑四图物理锁专项结果另记录在本文件末尾。

Windows新增路径钩子在 `_enter_tree` 注册，不修改既有Live2D适配器；其余模型、动作、Native资源只复制。来源弹窗只读本地文本，Android单APK内也可访问OFL、Kenney、音乐、署名及实际引擎依赖许可。用户确认模型/库与音乐授权是项目事实记录，本审查不冒充合同审查。

## 体验、资产与文档

已核对16策略、全部120卡对和八阶段评分口径。权重优先运营/兑现，分数明确为设计判断。18局v4存在一个旧版本物理ERROR并正确标invalid；v5九局全部死亡，没有被改写为通关。重选14次/120币、7次找到目标、精准回能10次/3.8083秒均保留坏例和限制。6000路径模型假设满血、固定收入与存活，未冒充自然通关率。流程6.1、经营兑现6.2不代表真人满意度；没有证据认定全流派或高反馈爽感已经验收。

96份源资产路径逐一存在且台账无漏项，74份import旁车；71位图的逐图实看由美术Agent完成，本人没有冒称逐像素检查全部素材。本轮另外实看三张新伙伴图、Android DS前景图标、策略UI/三尺寸补给与窄四卡截图。新伙伴图确实表达实际GPT/Claude/Qwen身份，DS人物保持蓝发蓝瞳、女仆头饰与鲸尾；旧动物鱼仍为历史未接正式入口。源码里未发现本轮对既有Live2D脚本的修改。

教程056–061已阅读并检查本地Markdown链接，无断链；说明文件/节点、输入到输出、调参/扩展、真实复现、已知错误及未测项。README/PROJECT/STATUS保留技术检查与真人自然通关/审美/ARM真机的区别。首次收尾目录检查发现最终Review与body_fallback用途未登记、Noto来源文档哈希过期，已交根Agent统一修正；需在最终包收尾后复验，不能用先前59套通过掩盖新增文件。

## 独立实测证据

- `.local/independent_final_economy.out/.err`：冻结源码的经济/精准专项重跑，结果见末尾；此前R2标准命令67项0失败，之后实现者仅补三项附加伤害反例至70。
- `.local/independent_final_pause.out/.err`：四图真实危险球致死/物理锁复测。
- `.local/independent_platform.out/.err`：21项通过，退出0。
- `.local/independent_p2_click.out/.err`：实际引擎输入事件验证禁用、付费和滚动继续；退出0，有既有ObjectDB退出警告。
- `.local/release-final-verify-r5.log`：读取并核对根Agent完整59套通过标志，同时保留ObjectDB2退出警告。它是固定wght400资源补充前版本，不替后续字体变更背书。
- `.local/independent_final_windows_probe.*` / `independent_final_android_probe.*`：对 `*-verified` 前一字体版本的真实EXE/PCK及APK重封资源独立probe，均退出0、`PACKAGE PROBE PASSED`、stderr空；最终 `*-final` 包必须另验。

## 成品复核与尚未完成的验收

前一字体版本 `release-1-0-0-*-verified` 已独立验证：EXE/APK哈希与build_info一致；APK实际apksigner v2/v3验证通过；两目录各五份Notices，APK内五份legal文本；Windows ZIP128项含完整旁置目录，111份运行文件逐项哈希与manifest及原本机来源一致；未发现keystore、口令、preparation.json混入。Android实际含ARMv7、ARM64与供模拟器验证的x86_64，未冒称ARM真机运行。

根Agent随后根据实际字体Thin问题新增FontVariation固定wght400。本次仅审查其资源与两处预载，尚不把前述包结论套在重新导出的 `*-final` 包上。最终成品及目录补项复核后在此追加结论。

仍未完成：真人自然完整通关与经营爽感验收、ARM真机兼容/低端峰值帧时和内存/温升电量、所有音频驱动、完整Native L0。自然AI死亡、渲染夹具、模拟器host GPU与桌面合成测量不能替代这些。可对发布模板技术构建作结论，不能写“总体体验与双平台全面验收完成”。

## 最终补验

70项经济/精准与51项四图暂停专项本人再次独立运行通过、退出0；前者stderr空，后者有既有ObjectDB2退出警告，不能称全套零警告。

Android实际滑动误选已新增UI-only输入guard，保持Scroll接收输入，只在发出upgrade_selected前拒绝超过18逻辑像素的拖动。本人独立读审并运行 `tests/roguelite_card_gestures.gd`，10项0失败、退出0、stderr空（`.local/independent_final_gestures.*`），覆盖原生拖动/释放、模拟鼠标不重置、tap、鼠标拖动/点击、键盘与无motion事件的释放位移。该测试明确断言没有发出选择信号，不仅断言滚动；真实最终APK滑动仍待安装复验。

原生快速Back/Home/恢复中另有一次7条self_list原生ERROR，本人核对 `.local/verified-android.log`：均为09:03:55.256同线程、无GDScript栈，启动另有缓存shader重编译WARNING。包SHA为`DC1A6DB36A67E61CEA722617334C2A811C0D550B6EFADD7C3D82F72618380876`；动作是第三次滑动后等1秒、Back、立即Home、恢复。平台其后24次Back、8次Home、8次混合未复现，物理仍继续产生击杀并进入奖励，未观察到挂起或状态损坏；根因未确认。[Godot官方issue122378](https://github.com/godotengine/godot/issues/122378)描述4.7.1的deferred恢复/物理step与flush顺序问题，目前仍Open/needs testing；同类错误字符串并不能证明同根因，也没有官方无害保证。必须保留原日志、包版本与有界复测次数；若最终包再现或有挂起/物理状态损坏则继续阻塞。若未再现且无实际损坏，可在明确披露风险后对本地release格式构建给有保留技术结论，不等于生产稳定性全面验收。

最终 `builds/release-1-0-0-windows-final` 与 `builds/release-1-0-0-android-final` 已独立补验：

| 成品 | SHA256 | 实际检查 |
| --- | --- | --- |
| Windows EXE，162931288 bytes | `20E952B6952456765715B8839140F15D027AEED405C9062454E81F2C6B87A2A0` | 与build_info一致；独立空目录main-pack包探针通过、退出0、stderr空；ZIP旁置目录112项，111文件与原源/manifest哈希全部一致 |
| Android APK，132819866 bytes | `C7770AF9BF274A3B438DCF3BBAF81B176B141F7706B1CEDE7989DC390EDCD5DA` | 与build_info一致；apksigner v2/v3验证通过；独立APK重封main-pack包探针通过、退出0，有已知ObjectDB2退出警告 |

两个实际包额外探针均返回 `PACK_FONT_WEIGHT=400.0 GLYPH_FULLWIDTH=true GESTURE_GUARD=true LEGAL=true`，证明最终包确实包含固定字重、全角字形与手势guard，非源码兜底。日志 `.local/independent_windows_final_extra.*` / `independent_android_final_extra.*`、`independent_windows_final_probe.*` / `independent_android_final_probe.*`。两包Notices齐全，APK内五份legal文本，未发现keystore/password/preparation.json泄漏。已实看 `.local/final-android-settings.png`，常规字重和全角标点正常。

目录补项复查通过：`PROJECT MAP CHECK PASSED: 786 files`，`.local/independent_final_map_recheck.*`。96资产哈希全部与现物一致，Noto来源旧哈希问题已解决。本人新增的本Review由根Agent统一登记，后续登记新专项造成的树更新由根Agent再做最终check。

平台Agent在准确SHA为C777…D5DA的final APK中无注入自然取得6杀、HP5进入三卡；中卡650,550→650,250上划后仍保留同三张卡。本人实看 `.local/final-android-three-before.png` 与 `final-android-three-after-swipe.png`，不是把单位输入guard绿灯替代实包。随后6币合法重选、候选实际变更，实看 `.local/final-android-reroll-settled.png` 清楚显示余额0/余2次、下一次10币禁用；早先“页脚仍显示旧数”属读图误判已撤回，源码无需修改。平台再轻点补刀一次回战斗，之后自然击杀增加1币，不是免费重选。

前述包技术内容和核心滑动修复核对通过后，**该轮最终Review曾判定阻塞**（后续A修复与关闭记录见下）：平台最后8轮原生混合marker在相同final APK再现10条self_list.h:46 ERROR。Mixed1恢复23ms后4条，Mixed2恢复354ms后6条，均早于下一轮Back/Home；日志 `.local/final-android.log`，SHA256 `03C57857EFD5874E8525FBF69B69CF84A672A28AB25D552EE49F582705AB70AC`。这已经满足前述“final再现继续阻塞”的条件，不能用其后能玩或没有崩溃替代排查，也不能声明零ERROR/发布稳定性通过。

建议只进行有界定位与相关复测：核对Android通知中直接恢复，以及暂停接管前 `launcher.cancel()` 是否在未blocked且拥有瞄准暂停时短暂恢复SceneTree；参考教程030把恢复移到正常_process的既有经验。该推断未被根因实验确认，独立审查者不参与修复。修复后重导受影响包并重跑同marker序列，再复查物理与暂停所有权；不为排错盲目重写全部架构。

### 通知顺序候选A的审查与关闭

本人独立读审最小A：Arena通知仅累积Back/Suspend意图，立即cancel(false)撤销输入资格但不恢复Tree；正常_process首部原子消费，Suspend优先，同批重复Back合并，局context/离树丢弃旧请求；pending期间阻挡旧释放与新按下。Launcher Android焦点丢失也不抢先释放瞄准暂停；普通GUI/瞄准及桌面默认取消语义保留。

独立运行新增 `tests/roguelite_platform_pause_order.gd`：13项0失败、退出0、stderr空，`.local/independent_pause_a_order.*`；原平台专项21项亦通过，`.local/independent_pause_a_mobile.*`，后者有既有ObjectDB4退出警告。代码与专项证明通知顺序不变量改变，不证明self_list根因或已经消失。

基线两组结果有13→0波动，因此A首组0时没有提前解除运行阻塞，而是继续准确签名包、相同marker序列、多敌新局和恢复后的玩法状态对照。前面C777…的包保留为发生过ERROR的旧候选证据，不再作为当前交付包。

**最终门禁结论：A修复完成有界闭环，本轮技术交付Review通过；无剩余必须修复的已证实P1/P2项。** 该结论允许用户已授权范围内的本地commit与A包交付，不授权push/PR/合并，也不表示真人经营爽感、ARM真机最低配置或全部驱动已验收。

关闭依据：

- 根Agent最新隔离用户目录完整61套退出0，`.local/release-final-verify-r8.log`末尾VERIFIED已核对。本人读审验证器GUID新APPDATA与try/finally恢复、61套入口与完成标志；CI新增9套脚本/markers对应正确（含原CI漏掉的card_art），只是本地审查，未上传或运行远端CI。
- Android准确A包SHA256 `6719F495EBCDBF5EF57672514246C3523B9EB8D5E9A5475C27234C2992F51EFC`，源暂存指纹`86356E510DE428E38CCFA2A8307FF1C236DAFD3561ADDE7BB9AA5B0DB9520D61`，哈希与metadata一致，独立apksigner v2/v3验证通过。
- 两个新局14次尝试、13次逐图确认普通BATTLE恢复/发射：live1为6/6，live2为5/6，加补样2/2；1次仍普通暂停未确认，保留在分母14且不归因工具。冷启动停在菜单的pause-a-group1整组排除。平台实看全部循环；本人读取三组原日志与JSON、核对每份log SHA、抽看live1-cycle0/5、live2-cycle4/5及extra-cycle1，确认被排除的cycle5确为暂停，其余抽样有活动敌人/不同位置。三组engine/script/self_list/fatal均0；额外GUI继续、撤销瞄准后再发射无卡死。精确汇总`.local/pause-a-comparison.json`、原始`.local/pause-a-live1.*`、`pause-a-live2.*`、`pause-a-live2-extra.*`，不将摘要中的cycles误当全部有效。
- Windows准确A包SHA256 `6FB88266B20EF4701838835EC9493445F46C0A82908CB6D7BD6A4073898D6F60`，源暂存指纹`CD0793202EA1C2DE84F351DB85D6FC026D5FDEB5B092EACBD676B412D27F84BF`；独立比对111份旁置文件与原来源/manifest全一致，ZIP有112项旁置目录条目，无密钥/准备报告。根实际启动证据`.local/windows-pause-a-native-evidence.json`为release DLL加载true、退出0、EXE哈希准确。Windows/Android导出设置不同，暂存指纹不同，不冒称两个输入哈希相同。
- 两个A实际包独立空目录main-pack专项均为 `PACK_A_IDLE_PAUSE=true FONT_WEIGHT=400.0 GESTURE_GUARD=true`，退出0、stderr空，`.local/independent_windows_pause_a_pack.*` / `independent_android_pause_a_pack.*`，证明受影响内容确实进入成品。
- 最新目录独立复查`PROJECT MAP CHECK PASSED: 789 files`，`.local/independent_pause_a_map.*`。当时未暂存的`git diff --check`退出0只覆盖已跟踪差异，不涵盖原untracked新增文件；完整暂存检查的三项格式例外见下，不能据前者声称全部新增文件零格式提示。96资产路径/哈希及教程链接前述问题均已关闭。

这关闭的是已知通知栈瞬时恢复/暂停所有权风险：代码有可验证顺序约束，并在两个新局的同序列原生样本没有再现。self_list唯一根因未被引擎插桩证明，基线自身有波动，样本亦非统计独立；仍保留间歇性引擎风险，不能说“所有self_list错误彻底修复”。原错误、失败包、红绿与未确认轮次均保留。如果后续准确A包再次出现相同错误，应重新打开对应问题；不因无法证明永不复现而无限阻止已满足本轮预定门槛的技术交付。

最终文档增量已独立复核：STATUS、整批自查Review、计划019/020与教程062与上述采用A包/61套/13有效14尝试/旧失败保留/真人和ARM未测口径一致；没有把OS菜单点击、引擎输入事件GUI与Android原生操作混为完整自然通关。CI未上传、本轮不push/PR/合并的授权边界明确。此后仅在忽略的成品元数据补充真实reviewed_commit，不改变已测EXE/APK字节，不把这些成品冒称最初从纯HEAD构建。本人Review至此冻结；若运行源码或交付二进制再变，应按受影响范围重新核验。

### 完整暂存后的格式复核

根Agent暂存111个已审文件后，本人实际运行`git diff --cached --check`，退出码2，精确列出三处：`assets/fonts/noto_sans_sc/OFL.txt:21`与`resources/legal/Noto_OFL.txt:21`原许可文本各有一个行尾空格；`scripts/ui/credits_panel.gd:60`为文件末额外空白行。先前未暂存检查没有覆盖这些原untracked文件，不能写成完整暂存检查通过。

两份OFL字节完全相同，SHA256均为`1c05c68c34f9708415aada51f17e1b0092d2cea709bf4a94cd38114f9e73d7d9`；三份文件的索引字节均与已审工作区一致。独立接受这三处为明确记录的非阻塞格式例外：保留许可原文及已测包对应源码，不改变行为，不需要重测或重导。此处接受例外不等于忽略其他未审格式问题；本次完整暂存检查仅有上述三项，技术交付Review结论不变。
