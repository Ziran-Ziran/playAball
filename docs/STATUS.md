# 当前状态

更新：2026-11-06。工作分支 `fix/map-blueprints-20261105`，基线 `cfe31a2`。用户已明确授权整理、提交、push和合并；已按[REVIEW](REVIEW.md)完成整批本地核对，结果见[最终Review](reviews/2026-11-06-final-integration.md)；远端CI通过后执行已授权合并。

## 已接入

四图按蓝图修正、瞄准暂停及单体箭头、人物伙伴/分级病毒、连续球体动画、16种成长/28张等级卡图、内容流排版、商店/补给/胜负/重开UI、安全Live2D头身动作、独立图标、用户提供的Let Me Go循环BGM与独立音量/全部静音。

普通checkout缺少私有Live2D时静态回退，所有基础玩法、卡牌与BGM可用。当前用户本机音乐偏好保存了“全部静音”，试听先在设置取消；新机器默认音乐22%。

## 验证与审查

既有完整52套、音乐原生26/headless25、菜单动作166及专项证据分见[音乐验收](reviews/2026-11-06-let-me-go-music.md)、[动画/卡牌/动作](reviews/2026-11-06-smooth-card-menu-actions.md)、[地图/美术与暂停](reviews/2026-11-05-ball-art-and-tactical-aim.md)。本次提交阶段重新运行52套行为检查、8项Python准备工具检查、实际普通导出/PCK探针，均通过；未参与实现的Agent完成整批独立审查，无P1阻塞项。日志仍含下述已知退出警告。远端CI结果以PR记录为准。

文件整理：README/PROJECT/STATUS保留当前事实；原三文档完整内容归入[历史快照](history/development_before_20261106.md)。素材、字体/音源来源与许可文件、Godot导入配置及UID随源码管理；`.local/`、`.godot/`、`builds/`、私有模型/DLL、凭据不入Git。

## 已知限制

- 音乐在进程退出时仍偶发AudioStreamMP3/AudioStreamPlaybackMP3各一份引用警告，独立审查已同机复现；50ms退出回收仅缓解，不是可靠完成确认。目前未见运行中随场景累积，作为非阻塞已知限制保留，不能称彻底修复或全部日志零警告。
- Native完整L0内存、手臂自然度及全部音频后端未完成验证；安卓仍为适配评估。
- 没有真人自然完整通关、难度平衡或全部审美验收结论；自动输入/截图和包探针不替代这些。

## 本机体验包

本机已有 `builds/playaball-let-me-go-live2d-20261106-194509.zip`，含BGM及旁置Live2D。完整解压保留menu_character_runtime；旧包保留。成品不上传源码仓库，不代表公开发行许可已经确认。

## 接手入口

[项目概况](PROJECT.md) · [文件目录](FILE_MAP.md) · [教程040：可选Live2D](tutorials/040-live2d-start-menu.md) · [041：地图](tutorials/041-map-blueprint-correction.md) · [049：卡片](tutorials/049-card-content-flow.md) · [050：动画](tutorials/050-smooth-hero-animation.md) · [051：鼠标动作](tutorials/051-menu-visible-actions.md) · [052：音乐](tutorials/052-persistent-music.md)
