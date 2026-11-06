# 046 菜单Live2D安全表情与自然互动

## 为什么修改

用户提供的菜单截图中，角色上半脸被阴影遮住。本次实际查到本机menu_profile.json把annoyed映射到作者的“黑脸”；Exp3/黑脸.exp3.json写入key1=1，作者cdi3说明也将key1标作“黑脸”。这与旧三连点路径和截图一致。作者“屑屑眼”使用key6，菜单也一并禁用，避免阴沉眼神；没有把其他未经证实的参数猜成黑脸原因。

本轮替代教程040中“三连点升级不满”和“作者黑脸表情”的旧说明。没有重新下载模型、SDK，也没有修改.local中的profile、exp3、moc3或纹理，不需要新的prepare步骤。原工具准备出的旧profile即使仍包含annoyed=黑脸，新驱动也不会读取其reactions表或播放start_expression。私有模型继续留在.local，原资源缺失时使用已有静态回退。

## 文件、节点与职责

- scripts/ui/menu_character.gd：已有模型加载、输入参数平滑及短表情仲裁。
- scripts/ui/menu_character_view.gd：现有透明像素命中、头顶/脸颊/身体输入分类，本轮沿用。
- scenes/ui/menu_character.tscn：Stage/Character真实Native模型，Portrait显示透明SubViewport，Fallback保持旧资源。
- tests/menu_character_expressions.gd：真实参数和原生渲染专项，不以静态替代图验证Live2D。
- tests/menu_character_integration.gd：正式菜单输入、设置、焦点、开始与返回的既有验证，三连点断言更新为温和惊讶。

## 输入 → 逻辑 → 输出

头顶轻点或慢速抚摸产生pet：闭眼微笑。脸颊点击产生cheek：短暂鼓脸。身体点击的慢速完整回应依次为greet、shy、wink：单眨眼招呼、腮红害羞、单眨眼；未完成的回应不会每帧重启。1.4秒内三次点击只升级一次surprised：睁眼、轻张嘴的温和惊讶，不播放黑脸或大幅抬手。

驱动用SAFE_REACTIONS白名单拒绝未知反应，包括旧annoyed。reaction_remaining默认2.1秒。进入用0.15秒淡入，最后0.35秒淡出；时间结束归idle。所有表情由模型真实存在的输入构成：EyeSmile、ParamEyeLOpen/ROpen、ParamMouthForm、ParamMouthOpenY、CheeckPuff、key7腮红与BrowInnerUp。旧代码里的ParamEyeLSmile并不存在，因此本轮改为作者实际提供的EyeSmile。

每帧把key1与key6保持为0，防止旧本机配置或待机动作重新留下危险开关。设置与失焦通过set_blocked(true)立即调用_reset_safe_face：停止作者表情，清反应时间和连点队列，复位眼睑、嘴、腮红及鼓脸。减少动态也立即复位，并拒绝新的互动反应；关闭减少动态后恢复已有作者物理，不补发旧点击。开始游戏释放整个角色节点，返回菜单重新加载安全中立。开始、退出、设置按钮逻辑未修改。

## 在检查器中调参和扩展

选择MenuCharacter/Stage/Character，Response Seconds控制短回应总长；Head Follow Time和Eye Follow Time继续控制注视速度，Head Angle Limit和Eye Range限制幅度。为了保留短回应可见性，不要把Response Seconds设为小于淡入/淡出总和。Display Height只调整显示尺寸，不是骨骼动画。

新增表情时，先在作者cdi和实际get_parameters结果中确认参数ID。把名称加入SAFE_REACTIONS，在step_character的match分支定义有限幅值，并在_reset_safe_face里补复位值。不要直接重新接profile.reactions，也不要解除key1/key6的零值保护。图形专项至少检查参数实际存在、截图输出不同、自然恢复以及设置/失焦/减少动态的即时复位。不要强写手臂物理输出或引入新的骨骼求解器。

## 复现、证据与限制

本机LAPTOP-8GS4N5SG，Windows10.0.26200，Godot4.7.1.stable.official.a13da4feb标准版/Compatibility。真实命令：

```powershell
& <本机Godot4.7.1实际路径> --path . --script tests/menu_character_expressions.gd
& <本机Godot4.7.1实际路径> --path . --script tests/menu_character_integration.gd -- --expect-live2d --out=res://.local/menu_expression_20261106/integration
```

新表情测试先原生红灯5项，检出三连点key1、阻断后状态/黑脸未清及后续反应受旧状态影响；修后21项通过、退出0。旧正式菜单专项28项通过、退出0。日志为.local/menu_expression_20261106/red.log、green.log、integration.log。目录中的pet、cheek、greet、shy、surprised、safe_neutral及对应_menu.png是原生Viewport截图，已逐组查看；至少四组眼睑/嘴/腮红组合真实不同。截图和私有资源不提交。

headless只验证无图形回退，不能代替本机Native表情验收。技术通过和本次查看不代表用户认可审美，也不包含另一台机器、完整L0内存、SDK发行授权或自然抬手问题的解决。若另一台机器没有私有资源，应保留回退导航，不能复制私人模型进公共assets解决。
