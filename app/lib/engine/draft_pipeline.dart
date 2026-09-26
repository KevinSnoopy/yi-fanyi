import 'dart:async';


import '../providers/mock_provider.dart';
import '../providers/provider.dart';
import 'recorder_state_machine.dart';

/// 成稿流水线 —— 流程 A 的业务编排（PRD v3.2 §2.1）：
///
/// ```
/// STT 转写 ──► 成稿（provider.draft 流式）──► 翻译开关？
///                                              ├─ 关：成稿即终稿
///                                              └─ 开：provider.translate 流式（仅译文 / 双语）
/// ```
///
/// 状态机只管「形」（ADR-008 四态），本类只管「链路」；两者解耦可各自单测。
class DraftPipeline {
  DraftPipeline({required this.sm, required this.stt, required this.provider});

  final RecorderStateMachine sm;
  final SttService stt;
  final TranslationProvider provider;

  CancelToken? _cancel;

  /// 是否正在跑（供 Esc 判断）。
  bool get running => _cancel != null && !_cancel!.isCancelled;

  /// 完整跑一遍：录音结束 → 转写 → 成稿 → (翻译) → 预览。
  /// [onFinal] 在预览确认前收到最终文本（供宿主输入框写入回调）。
  Future<void> run({
    required void Function(String) onFinal,
    String? glossaryJson,
    String? tone,
    bool bilingual = false,
  }) async {
    _cancel?.cancel();
    final cancel = CancelToken();
    _cancel = cancel;

    try {
      sm.beginDrafting();

      // ① 转写（本地 Whisper / 云端 STT；演示环境 MockStt）
      final transcript = await stt.transcribe();
      cancel.throwIfCancelled();

      // ② 成稿（流式；字数上报到状态机「已输出 N 字」）
      final draftBuf = StringBuffer();
      await for (final chunk
          in provider.draft(DraftRequest(transcript: transcript, glossaryJson: glossaryJson, tone: tone), cancelToken: cancel)) {
        draftBuf.write(chunk);
        sm.reportStreamedChars(draftBuf.length);
      }
      final drafted = draftBuf.toString().trim();

      // ③ 翻译开关：关 = 同语言成稿即终稿；开 = 成稿 → 目标语言（可双语）
      String finalText;
      if (sm.translateOn) {
        final transBuf = StringBuffer(drafted.isEmpty ? '' : '');
        final first = StringBuffer();
        await for (final chunk in provider.translate(
          TranslateRequest(
            text: drafted,
            sourceLang: 'Chinese',
            targetLang: 'English',
            glossaryJson: glossaryJson,
          ),
          cancelToken: cancel,
        )) {
          first.write(chunk);
          transBuf.write(chunk);
          sm.reportStreamedChars(first.length);
        }
        finalText = bilingual ? '$drafted\n${first.toString().trim()}' : first.toString().trim();
      } else {
        finalText = drafted;
      }

      // ④ 预览（1.2s 后悔窗口；超时自动写入）
      cancel.throwIfCancelled();
      sm.showPreview(finalText, onTimeout: () => onFinal(finalText));
    } on LfProviderException {
      if (!cancel.isCancelled) rethrow;
    } finally {
      _cancel = null;
    }
  }

  /// Esc 取消 / 焦点变化终止（PRD §4 交互规则 3）。
  void abort() {
    _cancel?.cancel();
    _cancel = null;
    sm.cancel();
  }
}
