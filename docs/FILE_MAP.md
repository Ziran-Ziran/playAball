# 项目文件目录

由 `tools/project_map.gd` 根据 Git 可见文件与 `docs/file_purposes.json` 生成。请修改用途清单后重新生成，不直接编辑此树。

覆盖已跟踪文件及未忽略的新文件；不包含 `.git/`、`.godot/`、`.local/` 等本机缓存。新增、删除、改名或职责变化后立即更新，交付前和 CI 检查是否过期。

```text
playAball/
├── .github/  # GitHub 协作模板与自动检查
│   ├── workflows/  # 提交/PR 触发的持续集成
│   │   └── godot.yml  # Linux固定引擎导入、目录、物理/UI/经营/移动暂停行为回归与可选菜单回退配置。
│   └── pull_request_template.md  # PR 的改动、测试、Review、教程和目录核对模板。
├── assets/  # 运行素材
│   ├── cards/  # 正式HUD与独立图鉴使用的成长插画候选/历史母版，审美状态与技术接线分开
│   │   ├── release_r5/  # 与实际GPT、Claude、Qwen伙伴身份一致的三等级外包卡新插画及生成来源。
│   │   │   ├── SOURCE.md  # 三张真实伙伴身份外包卡的新生成来源、参考与原图历史保留说明。
│   │   │   ├── companion_lv1.png  # 内置生成第1级外包卡：DS与白发薄荷GPT，修正原DS分身对实际伙伴的误导。
│   │   │   ├── companion_lv1.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── companion_lv2.png  # 内置生成第2级外包卡：DS与GPT及杏发Claude，修正原DS分身对实际伙伴的误导。
│   │   │   ├── companion_lv2.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── companion_lv3.png  # 内置生成第3级外包卡：DS与GPT、Claude及紫发Qwen，修正原DS分身对实际伙伴的误导。
│   │   │   ├── companion_lv3.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   └── generation.json  # 三等级外包卡完整提示、人物参考、生成输出尺寸与SHA256。
│   │   ├── bowling_lv1.png  # 内置image_gen成长插画：bowling，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── bowling_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── choices_lv1.png  # 内置image_gen成长插画：choices，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── choices_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── companion_lv1.png  # 内置image_gen成长插画：companion，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── companion_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── companion_lv2.png  # 内置image_gen成长插画：companion，第2级；正式HUD显示下一等级，审美待用户验收
│   │   ├── companion_lv2.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── companion_lv3.png  # 内置image_gen成长插画：companion，第3级；正式HUD显示下一等级，审美待用户验收
│   │   ├── companion_lv3.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── cooldown_lv1.png  # 内置image_gen成长插画：cooldown，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── cooldown_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── cooldown_lv2.png  # 内置image_gen成长插画：cooldown，第2级；正式HUD显示下一等级，审美待用户验收
│   │   ├── cooldown_lv2.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── cooldown_lv3.png  # 内置image_gen成长插画：cooldown，第3级；正式HUD显示下一等级，审美待用户验收
│   │   ├── cooldown_lv3.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── cooldown_lv4.png  # 内置image_gen成长插画：cooldown，第4级；正式HUD显示下一等级，审美待用户验收
│   │   ├── cooldown_lv4.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── double_launch_lv1.png  # 内置image_gen成长插画：double_launch，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── double_launch_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── echo_lv1.png  # 内置image_gen成长插画：echo，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── echo_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── explosion_lv1.png  # 内置image_gen成长插画：explosion，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── explosion_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── follow_lv1.png  # 内置image_gen成长插画：follow，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── follow_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── glide_lv1.png  # 内置image_gen成长插画：glide，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── glide_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── glide_lv2.png  # 内置image_gen成长插画：glide，第2级；正式HUD显示下一等级，审美待用户验收
│   │   ├── glide_lv2.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── glide_lv3.png  # 内置image_gen成长插画：glide，第3级；正式HUD显示下一等级，审美待用户验收
│   │   ├── glide_lv3.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── heal_repeat.png  # 内置image_gen成长插画：heal，重复共用；正式HUD显示下一等级，审美待用户验收
│   │   ├── heal_repeat.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── heavy_lv1.png  # 内置image_gen成长插画：heavy，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── heavy_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── heavy_lv2.png  # 内置image_gen成长插画：heavy，第2级；正式HUD显示下一等级，审美待用户验收
│   │   ├── heavy_lv2.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── heavy_lv3.png  # 内置image_gen成长插画：heavy，第3级；正式HUD显示下一等级，审美待用户验收
│   │   ├── heavy_lv3.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── launch_power_lv1.png  # 内置image_gen成长插画：launch_power，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── launch_power_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── launch_power_lv2.png  # 内置image_gen成长插画：launch_power，第2级；正式HUD显示下一等级，审美待用户验收
│   │   ├── launch_power_lv2.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── launch_power_lv3.png  # 内置image_gen成长插画：launch_power，第3级；正式HUD显示下一等级，审美待用户验收
│   │   ├── launch_power_lv3.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── pulse_lv1.png  # 内置image_gen成长插画：pulse，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── pulse_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── relay_lv1.png  # 内置image_gen成长插画：relay，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── relay_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── shrink_lv1.png  # 内置image_gen成长插画：shrink，第1级；正式HUD显示下一等级，审美待用户验收
│   │   ├── shrink_lv1.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── shrink_lv2.png  # 内置image_gen成长插画：shrink，第2级；正式HUD显示下一等级，审美待用户验收
│   │   ├── shrink_lv2.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   │   ├── vigor_repeat.png  # 内置image_gen成长插画：vigor，重复共用；正式HUD显示下一等级，审美待用户验收
│   │   └── vigor_repeat.png.import  # 同名卡面Godot纹理导入配置，mipmap开启、512尺寸限制，原始1536×1024源图保留
│   ├── fonts/  # 随工程分发的字体及来源许可
│   │   ├── noto_sans_sc/  # 随包的OFL中文fallback字体，补齐安卓全角标点与符号。
│   │   │   ├── NotoSansSC.ttf  # Google Fonts官方未修改Noto Sans SC可变字体，为菜单和共享主题显式补齐安卓标点。
│   │   │   ├── NotoSansSC.ttf.import  # 同名素材的Godot导入配置，随源码保留并使用明确资源预算。
│   │   │   ├── OFL.txt  # Noto Sans SC随包SIL OFL 1.1原始许可全文。
│   │   │   └── SOURCE.md  # Noto字体官方来源、实际字节/哈希与作为fallback的用途。
│   │   └── zcool_kuaile/  # 官方OFL站酷快乐体，用于动态中文卡片艺术标题
│   │       ├── OFL.txt  # 站酷快乐体原始SIL Open Font License，随字体分发保留
│   │       ├── SOURCE.txt  # 字体官方来源与下载记录
│   │       ├── ZCOOLKuaiLe-Regular.ttf  # Google Fonts官方站酷快乐体，用于真实动态中文艺术标题
│   │       └── ZCOOLKuaiLe-Regular.ttf.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   ├── music/  # 用户提供的背景音乐原音频及来源说明
│   │   ├── SOURCE.md  # 用户提供音频的原文件名、歌曲来源、SHA256与使用边界记录
│   │   ├── let_me_go.mp3  # 用户提供的Let Me Go共创版原MP3，字节不变，用作本机体验背景音乐
│   │   └── let_me_go.mp3.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   ├── roguelite/  # 正式游戏实体独立美术资源
│   │   ├── ball_animation_r5/  # 项目子目录
│   │   │   ├── generation.json  # 四张内置生成图集的提示词、引用与透明规格
│   │   │   ├── hashes.json  # 四张生成动画图集的SHA256完整性记录
│   │   │   ├── hero_sheet.png  # 内置生图主角四格透明姿势：长圆、扁圆、碰撞与痛脸
│   │   │   ├── hero_sheet.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── virus_high_sheet.png  # 内置生图高级病毒受击、反弹、裂壳与碎片四格
│   │   │   ├── virus_high_sheet.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── virus_low_sheet.png  # 内置生图低级病毒受击、反弹、裂壳与碎片四格
│   │   │   ├── virus_low_sheet.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── virus_mid_sheet.png  # 内置生图中级病毒受击、反弹、裂壳与碎片四格
│   │   │   └── virus_mid_sheet.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   ├── ball_art_r4/  # 内置生图的鲸鱼娘与AI人物团子、分级病毒透明素材
│   │   │   ├── claude.png  # 内置imagegen透明素材：杏色卷发Claude人物团子与小Clawd发饰，审美以用户反馈为准
│   │   │   ├── claude.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── gpt.png  # 内置imagegen透明素材：白发薄荷斗篷GPT人物团子，审美以用户反馈为准
│   │   │   ├── gpt.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── hero.png  # 内置imagegen透明素材：蓝发鲸鱼娘主角团子，审美以用户反馈为准
│   │   │   ├── hero.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── qwen.png  # 内置imagegen透明素材：紫发云纹千问人物团子与小几何发饰，审美以用户反馈为准
│   │   │   ├── qwen.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── virus_high.png  # 内置imagegen透明素材：数字冠与分节外壳高级病毒，审美以用户反馈为准
│   │   │   ├── virus_high.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── virus_low.png  # 内置imagegen透明素材：光滑短触角低级病毒，审美以用户反馈为准
│   │   │   ├── virus_low.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   │   ├── virus_mid.png  # 内置imagegen透明素材：四短刺装甲中级病毒，审美以用户反馈为准
│   │   │   └── virus_mid.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │   └── presentation/  # 生图透明实体素材与生成来源，不改变碰撞形状
│   │       ├── fat_fish_ball_v1.png  # 内置生图制作的透明肥鱼主球，真实Sprite接入
│   │       ├── fat_fish_ball_v1.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │       ├── fragile_crate_v1.png  # 内置生图制作的透明箱子，敌人表现按真实HP染色
│   │       ├── fragile_crate_v1.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │       ├── generation_metadata.json  # 四张实际位图的完整最终提示词、原始来源和审批边界
│   │       ├── heavy_shell_v1.png  # 内置生图的圆形重型/首领共用透明装甲，保留物理轮廓与真实状态染色
│   │       ├── heavy_shell_v1.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   │       ├── turret_base_v1.png  # 内置生图的三角炮台透明底座，炮管仍按真实方向独立绘制
│   │       └── turret_base_v1.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│   └── ui/  # 用户认可的第一批UI素材；从文档样板复制用于运行
│       ├── aim_kenney/  # 按用户最新反馈选用的Kenney CC0单体指向/尾流素材及来源记录
│       │   ├── KENNEY_PARTICLE_LICENSE.txt  # 粒子包自带的原始Kenney CC0许可与作者信息
│       │   ├── SOURCE.md  # Kenney箭头/粒子许可页面核查、来源和本轮取舍说明
│       │   ├── light_03.png  # Kenney Particle Pack CC0能量环原始PNG，用于轻微滑动亮点
│       │   ├── light_03.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│       │   ├── navigation_e.png  # Kenney Cursor Pack CC0导航单体箭头原始PNG，用于风格对照
│       │   ├── navigation_e.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│       │   ├── pointer_toon_a.png  # Kenney Cursor Pack CC0圆角单体箭头原始PNG，默认瞄准头
│       │   ├── pointer_toon_a.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│       │   ├── sources.json  # 两套素材的官方页面、固定镜像版本、逐文件原始URL与SHA256
│       │   ├── trace_06.png  # Kenney Particle Pack CC0柔和光带原始PNG，用于低透明尾流
│       │   └── trace_06.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│       ├── app_icon/  # 项目子目录
│       │   ├── ANDROID_SOURCE.md  # DS安卓自适应前景/背景的生成来源与实际alpha安全区核验边界。
│       │   ├── SOURCE.md  # 应用图标来源、生成方式和ICO更新说明
│       │   ├── android_background.svg  # 项目编写的432像素纯深蓝安卓自适应图标背景。
│       │   ├── android_background.svg.import  # 同名素材的Godot导入配置，保留明确显示尺寸与透明处理。
│       │   ├── android_foreground.png  # 内置生成留足透明边距的DS鲸鱼娘抱饭碗安卓自适应与单色轮廓前景。
│       │   ├── android_foreground.png.import  # 同名素材的Godot导入配置，保留明确显示尺寸与透明处理。
│       │   ├── android_generation.json  # 安卓人物前景的完整内置提示、参考、SHA256与安全圆alpha实测。
│       │   ├── playaball.ico  # 由原画生成的16至256像素七尺寸Windows导出图标
│       │   ├── playaball.png  # 内置生图独立肥鱼应用图标原画，项目与窗口使用
│       │   └── playaball.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│       ├── build_feedback/  # 蓝白策略兑现四格图集与完整生成来源。
│       │   ├── SOURCE.md  # 策略徽记的内置生成方式、角色边界、透明与真实状态显示说明。
│       │   ├── generation.json  # 四格策略徽记完整提示词、实际尺寸、输出标识与SHA256。
│       │   ├── strategy_badges.png  # 内置生成透明四格蓝白徽记：接力、病毒爆破、余势、饭碗整备。
│       │   └── strategy_badges.png.import  # 同名素材的Godot导入配置，保留透明、滤波与明确运行尺寸预算。
│       ├── ds_console/  # 项目子目录
│       │   ├── SOURCE.md  # DS鲸鱼娘UI第二轮内置生图来源、技术规格与拒绝旧动物鱼候选记录。
│       │   ├── button.png  # 由按钮母图技术裁切/缩小的运行九宫格底图。
│       │   ├── button.png.import  # 同名DS主题UI素材的Godot纹理导入配置。
│       │   ├── button_source.png  # 内置生图哑光蓝矩形按钮透明母图。
│       │   ├── button_source.png.import  # 同名DS主题UI素材的Godot纹理导入配置。
│       │   ├── ds_maid_frames.png  # 参考已认可DS鲸鱼娘人物的内置生图八帧RGBA，禁止普通鱼替代。
│       │   ├── ds_maid_frames.png.import  # 同名DS主题UI素材的Godot纹理导入配置。
│       │   ├── generation.json  # 第二轮人物八帧/浅色面板/按钮/背景编辑的完整内置生图提示词、参考与指纹。
│       │   ├── menu_room.png  # 内置修图移除原菜单背景动物鱼鲸和独立鲸尾标记，保留原室内构图。
│       │   ├── menu_room.png.import  # 同名DS主题UI素材的Godot纹理导入配置。
│       │   ├── panel.png  # 内置生图并透明修边的浅蓝白面板，九宫格底图。
│       │   ├── panel.png.import  # 同名DS主题UI素材的Godot纹理导入配置。
│       │   ├── result_generation.json  # 蓝白第三轮胜利/重试人物的完整内置生图提示词、参考与指纹。
│       │   ├── result_retry.png  # 内置生图DS鲸鱼娘抱碗休息透明插画，用于重试结算。
│       │   ├── result_retry.png.import  # 同名结算人物纹理的Godot导入配置。
│       │   ├── result_victory.png  # 内置生图DS鲸鱼娘庆祝透明插画，用于真实胜利结算。
│       │   └── result_victory.png.import  # 同名结算人物纹理的Godot导入配置。
│       ├── arena_skin.png  # 用户认可的暗绿薄墙全景生图；正式运行仅裁取无字地面和四边墙纹理。
│       ├── arena_skin.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_exit_button_full.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_exit_button_full.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_menu_background.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_menu_background.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_menu_character.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_menu_character.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_menu_title.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_menu_title.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_settings_button_full.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_settings_button_full.png.import  # UI贴图导入配置，由Godot维护。
│       ├── fat_fish_start_button_full.png  # 第一批生图UI运行贴图。
│       ├── fat_fish_start_button_full.png.import  # UI贴图导入配置，由Godot维护。
│       ├── health_skin.png  # 已生成红格HUD原图；正式Atlas裁取十字/红格/空格/金币/暂停等，不使用示例数字。
│       ├── health_skin.png.import  # UI贴图导入配置，由Godot维护。
│       ├── panel_base.png  # 已生成无字通用面板，Atlas去透明边距后用于暂停、选卡、商店与事件。
│       ├── panel_base.png.import  # UI贴图导入配置，由Godot维护。
│       ├── upgrade_card_frame_v2.png  # 第一批生图UI运行贴图。
│       └── upgrade_card_frame_v2.png.import  # UI贴图导入配置，由Godot维护。
├── docs/  # 项目现状、设计、教程与协作说明
│   ├── art/  # 视觉方向样板与用户反馈记录，未获认可的样板不用于全面替换
│   │   ├── ball_art_r4.json  # 七张内置生图透明角色的完整提示词、路径、来源输出与SHA256
│   │   ├── card_briefs_r3.md  # 用户同质化反馈后的28张逐卡叙事/机位/受力/规则约束与先描述后生成规范
│   │   ├── fat_fish_exit_button_full.png  # 与开始同风格的完整退出按钮，门箭头和中文字整体生图，待评价。
│   │   ├── fat_fish_menu.html  # 角色/标题/背景/按钮分层组合的菜单小样，点击仅回显预览信息。
│   │   ├── fat_fish_menu_background.png  # 独立生图的菜单球类训练场景插画，不是正式战斗地图。
│   │   ├── fat_fish_menu_character.png  # 用户已认可的透明护饭碗/鼓脸鲸鱼娘菜单角色，内置生图，未替换正式actor。
│   │   ├── fat_fish_menu_preview.png  # 1280×720肥鱼主题分层菜单截图，新标题/背景/按钮组合待评价。
│   │   ├── fat_fish_menu_preview_v2.png  # 完整生图三按钮替换后的肥鱼菜单截图，无后加图标/文字覆盖。
│   │   ├── fat_fish_menu_title.png  # 独立生图的蓝白玩个球标题字形，菜单新方案待评价。
│   │   ├── fat_fish_settings_button_full.png  # 与开始同风格的完整设置按钮，齿轮和中文字整体生图，待评价。
│   │   ├── fat_fish_start_button.png  # 首版无字蓝白开始按钮底图，后加图标被否定，保留历史对照。
│   │   ├── fat_fish_start_button_full.png  # 按用户要求整体生图的开始按钮，含播放图标与开始游戏中文字，待评价。
│   │   ├── hud_health_flow.gif  # 用户已认可力度的红色血条逐格流光两秒循环参考；正式版本见health_skin.gd。
│   │   ├── hud_health_flow.html  # 用生成贴图演示红色有血格的逐格流光，不改变或接线玩法状态。
│   │   ├── hud_red_sample.png  # 内置生图的透明红色血条HUD概念图；文字数字为示例，未接正式游戏。
│   │   ├── live2d_model_research.md  # 菜单鲸鱼娘Live2D与公开3D候选的来源/外观/格式/授权核验及实际验证边界；追加双线现成动作/VRM物理对照和真实未通过项
│   │   ├── mascot_references_r4.md  # AI视觉锚点的公开参考、机器人候选被否定后的最终人物风格取舍
│   │   ├── menu_preview.html  # 生图按钮和面板的独立菜单/四态演示，点击仅显示预览反馈。
│   │   ├── menu_preview.png  # 1280×720开始/设置/退出菜单的美术组合截图，未接游戏功能。
│   │   ├── production_r2.json  # R2视听素材完整提示词、被否定候选、16种28图映射、六音频返回与分离验收状态
│   │   ├── production_r2.md  # 视听任务恢复清点、首轮剩余数量、拟人主体纠正、真实事件缺口与整文件职责
│   │   ├── release_asset_audit.json  # 逐份美术音频字体源资产与导入配置的覆盖台账、评估证据与处理状态。
│   │   ├── ui_button_base.png  # 内置生图的透明无字通用按钮底图，沿用已认可细边科幻卡框风格。
│   │   ├── ui_panel_base.png  # 内置生图的透明无字横向菜单面板底板，不含控件和具体流程。
│   │   ├── ui_sample.svg  # 已向用户展示且被否定的暖色UI布局样板，保留反馈上下文，不作为实施风格。
│   │   ├── ui_style_guide.md  # 记录样板来源、用户否定与停止全面美术替换的边界。
│   │   ├── upgrade_card_frame.png  # 首版厚切角成长卡框，用户评价太朋克，保留历史对照。
│   │   ├── upgrade_card_frame_v2.png  # 用户已认可的内置生图简约科幻细边柔角通用卡框，无字无具体卡面。
│   │   ├── upgrade_cards_entrance.gif  # 首版三张成长卡轻弹入场的历史预览，后续改为平滑流动风格。
│   │   ├── upgrade_cards_entrance.html  # v2细边卡框三/四张平滑入场及沿边流光独立演示，不接奖励状态。
│   │   └── upgrade_cards_entrance_v2.gif  # 用户已认可的v2三卡平滑滑入及沿边流光预览，正式游戏未接入。
│   ├── history/  # 整理前开发文档的单次历史快照，当前事实以README/PROJECT/STATUS为准
│   │   └── development_before_20261106.md  # 文件整理前README/PROJECT/STATUS完整原文快照，仅作历史追溯
│   ├── ideas/  # 设计方案与创意草案，各文件注明采纳状态
│   │   ├── COLLISION_ROGUELITE_DEMO.md  # 已确认的俯视零重力肉鸽方案、P0～P5 验收与分阶段建设边界。
│   │   └── ROADMAP_DRAFT.md  # 未采纳的开发里程碑、玩法脑洞与可转为 GitHub Issue 的草案。
│   ├── onboarding/  # 另一位开发者与另一台电脑 AI 的入门材料
│   │   ├── images/  # 交接说明配套的可维护流程图
│   │   │   ├── environment.svg  # 另一台电脑的必需环境与可选 MCP 的关系图。
│   │   │   └── workflow.svg  # 开发者从提出功能到 Review、授权提交和 PR 合并的流程图。
│   │   ├── AI_SETUP.md  # 另一电脑 AI 的环境调查、工具补齐、可选 MCP 和验证步骤。
│   │   ├── DEVELOPER.md  # 新开发者如何用 Agent、Git、GitHub、Godot 完成一次协作。
│   │   ├── NEXT_SESSION.md  # 下一对话可复制提示词：现状、最新体验问题、实施顺序与环境/Git授权边界。
│   │   └── live2d_handoff_prompt.md  # 交给另一对话的Live2D只读讲解提示词，明确现状/技术栈与暂不开工、卡片独占边界
│   ├── plans/  # 具体工作的范围与执行清单
│   │   ├── 001-bootstrap.md  # 首次建仓、原型实现和交接的已执行计划。
│   │   ├── 002-workflow.md  # 本轮目录维护、Review、交接配图与路线草案的执行清单。
│   │   ├── 003-collision-roguelite.md  # P0～P2 俯视迁移执行清单、验证与玩家门槛。
│   │   ├── 004-roguelite-run.md  # P3并行分工、整局实现/验证清单与未完成人工验收。
│   │   ├── 005-kill-rewards.md  # 用户批准的击杀领奖/十五项发育池计划、并行分工与验收清单。
│   │   ├── 006-feedback-and-run-rhythm.md  # 音效/生命面板/阶段节奏计划与本地实施更新，音质与两局节奏待验收。
│   │   ├── 007-ui-art-direction.md  # UI美术方向与样板反馈；用户否定样板后暂停全面替换。
│   │   ├── 008-parallel-development.md  # A表现/B玩法实验室、用户owner合并权、整文件边界、S0～S4计划与当前最小接口/实验室实施进度。
│   │   ├── 009-ui-game-integration.md  # 本轮集成范围、所有权、验证与Git授权边界。
│   │   ├── 010-full-game-and-overnight-iteration.md  # 根据附件和代码整理的四地图/Buff/操作、有限自动调参与表现迭代计划；含范围、门槛、整夜预算和授权边界，尚未执行。
│   │   ├── 011-art-audio-interactive-menu.md  # 手绘碰撞风格的28张卡面与视听生产计划R2；含Live2D兼容验证、绑定/互动、原执行进度保留及接续提示词
│   │   ├── 012-card-art-integration.md  # 用户授权卡面/文字做到正式实装的执行范围、整文件接管、步骤与验证入口
│   │   ├── 013-interactive-menu-character.md  # 以米塔/精细Live2D观感为目标的菜单角色执行范围、原生3D试验结果与未达标项；双线继续及耳骨/布料碰撞验收边界
│   │   ├── 014-map-blueprint-correction.md  # 本轮四图修正的用户确认、几何设计、验收条件与本地执行计划
│   │   ├── 015-ball-art-effects-and-tactical-aim.md  # 本轮美术/特效/字体/瞄准静止的完整需求、子Agent分工与验收计划
│   │   ├── 016-ui-animation-icon-and-platform.md  # 六项UI、球体动画、菜单表情、独立图标及Windows安卓评估的分工与验收
│   │   ├── 017-smooth-animation-card-flow-menu-actions.md  # 用户复验后的连续动画、真实卡片内容流及可发现Live2D动作分工/验收
│   │   ├── 018-let-me-go-background-music.md  # 用户提供Let Me Go音频后的持续BGM、音量/静音与实际包验证分工
│   │   ├── 019-release-experience.md  # 发布前玩法、美术、性能与Windows/安卓分阶段验收计划及Agent整文件分工。
│   │   └── 020-build-economy-and-skill-payoff.md  # 第二轮金币重选和精准三敌回能的设计反证、文件单写分工与验收计划。
│   ├── playtest/  # 面向策划/试玩者的启动操作、反馈与已知限制说明
│   │   ├── OVERNIGHT_DELIVERY.md  # 整夜阶段交付：普通包、实际采用差异、前后证据和真人/原生窗口未验项
│   │   ├── OVERNIGHT_FEEDBACK.txt  # 普通包真人手感、美术、音频与成长反馈模板，无调参快捷键误导
│   │   ├── OVERNIGHT_README.txt  # 普通菜单包的零伙伴/四图操作说明与验证边界
│   │   ├── PLANNER_FEEDBACK.txt  # 只供策略、成长与节奏逐局反馈；手感改用实时面板并回传物理参数JSON。
│   │   ├── PLANNER_README.txt  # 随Windows试玩包交给策划的操作、流程、版本反馈与限制说明。
│   │   ├── RELEASE_CREDITS.md  # 双平台发布随包署名、字体/音频/生成素材/Live2D来源和用户许可确认记录。
│   │   └── RELEASE_README.txt  # Windows完整解压与安卓安装、基本操作、构筑和真实验收边界的随包游玩说明。
│   ├── reviews/  # 重要改动的审查证据与交接
│   │   ├── 2026-10-28-workflow.md  # 本轮独立最终审查、测试证据、问题处理、用户授权与交接记录。
│   │   ├── 2026-10-31-feedback-export.md  # 当前反馈整改/导出/分工完整最终Review、独立审查与测试/未测证据。
│   │   ├── 2026-10-31-kill-rewards.md  # 击杀奖励原型最终独立Review、验证限制、最新体验缺陷与本轮上传范围。
│   │   ├── 2026-11-01-gameplay-lab.md  # 本批S1表现接口和B线玩法实验室的最终Review范围、独立审查、问题处理、验证证据、未测项与授权边界。
│   │   ├── 2026-11-02-ui-integration.md  # A/B快照集成与UI接线的验证/独立审查证据及未测项。
│   │   ├── 2026-11-03-function-verification.md  # 本轮完整功能实测清单、翻板数值对照、独立审查与Git边界证据
│   │   ├── 2026-11-05-ball-art-and-tactical-aim.md  # 本轮人物团子/字体/决策静止/单体素材箭头的独立技术验收、修复证据和授权边界
│   │   ├── 2026-11-05-live2d-start-menu.md  # 正式菜单最终自查、独立Review、问题修复与测试/发布边界记录
│   │   ├── 2026-11-06-final-integration.md  # 整批文件整理、独立最终审查、测试与Git交付边界记录
│   │   ├── 2026-11-06-let-me-go-music.md  # 原曲BGM独立复核、52套及退出修正复测、新包原曲与用户静音偏好交接
│   │   ├── 2026-11-06-smooth-card-menu-actions.md  # 用户复验后的动画/卡牌/菜单独立审查、51套回归、新包与实际窗口未测边界
│   │   ├── 2026-11-06-ui-animation-icon.md  # 本轮UI/动画/表情/图标独立验收、红绿修复、实际导出与安卓未测边界
│   │   ├── 2026-11-10-art-inventory.md  # 全部素材的实看范围、分组评分、正式引用与许可来源缺口审查。
│   │   ├── 2026-11-10-gameplay-assessment.md  # 16策略、120组合与整局的加权设计评分、玩家视角反证及发布前玩法方案。
│   │   ├── 2026-11-10-independent-release-review.md  # 未参与实现Agent的整批独立审查、复测/实际包证据与明确有保留结论。
│   │   ├── 2026-11-10-platform-audit.md  # 当前设备双平台工具链、代码性能热点与安卓输入适配的只读审查证据。
│   │   ├── 2026-11-10-release-final.md  # 发布前整批最终Review：自查、独立审查、全量与实际包证据、授权和明确未测项。
│   │   ├── 2026-11-10-release-playtest-results.md  # 同v4评估器18独立局的真实结果、完整策略复评分与未通过的体验条件。
│   │   ├── 2026-11-10-rice-map-ds-ui.md  # 本批白饭/地图/DS蓝白UI的Git前最终Review、独立审查、新鲜测试与commit/push授权边界。
│   │   ├── 2026-11-13-cleanup-release-independent.md  # 未参与整理实现Agent对隔离映射、原字节与正式成品、文档/目录的独立Review。
│   │   ├── 2026-11-13-cleanup-release.md  # 本轮本机归档整理、成品哈希与验证、公开推送/合并/Release授权和已知边界自查。
│   │   └── collision-demo-final.md  # 当前Demo最终独立Review、首领真实接触修复、验证与人工未测证据。
│   ├── tutorials/  # 每个功能的实现原理和手动修改教程
│   │   ├── 001-prototype.md  # 球发射、碰撞表现、机关、目标和手动调参的初始教程。
│   │   ├── 002-project-map-and-review.md  # 文件目录生成/检查的实现和 Review/授权流程的操作教程。
│   │   ├── 003-collision-roguelite.md  # 俯视 P0～P2 输入、冲量、接力、归队、检查器调参与玩家验收教程。
│   │   ├── 004-enemies.md  # 三敌人/生命/危险弹的状态、节点、检查器与回归教程。
│   │   ├── 005-build.md  # 十五项奖励候选/权重/等级与碰撞收益、资源调参和扩展教程。
│   │   ├── 006-boss.md  # 首领模块/弱点/危险弧、物理接口、调参与验证教程。
│   │   ├── 007-run-loop.md  # 完整战斗入口、波次/升级/结算、调试构筑及人工验证教程。
│   │   ├── 008-rice.md  # 白饭力场/周期/满血禁生成/拾取回血、调参与复现教程。
│   │   ├── 009-theme.md  # 几何肥鱼/小鱼、主题资源、饱饭外观与物理隔离教程。
│   │   ├── 010-kill-rewards.md  # 击杀奖励队列、三选四选、真实收益、调参与扩展教程。
│   │   ├── 011-health-panel.md  # 生命面板节点、信号与只读状态、调参、扩展及手动复现教程。
│   │   ├── 012-event-audio.md  # 原创事件音组、调度预算、独立音量、试听与打击感整改教程。
│   │   ├── 013-stage-rest.md  # 三阶段、钱包、商店/免费成长事件、状态清理与调参复现教程。
│   │   ├── 014-crowd-impact.md  # 扎堆撞停根因、敌人质量/硬直、有限续力与真物理回归及调参教程。
│   │   ├── 015-difficulty.md  # 逐波含预警预算、渐进间隔/强敌配额、检查器与新手试玩教程。
│   │   ├── 016-enemy-range-and-health.md  # 三敌人出范围取消/重新蓄力、剩余血量颜色和数字、检查器与回归教程。
│   │   ├── 017-enemy-splitting.md  # 玩家勾选分裂、两代次球、安全预警/预算和整族经济教程。
│   │   ├── 018-contact-damage.md  # 橙色方块漏伤根因、物理帧双快照与不同节点顺序真实接触回归教程。
│   │   ├── 019-windows-export.md  # 隔离导出Windows策划包、版本指纹、验证与跨电脑限制教程。
│   │   ├── 020-parallel-workflow.md  # 两电脑同基线、唯一文件owner、接口交接、文档集成与用户审阅merge操作教程。
│   │   ├── 021-gameplay-presentation-interface.md  # 敌人只读快照/事件、可替换表现、生命面板和UI请求校验的最小接口教程。
│   │   ├── 021-hud-health-flow.md  # 红色HUD生图来源、流光过程/参数、独立预览验证与B接线边界教程。
│   │   ├── 022-gameplay-lab.md  # 八类玩法夹具、白名单参数、正式固定发射、拒伤日志、预设与复现教程。
│   │   ├── 022-upgrade-card-frame.md  # 通用卡框来源、依次入场原理/参数、预览验证与B奖励接线边界。
│   │   ├── 023-menu-ui-assets.md  # 无字按钮/面板来源、四态组合、尺寸验证和B菜单接线边界教程。
│   │   ├── 024-fat-fish-menu.md  # 肥鱼菜单独立生图来源、图层/参数、浏览器验证及B接线边界教程。
│   │   ├── 024-live-feel-tuning.md  # 策划EXE现场调物理量的操作、生效语义、节点/源码、对照/存取与扩展验证教程。
│   │   ├── 025-full-engine-tuning.md  # 完整引擎/玩法调参台的覆盖、生效/重启、复合编辑、源码与验证教程。
│   │   ├── 026-ui-game-integration.md  # A/B快照汇合、入口分离、UI运行接入、调参保留与验证教程。
│   │   ├── 027-zero-companion-buffs.md  # 零伙伴开局、外包前提、安全增员与15项Buff文案的修改和验证教程
│   │   ├── 028-map-mechanisms-portals.md  # 真实机关节点、传送保速与安全出口、旧地图接口的使用修改和验证教程
│   │   ├── 029-four-map-run.md  # 四张实际地图的波次接线、暂停/休息/重开、安全生成与空间通道检查教程
│   │   ├── 030-balance-evaluation.md  # 固定场景、策略、真实指标、提速验证、候选取舍与证据复现教程
│   │   ├── 031-fish-art-feedback.md  # 位图接入、UV修复、事件反馈、四卡排版与实录边界教程
│   │   ├── 032-ordinary-export-validation.md  # 普通包过滤、内嵌资源探针、标准发布模板限制与原生验证边界教程
│   │   ├── 033-paddle-response-and-feature-checks.md  # 翻板限速限位原理、检查器调参与逐项功能验证教程
│   │   ├── 034-live2d-l0-and-audio-samples.md  # Live2D许可与构建前置、隔离引擎基线复现、待测模型项目、绑定交付要求及六音频试听方法
│   │   ├── 035-live2d-architecture.md  # Live2D制作/运行两阶段、Editor与SDK/Core/Framework/桥接分工、模型文件与交互流程入门
│   │   ├── 036-card-art-catalog-and-gallery.md  # 28张卡面映射、圆眼母版与生成修正、导入参数、图鉴操作和跨机验证教程
│   │   ├── 037-integrated-upgrade-cards.md  # 正式卡片贴图/文案/下一等级收益接线、节点/检查器调整、导出与验证教程
│   │   ├── 038-deepseek-live2d-menu-sample.md  # 成年精细Live2D样板的来源、近景/身体输入、原跟随修复、真实验证及内存/授权限制；原动作曲线复用、作者手势与独立对照操作
│   │   ├── 039-whale-menu-3d.md  # 成年鲸鱼娘原生3D样板的准备、四骨微动、注视、材质、真实验证及专业绑定缺口；现成VRM2.6.1弹簧/碰撞对照及复现限制
│   │   ├── 040-live2d-start-menu.md  # F5菜单角色节点/输入/私有资源加载、检查器调参、回归证据与发布边界教程
│   │   ├── 041-map-blueprint-correction.md  # 四张示意图到实际场景/出生/运动/门配对的修正原理、调参与验证
│   │   ├── 042-ball-art-and-effects.md  # 人物与分级病毒接线、只读映射、透明裁切与真实事件特效的调参与验证
│   │   ├── 043-tactical-aim.md  # 瞄准决策静止、暂停所有权、正式Game共享箭头动画及边界验证
│   │   ├── 044-card-typography.md  # 中文动态艺术标题、可再分发字体、规则文案与小窗口全卡验收
│   │   ├── 045-sea-ui-hierarchy.md  # 卡片收益与规则层级、商店结算暂停主题及真实布局验证教程
│   │   ├── 046-menu-safe-expressions.md  # 黑脸参数根因、温和互动表情与恢复阻断的开发教程
│   │   ├── 047-ball-animation.md  # 内置生成姿势图集、真实事件驱动与表现层动画调参教程
│   │   ├── 048-icon-and-windows-android.md  # PNG多尺寸ICO生成、Windows实际导出图标与安卓适配评估边界
│   │   ├── 049-card-content-flow.md  # 取代百分比定位和固定分隔的卡牌内容流、全规则测量与实际路径验证教程
│   │   ├── 050-smooth-hero-animation.md  # 固定待机底图与连续阻尼回弹、生成表情构图校准及多帧率验证教程
│   │   ├── 051-menu-visible-actions.md  # Live2D固定部位到可见头身动作、命中/打断/减少动态提示及网格证据教程
│   │   ├── 052-persistent-music.md  # 持续背景音乐、音源替换、音量与静音接线及导出排错开发教程
│   │   ├── 053-ocean-ui-polish.md  # UI/动效修改前后主观评分、生成素材接线、布局与减少动态教程。
│   │   ├── 054-ds-character-ui.md  # 身份纠偏、蓝白双栏UI、审美重评、动画节奏和HUD隔离教程。
│   │   ├── 055-light-ui-refinement.md  # 已选蓝白方向的商店分栏、胜负人物/统计、内容测量与再评分教程。
│   │   ├── 056-strategy-payoff.md  # 深链接力、爆破半径、保龄余势、后段整备和可复现seed的开发者教程。
│   │   ├── 057-build-feedback-and-supply.md  # 只读构筑/真实成功提示、策略徽记、窄屏补给滚动和减少动态的开发者教程。
│   │   ├── 058-mobile-input-and-release.md  # 触控index、取消/后台/返回、安全区、重复刷新优化与安卓导出实证教程。
│   │   ├── 059-query-safe-map-pause.md  # 真实危险球致死暴露的翻板物理锁问题、revision延后模式修复和四图复现。
│   │   ├── 060-rerolls-and-precision-chain.md  # 有限金币重选事务、候选保证、入场防重复与真实三敌精准回能的开发者教程。
│   │   ├── 061-release-packaging.md  # 双平台release构建、旁置Live2D新增路径接线、来源通知、签名备份与包探针教程。
│   │   ├── 062-platform-pause-order.md  # Android暂停恢复的间歇性原生错误、最小通知交易修正、基线对照与原生验收限制。
│   │   └── 063-cleanup-and-public-release.md  # 可再生文件与私有资源边界、保留式隔离/证据追溯及PR合并和Release维护教程。
│   ├── .gdignore  # 让 Godot 跳过文档目录的资源导入，避免把交接图当作游戏素材。
│   ├── FILE_MAP.md  # 自动生成的项目文件树、每个文件的用途及主要调用关系。
│   ├── PROJECT.md  # 已采纳的游戏目标、技术选择、原型范围与模块边界。
│   ├── REVIEW.md  # 开发者准备 Git 提交时发起的最终审查、测试和授权流程，与开发中的局部检查独立。
│   ├── STATUS.md  # 当前实际进展、验证证据、已知限制和下一步交接。
│   └── file_purposes.json  # 文件与目录用途的人工说明，作为文件树生成器的语义来源。
├── resources/  # Godot 可调数据资源
│   ├── legal/  # 随APK/EXE打包且可在设置读取的署名、音乐来源、字体及Kenney许可原文。
│   │   ├── Kenney_CC0.txt  # Kenney瞄准粒子素材随应用分发的CC0许可原文。
│   │   ├── Noto_OFL.txt  # APK设置中可离线读取的Noto Sans SC OFL许可副本。
│   │   ├── ZCOOL_OFL.txt  # 未修改ZCOOL字体随应用分发的SIL OFL许可原文。
│   │   ├── credits.txt  # APK内可访问的完整发布署名与用户音乐/模型再分发许可确认记录。
│   │   └── music.txt  # APK内可访问的音乐原来源、哈希及用户公开分发许可确认。
│   ├── roguelite/  # 肉鸽构筑与主题数据
│   │   ├── audio/  # 原创事件音组与混音调参资源
│   │   │   └── default_palette.tres  # 默认原创音色合成增益资源。
│   │   ├── balance/  # 独立评估参数候选与搜索前锁定的分组门槛
│   │   │   ├── baseline.tres  # 独立真实物理评估参数：baseline；未自动替换正式默认
│   │   │   ├── control_015.tres  # 独立真实物理评估参数：control_015；未自动替换正式默认
│   │   │   ├── control_030.tres  # 独立真实物理评估参数：control_030；未自动替换正式默认
│   │   │   ├── control_045.tres  # 独立真实物理评估参数：control_045；未自动替换正式默认
│   │   │   ├── control_060.tres  # 独立真实物理评估参数：control_060；未自动替换正式默认
│   │   │   ├── cooldown_180.tres  # 独立真实物理评估参数：cooldown_180；未自动替换正式默认
│   │   │   ├── cooldown_200.tres  # 独立真实物理评估参数：cooldown_200；未自动替换正式默认
│   │   │   ├── cooldown_rules_v1.json  # 冷却组搜索前锁定的战斗等待改善门槛，保留共同安全约束
│   │   │   ├── evaluation_rules_v1.json  # 控制组搜索前锁定的成对改善、坏例、伤害与物理硬门槛
│   │   │   ├── impact_0945.tres  # 实际发射冲量945独立候选，正式默认1050未替换
│   │   │   ├── impact_1155.tres  # 实际发射冲量1155独立候选，正式默认1050未替换
│   │   │   ├── impact_rules_v1.json  # 搜索前锁定的主动撞击清敌/首次真实HP伤害及安全门槛
│   │   │   ├── transfer_075.tres  # 独立真实传能评估候选0.75，默认0.85未自动替换
│   │   │   ├── transfer_090.tres  # 独立真实传能第二轮候选0.90，保持冲量与链路上限
│   │   │   ├── transfer_095.tres  # 独立真实传能评估候选0.95，默认0.85未自动替换
│   │   │   ├── transfer_rules_v1.json  # 首轮搜索前锁定的伙伴实际HP速率、清敌与安全门槛
│   │   │   └── transfer_rules_v2_fan.json  # 保留原门槛并加入可观测侧向伙伴场景的第二轮固定规则
│   │   ├── maps/  # 地图边界、出生点及入口资源
│   │   │   ├── boss_map.tres  # 首领场肥鱼左下与完整Boss右上独立出生及边界数据
│   │   │   ├── legacy.tres  # 旧原型围场的默认地图数据
│   │   │   ├── map_01.tres  # 第一图中央出生区及边界数据
│   │   │   ├── map_02.tres  # 第二图X上方出生区及边界数据
│   │   │   └── map_03.tres  # 第三图环心出生区及边界数据
│   │   ├── stages/  # 波次范围与阶段休息配置
│   │   │   ├── stage_1.tres  # 第一阶段波1～2及波末商店配置。
│   │   │   ├── stage_2.tres  # 第二阶段波3～4及波末补给事件配置。
│   │   │   └── stage_3.tres  # 第三阶段波5及首领、结束无额外休息配置。
│   │   ├── themes/  # 只影响绘图配色的角色主题资源
│   │   │   └── fat_fish.tres  # 肥鱼主球、小鱼、能量与饱饭符号的默认配色。
│   │   ├── upgrades/  # 十五项普通奖励和独立强身兜底的说明、分类、权重与等级上限
│   │   │   ├── bowling.tres  # 升级 bowling 的标题、效果说明与等级上限。
│   │   │   ├── choices.tres  # 三选变四选的说明、类别与一级上限。
│   │   │   ├── companion.tres  # 升级 companion 的标题、效果说明与等级上限。
│   │   │   ├── cooldown.tres  # 升级 cooldown 的标题、效果说明与等级上限。
│   │   │   ├── double_launch.tres  # 双发容量的说明、类别与一级上限。
│   │   │   ├── echo.tres  # 有限二次撞击的说明、类别与一级上限。
│   │   │   ├── explosion.tres  # 升级 explosion 的标题、效果说明与等级上限。
│   │   │   ├── follow.tres  # 升级 follow 的标题、效果说明与等级上限。
│   │   │   ├── glide.tres  # 滑行的自身阻尼/摩擦增益、类别和三级上限。
│   │   │   ├── heal.tres  # 升级 heal 的标题、效果说明与等级上限。
│   │   │   ├── heavy.tres  # 升级 heavy 的标题、效果说明与等级上限。
│   │   │   ├── launch_power.tres  # 强力发射的冲量增益、类别、权重与三级上限。
│   │   │   ├── pulse.tres  # 无伤护身震退的说明、类别和一级上限。
│   │   │   ├── relay.tres  # 升级 relay 的标题、效果说明与等级上限。
│   │   │   ├── shrink.tres  # 敌人脉冲/首领震波缩范围的说明与两级上限。
│   │   │   └── vigor.tres  # 普通池耗尽时本局生命上限+1的独立可重复兜底。
│   │   ├── card_art_catalog.json  # 正式HUD与独立图鉴共享的28张下一等级插画只读映射及分离审美状态，不决定奖励
│   │   └── upgrade_card_copy.json  # 16项成长的玩家规则说明和趣味短句；纯显示，不决定玩法或数值
│   └── ui/  # 跨平台UI字形样式资源。
│       └── body_fallback.tres  # Noto可变字体的共享FontVariation，wght固定400，补全安卓标点并避免默认Thin100。
├── scenes/  # Godot 可编辑场景与节点结构
│   ├── roguelite/  # 俯视零重力三靶场、正式整局与B线独立玩法夹具场景
│   │   ├── maps/  # 三张普通地图与首领地图的可编辑布局
│   │   │   ├── boss_map.tscn  # 封闭内圈四刺、四开口外圈、四向翻板及绿黄两组传送门
│   │   │   ├── map_01.tscn  # 固定左右斜板、上横下竖中心轴翻板的实际布局
│   │   │   ├── map_02.tscn  # X形共轴翻板、世界上下移动斜板与左下/右上两处短浅刺
│   │   │   └── map_03.tscn  # 环心出生、水平移动刺板与左右保速门的实际布局
│   │   ├── mechanisms/  # 可编辑的刚体挡板、移动板、圆弧、尖刺与成对门场景
│   │   │   ├── boss_inner_ring.tscn  # 首领完整内圆周的可编辑分段实体碰撞与视觉
│   │   │   ├── boss_outer_ring.tscn  # 首领四处30度开口外圆周的可编辑碰撞与视觉
│   │   │   ├── fixed_barrier.tscn  # 第一图左右固定斜板，使用静态实体碰撞与可编辑视觉
│   │   │   ├── moving_barrier.tscn  # 物理帧驱动的往返AnimatableBody2D挡板的可编辑场景
│   │   │   ├── pivot_paddle.tscn  # 真实关节翻转挡板的配置、暂停与复位的可编辑场景
│   │   │   ├── portal_pair.tscn  # 传送入口检测、出口占用复核、同帧预约与离门冷却锁的可编辑场景
│   │   │   ├── rotating_arc.tscn  # 带缺口分段圆弧的物理帧旋转的可编辑场景
│   │   │   ├── spike_strip.tscn  # 主球尖刺接触与统一生命伤害请求的可编辑场景
│   │   │   └── twin_arcs.tscn  # 地图三两段带缺口圆弧的可编辑分段碰撞场景
│   │   ├── presentation/  # 可独立替换的角色/敌人/生命表现与只读卡面样板场景
│   │   │   ├── boss_view.tscn  # 可编辑首领表现与不会遮住危险的顶栏状态
│   │   │   ├── build_feedback.tscn  # 独立可编辑的只读构筑状态与有限策略成功提示场景。
│   │   │   ├── card_art_card.tscn  # 图鉴单卡表现样板，插画/等级/真实收益/说明分区及缩图mipmap采样
│   │   │   ├── companion_view.tscn  # 可编辑伙伴Sprite视觉子场景
│   │   │   ├── enemy_view.tscn  # 三种敌人共用独立视图，线性mipmap与生图材质接入
│   │   │   ├── fish_ball_view.tscn  # 可编辑主球视觉子场景，Sprite及导入位图
│   │   │   ├── health_view.tscn  # 正式可替换生命面板场景，只读取DemoHealth数据。
│   │   │   └── upgrade_card.tscn  # 正式选卡Button的可编辑插画/等级/收益/规则/趣味短句节点与手绘卡框
│   │   ├── arena.tscn  # 可编辑俯视三靶场、四边围墙、斜切角、平面挡板与 HUD。
│   │   ├── audio_preview.tscn  # F6独立音效试听场景，不改变游戏进度。
│   │   ├── boss.tscn  # 同一刚体上的核心和四个可拆模块碰撞形状。
│   │   ├── card_art_gallery.tscn  # 独立可编辑成长图鉴，三/四卡、分页和系列筛选；不替换正式HUD或菜单
│   │   ├── companion_ball.tscn  # 零重力小兵、接力传感器及围墙/挡板/箱体实体碰撞配置。
│   │   ├── destructible.tscn  # 可复用的固定碰撞靶形状与受击脚本入口。
│   │   ├── enemy.tscn  # 三敌人共用刚体/碰撞形状和低弹性材质，并实例可替换表现组件。
│   │   ├── gameplay_lab.tscn  # B线独立八类玩法夹具入口，F6运行且不替换正式run。
│   │   ├── hazard_ball.tscn  # 危险弹刚体与玩家传感器，环境碰撞后消失。
│   │   ├── lab_panel.tscn  # 实验室可编辑开发控制根场景，运行时分栏显示白名单参数、读数和有界日志。
│   │   ├── player_ball.tscn  # 零重力主球刚体、圆形形状与弹性材质。
│   │   ├── rest_panel.tscn  # 商店、补给事件和3秒准备共用的可编辑功能面板。
│   │   ├── rice_lure.tscn  # 白饭Area2D与玩家拾取形状，不改变刚体碰撞。
│   │   ├── run.tscn  # 独立三阶段战斗入口，接合音频、商店/事件与首领，保留F5旧入口。
│   │   ├── run_hud.tscn  # 正式生命/奖励/结算HUD布局，奖励行容纳三/四张带图卡片
│   │   ├── tuning_panel.tscn  # 完整引擎/快捷模式的可编辑面板壳，暂停、分页区域与对照/存取容器。
│   │   └── tuning_run.tscn  # 策划完整属性调参入口，继承正式整局，含全量目录与原快捷面板。
│   ├── ui/  # 正式主菜单与完整战斗入口
│   │   ├── game.tscn  # 继承完整run的发布场景，无调参节点。
│   │   ├── main_menu.tscn  # F5正式开始界面，挂可编辑MenuCharacter表现组件
│   │   ├── menu_character.tscn  # 菜单角色区域、1440透明SubViewport、Portrait与无本机资源时的原PNG回退
│   │   └── result_body.tscn  # DS胜负人物、真实击破/最长接力记录和说明的可编辑结算组件。
│   ├── ball.tscn  # 可复用的球刚体、圆形碰撞形状与物理材质。
│   ├── main.tscn  # 实验关卡的障碍、球、机关、目标、镜头和 HUD 节点布局。
│   └── mechanism.tscn  # 可复用的区域机关入口，运行时按参数生成检测形状。
├── scripts/  # 游戏逻辑与表现脚本
│   ├── roguelite/  # 新肉鸽物理、发射、碰撞、同伴逻辑与独立玩法实验室
│   │   ├── evaluation/  # 固定输入、真实物理夹具、原始指标及正常AI整局代理；不挂正式入口
│   │   │   ├── balance_profile.gd  # 白名单冲量/反向抵消/冷却候选的应用与实际参数快照
│   │   │   ├── balance_profile.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── evaluation_fixture.gd  # 六类固定种子独立物理夹具，使用正式球/发射/敌人/机关
│   │   │   ├── evaluation_fixture.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── full_run_agent.gd  # 正常AI整局代理，遵守卡入场锁并从真实候选和商店选择
│   │   │   ├── full_run_agent.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── full_run_runner.gd  # 独立正式整局的自然胜负/截尾、构筑与事件证据运行入口
│   │   │   ├── full_run_runner.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── input_policy.gd  # 最近/墙与尖刺安全启发式/伙伴策略，只调用正式发射；普通预警按DemoEnemy类型守卫，不误读首领
│   │   │   ├── input_policy.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── metrics_recorder.gd  # 真实HP/过量/伙伴直接归因、激活、输入、轨迹和伙伴越界计量
│   │   │   ├── metrics_recorder.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── scenario_runner.gd  # 固定120Hz/20秒矩阵运行与逐条原始JSON保存
│   │   │   └── scenario_runner.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── lab/  # B线玩法实验室的开发面板与请求界面
│   │   │   ├── engine_tuning.gd  # ProjectSettings与Engine/PhysicsServer热调适配及override.cfg保存/清除。
│   │   │   ├── engine_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── full_tuning.gd  # 实际属性/资源/原型全量目录，校验应用、复位、生成继承与跨别名全局恢复。
│   │   │   ├── full_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── full_tuning_view.gd  # 完整参数分类/搜索/每页20行及数字/开关/枚举/颜色/JSON编辑器。
│   │   │   ├── full_tuning_view.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── lab_panel.gd  # 实验室白名单参数表单、即时显示偏好和带revision的玩法请求；不直接修改战斗状态。
│   │   │   ├── lab_panel.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── tuning_panel.gd  # 纯界面：生成滑杆和数字框、F1显隐、发送参数/按钮请求并显示实际读数。
│   │   │   ├── tuning_panel.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── tuning_variant.gd  # 无对象Variant存取、可读JSON复合值转换、有限数和结构校验。
│   │   │   └── tuning_variant.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── maps/  # 地图数据、安全查询与切换接口
│   │   │   ├── map_controller.gd  # 四图选择/释放、玩家伙伴安全落位、机关状态与地图碰撞安全查询
│   │   │   ├── map_controller.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── map_definition.gd  # 地图边界、玩家/首领出生点、敌人入口与安全区域的数据契约
│   │   │   ├── map_definition.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── map_layout.gd  # 地图根数据及从现有墙条位图映射到真实障碍的视觉接入
│   │   │   └── map_layout.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── mechanisms/  # 地图真实物理机关、尖刺接触与受控传送组件
│   │   │   ├── moving_barrier.gd  # 物理帧驱动的往返AnimatableBody2D挡板
│   │   │   ├── moving_barrier.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── pivot_body.gd  # 翻板刚体物理状态复位、角速度上限及相对初始角度限位稳定
│   │   │   ├── pivot_body.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── pivot_paddle.gd  # 真实关节翻转挡板的配置、暂停与复位
│   │   │   ├── pivot_paddle.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── portal_pair.gd  # 传送入口检测、出口占用复核、同帧预约与离门冷却锁
│   │   │   ├── portal_pair.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── rotating_arc.gd  # 带缺口分段圆弧的物理帧旋转
│   │   │   ├── rotating_arc.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── spike_strip.gd  # 主球尖刺接触与统一生命伤害请求
│   │   │   └── spike_strip.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── presentation/  # 只读玩法快照/事件的绘制组件与独立卡面图鉴控制
│   │   │   ├── aim_indicator.gd  # 正式Game与实验场共用的单头素材箭头、柔和尾流、呼吸和释放缩回，只读手势
│   │   │   ├── aim_indicator.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── ball_art.gd  # 稳定角色身份纹理、实际透明裁切与生成四格AtlasTexture缓存/防串采
│   │   │   ├── ball_art.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── boss_view.gd  # 病毒首领核心/四模块与原阶段/破防/冲撞/震波的只读表现
│   │   │   ├── boss_view.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── build_feedback.gd  # 消费真实接力/爆破/余势/精准回能的单条有界提示与响应式构筑条，不回写玩法。
│   │   │   ├── build_feedback.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── card_art_gallery.gd  # 只读图鉴控制与真实收益复用、素材加载、分页筛选及可选渲染证据输出
│   │   │   ├── card_art_gallery.gd.uid  # 独立成长图鉴脚本UID
│   │   │   ├── card_art_library.gd  # 只读卡面/文案JSON，按下一等级解析纹理并缓存，重复项共用图
│   │   │   ├── card_art_library.gd.uid  # 同名GDScript的稳定资源UID，随脚本提交
│   │   │   ├── combat_float.gd  # 已结算伤害/击破浮字，与战场显式共同暂停和自动清理
│   │   │   ├── combat_float.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── companion_view.gd  # 读取只读slot选择GPT/Claude/千问人物团子，保留攻击资格与归队环
│   │   │   ├── companion_view.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── enemy_view.gd  # 出生等级病毒皮肤与真实剩余HP/预警/角色朝向，只消费玩法事件
│   │   │   ├── enemy_view.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── fish_ball_view.gd  # 鲸鱼娘生成姿势idle/碰撞/痛脸、真实发射击杀回弹与回能反馈，只改Sprite不改物理
│   │   │   ├── fish_ball_view.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── health_view.gd  # 只读生命条/数字/状态表现组件及热绑定入口。
│   │   │   ├── health_view.gd.uid  # 关联GDScript稳定资源标识。
│   │   │   ├── portal_view.gd  # 细弧/出口箭头与物理成功后过门短环，不播放假成功
│   │   │   ├── portal_view.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── sea_ui_theme.gd  # 委托生成海蓝主题与主操作状态，不参与购买许可。
│   │   │   ├── sea_ui_theme.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   │   ├── upgrade_card.gd  # 按实际文字测高扩展卡片、保留最小插画与全文；配合外层滚动，不执行升级规则。
│   │   │   ├── upgrade_card.gd.uid  # 同名GDScript的稳定资源UID，随脚本提交
│   │   │   ├── virus_burst.gd  # 真实病毒死亡的生成裂壳/散片帧、短时有界且随战场暂停
│   │   │   └── virus_burst.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── arena.gd  # 鼠标/原生手指归属与GUI隔离、Android通知暂停意图的idle交易/输入屏障、状态文案单次生成及越界回收。
│   │   ├── arena.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── assist_effects.gd  # 可暂停的无伤护身震退、有限冲量与表现事件。
│   │   ├── assist_effects.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── audio_director.gd  # 多事件变体回避、限频与优先级声部、混音/暂停和重开清理。
│   │   ├── audio_director.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── audio_palette.gd  # 原创PCM音色合成与缓存，轻重多变体和各事件音组。
│   │   ├── audio_palette.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── audio_preview.gd  # 事件逐项与密集连锁真机试听入口，数字键/静音/重播。
│   │   ├── audio_preview.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── boss.gd  # 首领预警冲刺、真实撞墙弱点、可碎模块、缺口震波与召唤。
│   │   ├── boss.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── collision_combat.gd  # 有效碰撞/代数伤害/有界余势爆破、生命周期守卫与同链三不同主球直伤条件事件。
│   │   ├── collision_combat.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── combat_body.gd  # 接触快照/冲量刚体基类，集中复位与一次性调试状态接口，拒绝旧局回调。
│   │   ├── combat_body.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── companion_ball.gd  # 默认不跟随的小鱼、接力/障碍碰撞与升级后的限力引导。
│   │   ├── companion_ball.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── companion_manager.gd  # 小弟数量上限、障碍外初始摆球、保留旧球的增员与跟随开关。
│   │   ├── companion_manager.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── destructible.gd  # 固定碰撞靶的生命、一次死亡事件、复位与占位绘图。
│   │   ├── destructible.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── enemy.gd  # 三类物理敌人的生命、范围攻击、硬直、死亡与只读表现快照/事件；不负责绘制。
│   │   ├── enemy.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── gameplay_lab.gd  # 独立八夹具、完整构筑/显式覆盖、生成校验、分裂AI策略、拒伤读数与预设迁移。
│   │   ├── gameplay_lab.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── hazard_ball.gd  # 慢危险弹、玩家检测、寿命和旧事件保护。
│   │   ├── hazard_ball.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── kill_rewards.gd  # 死亡去重、递增门槛、击杀溢出和排队奖励的独立资源。
│   │   ├── kill_rewards.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── launch_controller.gd  # 单发/双发容量、串行冷却/有限返还、瞄准暂停与可不释放暂停的手势取消、正式及实验室发射入口。
│   │   ├── launch_controller.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── live_tuning.gd  # 快捷基线和完整属性覆盖协调、暂停/对照/F9、schema2含高级值存取。
│   │   ├── live_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── player_ball.gd  # 主球冲量/短时有限撞敌续力、升级物理参数、续力只读读数、能量环与肥鱼绘图。
│   │   ├── player_ball.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── player_health.gd  # 五格生命、受伤无敌/拒伤、一次死亡、真实扣血damaged事件与整局重置
│   │   ├── player_health.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── rest_panel.gd  # 双栏人物/真实报价操作、主次按钮与原revision请求，内容测高不改变购买规则。
│   │   ├── rest_panel.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── rice_lure.gd  # 白饭拾取区域、有限平面吸力、寿命/闪烁及物理锁外清理。
│   │   ├── rice_lure.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── rice_manager.gd  # 白饭周期/安全候选、满血禁生成与生命恢复/清理。
│   │   ├── rice_manager.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_arena.gd  # 整局输入/生命HUD接线、Android旧局暂停意图失效、实际战斗文案及缓存音频混音同步。
│   │   ├── run_arena.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_build.gd  # 十五项候选的类别/权重/资格、等级与全部派生数值及强身兜底。
│   │   ├── run_build.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_director.gd  # 整局/波次/阶段经济、付费整备与重选、精准链回能校验和可复现随机种子。
│   │   ├── run_director.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── run_hud.gd  # 正式成长/结算、完整正文滚动、有限金币重选报价与入场ready/revision，保持真实请求校验。
│   │   ├── run_hud.gd.uid  # 同名GDScript的稳定资源UID，随脚本提交
│   │   ├── run_wallet.gd  # 唯一死亡入账、余额校验扣款与整局钱包复位。
│   │   ├── run_wallet.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── stage_definition.gd  # 阶段波范围、休息类型与名称数据资源。
│   │   ├── stage_definition.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── stage_flow.gd  # 解析阶段资源与波末商店/事件边界。
│   │   ├── stage_flow.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── theme_definition.gd  # 肥鱼主题ID/名字/绘图配色数据，不携带物理参数。
│   │   ├── theme_definition.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── tuning_run.gd  # 策划完整调参接线、文本输入/鼠标隔离与普通暂停所有权交接。
│   │   ├── tuning_run.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── upgrade_definition.gd  # 升级数据资源：ID、标题、说明与等级上限。
│   │   └── upgrade_definition.gd.uid  # 关联GDScript稳定资源标识。
│   ├── ui/  # 发布入口、主菜单与表现外壳
│   │   ├── arena_skin.gd  # 按现有碰撞坐标绘制生成地面、四墙、斜坡与拐角贴图；不改物理。
│   │   ├── arena_skin.gd.uid  # 关联表现资源的稳定标识。
│   │   ├── card_flow.gd  # 暂停期间运行的卡框边缘流光，鼠标穿透且不发奖励。
│   │   ├── card_flow.gd.uid  # 关联GDScript的稳定资源标识。
│   │   ├── credits_panel.gd  # 设置中的只读可滚动制作/许可全文弹窗，APK离线可访问，来源只在打开时读取。
│   │   ├── credits_panel.gd.uid  # 同名GDScript的Godot稳定资源UID，随脚本提交。
│   │   ├── game.gd  # 正式完整游戏外壳，隐藏调试控件，显示正式进度与暂停返回。
│   │   ├── game.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── health_cell.gdshader  # 裁掉Atlas相邻像素，只保留斜切单个生命格。
│   │   ├── health_cell.gdshader.uid  # 关联表现资源的稳定标识。
│   │   ├── health_skin.gd  # 消费DemoHealthView真实状态，动态分格生命与逐格提亮，保留准确数字。
│   │   ├── health_skin.gd.uid  # 关联表现资源的稳定标识。
│   │   ├── main_menu.gd  # 原菜单导航/Live2D接线、无动物背景及DS人物插画与偏好的双栏设置。
│   │   ├── main_menu.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── menu_character.gd  # Native角色头眼跟随、固定头身短动作和安全表情、短冷却打断/黑脸禁止/阻断恢复，不读写玩法
│   │   ├── menu_character.gd.uid  # 同名GDScript的稳定资源UID，随脚本保留
│   │   ├── menu_character_view.gd  # 菜单与逻辑画布坐标换算、真实alpha点击/抚摸分类、GUI及窗口焦点阻断
│   │   ├── menu_character_view.gd.uid  # 同名GDScript的稳定资源UID，随脚本保留
│   │   ├── music_manager.gd  # 全局单播放器、Music总线、原曲循环/跨场景播放与音乐音量/全部静音持久化
│   │   ├── music_manager.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── ocean_motion.gd  # DS鲸鱼娘八帧人物演出与按钮渐变，静候后回应，减少动态固定首帧。
│   │   ├── ocean_motion.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── ocean_ui.gd  # 共享蓝白主题/控件样式、OFL中文fallback与减少动态，不决定玩法。
│   │   ├── ocean_ui.gd.uid  # 关联GDScript稳定资源标识。
│   │   ├── release_menu_paths.gd  # 仅Windows含旁置模型导出副本启用的新增autoload，在原角色ready前设置已有路径输入，不改Live2D文件。
│   │   ├── release_menu_paths.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── result_body.gd  # 只展示传入胜负/记录，选择内置生图人物并测量说明宽度。
│   │   └── result_body.gd.uid  # 关联GDScript稳定资源标识。
│   ├── ball.gd  # 控制球的停稳、冲量发射、刚体复位与真实接触事件。
│   ├── ball.gd.uid  # 关联GDScript稳定资源标识。
│   ├── impact_feedback.gd  # 共用亮环/震动/粒子；run音频路由独立调度，旧场景保留原声音接口。
│   ├── impact_feedback.gd.uid  # 关联GDScript稳定资源标识。
│   ├── main.gd  # 组织关卡输入、拖拽瞄准、杆数、HUD、目标胜利和重置。
│   ├── main.gd.uid  # 关联GDScript稳定资源标识。
│   ├── mechanism.gd  # 管理区域内的加速、粘滞或反向重力及离开后的恢复。
│   └── mechanism.gd.uid  # 关联GDScript稳定资源标识。
├── tests/  # 无需测试插件的游戏行为检查
│   ├── menu_character_actions.gd  # 原生GUI部位点击到Live2D头身动作、打断与安全阻断和提示布局验证
│   ├── menu_character_actions.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── menu_character_expressions.gd  # 原生Live2D五组安全表情、黑脸禁止与恢复专项；headless只验回退
│   ├── menu_character_expressions.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── menu_character_integration.gd  # 正式菜单真实引擎输入、头眼/点击/遮挡/焦点/释放与游戏返回、缩放和回退检查
│   ├── menu_character_integration.gd.uid  # 同名GDScript的稳定资源UID，随脚本保留
│   ├── music_manager.gd  # 真实MP3及短循环夹具、场景连续播放、音乐UI与静音/配置保留回归
│   ├── music_manager.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── ocean_ui.gd  # 双分辨率DS分栏/输入/音量/HUD隔离、全卡池窄四卡及胜负统计/导航回归。
│   ├── ocean_ui.gd.uid  # 关联GDScript稳定资源标识。
│   ├── platform_mobile.gd  # 真实原生触摸归属、模拟鼠标去重、取消/Back后台与预算满载音频的行为回归。
│   ├── platform_mobile.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_actor_views.gd  # 伙伴/首领物理不受表现影响、真实事件与快照隔离回归
│   ├── roguelite_actor_views.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_audio.gd  # 音组变体、PCM余量、优先级预算、混音与生命周期调度回归。
│   ├── roguelite_audio.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_balance_metrics.gd  # 真实伤害/伙伴归因/冲量、夹具升级/冷却/种子复现及实际首领代理类型边界验证
│   ├── roguelite_balance_metrics.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_ball_animation.gd  # 真实Game生命与去重击杀驱动、碰撞姿势、物理不变、暂停和碎帧清理验证
│   ├── roguelite_ball_animation.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_ball_art.gd  # 透明/裁切/稳定AI与病毒身份/物理不变及ALWAYS父节点下特效暂停回归
│   ├── roguelite_ball_art.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_boss.gd  # 首领真实撞墙/模块接触、弱点时序、护甲、缺口与死亡回归。
│   ├── roguelite_boss.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_build.gd  # 十五项池资格/权重/上限、派生参数与碰撞升级预算边界回归。
│   ├── roguelite_build.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_build_economy.gd  # 金币重选合法替代/限次/费用/revision事务与主球三不同敌精确冷却回能回归。
│   ├── roguelite_build_economy.gd.uid  # 同名GDScript的Godot稳定资源UID，随脚本提交。
│   ├── roguelite_build_economy_gui.gd  # 原生GUI真实鼠标输入重选/入场防双点、三四卡宽窄屏与正文滚动回归。
│   ├── roguelite_build_economy_gui.gd.uid  # 同名GDScript的Godot稳定资源UID，随脚本提交。
│   ├── roguelite_build_feedback.gd  # 构筑与真实策略成功提示、精准实际回能、暂停/重开/减少动态与宽窄屏边界回归。
│   ├── roguelite_build_feedback.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_card_art.gd  # 真实HUD的28级贴图映射、标题/收益/规则、重复项及近满血恢复检查
│   ├── roguelite_card_art.gd.uid  # 同名GDScript的稳定资源UID，随脚本提交
│   ├── roguelite_card_content_flow.gd  # 全16卡290×480含hover/流光的安全内边距及纵向顺序回归
│   ├── roguelite_card_content_flow.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_card_gestures.gd  # 卡片原生触摸/模拟鼠标/鼠标拖动拒误选、tap/键盘选择及长卡滚动传播回归。
│   ├── roguelite_card_gestures.gd.uid  # 同名GDScript的Godot稳定资源UID，随脚本提交。
│   ├── roguelite_card_typography.gd  # 两种分辨率三四卡及最窄全16张的字体/完整文案/数字/控件边界回归
│   ├── roguelite_card_typography.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_crowd.gd  # 真实三重敌推进/后排受推/实体碰撞与续力限次/到期/重开预算回归。
│   ├── roguelite_crowd.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_damage_contacts.gd  # 四方向/四距离/两节点顺序真实击破及低速/被动无伤回归。
│   ├── roguelite_damage_contacts.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_difficulty.gd  # 五波30秒未清场压力上限、强敌配额与重开/直接生成预算回归。
│   ├── roguelite_difficulty.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_enemies.gd  # 三敌人预警/攻击、生命无敌、危险弹与旧事件回归。
│   ├── roguelite_enemies.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_enemy_readability.gd  # 三敌人范围即时取消/重新蓄力、生命覆盖和受伤跨颜色等级回归。
│   ├── roguelite_enemy_readability.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_feature_acceptance.gd  # 逐张合法卡池到真实按钮选择的正式构筑接线与物理效果验证
│   ├── roguelite_feature_acceptance.gd.uid  # 逐项成长功能验收脚本UID
│   ├── roguelite_feedback_integration.gd  # 整局真实事件到音效、静音/结算尾音与生命面板重开集成回归。
│   ├── roguelite_feedback_integration.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_fish_view.gd  # 视觉形变不改变物理、有效HP浮字与释放回归
│   ├── roguelite_fish_view.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_full_tuning.gd  # 完整目录、真实引擎读回、资源隔离/新实体、别名恢复、类型与重启配置回归。
│   ├── roguelite_full_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_gameplay_lab.gd  # 八夹具真实发射/构筑与覆盖、阵型拒绝、分裂两代AI/经济、预设迁移/失败与输入隔离回归。
│   ├── roguelite_gameplay_lab.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_hero_smooth.gd  # 30/60/120/144Hz连续呼吸/事件运动边界及原点/纹理稳定回归
│   ├── roguelite_hero_smooth.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_hero_smooth_capture.gd  # 原生渲染待机与事件的原尺寸/放大连续帧采集，headless明确跳过捕获
│   ├── roguelite_hero_smooth_capture.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_hud.gd  # 真实生命受伤/恢复/上限/无敌/死亡/复位与鼠标穿透回归。
│   ├── roguelite_hud.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_input_feedback.gd  # 全屏真实鼠标事件、冷却临界帧、正常速度、接触反馈位置与复位清理回归。
│   ├── roguelite_input_feedback.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_kill_rewards.gd  # 击杀门槛/溢出/去重/排队/复位与非法调参回归。
│   ├── roguelite_kill_rewards.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_kill_run.gd  # 真实死亡领奖、保留弹体暂停、连续奖励/旧卡保护、胜负和整局重置。
│   ├── roguelite_kill_run.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_launch_rewards.gd  # 双发容量/串行恢复/幂等应用与滑行独立材质回归。
│   ├── roguelite_launch_rewards.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_live_tuning.gd  # 实时滑杆/数字接线、真实冲量、成长/重开、已有/新敌人、暂停所有权与存取隔离回归。
│   ├── roguelite_live_tuning.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_map_blueprints.gd  # 图纸布局、真实轨迹、尖刺尺寸、翻板扫掠和Boss双组门三类身体双向保速回归
│   ├── roguelite_map_blueprints.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_map_flow.gd  # 正式菜单到四图、成长商店事件、胜负重开及地图释放的流程夹具与首领撞刚体挡板回归
│   ├── roguelite_map_flow.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_map_mechanisms.gd  # 真实刚体翻转、物理运动机关、暂停复位及尖刺伤害回归
│   ├── roguelite_map_mechanisms.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_map_navigation.gd  # 真实空间旋转快照下环内外通行、封闭内圈及完整Boss出生/圈外路线回归
│   ├── roguelite_map_navigation.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_maps.gd  # 旧场地地图接口、真实障碍与安全出生查询回归
│   ├── roguelite_maps.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_paddle_response.gd  # 真实主球多方向/速度撞击、偏心轴、反复限位与停转复位回归
│   ├── roguelite_paddle_response.gd.uid  # 翻转板转速及限位回归脚本UID
│   ├── roguelite_pause_physics.gd  # 四张真实地图中危险球Area2D致死的查询锁及翻板延后状态revision回归。
│   ├── roguelite_pause_physics.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_platform_pause_order.gd  # Android系统Back/挂起意图在正常idle原子消费、输入屏障及旧局失效的13项顺序回归。
│   ├── roguelite_platform_pause_order.gd.uid  # 同名GDScript的Godot稳定资源UID，随脚本提交。
│   ├── roguelite_portals.gd  # 传送保速、去重、堵塞/死亡/暂停取消、双体出口及高速往返回归
│   ├── roguelite_portals.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_presentation_interface.gd  # 敌人视图替换、生命面板、真实拒伤结果和物理签名不变回归。
│   ├── roguelite_presentation_interface.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_reward_effects.gd  # 分级重击、有限二连撞、攻击缩圈、无伤震退与旧局事件回归。
│   ├── roguelite_reward_effects.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_rice.gd  # 平面吸力、安全生成/过期/暂停、满血禁生成与回血上限/通知检查。
│   ├── roguelite_rice.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_run.gd  # 整局清残敌、击杀升级/暂停优先级、五次清波到首领、胜负与十次重开检查。
│   ├── roguelite_run.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_sea_ui.gd  # 两种窗口的商店按钮状态、结算位置与焦点夹具验证
│   ├── roguelite_sea_ui.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_sea_ui_formal_game.gd  # 正式Game最窄四卡的全16种完整规则/趣味句边界与HUD遮挡回归
│   ├── roguelite_sea_ui_formal_game.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_sea_ui_integration.gd  # 正式Game两窗口三四卡真实卡片、商店经济状态、暂停与恢复集成验证
│   ├── roguelite_sea_ui_integration.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_sea_ui_mouse.gd  # 正式Game真实鼠标购买/重复禁用、暂停恢复和结算重开集成验证
│   ├── roguelite_sea_ui_mouse.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_shop_events.gd  # 钱包死亡去重、余额限购、旧报价、商店独立成长与重开回归。
│   ├── roguelite_shop_events.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_smoke.gd  # 俯视发射/接力、默认不跟随、三态障碍反弹、可选引导与回收检查。
│   ├── roguelite_smoke.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_splitting.gd  # 分裂勾选接线、两代生命/预算/整族经济、安全预警与旧局防重回归。
│   ├── roguelite_splitting.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_stage_flow.gd  # 清场阶段边界、危险清理、冷却暂停、准备、免费成长来源与旧点击回归。
│   ├── roguelite_stage_flow.gd.uid  # 关联GDScript稳定资源标识。
│   ├── roguelite_strategy_payoff.gd  # 深代直伤/爆破/撞杀余势、真实传能刚体链、来源生命周期、后段交易与seed回归。
│   ├── roguelite_strategy_payoff.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_tactical_aim.gd  # 正式Game瞄准冻结/动量/冷却等待/暂停接管/失焦/重开及箭头动画回归
│   ├── roguelite_tactical_aim.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── roguelite_theme.gd  # 主题替换/饱饭绘图不改变刚体签名或同伴状态的检查。
│   ├── roguelite_theme.gd.uid  # 关联GDScript稳定资源标识。
│   ├── smoke.gd  # 旧原型停稳、发射、真实接触点、机关、复位、鼠标与进球回归。
│   ├── smoke.gd.uid  # 关联GDScript稳定资源标识。
│   ├── test_prepare_menu_live2d.py  # 本机菜单资源准备的幂等、内容保护、缺来源/复制失败及路径越界回归；不执行模型或Native库
│   ├── ui_integration.gd  # 正式菜单/输入/暂停/卡图文字排版/结算返回的引擎合成输入集成检查
│   └── ui_integration.gd.uid  # 同名GDScript的稳定资源UID，随脚本提交
├── tools/  # 开发辅助工具，不属于游戏玩法
│   ├── live2d_menu_sample/  # 另一对话的Live2D独立菜单/参数/生命周期样板源与准备验证工具，不进入正式游戏
│   │   ├── .gdignore  # 阻止Godot把隔离Live2D样板作为正式工程资源导入
│   │   ├── character.gd  # 精细成年模型的真实头眼/身体物理输入、作者手势/表情与减少动态仲裁，保留原绑定
│   │   ├── character.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── entry.gd  # 独立Live2D发布入口，选择试玩、旧回归、生命周期或近景/身体视觉复验，不连接正式游戏
│   │   ├── entry.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── entry.tscn  # 隔离Live2D发布样板的可编辑根入口场景
│   │   ├── lifecycle.gd  # 隔离模型重复创建/渲染/释放的有界观察与证据输出，不证明无泄漏
│   │   ├── lifecycle.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── lifecycle.tscn  # 隔离模型生命周期观察的根场景
│   │   ├── menu_sample.gd  # 独立Live2D菜单、透明命中/触摸、近景缩放坐标和设置阻断，不读写玩法/正式设置
│   │   ├── menu_sample.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── menu_sample.tscn  # 独立Live2D菜单样板布局与模型SubViewport场景
│   │   ├── prepare.py  # 使用已有本机资源准备独立Live2D夹具，不下载或修改正式工程
│   │   ├── verify_sample.gd  # 隔离模型与引擎输入分发/释放检查，记录证据不冒充人类试玩
│   │   ├── verify_sample.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── verify_visual.gd  # 近景真实输入、身体渲染网格/负对照、闭眼/作者手势和全身恢复的窗口复验，不代表审美或完整L0
│   │   ├── verify_visual.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   └── verify_windows.py  # 等待Windows Godot/Release子进程并保留输入或生命周期验证证据
│   ├── whale_menu_sample/  # 与正式工程隔离的成年鲸鱼娘原生3D菜单实验；源码、准备和真实输入/渲染检查，专业效果未验收
│   │   ├── .gdignore  # 阻止正式Godot工程扫描独立3D样板，先准备.local夹具再运行
│   │   ├── additive_motion.gd  # 只转移现成Idle/谈话相对参考帧的四骨旋转微动，保留原始骨架/蒙皮与四肢姿态
│   │   ├── additive_motion.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── character.gd  # 原始成年GLB及现成源动作加载、微动/形态键回应和样板材质调整
│   │   ├── character.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── gaze_motion.gd  # 在身体微动后叠加真实头颈注视、点头和尾巴小幅动态并记录处理后头部姿态
│   │   ├── gaze_motion.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── menu.gd  # 独立菜单输入、按钮、头部命中、设置阻断和近景相机，不连接正式游戏
│   │   ├── menu.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── menu.tscn  # 原生3D菜单实验的透明高分辨率Stage、固定相机和可编辑角色显示结构
│   │   ├── prepare.py  # 从已取得的模型/动作ZIP创建新隔离工程、许可与哈希清单，拒绝覆盖已有夹具
│   │   ├── verify_lifecycle.gd  # 20轮headless实例化释放、弱引用与对象回收检查，不证明完整L0或GPU/私有内存无泄漏
│   │   ├── verify_lifecycle.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   │   ├── verify_sample.gd  # 实际输入分发、处理后骨骼与GPU截图差分、反应/设置/减少动态的独立样板检查
│   │   └── verify_sample.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── analyze_balance.py  # 按固定分组规则比较相同种子/策略原始结果，不伪造用户认可
│   ├── analyze_transfer.py  # 比较同源实际传能候选，使用真实伙伴直接HP归因和硬门槛
│   ├── balance_search.ps1  # 固定源文件指纹并运行串行或逐条隔离进程的数值矩阵
│   ├── build_icon.gd  # 把生成PNG缩放封装为七尺寸Windows ICO的可复现工具
│   ├── build_icon.gd.uid  # 同名GDScript的稳定资源UID，由Godot生成并随源码提交。
│   ├── export_android.ps1  # 隔离APPDATA的Android release暂存/参数化SDK、签名验证、aapt2与真实APK资源探针。
│   ├── export_windows.ps1  # 唯一暂存Windows release、可选旁置Live2D新增接线/字节清单、许可与递归完整ZIP。
│   ├── live2d_l0_model_test.gd  # 隔离Live2D示例模型加载、透明姿态截图、参数与可配置重复释放检查；仅复制到.local运行
│   ├── live2d_l0_model_test.gd.uid  # Live2D隔离模型验证工具脚本UID
│   ├── package_probe.gd  # 读取实际导出内嵌包，检查正式地图/输入/流程及28卡图/JSON文案是否完整
│   ├── package_probe.gd.uid  # 同名GDScript的稳定资源UID，随脚本提交
│   ├── prepare_live2d_l0.ps1  # 在忽略的.local重建可复现引擎/导出基线；不下载SDK、不接受许可、不冒充模型验证
│   ├── prepare_menu_live2d.py  # 只从已有本机夹具准备.local私有模型/已适配桥接/Shader和图集缓存，不下载或打发行包
│   ├── project_map.gd  # 从Git可见文件与用途清单生成目录/架构，包括正式卡片与独立图鉴调用关系
│   ├── project_map.gd.uid  # 关联GDScript稳定资源标识。
│   ├── release_notices.gd  # 从实际Godot引擎生成Godot和编译依赖许可文本的随包工具。
│   ├── release_notices.gd.uid  # 同名GDScript的Godot稳定资源UID，随脚本提交。
│   ├── validate_natural_runs.ps1  # 逐个引擎进程跑真实卡池与正常AI完整局，记录自然死亡/胜利/截尾并拒绝错误日志
│   └── verify.ps1  # 每批隔离APPDATA的固定引擎导入/目录与61套行为回归入口，校验各套完成标志并恢复用户环境。
├── .editorconfig  # 统一编码、缩进、换行和文件末尾格式。
├── .gitattributes  # 统一 Git 文本换行，标记图片/音频为二进制。
├── .gitignore  # 排除引擎缓存、本机临时文件、凭据和导出成品。
├── AGENTS.md  # 接手/物理/审查与Git授权、DS鲸鱼娘身份固定、双线唯一写入及owner边界。
├── CONTRIBUTING.md  # Git分支/Review/授权与A/B独立checkout及用户最终审阅合并约定。
├── README.md  # 游戏介绍、运行方式和面向开发者的总入口。
├── export_presets.cfg  # Windows x86_64及Android ARMv7/ARM64发布预设、真实版本与分层DS安卓图标。
└── project.godot  # Godot 工程入口：主场景、窗口、渲染、物理和碰撞层设置。
```

