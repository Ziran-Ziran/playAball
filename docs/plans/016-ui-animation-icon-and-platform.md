# 016：UI层级、球体动画、温和表情与独立图标

用户目标：保留已认可的肥鱼球与病毒球，改善商店/结算/暂停UI与卡牌信息层级；补充待机、接触、受伤、击杀动画；替换菜单恐怖表情并增加互动；独立游戏图标；优先评估Windows与安卓手机。

基线cfe31a2，分支fix/map-blueprints-20261105，保留原有未提交内容。2026-11-06本机LAPTOP-8GS4N5SG，Windows 10.0.26200，Ziran，Godot4.7.1标准版Compatibility。只做本地开发和验证，不包含commit/push/PR/发布授权。

| 工作 | 负责人及整文件边界 | 验收 |
| --- | --- | --- |
| 卡片与通用游戏UI | card_typography：upgrade_card、run_hud、rest_panel、sea_ui_theme及专项测试 | 1280×720和1024×576、三/四卡、名称/收益/规则/趣味句层级，真实商店购买状态、暂停和胜负重开 |
| 球体动画 | mascot_references：presentation球体组件、ball_animation_r5素材及专项测试 | 内置生图产出透明姿势图，长圆/圆/扁圆待机、接触/受伤/死亡区别；真实事件，冻结与清理，物理形状不变 |
| 菜单表情 | tactical_aim：menu_character及专项测试 | 移除黑脸/阴沉眼参数；至少四组温和互动，失焦/设置/减少动态安全恢复，原生Live2D实图 |
| 独立图标与平台评估 | root：project/export、app_icon、build_icon、平台教程 | PNG/7尺寸ICO，实际导出EXE提取图标；Windows与安卓差异、工具和未测边界如实记录 |
| 视觉事件接线、目录和集成 | root：player_health、run_director、用途/FILE_MAP/STATUS/验证入口 | 实际扣血才发damage；去重击杀发kill；完整回归与独立交叉验收 |

表现只读玩法事件，不能更改伤害/经济/碰撞/生成。菜单与美术实现者交叉只读验收对方模块；独立报告与自查分开标记。此轮不是Git最终Review，若进入提交阶段需按REVIEW重新明确提交范围。

平台边界：本轮完成Windows图标接入及适配评估；安卓尚未开发为可交付版本，不能把缺少JDK/SDK、触屏与Live2D原生库支持的现状称为“只换导出格式”。后续按输入→布局/安全区域→可选Live2D回退→分档性能→真机APK验证实施。
