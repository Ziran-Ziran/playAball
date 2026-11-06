# 用户复验后的连续动画、卡牌内容流与菜单动作

2026-11-06，LAPTOP-8GS4N5SG / Windows 10.0.26200 / Ziran，Godot4.7.1.stable.official.a13da4feb标准版Compatibility，基线cfe31a2。范围见[计划017](../plans/017-smooth-animation-card-flow-menu-actions.md)。本记录是本地开发验收，不是Git提交阶段最终Review；没有commit/push/PR/merge。

## 根因与实际改动

- 旧肥鱼idle按sin阈值硬切三张构图/裁切不同的图。现固定认可原图、每渲染帧连续形变，事件只给解析阻尼弹簧速度冲量；接触/痛脸用已有内置生成表情并校正长宽和比例。表情仍为短切，不冒称逐像素面部补间。本机正式Game短测359帧、渲染120FPS、帧时中位数/p95为8.33ms，只代表本机第一波3秒采样。
- 旧卡框内置固定分隔，正文按卡高百分比摆放、底句越过内框。现使用可编辑实色边框，按真实宽度/最小字高顺排类别、名称、插画、级别、收益、完整规则与底句，20px安全边距，去除旧框纹理引用。没有删规则或更改成长收益。
- 旧Live2D多数只改变表情、2.1秒内忽略新点击，几乎没有头身动作。现固定头顶点头、屏幕左脸眨眼歪头、右脸鼓脸摇头、上半身鞠躬、三连点惊讶后仰、按住头发拖抚轻摆；0.22秒后允许打断，菜单显示绑定/反馈/减少动态说明。沿用原模型输入与物理，不移动整张立绘或引入新模型/SDK。

## 验证和独立审查

- 动画：旧阈值独立夹具748项失败，新30/60/120/144Hz回归通过；60Hz四事件相邻外框最大1.24–1.77像素。真实Game67项涵盖实际扣血/无敌、碰撞、去重击杀、物理不变、暂停与清理。card_typography未参与动画实现，自行运行headless/原生专项并目视sequence及原生关键帧，未发现阻塞；指出包围框测试不测脸中心像素、launch/kill没有对应原生截图，作为证据边界保留。
- 卡牌：290×480全16卡含hover/流光，正式Game两窗口三/四卡与16种规则，图鉴截图分别检查。mascot_references未参与卡牌实现，实跑16卡内容流与正式Game24项，目视6张截图；tactical_aim另实跑16卡内容流并检查用户近似尺寸与长规则，未见收益穿线、规则左裁、底句贴边。
- 菜单：原生GUI动作最终166项通过，较早的小窗版本162项通过（新增4项网格断言前），旧菜单28/表情21项通过。原桥接ParamAngle Resource值不反映当前物理输出，不能用其读0伪造成功/失败；实际get_meshes同一网格顶点位移证明头16.33/16.22/16.51、躯干31.77逻辑像素，角色根节点不动。card_typography独立核对代码、六组截图与日志，未见阻塞，没有冒称再次独立复跑全部166。
- root完整运行tools/verify.ps1，`.local/r7/verify_final.log`退出0、51套行为完成。首轮暴露旧ui_integration硬性要求StyleBoxTexture，按本轮已批准实色框更新为StyleBoxFlat后专项通过再跑全量；未放松内容安全区/规则完整断言。自动捕获工具另加headless跳过和20秒超时，未混入行为套数。

全量导入曾扫描新旧builds中重复旁置模型，出现6条UID重复警告；已在生成目录放.gdignore，并让共享导出器今后创建该隔离文件。之后实际导入退出0、stderr空；导出脚本PowerShell语法解析0错误。编辑器扫描改写的6张生成包.import已恢复原字节，111份旁置文件与原清单、最终ZIP逐项SHA256一致。没有把导入警告写成“全日志零警告”。

## 本机新体验包与实际EXE边界

`builds/playaball-smooth-live2d-20261106-184803/PlayABall.exe`及同名ZIP包含本轮所有运行改动和旁置Live2D，旧包保留。源码只在独立暂存中替换三项角色路径为EXE相对目录；674份源文件在构建过程中保持不变。实际内嵌包探针通过、ZIP完整性通过，111份旁置文件指纹匹配；真实Release进程加载包旁libgd_cubism.windows.release.x86_64.dll。

root尝试computer-use验证实际EXE，但系统两次返回`failed to activate captured window`，画面被另一个窗口遮住，停止继续注入输入。**没有完成这份EXE内的鼠标逐项验收**；源码Native GUI的166项和实际包资源探针是分开的证据，不能合并冒称Release鼠标验证全部通过。此包仅供当前用户本机体验，完整解压并保留旁置目录；既有Native完整L0内存与发行授权边界没有在本轮解决。

教程：[049卡片](../tutorials/049-card-content-flow.md)、[050动画](../tutorials/050-smooth-hero-animation.md)、[051菜单](../tutorials/051-menu-visible-actions.md)。证据集中在`.local/r7`、`.local/art_pass_20261105/card`、`.local/menu_actions_20261106`。技术检查不能代替用户对丝滑程度、动作自然度及排版的审美判断或真人完整通关。
