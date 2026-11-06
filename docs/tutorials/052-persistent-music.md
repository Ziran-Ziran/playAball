# 052 原曲BGM、跨场景播放与独立音乐音量

## 本轮音源与边界

root先按用户记忆的歌词定位罐装毕加索《Let Me Go（共创版）》[原曲页面BV1XbY66nEWr](https://www.bilibili.com/video/BV1XbY66nEWr/)，随后用户提供`BV1XbY66nEWr_LetMeGo.mp3`用于接入。本轮没有抓流、调用第三方镜像、下载另一份音频或生成替代音乐。root将用户文件原字节放在assets/music/let_me_go.mp3；两份SHA256均为`4895eb01e8667ddf51d39546cdf73b172fea71f8cc3c3ef20ce1e933a972e826`，3581165字节。用户提供本机体验音源不等于已经取得公开发行许可；来源和后续发布范围仍由root在交付记录说明。

## 文件与播放器

- scripts/ui/music_manager.gd：project.godot中唯一MusicManager Autoload，跨菜单和战斗常驻，仅持有一个PersistentMusicPlayer。
- scripts/ui/main_menu.gd：设置中的原主音量滑杆保留，增加音乐音量、实际歌曲状态和“全部静音”；设置面板改为不透明深海底色，避免logo透在文字下。
- scripts/roguelite/run_arena.gd：把原静音请求接到全局音乐与SFX，初始化时同步已保存的静音状态。
- scripts/ui/game.gd：暂停菜单增加音乐滑杆，原音效、提示滑杆保留。
- tests/music_manager.gd：临时短WAV循环、原MP3、设置、单例与场景生命周期的专项。

Music总线发送到Master，音乐默认0.22。Master仍是总音量；Music仅改变音乐。全部静音用Master mute压住音乐和音效，同时更新现有SFX控制；解静音恢复静音之前的Master mute状态，绝不把Master增益写成另一数值。音乐不会因瞄准、Esc暂停、成长或切场景而stop/seek；默认以低音量连续播放，不在每次发射时断歌。

## 音源选择与循环

启动时只搜索一次，缺曲保持安静，不在每帧重复加载或输出ERROR。Windows导出包依次查找EXE旁的`music/let_me_go.mp3`、`.ogg`、`.wav`；源工程运行时外置目录是工程根的music。没有外置文件时才查已获准进入当前工程的`res://assets/music/let_me_go.mp3`、ogg、wav。本轮用户原MP3已在资源路径内，状态显示真实曲名；没有可载入音源时设置显示“未载入音乐”。路径说明只放本教程和交付说明，不堆进玩家设置。

资源路径存在检查用ResourceLoader.exists，支持导出PCK的.import重映射，不能用原始文件FileAccess判断PCK资源。外部原文件才用FileAccess。原MP3不转码、不裁剪。MP3/Ogg启用stream.loop；WAV使用LOOP_FORWARD并按真实采样数设置终点。显式reload同一已播放曲目保持原播放器和进度，不重新开头。

## 接口和设置保存

MusicManager提供`reload_track(directory="")`、`set_music_volume(0..1)`、`set_muted(bool)`、`status_text()`、`snapshot()`。传入directory时只测试这个目录，不回落正式资源；正式调用不传目录。snapshot提供available、playing、position、length、source、music_volume、muted和player_id，供只读验证。

music_volume与muted合并保存到`user://ui_settings.cfg`的audio节，不清空原volume或visual节。主音量继续由原入口读取和保存。mix_changed与track_changed的UI接线使用场景实例命名方法，随实例销毁自动断开；不要在Autoload信号中留下仅捕获局部slider的lambda，否则场景释放后再次调音量会访问freed控件。

## 实际验证

本机LAPTOP-8GS4N5SG / Windows10.0.26200 / Godot4.7.1标准版Compatibility。专项先因缺少Autoload退出1；首轮接线断言通过但出现freed lambda渲染日志错误，该轮不计最终通过。改为实例方法后复测没有该ERROR。

```powershell
# $GodotExe使用当前机器已核实的4.7.1标准版绝对路径；原生小窗：
$test = Start-Process -FilePath $GodotExe -ArgumentList '--path . --script tests/music_manager.gd -- --small' -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput music.out -RedirectStandardError music.err
Get-Content music.out,music.err
if ($test.ExitCode -ne 0) { throw '音乐专项失败' }
# headless复验将ArgumentList换为：--headless --path . --script tests/music_manager.gd
```

原生26项、headless25项通过，实际退出0。图形模式多一项Music总线非静音peak检查。日志`.local/music_native_final2.log`、`.local/music_headless_final.log`；小窗口截图`.local/music_settings.png`、`.local/music_pause.png`。旧菜单headless导航12项也通过，Master滑杆仍保留原Content child1兼容。

专项在.local生成0.12秒合成WAV仅测试实际多次循环，不进入assets、不作为交付BGM。原曲实际解码时长125.376秒，播放位置推进到0.8667秒、Music总线peak约-21.69dB；这是解码/播放与电平证据，不冒称已人工试听。两轮菜单→Game→返回期间player_id不变，进度连续；真实暂停和瞄准时进度继续。最终场景释放后全局mix/track订阅均为0，没有累计旧控件回调。全部静音能同时压音乐与实际SFX，解静音保留原Master增益；外部已经mute的Master也不会被擅自解除。

测试在结束时按原字节恢复ui_settings.cfg，原本无文件则只移除本测试创建的这一份；同时恢复Master和Music总线增益/mute。测试不要与另一进程的菜单设置测试同时跑，以免共享user目录相互覆盖。原生Live2D保留其既有Cubism弃用提示，未屏蔽日志。导出PCK资源可用性由root的实际新包探针另验，不能只凭编辑器结果声称新EXE已含音乐。

## 进程退出的音源回收

完整回归另发现：短命工具在_initialize请求quit之后，Autoload仍会立即开声，verbose能定位AudioStreamMP3与AudioStreamPlaybackMP3各一份遗留引用。不能只因命令退出0就忽略这个警告。默认启动现等待应用走过首个完整process_frame后才加载；如果调用者已经显式选曲，则不会覆盖该stream。这里没有对project_map或测试名称做特殊判断。

MusicManager._exit_tree在AudioServer锁内停止、断开stream并释放唯一播放器。对于实际启动过的音源，解锁后留50毫秒让混音线程回收停止的Playback，再用锁屏障同步；从未加载音源时没有这段等待。纯stop/null/free以及仅锁同步曾仍复现泄漏，增加实际混音回收窗口后才通过。此等待只在退出时发生，不在切场景、暂停或每次发射时执行。

受影响的只读验证为`--headless --verbose --script tools/project_map.gd -- --check`与“实际播放0.15秒后quit”探针。最终`.local/r8/music_exit_final.out/.err`和`music_play_exit_final.out/.err`均退出0、stderr空；后者snapshot仍显示原曲playing、进度0.0933秒。旧失败日志保留，不屏蔽ObjectDB输出，也不把未播放的短命工具结果当作完整播放路径验证。

2026-11-06提交前独立Review补充：上述两次通过不代表稳定消除。独立Agent在ball_art headless verbose三轮的第三轮仍复现AudioStreamMP3与AudioStreamPlaybackMP3各一引用以及Music StringName；图纸检查也曾偶发退出警告。当前未发现运行中跨场景累积，作为退出时非阻塞已知限制保留。50ms不是混音完成确认，不继续增加固定等待并宣称根治；后续需专门验证音频线程生命周期与不同后端。

退出修复后的串行复测为`.local/r8/music_final_native.out/.err`（原生26项）和`music_final_headless.out/.err`（25项），均退出0且没有ERROR、ObjectDB泄漏或Orphan StringName。原生仍有既有Cubism提示，headless stderr为空。原曲/短WAV、两轮场景切换和设置原字节恢复断言仍通过。回收窗口经过当前本机音频后端验证，不泛称已经覆盖所有设备或驱动。
