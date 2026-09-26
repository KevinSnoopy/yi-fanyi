
import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../components/common.dart';
import '../components/phone_frames.dart';
import '../overlays/floating_windows.dart';
import '../overlays/recorder_pill.dart' show LfSpinner;
import 'flow_demos.dart';
import 'flow_page.dart' show HostTitleBar;
import 'mobile_pages.dart' show WechatThread;

// ==================================================================
// N 页 · Windows 端 —— PRD §5（原型 Tab N 五态，Win11 Fluent Design）
// Win+H 按住说话 → Fluent pill 成稿 → 落入邮件正文；托盘快速面板
// ==================================================================
class WindowsDemoPage extends FlowDemoPage {
  const WindowsDemoPage({super.key, required super.store});

  @override
  int get stateCount => 5;

  @override
  String get hostTitle => 'Windows 11 · 译语';

  @override
  State<FlowDemoPage> createState() => _WindowsDemoPageState();
}

class _WindowsDemoPageState extends State<WindowsDemoPage> with FlowDemoStateMixin {
  static const draftZh = '那个报价我确认没问题，下周三之前可以签合同。';
  static const finalZh = '那个报价我确认没问题，下周三之前可以把合同签了。';

  @override
  List<String> get stateLabels => const ['录音中', '成稿中', '预览', '已落框', '托盘面板'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1800));
    schedule(() => setStateAt(2), const Duration(milliseconds: 3400));
    schedule(() => setStateAt(3), const Duration(milliseconds: 5400));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ---- Win 桌面 ----
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A5F), Color(0xFF0F2027), Color(0xFF2C5364)],
            ),
          ),
          child: Stack(
            children: [
              // 邮件窗口
              Positioned(left: 0, right: 0, top: 40, child: Center(child: _WinWindow(stateIdx: stateIdx, finalZh: finalZh))),
              // 任务栏
              const Positioned(left: 0, right: 0, bottom: 0, child: _WinTaskbar()),
              // Fluent pill（态 0-3）
              if (stateIdx <= 3)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 74,
                  child: Center(child: _WinPill(stateIdx: stateIdx, draftZh: draftZh)),
                ),
              // 态 3 · Win 通知 Toast（右下）
              if (stateIdx == 3)
                const Positioned(
                  right: 18,
                  bottom: 64,
                  child: _WinToast(text: finalZh),
                ),
              // 态 4 · 托盘快速面板
              if (stateIdx == 4)
                const Positioned(
                  right: 12,
                  bottom: 56,
                  child: _WinQuickPanel(),
                ),
            ],
          ),
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
      ],
    );
  }
}

/// Win11 邮件窗口（Mica 风 · 8px 圆角 · 右侧 − □ ×）。
class _WinWindow extends StatelessWidget {
  const _WinWindow({required this.stateIdx, required this.finalZh});

  final int stateIdx;
  final String finalZh;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final bool light = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: 520,
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: light ? Colors.white : const Color(0xFF202020),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.divider),
        boxShadow: s.shadowWindow,
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: light ? const Color(0xFFF3F3F3) : const Color(0xFF2B2B2B),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(3)),
                  child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('新邮件 · 致 Daniel', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
                ),
                const _WinCap(svg: Icons.horizontal_rule, close: false),
                const _WinCap(svg: Icons.crop_square, close: false),
                const _WinCap(svg: Icons.close, close: true),
              ],
            ),
          ),
          // 邮件正文
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _mailRow(context, '收件人', 'daniel@acme.com'),
                const SizedBox(height: 6),
                _mailRow(context, '主题', 'Re: 报价确认'),
                const SizedBox(height: 12),
                Container(height: 1, color: s.divider),
                const SizedBox(height: 12),
                Text(
                  stateIdx >= 3 ? finalZh : '',
                  style: TextStyle(fontSize: LfDimens.fsBase, height: 1.6, color: s.text),
                ),
                if (stateIdx < 3)
                  Text(
                    '点击开始输入 · 按住 Win+H 说话，成稿自动写入',
                    style: TextStyle(fontSize: LfDimens.fsBase, color: s.text3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mailRow(BuildContext context, String label, String value) {
    final s = LfScheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3)),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2))),
      ],
    );
  }
}

/// Win 标题栏控制钮（close hover 红）。
class _WinCap extends StatelessWidget {
  const _WinCap({required this.svg, required this.close});

