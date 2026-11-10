# Android系统通知与暂停交易的顺序

本教程记录发布阻塞的候选A。它不是“改成_process就证明修复”的结论；Android原生同动作对照通过前，不能把self_list问题标记已解决。

## 真实基线和假设

设备LAPTOP-8GS4N5SG，Windows；平台Agent使用Android15/API35/x86_64/WHPX模拟器。基线APK SHA256为`C7770AF9BF274A3B438DCF3BBAF81B176B141F7706B1CEDE7989DC390EDCD5DA`。`.local/final-android.log`哈希`03C57857EFD5874E8525FBF69B69CF84A672A28AB25D552EE49F582705AB70AC`，8轮Back/Home/发射混合序列产生10条`p_elem->_root`/self_list ERROR；最初两次恢复marker后23ms/354ms各有4/6条。

更明确脚本`.local/reproduce_android_pause.ps1`从正常战斗手动暂停开始：marker resume→系统Back恢复→250ms拖拽→等1秒截图→marker BackHome→Back暂停→Home→重新进入Activity。第一组六轮13条ERROR、0脚本fatal，5次截图确认有效战斗发射；第二组六轮0ERROR、6次确认有效。基线不是每轮必现，不能把候选单组六轮0错误当充分修复证据。

错误没有GDScript栈。教程030记录过同类引擎问题，但仅同字符串不足认定根因。当前可直接验证的代码风险是系统通知栈内`handle_back_request→launcher.cancel→Tree.paused=false→Director.set_paused`，瞄准取消可能先恢复物理一次，再由菜单接管暂停；Launcher自身FocusOut通知也可抢先恢复。候选A只针对这两条通知入口交易，不先重写全部瞄准/GUI恢复路径。

## 文件与顺序

- `arena.gd`：系统Back/挂起通知只记录意图；立即撤销手势资格，但不释放aim拥有的Tree暂停。`_process`最前消费整笔交易。Arena在场景中使用Always process，树暂停时仍能消费。
- `launch_controller.gd`：`cancel(release_owned_pause=true)`保留原默认语义；平台通知调用false，只清输入/所有权，不在通知栈改Tree.paused。Android Launcher FocusOut也使用false，不能抢在父Arena前恢复；桌面原FocusOut语义保持。
- `run_arena.gd`：为意图提供Director当前run_revision，旧局请求不能在重开后暂停新局；等待意图时屏障也先于R重开快捷键。

通知到达→记录Back/Suspend位→cancel(false)清手指与旧释放资格→输入屏障拦旧释放/新按下→正常idle `_process`消费→再次无恢复取消→由当前Director校验状态并一次切暂停。Suspend优先于同批Back；同批重复Back合并一次。升级/商店/结算不让平台意图夺暂停所有权。换局token不匹配直接丢弃；离树清空队列。

这里不用call_deferred代替idle：延后队列仍可能落在物理step/flush间隙，目标是明确由正常_process消费完整交易。没有延后死亡/受伤判定，没有修改1050冲量、2.2秒基础冷却、120Hz、伤害/经济、Live2D或卡片UI。

## 本机红绿与限制

Godot4.7.1，标准命令：`--headless --path . --script tests/roguelite_platform_pause_order.gd`。红灯证明Back通知栈立即恢复Tree且缺正常idle消费，退出1；日志`.local/platform-pause-order-red.out/.err`。候选A绿灯13项0失败、退出0，无错误警告；日志`.local/platform-pause-order-green.out/.err`。

回归验证：通知栈不恢复、idle消费才恢复、aim取消不瞬时恢复、旧释放不发射、新手指不能穿过挂起屏障、重复Back合并、Suspend优先、重开旧请求作废、升级暂停所有权和离树清队列。相关原回归platform_mobile21、战术瞄准、input_feedback49、pause_physics51和sea_ui_mouse退出0；部分旧用例仍有ObjectDB2/4退出警告，未隐藏。

这些证明交易入口顺序和原功能边界，不证明Android原生self_list已消失。原生候选需使用同marker动作脚本、保存APK/源哈希、至少核验有效操作与真实接触次数，保留失败轮和截尾；基线已经出现13→0的批次变化，候选0错误必须写成“在该范围未复现”。若仍出现，再定位战术aim take/release及GUI恢复按钮直接Tree.paused的真实时序，不先扩大无关重构。

