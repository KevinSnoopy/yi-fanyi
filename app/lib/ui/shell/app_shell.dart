import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../services/app_store.dart';
import '../../services/service_scope.dart';
import '../components/common.dart';
import '../overlays/floating_windows.dart' show Toast;
import '../pages/flow_demos.dart';
import '../pages/flow_page.dart';
import '../pages/mobile_pages.dart';
import '../pages/onboarding_page.dart';
import '../pages/platform_skins.dart';
import '../pages/prefs_pages.dart';
import '../pages/settings_pages.dart';

/// AppShell —— 主窗口骨架（原型 index.html menubar + tabs + 主舞台）：
/// macOS 菜单栏（26px）+ 15 Tab 导航条 + 页面分发 + 亮暗主题切换。
///
/// 全舞台外包 [ServiceScope]，页面可按需取热键/触发/通知服务（T-022/T-024）。
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.tab,
    required this.onTab,
    required this.dark,
    required this.onToggleTheme,
    required this.services,
  });

  final AppStore store;
  final int tab; // 0..14 → A..O
  final void Function(int) onTab;
  final bool dark;

  /// 运行期服务（热键 / 触发 / toast）。
  final LfServices services;
  final VoidCallback onToggleTheme;

  static const List<(String, String)> tabs = [
    ('A', '语音输入'),
    ('B', '悬浮窗'),
    ('C', '划词翻译'),
    ('D', '静默替换'),
    ('E', 'OCR 翻译'),
    ('F', '隐私锁'),
    ('G', 'iOS 键盘'),
    ('H', '首页'),
    ('I', '模型配置'),
    ('J', '快捷键'),
    ('K', '偏好·术语'),
    ('L', '首次引导'),
    ('M', 'iOS App'),
    ('N', 'Windows 端'),
    ('O', 'Android 端'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return ServiceScope(
      services: services,
      child: Stack(
        children: [
          Column(
            children: [
              _MenuBar(dark: dark, onToggleTheme: onToggleTheme, onTab: onTab),
              _TabBar(active: tab, onTab: onTab),
              Divider(height: 1, color: s.divider),
              Expanded(
                child: AnimatedSwitcher(
                  duration: LfDimens.tBase,
                  child: KeyedSubtree(
                    key: ValueKey(tab),
                    child: _page(tab),
                  ),
                ),
              ),
              _StatusBar(store: store, services: services),
            ],
          ),
          // in-app toast 宿主（原生通知的降级呈现，T-022）
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: ListenableBuilder(
              listenable: services.toasts,
              builder: (context, _) {
                final msg = services.toasts.message;
                if (msg == null) return const SizedBox.shrink();
                return Center(
                  child: Toast(message: msg, key: ValueKey(services.toasts.seq)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _page(int t) {
    final p = switch (t) {
      0 => FlowPage(store: store),
      1 => FlowBPage(store: store),
      2 => FlowCPage(store: store),
      3 => FlowDPage(store: store),
      4 => FlowEPage(store: store),
      5 => PrivacyDemoPage(store: store),
      6 => IosKbDemoPage(store: store),
      7 => _SettingsLayout(
          store: store,
          active: 'H',
          onTab: onTab,
          child: HomePage(store: store, onGoOnboarding: () => onTab(11)),
        ),
      8 => _SettingsLayout(
          store: store,
          active: 'I',
          onTab: onTab,
          child: ProvidersPage(store: store),
        ),
      9 => _SettingsLayout(
          store: store,
          active: 'J',
          onTab: onTab,
          child: HotkeysPage(store: store),
        ),
      10 => _SettingsLayout(
          store: store,
          active: 'K',
          onTab: onTab,
          child: PrefsPage(store: store),
        ),
      11 => OnboardingPage(store: store),
      12 => IosAppDemoPage(store: store),
      13 => WindowsDemoPage(store: store),
      _ => AndroidDemoPage(store: store),
    };
    return p;
  }
}

/// macOS 菜单栏（原型 .menubar 26px）。
class _MenuBar extends StatelessWidget {
  const _MenuBar({required this.dark, required this.onToggleTheme, required this.onTab});

  final bool dark;
  final VoidCallback onToggleTheme;
  final void Function(int) onTab;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      height: LfDimens.menubarH,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: s.menubarBg,
        border: Border(bottom: BorderSide(color: s.menubarBorder)),
      ),
      child: Row(
        children: [
          Text('', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.menubarText)),
          const SizedBox(width: 2),
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(3.5)),
            child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 5),
          Text('译语', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.menubarText)),
          const SizedBox(width: 14),
          for (final m in ['文件', '编辑', '视图', '窗口', '帮助'])
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(m, style: TextStyle(fontSize: 11.5, color: s.menubarText.withValues(alpha: 0.75))),
            ),
          const Spacer(),
          InkWell(
            onTap: onToggleTheme,
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                children: [
                  LfIcons.icon(dark ? 'smile' : 'settings', size: 11, color: s.menubarText.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(dark ? '深色' : '浅色', style: TextStyle(fontSize: 11, color: s.menubarText.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 15 Tab 导航条（原型 menubar 内 tab 按钮组 → 独立一行更适配窗口）。
class _TabBar extends StatelessWidget {
  const _TabBar({required this.active, required this.onTab});

  final int active;
  final void Function(int) onTab;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: s.bgSource,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, t) in AppShell.tabs.indexed) ...[
              const SizedBox(width: 2),
              _TabBtn(
                letter: t.$1,
                label: t.$2,
                active: i == active,
                onTap: () => onTab(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.letter, required this.label, required this.active, required this.onTap});

  final String letter;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? s.bgWindow : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? s.divider : Colors.transparent),
          boxShadow: active ? s.shadowXs : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter,
              style: TextStyle(
                fontSize: LfDimens.fs2xs,
                fontWeight: FontWeight.w800,
                color: active ? s.brand : s.text3,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: LfDimens.fsXs,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? s.text : s.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置类页整页布局（原型 buildSideNav：左侧导航 + 内容，H/I/J/K）。
class _SettingsLayout extends StatelessWidget {
  const _SettingsLayout({required this.store, required this.active, required this.onTab, required this.child});

  final AppStore store;
  final String active;
  final void Function(int) onTab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    Widget link(String key, int tabIdx, String iconName, String label) {
      final bool on = key == active;
      return InkWell(
        onTap: on ? null : () => onTab(tabIdx),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: on ? s.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              LfIcons.icon(iconName, size: 13, color: on ? s.brand : s.text2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: LfDimens.fsSm,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: on ? s.text : s.text2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: LfDimens.sideNavW,
          height: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: s.bgSource,
            border: Border(right: BorderSide(color: s.divider)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(5)),
                        child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 7),
                      Text('译语', style: TextStyle(fontSize: LfDimens.fsBase, fontWeight: FontWeight.w700, color: s.text)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                link('H', 7, 'home', '首页 · 历史与用量'),
                link('I', 8, 'chip', '模型配置'),
                link('J', 9, 'cmd', '快捷键'),
                link('K', 10, 'sparkles', '偏好 / 术语 / Skills'),
                _sep(s),
                link('F', 5, 'shield', '隐私安全'),
                link('L', 11, 'compass', '首次引导'),
                _sep(s),
                link('A', 0, 'mic', '回到语音输入'),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _sep(LfScheme s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, color: s.divider),
      );
}

/// 底部状态条 —— 引擎 / Provider / 隐私态一眼可读（原型 showHint 提示带的常驻化）。
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.store, required this.services});

  final AppStore store;
  final LfServices services;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final profile = store.defaultProfile;
    final report = services.hotkeys.lastReport;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: s.bgSource,
        border: Border(top: BorderSide(color: s.divider)),
      ),
      child: Row(
        children: [
          const StatusDot(ok: true, size: 6),
          const SizedBox(width: 6),
          Text(
            profile == null ? '本地兜底 · MockProvider（未配置模型绝不白屏）' : '${profile.platform} · ${profile.model}',
            style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
          ),
          const SizedBox(width: 10),
          // T-024：热键注册实况
          Text(
            services.hotkeys.paused ? '热键已禁用' : (report?.summary ?? '热键未注册'),
            style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
          ),
          if (services.hotkeys.conflictCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '⚠ ${services.hotkeys.conflictCount} 处冲突',
              style: TextStyle(fontSize: LfDimens.fs2xs, color: s.warning),
            ),
          ],
          const Spacer(),
          Text('零遥测', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
          const SizedBox(width: 12),
          Text('全部本地化', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
        ],
      ),
    );
  }
}