  final IconData svg;
  final bool close;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 26,
      child: Icon(svg, size: 12, color: close ? const Color(0xFFC42B1C) : LfScheme.of(context).text2),
    );
  }
}

/// Win11 任务栏（居中图标 + 右侧托盘）。
class _WinTaskbar extends StatelessWidget {
  const _WinTaskbar();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final bool light = Theme.of(context).brightness == Brightness.light;
    final Color barBg = light ? const Color(0xE6F3F3F3) : const Color(0xE6202020);

    Widget tbIcon(Widget child, {bool active = false}) {
      return Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: light ? 0.9 : 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active ? Border(top: BorderSide(color: s.brand, width: 2.5)) : null,
        ),
        child: Center(child: child),
      );
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: barBg,
      child: Row(
        children: [
          const Spacer(),
          tbIcon(LfIcons.icon('windows', size: 18, color: light ? const Color(0xFF0078D4) : Colors.white)),
          tbIcon(Icon(Icons.search, size: 17, color: s.text2)),
          tbIcon(LfIcons.icon('folder', size: 17, color: const Color(0xFFF7B84B))),
          tbIcon(const Icon(Icons.public, size: 17, color: Color(0xFF0078D4))),
          tbIcon(
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(4)),
              child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
            ),
            active: true,
          ),
          const Spacer(),
          // 托盘
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: light ? 0.5 : 0.08), borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Text('中', style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2)),
                const SizedBox(width: 8),
                LfIcons.icon('mic', size: 12, color: s.text2),
                const SizedBox(width: 8),
                Icon(Icons.wifi, size: 13, color: s.text2),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('20:10', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2, height: 1.1)),
                    Text('2026/09/26', style: TextStyle(fontSize: 9, color: s.text3, height: 1.1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Win 语音成稿 pill（复用 pill 形制 · Fluent 方角皮肤）。
class _WinPill extends StatelessWidget {
  const _WinPill({required this.stateIdx, required this.draftZh});

  final int stateIdx;
  final String draftZh;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final bool light = Theme.of(context).brightness == Brightness.light;

    Widget inner;
    if (stateIdx == 0) {
      inner = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusDot(ok: true, size: 9),
          const SizedBox(width: 8),
          const _MiniWave(),
          const SizedBox(width: 8),
          Text('正在聆听', style: TextStyle(fontSize: LfDimens.fsBase, color: s.text)),
          Text(' 0:02', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
          const SizedBox(width: 10),
          const Kbd('Win+H'),
        ],
      );
    } else if (stateIdx == 1) {
      inner = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LfSpinner(size: 13),
          const SizedBox(width: 8),
          Text('成稿中…', style: TextStyle(fontSize: LfDimens.fsBase, color: s.text)),
          Text(' 已输出 8 字', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
          const SizedBox(width: 10),
          Text('Esc 取消', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
        ],
      );
    } else if (stateIdx == 2) {
      inner = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(draftZh, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: LfDimens.fsBase, color: s.text)),
          ),
          const _Cursor(),
          const SizedBox(width: 10),
          Text('✓ 1.2s', style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w600, color: s.success)),
          const SizedBox(width: 6),
          Text('✗ 重说', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
        ],
      );
    } else {
      inner = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusDot(ok: true, size: 9),
          const SizedBox(width: 8),
          Text('✓ 已写入 · 成稿', style: TextStyle(fontSize: LfDimens.fsBase, color: s.text)),
        ],
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 460),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: LfDimens.barH + 6,
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.96) : const Color(0xF0272727),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.dividerStrong),
        boxShadow: s.shadowBrand,
      ),
      child: inner,
    );
  }
}

/// 小波形（录音态 10 根正弦条）。
class _MiniWave extends StatefulWidget {
  const _MiniWave();

  @override
  State<_MiniWave> createState() => _MiniWaveState();
}

class _MiniWaveState extends State<_MiniWave> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 10; i++)
              Container(
                width: 2.5,
                height: 4 + 10 * (0.5 + 0.5 * _waving(i, _c.value)),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(color: s.brand, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        );
      },
    );
  }

  double _waving(int i, double t) {
    final v = (t * 2 + i * 0.45) % 1;
    return v < 0.5 ? v * 2 : (1 - v) * 2;
  }
}

