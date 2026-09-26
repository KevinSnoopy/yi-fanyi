import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../../engine/translate_runner.dart';
import '../../services/app_store.dart';
import '../../services/hotkeys.dart';
import '../../services/native_bridge.dart';
import '../../services/service_scope.dart';
import '../../services/system_trigger.dart';
import '../components/common.dart';
import '../overlays/floating_windows.dart';
import '../overlays/live_overlays.dart';
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

/// T-022 · 真实触发混入 —— 订阅热键事件 + 走 SystemTriggerService。
///
/// 与 [FlowDemoStateMixin] 的分工：演示序列（定时器）归前者，真实交互
/// （热键 → 浮层 → 真实流式 → 写回）归本混入；一旦进入真实交互立即
/// `cancelTimers()`，两套逻辑不并存（防孤儿回调 —— 原型 session07 教训）。
mixin LiveFlowMixin<T extends FlowDemoPage> on State<T> {
  StreamSubscription<HotkeyEvent>? _hotkeySub;
  late final TranslateRunner runner = TranslateRunner(store: widget.store);

  ServiceScope? get scope => ServiceScope.maybeOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hotkeySub ??= scope?.services.hotkeyEvents.listen(onHotkey);
  }

  @override
  void dispose() {
    _hotkeySub?.cancel();
    runner.abort();
    super.dispose();
  }

  /// 子类实现：匹配自己的热键 id。
  void onHotkey(HotkeyEvent e);

  /// 请求弹出浮层：优先原生，失败退回页面内渲染（由子类 setState 打开）。
  Future<TriggerMode> requestOverlay(TriggerRequest req) async {
    final trigger = scope?.trigger;
    if (trigger == null) return TriggerMode.inApp;
    return trigger.request(req);
  }

  void toast(String msg) => scope?.toasts.show(msg);

  /// 写回：走原生桥 injectText（Web 降级剪贴板），并把结果落回宿主输入框。
  Future<void> writeBack(String text, {TextEditingController? target}) async {
    if (target != null) target.text = text;
    await scope?.trigger.injectText(text);
  }

  String clip(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';
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

class _FlowBPageState extends State<FlowBPage> with FlowDemoStateMixin, LiveFlowMixin {
  static const source = '本周三之前能敲定报价吗？合同下周五前要签。';
  static const full = 'Can we finalize the quote by this Wednesday? The contract needs to be signed by next Friday.';

  final TextEditingController _input = TextEditingController(text: source);
  final FocusNode _inputFocus = FocusNode();
  final TextEditingController _host = TextEditingController();

  bool _live = false;
  bool _streaming = false;
  String _streamed = '';
  String? _error;
  String _latency = '—';

  @override
  List<String> get stateLabels => const ['触发', '加载', '流式', '完成'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _host.dispose();
    super.dispose();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 600));
    schedule(() => setStateAt(2), const Duration(milliseconds: 1500));
    schedule(() => setStateAt(3), const Duration(milliseconds: 3200));
  }

  // ---------------- T-022 真实触发 ----------------

  @override
  void onHotkey(HotkeyEvent e) {
    if (e.id == 'hk-b' && e.down) unawaited(open());
  }

  /// 唤起悬浮窗：⌥Space（进程内）/ 原生全局热键 → 走 SystemTriggerService。
  Future<void> open() async {
    cancelTimers();
    setState(() {
      _live = true;
      _streamed = '';
      _error = null;
      _streaming = false;
    });

    final mode = await requestOverlay(
      const TriggerRequest(id: 'b-float', kind: SystemOverlayKind.floatingWindow),
    );
    if (!mounted) return;
    _inputFocus.requestFocus();
    toast(mode == TriggerMode.system
        ? '已唤起系统悬浮窗（原生 NSPanel）'
        : '已唤起悬浮窗 · 应用内降级（浏览器预览无系统浮层）');

    // PRD 流程 B：自动读剪贴板（空输入时才填，避免覆盖用户已输入内容）
    if (_input.text.trim().isEmpty) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final t = data?.text?.trim() ?? '';
      if (t.isNotEmpty && t.length <= 500) setState(() => _input.text = t);
    }
  }

  /// 真实流式翻译（走 AppStore.resolveProvider：有 Key 走真模型，否则演示流）。
  Future<void> submit() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _streaming = true;
      _streamed = '';
      _error = null;
    });
    final sw = Stopwatch()..start();
    await runner.start(
      text: text,
      sourceLang: '中文',
      targetLang: 'English',
      style: widget.store.translateStyle,
      onDelta: (partial) {
        if (mounted) setState(() => _streamed = partial);
      },
      onError: (e) {
        if (mounted) setState(() => _error = '${e.code.name} · ${clip(e.detail, 140)}');
      },
    );
    sw.stop();
    if (!mounted) return;
    setState(() {
      _streaming = false;
      _latency = '${sw.elapsedMilliseconds}ms';
    });
  }

  Future<void> writeBackAndClose() async {
    if (_streamed.isEmpty) return;
    await writeBack(_streamed, target: _host);
    toast('已写回宿主输入框');
    close();
  }

  Future<void> copyOnly() async {
    await Clipboard.setData(ClipboardData(text: _streamed));
    toast('译文已复制');
  }

  void close() {
    runner.abort();
    const id = 'b-float';
    unawaited(scope?.trigger.close(id));
    setState(() => _live = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final profile = widget.store.defaultProfile;
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgWindow,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HostBubble(
                      meta: 'Daniel · 14:28',
                      text: 'Hi Kevin, can you confirm the quote by Wednesday? We want to sign the contract before next Friday.',
                    ),
                    if (_host.text.isNotEmpty)
                      _HostBubble(meta: '我 · 刚刚', text: _host.text, mine: true),
                  ],
                ),
              ),
            ),
            // 宿主输入框（写回落点）
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: s.bgWindow,
                border: Border(top: BorderSide(color: s.divider)),
              ),
              child: TextField(
                controller: _host,
                style: TextStyle(fontSize: LfDimens.fsBase, color: s.text),
                decoration: const InputDecoration(hintText: '译文将写回这里…'),
              ),
            ),
          ],
        ),
        if (!_live) Positioned(top: 44, right: 16, child: demoControls()),
        if (_live)
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Center(
              child: LiveFloatingWindow(
                input: _input,
                inputFocus: _inputFocus,
                streamed: _streamed,
                streaming: _streaming,
                error: _error,
                modelLabel: runner.source == ProviderSource.real
                    ? '${profile?.platform ?? ''} · ${profile?.model ?? ''}'
                    : '演示流式 · MockProvider',
                latencyLabel: _latency,
                onClose: close,
                onCopy: copyOnly,
                onSubmit: () => unawaited(submit()),
                onWriteBack: () => unawaited(writeBackAndClose()),
              ),
            ),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Center(
              child: MiniFloatingWindow(
                state: stateIdx,
                source: source,
                streamedText: stateIdx == 2 ? full.substring(0, (full.length * 0.55).floor()) : full,
                onCopy: () {},
                onInject: () {},
                onClose: () => setStateAt(3),
              ),
            ),
          ),
        // 触发提示（真实热键 + 兜底按钮）
        Positioned(
          left: 16,
          bottom: 16,
          child: _TriggerHint(
            hotkey: '⌥ Space',
            label: '唤起悬浮窗',
            live: _live,
            onTap: () => unawaited(open()),
          ),
        ),
      ],
    );
  }
}

