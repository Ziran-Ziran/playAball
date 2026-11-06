# 球体人物参考与本轮取舍

日期：2026-11-05。网络核查由mascot_references子Agent完成，最终生成与接线由根Agent完成。

## 参考的实际含义

- 大肥鱼是社区鲸鱼娘方向：蓝发、鲸鳍、白色女仆头饰与鲸尾，不能误画成普通蓝鲸。参考[社区设定与来源署名](https://github.com/xiaoweigen/deepseek-dafeiyu-assets)。本轮只取辨识元素，项目内角色PNG由内置imagegen生成，不把网页原图作为生产贴图。
- GPT的可靠视觉锚点是[OpenAI Blossom结绳标记](https://openai.com/brand/)，没有将某款任意白发少女认定为官方拟人形象。
- Claude的Clawd橙色像素蟹在社区有辨识度，见[官方仓库中的社区请求](https://github.com/anthropics/claude-code/issues/42415)。该请求是社区发言，不将其文字当作完整官方角色设定。
- 千问参考[官方Qwen3仓库](https://github.com/QwenLM/Qwen3)的紫色三组互扣几何箭头标记；不是任意三叶花或紫发少女的官方身份声明。

## 用户反馈优先于符号堆叠

首张样例的人物团子方向被用户认可，但AI伙伴辨识不足。随后生成过大徽记/像素蟹机器球，用户明确认为不如原来的GPT/Claude。本轮最终恢复原人物团子：GPT白发薄荷斗篷，Claude杏色卷发眯眼，千问紫发云纹；网络标记只作为小发饰。机器人版本留在忽略的`.local/art_pass_20261105/rejected_robot`，不作为当前候选和生产贴图。

这些是参考网络视觉锚点的游戏二创人物，不宣称是各公司的统一官方拟人角色；当前最终小尺寸审美仍由用户判断。

## 生成记录

[ball_art_r4.json](ball_art_r4.json)逐张记录内置生图模块、完整提示词、生成输出文件名、PNG尺寸、最终工程路径和SHA256。七张生产PNG位于`assets/roguelite/ball_art_r4/`，保留透明通道，512导入限制与mipmap。去除两张人物候选外部光晕的编辑同样使用内置imagegen，不用脚本抠图改变角色画面。