/// 光标闪烁条。
class _Cursor extends StatefulWidget {
  const _Cursor();

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return FadeTransition(
      opacity: _c,
      child: Container(width: 2, height: 14, color: s.brand),
    );
  }
}

/// Win 通知 Toast（态 3 右下角）。
class _WinToast extends StatelessWidget {
  const _WinToast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.bgBar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(7)),
              child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('译语', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                  const SizedBox(height: 1),
                  Text('已写入成稿', style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
                  const SizedBox(height: 2),
                  Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 托盘上方 Acrylic 快速面板（态 4）。
class _WinQuickPanel extends StatelessWidget {
  const _WinQuickPanel();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    Widget row(String label, String val) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2)),
              Text(val, style: TextStyle(fontSize: LfDimens.fsXs, fontWeight: FontWeight.w600, color: s.text)),
            ],
          ),
        );

    Widget toggle(String label, bool on, {ValueChanged<bool>? onChange}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2)),
              LfSwitch(value: on, onChanged: onChange ?? (_) {}),
            ],
          ),
        );

    return RiseIn(
      child: Container(
        width: 264,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: s.bgBar.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowWindow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(6)),
                  child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('译语', style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: s.text)),
                      Text('本地优先 · 已连接', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                    ],
                  ),
                ),
                const StatusDot(ok: true),
              ],
            ),
            const SizedBox(height: 8),
            row('模型', 'Ollama · qwen2.5:7b'),
            row('语言方向', '中文 → English'),
            row('按住说话', 'Win+H'),
            Divider(height: 16, color: s.divider),
            toggle('开机自启', true),
            toggle('隐私锁', false),
            const SizedBox(height: 6),
            const LfButton(
              label: ' 打开主窗口',
              icon: 'window',
              full: true,
              padding: EdgeInsets.symmetric(vertical: 7),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// O 页 · Android 端 —— PRD §5（原型 Tab O 五态，Material 3 / Material You）
// Gboard 语音成稿 → 已落框（M3 Snackbar）→ App 主页（NavigationBar + FAB）
// ==================================================================
class AndroidDemoPage extends FlowDemoPage {
  const AndroidDemoPage({super.key, required super.store});

  @override
  int get stateCount => 5;

  @override
  String get hostTitle => 'Android · 译语';

  @override
  State<FlowDemoPage> createState() => _AndroidDemoPageState();
}

class _AndroidDemoPageState extends State<AndroidDemoPage> with FlowDemoStateMixin {
  static const original = '下周三能签吗？';
  static const draftZh = '下周三之前应该可以签合同。';
  static const finalZh = '下周三之前应该可以把合同签了。';

  @override
  List<String> get stateLabels => const ['键盘展开', '语音输入', '成稿候选', '已落框', 'App 主页'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1600));
    schedule(() => setStateAt(2), const Duration(milliseconds: 3400));
    schedule(() => setStateAt(3), const Duration(milliseconds: 5200));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(child: Container(color: s.bgSource, alignment: Alignment.center)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 46,
          bottom: 8,
          child: Center(
            child: stateIdx == 4 ? const _M3AppHome() : _androidFlow(),
          ),
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
      ],
    );
  }

  Widget _androidFlow() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PhoneFrame(
          android: true,
          child: Column(
            children: [
              const AndroidStatusBar(),
              const Expanded(
                child: WechatThread(
                  name: '给李总',
                  incoming: '确认一下，这周能把合同定下来吗？',
                ),
              ),
              _AndroidInputRow(text: stateIdx >= 3 ? finalZh : (stateIdx == 2 ? original : null)),
              Gboard(
                state: stateIdx >= 2 ? 2 : stateIdx,
                draftChip: stateIdx == 2 ? draftZh : null,
                micOn: stateIdx == 1,
              ),
            ],
          ),
        ),
        // 态 3 · M3 Snackbar
        if (stateIdx == 3)
          const Positioned(
            left: 16,
            right: 16,
            bottom: 120,
            child: Center(child: M3Snackbar(message: '已写入成稿 · 本地处理 · 0 ¥')),
          ),
      ],
    );
  }
}