## 主要关系

```text
project.godot → scenes/ui/main_menu.tscn → scripts/ui/main_menu.gd（正式入口）
  ├─ MusicManager（跨场景背景音乐）
  ├─ menu_character（可选Live2D，缺资源静态回退）
  └─ scenes/ui/game.tscn → game / run_arena / run_director

旧侧视实验：scenes/main.tscn → scripts/main.gd（F6独立运行）
  ├─ scenes/ball.tscn → scripts/ball.gd（刚体与碰撞信号）
  ├─ scenes/mechanism.tscn → scripts/mechanism.gd（区域机关）
  └─ scripts/impact_feedback.gd ← impacted 信号（碰撞表现）

scenes/roguelite/arena.tscn → arena.gd（独立俯视三靶场）
  ├─ launch_controller → player_ball → combat_body（冲量/接触）
  ├─ companion_manager → companion_ball（初始摆球/接力/可选跟随）
  ├─ collision_combat → destructible（去重伤害）
  └─ impact_feedback（共用表现，新场景粒子零重力）

scenes/roguelite/run.tscn → run_arena → run_director（阶段/击杀领奖/胜负）
  ├─ enemy / player_health / hazard_ball（三敌人与可预警危险）
  ├─ run_build → resources/roguelite/upgrades（十五项池/分类权重）
  ├─ boss（可碎模块/撞墙弱点/缺口震波）
  ├─ run_hud（生命/3/4选卡/结算/重开）
  │  └─ result_body（DS胜负人物与真实记录，只读展示）
  ├─ stage_flow / run_wallet → rest_panel（商店/补给/准备）
  ├─ audio_director → audio_palette（事件音组/声部预算）
  └─ rice_manager → rice_lure / theme_definition（白饭平面力/肥鱼绘图）

tools/verify.ps1 / GitHub CI
  ├─ Godot 导入检查
  ├─ tools/project_map.gd --check（文件目录完整且最新）
  ├─ tests/smoke.gd（旧侧视行为回归）
  ├─ tests/roguelite_smoke.gd（俯视发射/碰撞/接力/归队）
  ├─ tests/roguelite_input_feedback.gd（全屏手势/冷却临界/反馈坐标）
  ├─ tests/roguelite_{enemies,build,boss,run,rice,theme}.gd（整局/白饭/主题规则）
  └─ tests/roguelite_{kill_rewards,kill_run,launch_rewards,reward_effects}.gd（击杀发育雏形）
  └─ tests/roguelite_{audio,hud,feedback_integration,stage_flow,shop_events}.gd（音效/生命/阶段经济）
  └─ tests/roguelite_{crowd,difficulty}.gd（怪群真物理/逐波压力预算）
  └─ tests/roguelite_{damage_contacts,enemy_readability,splitting}.gd（漏伤/范围与生命/可选分裂）
```

