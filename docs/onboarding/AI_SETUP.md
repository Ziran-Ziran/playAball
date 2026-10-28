# 给另一台电脑上的 AI

请在克隆的 playAball 根目录开始，先完整阅读 `AGENTS.md`，再读 README、项目概况、状态和 Git 公约。以下是接手指令，不代表你电脑的现有配置。

## 必须检查并补齐

1. 只读确认当前主机名、OS、用户和工作目录。不要把 `LAPTOP-8GS4N5SG` 或 `C:/Users/Ziran` 当作当前电脑。
2. 检查 Git 的版本和实际路径；缺少时安装适合本 OS 的 Git。验证 `git --version`，提交姓名和邮箱必须属于当前开发者。
3. 安装/定位 **Godot 4.7.1 stable 标准版**，用 `--version` 验证。无需 .NET、Python、付费插件或独立物理引擎；导出游戏时才需要同版本 export templates。
4. 确认当前开发者可访问 `https://github.com/Ziran-Ziran/playAball`；公开仓库可直接克隆，推送需要所有者邀请其 GitHub 账号成为 collaborator。让用户自行完成登录，不复制另一台电脑的凭据。
5. 在 Godot 导入 `project.godot` 并 F5。按 `tools/verify.ps1`（Windows）或下方 CLI（其他系统）验证。确认教程文档可阅读。

## Agent / MCP 补齐清单

- 必需：一个能读写仓库并运行本机命令的 Agent。遵守根目录 AGENTS.md。无需安装整套技能才能开发。
- 推荐的知识技能：`godot-gdscript-patterns`；缺少时可参考 Godot 官方 4.7 文档，不阻塞游戏运行。
- **可选** Godot MCP：初始电脑使用 `@yanhuifair/godot-mcp` **1.9.0**，Node.js 要求 ≥18；安装时选仍受维护的 Node LTS。参考该包随附 README 核对参数。没有 MCP 时直接编辑 `.gd/.tscn` 并用 CLI 验证。
- MCP 配置必须使用此电脑的实际路径。初始电脑的 MCP 原来指向另一个项目 xplore，不能沿用，也不能只因工具可调用就相信它操作的是本项目。

可选安装命令（先确认已有 Node/npm）：
```sh
npm install -g @yanhuifair/godot-mcp@1.9.0
```

在当前 Agent 的 MCP 设置中添加 stdio server：command 为实际 `node` 可执行文件；args 为实际安装包下的 `dist/index.js`、`-p`、本仓库绝对路径、`-g`、本机 Godot 绝对路径。用 `npm root -g` 定位包；不要复制初始电脑的全局路径。个人配置不提交 Git。

本项目当前没有嵌入 MCP 编辑器插件。文件类工具不需要插件。若团队决定使用实时编辑器/游戏桥接，再依据包内 README 安装 `addons/godot-mcp`，评估随附许可证并单独提交对应工程变化；不要每台电脑自行向共享工程加不同插件。桥接需核对实际项目路径，避免连到另一个已打开的 Godot 实例。

## 验证和回报

Windows：
```powershell
./tools/verify.ps1 -GodotExe '本机Godot可执行文件绝对路径'
```

macOS/Linux（将 godot 替换为实际可执行文件）：
```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/smoke.gd
```

必须检查日志无 SCRIPT ERROR/ERROR，smoke 输出 ALL CHECKS PASSED，退出码 0。然后手动试玩发射、R、机关切换。向开发者用短清单回报：设备；Git/Godot 路径与版本；GitHub 推送权限；MCP 已配置/未配置（可选）；测试结果和仍需人工完成的步骤。不要安装无关插件，不向聊天输出凭据。
