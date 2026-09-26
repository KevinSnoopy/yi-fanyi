import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/providers/anthropic.dart';
import 'package:linguaflow/providers/openai_compatible.dart';
import 'package:linguaflow/providers/provider.dart';

import 'helpers/mock_provider_server.dart';

/// T-021 · 真实 Provider 联调验证（本地假服务端，走真实 HTTP + SSE）。
///
/// 覆盖：鉴权头、testConnection 成功/401/429、listModels、成稿流式增量拼接、
/// 翻译流式、CancelToken 中断、错误码映射（ADR-007 收敛表）。
void main() {
  late MockProviderServer server;

  setUpAll(() async {
    server = await MockProviderServer.start();
  });

  tearDownAll(() async {
    await server.close();
  });

  TranslationProvider openai({String key = MockProviderServer.validKey}) =>
      OpenAICompatibleProvider.forPlatform(
        'OpenAI',
        apiKey: key,
        model: MockProviderServer.modelId,
        baseUrl: server.baseUrl,
      );

  group('T-021 · OpenAI 兼容 Provider（真实 HTTP/SSE）', () {
    test('testConnection 成功：返回真实延迟', () async {
      final p = openai();
      final r = await p.testConnection();
      expect(r.success, isTrue);
      expect(r.latencyMs, greaterThanOrEqualTo(0));
      p.dispose();
    });

    test('testConnection 401：Key 错误映射到 authInvalid', () async {
      final p = openai(key: 'sk-wrong-key');
      final r = await p.testConnection();
      expect(r.success, isFalse);
      expect(r.errorCode, '401');
      expect(r.errorMessage, contains('Incorrect API key'));
      p.dispose();
    });

    test('testConnection 429：限流被识别', () async {
      final p = openai(key: MockProviderServer.rateLimitedKey);
      final r = await p.testConnection();
      expect(r.success, isFalse);
      expect(r.errorCode, '429');
      p.dispose();
    });

    test('listModels：真实拉取模型列表', () async {
      final p = openai();
      final models = await p.listModels();
      expect(models, contains(MockProviderServer.modelId));
      p.dispose();
    });

    test('draft 流式：增量拼接等于完整成稿', () async {
      final p = openai();
      const input = '呃…那个报价我确认没问题啊';
      final buf = StringBuffer();
      var chunkCount = 0;
      await for (final chunk in p.draft(const DraftRequest(transcript: input))) {
        expect(chunk, isNotEmpty);
        chunkCount++;
        buf.write(chunk);
      }
      expect(chunkCount, greaterThan(1), reason: '必须是多段流式，不能一次吐完');
      expect(buf.toString(), MockProviderServer.draftOf(input));
      p.dispose();
    });

    test('translate 流式 + 术语表注入', () async {
      final p = openai();
      final buf = StringBuffer();
      await for (final chunk in p.translate(
        const TranslateRequest(
          text: '报价',
          sourceLang: 'Chinese',
          targetLang: 'English',
          glossaryJson: '报价 => quote',
        ),
      )) {
        buf.write(chunk);
      }
      expect(buf.toString(), isNotEmpty);
      p.dispose();
    });

    test('CancelToken 中断：抛 streamAborted 且立即停止产出', () async {
      final p = openai();
      final cancel = CancelToken();
      var chunks = 0;
      var caught = false;
      try {
        await for (final _ in p.draft(
          const DraftRequest(transcript: '这是一段足够长的输入用于触发多段流式输出以便中途取消'),
          cancelToken: cancel,
        )) {
          chunks++;
          if (chunks == 1) cancel.cancel();
        }
      } on LfProviderException catch (e) {
        caught = true;
        expect(e.code, LfErrorCode.streamAborted,
            reason: '取消必须走 ADR-007 收敛错误码，上层据此静默处理');
      }
      expect(caught, isTrue);
      expect(chunks, lessThan(20), reason: '取消后不应继续吐流');
      p.dispose();
    });

    test('网络不可达 → networkUnreachable', () async {
      final p = OpenAICompatibleProvider.forPlatform(
        'OpenAI',
        apiKey: MockProviderServer.validKey,
        model: 'm',
        baseUrl: 'http://127.0.0.1:1/v1', // 必然拒绝连接
      );
      final r = await p.testConnection();
      expect(r.success, isFalse);
      expect(r.errorCode, LfErrorCode.networkUnreachable.name);
      p.dispose();
    });
  });

  group('T-021 · Anthropic Provider（真实 HTTP/SSE）', () {
    test('draft 流式：解析 content_block_delta', () async {
      final p = AnthropicProvider(
        apiKey: MockProviderServer.validKey,
        model: 'claude-mock',
        baseUrl: server.baseUrl,
      );
      const input = '呃…那个报价我确认没问题啊';
      final buf = StringBuffer();
      await for (final chunk in p.draft(const DraftRequest(transcript: input))) {
        buf.write(chunk);
      }
      expect(buf.toString(), MockProviderServer.draftOf(input));
      p.dispose();
    });

    test('testConnection：走 messages 最小调用', () async {
      final p = AnthropicProvider(
        apiKey: MockProviderServer.validKey,
        model: 'claude-mock',
        baseUrl: server.baseUrl,
      );
      final r = await p.testConnection();
      expect(r.success, isTrue);
      p.dispose();
    });
  });
}
