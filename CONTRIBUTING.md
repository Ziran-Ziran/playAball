# 三人 Git 公约

记住一句话：**先同步 → 开分支开发 → 开发者认为基本完成 → Git 前最终 Review → 用户授权提交和上传 → PR / CI → 合并。**

## 第一次

各自使用自己的 GitHub 账号；仓库所有者在 Settings → Collaborators 邀请另外两人。各电脑分别配置本人的提交姓名和邮箱（建议 GitHub noreply 邮箱）。不要共用密码或上传 Token。

```sh
git clone https://github.com/Ziran-Ziran/playAball.git
cd playAball
git config user.name "你的名字"
git config user.email "你自己的邮箱"
```

## 每天做任务

先检查有无未保存修改。有修改先确认来源，保留并让作者决定如何保存；Agent 不得自动提交或覆盖它们。本轮授权规则见下文。

```sh
git status
git switch main
git pull --ff-only
git switch -c feat/short-task-name
# 开发过程中按需局部检查；开发者准备提交时，统一做最终 Review
# 最终核对测试、教程、FILE_MAP 和 STATUS
git diff
```

**Agent 此时必须先汇报 Review、测试、教程和目录结果，询问用户是否 commit、是否 push。用户明确同意对应动作后，才运行：**

若用户已经明确授权“检查无误后 commit/push”，最终 Review 通过即执行，不重复询问。最终 Review 不随每次少量代码修改触发，开发中的小范围 Review 另行按需进行。

```sh
# 用户授权 commit 后；只暂存本次审查通过的文件
git add 本次改动的文件
git commit -m "feat: 增加力度预览"
# 用户另外授权 push 后（也可同时授权 commit 和 push）
git push -u origin feat/short-task-name
```

在 GitHub 点击 Compare & pull request。PR 是把本次改动汇总到主分支前的检查入口。同伴可参与审查，但不强制另一个 GitHub 账号批准。最终 Review 与 CI 通过并获得合并授权后，可由 owner 使用 **Squash and merge** 合并自己的 PR；远端任务分支自动删除。同步 main 后再开下一个分支。不另设 develop 分支。

Agent 不得把初始化时的上传授权沿用到新任务。“可以提交”不等于“可以上传”。创建 PR、合并也需明确授权；没有回答就保留本地修改。正常 Review 流程见 [Review 与测试](docs/REVIEW.md)。

分支前缀只用 `feat/`（新功能）、`fix/`（修错）、`docs/`（文档）。提交前缀用 `feat:`、`fix:`、`docs:`、`chore:`。每次提交只表达一个清楚的目的，不追求复杂格式。

## 避免冲突

- 开工前在 Issue 留一句“我改哪些文件”。两位程序尽量改不同模块，避免同时编辑同一个 `.tscn`。
- 二进制图片/音频不要两人同时修改；大素材先沟通，再决定 Git LFS。
- 冲突时先保留自己的分支，与另一人确认内容，解决后重新试玩；新手可请 Agent 解释冲突。不要用 `reset --hard` 或 force push 图省事。
- `main` 不直接开发。仓库首次初始化阶段提交是例外；以后通过 PR。

## GitHub 设置

已设置 main 分支保护：必须 PR、必须通过 `smoke`（工作流名 Godot checks）、分支保持最新、解决审查对话，禁止 force push 和删除主分支，管理员也适用。**不强制另一位 GitHub 用户批准**（required approving reviews = 0）；代码最终 Review 仍按项目流程执行。仓库仅允许 Squash 合并，合并后自动删除远端任务分支。

公开仓库不等于允许他人使用你们的美术和代码；本项目尚未授予开源许可证，需要团队明确选择后再添加 LICENSE。

## 两位开发者分工

文件职责、共享接口与S0～S4顺序见[计划008](docs/plans/008-parallel-development.md)，操作见[教程020](docs/tutorials/020-parallel-workflow.md)。仓库owner始终为用户，可兼任A，最终审阅与合并权不随A角色分配转移；B负责玩法/实验室和集成协调，不因协调获得长期merge权限。各自独立checkout和feat/分支，从同一已核验基线开始；当前混合文件先登记唯一写入者，必要拆分后再全面并行。
