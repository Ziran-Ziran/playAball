# Noto Sans SC

2026-11-10从Google Fonts官方源下载未修改的`NotoSansSC[wght].ttf`，项目保存为`NotoSansSC.ttf`。来源：https://github.com/google/fonts/tree/main/ofl/notosanssc 。许可为同目录SIL OFL 1.1原文。

原文件17,772,300字节，SHA256为`A3041811A78C361B1DE50F953C805E0244951C21C5BD412F7232EF0D899AF0DA`。

用于安卓系统字体缺少全角标点、符号时的显式fallback，保持桌面首选字体及现有ZCOOL标题。字体随包分发，避免依赖某台机器安装微软字体；实际手机字形仍以发布包原生截图核验。

原可变字体的wght默认100，安卓首次复验偏细。因此`resources/ui/body_fallback.tres`以FontVariation选择wght400，不修改原TTF，维持常规正文笔画。
