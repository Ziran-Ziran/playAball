# 018：用户提供的Let Me Go背景音乐

用户要求找到“Let me go”大肥鱼歌曲并接入BGM，随后提供`BV1XbY66nEWr_LetMeGo.mp3`。本轮使用该用户提供音频，不从视频流提取或放入替代歌曲。工作区LAPTOP-8GS4N5SG / Windows 10.0.26200 / Ziran，Godot4.7.1标准版Compatibility，保留基线cfe31a2上的所有原有未提交工作，不含commit/push/PR/发布授权。

| 项目 | 负责人 | 验收 |
| --- | --- | --- |
| 原音频与来源 | root | 用户文件与项目副本SHA256一致，实际MP3可解码，有真实时长/播放进度 |
| 持续音乐管理 | tactical_aim：music_manager、project autoload | 全程单播放器，跨菜单/战斗/返回连续，循环；瞄准/暂停保留播放；缺文件安静回退 |
| 音量与静音 | tactical_aim：main_menu、game、run_arena整文件单写 | Master主音量保留，独立背景音乐音量持久化；全部静音包含音乐/音效；菜单与暂停同步，最窄窗口控件完整 |
| 专项与开发教程 | tactical_aim：tests/music_manager.gd、教程052 | 合成短WAV只作循环夹具，实际原曲验证解码/播放/场景连续；测试恢复用户配置与音频bus状态 |
| 独立验收、集成和新包 | root及未参与实现者 | 相关及适用全量回归、实际包内BGM载入/播放、教程/用途/FILE_MAP/STATUS、新含Live2D本机体验包 |

默认音乐音量0.22，用户可在主菜单设置和游戏暂停中修改。音乐为表现层，不更改伤害、经济、物理、发射或生成。原MP3保持字节不变；复制到assets/music/let_me_go.mp3，动态loop由管理器设置，外置覆盖保留。所有本地路径只在开发记录和交付说明中使用，运行逻辑不得写入本机绝对路径。
