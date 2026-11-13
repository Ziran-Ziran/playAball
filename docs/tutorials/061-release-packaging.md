# 双平台发布包与不修改Live2D的旁置接线

本教程承接[安卓输入与导出](058-mobile-input-and-release.md)。发布包使用release模板；它证明构建格式，不代表自然通关、全部机型和长期性能已经验收。

## Windows完整目录

`tools/export_windows.ps1`先将运行源码复制到唯一`.local/export-*`副本，导入并导出EXE，随后用同版编辑器读取EXE内嵌资源执行`package_probe.gd`。原工程的`project.godot`不写回，输出位于忽略的`builds/`。

指定`-Live2DRuntime`时复制原运行目录的`model/native/textures`和`menu_profile.json`，保留模型原NOTICE/条款，排除含本机来源路径的`preparation.json`。`-Live2DNotices`可附加同版桥接、godot-cpp、Framework/Core许可。用户已确认本轮模型和库的公开分发许可；此参数不替其他项目取得授权。

副本配置新增`ReleaseMenuPaths`autoload，脚本是`scripts/ui/release_menu_paths.gd`。它在菜单节点进入树、尚未执行`_ready`时，只把既有适配器的三个文件路径设置到EXE旁的运行目录。原Live2D脚本、模型、动作、表情和Native库均保持原字节。headless与非Windows跳过，所以包探针仍验证静态回退；真实Windows渲染和DLL加载需要另测。

注册入口必须是autoload的`_enter_tree`，不是`_ready`。实际release首场景曾先入树，导致后者错过角色而静态回退；原生DLL加载/截图验证后才关闭此问题，不能只用headless包探针声称Live2D成功。

```powershell
# 以下路径参数来自当前机器轻度核验，不写进游戏运行代码。
./tools/export_windows.ps1 -GodotExe $GodotExe -BuildName release-1-0-0-windows `
  -Live2DRuntime $RuntimeDirectory -Live2DNotices $RuntimeNotices
```

`live2d_manifest.json`记录复制后的每份文件哈希，可与输入逐一核对。ZIP必须包含整个旁置目录，不能只压顶层EXE/JSON。完整解压后即使工作目录不在游戏目录，也应按EXE所在位置找到模型；删除旁置目录时保持原静态回退而不阻止开始游戏。

## Android签名与包证据

`tools/export_android.ps1`接收本机Godot/JDK/SDK路径与模板。它隔离APPDATA，暂存编辑器路径设置，结束后恢复环境；全局编辑器设置哈希不得变化。4.7.1实际模板为minSdk24/targetSdk36，普通预编译APK无需Gradle，不照搬在线stable文档的旧35数值。

`-Signed`只从`GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD`临时环境读取身份，先导出未签名release，再调用apksigner签名与验证。口令不进入preset、源码、命令行实参或构建说明。首次创建的发行密钥和口令保存在私有忽略目录，必须安全备份；同应用更新沿用同一身份，不重新生成替换。

```powershell
# 在本机安全注入上述环境变量后执行；不要把口令粘进聊天或脚本。
./tools/export_android.ps1 -GodotExe $GodotExe -JavaSdkPath $JavaSdkPath `
  -AndroidSdkPath $AndroidSdkPath -BuildName release-1-0-0-android -Signed
```

ARMv7/ARM64为正常包；`-EmulatorX64`额外加入x86_64仅供模拟器验证。以aapt2读取实际APK的包名、ABI与API，不能把源preset当成成品证据。实际APK的assets被重封成临时资源包，在空目录通过`--main-pack`执行包探针，避免源码兜底。导出只做本地构建，不上传商店。

## 来源与验证

两平台同时生成`build_info.json`、资源清单与SHA256。`tools/release_notices.gd`从实际引擎提取Godot及编译依赖许可，附上字体OFL、Kenney CC0、音乐来源和发布署名。不会将签名私钥或个人准备报告复制进运行资源。

源码验证使用`tools/verify.ps1`；原生GUI、实际EXE/安装APK、Live2D旁置目录完整性与模拟器操作需另留证据。模拟器host GPU可正常验证Compatibility；SwiftShader上曾报CanvasShader uniform限制，不能把软件模拟器失败当成全部安卓不兼容，也不能因host模拟器成功就保证所有低端手机。

安卓实际字体缺标点时使用随包OFL Noto fallback；`resources/ui/body_fallback.tres`选择wght400。原变量TTF默认100，不能把“字形存在”当作字重观感已经正确，也不能只在Windows首选微软雅黑的截图上验安卓字体。

常见错误：ZIP漏旁置目录；用旧EXE测新源码；暂存副本指纹与HEAD不一致却宣称纯提交包；使用debug证书作为正式签名；删密钥导致更新身份丢失；只检查导出退出码而不安装或检查包内容。最终Review应逐项说明实测与未测范围。