## 策划实时手感

```text
tuning_run.tscn → 正式run + live_tuning + full_tuning（完整属性/快捷基线/存取）
  ├─ tuning_panel + full_tuning_view（F1分类/搜索/分页/各类型编辑）
  └─ tests/roguelite_{live_tuning,full_tuning}.gd（实时物理/全局恢复/类型/资源隔离）
```

## 玩法实验室与表现接口

```text
scenes/roguelite/gameplay_lab.tscn → gameplay_lab（B线完整夹具）
  ├─ DemoLaunch.launch_with_drag → player_ball → combat_body（正式固定发射/真实接触）
  ├─ RunDirector.spawn_enemy/queue_split（正式敌人与分裂规则）
  ├─ boss / player_health / hazard_ball（范围、炮台和首领夹具）
  └─ DemoLabPanel → GameplayLab（白名单请求、读数、有界日志、本地预设）

enemy.tscn → DemoEnemy（玩法状态/事件）
  └─ DemoEnemyView（只读快照与绘制替换）
run_hud.tscn → RunHUD（奖励/结算）
  └─ DemoHealthView（只读生命面板替换）

tests/roguelite_presentation_interface.gd（换图不改物理/面板请求）
tests/roguelite_gameplay_lab.gd（固定发射/八类夹具/预设/日志边界）
```

