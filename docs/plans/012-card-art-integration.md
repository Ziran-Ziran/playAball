# 012：卡面与文字返修并实装正式选卡

日期：2026-11-04。用户明确要求本对话持续做到卡片贴图、文字实装；Live2D移交另一个对话，首轮只读讲解。沿用无限生成预算与既有40图片输出，不重置首轮配额。不创建新对话、不commit/push/PR/merge、不建clone/worktree或自动化。

## 目标与验收

真实16种成长/28张基础图，每张按[描述R3](../art/card_briefs_r3.md)先设计再生成；统一人物和笔触，动作、机位、受力阶段有区别。正式F5游戏中的击杀奖励、商店成长、补给成长共用实装后的HUD，正确显示“当前→下一等级”的贴图和真实收益，饱餐/强身共用重复项插画。用户要求实装是接线授权，不推定所有候选已经获得审美认可。

标题来自原.tres，不改ID、等级、数值或规则。单独的显示文案包含面向玩家的规则说明和趣味短句；收益继续由DemoBuild/实际生命快照计算。三选一、四选一、单张兜底、暂停/队列/重复点击校验、重开/结算流程保持。

## 文件与唯一写入者

本对话Codex作为卡片与接线负责人，依据本次用户实装授权接管整个scripts/roguelite/run_hud.gd与scenes/roguelite/run_hud.tscn，不按局部分割给其他Agent；本轮无其他实现Agent。独立组件为scenes/roguelite/presentation/upgrade_card.tscn、scripts/roguelite/presentation/upgrade_card.gd、card_art_library.gd；数据为card_art_catalog.json和upgrade_card_copy.json；贴图为assets/cards。B的run_director、actor、run_build、物理与规则.tres只读。

Live2D对话先不执行，后续不得编辑上述卡片文件。共享STATUS/用途目录按语义追加，不覆盖对方的有效记录。其提示词见[交接文档](../onboarding/live2d_handoff_prompt.md)。

## 实施步骤

- [x] 记录既有运行/规则/素材哈希与HUD备份；新增真实HUD插画映射测试，先确认旧HUD因缺少贴图而失败。
- [x] 复用三张历史一级母版与R3三张新候选，其余22张按独立描述生成；每个请求保存完整prompt、参考、状态、结果/哈希与语义/审美分项，结果未明不重发。原28张与失败稿保留在.local。
- [x] 建立只读贴图/文案库与可编辑卡片场景。HUD只配置表现并保留原upgrade_selected(id, offer_id)信号，不做规则结算。实装28图与16套文字。
- [x] 跑新增28项真实等级/贴图/生命文案检查、既有HUD/UI与正式选卡→应用→恢复战斗回归；真实Compatibility窗口检查三/四卡、长标题和两种窗口，另核验商店/补给/单张兜底。修复与复测只针对实际问题。
- [x] 更新开发者教程、用途、FILE_MAP、STATUS和制作清单，运行目录--write/--check与git diff --check。记录技术检查、合成输入、真人试玩和用户审美分别是什么；保留本地未提交，不发起Git阶段最终Review。

## 验证入口

Godot路径以本机调查为准；当前是C:\Users\Ziran\Desktop\Godot_v4.7.1-stable_win64.exe。新增测试命令为`--headless --path . --script tests/roguelite_card_art.gd`。正式回归使用现有tests/roguelite_hud.gd、ui_integration.gd、roguelite_feature_acceptance.gd、roguelite_kill_run.gd、roguelite_shop_events.gd、roguelite_stage_flow.gd；更改正式HUD后按tools/verify.ps1完成适用全套检查。实际渲染/输入证据保存在.local/art_audio_r2/card_integration，不上传导出或截图缓存。

实施结果：39行为套件、144项卡面、21个实际窗口布局与5个合成鼠标流程通过；最新v4包的实际EXE资源探针通过。150个既有运行文件仅HUD两文件改变，其他148哈希不变。Release外部脚本/原生窗口输入未完成不计通过，用户审美仍待验收。source fingerprint曾漏JSON，已按真实两暂存输入的签名差异修正与核验。详细证据见STATUS和制作清单，不触发Git阶段。
