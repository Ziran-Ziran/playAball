# 044 卡片动态艺术字

卡片标题使用随项目分发的站酷快乐体，保留真实中文字符串，等级和收益继续由玩法传入。字体使用 SIL OFL 1.1，原许可与来源放在 assets/fonts/zcool_kuaile。正文仍使用原来的清晰字体，不把规则和数值烘焙进插画。

## 文件和节点

upgrade_card.tscn 的 Content/Heading 使用 FontFile、米白字色、2 像素深绿描边及短阴影。upgrade_card.gd 的 configure 接收升级资源，把原始 title 写入 Heading；_layout 分配标题区域，_fit 根据高度缩小字号。upgrade_card_copy.json 只补充规则和趣味句，不执行升级。

## 调参与扩展

在卡片根节点检查器修改 title_font_size（默认24），再用真实三卡、四卡奖励面板检查。Heading 的主题覆盖可调整颜色、描边、阴影；描边保持克制，避免遮住笔画。新标题应同时检查最窄卡片宽度，不通过修改原规则换取排版空间。

## 验证和常见错误

使用 Godot 4.7.1 --headless --path . --script tests/roguelite_card_art.gd 验证正式HUD的28张等级插画与动态标题接线。本次144项通过。无控制台的Windows可用 --log-file 保存日志，并等待进程退出。

标题缺字时先确认字体已导入、FontFile路径为res://。标题溢出应检查卡宽与换行高度；不要把标题改成图片。字体文件必须连同OFL和来源分发。两种真实分辨率的固定夹具截图已检查，见下文；这仍不代表完整游戏交互或用户审美认可。

## 专项验收补充

新增 tests/roguelite_card_typography.gd，实例化真实卡片场景，在1280×720、1024×576分别排列三卡和四卡。使用九字长标题，检查标题字形存在、真实字体来源、各标签可见行数、控件边界和精确数字文本。独立夹具关闭项目内容缩放，确保测试的窗口坐标就是目标分辨率。

负对照：传入 -- --negative-font，移除标题字体覆盖以模拟旧默认字体，306项检查中82项失败、退出1；正常配置306项通过、退出0。Compatibility真实渲染四张截图在 .local/art_pass_20261105/card/cards_*.png；Windows进程使用Start-Process -Wait等待，日志typography.log记录OpenGL Compatibility设备。最窄四卡截图标题和正文均在边框内，未观察到遮挡。测试数字为夹具刻意输入的精确字符串，用于排版而非模拟升级收益；真实收益另由144项正式卡片测试覆盖。

未覆盖：所有未来无限长度标题、不同GPU驱动、鼠标交互动效的人工体验。此夹具不代替整局游戏试玩。

全量复查：全部16种真实标题和完整规则均加入1024×576四卡槽（229.5×492）检查，特别包含relay、explosion、bowling；保留完整规则，无删节，验证可见行、上下边界及规则和趣味句间隔。扩展后484项通过（all16.log及Compatibility的typography.log），替代前述306项正向结果。heavy规则明确限定‘主球有效撞击伤害’，与玩法仅DemoPlayer获得加成一致；HUD收益预览措辞由集成负责人核对。
