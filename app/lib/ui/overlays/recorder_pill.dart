import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../engine/recorder_state_machine.dart';

/// 录音条 pill —— ADR-008 三态强制组件（PRD v3.2 §5.1 / §5.3 ①）。
///
/// ```
/// [◉ 波形  0:02  ○译开关]   录音态：160×36 基准 + 波形 + 计时 + 翻译开关（默认关）
/// [◌ 成稿中… 已输出 8 字  Esc取消]  处理态：开关开时显示「翻译中…」
/// [成稿文本… ✓1.2s ✗重说]   预览态：自适应加宽（max 400）
/// [✓ 已写入输入框 · 成稿]   完成态：1.5s 后自动淡出
/// ```
///
/// 动画约束（原型陷阱备忘）：pill 为居中元素，入场用 rise（上移 8px + 淡入），
/// 出场下沉淡出；非居中元素同样走 rise，不存在 translateX(-50%) 体系。
class RecorderPill extends StatelessWidget {
  const RecorderPill({
    super.key,
    required this.state,
    required this.onToggleTranslate,
    this.onCancel,
    this.onRetry,
    this.onConfirm,
    this.onHoldStart,
    this.onHoldEnd,
    this.winSkin = false,
  });

  final RecorderStateMachine state;
  final VoidCallback onToggleTranslate;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onConfirm;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final bool winSkin; // N Windows 端 Fluent 皮肤（隐藏「译」开关，显示 Win+H）

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final phase = state.phase;
        if (phase == RecorderPhase.idle) return const SizedBox.shrink();

        final bool isPreview = phase == RecorderPhase.preview;
        final bool isRecording = phase == RecorderPhase.recording;

        final Widget content = switch (phase) {
          RecorderPhase.recording => _RecordingBody(state: state, transSwitch: winSkin ? null : _TransSwitch(on: state.translateOn, onTap: onToggleTranslate), winHint: winSkin),
          RecorderPhase.drafting => _DraftingBody(state: state, transSwitch: winSkin ? null : _TransSwitch(on: state.translateOn, onTap: onToggleTranslate)),
          RecorderPhase.preview => _PreviewBody(state: state, onRetry: onRetry, onConfirm: onConfirm, transSwitch: winSkin ? null : _TransSwitch(on: state.translateOn, onTap: onToggleTranslate)),
          RecorderPhase.done => _DoneBody(translateOn: state.translateOn),
          RecorderPhase.idle => const SizedBox.shrink(),
        };

        return AnimatedSwitcher(
          duration: LfDimens.tBase,
          switchInCurve: LfDimens.ease,
          switchOutCurve: LfDimens.ease,
          transitionBuilder: (child, anim) {
            // 淡入 + 上移 8px（≤180ms，PRD §4 规则 4）
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(phase),
            constraints: const BoxConstraints(
              minWidth: LfDimens.pillMinW,
              maxWidth: LfDimens.pillMaxW,
              minHeight: LfDimens.barH,
            ),
            padding: EdgeInsets.only(left: 13, right: isPreview ? 8 : 13, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: s.bgWindow.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(LfDimens.rPill),
              border: Border.all(
                color: isRecording || phase == RecorderPhase.drafting
                    ? s.brand.withValues(alpha: 0.55)
                    : s.dividerStrong,
                width: 1.2,
              ),
              boxShadow: s.shadowBar,
            ),
            child: content,
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// 录音态：mic 点 + 波形 + 计时 + 「译」开关
// ------------------------------------------------------------------
class _RecordingBody extends StatelessWidget {
  const _RecordingBody({required this.state, this.transSwitch, this.winHint = false});

  final RecorderStateMachine state;
  final Widget? transSwitch;
  final bool winHint;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MicDot(),
        const SizedBox(width: 8),
        const WaveBars(active: true),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: state,
          builder: (_, __) => Text(
            formatRecorded(state.recorded),
            style: TextStyle(
              fontSize: LfDimens.fsSm,
              fontWeight: FontWeight.w600,
              color: s.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (transSwitch != null) ...[
          const SizedBox(width: 10),
          transSwitch!,
        ] else if (winHint) ...[
          const SizedBox(width: 10),
          Text(
            'Win+H',
            style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

/// 红点（录音 / 完成变绿）。
class MicDot extends StatelessWidget {
  const MicDot({super.key, this.ok = false});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final Color c = ok ? s.success : s.error;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 2)],
      ),
    );
  }
}

/// 波形条（10 根正弦相位柱，60fps Ticker 驱动）。
class WaveBars extends StatefulWidget {
  const WaveBars({super.key, this.active = true, this.count = 10, this.width = 3, this.maxHeight = 14});

  final bool active;
  final int count;
  final double width;
  final double maxHeight;

  @override
  State<WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<WaveBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

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
            for (var i = 0; i < widget.count; i++)
              Container(
                width: widget.width,
                height: widget.active
                    ? 3 +
                        (widget.maxHeight - 3) *
                            (0.35 + 0.65 * (0.5 + 0.5 * math.sin((_c.value * 2 * math.pi) + i * 0.9)))
                    : 3,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  color: s.brand.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// 处理态：spinner + 「成稿中…/翻译中…」 + 已输出 N 字 + Esc 取消
// ------------------------------------------------------------------
class _DraftingBody extends StatelessWidget {
  const _DraftingBody({required this.state, this.transSwitch});

  final RecorderStateMachine state;
  final Widget? transSwitch;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LfSpinner(size: 13),
            const SizedBox(width: 8),
            Text(
              state.translateOn ? '翻译中…' : '成稿中…',
              style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text),
            ),
            Text(
              ' 已输出 ${state.streamedChars} 字',
              style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
            ),
            const SizedBox(width: 8),
            Text(
              'Esc 取消',
              style: TextStyle(
                fontSize: LfDimens.fs2xs,
                color: s.text2,
                decoration: TextDecoration.underline,
              ),
            ),
            if (transSwitch != null) ...[
              const SizedBox(width: 10),
              transSwitch!,
            ],
          ],
        );
      },
    );
  }
}

