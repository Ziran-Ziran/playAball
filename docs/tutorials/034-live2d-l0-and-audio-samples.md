# Live2D L0隔离验证与音频小样恢复

## 人物表情修订：圆润眼型与奶凶

2026-11-04用户要求减轻人物凶相。制作时使用原样卡作为编辑目标，只修改主角眼型、眉毛及邻近表情线；把上眼睑和眼角变圆、减轻眯眼/尖锐黑色睫毛楔形/重V形压眉，保留鼓脸与抿嘴的轻微倔劲。外包伙伴已圆眼惊讶，保持不变。生成式编辑不保证目标区域外逐像素相同，因此实际检查主体、姿态和构图，保留原图供前后对照。heavy/外包/快速上弦三张新版为待审v2；提示词和记录见production_r2.json的eye_revisions。比较图包含脸部放大及167像素缩图，缩图不是正式HUD截图，也不代替用户审美验收。

## 2026-11-04执行更新：SDK到位，模型链路已运行

下文“SDK未到位/未测”描述保留为此前恢复检查点。当前用户已自行下载CubismSdkForNative-5-r.5.zip，已解压到.local；原图的拟人样卡已获认可，另三张样图已返回，数量累计6/6，不重置首轮配额。Live2D架构入门见[教程035](035-live2d-architecture.md)。

### 实测版本与适配限制

官方SDK包5-r.5的SHA256为7ff3a4bbc19c0a8728965aa522ab77eb11b252916453e68a8a78d3b71188bb12，Core运行查询major=6/minor=0/patch=1。gd_cubism保持v0.9.1/60e9c61，godot-cpp保持fbbf9ec。引擎仍是4.7.1标准版，renderer仍gl_compatibility。

原版桥接直接配Framework5-r.5编译失败：CubismRenderer新增纯虚方法/构造参数，且GetDrawableRenderOrders接口变化。另一个官方旧SDK下载尝试返回403，未继续盲试。最终隔离实验使用公开Framework **5-r.3 / f2b858a7b99eaef928e7bf2c7bdbeb6ca4f75bbf**（ZIP SHA256 5c3914cc234a8af5a01a70808ba2eeb8d37ab9361c396f6d46364c363c22570b），配SDK5-r.5的Core，做了一处渲染顺序函数适配。它是本地兼容实验组合，不是官方原包完整支持声明。

补丁只在.local：

