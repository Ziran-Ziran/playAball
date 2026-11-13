# 文件整理与1.0.0公开发布Review

范围：分支feat/release-experience，运行内容为既有235f32e及其前序a494ad2；本批只整理本机再生文件、增加整理教程/审查和更新入口文档。用户于2026-11-13明确授权本轮提交、push、合并、Release上传，覆盖此前本地提交任务的禁止上传限制。

设备LAPTOP-8GS4N5SG，Windows10.0.26200，Ziran，Godot4.7.1。开始时工作区干净，origin/main为612bebb。未删除源码、素材历史、教程或他人工作；本机清单和操作证据位于.local/cleanup-*-20261113.json。

正式Windows ZIP/EXE与Android ZIP/APK四项SHA256已重新核对，与原checksums JSON一致。二进制保留原字节，公开说明保留已有self_list间歇性风险、退出引用警告、ARM真机与真人通关未完成等边界；用户录制只证明该次实况，不替代自然通关。

清理前逐份归档导出配置/日志并校验。永久删除被自动安全审查拒绝，根Agent没有改用其他工具强行删除；改为47个目录保留式移动至`.local/cleanup-quarantine-20261113/`，精确映射见`.local/cleanup-result-20261113.json`。整理约6.41GB，释放空间为0。3份旧解压包不能由同名ZIP精确恢复，跳过保留；全部verify-profile也保留。原始问题日志、SDK/JDK、模型与Native、发行密钥、评估快照、正式包、用户视频及剪辑均保留。

验证：本次完整61套行为回归退出0，`.local/cleanup-release-20261113-verify.log`末尾VERIFIED；8项Python准备工具检查通过。目录、文档链接和独立Review在提交前统一核验。第一次重生成目录时独立审查文件尚未写入，工具正确阻止悬空用途，待文件到位再生成并check；不冒称第一次即成功。既有三处无行为影响格式例外见2026-11-10独立Review，不用已跟踪差异检查掩盖新增文件问题。

独立审查见[本轮报告](2026-11-13-cleanup-release-independent.md)；整理原理、恢复映射、验证和发行见[教程063](../tutorials/063-cleanup-and-public-release.md)。GitHub PR/CI/Release状态以线上记录为准，提交前不预称上传成功。

收口：独立Review通过，无剩余已证实阻塞；47份隔离映射、370份原归档证据、4项成品SHA/ZIP CRC与111份Live2D均复核。目录补齐3份新文档后write/check通过（792文件），本轮相对文档链接和完整新增差异检查通过。本批准备按既有授权提交并push，由远端smoke通过后Squash合并，再上传原字节1.0.0成品。
