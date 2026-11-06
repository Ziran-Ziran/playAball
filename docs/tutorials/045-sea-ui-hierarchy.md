# 045 深海界面的信息层级

卡牌先回答“这次会增加什么”：收益24px为第一层，名称20px保留辨识度，规则13px解释边界，趣味句最弱。标题与收益保持真实文本。规则保留完整，不通过删改玩法缩短卡片。

共享sea_ui_theme.gd为商店、结算及暂停菜单提供实色深绿面板、温暖主操作、独立hover/pressed/disabled/focus状态。购买是否可用只读取offer.enabled，不自行计算金币或治疗。rest_panel响应式居中，选择第一个可用按钮聚焦；RunHUD结算聚焦重新开局，返回菜单作为次级操作。

参考公开设计来源的原则，不复制游戏素材：
- [Xbox XAG114](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/114)：明确操作上下文。
- [Google Playables设计](https://developers.google.com/youtube/gaming/playables/certification/best_practices_design)：跨分辨率清晰及主次按钮。
- [Apple游戏控制](https://developer.apple.com/design/human-interface-guidelines/game-controls)：明确按压反馈。

检查器在UpgradeCard调title_font_size、detail_font_size与插画区域。收益布局在_layout的Preview段；修改后同时检查三卡、四卡和全部16种规则。按钮主题由共享脚本生成；不要把玩法交易逻辑搬进主题。

专项验证：roguelite_card_typography.gd真实Compatibility484项通过；roguelite_sea_ui.gd两分辨率商店可买、金币不足、已购、跳过及胜负结算焦点/边界12项通过。开发中主按钮尺寸令小窗口商店越界，测试出现1项失败；响应式居中修复后通过。截图保存.local/art_pass_20261105/card。夹具状态文案不是经济系统的实际报价；正式交易仍由director校验revision和金额。

早期样例夹具不覆盖正式Game的皮肤覆盖与输入层级，不能把样例截图写成完整游戏人工验收。下文记录后续正式场景、真实经济状态与鼠标事件补验，以及实际发现的遗漏。

正式Run集成补验：roguelite_sea_ui_integration.gd在两分辨率打开现有暂停菜单并触发现有Resume pressed信号，确认恢复战斗；使用director.refresh_rest生成真实可买、余额不足、已购和补给状态，核对钱包显示与enabled，共20项通过，截图actual_*和pause_*。测试只在夹具设置状态，不修改玩法实现。暂停菜单显示时居中并聚焦继续。信号触发验证接线，不等同鼠标坐标点击人工体验。

进一步真实奖励截图actual_cards_*覆盖两种窗口三/四卡；发现最窄卡片长收益出现第三行与规则重叠，修正_fit按实际行数乘字高计算，窄卡允许收益缩至14px；复拍确认bowling、relay完整收益与规则分离。正式集成测试扩展到24项通过。

独立审查阻塞修复：正式Game的217.5×357附近四卡高度比先前Run夹具小，echo/heal/pulse/relay/vigor规则与趣味句相撞。现将插画高度由30.2%调为26%，上移等级与收益，完整规则获得21%卡高。新增roguelite_sea_ui_formal_game.gd以正式Game全16卡检查实际行数×字体高度及规则和趣味句的严格间隔，0失败；证据formal_game.log和formal_game_0/4/8/12.png。HUD决策面板提升同Overlay绘制顺序并添加同步遮罩，阻止Game后来添加的生命皮肤覆盖标题。主按钮补全hover/pressed/disabled底色与文字对比。

首次正式商店鼠标验收补充：发现父Game在_ready覆盖的大纹理面板产生1117px最小高，首次商店中心落到屏外。rest_panel.show_rest现移除panel样式覆盖并恢复自身共享主题。新增roguelite_sea_ui_mouse.gd：正式Game初次展示后两帧检查panel与购买按钮完整在视口内，真实鼠标继续/购买/禁用重复点击/结算再开局均通过，panel为(192,98,640,380)，金币12→8、生命3→5。formal_game及mouse测试均加30秒有界超时和headless截图分支，正式Game全16卡headless复测0失败。

暂停遮挡复查：正式Game动态生命皮肤与暂停菜单跨CanvasLayer，现HUD已有visibility_changed在暂停时隐藏整个Overlay，关闭时恢复，避免标题被遮。formal_game及mouse新增暂停标题视口包含、HUD遮挡层隔离与恢复断言；headless正式Game与原生鼠标专项均0失败。根pause_probe原生重拍visual_r6_pause.png，标题完整可见。
