import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../services/app_store.dart';
import '../overlays/floating_windows.dart';
import 'flow_page.dart' show HostTitleBar;

/// 流程 B/C/D/E 演示页 —— 原型对应 Tab，四页共用「宿主场景 + 浮层 + 状态序列」骨架。
/// 状态序列走 schedule 定时器（切页 dispose 清理，防孤儿回调——原型 session07 教训）。

abstract class FlowDemoPage extends StatefulWidget {
  const FlowDemoPage({super.key, required this.store});

  final AppStore store;

  /// 状态数（演示控制按钮 1..N）。
  int get stateCount;

  String get hostTitle;
}

mixin FlowDemoStateMixin<T extends FlowDemoPage> on State<T> {
  int stateIdx = 0;
  final List<Timer> _timers = [];

  void schedule(void Function() fn, Duration d) {
    _timers.add(Timer(d, fn));
  }

  void cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// 单切状态（演示控制 / 测试调用）。
  void setStateAt(int i) {
    cancelTimers();
    setState(() => stateIdx = i);
    onStateChanged(i);
  }

  /// 重放全流程（子类实现状态序列）。
  void replay();

  void onStateChanged(int i) {}

  @override
  void dispose() {
    cancelTimers();
    super.dispose();
  }

  Widget demoControls() {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: s.bgWindow,
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.divider),
        boxShadow: s.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '演示控制',
            style: TextStyle(fontSize: LfDimens.fsXs, fontWeight: FontWeight.w700, color: s.text2),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < widget.stateCount; i++)
                _StateBtn(
                  label: '${i + 1}. ${stateLabels[i]}',
                  active: i == stateIdx,
                  onTap: () => setStateAt(i),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateBtn(label: '▶ 重放', active: false, onTap: replay),
              const SizedBox(width: 4),
              _StateBtn(label: '↺ 重置', active: false, onTap: () => setStateAt(0)),
            ],
          ),
        ],
      ),
    );
  }

  List<String> get stateLabels;
}

class _StateBtn extends StatelessWidget {
  const _StateBtn({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: active ? s.brand : s.bgSource,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: LfDimens.fsXs,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? Colors.white : s.text2,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// 流程 B · 悬浮窗输入翻译（Slack 宿主）
// ==================================================================
class FlowBPage extends FlowDemoPage {
  const FlowBPage({super.key, required super.store});

  @override
  int get stateCount => 4;

  @override
  String get hostTitle => 'Slack · 工程频道';

  @override
  State<FlowDemoPage> createState() => _FlowBPageState();
}

class _FlowBPageState extends State<FlowBPage> with FlowDemoStateMixin {
  static const source = '本周三之前能敲定报价吗？合同下周五前要签。';
  static const full = 'Can we finalize the quote by this Wednesday? The contract needs to be signed by next Friday.';

  @override
  List<String> get stateLabels => const ['触发', '加载', '流式', '完成'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 600));
    schedule(() => setStateAt(2), const Duration(milliseconds: 1500));
    schedule(() => setStateAt(3), const Duration(milliseconds: 3200));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgWindow,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HostBubble(
                      meta: 'Daniel · 14:28',
                      text: 'Hi Kevin, can you confirm the quote by Wednesday? We want to sign the contract before next Friday.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 44,
          right: 16,
          child: demoControls(),
        ),
        // 悬浮窗（居中偏右）
        Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: Center(
            child: MiniFloatingWindow(
              state: stateIdx,
              source: source,
              streamedText: stateIdx == 2
                  ? full.substring(0, (full.length * 0.55).floor())
                  : full,
              onCopy: () {},
              onInject: () {},
              onClose: () => setStateAt(3),
            ),
          ),
        ),
      ],
    );
  }
}

class _HostBubble extends StatelessWidget {
  const _HostBubble({required this.meta, required this.text});

  final String meta;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(meta, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: s.bgSource,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(text, style: TextStyle(fontSize: LfDimens.fsBase, color: s.text, height: 1.5)),
        ),
      ],
    );
  }
}

// ==================================================================
// 流程 C · 划词翻译（Medium 宿主）
// ==================================================================
class FlowCPage extends FlowDemoPage {
  const FlowCPage({super.key, required super.store});

  @override
  int get stateCount => 4;

  @override
  String get hostTitle => 'Chrome · Medium 文章';

  @override
  State<FlowDemoPage> createState() => _FlowCPageState();
}

class _FlowCPageState extends State<FlowCPage> with FlowDemoStateMixin {
  static const word = 'forget to unsubscribe';
  static const translated = '忘记取消订阅';

