# 055：蓝白方向的商店与结算精修

## 目标与用户确认

2026-11-09，用户选择“蓝白浅色，继续精修”。保留054的设置与暂停方向，本轮优先处理此前自评分较低的商店/补给和胜负结算。人物仍为DS鲸鱼娘：蓝发蓝瞳、女仆头饰/服装、鳍耳与鲸尾，不使用普通鱼动物。

这是配色方向确认后的局部精修，不将用户选择扩大为全页面、插画或动效的审美认可。负责人为当前Agent，基线612bebb；保留已有白饭和地图本地修改。该轮开发时尚未授权提交或上传；2026-11-10用户要求“push一版”，已授权本批commit与push，最终核验见[Review记录](../reviews/2026-11-10-rice-map-ds-ui.md)。

## 文件与节点

- `scenes/roguelite/rest_panel.tscn`：Content下的Heading/Detail与Body；Body内Character显示已有内置生图人物，Actions展示真实可用操作。Actions路径改为Content/Body/Actions，外部仍使用rest_panel.actions引用。
- `scripts/roguelite/rest_panel.gd`：保留offer原文、enabled、quote和原请求信号。人物/操作双栏宽度上限880；购买操作使用浅色行，继续/跳过使用实色主按钮。标题18px、辅助说明14px，不把价格写进图片。
- `scenes/ui/result_body.tscn`、`scripts/ui/result_body.gd`：可编辑独立结算组件。左侧是胜利/重试人物，右侧是两个真实记录数值与说明，完全不判断胜负或发放奖励。
- `scenes/roguelite/run_hud.tscn`：新增ResultBody与ResultActions；Restart/Home改为横向同行。脚本仍暴露restart_button/home_button，玩法只使用原信号。
- `scripts/roguelite/run_hud.gd`：show_result传入won/kills/longest；按真实内容测量面板高度并居中，窗口变化会重排。show_choices/close隐藏结果组件，避免污染成长选择。
- `assets/ui/ds_console/result_victory.png`、`result_retry.png`：内置生图新增透明人物，提示与指纹见同目录result_generation.json。沿用原蓝白底图和按钮，不重画整页截图。

## 输入 → 展示 → 请求

RunDirector提供offer文字、价格状态、enabled与revision → RestPanel生成按钮。按钮.text和tooltip保留原文；鼠标穿透的子标签分别显示标题和小字解释。辅助说明不参与治疗/扣币/成长计算。按下后仍发送原id/revision，由RunDirector判断购买资格。

继续和跳过可明确识别，但键盘仍从首个可用操作开始，不强制玩家消费。已购、满血或余额不足仍以原状态禁用，不能因换皮绕过校验。

RunDirector.finish传入真实胜负和记录 → ResultBody显示整数 → 换对应DS插画和短句。记录不做先显示假数字的动画。重开与返回沿用原请求。新增人物是静态透明插画，显现使用既有短淡入；减少动态依然立即展示。

## 怎样调参数

商店在rest_panel的_fit_panel调整880宽度上限，场景Body的h_separation调整人物与操作间距，Character控制人物区域。价格和收益改玩法数据，不在UI解释中写固定价格。

结算人物区域在result_body.tscn，默认188×192，TextureRect按比例居中；统计字号38，标签16，说明15。ResultActions间距14，按钮仍保持54px最小高度。_layout_result_panel根据真实字号/宽度计算高度，避免固定508导致大块底部留白；fit_width先明确说明行宽，再刷新最小尺寸。

修改字体、价格文本或人物比例后，检查1280×720、1024×576，胜利/重试/零记录和四卡。不要将人物根节点或物理节点一起缩放。

## 验证与再评分

`tests/ocean_ui.gd`增加：首次未选过卡直接结算时使用浅色主题、零记录、胜负对应人物、真实统计、导航不压住人物；全卡池16种在窄四卡布局下检查Preview/Detail/Flavor边界。原实际鼠标测试继续覆盖恢复、扣款、禁止复购、重开。同帧结果→选卡时忽略已过期的结算延迟布局；四卡按整像素算宽，避免容器逐张向上取整后反撑宽。最新专项108项通过。

使用当前机器实际Godot4.7.1执行tools/verify.ps1；完整结果见STATUS，截图在忽略目录.local/ds_ui_iteration_3。截图由脚本摆设真实渲染，不能冒充自然完整通关。已覆盖商店正常/贫穷/已购/补给、两种结算和两种窗口。

| 项目 | 上轮自评 | 本轮自评 | 依据 |
| --- | --- | --- | --- |
| 商店/补给 | 6.3 | 7.0 | 人物与操作分栏、主次操作和小字层次；仍是简洁列表。 |
| 胜利结算 | 6.2 | 7.1 | 庆祝人物、记录卡和同行导航，收紧无效空白。 |
| 重试结算 | 6.2 | 7.0 | 表情与文案对应重试情境，保留实际记录。 |
| 设置/暂停 | 7.0/6.8 | 7.0/6.8 | 本轮保留，配色确认不增加分数。 |
| 成长卡 | 6.8 | 6.8 | 复查窄四卡，未因增加测试给美术加分。 |

分数仍为主观开发自评，用户尚未认可本轮具体页面。统计卡还较朴素，窄四卡文字仍密，保留为后续可细化项。测试通过与画面漂亮分别判断。
