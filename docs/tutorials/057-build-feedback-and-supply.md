# 057 · 构筑兑现提示与五选项补给布局

本批目标是让玩家知道运营怎样兑现：伙伴阵型串到二/三代、连锁爆破扩大、撞杀后余势波及，都有真实事件提示；底部保留自己已取得的构筑状态。它不是新的伤害系统，也不把尝试伤害包装成伤害贡献。

## 文件与节点

- `scripts/roguelite/presentation/build_feedback.gd`、`scenes/roguelite/presentation/build_feedback.tscn`：独立只读表现。RunHUD创建组件后，延迟找到父arena的director，消费Combat的成功信号。
- `scripts/roguelite/run_hud.gd`：增加组件实例，更新接力、爆破、保龄球收益短句；卡片点击信号和入场禁用期保持原逻辑。
- `scripts/roguelite/rest_panel.gd/.tscn`：Body内增加Scroll，Actions仍保存真实Button；付费整备先列、免费离场后列。全部原id与revision保留交给RunDirector校验。
- `assets/ui/build_feedback/strategy_badges.png`：内置生成的2×2透明图集，接力三色能量节点、病毒爆破、病毒余势、饭碗整备；[来源](../../assets/ui/build_feedback/SOURCE.md)。没有人物替身或普通鲸鱼。
- `tests/roguelite_build_feedback.gd`：成功信号、边界与三种窗口尺寸专项；原生模式额外保存PNG。

## 输入 → 逻辑 → 输出

Combat的relay表示伙伴已成功接到传能；generation小于2不弹“深度接力”。explosion_triggered提供真实爆破半径，bowling_surged提供实际波及人数。组件只修改提示Label、图集区域和触发计数，不调用hurt、发奖励、改金币或控制刚体。

```gdscript
combat.relay.connect(_on_relay)
combat.explosion_triggered.connect(_on_explosion)
combat.bowling_surged.connect(_on_bowling)
```

多个事件到达时复用同一条提示，新提示覆盖旧提示，不建立增长的动画/节点队列。底部读director.build.levels与companion_count，显示伙伴数、强化接力、爆破和保龄球是否已拥有。“强化接力未取得”不代表基础传能不存在。

受击事件里的尝试伤害可能超过敌人实际剩余HP，因此这里**不累计伤害贡献**。触发次数只是内部可测计数，不能当成击杀数。已有结算记录仍由原玩法提供。

## 暂停、重开和图集

组件以PROCESS_MODE_ALWAYS检查模态，但notice_left只在树没有暂停时递减。瞄准决策暂停保留构筑和提示，成长/商店/结算/暂停菜单隐藏组件。reset事件清掉次数与当前提示，不改变构筑重置逻辑。减少动态开启时保留静态成功文字，关闭末尾渐隐。

图集原画为1254×1254，并非请求尺寸；导入限制512、开启mipmap。不能写死627像素格：实际运行用`_art.get_size()/2.0`作为每格尺寸，再按行列生成AtlasTexture，适用于重新导入和导出。不要对PNG做脚本重绘。

## 五选项补给

免费回血或免费成长会离场，付费整备不会消耗免费补给。组件先陈列paid_heal、paid_upgrade，再按原序列出免费选择与跳过。按钮辅助说明明确“选卡后返回，免费补给保留”和“免费选卡后进入下一阶段”。禁用项目保留价钱与已购/条件不满足说明，不仅靠灰色表达。

弹窗高度最多640，并保留上下24像素边距；按钮放在独立纵向滚动区。低于650像素高或面板窄于760时，隐藏左侧装饰人物，保留全部操作文字。窄窗口下第五项需要滚动，专项确认滚到底能完整看见。按钮还是原Button，选项id/revision未重命名，实际库存/生命/经济校验仍在玩法里。

## 检查器调参和扩展

选中build_feedback场景根节点，可以将notice_duration在0.3–3秒间调整，默认1.45。提示字体与位置在脚本_ready/_process集中设置；布局位于战场外底部，成功提示位于右上。增加新策略前，先让玩法发布“已成功”事件，再让表现订阅；不要从角色速度或碰撞声猜测成功。

补给可修改按钮最小高度、文字字号、Scroll和角色显示阈值，但需重测1024×576。新增选项应先在RunDirector实现合法请求和拒绝路径，表现只增显示，不复制价格规则。

## 验证及证据

设备LAPTOP-8GS4N5SG；Godot4.7.1 stable，Compatibility。实际执行：

```powershell
# $engine设置为本机已经核验的引擎路径。
Start-Process -FilePath $engine -ArgumentList '--headless --path . --script tests/roguelite_build_feedback.gd' -WindowStyle Hidden -Wait
Start-Process -FilePath $engine -ArgumentList '--path . --script tests/roguelite_build_feedback.gd' -WindowStyle Hidden -Wait
```

首轮专项headless和原生GUI各32项0失败；旧roguelite_sea_ui_integration为24项0失败、roguelite_shop_events为12项0失败。部分headless进程有既有2 ObjectDB退出警告，未称零警告。

原生专项保存`.local/p2-ui/rest-1280x720.png`、`rest-1024x576.png`、`rest-1600x720.png`与`feedback.png`；本Agent实际打开查看。截图是受控GUI夹具，输入报价由测试设置，不能当成自然通关/真人策略评分。测试还验证1000次连续提示节点数不增长、暂停期间寿命不变、模态隐藏、重开清零和滚动可达；未伪造有效伤害统计。

开发主观复评：构筑可见性5.5→7.7、策略成功辨识6.0→8.0、五选项可理解性6.0→7.8；与之前评分方法不同，不计算成“自然游玩总分”。窄屏仍需要滚动，新提示不替代完整局内教导；安卓真机和听感未由此专项验证。

常见错误：图标裁错时先看实际导入尺寸；提示计时在暂停仍走时检查是否漏了get_tree().paused；画面被结算遮住时不要提升反馈z_index，模态应该独占；补给免费选完离场是实际规则，不应改文案假称还能返回。


## 第二轮：精准连击实际回能

RunDirector新增`precision_rewarded(point, refunded_seconds)`，只在实际缩短了剩余冷却时发布。BuildFeedback消费该成功事件，显示“精准连击 · 回能0.5秒”或剩余冷却不足时的实际退款数（例如0.25秒）；不足0.01秒明确显示“回能不足0.01秒”，不把舍入零写成成功0秒。零、负值与非有限值不出提示。复用接力徽记和同一条提示控件，不增伤害统计，不建立事件队列。

trigger_counts新增precision触发计数，reset一并清零；暂停冻结和模态隐藏规则与首轮相同。底栏尝试附加“直撞3敌可回能”短教学，先量真实字体宽度，容不下时优先保留实际构筑，并启用文字裁切防止越界。

更新后的专项为40项，包含真实director信号、部分退款、零退款拒绝、暂停和重开、三个窗口字宽边界。原生测试额外保存`.local/p2-ui/feedback-precision.png`；这是受控信号夹具，不冒充自然整局触发证据。新增素材已逐张实看并纳入资产台账：release_r5的三张真实伙伴卡，以及安卓透明DS前景/纯深蓝SVG背景；原三张DS分身卡保留历史，生产索引由根Agent替换。

音乐和既有Live2D公开使用许可均经用户明确确认；这是用户提供的事实记录，不代表Agent审查了合同，也不扩大资源使用范围。本次未修改Live2D。
