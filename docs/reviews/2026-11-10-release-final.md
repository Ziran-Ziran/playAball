# 1.0.0发布构建最终Review

日期：2026-11-10。范围：基线`a494ad2`后的完整本地工作区，分支`feat/release-experience`。用户授权自主优化、导出和本地commit；禁止push、PR和合并。根Agent发起本批Git前最终Review，独立审查者为未参与实现的`independent_review`。本文在最终核验过程中更新，不把未测项写成完成。

## 改动与证据入口

- [总体计划019](../plans/019-release-experience.md)、[第二轮计划020](../plans/020-build-economy-and-skill-payoff.md)：串并联、唯一写入者和验收。
- [初评](2026-11-10-gameplay-assessment.md)、[完整前后与v5复评](2026-11-10-release-playtest-results.md)：16策略、120组合、八阶段、玩家视角三轮反证和真实坏例。
- [全部资产](2026-11-10-art-inventory.md)、[逐份台账](../art/release_asset_audit.json)、[平台/代码覆盖](2026-11-10-platform-audit.md)。
- 教程[056策略](../tutorials/056-strategy-payoff.md)、[057表现](../tutorials/057-build-feedback-and-supply.md)、[058安卓](../tutorials/058-mobile-input-and-release.md)、[059物理锁](../tutorials/059-query-safe-map-pause.md)、[060重选](../tutorials/060-rerolls-and-precision-chain.md)、[061发布](../tutorials/061-release-packaging.md)、[062通知顺序](../tutorials/062-platform-pause-order.md)。

## 自查与修复

基础1050冲量、0反向抵消、2.2秒冷却、0.85传能、120Hz与1点白饭治疗保持；新收益有条件与硬上限，不改变碰撞形状/质量。增加深链伤害/首爆范围、撞杀余势、后段付费整备、6/10/14金币有限重选、同发主球三不同敌直伤最多0.5秒已有冷却回能。

独立审查复现的同步来源复位/移除/释放后旧附加伤害和旧成功信号已修复复测。真实危险球致死暴露旧翻板同步freeze物理锁，修为逻辑同步、物理延后且revision守卫。包探针暴露结算后快速Home的延迟布局失效，已加离树/viewport守卫。

全量回归发现正式随机seed使两个旧夹具首批数量不稳定，`roguelite_run`和`roguelite_kill_run`显式固定31030保留旧基线；正式仍随机。新伙伴卡路径的独立期望更新，不改变28张等级结构。窄四卡完整保龄规则超过旧420高度，按实测文字+最小插画扩高并滚动，保留全文；测试改验裁剪视窗/完整横向/全部文字在实际卡内，未删除失败断言。

Android候选1真实截图发现全角标点方框，增加官方OFL Noto Sans SC作为系统字体fallback，保留桌面首选和ZCOOL标题。Windows真实EXE发现新增路径钩子在_ready注册错过首场景，改在_enter_tree注册后Native release DLL实际加载、人物渲染。原Live2D脚本/模型/动作不改；旁置资源复制清单与ZIP完整性单独验证。

## 测试和构建状态

已完成：隔离APPDATA的53套基线；75项策略、70项第二轮规则、117项GUI输入、40项策略反馈、51项四图物理锁、21项平台专项；独立Agent分别复跑关键路径。新增通知顺序13项以及最新完整61套与最终包复核见本文末尾，开发中通过不能代替最终版本。

18局v4与9局v5原始数据/源清单在`.local/release-v4-*`及`.local/release-r2-evaluation/`。v4旧版本一局真实引擎错误保持invalid；v5九局全部有效且全部自然死亡，无自然胜利。金币重选14次耗120币、7次出现目标；自然回能10次共3.8083秒。1000匹配种子/路线模型6000路径仅是固定收入/满血的乐观抽牌模型，不能冒称真人完成率或把九局说成通关。

Windows原生EXE已通过OS点击开始、R重开、失败返回菜单、Native模块加载和人物渲染观察；工具等待期间自然失败，未完成自然整局，也不把OS拖动尝试冒称成功战斗。重选真实输入证据是Godot原生窗口Input.parse_input_event及滚轮117项，不冒充OS完整试玩。

安卓模拟器实际安装/启动/触摸瞄准取消/返回暂停/后台恢复/完整许可滚动/圆形图标已有证据；候选1标点问题单独保留，最终包字体复验结果另追加。host GPU Compatibility正常，SwiftShader曾报uniform限制；不降物理或画质绕过。ARM真机、长期温升与全部驱动未测。

## 资产、代码覆盖与授权

96源资产、71位图、74旁车逐份登记。新增策略徽记、三张实际伙伴卡、Android分层DS图标与Noto字形兜底；旧图保留历史。源码扫描/精读覆盖清单在`.local/independent_script_coverage.json`，明确扫描与深读范围，不声明每行已经数学证明正确。所有新机制和事务有中文原因注释。

