# 048：独立图标与Windows/安卓适配边界

## 图标如何进入游戏

`assets/ui/app_icon/playaball.png`是内置生图产生的肥鱼图标；`project.godot`的`application/config/icon`使用它。`tools/build_icon.gd`只进行Lanczos缩放和ICO封装，生成16、24、32、48、64、128、256七种尺寸；`config/windows_native_icon`与Windows预设`application/icon`指向ICO。预设必须开启`application/modify_resources`，否则只改PNG不会改变导出EXE图标。`tools/export_windows.ps1`的输入指纹已包含ICO。

改图时保留方形构图与小尺寸清晰的眼睛/蓝发轮廓，在编辑器或命令行执行：

```powershell
# GodotExe请替换为当前机器实际核实的4.7.1标准版路径。
$iconStep = Start-Process -FilePath $GodotExe -ArgumentList '--headless --path . --script tools/build_icon.gd' -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput icon.out -RedirectStandardError icon.err
Get-Content icon.out,icon.err
if ($iconStep.ExitCode -ne 0) { throw '图标构建失败' }
./tools/export_windows.ps1 -GodotExe $GodotExe -BuildName your-new-build-name
```

Windows版Godot是GUI程序，脚本自动化应使用Start-Process -Wait及输出日志，不能把刚返回终端视为完成。本机图标测试包为`builds/visual-r6-icon-check-20261106/PlayABall.exe`；实际内嵌包探针通过，并用System.Drawing.Icon.ExtractAssociatedIcon从EXE提取32px，确认是肥鱼图标。这个包只用于导出图标检查，制作时其他动画仍在开发，**不是全部本轮修改的最终交付包**。它也不包含私有Live2D；不要替换此前含Live2D的体验包。旧快捷方式可能缓存图标，应先查看新EXE。

## Windows＋安卓能否共用工程

可以共用Godot 2D、GDScript、Compatibility与玩法资源；导出格式只是其中一步。Windows保留鼠标拖拽/右键取消/ESC暂停；安卓必须有明确的单指拖拽、取消按钮、暂停/系统返回、多点触摸归属，以及切后台时的手势取消。当前arena处理鼠标事件，不能因为触屏模拟鼠标就声称这些流程已经适配。

| 项目 | 当前事实 | 安卓实施与验收 |
| --- | --- | --- |
| 画面 | 1280×720基准，canvas_items拉伸；新UI已测1024×576与1280×720 | 横屏宽比例、刘海/挖孔安全区、48dp触控目标、手指遮挡；不能只缩小桌面按钮 |
| 物理 | 120Hz、RigidBody2D与原生碰撞 | 先保持规则一致测CPU帧时；必要优化碰撞查询/生成与对象复用。改变物理频率需单独做120/60Hz玩法回归，不能悄悄降低 |
| 美术 | 角色/姿势图与UI叠层，部分源图高分辨率 | 限制导入尺寸、内存与透明叠绘；低/中档控制粒子和尾迹上限，优先减表现而非敌人数量与难度 |
| 帧率 | 桌面技术测试，无安卓基准 | 中档目标60fps、低档允许稳定30fps需真机证实；记录拥挤Boss/多伙伴/连杀峰值、长时间温升和内存 |
| 菜单Live2D | 私有运行目录实际只有Windows x86_64 DLL | gdextension虽列Android路径，本机没有对应.so，不代表可用；安卓先静态回退或另行编译/验证arm64及Cubism授权。不能把Windows DLL复制改后缀 |
| 图标 | 本轮PNG＋Windows多尺寸ICO | Android传统图标可用PNG；正式自适应前景/背景需按安全区另制，避免裁掉眼睛。尚未制作/验收安卓自适应图标 |
| 打包 | Windows导出与实际EXE图标已验证 | APK真机侧载；商店AAB/签名与渠道要求另评估，密钥保持私有 |

本机2026-11-06轻量核查：adb在`C:/platform-tools_r20-windows/platform-tools/adb.exe`，默认Android SDK目录不存在，java不在PATH。没有全面扫描其他安装目录，因此结论是**尚未核实可用Android工具链**，不是断言整台电脑无JDK。没有连接/操作手机、安装SDK、生成密钥或导出APK。本轮用户要的是可行性评估；安卓移植应另以触控→横屏/安全区→原生库回退→分档性能→真机测试推进。

## 常见问题与来源

- EXE仍是Godot图标：检查modify_resources=true、ICO路径及重新导出日志，不只看旧快捷方式。
- 动画资源变大：检查导入上限；姿势图必须保留透明与格子边界，不能让相邻帧进入裁剪。
- 安卓启动缺库：检查实际arm64二进制与gdextension配置；配置写了路径不会自动产生.so。

官方依据：[Windows导出图标](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)、[Windows资源修改选项](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformwindows.html)、[Android导出与启动图标](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)。在线stable文档会更新；实施时以项目固定4.7.1编辑器的实际选项、模板和当时渠道要求复核。
