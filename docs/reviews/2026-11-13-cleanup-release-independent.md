# 整理与公开发行独立Review

日期：2026-11-13。独立审查者：`independent_review` Agent，未参与整理执行或本轮实现；仅写本报告。当前设备实测 `LAPTOP-8GS4N5SG` / Windows NT 10.0.26200 / Ziran / `C:/Users/Ziran/playAball`。开始时分支 `feat/release-experience`、HEAD `235f32e`、工作区干净。

## 结论与范围

**本轮整理与公开发行准备的独立Review通过，无剩余已证实必须修复项。** 用户2026-11-13已明确授权本批commit、push、PR合并与Release上传，覆盖历史任务仅本地commit的限制；不得把本次授权解释成下一任务长期权限。后续仍应按仓库流程等待真实远端CI通过，再Squash合并并给合并后的提交建Release标签，不能提前声称上传或远端验证完成。

本轮只改变入口/状态/用途及整理说明等文档，未改玩法、美术、Live2D或已测二进制。既有运行审查、源指纹与未测边界仍见2026-11-10最终Review，本报告不伪造新试玩或重新论证235f32e全部实现。

## 整理边界与实际结果

初稿53目标的绝对解析路径均在工程内，目标及递归子项未发现symlink/junction。初稿包含3个verify-profile，根Agent执行前已排除全部profile；运行中的验证目录没有被整理。

本人逐文件比对14个旧解压包与同名ZIP。发现`builds/playaball-live2d-release-20261105-215502`有11项不能从ZIP精确恢复（6个import字节不同、5个ctex.uid不存在），立即要求排除。根Agent进一步按完整文件集合比较，共保留3个不完全一致旧目录，未为清理强行删除或改写Live2D文件。

永久删除被自动安全审查拒绝，根Agent改为保留式隔离，没有强行永久删除。本人读取`.local/cleanup-result-20261113.json`并核对47条来源→目的地：原路径均已不在，隔离目的地均存在且在本工程内；约6405766814 bytes仅重新组织，实际释放磁盘空间为0。该结果必须称“隔离/整理”，不能称已永久清理6.41GB。

`.local/cleanup-approved-20261113.json`提供旧导出路径→证据归档的映射，`.local/cleanup-result-20261113.json`提供旧路径→完整隔离目录的映射。导出顶层out/err/log、签名验证/包探针与配置先归档到`.local/cleanup-evidence-20261113/`；原始字节仍完整保留在隔离目录。本人对归档原文件与隔离副本逐份哈希核对；归档新生成的`archived_files.json`是清理元数据，不当作应存在于原副本的文件。

正式PlayABall目录/ZIP、原问题日志与评估快照、SDK/JDK、menu_character_runtime、签名身份、用户原视频及已剪素材不在处理目标内。本人确认工具链、原runtime和全部3个verify-profile仍存在；签名私钥存在性由根Agent检查，本人没有读取密钥内容。源码历史资产没有凭“当前未引用”删除。

## 发行成品独立核验

四项当前文件大小与SHA256均重新计算，并与`builds/PlayABall-1.0.0-checksums.json`一致，隔离后再次核对未变：

| 文件 | SHA256 |
| --- | --- |
| Windows ZIP | `94E66CCA2DA47EFB38E5C9ACE47E41A328993EBDA54D156CB422C1FC2B239AEE` |
| Windows EXE | `6FB88266B20EF4701838835EC9493445F46C0A82908CB6D7BD6A4073898D6F60` |
| Android ZIP | `37E49F5ED8E7839DBAFA4088FD6CB4126AD9234CE1979277F52A4A5A113D841A` |
| Android APK | `6719F495EBCDBF5EF57672514246C3523B9EB8D5E9A5475C27234C2992F51EFC` |

两个ZIP CRC检查通过；Windows128项、Android13项，未发现keystore/password/preparation.json文件名混入。111份Windows旁置Live2D文件与manifest哈希一致。EXE/APK与既有已签名/原生验收A版本完全同字节，所以沿用其签名与运行证据，不冒称本轮重新试玩。两平台build_info的reviewed_commit为235f32e，明确是提交前已审工作区构建，并非之后合并HEAD重新导出。

已审Release说明和SHA256SUMS草稿：上传范围仅Windows ZIP、Android ZIP/APK、校验JSON与SHA文本5件；不上传隔离目录、SDK、用户录制或密钥。说明保留ARM真机/最低配置/长期温升/真人通关与经营爽感未全面验收、self_list仅有界未复现及偶发退出引用警告。Release标签后含整理文档不被写成重新构建过二进制。

## 文档、验证与后续门禁

README、STATUS、教程063与本轮自查Review已读审，准确写明47隔离、释放0、3旧包/profile保留与新授权，不把旧禁止上传记录当成本次状态。教程说明恢复前检查原位置没有新文件、旧source_logs如何通过映射追溯；正式ZIP保持原哈希，没有为修改本机日志地址重打包。

根Agent本轮完整61套回归退出0、8项Python检查通过，证据`.local/cleanup-release-20261113-verify.log`与`cleanup-release-20261113-python.log`；本轮无行为变更，不重复执行无关试玩。原三个暂存格式例外已在旧独立Review明确接受，不称全部新增文件零格式提示。

本报告到位后由根Agent登记用途、重生成FILE_MAP并check，再核对本轮暂存差异和文档链接。之后按本次授权提交、上传任务分支、创建PR、等待真实CI、合并并上传Release；线上动作结果必须另以实际记录收口，当前不预先记为成功。本轮没有要求因已明确授权而再次向用户索取相同确认。
