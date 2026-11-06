# 玩个球应用图标

2026-11-06使用内置image_gen，引用项目已认可的ball_art_r4/hero.png生成独立正方形图标。蓝发鲸鱼女仆团子、深海背景，未使用网络图标或Godot默认标志。

- playaball.png：生成原画，项目图标与窗口图标。
- playaball.ico：tools/build_icon.gd由PNG进行Lanczos采样，封装16、24、32、48、64、128、256七种尺寸，Windows导出使用。
- 工具只缩放及封装格式，不替代生图绘画。修改PNG后重新运行工具；Windows旧快捷方式可能保留系统图标缓存，应先核验新EXE本身。
