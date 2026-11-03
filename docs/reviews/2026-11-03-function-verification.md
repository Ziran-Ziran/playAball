# 全功能复验与翻转板修复

日期：2026-11-03。实现/自查：主Agent；独立只读审查：未参与实现的`independent_review` Agent。基线8b7b0ad；原目录分支codex/verify-gameplay-and-paddle。用户本轮已授权功能逐项验证后commit/push、创建PR并合并；不重做未认可生图，不扩主动技能。

当前阶段：本地功能复验、普通包、原生输入及最终独立增量复核完成，未发现阻塞项，可进入用户本轮授权的Git阶段；远端PR/CI及合并结果以GitHub实际状态为准。

## 修复与对照

| 同输入场景 | 修复前 | 当前结果 |
| --- | --- | --- |
| 中心板，80速度轻碰 | 峰值0.7154rad/s，最大摆角0.2720rad | 0.4408rad/s、0.1224rad |
| 中心板，300速度 | 峰值3.1997rad/s | 1.2rad/s |
| 中心板，1050速度 | 峰值10.2541rad/s；7秒后7.6252rad/s；摆角越界 | 峰值1.2rad/s；7秒后小于0.00001rad/s；最大摆角0.3796rad |
| 偏心板，1050速度 | 峰值7.3052rad/s，摆角2.0121rad | 1.2rad/s、0.6835rad |
| 旋转父节点，反复推向0.25rad限位 | 补充的边界场景 | 最大偏差约0.25075rad，反向冲量能推回 |

采用：板质量3→6、角阻尼1.4→2.6、物理接口限速1.2rad/s及相对初始角度限位。关闭内置异常角度限制但保留真实Pin轴心。没有按动画改刚体位置/角度。新回归修复前64项中16项失败；新增反复撞击等边界后继续发现并处理小幅累计漂移；最终71项零失败。原始日志保留`.local/feature_review/paddle-response-*`，成功结果另保存`.local/paddle_response.json`。

## 逐项功能验证清单

以下“验证”表示确定夹具中的功能效果，未宣称人类自然完整通关。

| 功能 | 实际实验及判断依据 | 对应测试 |
| --- | --- | --- |
| 拖拽、取消、运动中再发、冷却预按 | 引擎视口输入、冲量/速度变化、取消不扣能、临界帧 | input_feedback、launch_rewards、ui_integration |
| 真实撞击与生命 | 有效速度伤害、实体阻挡、同目标/链去重、死亡优先与共享无敌 | smoke、damage_contacts、crowd、run |
| 零伙伴、外包、跟随、基础传能 | 实际增员、受撞出击、归队距离减少、撞墙反弹、重开归零 | smoke、build、feature_acceptance、run |
| 冲刺！冲刺！ | 选择真实卡后同输入发射，实际水平速度超过1180 | feature_acceptance、launch_rewards |
| 逍遥游 | 相同初速与1.5秒模拟后剩余速度72.0027→75.3036；摩擦材质隔离 | feature_acceptance、launch_rewards |
| 快速上弦 | 选择后1.94秒不能发、1.96秒可发；满级1.2秒上限 | feature_acceptance、build |
| 双发 | 实际连续发两次，第三次拒绝；逐格恢复、暂停不刷能 | feature_acceptance、launch_rewards |
| ！？肥肥？！ | 主球命中HP按等级减少，低速无伤 | reward_effects |
| 补刀 | 0.12秒后追加真实1HP伤害，复位/死目标/递归限制 | reward_effects |
| 保龄球 | 存活敌人获得0.6秒攻击，另外两敌受伤，第三敌及传代拒绝 | build |
| 炸鱼 | 伙伴首击半径80内额外1HP、范围外不伤、每链一次 | build、reward_effects |
| 接力 | 实际激活接收伙伴，额外冲量≤262.5，每球每链一次、保留三代上限 | build、smoke |
| 小小的也很可爱 | 真实脉冲/首领波在原外圈不伤；恢复基准会伤，新敌正确应用 | reward_effects、feature_acceptance |
| 退！退！退！ | 4秒前不触发、到时敌人速度改变，生命不变 | reward_effects |
| 饱餐、运筹、强身 | 真实卡选择后回血2、生成四卡、上限加1并回1 | feature_acceptance、build |
| 第一图翻板与偏心轴 | 实际球两向三速撞击、轴心误差、限位和停转 | paddle_response、map_mechanisms |
| 第二图十字/移动板/四边刺 | 实体形状、真实推球、玩家接触扣血、伙伴不远程扣血 | maps、map_mechanisms、navigation |
| 第三图圆弧/移动刺/传送 | 实体运动、实际进门、保速保链、出口堵塞及同帧并发拒绝 | maps、portals、navigation |
| 首领图与战斗 | 核心/模块实际受伤与阶段、震波缺口、首领穿过实体通道 | boss、map_flow、maps |
| 三类普通敌人 | 实际攻击及预警、脱离范围取消、受击打断、生命显示 | enemies、enemy_readability、difficulty |
| 成长经济 | 击杀唯一奖励、队列、多选一次、满级/依赖/满血候选过滤 | kill_rewards、kill_run、build、feature_acceptance |
| 商店 | 金币扣费、回血/成长、余额不足、重复购买及旧按钮拒绝 | shop_events、stage_flow |
| 补给事件 | 免费成长/回血/跳过、倒计时推进、旧卡/旧事件拒绝 | stage_flow、map_flow |
| 白饭 | 真实拾取、冷却返还、下一发首次有效命中加伤、旧链不偷用 | rice、run、input_feedback |
| 可选分裂 | 生成低阶子体、预警、安全放置、家族不重复计奖 | splitting |
| 菜单/胜负/重开/回菜单 | 正式入口、四图流转、胜负状态、清理节点与多次重开 | ui_integration、map_flow、run |
| 设置/声音/反馈 | 开关接线、独立音量和静音、声音实例上限、真实事件显示 | audio、hud、feedback_integration、actor_views、ui_integration |
| 开发工具 | 八夹具、参数修改/恢复、运行快照与评估指标 | gameplay_lab、live_tuning、full_tuning、balance_metrics |
| 普通导出 | 读取真实EXE内嵌包，检查四图内部节点/形状/入口、排除调参入口 | tools/package_probe.gd |