## 修改时常见错误

- 通知里先普通cancel再排队：已经恢复一次Tree，队列不能撤回这个副作用。
- 只排pause而不撤销手势：旧touch释放能在消费前误发。
- 用物理帧信号/call_deferred代替正常idle：无法证明避开原有step/flush间隙。
- 只保留一个bool暂停：无法表达Suspend压过Back及旧局请求作废。
- 候选六轮0错误即宣布解决：基线本身有六轮0错误，必须保留原生对照和概率限制。

## 平台Agent原生候选A对照

候选APK：`builds/release-1-0-0-android-pause-a/PlayABall.apk`，实际SHA256 `6719F495EBCDBF5EF57672514246C3523B9EB8D5E9A5475C27234C2992F51EFC`，源码指纹`86356E510DE428E38CCFA2A8307FF1C236DAFD3561ADDE7BB9AA5B0DB9520D61`。同一发行签名`adb install -r`升级成功，设备/模拟器/ADB5038保持与基线一致，没有为测试改HP、钱币、敌人数或奖励。

动作使用同一`.local/reproduce_android_pause.ps1`，脚本SHA256 `2BC0FF2EFF18485D18BAED87694F17EA8596AD8085EE29D9AF9E886577BC2C4B`。两次通过可见菜单启动/重新开局进入新局，再等自然多敌出现，普通暂停后开始；每轮仍是Back恢复、250ms native swipe、等1秒截图、Back紧接Home/重新进入。逐张查看截图，不用程序循环次数代替有效发射数。

| 原生批次 | 尝试 / 明确有效恢复发射 | 实际状态 | ERROR / SCRIPT ERROR / FATAL |
| --- | --- | --- | --- |
| pause-a-live1 | 6 / 6 | HP5，正常战斗，2–3敌、预警/击杀，球与敌位置变化 | 0 / 0 / 0 |
| pause-a-live2 | 6 / 5 | HP5，4敌；第5张仍普通暂停，列未确认，不推断原因 | 0 / 0 / 0 |
| pause-a-live2-extra | 2 / 2 | 同一第二新局补样，HP5，6活敌、真实位置变化 | 0 / 0 / 0 |

合计14次尝试，13次明确有效恢复/发射，第二新局共7次有效。没有把死亡、成长或未恢复的轮计为有效；首次冷启动tap早于菜单就绪的`pause-a-group1`整组六轮仍是主菜单，已作废排除，不能拿它的零日志算通过。各有效截图`${prefix}-cycle-N.png`均保留在.local；第2组cycle5普通暂停的截图也保留。

精确日志SHA256：

- `.local/pause-a-live1.log`：`92303D6DE697842DD99D5B9BCA28EFB22DD139099E01416C0D1CE5DADE36D7B8`。
- `.local/pause-a-live2.log`：`32F5E334235AFA8160523D0A8633CEC2DDF90017A5B600775FB81D370A43E541`。
- `.local/pause-a-live2-extra.log`：`D627216086E9AF5A3F23BD3FF50EAB8EB7A073DAEB1A9E9743C96B2427F76760`。

额外实际点击GUI“继续”，瞄准后拖入取消区、再正常native swipe，之后Back暂停，球/敌/翻板继续移动，无卡死或新ERROR。截图`.local/pause-a-gui-continued.png`；日志`.local/pause-a-extra-gui.log` SHA256 `ECE83B29AA4AA062BF489F7A4139AB429E03C1B314DEC11CAAC0C822FE025EE3`。该画面不能独立精确计数所有碰撞或证明每个旧释放均拒绝，旧释放细节仍由专项测试支撑。

结构化汇总`.local/pause-a-comparison.json`，各组`.json`提供原始计数。原基线7条、final10条及稳定基线13条日志没有覆盖。结论仅为**候选A在上述范围未复现self_list，13次确认操作未观察到物理挂起**；基线本身已有13→0批次变化，不能宣称唯一根因或所有Android设备已彻底修复。是否按有保留技术验收交付由根Agent与独立审查结合完整变更决定；ARM真机仍未测。

本修正没有新增检查器调参，保持`freeze_while_aiming=true`、120Hz及原发射/玩法参数。扩展新的系统通知类型时，应加入同一意图交易、换局版本校验与专项测试；不能重新在通知栈直接恢复Tree暂停。
