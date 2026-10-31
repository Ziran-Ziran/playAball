# 019：导出给策划的Windows试玩版

目标是让策划不安装Godot也能双击体验当前碰撞肉鸽，而不是把F5旧侧视实验误当作本次交付。导出版本是功能预览，音质、美术、手感、难度和完整一局时长仍未最终验收。

## 文件与入口

- `tools/export_windows.ps1`：检查本机引擎版本，复制运行资源到忽略的独立暂存目录，导入并导出。
- `export_presets.cfg`：Windows Desktop、x86_64、内嵌PCK、不签名、不附控制台窗口的项目内预设。
- `docs/playtest/PLANNER_README.txt`：随包交给策划的启动、操作、流程、限制和反馈提示。
- `builds/<BuildName>/PlayABall.exe`：单文件试玩程序，游戏资源内嵌；旁边附说明及build_info.json。
- `builds/<BuildName>.zip`：建议发送的压缩包。builds、zip和.local均被Git忽略，不提交成品。

## 为什么在暂存目录导出

源码的project.godot仍保留F5旧侧视入口以及既有编辑器规范化差异。脚本只复制scripts/scenes/resources和可选assets，以及工程配置和导出预设。它只把暂存副本的主场景替换成`res://scenes/roguelite/run.tscn`，原工程文件不写回，结束时核对原project.godot哈希。

不复制文档、测试、个人设置、Git数据或原引擎缓存。暂存项目自行导入并生成所需缓存，再由Godot正式导出。正式导出不使用临时测试脚本代替玩法入口。

## 本机操作

脚本使用Windows PowerShell 5.1及PowerShell 7共有的文件/哈希API；先用`$PSVersionTable.PSVersion`确认实际Shell，再遵守AGENTS调查当前设备和Godot实际路径，确认4.7.1 stable标准版及匹配Windows导出模板已安装。模板由Godot管理；另一电脑不要照抄本机绝对路径。运行：

```powershell
./tools/export_windows.ps1 -GodotExe '<本机实际Godot路径>' -BuildName planner-preview-v1
```

BuildName只允许字母、数字、下划线和连字符；已有同名目录时拒绝覆盖，请换新版本名。脚本通过Start-Process -Wait等待图形版Godot真正结束，并检查版本、退出码和错误日志。日志在.local/export-<唯一ID>中，便于故障追踪。

成功时会输出`EXPORT READY`、`SHARE ZIP`与运行资源指纹。exe/zip存放项目builds目录，不能把它们加入Git。用户自行发给策划；脚本不上传、不发消息、不创建Release。

## 版本识别与验证

build_info.json记录构建名、引擎版本、平台、入口、基线提交、运行资源SHA256和EXE SHA256。基线提交只是导出时HEAD；如果导出包含未提交功能，不能把它当成完整源码版本。运行资源指纹把实际打包的资源区分开，提交/合并后的对应源码由最终交付记录说明。

至少执行：

1. 实际运行导出脚本，确认成功标志、非空exe、说明/元信息和zip，原工程哈希不变。
2. 从构建目录双击EXE，确认进入击杀奖励肉鸽界面，看到生命、敌方血量和分裂选项，而不是旧侧视场景。
3. 空白处真实拖动发射，观察发射计数/冷却；失败后R重开恢复生命和计数。
4. 核对导出程序日志无脚本错误，并可用`PlayABall.exe --headless --quit-after 60`做独立包启动冒烟；这不替代可见窗口检查。
5. 给另一台电脑验证启动、输入、文字、声音和整局流程。当前同机启动成功不等于跨机已经验证。

本次本机2026-10-31生成playaball-planner-20261031-final，约109MB内嵌EXE。首次包实窗启动、拖动发射计数1及R失败重开恢复5/5生命已验证；最终包的运行源资源与首次包逐字节一致，另做最终EXE独立headless启动验证，退出0、无脚本错误。因用户停止桌面控制，不声称最终包新增实窗操作。完整真人通关、音质和另一电脑仍未验收。用户使用说明详见docs/playtest。

## 常见问题

- 提示缺少模板：确认引擎和模板同为4.7.1 stable，不用另一个版本模板硬凑。
- 导出的却是旧实验：不要直接在原工程沿默认主场景导出，使用本脚本的隔离入口流程。
- 无法覆盖exe：旧版可能仍运行；本脚本不覆盖既有构建，换BuildName并关闭无需使用的旧窗口。
- 因BuildName失败：不要传路径或斜杠，脚本只接受构建目录名。
- 单机运行正常但另一机失败：记录Windows/显卡、错误与build_info，不把本机结果推广成所有机器通过。