新增feature_acceptance对15普通卡和兜底卡逐一验证合法出牌、实际Button可用和正式选择接线，共98项。它用引擎内输入/信号，并非真人逐张抽卡。战斗Buff另用独立效果夹具，不能只以等级变化作为通过依据。

## 本地执行与审查

设备LAPTOP-8GS4N5SG，Windows10.0.26200，Ziran。Godot4.7.1.stable.official.a13da4feb，Compatibility。所有命令在正式仓库执行，路径通过本机核验。

- 基线：`tools/verify.ps1 -GodotExe <本机固定版本>`36套通过，保存`.local/feature_review/full-baseline.*`。
- 新测试：`--headless --fixed-fps 120 --script tests/roguelite_paddle_response.gd`与`tests/roguelite_feature_acceptance.gd`。首轮成长夹具退出出现2–3个音频ObjectDB警告；追踪发现Game每帧按正式静音控件同步混音，直接设置muted会被覆盖，现改为通过正式控件静音。来源与实包新测试均已复测，无错误/警告。
- 当前旧包原生Windows操作：真实点击开始、按R失败重开、拖拽发射后主球位移/金币增加、Esc打开暂停设置已观察；此前旧任务的窗口激活限制在本轮没有复现。新包另已真实点击开始、拖拽发射（主球位移并获得金币）、Esc暂停、点击返回主菜单。不是自然整局通关。
- 独立审查首轮未发现确定的玩法阻塞缺陷；建议补物理效果、测试目录自建、教程职责、CI/verify/目录接线及历史计数已纳入本轮收尾。

- 完整38套行为断言通过、目录443项通过；原旧smoke夹具在引擎退出时报2个音频实例释放警告，补与既有反馈夹具相同的0.5秒后台混音清理等待后，针对该夹具verbose复测通过且无错误/警告。旧带警告日志保留，不冒充零警告完整运行。
- 新普通包实际内嵌PCK：feature_acceptance98项、paddle_response71项均零失败且日志无错误/警告。源码与实包挡板关键数值一致；虚拟res目录诊断创建错误已改为绝对磁盘路径，旧失败日志保留。
- 当前普通包仍位于builds/overnight-final与同名ZIP；构建ID为function-verified，EXE SHA256为FBFB6893562CF87062BA6A56810942CE165BF578921B120DFD1B4F9C24620779，输入指纹E913288F6FFECA5273C2CF121D8C03E752B19F9E13769FF72583E5B3A87686A6。ZIP CRC及内嵌EXE哈希通过。旧包已移入回收站，builds仍只保留最终目录/游戏ZIP/汇总证据ZIP三项。

独立审查最终结论：建议均已处理，未发现阻塞项；可commit/push并创建PR，合并仍须等待远端smoke检查通过。审查只读覆盖代码、测试、教程、目录与授权，未亲自重跑全部套件，不冒充真人通关。

## 授权与保留事项

生图仍为用户不认可的已接入候选，后续对话修改；没有新生成素材。用户仍未完成本轮玩法/美术/音质验收。Git合并是本轮明确授权的工程动作，不能写为用户审美认可。

原有project.godot编辑器规范化修改保留在工作区，SHA256为0D979E682E04F6E1066F2CA20B0FBBA358FC74D0A3C1B7F7820998E5C1EBE799，不纳入本轮提交。不提交.local、builds、导出暂存或凭据。整夜定时任务保持停用。功能边界、工具日志和旧证据中的“当时状态”不替代本记录的最新结论。
