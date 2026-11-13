# 文件整理与公开发布

本教程说明哪些文件可再生、哪些必须保留。2026-11-13用户明确授权本批commit、push、PR合并和GitHub Release上传；这不构成下一任务的长期授权。

## 目录职责

- `assets/`、`resources/`、`scenes/`、`scripts/`是可编辑源码。历史图片、样板和来源记录可能被教程或开发工具使用，不能只凭正式入口未引用就删除。
- `docs/`保存教程、设计与审查；`docs/file_purposes.json`是用途源，FILE_MAP由工具生成。
- `.local/`保存本机工具链、私有运行资源和验证证据，不进入Git。
- `builds/PlayABall-1.0.0-Windows.zip`与`PlayABall-1.0.0-Android.zip`是已审正式成品；APK另供直接安装。校验见同目录checksums JSON。
- 用户原始视频和已剪素材仍在Videos目录，本轮不清理或自动公开这些录制。

## 安全清理的输入、过程和结果

先只读盘点目录、大小和Git状态。暂存清理仅选`.local/export-<32位hex>`、`android-export-<32位hex>`及已停止的失败录制；运行中的测试profile不能删除。签名目录、SDK/JDK、Live2D原模型和Native、原问题日志与评估快照均保留。

导出根目录中的日志、签名验证、包探针和配置先复制到`.local/cleanup-evidence-20261113/<原目录名>/`并校验哈希。`.local/cleanup-approved-20261113.json`记录旧路径→证据归档/ZIP的映射；已有build_info的旧source_logs通过此表追溯，不重写正式ZIP而改变其哈希。

旧成品解压目录必须先与同名ZIP比较完整文件集合和每份文件内容；不一致时保留，不能只比较EXE。删除前再次核对绝对路径属于本工程指定的`.local/`或`builds/`子目录，并拒绝重解析点。不使用跨Shell拼接删除命令，不盲目执行git clean。

清理后复核正式成品哈希、密钥存在、证据归档与Git差异。本批没有改变玩法、物理或美术资源；不需要新增检查器参数。扩展清理范围时必须重新盘点与核对用途，不能将这次已核验路径列表当成通用删除规则。

本次实际执行时，自动安全审查拒绝永久删除，因此采取更安全的保留式隔离，没有绕开审查强行删除。47个已核验目录移到`.local/cleanup-quarantine-20261113/`，`.local/cleanup-result-20261113.json`记录来源和归档目的地；约6.41GB只是重新组织，释放空间为0。需要恢复时按映射移回原路径，先检查原位置没有新文件。本批3个ZIP不完全一致的旧解压目录、所有测试profile均未移动。

## 验证与发行

使用实际Godot4.7.1路径运行`tools/verify.ps1`，再运行Python准备工具测试。更新STATUS、用途及FILE_MAP，完成独立Review后提交。按仓库公约push任务分支、创建PR、等待smoke通过后Squash合并，不绕过保护。

Release标签指向合并后的main提交。上传已验收原字节的Windows ZIP、Android ZIP/APK和校验JSON，说明二进制来自235f32e所审工作区；后续清理文档提交不冒称重新构建过二进制。保留许可、Live2D旁置目录、安卓签名身份和已知限制。GitHub自动Source code附件不含私有模型或发行密钥。

常见错误：删除签名密钥导致后续APK不能更新；删除唯一源模型；把旧候选当正式包；清理正在使用的用户目录；修改ZIP后仍发布旧哈希；把模拟器与自动回归说成ARM真机或真人通关。