  @override
  List<String> get stateLabels => const ['选词', '弹窗', '翻译', '替换'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 700));
    schedule(() => setStateAt(2), const Duration(milliseconds: 1700));
    schedule(() => setStateAt(3), const Duration(milliseconds: 3000));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgWindow,
                padding: const EdgeInsets.all(28),
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why useEffect Cleanup Matters',
                        style: TextStyle(
                          fontSize: LfDimens.fsLg,
                          fontWeight: FontWeight.w700,
                          color: s.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: LfDimens.fsBase, color: s.text2, height: 1.75),
                          children: [
                            const TextSpan(text: 'Many developers '),
                            TextSpan(
                              text: word,
                              style: TextStyle(
                                backgroundColor: stateIdx >= 1 ? s.brandSoft2 : s.brandSoft,
                              ),
                            ),
                            const TextSpan(
                              text: ' from event listeners. This causes memory leaks in single-page apps.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A proper cleanup function returns from useEffect. Most teams use a linter to enforce this.',
                        style: TextStyle(fontSize: LfDimens.fsBase, color: s.text2, height: 1.75),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
        if (stateIdx >= 1)
          const Positioned(top: 150, right: 200, child: SelectionMarker()),
        if (stateIdx >= 2)
          Positioned(
            bottom: 80,
            right: 60,
            child: SelectionPopover(
              word: word,
              translated: translated,
              translating: stateIdx == 2,
              onCopy: () {},
              onReplace: () {},
            ),
          ),
      ],
    );
  }
}

// ==================================================================
// 流程 D · 静默替换（GitHub Issue 宿主）
// ==================================================================
class FlowDPage extends FlowDemoPage {
  const FlowDPage({super.key, required super.store});

  @override
  int get stateCount => 3;

  @override
  String get hostTitle => 'Chrome · GitHub Issue 评论';

  @override
  State<FlowDemoPage> createState() => _FlowDPageState();
}

class _FlowDPageState extends State<FlowDPage> with FlowDemoStateMixin {
  static const original = '需要给页面添加一个深色模式开关';
  static const translated = 'Add a dark mode toggle to the page';

  @override
  List<String> get stateLabels => const ['打字中', '翻译中', '已替换'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1400));
    schedule(() => setStateAt(2), const Duration(milliseconds: 2700));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgWindow,
                padding: const EdgeInsets.all(20),
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#1827 · Add dark mode toggle',
                      style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(minHeight: 64),
                      decoration: BoxDecoration(
                        color: s.bgWindow,
                        borderRadius: BorderRadius.circular(LfDimens.rInput),
                        border: Border.all(color: stateIdx == 2 ? s.brand : s.dividerStrong, width: stateIdx == 2 ? 1.4 : 1),
                      ),
                      child: Text(
                        stateIdx == 2 ? translated : original,
                        style: TextStyle(fontSize: LfDimens.fsBase, color: s.text, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Center(
            child: SilentBar(
              processed: original.length,
              total: original.length,
              done: stateIdx == 2,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// 流程 E · 截图 OCR（PDF 宿主）
// ==================================================================
class FlowEPage extends FlowDemoPage {
  const FlowEPage({super.key, required super.store});

  @override
  int get stateCount => 3;

  @override
  String get hostTitle => 'PDF · 合同节选';

  @override
  State<FlowDemoPage> createState() => _FlowEPageState();
}

class _FlowEPageState extends State<FlowEPage> with FlowDemoStateMixin {
  static const source =
      'The Seller shall deliver the Goods within thirty (30) business days after receipt of the Purchase Order.';
  static const target = '卖方应在收到采购订单后 30 个工作日内交付货物。';

  @override
  List<String> get stateLabels => const ['框选', 'OCR 识别', '双栏结果'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1200));
    schedule(() => setStateAt(2), const Duration(milliseconds: 2600));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgSource,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.topLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: s.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARTICLE 3 · DELIVERY TERMS',
                        style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: s.text),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '3.1 The Seller shall deliver the Goods within thirty (30) business days after receipt of the Purchase Order.',
                        style: TextStyle(fontSize: LfDimens.fsSm, color: s.text, height: 1.7),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '3.2 Risk of loss passes to the Buyer upon delivery to the carrier.',
                        style: TextStyle(fontSize: LfDimens.fsSm, color: s.text, height: 1.7),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '3.3 Late delivery exceeding seven (7) days entitles the Buyer to terminate without penalty.',
                        style: TextStyle(fontSize: LfDimens.fsSm, color: s.text, height: 1.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
        // 框选遮罩 / OCR 窗
        if (stateIdx >= 1)
          Positioned.fill(
            child: stateIdx == 1
                ? const OcrSelectionMask()
                : Container(
                    color: Colors.black12,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: OcrResultWindow(
                      source: source,
                      target: target,
                      onCopySource: () {},
                      onCopyTarget: () {},
                      onInject: () {},
                      onDone: () {},
                    ),
                  ),
          ),
      ],
    );
  }
}
