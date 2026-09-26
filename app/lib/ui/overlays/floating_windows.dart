import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../components/common.dart';
import 'recorder_pill.dart' show BlinkCursor, LfSpinner;

/// 浮层入场动画包装 —— 淡入 + 上移 8px（≤180ms，PRD §4 规则 4；对应原型
/// .mini-window-enter / .rise-in）。
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: LfDimens.tBase + delay,
      curve: LfDimens.ease,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ==================================================================
// 流程 B · 迷你悬浮窗（380 × 自适应，四态：空/加载/流式/完成）
// ==================================================================
class MiniFloatingWindow extends StatelessWidget {
  const MiniFloatingWindow({
    super.key,
    required this.state, // 0 触发 / 1 加载 / 2 流式 / 3 完成
    required this.source,
    required this.streamedText,
    this.pair = ('中文', 'English'),
    this.modelLabel = 'Ollama · qwen2.5:7b · 0ms',
    this.latencyLabel,
    this.onCopy,
    this.onInject,
    this.onClose,
  });

  final int state;
  final String source;
  final String streamedText;
  final (String, String) pair;
  final String modelLabel;
  final String? latencyLabel;
  final VoidCallback? onCopy;
  final VoidCallback? onInject;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        width: LfDimens.popoverW,
        constraints: const BoxConstraints(maxHeight: 480),
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
            // 头部：语言方向 + 模型
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  _LangPair(pair),
                  const Spacer(),
                  Text(
                    modelLabel,
                    style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClose,
                    child: LfIcons.icon('x', size: 12, color: s.text3),
                  ),
                ],
              ),
            ),
            // 原文区（浅灰底可折叠）
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.bgSource,
                borderRadius: BorderRadius.circular(LfDimens.rInput),
              ),
              child: Text(
                source,
                style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2, height: 1.55),
              ),
            ),
            // 译文流式区（白底 + 顶部 2px 进度条）
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.bgWindow,
                borderRadius: BorderRadius.circular(LfDimens.rInput),
                border: Border.all(color: s.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state == 2)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: s.brandGrad,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  _buildTarget(s),
                ],
              ),
            ),
            // 底部动作
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 12, 10),
              child: Row(
                children: [
                  _MiniAction(icon: 'copy', label: '复制', onTap: onCopy),
                  const SizedBox(width: 6),
                  _MiniAction(icon: 'inject', label: '注入', onTap: onInject),
                  const SizedBox(width: 6),
                  _MiniAction(icon: 'check', label: '完成', onTap: onClose, primary: true),
                  const Spacer(),
                  Text(
                    state == 3 ? (latencyLabel ?? '178ms · 0 ¥') : '…',
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
    if (state == 0) {
      return Text('…', style: TextStyle(fontSize: LfDimens.fsMd, color: s.text3));
    }
    if (state == 1) {
      return Row(
        children: [
          const LfSpinner(size: 12),
          const SizedBox(width: 6),
          Text('翻译中…', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
        ],
      );
    }
    if (state == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              streamedText,
              style: TextStyle(fontSize: LfDimens.fsMd, color: s.text, height: 1.5),
            ),
          ),
          const BlinkCursor(),
        ],
      );
    }
    return Text(
      streamedText,
      style: TextStyle(fontSize: LfDimens.fsMd, color: s.text, height: 1.5),
    );
  }
}

class _LangPair extends StatelessWidget {
  const _LangPair(this.pair);

  final (String, String) pair;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          pair.$1,
          style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(Icons.arrow_forward_rounded, size: 12, color: s.text3),
        ),
        Text(
          pair.$2,
          style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.label, this.onTap, this.primary = false});

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: primary ? s.brand : s.bgWindow,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: primary ? s.brand : s.dividerStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LfIcons.icon(icon, size: 11, color: primary ? Colors.white : s.text2),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: LfDimens.fsXs,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : s.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// 流程 C · 划词翻译小窗（320 宽：EN→ZH + 原文/译文 + 复制/替换）
// ==================================================================
class SelectionPopover extends StatelessWidget {
  const SelectionPopover({
    super.key,
    required this.word,
    required this.translated,
    this.translating = false,
    this.pair = 'EN → ZH',
    this.latency,
    this.onCopy,
    this.onReplace,
  });

