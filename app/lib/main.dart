import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/tokens.dart';
import 'services/app_store.dart';
import 'services/native_bridge.dart';
import 'services/secure_store.dart';
import 'services/service_scope.dart';
import 'ui/shell/app_shell.dart';

/// 译语 LinguaFlow —— BYOK 语音成稿 · 五端一致
/// 入口：AppStore 装配 + 亮暗双主题 + AppShell（15 Tab 演示导航）。
///
/// T-021：Key 走 SecureStore（桌面 Keychain / Web 混淆降级）；配置与历史落
/// SharedPreferences。T-022/T-024：装配热键 + 触发服务（Web 自动降级）。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = SharedPreferencesAsync();
  final secure = DelegatingSecureStore(
    primary: kIsWeb ? null : ChannelSecureStore(),
    fallback: PrefsSecureStore(prefs),
  );

  final store = AppStore(secure: secure, prefs: prefs);
  await store.load();

  final services = LfServices.bootstrap(
    store: store,
    bridge: kIsWeb
        ? NoopNativeBridge()
        : FallbackNativeBridge(ChannelNativeBridge()),
  );
  await services.init();

  runApp(LinguaFlowApp(store: store, services: services));
}

class LinguaFlowApp extends StatefulWidget {
  const LinguaFlowApp({super.key, required this.store, required this.services});

  final AppStore store;
  final LfServices services;

  @override
  State<LinguaFlowApp> createState() => _LinguaFlowAppState();
}

class _LinguaFlowAppState extends State<LinguaFlowApp> {
  bool _dark = false;
  late int _tab = _initialTab(); // A..O

  /// URL hash 直达（冒烟/分享用）：#tab=I → 打开 I 模型配置。
  static int _initialTab() {
    final m = RegExp(r'tab=([A-O])').firstMatch(Uri.base.fragment);
    if (m == null) return 0;
    return 'ABCDEFGHIJKLMNO'.indexOf(m.group(1)!).clamp(0, 14);
  }

  @override
  void dispose() {
    widget.services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _dark ? LfScheme.dark() : LfScheme.light();
    final base = _dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    return MaterialApp(
      title: '译语 LinguaFlow',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: scheme.bgSource,
        extensions: [scheme],
        colorScheme: base.colorScheme.copyWith(primary: scheme.brand, secondary: scheme.brand2, surface: scheme.bgWindow),
        splashFactory: InkSparkle.splashFactory,
        textTheme: base.textTheme.apply(
          bodyColor: scheme.text,
          displayColor: scheme.text,
          fontFamily: 'LfSans',
          fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei UI', 'Noto Sans SC', 'Segoe UI'],
        ),
        dividerTheme: DividerThemeData(color: scheme.divider, thickness: 1, space: 1),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(color: scheme.bgBar, borderRadius: BorderRadius.circular(8), border: Border.all(color: scheme.divider)),
          textStyle: TextStyle(fontSize: LfDimens.fsXs, color: scheme.text),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: scheme.bgWindow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LfDimens.rPopover), side: BorderSide(color: scheme.divider)),
        ),
      ),
      home: Scaffold(
        backgroundColor: scheme.bgSource,
        body: AppShell(
          store: widget.store,
          services: widget.services,
          tab: _tab,
          onTab: (t) => setState(() => _tab = t),
          dark: _dark,
          onToggleTheme: () => setState(() => _dark = !_dark),
        ),
      ),
    );
  }
}
