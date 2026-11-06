# 用户提供原曲的BGM本地验收

本地开发验收，不是Git提交阶段最终Review。2026-11-06，LAPTOP-8GS4N5SG / Windows10.0.26200 / Ziran，Godot4.7.1.stable.official.a13da4feb标准版Compatibility；保留基线cfe31a2上全部原有工作，无commit/push/PR/merge。分工与范围见[计划018](../plans/018-let-me-go-background-music.md)。

## 音源和功能

用户提供`BV1XbY66nEWr_LetMeGo.mp3`，按原字节复制到assets/music/let_me_go.mp3。两份3,581,165字节、SHA256均为4895EB01E8667DDF51D39546CDF73B172FEA71F8CC3C3EF20CE1E933A972E826；没有用另一首歌替代。root独立原生媒体探针实际解码125.376秒，进度0.429秒、检测到非零音频电平；seek至末尾后实际循环到0.192秒，退出0（.local/r8/media_probe.out/.err）。

tactical_aim实现唯一MusicManager Autoload及Music总线/单播放器，默认音乐0.22；跨菜单、战斗、暂停、瞄准与返回持续播放，音乐音量/全部静音合并保存配置。主音量仍控制Master，音乐只调Music。配置可覆盖为EXE旁music/let_me_go音源；本轮原曲已内嵌，无需另放MP3。原生小窗口设置与暂停均已检查，设置改不透明深海背景，文案控件完整。

## 测试与独立复核

- 音乐专项最终原生26项、headless25项退出0（.local/r8/music_final_native.*、music_final_headless.*）。原生多一项Music bus非零peak，原曲测得约-21.69dB；不能当成人工试听。短WAV只用于真实循环夹具，不进入交付。验证跨场景相同player_id、播放位置推进、暂停/瞄准不断歌、音量持久化和全部静音覆盖SFX/音乐。
- 首轮持久信号lambda捕获已释放控件产生ERROR；已全部改为场景实例命名方法。两轮Menu→Game→Menu后仅保留活菜单订阅，最终场景释放后归零。测试恢复ui_settings.cfg原字节及Master/Music增益/mute，避免测试污染偏好；会修改同一配置的检查串行运行。
- card_typography未参与实现，独立只读复核管理器/接线，实际串行运行25项headless通过，无ERROR/SCRIPT ERROR（.local/music_independent_review.log）；核对配置恢复、信号生命周期、MP3哈希与新版UI截图。未做独立人工试听或PCK验证，包验证由root承担。
- root完整运行tools/verify.ps1，.local/r8/verify.log退出0、52套行为完成；该轮含后来修复的退出MP3引用警告。修正后重跑受影响的音乐原生26/headless25、短CLI与实际播放退出检查，没有冒称又跑完整52套。

## 退出引用与验证边界

verbose定位到AudioStreamMP3与AudioStreamPlaybackMP3各一份退出引用。默认启动改为跨过首个完整process_frame后加载，不覆盖调用者已显式选中的stream；短CLI提前quit不再开声。退出时在AudioServer锁内stop、断开音源、free唯一播放器，锁外留50ms回收窗口再同步。此等待仅在有音源的Autoload退出时执行，不在正常帧或切场景执行。

纯目录CLI和实际播放0.15秒后退出，两类verbose最终退出0、stderr空（music_exit_final.*、music_play_exit_final.*）。card_typography独立只读复核退出锁路径，未见当前本机交付阻塞；50ms是本机后端验证过的经验窗口，不保证所有设备/驱动，安卓等仍需另测。未屏蔽日志。

提交前最终Review更正：未参与实现的final_review_full在本机ball_art verbose三轮中第三轮仍复现上述两份MP3退出引用，故本节的两次成功只保留为当时证据，不再代表稳定解决。当前未见运行中随场景增长，按非阻塞已知限制记录；不能说“退出问题已彻底修复”。本次最终Review与STATUS采用这一较新结论。

## 实际新包

`builds/playaball-let-me-go-live2d-20261106-194509/PlayABall.exe`与同名ZIP包含原曲和已有Live2D，旧包保留。独立暂存导出，684份源文件在构建中保持不变；只有暂存角色三条路径改为EXE相对旁置目录。

实际内嵌PCK探针验证：导入后的MP3资源可读取、原曲完整解码/playing、播放位置真实推进、菜单进入Game仍为同一个音乐播放器。真实Release EXE从系统临时目录启动，原生Compatibility加载内嵌MP3并正常退出0，没有ERROR/SCRIPT ERROR、ObjectDB或Orphan（.local/r8/native_release.*）；并未完成这份EXE的鼠标逐项操作或人工听觉首尾接缝验收。

最终ZIP完整性、111份旁置文件逐项SHA256通过，归档154,360,193字节（.local/r8/archive.log）。原用户音频字节与来源见[assets/music/SOURCE.md](../../assets/music/SOURCE.md)，替换/调参/排错见[教程052](../tutorials/052-persistent-music.md)。

当前本机已有配置保存了`audio.muted=true`，测试均恢复它，无法仅凭持久值判定由谁开启，未擅自改写。用户试听需在设置取消“全部静音”；新电脑无该偏好时默认音乐音量22%。音频被用户提供用于本机体验，不据此宣称公开发行授权。