  final String word;
  final String translated;
  final bool translating;
  final String pair;
  final String? latency;
  final VoidCallback? onCopy;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        width: LfDimens.selectionWinW,
        padding: const EdgeInsets.all(12),
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
            Row(
              children: [
                Text(
                  pair,
                  style: TextStyle(
                    fontSize: LfDimens.fsXs,
                    fontWeight: FontWeight.w700,
                    color: s.brand,
                  ),
                ),
                const Spacer(),
                Text(
                  translating ? '…' : (latency ?? '68ms'),
                  style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              word,
              style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              translating ? translated : translated,
              style: TextStyle(
                fontSize: LfDimens.fsMd,
                fontWeight: FontWeight.w600,
                color: s.text,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniAction(icon: 'copy', label: '复制', onTap: onCopy),
                const SizedBox(width: 6),
                _MiniAction(icon: 'swap', label: '替换', onTap: onReplace, primary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 划词「译」水印浮标（选区旁）。
class SelectionMarker extends StatelessWidget {
  const SelectionMarker({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: s.brandGrad,
            borderRadius: BorderRadius.circular(7),
            boxShadow: s.shadowBrand,
          ),
          child: const Center(
            child: Text(
              '译',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// 流程 D · 静默替换状态条（底部居中：进度 + 字数 + 可取消）
// ==================================================================
class SilentBar extends StatelessWidget {
  const SilentBar({
    super.key,
    required this.processed,
    required this.total,
    this.done = false,
    this.onUndo,
  });

  final int processed;
  final int total;
  final bool done;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: s.bgBar,
          borderRadius: BorderRadius.circular(LfDimens.rPill),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowBar,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!done) ...[
              const LfSpinner(size: 12),
              const SizedBox(width: 8),
              Text(
                '静默翻译中 · 已处理 ',
                style: TextStyle(fontSize: LfDimens.fsSm, color: s.text),
              ),
              Text(
                '$processed',
                style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: s.brand),
              ),
              Text(' / $total 字', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text)),
            ] else ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: s.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '✓ 已替换（1.2s 内静默写入）',
                style: TextStyle(fontSize: LfDimens.fsSm, color: s.text),
              ),
              const SizedBox(width: 10),
              _MiniAction(icon: 'rotate', label: '撤回', onTap: onUndo),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// 流程 E · 截图 OCR 双栏结果窗
// ==================================================================
class OcrResultWindow extends StatelessWidget {
  const OcrResultWindow({
    super.key,
    required this.source,
    required this.target,
    this.scanning = false,
    this.onCopySource,
    this.onCopyTarget,
    this.onInject,
    this.onDone,
  });

  final String source;
  final String target;
  final bool scanning;
  final VoidCallback? onCopySource;
  final VoidCallback? onCopyTarget;
  final VoidCallback? onInject;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.bgBar,
          borderRadius: BorderRadius.circular(LfDimens.rPopover),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowPopover,
        ),
        child: scanning
            ? Row(
                children: [
                  const LfSpinner(size: 12),
                  const SizedBox(width: 8),
                  Text('识别中…', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
                  const Spacer(),
                  Text('Mistral OCR · 1.2s', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _OcrColumn(
                          label: '原文',
                          body: source,
                          onCopy: onCopySource,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OcrColumn(
                          label: '译文 · 中文',
                          body: target,
                          target: true,
                          onCopy: onCopyTarget,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LfButton(label: ' 注入', icon: 'inject', kind: LfButtonKind.ghost, full: true, onPressed: onInject),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LfButton(label: ' 完成', icon: 'check', kind: LfButtonKind.primary, full: true, onPressed: onDone),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _OcrColumn extends StatelessWidget {
  const _OcrColumn({required this.label, required this.body, required this.onCopy, this.target = false});

  final String label;
  final String body;
  final VoidCallback? onCopy;
  final bool target;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: LfDimens.fsXs,
                fontWeight: FontWeight.w700,
                color: target ? s.brand : s.text2,
              ),
            ),
            const Spacer(),
            _MiniAction(icon: 'copy', label: '复制', onTap: onCopy),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: target ? s.bgWindow : s.bgSource,
            borderRadius: BorderRadius.circular(LfDimens.rInput),
            border: Border.all(color: s.divider),
          ),
          child: Text(
            body,
            style: TextStyle(
              fontSize: target ? LfDimens.fsMd : LfDimens.fsSm,
              height: 1.6,
              color: s.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// OCR 框选遮罩（暗色 mask + 高亮框 + 尺寸标注）。
class OcrSelectionMask extends StatelessWidget {
  const OcrSelectionMask({super.key, this.rect, this.sizeLabel = '536 × 168'});

  final Rect? rect;
  final String sizeLabel;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.28),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 420,
            height: 130,
            decoration: BoxDecoration(
              border: Border.all(color: s.brand, width: 1.6),
              borderRadius: BorderRadius.circular(4),
              color: s.brand.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: s.brand,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sizeLabel,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// 流程 F · 锁屏层（主窗 / 移动端共用：FaceID 扫描 + 密码回退）
// ==================================================================
class LockScreen extends StatelessWidget {
  const LockScreen({
    super.key,
    this.compact = false,
    this.scanning = true,
    this.onUnlock,
    this.onPassword,
  });

  final bool compact; // 移动端窄卡
  final bool scanning;
  final VoidCallback? onUnlock;
  final VoidCallback? onPassword;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      color: s.bgWindow.withValues(alpha: 0.86),
      alignment: Alignment.center,
      child: Container(
        width: compact ? 280 : 340,
        padding: EdgeInsets.all(compact ? 22 : 28),
        decoration: BoxDecoration(
          color: s.bgBar,
          borderRadius: BorderRadius.circular(LfDimens.rPopover),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowWindow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: s.brandGrad,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: LfIcons.icon('shieldCheck', size: 22, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(
              '译语',
              style: TextStyle(
                fontSize: LfDimens.fsMd,
                fontWeight: FontWeight.w700,
                color: s.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              compact ? '已锁定' : '主窗口已锁定',
              style: TextStyle(fontSize: LfDimens.fsLg, fontWeight: FontWeight.w700, color: s.text),
            ),
            const SizedBox(height: 4),
            Text(
              '历史 / 配置 / 术语表已隐藏',
              style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: s.bgWindow,
                borderRadius: BorderRadius.circular(LfDimens.rCard),
                border: Border.all(color: s.divider),
              ),
              child: Row(
                children: [
                  FaceScanIcon(scanning: scanning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FaceID 解锁',
                          style: TextStyle(
                            fontSize: LfDimens.fsSm,
                            fontWeight: FontWeight.w600,
                            color: s.text,
                          ),
                        ),
                        Text(
                          scanning ? '正在扫描…' : '验证通过',
                          style: TextStyle(
                            fontSize: LfDimens.fsXs,
                            color: scanning ? s.text2 : s.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PulsingDot(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onPassword,
              child: Text(
                '或输入密码',
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FaceID 扫描图标（弧线动画感）。
class FaceScanIcon extends StatelessWidget {
  const FaceScanIcon({super.key, required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: s.brandSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: LfIcons.icon('smile', size: 18, color: s.brand),
      ),
    );
  }
}

/// 呼吸圆点。
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.color});

  final Color? color;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color ?? s.brand, shape: BoxShape.circle),
      ),
    );
  }
}

// ==================================================================
// Toast / 提示条（showHint 对应物；顶部居中胶囊）
// ==================================================================
class Toast extends StatelessWidget {
  const Toast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: s.text.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(LfDimens.rPill),
        boxShadow: s.shadowMd,
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: LfDimens.fsSm, color: Colors.white, height: 1.4),
      ),
    );
  }
}