/// 旋转 spinner（--bar-spinner）。
class LfSpinner extends StatefulWidget {
  const LfSpinner({super.key, this.size = 13, this.color});

  final double size;
  final Color? color;

  @override
  State<LfSpinner> createState() => _LfSpinnerState();
}

class _LfSpinnerState extends State<LfSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.rotate(
          angle: _c.value * 2 * math.pi,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              value: 0.32,
              color: widget.color ?? s.brand,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// 预览态：成稿文本 + 光标 + ✓1.2s / ✗重说
// ------------------------------------------------------------------
class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.state, this.onRetry, this.onConfirm, this.transSwitch});

  final RecorderStateMachine state;
  final VoidCallback? onRetry;
  final VoidCallback? onConfirm;
  final Widget? transSwitch;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 44),
            child: Text(
              state.previewText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: LfDimens.fsSm,
                color: s.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const BlinkCursor(),
        const SizedBox(width: 10),
        _PillAction(label: '✓ 1.2s', onTap: onConfirm, primary: true),
        const SizedBox(width: 4),
        _PillAction(label: '✗ 重说', onTap: onRetry),
        if (transSwitch != null) ...[
          const SizedBox(width: 8),
          transSwitch!,
        ],
      ],
    );
  }
}

/// 打字光标（竖条闪烁）。
class BlinkCursor extends StatefulWidget {
  const BlinkCursor({super.key, this.color});

  final Color? color;

  @override
  State<BlinkCursor> createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<BlinkCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

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
      child: Container(
        width: 2,
        height: 14,
        margin: const EdgeInsets.only(left: 2),
        color: widget.color ?? s.brand,
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({required this.label, this.onTap, this.primary = false});

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: primary ? s.brand : Colors.transparent,
      borderRadius: BorderRadius.circular(LfDimens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LfDimens.rPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            style: TextStyle(
              fontSize: LfDimens.fs2xs,
              fontWeight: FontWeight.w700,
              color: primary ? Colors.white : s.text2,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// 完成态：绿点 + ✓ 已写入输入框 · 成稿 / 中→EN
// ------------------------------------------------------------------
class _DoneBody extends StatelessWidget {
  const _DoneBody({required this.translateOn});

  final bool translateOn;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MicDot(ok: true),
        const SizedBox(width: 8),
        Text(
          translateOn ? '✓ 已写入输入框 · 中→EN' : '✓ 已写入输入框 · 成稿',
          style: TextStyle(
            fontSize: LfDimens.fsSm,
            fontWeight: FontWeight.w600,
            color: s.text,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// 翻译开关 —— pill 右侧常驻「译」开关（默认关，PRD v3.2 §2.1 关键规则①）
// ------------------------------------------------------------------
class _TransSwitch extends StatelessWidget {
  const _TransSwitch({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Tooltip(
      message: '翻译开关：关 = 同语言成稿（默认），开 = 写入英文',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 22,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: on ? s.brandSoft2 : s.bgHover,
            borderRadius: BorderRadius.circular(LfDimens.rPill),
            border: Border.all(color: on ? s.brand.withValues(alpha: 0.5) : s.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '译',
                  style: TextStyle(
                    fontSize: LfDimens.fs2xs,
                    fontWeight: FontWeight.w700,
                    color: on ? s.brand : s.text3,
                  ),
                ),
              ),
              AnimatedAlign(
                duration: LfDimens.tFast,
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: on ? s.brand : s.bgWindow,
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? s.brand : s.dividerStrong),
                    boxShadow: s.shadowXs,
                  ),
                  child: on
                      ? Center(child: LfIcons.icon('check', size: 9, color: Colors.white))
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