/// 触发提示条：展示真实热键 + 兜底点击（浏览器里热键可能被浏览器占用）。
class _TriggerHint extends StatelessWidget {
  const _TriggerHint({
    required this.hotkey,
    required this.label,
    required this.live,
    required this.onTap,
  });

  final String hotkey;
  final String label;
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: s.bgBar,
      borderRadius: BorderRadius.circular(LfDimens.rPill),
      child: InkWell(
        onTap: live ? null : onTap,
        borderRadius: BorderRadius.circular(LfDimens.rPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LfDimens.rPill),
            border: Border.all(color: s.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Kbd(hotkey),
              const SizedBox(width: 7),
              Text(
                live ? '$label · 进行中' : '点此$label',
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostBubble extends StatelessWidget {
  const _HostBubble({required this.meta, required this.text, this.mine = false});

  final String meta;
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(meta, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: mine ? s.brandSoft : s.bgSource,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(mine ? 12 : 3),
              topRight: Radius.circular(mine ? 3 : 12),
              bottomLeft: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
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

class _FlowCPageState extends State<FlowCPage> with FlowDemoStateMixin, LiveFlowMixin {
  static const prefix = 'Many developers ';
  static const suffix = ' from event listeners. This causes memory leaks in single-page apps.';
  static const initialWord = 'forget to unsubscribe';
  static const translated = '忘记取消订阅';

  String _word = initialWord;
  bool _live = false;
  bool _streaming = false;
  String _streamed = '';
  String? _error;
  String _latency = '68ms';
  TapGestureRecognizer? _tap;

  @override
  List<String> get stateLabels => const ['选词', '弹窗', '翻译', '替换'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void dispose() {
    _tap?.dispose();
    super.dispose();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 700));
    schedule(() => setStateAt(2), const Duration(milliseconds: 1700));
    schedule(() => setStateAt(3), const Duration(milliseconds: 3000));
  }

  // ---------------- T-022 真实触发 ----------------

  @override
  void onHotkey(HotkeyEvent e) {
    if (e.id == 'hk-c' && e.down) unawaited(open());
  }

  /// 划词：先问原生桥要选区（macOS AX），取不到则退回页面内点选的词。
  Future<void> open() async {
    cancelTimers();
    final native = await scope?.trigger.readSelection();
    final word = (native != null && native.trim().isNotEmpty) ? native.trim() : _word;
    if (word.isEmpty) {
      toast('未读取到选区：先在正文里点选一个词');
      return;
    }
    setState(() {
      _word = word;
      _live = true;
      _streamed = '';
      _error = null;
      _streaming = false;
    });
    await requestOverlay(
      TriggerRequest(id: 'c-sel', kind: SystemOverlayKind.selectionPopover, text: word),
    );
    if (!mounted) return;
    unawaited(translate(word));
  }

  Future<void> translate(String word) async {
    setState(() => _streaming = true);
    final sw = Stopwatch()..start();
    await runner.start(
      text: word,
      sourceLang: 'English',
      targetLang: '中文',
      onDelta: (partial) {
        if (mounted) setState(() => _streamed = partial);
      },
      onError: (e) {
        if (mounted) setState(() => _error = '${e.code.name} · ${clip(e.detail, 120)}');
      },
    );
    sw.stop();
    if (!mounted) return;
    setState(() {
      _streaming = false;
      _latency = '${sw.elapsedMilliseconds}ms';
    });
  }

  Future<void> replace() async {
    final t = _streamed.trim();
    if (t.isEmpty) return;
    setState(() => _word = t);
    await writeBack(t);
    toast('已替换选区');
    close();
  }

  Future<void> copyOnly() async {
    await Clipboard.setData(ClipboardData(text: _streamed.trim()));
    toast('译文已复制');
  }

  void close() {
    runner.abort();
    unawaited(scope?.trigger.close('c-sel'));
    setState(() => _live = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    _tap ??= TapGestureRecognizer()..onTap = () => unawaited(open());
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
                            const TextSpan(text: prefix),
                            TextSpan(
                              text: _word,
                              recognizer: _tap,
                              style: TextStyle(
                                backgroundColor: (_live || stateIdx >= 1) ? s.brandSoft2 : s.brandSoft,
                                color: s.text,
                              ),
                            ),
                            const TextSpan(text: suffix),
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
        if (!_live) Positioned(top: 44, right: 16, child: demoControls()),
        if (_live || stateIdx >= 1)
          Positioned(top: 150, right: 200, child: SelectionMarker(onTap: () => unawaited(open()))),
        if (_live)
          Positioned(
            bottom: 80,
            right: 60,
            child: SelectionPopover(
              word: _word,
              translated: _error ?? (_streamed.isEmpty ? '翻译中…' : _streamed),
              translating: _streaming,
              latency: _latency,
              onCopy: copyOnly,
              onReplace: replace,
            ),
          )
        else if (stateIdx >= 2)
          Positioned(
            bottom: 80,
            right: 60,
            child: SelectionPopover(
              word: initialWord,
              translated: translated,
              translating: stateIdx == 2,
              onCopy: () {},
              onReplace: () {},
            ),
          ),
        Positioned(
          left: 16,
          bottom: 16,
          child: _TriggerHint(
            hotkey: '⌥ D',
            label: '划词翻译',
            live: _live,
            onTap: () => unawaited(open()),
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

class _FlowDPageState extends State<FlowDPage> with FlowDemoStateMixin, LiveFlowMixin {
  static const original = '需要给页面添加一个深色模式开关';

  final TextEditingController _input = TextEditingController(text: original);
  final FocusNode _focus = FocusNode();

  bool _live = false;
  bool _done = false;
  int _processed = 0;
  int _total = 0;
  String? _error;
  String? _lastOriginal;

  @override
  List<String> get stateLabels => const ['打字中', '翻译中', '已替换'];

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    replay();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _input.dispose();
    super.dispose();
  }

  /// PRD §4 规则 3：静默替换进行中若焦点变化，立即终止并 toast。
  void _onFocusChange() {
    if (!_focus.hasFocus && runner.running) {
      runner.abort();
      if (!mounted) return;
      setState(() {
        _live = false;
        _processed = 0;
      });
      toast('焦点变化 · 静默替换已终止');
      unawaited(scope?.trigger.notify(title: '静默替换已终止', body: '检测到焦点切换，未写入译文'));
    }
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1400));
    schedule(() => setStateAt(2), const Duration(milliseconds: 2700));
  }

  // ---------------- T-022 真实触发 ----------------

  @override
  void onHotkey(HotkeyEvent e) {
    if (e.id == 'hk-d' && e.down) unawaited(silentReplace());
  }

  /// 静默替换：无窗口打断，底部状态条显示真实进度，完成后原文被译文替换。
  Future<void> silentReplace() async {
    cancelTimers();
    final text = _input.text.trim();
    if (text.isEmpty) {
      toast('输入框是空的');
      return;
    }
    setState(() {
      _live = true;
      _done = false;
      _processed = 0;
      _total = text.length;
      _error = null;
      _lastOriginal = text;
    });

    final full = await runner.start(
      text: text,
      sourceLang: '中文',
      targetLang: 'English',
      style: widget.store.translateStyle,
      onDelta: (partial) {
        if (mounted) setState(() => _processed = partial.length);
      },
      onError: (e) {
        if (mounted) setState(() => _error = '${e.code.name} · ${clip(e.detail, 120)}');
      },
    );
    if (!mounted) return;

    if (full == null || full.isEmpty) {
      setState(() => _live = false);
      toast(_error ?? '翻译未完成');
      return;
    }

    setState(() {
      _input.text = full;
      _done = true;
      _live = true;
    });
    await writeBack(full);
    toast('原文已被译文替换');
    unawaited(scope?.trigger.notify(title: '静默替换完成', body: '${clip(text, 20)} → ${clip(full, 30)}'));
  }

  Future<void> undo() async {
    if (_lastOriginal == null) return;
    setState(() {
      _input.text = _lastOriginal!;
      _done = false;
      _live = false;
      _processed = 0;
    });
    toast('已撤回替换');
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
                        border: Border.all(
                          color: (_live && _done) || stateIdx == 2 ? s.brand : s.dividerStrong,
                          width: (_live && _done) || stateIdx == 2 ? 1.4 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _input,
                        focusNode: _focus,
                        maxLines: 3,
                        style: TextStyle(fontSize: LfDimens.fsBase, color: s.text, height: 1.5),
                        decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '替换失败 · $_error',
                        style: TextStyle(fontSize: LfDimens.fsXs, color: s.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!_live) Positioned(top: 44, right: 16, child: demoControls()),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Center(
            child: _live
                ? SilentBar(processed: _processed, total: _total, done: _done, onUndo: undo)
                : SilentBar(processed: original.length, total: original.length, done: stateIdx == 2),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: _TriggerHint(
            hotkey: '⌥ ↩',
            label: '静默替换',
            live: _live,
            onTap: () => unawaited(silentReplace()),
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
