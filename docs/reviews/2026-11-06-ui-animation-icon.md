# UI、生成动画、菜单表情与图标：本地技术验收

本记录是开发中的局部验收，不表示进入Git最终Review或获得提交/上传授权。2026-11-06，LAPTOP-8GS4N5SG / Windows 10.0.26200 / Ziran，Godot4.7.1.stable.official.a13da4feb标准版Compatibility，基线cfe31a2。原有未提交内容保留。

## 需求与分工

[计划016](../plans/016-ui-animation-icon-and-platform.md)覆盖用户六项需求。card_typography实现卡片与商店/暂停/结算；mascot_references使用内置imagegen生成四张独立透明四格图并接表现；tactical_aim实现安全菜单表情；root负责PNG/七尺寸ICO、实际导出、真实事件接线、平台评估及集成。没有更改伤害、经济、碰撞形状与敌人预算。

## 独立验收及发现的问题

- tactical_aim未参与新UI实现，独立以正式Game枚举全16卡，复现五卡规则/趣味句重叠、生命皮肤盖奖励标题；修后`sea_review_final.log`为零失败。又用真实鼠标事件复现首次商店高度1117、购买按钮在屏外，修复父Game纹理覆盖后面板为(192,98,640,380)。`sea_click_review_final.log`验证继续、购买生命3→5/金币12→8、禁用项不重复扣款、结算重开。原失败日志`sea_review.log`、`sea_click_review.log`保留。
- root额外检查真实暂停全图，发现生命皮肤挡住暂停标题；暂停时隐藏常驻Overlay、恢复时显示，重拍`.local/visual_r6_pause.png`，标题及全部控件入屏。专项增加标题可见/视口边界和Overlay隔离断言，不能只把按钮可点当成标题无遮挡。
- tactical_aim未参与动画实现，新增`roguelite_ball_animation.gd`，真实Game与生命/接触/奖励链路原生及headless各67项通过。发现图集无mipmap导致缩小锯齿，现1024导入上限、mipmap与Atlas防串采；实际16帧、痛脸/碰撞/碎帧截图完整。发现死亡浮光退化多边形渲染ERROR，极小尾端跳过后无ERROR/WARNING。最终日志`.local/ball_animation_review_final.log`及`_final_headless.log`。没有把“断言通过但渲染报错”的轮次计为通过。
- card_typography未参与菜单实现，独立核对五表情与安全中立图、驱动及测试：不读取旧危险reactions，无start_expression，key1/key6强制归零；未发现阻塞。实现者原生表情21项、正式菜单28项通过。独立者没有重跑原生，不冒称独立复跑全部。
- mascot_references未参与图标/根接线，独立确认实际EXE提取32px与检查图逐像素一致、ICO七尺寸正确；damaged只在实际hurt成功后发出、register_kill仅接受新ID时通知，原经济条件保留。教程048命令示例按反馈改为Start-Process等待。

## 集成与边界

完整执行`tools/verify.ps1 -GodotExe <本机核实的4.7.1路径>`，`.local/visual_r6_verify_final2.log`与`visual_r6_verify_clean.log`两轮均退出0、662文件目录及49套行为通过。后者文件名clean不代表日志零警告：mouse退出曾有4个ObjectDB警告；前者formal_game曾有2个。verbose均未复现对象，不能断言其类型。formal_game测试退出加两帧及0.1秒后专项无警告；mouse测试同样加两帧和0.2秒，`.local/sea_mouse_wait_final.out/.err`退出0且stderr空。没有屏蔽警告或改生产生命周期。最后测试退出等待的调整只复测受影响mouse套，没有冒称之后又跑一次全49套。

中途曾因formal_game无条件等待图形frame_post_draw令headless挂起，已改条件分支并加30秒超时，不以挂起轮次当通过。新增UID造成一次FILE_MAP过期，重新导入后生成已解决。最后暂停隔离实现与截图由tactical_aim独立只读复核，标题及全部控件入屏、Overlay恢复正常，未发现剩余阻塞。

Windows图标实际导出到`builds/visual-r6-icon-check-20261106/PlayABall.exe`，包探针通过，EXE提取图`.local/exported_icon_32.png`。这是动画尚在开发时的图标验证快照，**不是全部本轮修改的最终成品，也不含私有Live2D**；此前含Live2D的旧EXE没有被覆盖。

安卓优先级按用户确认为第二目标；本轮完成可行性与差距评估，未安装工具链、未做APK/真机或适配完成声明。触控/返回/后台、屏幕安全区、分档性能和Android arm64 Live2D二进制仍需实施。源码F5可体验本轮修改；真实鼠标事件与原生截图仍不等于真人自然完整通关或用户审美认可。无commit/push/PR/merge。
