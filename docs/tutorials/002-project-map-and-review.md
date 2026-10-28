# 教程 002：目录如何保持最新，Review 如何落地

## 为什么多了两个文件

`docs/FILE_MAP.md` 是给人和 AI 看的树；`docs/file_purposes.json` 是你手工填写“这个文件干什么”的说明表。`tools/project_map.gd` 用 Git 找到实际文件，把两者组合成目录。这样不用手工敲树枝，也不会忘记新文件。

它不是监听磁盘的后台程序。“实时”是每次增删、改名或职责变化时同步更新，并在本机验证/CI 拦住过期目录。保存文件后不会自动偷偷运行 Git 或提交。

## 数据怎么流动

1. 工具运行 `git ls-files --cached --others --exclude-standard`，包含已跟踪文件及尚未提交的新文件，遵守 `.gitignore`。
   为兼容 Windows 输出编码，Git 先输出 ASCII 引号/八进制转义，工具再还原 UTF-8 路径，避免漏掉中文文件名。
2. 过滤已经删除的文件并去重。文件说明来自 JSON 中 `files`，目录说明来自 `directories`；`.gd.uid` 和 `.import` 有通用说明。
3. 若任何文件缺少用途、或用途表保留了已删除文件，返回失败；不会悄悄写“未知文件”。
4. 递归按目录优先、名称排序生成树。`--write` 写入目录；`--check` 只比较，不改文件，发现树过期就返回非零。
5. Windows `verify.ps1` 与 Linux CI 在行为测试前运行 `--check`，同时检查退出码与日志完成标志。主架构关系摘要位于生成器中，需要人为复核。

只使用项目已有的 Godot 和 Git；无需额外 Python/Node 或插件。

## 新加文件时怎么做

假设新增 `scripts/goal.gd`，打开 `docs/file_purposes.json`，在 `files` 中增加：

```json
"scripts/goal.gd": "管理目标的可视外观、球进入判定与胜利信号。"
```

注意 JSON 条目之间要有逗号。改名时同步改键，删除文件时删掉对应条目；只改变职责也要改说明。新增目录可以在 `directories` 加一句用途。`.gd.uid` 由 Godot 维护，不必逐个写说明。不要把缓存/凭据加进目录或 Git。

在项目根目录执行（godot 替换为本机可执行文件）：

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tools/project_map.gd -- --write
godot --headless --path . --script tools/project_map.gd -- --check
```

先导入是为了让 Godot 为新增脚本生成 `.gd.uid`，再生成树，避免刚生成的 UID 使目录立刻过期。文档目录有 `.gdignore`，配图不会被当成游戏资源导入。

Windows 没有 PATH 命令时，使用 `& 'Godot实际绝对路径'` 代替 godot。若 PowerShell 对 GUI 程序不等待，以 `tools/verify.ps1` 的 Start-Process 等待方式读取日志与退出码；不要把控制台暂时没输出当成功。

生成后打开 FILE_MAP，确认用途讲得对。通过检查只证明清单完整、树匹配，不能证明说明的语义正确。随后运行：

```powershell
./tools/verify.ps1 -GodotExe 'Godot实际绝对路径'
```

新工具没有游戏检查器参数；改用途改 JSON，改树格式/主要关系改生成器，改验证顺序改 verify.ps1 和 godot.yml 两处。

## Review 到底看什么

例子：做“目标独立场景”。实现后，先检查目标外观和碰撞是否一起移动，测试进球/重复进入/重置，再写面向人的操作教程，更新用途和目录。交给独立审查者时提供需求、本轮差异、新文件、验证命令与未测项，不只说“帮我看看”。

审查者要看代码与功能，也要打开教程和目录；发现阻塞问题，修复并复测后请其复核。完整清单见 [Review 流程](../REVIEW.md)，不要维护另一套重复规则。

最后由你决定是否提交：`commit` 是把已选文件保存为本机版本，`push` 才是上传远端。你说“先 commit 不 push”，Agent 就只能本地保存；你没回答，Agent 留着工作区即可。上传后 CI 结果仍需再次检查。

## 常见问题

- “缺少文件用途”：补 JSON，不要为了通过检查把源文件加入 .gitignore。
- “存在已删除/改名文件”：确认删除是否有意，再同步清单。
- “FILE_MAP 已过期”：先 --write，再 --check。
- “JSON 格式错误”：检查逗号、双引号；不要写注释或尾逗号。
- 树不列出 `.godot/`：正常，这是可重建缓存。
- 生成后又新增了文件：再生成一次，最终以 Review 时的工作区为准。
