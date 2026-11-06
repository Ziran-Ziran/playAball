# 049 卡片真实内容流与内边距

用户截图的问题不是单纯字号：旧框位图内有固定分隔，收益百分比坐标压在分隔线上；底句按94%卡高再加固定高度，突破内框；旧验证只比较标签局部位置，没有保证整个内容顺序和卡内安全边距。

## 新结构

UpgradeCard保留可编辑动态Label与原节点路径。框改为可编辑StyleBoxFlat，移除不受布局控制的位图分隔。Category、Heading、Illustration、Level、Preview、Detail、Flavor按顺序排列，全部在20px内边距内。先按真实字体、当前宽度测量文字最小高度与行高，再把剩余高度分配给插画；正文不再按卡高百分比定位，不删规则、不烘焙数值、不靠hover缩放挪位置。

实际窄四卡收益17px、较宽卡20px，规则保持检查器detail_font_size，名称保持title_font_size。它们是明确宽度断点，而非不断压小文字勉强塞进旧矩形。_place统一写入局部位置；每次resized重新计算，configure输入仍来自真实升级资源和收益算法。删除已无意义的插画百分比参数与_fit循环，避免检查器调参不生效。

## 正式接线和图鉴

RunHUD展示奖励前移除父Game注入的大纹理面板override，使用统一主题内容边距。既有进场透明度/缩放与独立card_flow不改变内容坐标；测试在hover状态保留流光。图鉴是独立VBox容器组件，不调用旧UpgradeCard百分比排版，本次不替换图鉴结构，实际捕获确认原有边距完整。

## 验证

新增tests/roguelite_card_content_flow.gd，全部16卡290×480，验证每段矩形在20px安全区内、顺序不重叠，加入真实card_flow并触发hover；0失败。flow_290_companion.png与flow_290_relay.png复现用户宽高附近，收益无分隔穿过、规则左边完整、底句不贴边。

正式Game全16卡实际像素高度检查formal_game.log 0失败；484项排版回归0失败。roguelite_sea_ui_integration.gd现明确加载scenes/ui/game.tscn，两分辨率三/四卡真实截图actual_cards_*及状态验证24项通过。图鉴原生capture日志gallery_flow.log显示空问题列表，gallery_flow.png可见独立VBox路径内容完整。证据在.local/art_pass_20261105/card，截图不提交。

## 修改与常见错误

改字号或新增长规则后，先跑上述16卡与正式Game测试，再目视最窄卡。必须把标签最小高度也纳入测量，单纯行数乘字高会遗漏Godot内部最小尺寸。不要恢复带固定分隔的背景后继续沿用内容流坐标；若需要分隔，应新增真实容器边框并参与布局。图鉴与正式奖励是两个路径，两者必须分别验证。未覆盖比当前正式最窄窗口更小的任意自定义尺寸。
