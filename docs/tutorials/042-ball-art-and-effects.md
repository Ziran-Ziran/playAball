# 球体人物、分级病毒与真实事件特效

## 这轮做了什么

主角换成蓝发鲸鱼娘团子球；三个外包伙伴按顺序显示GPT/Claude/千问人物团子；普通敌人与首领换成数字病毒球。角色PNG全部由内置imagegen生成，提示词与指纹见`docs/art/ball_art_r4.json`。参考研究与用户否定机器人候选的取舍见`docs/art/mascot_references_r4.md`。

本篇是美术接线；瞄准静止和箭头动画见[教程043](043-tactical-aim.md)，动态艺术字见[教程044](044-card-typography.md)。没有将样例板直接当游戏画面，也没有因换贴图改变刚体大小。

## 文件和节点

- `ball_art.gd`集中保存七张纹理、透明裁切、伙伴顺序和敌人出生等级映射。PNG位于`assets/roguelite/ball_art_r4/`，旧v1图仍保留。
- `player_ball.tscn → Presentation/Sprite`继续由`fish_ball_view.gd`显示；实际显示最长边58，碰撞半径仍23。
- `companion_ball.gd.presentation_snapshot`新增只读slot；`companion_view.gd`在ready从slot确定GPT/Claude/千问，实际最长边36、碰撞半径14、质量0.65不变。颜色环只表达原有攻击/归队状态，不把整张人物染成青灰色。
- `enemy_view.gd`读取`max_hp`选择低/中/高病毒，读取`hp`画真实剩余生命的绿/黄/紫细环和数字。数字移到身体下沿，保留脸部和轮廓。重型有铆钉、炮台保留实际朝向喷口，三种攻击仍由原规则校验。
- `boss_view.gd`核心使用精英病毒，四个模块使用中档病毒。核心84、模块32的表现尺寸与原有真实模块位置/生命/破坏逻辑保留，金色破防环、冲撞方向和震波缺口不变。
- `virus_burst.gd`只在真实死亡后生成短时数据碎片；`combat_float.gd`继续显示已结算伤害。

## 输入→只读状态→表现

发射成功→主球原`visual_event(launch)`→0.18秒水纹与轻微压缩；速度快时短尾迹跟随真实速度。撞击、回能和伤害仍由原事件触发，不能在鼠标按下时播放“成功命中”。

伙伴生成时，manager先设置slot再add_child；表现ready取得稳定身份。不会因暂停/受击或每一帧随机换一个人物，也不会改变伙伴数量和接力资格。

敌人出生最大生命1/2–3/4–6分别选择低/中/高病毒皮肤；同一敌人掉血时不换身份，仍显示准确HP与原颜色。这样“精英受伤剩1点”仍是受伤精英，不会突然变成新刷的小怪。

死亡规则发出died→独立碎片组件创建，最多12组、0.32秒后释放；普通未击破受伤只显示真实有效伤害浮字。碎片/浮字显式使用PAUSABLE，因为正式Run父节点是ALWAYS，依赖继承会导致瞄准时它们继续移动。取消瞄准后按剩余寿命继续，不重放死亡或伤害。

## 如何调与扩展

主角/伙伴Presentation检查器的`sprite_extent`只改Sprite尺寸，不能缩放PlayerBall或修改Shape。美术形变只放Sprite/绘图局部变换，物理根节点保持Vector2.ONE。

新图透明留白、PNG尺寸和导入size_limit可能不同，因此`DemoBallArt.region_for()`从实际导入纹理的alpha边界取裁切，并按纹理实例缓存；`rect_for()`等比适配目标最长边，不能用源1280像素裁切512导入图。导入配置为mipmap开启、size_limit512，适合58/36等小尺寸显示。

增加同伴时先在素材字典加入新id，再明确slot映射；不要随机重抽。改等级阈值只改表现映射并同步本篇，不要顺手改敌人HP或伤害。若新增敌人攻击角色，保留原预警/朝向可读性，再设计相应外观。

箭头动画和静止由教程043的共享绘制与暂停接口控制；卡片标题仍是真实动态字体，不能将所有数值烘焙进生图。

## 验证与限制

执行`tools/verify.ps1 -GodotExe <本机Godot4.7.1路径>`。新增`roguelite_ball_art.gd`覆盖透明通道、真实导入裁切、三同伴身份、三角色×三等级的皮肤、受伤身份稳定与物理不变。暂停碎片回归在ALWAYS父节点下先失败，再设置PAUSABLE后通过；独立验收还覆盖真实死亡、数量上限与清理。

定向回归还应包含fish_view、actor_views、enemy_readability、presentation_interface、feedback_integration、boss及tactical_aim。截图与输入夹具输出在`.local/art_pass_20261105/`，正式Game的58/36像素画面与卡片两种分辨率另行目视检查。自动检查只证明技术接线与规则边界，不替代用户审美、自然Boss战或完整整局试玩。
