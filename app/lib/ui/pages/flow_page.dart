import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../engine/draft_pipeline.dart';
import '../../engine/recorder_state_machine.dart';
import '../../models/models.dart';
import '../../providers/mock_provider.dart';
import '../../providers/provider.dart';
import '../../services/app_store.dart';
import '../../services/hotkeys.dart';
import '../../services/service_scope.dart';
import '../components/common.dart';
import '../overlays/recorder_pill.dart';

/// 流程 A 页 —— 核心链路真实现（PRD v3.2 §2.1）：
///
/// 按住说话（长按 🎤 或底部大按钮）→ pill 录音态 → 松手 → STT 转写 →
/// 成稿（MockProvider 流式；接已配置模型时走真实现）→ 预览 1.2s → 落框。
/// pill 右侧「译」开关默认关（同语言成稿），打开后成稿→中→英写入。
class FlowPage extends StatefulWidget {
  const FlowPage({super.key, required this.store, this.showWindowChrome = true});

  final AppStore store;
  final bool showWindowChrome;

  @override
  State<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends State<FlowPage> {
  late final RecorderStateMachine sm;
  late final DraftPipeline pipeline;
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  /// T-021：当前链路来源（真实模型 / 演示流式），UI 明示，不做隐瞒。
  ProviderSource _source = ProviderSource.mock;

  /// 当前生效模型标签（状态条展示）。
  String _modelLabel = '演示流式 · MockProvider';

  StreamSubscription<HotkeyEvent>? _hotkeySub;

  /// T-021 · 真实模型报错后，用户主动切「演示流式」兜底（PRD §7 绝不白屏）。
  /// 每次重新录音时重置，回到「真实优先」的判定链。
  bool _forceDemo = false;

  @override
  void initState() {
    super.initState();
    sm = RecorderStateMachine();
    pipeline = DraftPipeline(sm: sm, stt: MockStt(), provider: widget.store.demoProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // T-024：订阅流程 A 语音键（按住触发：down 开始 / up 结束）。
    _hotkeySub ??= ServiceScope.maybeOf(context)?.services.hotkeyEvents.listen((e) {
      if (e.id != 'hk-a') return;
      if (e.down) {
        _startHold();
      } else {
        unawaited(_endHold());
      }
    });
  }

  @override
  void dispose() {
    _hotkeySub?.cancel();
    sm.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// T-021 · 每次松手前重新解析 Provider：
  /// 有 Key 且已验证 → 真实模型流式；否则 → 演示流式兜底（PRD §7 绝不白屏）。
  Future<void> _refreshProvider() async {
    if (_forceDemo) {
      pipeline.provider = widget.store.demoProvider;
      _source = ProviderSource.mock;
      _modelLabel = '演示流式 · MockProvider（真实模型不可用，已手动降级）';
      if (mounted) setState(() {});
      return;
    }
    final p = await widget.store.resolveProvider();
    final profile = widget.store.defaultProfile;
    pipeline.provider = p;
    _source = widget.store.lastProviderSource;
    _modelLabel = _source == ProviderSource.real
        ? '${profile?.platform ?? ''} · ${profile?.model ?? ''}'
        : '演示流式 · MockProvider（未配置可用模型）';
    if (mounted) setState(() {});
  }

  Future<void> _startHold() async {
    _forceDemo = false; // 每次录音重新走真实优先判定链
    sm.startRecording();
  }

  /// 真实模型报错后手动降级演示流式并重跑一次（PRD §7）。
  Future<void> _fallbackDemo() async {
    _forceDemo = true;
    sm.clearError();
    await _runPipeline();
  }

  Future<void> _endHold() async {
    if (sm.phase != RecorderPhase.recording) return;
    await _runPipeline();
  }

  /// 成稿主链路：先解析 Provider（真实 / 演示），再跑 STT → 成稿 → 预览 → 落框。
  Future<void> _runPipeline() async {
    await _refreshProvider();
    await pipeline.run(
      glossaryJson: widget.store.glossaryJson(),
      tone: 'im',
      bilingual: widget.store.bilingualWriteBack,
      onError: (e) {
        final scope = ServiceScope.maybeOf(context);
        scope?.toasts.show('成稿失败 · ${e.code.name}');
      },
      onFinal: (text) {
        _input.text = text;
        _inputFocus.requestFocus();
        widget.store.addHistory(
          HistoryRecord(
            id: 'h-${DateTime.now().millisecondsSinceEpoch}',
            time: TimeOfDay.now().format(context),
            dir: sm.translateOn ? '中→英' : '成稿',
            source: '呃…那个报价我确认没问题啊，就下周三之前吧…',
            target: text,
            meta: '${text.length} 字 · ${(sm.translateOn ? 1100 : 800) / 1000}s',
            flow: 'A',
          ),
        );
      },
    );
  }

  void _cancel() {
    pipeline.abort();
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Stack(
        children: [
          // 宿主应用：微信聊天
          Positioned.fill(
            child: Column(
              children: [
                if (widget.showWindowChrome) const HostTitleBar(title: '微信 · 给李总的消息'),
                // T-021：链路来源 + 真实错误条（Provider 血缘对用户透明）
                ListenableBuilder(
                  listenable: sm,
                  builder: (context, _) => _ProviderBanner(
                    source: _source,
                    label: _modelLabel,
                    error: sm.error,
                    onDismiss: sm.clearError,
                    onFallbackDemo: _fallbackDemo,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: s.bgWindow,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: const [
                              _Bubble(
                                meta: '李总 · 14:28',
                                text: '小陈，报价单我让财务核过了，没问题。',
                              ),
                              _Bubble(
                                meta: '李总 · 14:29',
                                text: '确认一下，这周能把合同定下来吗？',
                              ),
                            ],
                          ),
                        ),
                        // 输入区
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          decoration: BoxDecoration(
                            color: s.bgWindow,
                            border: Border(top: BorderSide(color: s.divider)),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _input,
                                focusNode: _inputFocus,
                                maxLines: 2,
                                style: TextStyle(fontSize: LfDimens.fsBase, color: s.text),
                                decoration: const InputDecoration(
                                  hintText: '按住下方 🎤 说话，成稿写进这里…（Esc 取消）',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '按 ',
                                    style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
                                  ),
                                  const Kbd('Fn'),
                                  Text(
                                    ' 说话 · 成稿自动写入 · ',
                                    style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
                                  ),
                                  const Kbd('Esc'),
                                  Text(
                                    ' 取消',
                                    style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.sync_alt_rounded, size: 12, color: s.text3),
                                  const SizedBox(width: 4),
                                  Text(
                                    '已发送 2 条',
                                    style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // pill 录音条（底部居中偏上 80px，PRD §5.1）
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: IgnorePointer(
              ignoring: sm.phase == RecorderPhase.idle,
              child: Center(
                child: RecorderPill(
                  state: sm,
                  onToggleTranslate: sm.toggleTranslate,
                  onCancel: _cancel,
                  onRetry: sm.retry,
                  onConfirm: () => sm.confirm(sm.previewText),
                ),
              ),
            ),
          ),
          // 按住说话按钮（PRD §2.1：按住开始、松开成稿）
          Positioned(
            right: 20,
            bottom: 84,
            child: Semantics(
              button: true,
              label: '按住说话',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // 轻按即视为「按下」（PRD §2.1：按一下开始、再按一下结束）；
                // 长按走 long* 分支，与 tap 分支互斥不会重复触发。
                onTapDown: (_) => _startHold(),
                onTapUp: (_) => unawaited(_endHold()),
                onTapCancel: () => unawaited(_endHold()),
                onLongPressStart: (_) => _startHold(),
                onLongPressEnd: (_) => unawaited(_endHold()),
                onLongPressCancel: () => unawaited(_endHold()),
                child: ListenableBuilder(
                  listenable: sm,
                  builder: (_, __) {
                    final recording = sm.phase == RecorderPhase.recording;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: s.brandGrad,
                        shape: BoxShape.circle,
                        boxShadow: s.shadowBrand,
                        border: recording
                            ? Border.all(color: s.error.withValues(alpha: 0.9), width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          recording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 24,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// T-021 · Provider 血缘条：当前成稿走真实模型还是演示流式，出错时内联展示原始返回。
class _ProviderBanner extends StatelessWidget {
  const _ProviderBanner({
    required this.source,
    required this.label,
    this.error,
    this.onDismiss,
    this.onFallbackDemo,
  });

  final ProviderSource source;
  final String label;
  final LfProviderException? error;
  final VoidCallback? onDismiss;

  /// 真实模型不可用时，一键降级演示流式（PRD §7 绝不白屏）。
  final VoidCallback? onFallbackDemo;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final real = source == ProviderSource.real;
    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        color: s.error.withValues(alpha: 0.10),
        child: Row(
          children: [
            LfIcons.icon('warn', size: 12, color: s.error),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '成稿失败 · ${error!.code.name} · ${error!.detail.length > 120 ? '${error!.detail.substring(0, 120)}…' : error!.detail}',
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onFallbackDemo != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onFallbackDemo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.error.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '用演示流式重试',
                    style: TextStyle(fontSize: LfDimens.fs2xs, color: s.error),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: LfIcons.icon('x', size: 11, color: s.error),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: s.bgSource,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: real ? s.success : s.warning, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              real ? '真实模型 · $label · 请求直连模型方（ADR-001）' : label,
              style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class HostTitleBar extends StatelessWidget {
  const HostTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: s.bgSource,
        border: Border(bottom: BorderSide(color: s.divider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          for (final c in [s.macClose, s.macMin, s.macMax]) ...[
            Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          ],
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text2),
              ),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.meta, required this.text});

  final String meta;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meta, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: s.bgSource,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: LfDimens.fsBase, color: s.text, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
