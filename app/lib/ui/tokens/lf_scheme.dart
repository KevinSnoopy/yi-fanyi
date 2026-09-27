import 'package:flutter/material.dart';

/// 译语色彩 Token —— PRD v3.2 §5.2 / 原型 v7-spa styles.css :root 的 1:1 平移。
///
/// 浅/深两套 scheme 通过 [LfScheme.light] / [LfScheme.dark] 提供，
/// 由 [LfScheme.of] 从 Theme 上下文取用。
/// Token 全表与差异点见 `app/lib/ui/tokens/README.md`（T-013）。
@immutable
class LfScheme extends ThemeExtension<LfScheme> {
  const LfScheme({
    required this.brand,
    required this.brand2,
    required this.brandSoft,
    required this.brandSoft2,
    required this.accent,
    required this.bgBar,
    required this.bgSource,
    required this.bgWindow,
    required this.bgHover,
    required this.text,
    required this.text2,
    required this.text3,
    required this.divider,
    required this.dividerStrong,
    required this.error,
    required this.success,
    required this.warning,
    required this.brandGrad,
    required this.shadowXs,
    required this.shadowMd,
    required this.shadowPopover,
    required this.shadowWindow,
    required this.shadowBar,
    required this.shadowBrand,
    required this.menubarBg,
    required this.menubarText,
    required this.menubarBorder,
    required this.macClose,
    required this.macMin,
    required this.macMax,
  });