- SConstruct的两处Core库目录选择改为`ARGUMENTS.get("cubism_core_msvc", env["MSVC_VERSION"].replace(".", ""))`，构建时传cubism_core_msvc=143。VS18编译器可链接SDK所带v143库的依据见[微软兼容性说明](https://learn.microsoft.com/en-us/cpp/porting/binary-compat-2015-2017?view=msvc-180)，实际仍以编译/运行结果为准。
- 自定义Framework的Model/CubismModel.cpp把`Core::csmGetDrawableRenderOrders(_model)`改为`Core::csmGetRenderOrders(_model)`。只在SDK所附旧版Haru示例验证，未验证Cubism5.3增强混合/离屏绘制；不能向用户或绑定师承诺这些新特性可用。
- SCons4.7未识别本机VS18，产生MSVC_VERSION缺失；改用独立build_env内的SCons4.11.1后能够构建。Python3.14.3和本机24逻辑处理器已实查，构建使用-j8。没有全局升级或降级工具，也没有迁移引擎。

### 实际结果与曾发现的问题

Debug和Release DLL均构建成功。隔离model_fixture中运行Haru示例，枚举42参数，测试ParamAngleX=-25/0/+25及左右眼开闭。透明PNG的alpha范围0～255，转头/闭眼的像素变化集中在脸部；编辑器二进制与Windows Release导出四个姿态的输出逐像素一致。

最初禁用pose_update使示例互斥的两套手臂同时出现。保留首次截图为问题证据，启用模型pose处理并预推进0.5秒后，最终编辑器与Release截图中多余手臂消失。因此不能把“参数能改”单独当作正确显示模型。

Release包从独立model_export_release目录启动，editor_binary=false、gl_compatibility；40次加载/释放中节点清空、WeakRef释放和对象数1405保持稳定，55条检查零失败。对应model_release40.json及.log保留。过程内存仍有分配器/驱动阶梯变化，因此继续120次观察；不能据短测无崩溃就写“无泄漏”。最终状态以production_r2.json的live2d字段及STATUS最新记录为准。

桥接把[CSM][I]信息统一输出到Godot的WARNING通道，故日志存在版本/启动/释放的WARNING；这不是无警告运行。当前未出现对应的脚本错误或崩溃，不能把这些日志删掉后称“无WARNING”。

### 在另一电脑复现模型实验

1. 按上文重建公开桥接、固定godot-cpp、用户同意许可后取得的SDK5-r.5；下载Framework5-r.3公开ZIP并展开到桥接thirdparty/CubismNativeFramework，使其优先于包内Framework。应用上述两处本地补丁并保留diff。
2. 在独立Python虚拟环境安装SCons4.11.1，实查那台机器MSVC；分别运行`python -m SCons platform=windows arch=x86_64 target=template_debug cubism_core_msvc=143 -j8`和template_release。如果那台机工具集不同，重新核实链接兼容性与实际库路径，不写死本机VS路径。
3. 用prepare_live2d_l0.ps1创建model_fixture；复制tools/live2d_l0_model_test.gd到其model_test.gd，把preflight.tscn的脚本引用改到model_test.gd。复制桥接gdextension、res与bin到该fixture的addons/gd_cubism，并复制SDK Samples/Resources/Haru到models/Haru。保留SDK与示例许可/版权说明，测试模型不进入正式游戏或上传。
4. export_presets.cfg设include_filter为`*.json,*.moc3,*.txt`，确保非默认资源文件真正进包。按隔离基线流程导入、运行、导出Release；运行时使用`-- --out=<绝对证据前缀>.json --cycles=40`，较长观察可用--cycles=120。
5. 对比证据JSON、透明PNG、左右转头/闭眼局部、节点与对象计数；进程内存可通过Windows GetProcessMemoryInfo记录WorkingSetSize和PrivateUsage。OS.get_static_memory_usage只覆盖Godot统计的一部分，不能代替原生/驱动内存观测。

正式角色绑定仍未实施。后续须把此兼容组合支持的模型目标版本交给实际绑定操作者，并用自有模型重新验证遮罩、极值、动作、物理和释放；本轮Haru只是技术测试样本。

以下为此前恢复阶段的历史说明：当时只实测无模型引擎基线；现在的实际模型结果以上方执行更新为准。自有菜单角色仍是静态PNG。

## 为什么先做L0

Cubism Editor把原画、网格、变形器、参数关键形编成moc3；Core执行模型计算；Framework处理动作/物理等；gd_cubism把这些能力桥接给Godot。PNG、PSD、moc3分别是不同产物，不能靠改扩展名互换。一个没有加载模型的EXE只能证明基础导出可用。

已核验[gd_cubism v0.9.1](https://github.com/MizunagiKB/gd_cubism/releases/tag/v0.9.1)，提交60e9c61ed20d08ec19b2cb80fb492ce6344927c6；godot-cpp固定fbbf9ec4efd8f1055d00edb8d926eef8ba4c2cce。其.gdextension声明compatibility_minimum=4.3，不能据此推断4.7.1运行成功。0.9后UserModel直接绘制，不再自己就是SubViewport；透明/合成实验应按该版示例验证。

桥接源代码MIT；链接后的Core采用Live2D Proprietary Software许可，Framework采用Live2D Open Software许可，示例模型另有素材/角色条款。不能把MIT当作整个组合的许可。Core应来自[官方下载页](https://www.live2d.com/en/sdk/download/native/)，不能用来源不明的DLL绕过许可。用户已选择自行接受许可/下载，尚未收到SDK。本轮不购买Editor、不激活试用、不代发委托。

## 当前设备与产物

LAPTOP-8GS4N5SG / Windows10.0.26200 / Ziran；Git2.53.0、Python3.14.3、Node24.19.0；Godot实际4.7.1.stable.official.a13da4feb。VS C++工具链由vswhere确认在18/Community（18.10.12210.168），SCons未安装，不把PATH中没有cl等同于没有编译器。Godot4.7.1导出模板已存在。

.local/art_audio_r2/ 保存候选、公开源码、下载包、证据、最小项目及导出。没有clone游戏、复制整个工程或更改正式入口。

- bridge_source/gd_cubism-0.9.1/：公开桥接源码；source ZIP SHA256 c09e4f985b087d61149d162d3b7eb54680d966d0cfe195f4bef0b1842bb3b7a5。
- godot-cpp ZIP SHA256 9a1c91a4c9fcbb9b9a068007fe5eaa1098cfd848a027883138b102815d3d4110，已展开到桥接的godot-cpp目录。
- engine_baseline.json/.png：实际窗口渲染gl_compatibility、640×360、保存返回OK。
- export_baseline2.json/.png与export_launch_evidence.json：发布模板实际启动，editor_binary=false，返回0，gl_compatibility；未加载桥接模型。
- 首次Start-Process启动返回1且无运行日志；后续subprocess以EXE所在目录启动成功。保留两轮证据，未把第一次失败写成通过，未确定其根因。

## 另一台电脑如何复现基线

先按AGENTS调查那台机器，核实Git、Python、Godot4.7.1标准版及同版导出模板。不要照抄本机Godot路径。运行以下命令，`$GodotExe`由操作者设为该机器实查路径；PowerShell的`Start-Process -Wait`用于等待GUI子进程完成。

```powershell
./tools/prepare_live2d_l0.ps1
$fixture = Join-Path (Get-Location) '.local/art_audio_r2/fixture'
& $GodotExe --headless --path $fixture --editor --import
& $GodotExe --path $fixture -- --out="$fixture/../engine_baseline.json"
New-Item -ItemType Directory -Force "$fixture/../export" | Out-Null
& $GodotExe --headless --path $fixture --export-release 'Windows L0' "$fixture/../export/l0_preflight.exe"
# 等导出结束、确认文件存在，再从export目录运行EXE；--out使用绝对路径。
```

准备工具只把四个小文件写到.local：project.godot、preflight.gd/.tscn、export_presets.cfg。重复运行内容一致则保留，已有不同内容会拒绝覆盖。要独立重做可用`-FixtureName repro_fixture`。工具不下载依赖、不接受许可、不安装软件、不加载或验证Live2D。

preflight.gd等待实际渲染帧，记录Engine版本、RenderingServer实际renderer、DisplayServer、编辑器/发布模板标记与桥接类存在性，并存viewport截图。当前bridge_class_available=false且live2d_tested=false是预期事实，不能删除这两项让结果变绿。

## SDK到位后完成真正的L0

1. 用户把官方Native SDK ZIP放在.local/art_audio_r2/downloads/。记录压缩包哈希、SDK cubism-info、Core README/CHANGELOG与RedistributableFiles、Framework版本；保留其许可。桥接文档中5-r.1只是示例，不是本轮已安装版本。
2. 解压到桥接thirdparty/CubismSdkForNative-*，检查Core/include、Framework/src、Core/lib/windows/x86_64下实际MSVC版本。桥接SConstruct以MSVC_VERSION决定子目录，当前VS18工具集与SDK库目录需实查，不能猜能直接链接。
3. 使用独立本地Python环境安装适用SCons。桥接v0.9.1文档建议4.7并提示旧环境4.8问题；本机Python3.14是否可用也需实测，不全局降级工具链。按固定godot-cpp提交构建template_debug及template_release，命令主体为`scons platform=windows arch=x86_64 target=template_debug`和相应release；保留完整日志。
4. 只将构建插件放入隔离fixture的addons，先验证GDExtension加载；按SDK包中实际模型许可选一个测试角色。没有许可依据就不使用，不把示例角色作为游戏素材发布。
5. 从真实模型枚举参数，测试AngleX/Y、EyeLOpen/ROpen等实际存在的参数；保存极值与中间值截图。透明背景/睫毛眼白遮罩叠加到明暗背景，检查漏色、黑边、翻转与modulate。不能用简单瞳孔移动替代精细脸部转向。
6. 在独立Windows导出包运行同一模型/参数脚本，核对moc3、model3.json、纹理、动作/物理资源是否都打包；从无源项目依赖的目录启动，存日志及截图。
7. 多次创建/加载/释放模型，跨帧等待释放并观察对象与进程内存；固定循环数和热身，记录是否单调增长、是否残留声音/动作/节点。退出无崩溃不等于无泄漏。

上面模型加载、透明遮罩、参数、模型导出和重复释放**全部未测**，因SDK/Core及有许可依据的运行时模型尚缺。Live2D路线保留，不退回原生绑定。

## 自有角色绑定的能力与交付边界

当前Agent能整理图层、参数表、写Godot适配代码与测试；没有已验证的Cubism Editor操作/网格绑定自动化，未发现本轮PSD/cmo3/moc3。L0通过后再安排可靠的实际绑定操作者，不承诺一键专业绑定。

先以原菜单角色身份整理统一画布PSD，补足遮挡下的脸/发/关节；面部转向要有透视关键形和组合参数修正，眨眼应闭合，头发用分层物理惯性。建议AngleX/Y、左右眼开合、呼吸、头发物理及左右局部戳脸参数；最终ID/范围以实际模型为准。Godot输入→坐标归一化/状态仲裁→Cubism参数/动作→Core形变输出，不能让眨眼、动作和触摸每帧互相覆盖。

小样交付PSD、可编辑cmo3、变形器/参数说明、运行时model3.json/moc3/纹理、实际使用的physics3/exp3/motion3及Cubism/Godot两段分别标来源的录像。先验收连续转头、眨眼、戳脸、呼吸、头发惯性，再扩摸头/饭碗/尾巴。此处是要求，不是已完成资产。

## 六个声音小样及修改方法

本轮使用[Sound Effects API](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert)和[Music API](https://elevenlabs.io/docs/api-reference/music/compose)，非TTS。四声效请求eleven_text_to_sound_v2、1.0秒、mp3_44100_128；两音乐请求music_v1、18000ms、force_instrumental=true、相同输出格式。六个HTTP200，权限实证只覆盖这些请求和格式，不推断48k WAV权限。

完整prompt/request、原始文件哈希、song-id（如返回）、格式、时长、峰值和用户状态见[production_r2.json](../art/production_r2.json)。脚本在提交前写请求状态，已有记录一律跳过，未知/超时不自动重试。没有在清单、日志或脚本里写入Key值。

原始文件.local/art_audio_r2/audio/*_raw.mp3保留；*_audition.wav使用已安装imageio_ffmpeg附带FFmpeg7.1转PCM16并统一-6dB，未安装新工具。四短音解码1.0秒，两音乐约18.0506秒（含编码时长差），44.1k双声道。

原始受伤MP3浮点解码有6样点超过满幅、峰值+0.10dBFS；其余峰值小于0，均有限数值。MP3解码超幅不单独证明原波形削平；-6dB副本只提供试听余量，不能修复原有失真。没有剪到游戏瞬态长度、没有混音接线、没有三遍循环验收，也没有真人试听结论。

认可音色后才剪前导静音、按瞬态保留尾音并加短淡变，转换短音WAV/音乐Ogg。配器或瞬态要修改时先调整具体prompt，不靠整体变速充当新演奏。短音乐只是配器试听，不把18秒自动循环叫正式无缝BGM；后续完整长度和循环接缝单独制作、试听。


## 2026-11-04拟人样卡与尺寸对照

heavy一级真实内置生图输出为.local/art_audio_r2/candidates/heavy_lv1_anthro_sample.png，完整prompt见production_r2.json的samples。heavy_lv1_size_comparison.png只将原图按192/167/154/134像素等比缩小并做灰度副本；没有程序绘制角色替代生图。前两宽度来自当前1280逻辑卡片内宽，后两为1024窗口0.8缩放的四舍五入估计。当前HUD没有插画槽，因此它不是已接入卡片的游戏截图，也没有排版验收结论。需要先认可人物画法，再由B整文件接入排版样板。

120次补测已执行：Windows Release实际135条检查零失败，对象数保持稳定；进程私有内存从237146112到279715840字节。2026-11-04复核原始model_release120_memory.json，更正此前“末20次采样不变”：实际末20轮仍有小范围波动，不能写成恒定。前期阶梯增长尚未归因，不宣称无泄漏或整体L0全部通过。报告与过程内存保留model_release120.json/model_release120_memory.json；模型功能链路成功与内存疑点分别登记。

后续用户已认可成年比例DeepSeek-chan现成模型并授权制作独立互动样板；源项目和Windows Release各40项检查通过，但新模型120轮私有内存仍增长，完整L0继续未通过。模型选择、派生manifest、真实交互与复现见[教程038](038-deepseek-live2d-menu-sample.md)，不以本页Haru旧数据代替新模型验证。
