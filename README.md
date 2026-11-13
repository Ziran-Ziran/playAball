# 玩个球 / playAball

俯视2D物理碰撞游戏：反向拖拽发射肥鱼球，撞击敌人、培养伙伴，经过三个阶段与Boss关。

Windows和安卓安装包、校验与已知限制见[GitHub Releases](https://github.com/Ziran-Ziran/playAball/releases)。文件整理和发布维护见[教程063](docs/tutorials/063-cleanup-and-public-release.md)。

## 运行

使用 **Godot 4.7.1 stable 标准版、Compatibility** 打开 `project.godot`，按 **F5** 进入主菜单。源码包含地图、美术、卡牌和用户提供的背景音乐。

Live2D是可选本机组件，模型、Native DLL和SDK资源不在仓库。未准备私有资源时菜单使用静态角色，游戏仍能正常开始；已有本机资源的准备方法见[教程040](docs/tutorials/040-live2d-start-menu.md)。

| 操作 | 作用 |
| --- | --- |
| 空白处按住左键，向目标反方向拖动 | 瞄准；就绪时战场静止，保留决策时间 |
| 松开左键 / 右键 | 发射 / 取消瞄准 |
| Esc | 暂停、音量设置、重开或回菜单 |
| 主菜单“设置” / 暂停菜单“音乐” | 调整主音量、音乐与全部静音；偏好跨版本保留 |

主菜单角色的头顶、左右脸、上半身、三连点和头发拖抚绑定不同动作；界面有操作指南，详见[教程051](docs/tutorials/051-menu-visible-actions.md)。

## 当前内容

- 四张地图：固定/翻转挡板、移动刺板、旋转缺口弧与两组同色传送门，见[地图041](docs/tutorials/041-map-blueprint-correction.md)。
- 肥鱼与三只AI伙伴、分级病毒外观、连续呼吸/碰撞/受伤/击破反馈，见[角色042](docs/tutorials/042-ball-art-and-effects.md)、[动画050](docs/tutorials/050-smooth-hero-animation.md)。
- 16种成长、28张等级卡图，商店/补给、胜负重开；卡牌以真实文字高度排版，见[卡片037](docs/tutorials/037-integrated-upgrade-cards.md)、[布局049](docs/tutorials/049-card-content-flow.md)。
- 深代接力/爆破与撞杀余势、后段金币整备；每局3次递增费用重选，同发直撞3个不同敌人返还已有冷却，见[策略056](docs/tutorials/056-strategy-payoff.md)、[重选060](docs/tutorials/060-rerolls-and-precision-chain.md)。
- 单体素材瞄准箭头与全场瞄准暂停，见[教程043](docs/tutorials/043-tactical-aim.md)。
- DS鲸鱼娘人物双栏设置/暂停、蓝白弹窗与成长卡，内置生图人物八帧、音量百分比和减少动态；[第二轮](docs/tutorials/054-ds-character-ui.md)、[已选蓝白方向的商店/结算精修](docs/tutorials/055-light-ui-refinement.md)。
- 用户提供的《Let Me Go（共创版）》循环BGM，跨菜单/战斗连续播放，见[音乐052](docs/tutorials/052-persistent-music.md)及[来源](assets/music/SOURCE.md)。
- Windows鼠标与安卓原生单指拖拽、取消/系统返回/后台暂停，独立PNG/ICO及DS安卓分层图标；已完成模拟器验证，ARM真机性能仍未验收，见[平台058](docs/tutorials/058-mobile-input-and-release.md)。
- 构筑状态和真实策略兑现提示、窄屏补给/卡片滚动、设置内离线可读制作与许可；[表现057](docs/tutorials/057-build-feedback-and-supply.md)、[发布打包061](docs/tutorials/061-release-packaging.md)。

技术检查不等于真人自然整局或审美验收。音乐退出时仍偶发两个MP3引用警告，当前未观察到运行中跨场景累积，详见[状态](docs/STATUS.md)。

## 验证与导出

```powershell
# 用当前机器已核实的Godot 4.7.1绝对路径设置$GodotExe。
./tools/verify.ps1 -GodotExe $GodotExe
python -X utf8 -m unittest discover -s tests -p test_prepare_menu_live2d.py
./tools/export_windows.ps1 -GodotExe $GodotExe -BuildName my-windows-build
```

导出需安装同版Windows模板。普通导出包含BGM与图标，不携带私有Live2D；已有本机资源的独立体验包见[教程040](docs/tutorials/040-live2d-start-menu.md)的Release说明。成品位于忽略的 `builds/`，日志/预览位于 `.local/`，引擎缓存位于 `.godot/`。

正式Windows可用`-Live2DRuntime`新增旁置接线并保留模型原字节；安卓使用`tools/export_android.ps1`和本机SDK/JDK/签名身份。两平台release构建及署名说明见[061](docs/tutorials/061-release-packaging.md)，公开分发音乐和本轮Live2D许可已由用户确认。构建通过不替代真人自然通关或全部机型验收。

开发场景可F6独立运行：`run.tscn`整局、`gameplay_lab.tscn`玩法实验室、`tuning_run.tscn`调参、`card_art_gallery.tscn`卡面图鉴，均在 `scenes/roguelite/`。

## 开发入口

[项目概况](docs/PROJECT.md) · [当前状态](docs/STATUS.md) · [文件目录](docs/FILE_MAP.md) · [协作规则](AGENTS.md) · [Git公约](CONTRIBUTING.md) · [最终Review](docs/REVIEW.md)

[双线分工](docs/plans/008-parallel-development.md) · [新开发者入门](docs/onboarding/DEVELOPER.md) · [整理前历史快照](docs/history/development_before_20261106.md)