  /// 浅色 token（PRD §5.2 / 原型 :root）
  factory LfScheme.light() => const LfScheme(
        brand: Color(0xFF4F7CFF),
        brand2: Color(0xFF7B5CFF),
        brandSoft: Color(0x144F7CFF), // 8% 主色淡底
        brandSoft2: Color(0x224F7CFF), // 13% hover
        accent: Color(0xFFFF7A45),
        bgBar: Color(0xEBFFFFFF),
        bgSource: Color(0xFFF7F8FA),
        bgWindow: Color(0xFFFFFFFF),
        bgHover: Color(0xFFF0F1F5),
        text: Color(0xFF1D2129),
        text2: Color(0xFF86909C),
        text3: Color(0xFFC9CDD4),
        divider: Color(0xFFF0F1F5),
        dividerStrong: Color(0xFFE5E7EB),
        error: Color(0xFFF53F3F),
        success: Color(0xFF2BA471),
        warning: Color(0xFFFF7D00),
        brandGrad: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F7CFF), Color(0xFF7B5CFF)],
        ),
        shadowXs: [
          BoxShadow(color: Color(0x0F101828), offset: Offset(0, 1), blurRadius: 2),
          BoxShadow(color: Color(0x14101828), offset: Offset(0, 1), blurRadius: 3),
        ],
        shadowMd: [BoxShadow(color: Color(0x24101828), offset: Offset(0, 4), blurRadius: 14)],
        shadowPopover: [
          BoxShadow(color: Color(0x2E101828), offset: Offset(0, 8), blurRadius: 24),
          BoxShadow(color: Color(0x14101828), offset: Offset(0, 2), blurRadius: 6),
        ],
        shadowWindow: [
          BoxShadow(color: Color(0x21101828), offset: Offset(0, 24), blurRadius: 60),
          BoxShadow(color: Color(0x0D101828), offset: Offset(0, 0), blurRadius: 0, spreadRadius: 1),
        ],
        shadowBar: [BoxShadow(color: Color(0x29101828), offset: Offset(0, 4), blurRadius: 14)],
        shadowBrand: [BoxShadow(color: Color(0x594F7CFF), offset: Offset(0, 4), blurRadius: 16)],
        menubarBg: Color(0xE0F8F8FA),
        menubarText: Color(0xFF1D1D1F),
        menubarBorder: Color(0x14000000),
        macClose: Color(0xFFFF5F57),
        macMin: Color(0xFFFEBC2E),
        macMax: Color(0xFF28C840),
      );

  /// 深色 token（原型 @media (prefers-color-scheme: dark)）
  factory LfScheme.dark() => const LfScheme(
        brand: Color(0xFF5B8CFF),
        brand2: Color(0xFF8E74FF),
        brandSoft: Color(0x1F5B8CFF),
        brandSoft2: Color(0x335B8CFF),
        accent: Color(0xFFFF8A5C),
        bgBar: Color(0xEB1E1F24),
        bgSource: Color(0xFF131519),
        bgWindow: Color(0xFF1E1F24),
        bgHover: Color(0xFF26282E),
        text: Color(0xFFE8EAED),
        text2: Color(0xFF9AA0A6),
        text3: Color(0xFF5F6368),
        divider: Color(0xFF2E3038),
        dividerStrong: Color(0xFF3A3D45),
        error: Color(0xFFF76965),
        success: Color(0xFF3CCB91),
        warning: Color(0xFFFFA940),
        brandGrad: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B8CFF), Color(0xFF8E74FF)],
        ),
        shadowXs: [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2)],
        shadowMd: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 14)],
        shadowPopover: [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24),
          BoxShadow(color: Color(0x4D000000), offset: Offset(0, 2), blurRadius: 6),
        ],
        shadowWindow: [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 24), blurRadius: 60),
          BoxShadow(color: Color(0x0FFFFFFF), offset: Offset(0, 0), blurRadius: 0, spreadRadius: 1),
        ],
        shadowBar: [BoxShadow(color: Color(0x80000000), offset: Offset(0, 4), blurRadius: 14)],
        shadowBrand: [BoxShadow(color: Color(0x665B8CFF), offset: Offset(0, 4), blurRadius: 16)],
        menubarBg: Color(0xEB1C1C1E),
        menubarText: Color(0xFFF5F5F7),
        menubarBorder: Color(0x14FFFFFF),
        macClose: Color(0xFFFF5F57),
        macMin: Color(0xFFFEBC2E),
        macMax: Color(0xFF28C840),
      );

  final Color brand;
  final Color brand2;
  final Color brandSoft;
  final Color brandSoft2;
  final Color accent;
  final Color bgBar;
  final Color bgSource;
  final Color bgWindow;
  final Color bgHover;
  final Color text;
  final Color text2;
  final Color text3;
  final Color divider;
  final Color dividerStrong;
  final Color error;
  final Color success;
  final Color warning;
  final LinearGradient brandGrad;
  final List<BoxShadow> shadowXs;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowPopover;
  final List<BoxShadow> shadowWindow;
  final List<BoxShadow> shadowBar;
  final List<BoxShadow> shadowBrand;
  final Color menubarBg;
  final Color menubarText;
  final Color menubarBorder;
  final Color macClose;
  final Color macMin;
  final Color macMax;

  static LfScheme of(BuildContext context) =>
      Theme.of(context).extension<LfScheme>() ?? LfScheme.light();

  @override
  LfScheme copyWith({Color? brand}) =>
      throw UnimplementedError('token scheme 为不可变整体，重建实例即可');

  @override
  LfScheme lerp(LfScheme? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    LinearGradient g(LinearGradient a, LinearGradient b) => LinearGradient(
          begin: a.begin,
          end: a.end,
          colors: [
            Color.lerp(a.colors[0], b.colors[0], t)!,
            Color.lerp(a.colors[1], b.colors[1], t)!,
          ],
        );
    List<BoxShadow> s(List<BoxShadow> a, List<BoxShadow> b) => List.generate(a.length, (i) {
          final x = a[i];
          final y = b.length > i ? b[i] : b.last;
          return BoxShadow(
            color: Color.lerp(x.color, y.color, t)!,
            offset: Offset.lerp(x.offset, y.offset, t)!,
            blurRadius: x.blurRadius + (y.blurRadius - x.blurRadius) * t,
            spreadRadius: x.spreadRadius + (y.spreadRadius - x.spreadRadius) * t,
          );
        });
    return LfScheme(
      brand: c(brand, other.brand),
      brand2: c(brand2, other.brand2),
      brandSoft: c(brandSoft, other.brandSoft),
      brandSoft2: c(brandSoft2, other.brandSoft2),
      accent: c(accent, other.accent),
      bgBar: c(bgBar, other.bgBar),
      bgSource: c(bgSource, other.bgSource),
      bgWindow: c(bgWindow, other.bgWindow),
      bgHover: c(bgHover, other.bgHover),
      text: c(text, other.text),
      text2: c(text2, other.text2),
      text3: c(text3, other.text3),
      divider: c(divider, other.divider),
      dividerStrong: c(dividerStrong, other.dividerStrong),
      error: c(error, other.error),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      brandGrad: g(brandGrad, other.brandGrad),
      shadowXs: s(shadowXs, other.shadowXs),
      shadowMd: s(shadowMd, other.shadowMd),
      shadowPopover: s(shadowPopover, other.shadowPopover),
      shadowWindow: s(shadowWindow, other.shadowWindow),
      shadowBar: s(shadowBar, other.shadowBar),
      shadowBrand: s(shadowBrand, other.shadowBrand),
      menubarBg: c(menubarBg, other.menubarBg),
      menubarText: c(menubarText, other.menubarText),
      menubarBorder: c(menubarBorder, other.menubarBorder),
      macClose: c(macClose, other.macClose),
      macMin: c(macMin, other.macMin),
      macMax: c(macMax, other.macMax),
    );
  }
}
