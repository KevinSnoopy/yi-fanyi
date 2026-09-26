import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../../engine/draft_pipeline.dart';
import '../../engine/recorder_state_machine.dart';
import '../../models/models.dart';
import '../../providers/mock_provider.dart';
import '../../providers/provider.dart';
import '../../services/app_store.dart';
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

  static const String _draftZh = '那个报价我确认没问题，下周三之前可以把合同签了。';
  static const String _draftEn =
      'Confirmed, no problem with the quote. We can sign the contract before next Wednesday.';

  @override
  void initState() {
    super.initState();
    sm = RecorderStateMachine();
    pipeline = DraftPipeline(sm: sm, stt: MockStt(), provider: _providerFor());
  }

  @override
  void dispose() {
    sm.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// 依 AppStore 当前默认 Profile 建 Provider（未配置走 Mock 兜底）。
  TranslationProvider _providerFor() {
    final p = widget.store.defaultProfile;
    if (p == null || p.platform == '演示') return MockProvider(draftText: _draftZh, translateText: _draftEn);
    // 预览环境：真实 Provider 由桌面端使用；Web 演示统一走 Mock 流式
    return MockProvider(draftText: _draftZh, translateText: _draftEn);
  }

  Future<void> _startHold() async {
    sm.startRecording();
  }

  Future<void> _endHold() async {
    if (sm.phase != RecorderPhase.recording) return;
    await pipeline.run(
      glossaryJson: widget.store.glossaryJson(),
      tone: 'im',
      bilingual: widget.store.bilingualWriteBack,
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
          // 按住说话按钮
          Positioned(
            right: 20,
            bottom: 84,
            child: GestureDetector(
              onLongPressStart: (_) => _startHold(),
              onLongPressEnd: (_) => _endHold(),
              onLongPressCancel: _endHold,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: s.brandGrad,
                  shape: BoxShape.circle,
                  boxShadow: s.shadowBrand,
                ),
                child: Center(
                  child: ListenableBuilder(
                    listenable: sm,
                    builder: (_, __) => Icon(
                      Icons.mic_rounded,
                      size: 24,
                      color: sm.phase == RecorderPhase.recording
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ),
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
