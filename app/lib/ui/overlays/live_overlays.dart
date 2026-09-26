import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../components/common.dart';
import 'floating_windows.dart' show RiseIn;
import 'recorder_pill.dart' show BlinkCursor, LfSpinner;

/// T-022 · 真实悬浮窗（流程 B）—— 可输入 + 真实流式译文 + 写回/复制。
///
/// 与演示版 [MiniFloatingWindow] 的区别：原文区是**可编辑输入框**（用户打字或
/// 粘贴、自动读剪贴板），译文区由真实 Provider 流式填充，底部动作接
/// [SystemTriggerService]（Enter 写回 / ⌘Enter 仅复制 / Esc 关闭）。
class LiveFloatingWindow extends StatelessWidget {
  const LiveFloatingWindow({
    super.key,
    required this.input,
    required this.inputFocus,
    required this.streamed,
    required this.streaming,
    this.error,
    this.pair = const ('中文', 'English'),
    this.modelLabel = '未配置模型 · 演示流式',
    this.latencyLabel,
    this.onClose,
    this.onCopy,
    this.onWriteBack,
    this.onSubmit,
  });

  final TextEditingController input;
  final FocusNode inputFocus;
  final String streamed;
  final bool streaming;

  /// 真实 Provider 抛错时的内联错误条文本（null = 无错误）。
  final String? error;
  final (String, String) pair;
  final String modelLabel;
  final String? latencyLabel;
  final VoidCallback? onClose;
  final VoidCallback? onCopy;
  final VoidCallback? onWriteBack;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        width: LfDimens.popoverW,
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: BoxDecoration(
          color: s.bgBar,
          borderRadius: BorderRadius.circular(LfDimens.rPopover),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowPopover,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部：语言方向 + 模型 + 关闭
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  _LiveLangPair(pair),
                  const Spacer(),
                  Text(modelLabel, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClose,
                    child: LfIcons.icon('x', size: 12, color: s.text3),
                  ),
                ],
              ),
            ),
            // 原文输入区
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: s.bgSource,
                borderRadius: BorderRadius.circular(LfDimens.rInput),
              ),
              child: TextField(
                controller: input,
                focusNode: inputFocus,
                maxLines: 3,
                minLines: 2,
                onSubmitted: (_) => onSubmit?.call(),
                style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2, height: 1.55),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '打字或粘贴要翻译的内容…（Enter 翻译）',
                  hintStyle: TextStyle(fontSize: LfDimens.fsSm, color: s.text3),
                ),
              ),
            ),
            // 译文流式区
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.bgWindow,
                borderRadius: BorderRadius.circular(LfDimens.rInput),
                border: Border.all(color: error != null ? s.error : s.divider),
              ),
              child: _buildTarget(s),
            ),
            // 底部动作
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 12, 10),
              child: Row(
                children: [
                  LfButton(label: '复制', icon: 'copy', padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5), onPressed: onCopy),
                  const SizedBox(width: 6),
                  LfButton(
                    label: '写回',
                    icon: 'inject',
                    kind: LfButtonKind.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    onPressed: onWriteBack,
                  ),
                  const Spacer(),
                  Text(
                    latencyLabel ?? (streaming ? '流式输出中…' : '—'),
                    style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarget(LfScheme s) {
    if (error != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LfIcons.icon('warn', size: 13, color: s.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error!,
              style: TextStyle(fontSize: LfDimens.fsSm, color: s.error, height: 1.5),
            ),
          ),
        ],
      );
    }
    if (streaming && streamed.isEmpty) {
      return Row(
        children: [
          const LfSpinner(size: 12),
          const SizedBox(width: 6),
          Text('翻译中…', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
        ],
      );
    }
    if (streamed.isEmpty) {
      return Text(
        '译文将在这里流式出现',
        style: TextStyle(fontSize: LfDimens.fsMd, color: s.text3),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            streamed,
            style: TextStyle(fontSize: LfDimens.fsMd, color: s.text, height: 1.5),
          ),
        ),
        if (streaming) const BlinkCursor(),
      ],
    );
  }
}

class _LiveLangPair extends StatelessWidget {
  const _LiveLangPair(this.pair);

  final (String, String) pair;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(pair.$1, style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(Icons.arrow_forward_rounded, size: 12, color: s.text3),
        ),
        Text(pair.$2, style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
      ],
    );
  }
}
