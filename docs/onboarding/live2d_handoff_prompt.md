# Live2D交接提示词：首轮只读讲解，不直接开工

以下内容可整体粘贴到另一个对话：

```text
接手《玩个球》的Live2D菜单角色路线。本轮请先只读调查、解释现状和技术栈，等我明确确认下一步后再动手；不要直接下载、构建、改文件、装软件、接受许可、启动绑定或接线。

先按AGENTS.md轻度核验当前设备、OS、用户、实际工作目录、Godot路径/版本；本账户两台电脑不能沿用历史路径。预期工程C:\Users\Ziran\playAball，但以实查为准，不切换覆盖整个工程，不另建游戏clone/worktree。依次读README、docs/PROJECT.md、docs/STATUS.md、docs/FILE_MAP.md、CONTRIBUTING.md、docs/REVIEW.md，再读docs/plans/011-art-audio-interactive-menu.md R2（重点0/3/6/8节）、docs/tutorials/034-live2d-l0-and-audio-samples.md、035-live2d-architecture.md、docs/art/live2d_model_research.md及production_r2.json。保留所有未提交修改。

事实快照：Godot固定4.7.1 stable标准版、GDScript、Compatibility，不降级或迁移。菜单蓝发鲨鱼尾抱饭碗少女目前仍是静态PNG，自有PSD/cmo3/moc3没有完成。菜单优先Cubism精细绑定；暂停扩旧Godot绑定，不能用整张图摇摆、瞳孔平移或视频冒充转头/触摸。战斗特效继续Godot原生。

用户已经自行接受SDK许可并下载.local/art_audio_r2/downloads/CubismSdkForNative-5-r.5.zip，不要让我重复下载或再次索取同一许可。此前设备LAPTOP-8GS4N5SG。隔离构建组合：gd_cubism v0.9.1/60e9c61、godot-cpp/fbbf9ec、公开Native Framework5-r.3/f2b858a、上述SDK里的Core06.00.0001；VS18、Python3.14.3、隔离SCons4.11.1。原桥接直接配Framework5-r.5编译失败，.local内做过库目录选择和Core渲染顺序适配，准确补丁/哈希见教程034，不要说官方原包直接兼容或新版特性全支持。

已完成的是.local中的官方Haru旧示例：42参数、左右转头/闭眼、透明渲染、Windows Release独立运行，120次加载释放135项检查零失败、Godot对象数稳定。但私有内存237146112→279715840字节，末20轮稳定，增长尚未归因；完整L0仍未通过，不能宣称无泄漏。旧/现代模型、增强混合、自有角色质量不能互相代替。证据model_release120.json、model_release120_memory.json；tools/live2d_l0_model_test.gd和prepare_live2d_l0.ps1可供以后复现，本轮先不要运行新实验。

现成模型调查：氵六青DS鲸鱼娘由https://github.com/A8Chann/dsh-pet-live2d分发，固定调查提交9b7cd8ed0d16bd23fb098bc0c4fdbac63d89de75。只读了公开文件树/NOTICE/model3/cdi3/physics3 JSON，未下载moc3/贴图、未运行第三方插件。元数据有247参数、44表情、8动作组、22物理组，未见PSD/cmo3；代码MIT和美术CC BY-NC-SA4.0分开。另有Mao绒绒家园免费公皮https://www.bilibili.com/video/BV1yep465EQz/，作者注明非商业、以实际视频而非封面为准。不要据“免费”推断可以随商业游戏发布，也不要假装已经看过视频或测过这些模型。

请先向我清楚解释：①哪些已经真正运行、哪些未做、L0为何仍未通过；②PSD→Cubism Editor/cmo3→moc3与贴图/JSON→Native Framework/Core→gd_cubism C++ GDExtension→Godot输入/状态的架构，各部分负责什么、SDK为什么不是角色模型、运行现成模型是否需Editor；③现成模型能省什么，缺少编辑源文件/脸颊关键形会限制什么；④你在当前设备真正具备哪些Cubism操作、绑定和桥接能力，哪些需要我操作、软件许可或实际绑定师，不能承诺一键专业自动绑定；⑤给出2–3个具体后续方案、推荐路线与验收条件，等我确认再开工。

另一对话继续卡片贴图、文字及正式选卡实装，整文件独占run_hud.gd/.tscn及卡片表现/文案/目录；你不要修改这些文件、玩法/Buff/物理或正式入口。共享STATUS、用途目录等以后需要写入时先说明范围，语义追加，避免覆盖卡片进展。本轮不commit/push/PR/merge，不创建自动化，不购买软件、不雇人、不代发消息，不静默退回旧绑定方案。现在先给我现状与技术栈讲解，不直接开工。
```
