# 球体少帧动画与重量反馈

## 原理与文件

本轮保留用户认可的七张球体身份。`assets/roguelite/ball_animation_r5/`四张透明sheet由内置imagegen分别引用hero/三个virus原图生成；不是将同一图缩放冒充新素材。`ball_art.gd.animation_frame()`用AtlasTexture引用2×2单身份图集，每格独立按真实alpha边界裁切，原图完整保留。hash见同目录hashes.json。

hero四格依次为长椭圆睁眼、矮椭圆半闭眼、撞击闭眼鼓脸、受伤痛脸；病毒四格为挤压受伤、拉伸反弹、壳裂击破、散落碎片。中性圆仍用原图。

`fish_ball_view.gd`在Sprite层循环idle，默认2.4秒、幅度0.055；可在检查器修改idle_period/idle_amplitude。真实contact选第三格0.16秒，damage选第四格0.28秒；kill仅有力回弹和水纹。reset清除表情/时钟，所有缩放只影响Sprite。主角最长边58、伙伴36，物理根不动。

伙伴保留GPT/Claude/Qwen独立身份，以2.7秒小幅原点椭圆循环表现呼吸。敌人三角色×三等级共享对应tier的受击pose，HP数字/生命环/炮口与预警保持独立。`material_for_kind`仍返回稳定出生身份纹理，绘制时才临时选动画，避免掉血改变身份。boss真实core_hurt/module_hurt选对应受击pose。

`virus_burst.gd`仅由真实died事件产生，读取出生tier，前半寿命画裂壳，后半画碎片；最多12组、0.32秒，PAUSABLE暂停后保留剩余寿命。没有碰撞/伤害能力。

## 事件契约与验证

主角原actor只有launch/reset；真实掉血通知由director转发health.damaged(actual)为visual_event damage/effective_damage，kill只在rewards首次接受后通知。动画不推断伤害成功。玩家无敌/治疗/reset不能播放痛脸，重复奖励不能播放kill。

本机Godot4.7.1运行旧roguelite_ball_art回归：先出现6个稳定身份接口失败，修复后53检查0失败。新增独立专项`tests/roguelite_ball_animation.gd`以正式Game验证实际health.hurt、无敌拒绝、治疗/reset、去重kill、真实墙壁接触、伙伴/Boss姿势、物理签名、暂停与碎片上限/清理；原生Compatibility和headless均67项零失败。最终日志为`.local/ball_animation_review_final.log`与`_final_headless.log`，无ERROR/WARNING。

真实小尺寸截图发现首版sheet没有mipmap，约630像素帧缩到58/42出现锯齿；四张图集现开启mipmap，size_limit=1024，每格约512。Atlas.filter_clip阻止跨格采样；重拍pain、contact、burst与16帧atlas_grid确认完整和表情差别。尾帧绘制还复现combat_float退化菱形的三角化ERROR，现于尺寸小于0.15时跳过不可见尾端，复测不再报错。数值断言通过但渲染日志报ERROR的中间轮次不算验收通过。

这些是引擎驱动的技术与截图验收，不能替代用户对动画节奏的审美判断或真人自然整局。

常见问题：不要将sheet当整张Sprite；不要给PhysicsBody缩放；不要用瞬时剩余hp挑身份；不要让临时effects继承ALWAYS导致暂停继续播放。若新生图四格构图偏移，先检视每格alpha边界与脸部可读性，再调整切片，不能偷偷重画原角色。
