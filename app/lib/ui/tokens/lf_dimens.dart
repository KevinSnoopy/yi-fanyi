import 'package:flutter/material.dart';

/// 译语几何 / 动效 Token —— 原型 styles.css 尺寸 token 1:1，与主题无关。
///
/// 字阶 / 圆角 / 尺寸 / 动画 / 核心链路节奏；组件级聚合规格见 `lf_components.dart`。
abstract final class LfDimens {
  // 字阶（原型 --fs-*：11 辅助 / 12 说明 / 13 正文 / 15 强调 / 17 标题 / 20 大标题）
  static const double fs2xs = 10;
  static const double fsXs = 11;
  static const double fsSm = 12;
  static const double fsBase = 13;
  static const double fsMd = 15;
  static const double fsLg = 17;
  static const double fsXl = 20;

  // 圆角（--r-*：按钮 8 / 输入 10 / 卡片 10 / 悬浮窗 14 / pill 999）
  static const double rBtn = 8;
  static const double rInput = 10;
  static const double rCard = 10;
  static const double rPopover = 14;
  static const double rPill = 999;

  // 尺寸（PRD §5.1）
  static const double barH = 36; // v7 pill 高度（PRD §5.1 Typeless pill 160×36 基准）
  static const double pillMinW = 160;
  static const double pillMaxW = 400; // 预览态自适应加宽上限
  static const double popoverW = 380; // 迷你悬浮窗 380 × 自适应
  static const double selectionWinW = 320;
  static const double windowW = 960; // 主窗口 960×640
  static const double windowH = 640;
  static const double sideNavW = 190;
  static const double menubarH = 26;

  // 动画（≤180ms：淡入 + 上移 8px）
  static const Duration tFast = Duration(milliseconds: 120);
  static const Duration tBase = Duration(milliseconds: 180);
  static const Duration tExit = Duration(milliseconds: 220);
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1);

  // 核心链路节奏（PRD §2.1）
  static const Duration previewWindow = Duration(milliseconds: 1200); // 1.2s 后悔窗口
  static const Duration doneFadeout = Duration(milliseconds: 1500);
}
