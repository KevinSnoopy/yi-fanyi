import 'package:flutter/material.dart';

import 'lf_dimens.dart';

/// 译语组件规格 Token —— PRD v3.2 §5.3 ①–⑥ + pages-specs 字段级规格 + 现行实现的聚合落点（T-013）。
///
/// 口径：**以 `app/lib/ui/` 现行实现为准**（与 pages-specs 同一约定）；PRD/原型不一致处
/// 见 `app/lib/ui/tokens/README.md` 差异清单，待拍板前不擅改数值。
/// 颜色一律取 [LfScheme]（跟随浅/深主题），本文件只放**主题无关**的几何/常量，
/// 极少数平台皮肤固定色（⑤ iOS 键盘底色）除外。
abstract final class LfComponents {
  /// ① 录音/状态条（`overlays/recorder_pill.dart` · pages-specs/01 · ADR-008 三态）
  static const pill = _PillSpec();

  /// ② 迷你悬浮窗（`overlays/floating_windows.dart` MiniFloatingWindow/LiveFloatingWindow · pages-specs/02）
  static const floatWin = _FloatWinSpec();

  /// ③ 划词译文小窗（`overlays/floating_windows.dart` SelectionPopover · pages-specs/03）
  static const selection = _SelectionSpec();

  /// ④ 设置页主窗（`shell/app_shell.dart` + `pages/settings_pages.dart` · pages-specs/06-09）
  static const settings = _SettingsSpec();

  /// ⑤ 移动端键盘（`pages/mobile_pages.dart` + `components/phone_frames.dart` · PRD §5.3 ⑤）
  static const kb = _KbSpec();

  /// ⑥ 首次引导三步（`pages/onboarding_page.dart` · PRD §5.3 ⑥）
  static const onboarding = _OnboardingSpec();
}

/// ① 录音/状态条：pill 160×36 基准 + 三态体 + 「译」开关。
class _PillSpec {
  const _PillSpec();

  // 尺寸（PRD §5.1 Typeless pill 160×36；预览态自适应加宽上限 400）
  final double minW = LfDimens.pillMinW; // 160
  final double maxW = LfDimens.pillMaxW; // 400
  final double h = LfDimens.barH; // 36

  // 外观（bgWindow 97% + 活跃态品牌描边）
  final double bgAlpha = 0.97;
  final double borderActiveAlpha = 0.55; // 录音/成稿中描边透明度
  final double borderWidth = 1.2;

  // 状态点（录音红 / 完成绿，带光晕）
  final double dotSize = 8;
  final double dotGlowAlpha = 0.3;
  final double dotGlowBlur = 6;
  final double dotGlowSpread = 2;

  // 波形（10 根正弦相位柱）
  final int waveCount = 10;
  final double waveWidth = 3;
  final double waveMinH = 3;
  final double waveMaxH = 14;

  // 「译」开关（pill 右侧常驻，默认关）
  final double switchH = 22;
  final double switchThumb = 16;
  final double switchPad = 2;
  final double borderOnAlpha = 0.5;

  // 预览态（成稿文本 ≤2 行 + 1.2s 后悔窗口）
  final double previewMaxH = 44;
  final int previewMaxLines = 2;

  // 麦克风触发圆钮（flow_page 右下 52×52）
  final double micFab = 52;
}

/// ② 迷你悬浮窗：380 × 自适应（min 120 / max 480 滚动）。
class _FloatWinSpec {
  const _FloatWinSpec();

  final double w = LfDimens.popoverW; // 380（PRD §5.1）
  final double minH = 120;
  final double maxH = 480;
  final double r = LfDimens.rPopover; // 14

  // 头部（方向选择 + 🔊/⚙/✕）
  final EdgeInsets headerPad = const EdgeInsets.fromLTRB(14, 10, 14, 8);

  // 原文区（浅灰底可折叠，r10）与译文流式区（顶部 2px 进度条）
  final double sourceR = LfDimens.rInput; // 10
  final double sourcePad = 10;
  final double progressH = 2;
  final EdgeInsets blockMargin = const EdgeInsets.all(10);

  // 底部输入行（🎤 + 输入框 + ➤发送）
  final EdgeInsets bottomPad = const EdgeInsets.fromLTRB(10, 0, 12, 10);

  // 文字：原文 12 次要色 / 译文 15（PRD §5.2「译文区 15px」）
  final double sourceFs = LfDimens.fsSm; // 12
  final double resultFs = LfDimens.fsMd; // 15
}

/// ③ 划词译文小窗：320 × 自适应；原文 12px 次要色在上、译文 15px 在下。
class _SelectionSpec {
  const _SelectionSpec();

  final double w = LfDimens.selectionWinW; // 320（PRD §5.1）
  final double r = LfDimens.rPopover; // 14
  final EdgeInsets pad = const EdgeInsets.all(12);

  // 底部图标排（复制/替换/朗读/收藏/进主窗）
  final double actionBtn = 24;
  final double actionR = 7;
  final double actionGap = 6;

  final double sourceFs = LfDimens.fsSm; // 12 次要色
  final double resultFs = LfDimens.fsMd; // 15
}

/// ④ 设置页主窗：960×640（min 720×480）+ 左侧导航 190。
class _SettingsSpec {
  const _SettingsSpec();

  final double windowW = LfDimens.windowW; // 960
  final double windowH = LfDimens.windowH; // 640
  final double windowMinW = 720; // PRD §5.1 最小 720×480
  final double windowMinH = 480;
  final double navW = LfDimens.sideNavW; // 190
  final double cardR = LfDimens.rCard; // 10
}

/// ⑤ 移动端键盘：与系统键盘同高；顶部 36px 工具条；候选区为「译文流」。
///
/// ⚠️ 键盘底色为 iOS 皮肤固定色（不随主题，模拟系统键盘观感）。
class _KbSpec {
  const _KbSpec();

  final double toolbarH = 36; // PRD §5.3 ⑤
  final Color keyboardBg = const Color(0xFFD1D4DA); // iOS 键盘底
  final Color toolbarBg = const Color(0xFFE4E6EB); // 工具条底
}

/// ⑥ 首次引导三步：选平台 → 填 Key（可零 Key 试用本地模型）→ 设热键。
class _OnboardingSpec {
  const _OnboardingSpec();

  final int stepCount = 3; // PRD §5.3 ⑥，无强制登录

  final double panelW = 560; // 引导面板宽（onboarding_page）
  final double heroIcon = 56;
  final double heroGlyph = 26;
  final double permBadge = 28; // 权限行徽标
}