音乐与既有Live2D模型/库公开分发许可均由用户明确确认，记录在来源/随包署名；不是Agent审合同。Godot依赖、字体OFL、Kenney CC0与模型/Native通知保留。签名私钥和口令仅本机私有ACL目录，Git忽略；不随APK、EXE或ZIP分发。

## 仍需保留的限制

- 设计复评是开发判断，流程6.1/10；没有真人自然通关或“爽感已验收”证据，不声称平衡完成。
- 原有ObjectDB/音频退出引用警告仍偶发，未见运行中跨场景累积；不称日志零警告。
- ARM低端设备兼容、峰值帧时/内存、温升、电量与Native完整L0仍未完成。模拟器PSS与桌面合成夹具不是最低配置承诺。
- 提交、push、PR和合并相互独立；本轮只可本地commit，不上传。

## 旧final候选的阻塞记录

最新完整60套已通过`.local/release-final-verify-r7.log`，验证器使用每批独立用户目录；8项Python通过。两个final包的签名/哈希/资源、111份Live2D原字节与wght400/字形/手势源码均经独立复核，最终Android真实自然6杀后的滑动不误选、6→0币/余3→2/新价10、tap一次返回战斗通过。

但该final APK在8轮混合Back/发射/Home中再现10条原生`self_list.h:46`错误，日志`.local/final-android.log` SHA256 `03C57857EFD5874E8525FBF69B69CF84A672A28AB25D552EE49F582705AB70AC`。第1恢复marker后23ms与第2恢复后354ms分别4/6条，独立审查已核实。当时判为**发布门禁阻塞**，该旧包仅留诊断，不作为最终交付。下述A重新导出与验收不删除该失败记录。

## A版本验收与最终交付范围

最小A仅修正系统通知交易：通知立即撤销手势但不释放瞄准暂停，在正常idle中统一接管/恢复；挂起优先、输入屏障、局版本和离树清理均有专项断言。代码独立审查及独立13项/21项复跑通过。完整61套在`.local/release-final-verify-r8.log`退出0，8项Python通过；目录789文件、所有改动路径用途齐全。CI本地补齐相应专项及原漏卡图检查，YAML解析通过，未上传或声称远端测试。

暂存前`git diff --check`退出0只覆盖已跟踪差异，不能代替新增文件检查。111文件暂存后的完整`git diff --cached --check`发现3处格式提示：官方Noto OFL第21行原文尾空格（原件与许可副本各1处）及`credits_panel.gd`末尾多1空白行。明确接受这些无行为影响的格式例外，保留上游许可和已测源码原字节；不称完整暂存空白检查零提示。无密钥、构建成品或未登记文件被暂存。

| 采用的实际成品 | SHA256 | 源指纹 |
| --- | --- | --- |
| `builds/release-1-0-0-windows-pause-a/PlayABall.exe` | `6FB88266B20EF4701838835EC9493445F46C0A82908CB6D7BD6A4073898D6F60` | `CD0793202EA1C2DE84F351DB85D6FC026D5FDEB5B092EACBD676B412D27F84BF` |
| `builds/release-1-0-0-android-pause-a/PlayABall.apk` | `6719F495EBCDBF5EF57672514246C3523B9EB8D5E9A5475C27234C2992F51EFC` | `86356E510DE428E38CCFA2A8307FF1C236DAFD3561ADDE7BB9AA5B0DB9520D61` |

两平台暂存配置、过滤和指纹范围不同，不能直接比较源指纹判断运行脚本不同；实际包受影响脚本另行核对。两包由release模板导出并通过实际资源探针。Windows A真实启动、Native release DLL加载true、退出0、stderr空，`.local/windows-pause-a-native-evidence.json`。现有Live2D原字节不改。

平台Agent对同一A APK在两个新局做同marker原生循环：第一组6尝试/6确认，第二组6尝试/5确认再补2/2，共14尝试/13逐图确认有效恢复发射；另一轮停普通暂停，不算成功、不推断工具原因。均HP5、普通战斗、有多敌/位移，无死亡或成长模态掩盖。全部日志0self_list/ERROR/脚本fatal，额外GUI“继续”、瞄准取消后正常发射可操作。详见062和`.local/pause-a-comparison.json`。基线第一组13错、第二组0错的波动完整保留，**这里只证明A在该范围未复现，不能证明self_list唯一根因或永久消失**。

**最终技术交付Review通过，无剩余已证实P1/P2必须修复项**；[独立Review末尾](2026-11-10-independent-release-review.md)核对了原生分母、原日志哈希、实际包受影响源码、字体/手势、签名、111份Live2D旁置原字节、789目录与CI增量。本轮允许本地commit，禁止push/PR/合并。交付包附操作、许可、哈希与验证边界；已构建并测过的二进制保持原字节，提交后只补充reviewed_commit元数据，不冒称这些字节最初从纯HEAD构建。真人爽感/自然通关、ARM低端与长期温升仍按上文保留。
