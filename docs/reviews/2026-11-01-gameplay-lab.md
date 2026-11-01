# 2026-11-01 表现接口与玩法实验室最终 Review

## 范围与基线

- 共同基线：`origin/main=935b9b87abf39f719172b3e618ea3ecf672d9fc9`。
- 本地分支：`feat/gameplay-lab`，独立 worktree为 `D:\playAball\B\playAball`。
- 范围：S1敌人/生命最小表现接口、正式 HUD 请求校验、真实判定的拒伤诊断事件、B线八类玩法实验室、测试/CI、教程、用途、自动目录和STATUS。
- 排除：`project.godot`编辑器规范化差异、`.local/`、`.godot/`、构建产物、个人预设和凭据。当前 B checkout 的`project.godot`也出现同类规范化差异，必须继续排除。

## 实现摘要

- `DemoEnemy`发布只读表现快照和真实事件，默认绘制迁至`DemoEnemyView`；替换视图不改质量、碰撞形状和物理规则。
- 正式生命面板拆至`DemoHealthView`；`RunHUD`只委托绑定，并保留旧只读`health_bar`路径兼容。结算重开请求经`RunDirector.request_restart()`校验。
- `DemoCombat.contact_outcome`与`DemoHealth.damage_rejected`从实际判定分支报告接受或拒伤原因；实验室只消费，不重复结算。
- `gameplay_lab.tscn`独立 F6 入口提供单敌、怪群、墙角、伙伴、范围、炮台、分裂、首领八类夹具。范围与炮台支持1～8个等距目标，单敌/分裂族根/首领固定一个；击破分裂仅用于夹具7。
- 固定发射复用`DemoLaunch.launch_with_drag()`和正式冲量规则；参数、读数、160条有界日志、本地预设和复现记录均只影响实验室。
- 正式`run.tscn`不引用实验室脚本或快捷键。实验室生命归零不进入正式胜负，需重置；正式run仍按原胜负流程。

## 验证证据

- Godot：`4.7.1.stable.official.a13da4feb`，Windows AMD64，Compatibility。
- `tools/verify.ps1`：导入、`PROJECT MAP CHECK PASSED`和25套行为共1072项通过，退出码0；最终代码日志`.local/final-review-verify.log`。
- `roguelite_presentation_interface.gd`：15项通过。
- `roguelite_gameplay_lab.gd`：52项通过，直接覆盖8敌人范围夹具、炮台预警/发射、分裂整族奖励、预设和日志边界。
- `git diff --check`、用途JSON解析和本地Markdown链接检查通过；加入本Review记录后目录文件数为229，已重新生成并检查通过。
- 图形模式曾启动正式`run.tscn`与`gameplay_lab.tscn`各240帧，OpenGL Compatibility/NVIDIA RTX4050，退出码0。

## 独立审查与问题处理

- 独立代码审查先发现炮台测试继承了`ai_enabled=false`，会使范围测试失败；已在测试中显式开启AI，并把8敌人生成与单敌人范围边界拆开。
- 独立文档审查发现README、PROJECT和计划008仍称表现接口/实验室未实现；已按当前代码修正。
- 后续文档复核对教程020、STATUS历史状态和当前`project.godot`差异作同步；由于修改了审查文件，另起只读审查者复核最终快照。
- 最终代码复核未发现正式物理、伤害、奖励、输入、重开或正式run隔离的阻塞；仅指出炮台测试重复赋值，该建议已清理并复测通过。
- 最终发布前只读审查在补入本记录、更新用途/FILE_MAP和STATUS后再次通过：229文件目录、15/52定向测试、25套1072项完整回归、链接/JSON/差异检查均成功，无剩余必须修复或建议修改项。

## 结论

本批最终Review通过。`project.godot`编辑器规范化差异仍不属于提交范围；其余列出的未测项不阻塞继续开发，但影响体验验收结论。进入commit/push/PR/merge前仍需用户按本轮明确授权。

## 未测与授权

- 未评价新增实验室 UI 的视觉品质，未完成真人手感、音质、完整通关、两台电脑性能和跨机启动验收。
- 远端CI尚未运行，因为改动未push。
- 用户只要求进入最终Review；本轮没有明确授权commit、push、创建PR或merge。收尾复核后仍须由用户决定Git动作。


## owner复核后的整改（2026-11-01，本地验证完成）

用户已明确要求修复后merge及导出策划EXE，本批必要commit/push/PR更新和合并均获授权，旧的未授权段落是历史记录。负责人为本次主Agent，最终独立审查由未参与修复的core_review执行。

目标与验收：构筑在实验室产生与正式规则一致的效果，覆盖参数需显式启用；非法阵型不生成、不破坏旧实验；分裂各代继承AI开关；事件只报告已提交攻击；原正式入口和A未提交修改保留。计划为先补红灯回归→最小修复→补教程/目录/策划单→完整验证→独立复核→更新原PR/CI/merge→从合并后的干净源码导出EXE。

涉及gameplay_lab.gd、lab_panel.gd、enemy.gd、两套接口/实验室测试、教程019/021/022、策划说明及反馈单、export_windows.ps1、用途/目录/STATUS和本记录。

红灯证据：原实现实验室62项9失败，接口攻击事件2项失败（另一次生命断言因测试自身伤害未复位，已修正夹具）；日志`.local/fixes-red.*`、`.local/interface-red.*`。新增非法预设阵型加载也在旧返回值下复现失败，日志`.local/expanded-red.*`。首个大阵型正例距离300与右挡板相交，校验正确拒绝；已改距离100，不改墙形或跳过校验。

修复说明：完整复用DemoBuild及DemoAssistEffects，开启覆盖时仅替换冷却/伙伴三项；schema1迁移保留旧旋钮条件。阵型先检查边界、重叠和墙/挡板，再清理旧实验；首领96像素保守生成边距不改物理。DemoEnemy在ready后统一缩圈与AI，涵盖分裂后代。攻击释放事件在真实提交后发出；生命面板保留类型/节点路径，文档不再承诺仅两方法即可任意替换。

实际完整运行`tools/verify.ps1`退出0：Godot4.7.1.stable.official.a13da4feb、230文件目录、25套1092项通过；日志`.local/fixes-full-verify.log`，无SCRIPT ERROR/ERROR/WARNING。独立core_review对全部修复只读审查并复跑实验室70/接口17项，退出0、stderr空。独立指出的非法预设加载返回值已修复，教程022类型校验措辞已收窄为实际实现。链接失效0、JSON解析/导出脚本语法/git diff --check通过。最终文档快照已获core_review独立复核通过，无剩余必须修复或建议项。远端CI与合并在push后确认；EXE在合并后的干净提交导出，结果以包内build_info及本次最终交付为准，不预先声明成功。未测项为真人完整通关、跨机性能、音质及平衡手感。