图中关系是人工维护的架构摘要，文件树由工具生成；改变模块关系时也要更新生成器中的摘要，并通过 Review。维护方法见 [教程 002](tutorials/002-project-map-and-review.md)。
## 正式成长卡与独立图鉴

```text
RunDirector 合法候选/等级/offer_id → RunHUD.show_choices
  ├─ CardArtLibrary → card_art_catalog.json → assets/cards（16种成长、28张基础图）
  ├─ upgrade_card_copy.json（玩家说明/趣味短句）
  ├─ benefit_preview → DemoBuild/实际生命（真实收益）
  └─ upgrade_card.tscn/.gd（正式Button：图/等级/收益/说明）
       └─ upgrade_selected(id, offer_id) → 原RunDirector校验/应用/恢复

card_art_gallery.tscn → card_art_gallery.gd（F6独立筛选/分页/三四卡）
  └─ 同一插画索引 + card_art_card.tscn（不发升级请求）
```

正式奖励、商店成长与补给成长共用RunHUD；文案与图片不改变Buff或物理规则。技术接线与用户审美验收分开。
## 可选Live2D开始界面

```text
main_menu.tscn/.gd → menu_character.tscn（透明SubViewport/原PNG回退）
  └─ menu_character_view.gd（GUI/焦点/alpha命中/鼠标坐标）
       └─ menu_character.gd（头眼输入/原物理/短回应）
            └─ .local/menu_character_runtime（已有Native资源，仅本机）
tools/prepare_menu_live2d.py → 私有目录（不下载，不打发行包）
```

缺少资源或headless使用静态回退；菜单不写玩法，开始/返回仍走原流程。见[教程040](tutorials/040-live2d-start-menu.md)。