/// Android 状态栏（左时间 · 右图标）。
class AndroidStatusBar extends StatelessWidget {
  const AndroidStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: Row(
        children: [
          Text('14:32', style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w600, color: s.text)),
          const Spacer(),
          Icon(Icons.signal_cellular_alt, size: 12, color: s.text2),
          const SizedBox(width: 4),
          Icon(Icons.wifi, size: 12, color: s.text2),
          const SizedBox(width: 4),
          Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              border: Border.all(color: s.text2, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(1),
            child: FractionallySizedBox(
              widthFactor: 0.7,
              child: DecoratedBox(decoration: BoxDecoration(color: s.text2, borderRadius: BorderRadius.circular(1))),
            ),
          ),
        ],
      ),
    );
  }
}

/// Android 输入行。
class _AndroidInputRow extends StatelessWidget {
  const _AndroidInputRow({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          LfIcons.icon('mic', size: 19, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.5),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                text ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          LfIcons.icon('smile', size: 19, color: Colors.black54),
        ],
      ),
    );
  }
}

/// Material You App 主页（态 4）。
class _M3AppHome extends StatelessWidget {
  const _M3AppHome();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    Widget m3Row(String iconName, String name, String meta, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              LfIcons.icon(iconName, size: 15, color: s.brand),
              const SizedBox(width: 10),
              Text(name, style: TextStyle(fontSize: LfDimens.fsSm, color: s.text)),
              const Spacer(),
              Text(meta, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ] else ...[
                const SizedBox(width: 4),
                Text('›', style: TextStyle(fontSize: LfDimens.fsMd, color: s.text3)),
              ],
            ],
          ),
        );

    return PhoneFrame(
      android: true,
      child: Stack(
        children: [
          Column(
            children: [
              const AndroidStatusBar(),
              // 顶部
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('译语', style: TextStyle(fontSize: LfDimens.fsLg, fontWeight: FontWeight.w700, color: s.text)),
                          Text('BYOK · 零采集 · 本地优先', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: s.brandSoft, shape: BoxShape.circle),
                      child: Text('K', style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: s.brand)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 最近成稿卡
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: s.brandSoft.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: s.brand.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(5)),
                                  child: Text('最近成稿', style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w700, color: s.brand)),
                                ),
                                const Spacer(),
                                Text('刚刚 · 微信', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('那个报价我确认没问题，下周三之前可以把合同签了。',
                                style: TextStyle(fontSize: LfDimens.fsSm, color: s.text, height: 1.5)),
                            const SizedBox(height: 6),
                            Text(
                              'Confirmed, no problem with the quote. We can sign the contract before next Wednesday.',
                              style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2, height: 1.5),
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                _M3ChipBtn(icon: Icons.copy, label: '复制'),
                                SizedBox(width: 8),
                                _M3ChipBtn(icon: Icons.refresh, label: '重说'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 设置列表卡
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: s.bgWindow, borderRadius: BorderRadius.circular(18), border: Border.all(color: s.divider)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            m3Row('chip', '模型', 'qwen2.5:7b'),
                            m3Row('keyboard', '译语键盘', '已启用'),
                            m3Row('globe', '语言方向', '中文 ⇄ English'),
                            m3Row('shield', '隐私锁', '指纹解锁',
                                trailing: LfSwitch(value: true, onChanged: (_) {})),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // NavigationBar
              Container(
                height: 60,
                decoration: BoxDecoration(color: s.bgWindow, border: Border(top: BorderSide(color: s.divider))),
                child: Row(
                  children: [
                    for (final (i, e) in [
                      (Icons.home_outlined, '首页'),
                      (Icons.history, '历史'),
                      (Icons.person_outline, '我的'),
                    ].indexed)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 46,
                              height: 26,
                              decoration: BoxDecoration(
                                color: i == 0 ? s.brandSoft : Colors.transparent,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(e.$1, size: 17, color: i == 0 ? s.brand : s.text3),
                            ),
                            const SizedBox(height: 2),
                            Text(e.$2, style: TextStyle(fontSize: 9, color: i == 0 ? s.brand : s.text3)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // FAB
          Positioned(
            right: 14,
            bottom: 74,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(16), boxShadow: s.shadowBrand),
              child: Center(child: LfIcons.icon('mic', size: 22, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _M3ChipBtn extends StatelessWidget {
  const _M3ChipBtn({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: s.dividerStrong),
        borderRadius: BorderRadius.circular(LfDimens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: s.text2),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2)),
        ],
      ),
    );
  }
}
