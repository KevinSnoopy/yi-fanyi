import 'dart:async';

import 'provider.dart';

/// 演示 / 零配置兜底 Provider（PRD §7：未配置任何模型时绝不白屏，
/// 默认引导「本地模型一键体验」；Web 预览环境无真实网络时使用）。
///
/// 行为：按字符节拍流式输出预置文本，还原真实 LLM 打字手感；
/// 支持可注入文本与节拍，便于 widget 测试与演示脚本控制。
class MockProvider implements TranslationProvider {
  MockProvider({
    this.translateText =
        'Confirmed, no problem with the quote. We can sign the contract before next Wednesday.',
    this.draftText = '那个报价我确认没问题，下周三之前可以把合同签了。',
    this.tick = const Duration(milliseconds: 28),
    this.chunkSize = 2,
  });

  final String translateText;
  final String draftText;
  final Duration tick;
  final int chunkSize;

  @override
  final String name = '演示模型（Mock）';
  @override
  final String defaultBaseUrl = 'local://mock';

  Stream<String> _emit(String text, CancelToken? cancelToken) async* {
    await Future<void>.delayed(const Duration(milliseconds: 350)); // 首 token 延迟
    for (var i = 0; i < text.length; i += chunkSize) {
      cancelToken?.throwIfCancelled();
      final end = (i + chunkSize).clamp(0, text.length);
      yield text.substring(i, end);
      await Future<void>.delayed(tick);
    }
  }

  @override
  Stream<String> translate(TranslateRequest req, {CancelToken? cancelToken}) =>
      _emit(translateText, cancelToken);

  @override
  Stream<String> draft(DraftRequest req, {CancelToken? cancelToken}) =>
      _emit(draftText, cancelToken);

  @override
  Future<List<String>> listModels() async => ['mock-qwen-2.5', 'mock-whisper-large'];

  @override
  Future<ConnectionTestResult> testConnection() async =>
      const ConnectionTestResult(success: true, latencyMs: 3);

  @override
  void dispose() {}
}

/// Mock STT —— 转写引擎挂点（PRD §3 P1：本地 Whisper / 云端 STT 接口预留）。
abstract class SttService {
  String get name;
  Future<String> transcribe();
}

class MockStt implements SttService {
  @override
  final String name = '本地 Whisper（演示）';

  /// 口语原话（含口头禅）—— 成稿引擎负责清理为书面语。
  @override
  Future<String> transcribe() async =>
      '呃…那个报价我确认没问题啊，就下周三之前吧，咱们把合同签了。';
}
