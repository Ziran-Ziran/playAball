# 三人 Git 公约

记住一句话：**先同步 → 开分支 → 做一件事 → 验证和写教程 → 提 PR → 另一人检查 → 合并。**

## 第一次

各自使用自己的 GitHub 账号；仓库所有者在 Settings → Collaborators 邀请另外两人。各电脑分别配置本人的提交姓名和邮箱（建议 GitHub noreply 邮箱）。不要共用密码或上传 Token。

```sh
git clone https://github.com/Ziran-Ziran/playAball.git
cd playAball
git config user.name "你的名字"
git config user.email "你自己的邮箱"
```

## 每天做任务

先检查有无未保存修改，有修改就先提交到原任务分支，再切换。

```sh
git status
git switch main
git pull --ff-only
git switch -c feat/short-task-name
# 开发、测试、更新教程和 docs/STATUS.md
git diff
git add 本次改动的文件
git commit -m "feat: 增加力度预览"
git push -u origin feat/short-task-name
```

在 GitHub 点击 Compare & pull request。PR = 请别人检查后再放进主版本。另一位开发者读代码/教程并运行 F5；检查通过后使用 **Squash and merge**，删除远端任务分支。同步 main 后再开下一个分支。不另设 develop 分支。

分支前缀只用 `feat/`（新功能）、`fix/`（修错）、`docs/`（文档）。提交前缀用 `feat:`、`fix:`、`docs:`、`chore:`。每次提交只表达一个清楚的目的，不追求复杂格式。

## 避免冲突

- 开工前在 Issue 留一句“我改哪些文件”。两位程序尽量改不同模块，避免同时编辑同一个 `.tscn`。
- 二进制图片/音频不要两人同时修改；大素材先沟通，再决定 Git LFS。
- 冲突时先保留自己的分支，与另一人确认内容，解决后重新试玩；新手可请 Agent 解释冲突。不要用 `reset --hard` 或 force push 图省事。
- `main` 不直接开发。仓库首次初始化阶段提交是例外；以后通过 PR。

## GitHub 设置

建议维护者设置 main 分支保护：必须 PR、至少 1 人批准、必须通过 `Godot checks / smoke`、禁止 force push 和删除主分支。CI 首次运行后再选取该检查名称。公开仓库不等于允许他人使用你们的美术和代码；本项目尚未授予开源许可证，需要团队明确选择后再添加 LICENSE。
