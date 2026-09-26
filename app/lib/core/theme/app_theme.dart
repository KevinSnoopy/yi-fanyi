import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// 应用主题构建 —— 对齐原型视觉基调：
/// 轻盈、无侵入、半透明质感；PingFang SC / HarmonyOS Sans + Inter 字体栈；
/// 控件全部走 LfScheme token（禁用 Material 默认紫）。
abstract final class AppTheme {
  static const String fontFamilyFallback =
      'PingFang SC, HarmonyOS Sans, Inter, -apple-system, Segoe UI, Roboto';

  static ThemeData light() => _build(Brightness.light, LfScheme.light());

  static ThemeData dark() => _build(Brightness.dark, LfScheme.dark());

  static ThemeData _build(Brightness brightness, LfScheme s) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: s.brand,
      brightness: brightness,
      primary: s.brand,
      secondary: s.brand2,
      error: s.error,
      surface: s.bgWindow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: s.bgSource,
      extensions: [s],
      fontFamilyFallback: const ['PingFang SC', 'HarmonyOS Sans', 'Inter'],
      textTheme: TextTheme(
        displaySmall: _txt(s, LfDimens.fsXl, FontWeight.w700),
        headlineMedium: _txt(s, LfDimens.fsLg, FontWeight.w700),
        titleLarge: _txt(s, LfDimens.fsMd, FontWeight.w600),
        titleSmall: _txt(s, LfDimens.fsBase, FontWeight.w600),
        bodyLarge: _txt(s, LfDimens.fsMd, FontWeight.w400),
        bodyMedium: _txt(s, LfDimens.fsBase, FontWeight.w400),
        bodySmall: _txt(s, LfDimens.fsSm, FontWeight.w400),
        labelLarge: _txt(s, LfDimens.fsBase, FontWeight.w500),
        labelSmall: _txt(s, LfDimens.fsXs, FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: s.divider, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? s.brand : s.text3.withValues(alpha: 0.4),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.bgWindow,
        hintStyle: _txt(s, LfDimens.fsBase, FontWeight.w400).copyWith(color: s.text3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LfDimens.rInput),
          borderSide: BorderSide(color: s.dividerStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LfDimens.rInput),
          borderSide: BorderSide(color: s.dividerStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LfDimens.rInput),
          borderSide: BorderSide(color: s.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LfDimens.rInput),
          borderSide: BorderSide(color: s.error),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: _txt(s, LfDimens.fsBase, FontWeight.w400),
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.compact,
    );
  }

  static TextStyle _txt(LfScheme s, double size, FontWeight w) => TextStyle(
        fontSize: size,
        fontWeight: w,
        height: 1.5,
        color: s.text,
        fontFamilyFallback: const ['PingFang SC', 'HarmonyOS Sans', 'Inter'],
      );
}

/// 系统 UI overlay（状态栏/导航栏跟随主题）。
SystemUiOverlayStyle systemOverlay(Brightness b) => SystemUiOverlayStyle(
      statusBarBrightness: b,
      statusBarIconBrightness: b == Brightness.dark ? Brightness.light : Brightness.dark,
    );
