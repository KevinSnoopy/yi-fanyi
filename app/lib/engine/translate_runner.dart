import '../models/models.dart';
import '../providers/provider.dart';
import '../services/app_store.dart';

/// 流式翻译执行器 —— 流程 B/C/D 共用（T-022）。
///
/// 与流程 A 的 [DraftPipeline] 分工：
/// - A：转写 → 成稿 →（可选）翻译 → 预览
/// - B/C/D：**已有文本** → 翻译流式 → 写回（无转写、无预览窗口）
///
/// 取消语义对齐 PRD §4 规则 3：静默替换进行中焦点变化 → [abort]。
class TranslateRunner {
  TranslateRunner({required this.store});

  final AppStore store;

  CancelToken? _cancel;

  bool get running => _cancel != null && !_cancel!.isCancelled;

  /// 当前链路来源（真实模型 / 演示流式 —— 与流程 A 一致，UI 明示）。
  ProviderSource get source => store.lastProviderSource;

  /// 跑一次流式翻译；返回完整译文（被取消时返回 null）。
  Future<String?> start({
    required String text,
    required String sourceLang,
    required String targetLang,
    required void Function(String partial) onDelta,
    void Function(LfProviderException error)? onError,
    String? style,
  }) async {
    abort();
    final cancel = CancelToken();
    _cancel = cancel;

    final provider = await store.resolveProvider();
    final buf = StringBuffer();
    try {
      await for (final chunk in provider.translate(
        TranslateRequest(
          text: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
          glossaryJson: store.glossaryJson(),
          style: style,
        ),
        cancelToken: cancel,
      )) {
        buf.write(chunk);
        onDelta(buf.toString());
      }
      final full = buf.toString().trim();
      final src = store.defaultProfile;
      if (full.isNotEmpty && src != null) {
        store.addHistory(
          HistoryRecord(
            id: 'h-${DateTime.now().millisecondsSinceEpoch}',
            time: _nowLabel(),
            dir: '$sourceLang→$targetLang',
            source: text,
            target: full,
            meta: '${full.length} 字',
            flow: 'BCD',
          ),
        );
      }
      return full;
    } on LfProviderException catch (e) {
      if (!cancel.isCancelled) onError?.call(e);
      return null;
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  /// 中止（Esc / 焦点变化 / 关闭浮层）。
  void abort() {
    _cancel?.cancel();
    _cancel = null;
  }

  static String _nowLabel() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
