import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/providers/ollama.dart';
import 'package:linguaflow/providers/provider.dart';
import 'package:linguaflow/services/app_store.dart';
import 'package:linguaflow/services/secure_store.dart';

import 'helpers/mock_provider_server.dart';

/// T-023 · 模型配置页三套真连接验证（本地假服务端，真实 HTTP/流式）。
///
/// 每套连接都要跑通完整链路：**测试连接 → 拉取模型 → 成稿一次**：
/// 1. OpenAI 官方（OpenAI 兼容协议）
/// 2. 自定义 BaseURL（OpenAI 兼容，任意第三方中转/私有部署）
/// 3. Ollama 本地（无鉴权 + NDJSON 流式）
///
/// 四类内联错误态全覆盖：401 鉴权失败 / 429 限流 / 404 模型不存在 /
/// BaseURL 填错（networkUnreachable）。
void main() {
  late MockProviderServer server;
  late AppStore store;

  setUpAll(() async {
    server = await MockProviderServer.start();
  });

  tearDownAll(() async {
    await server.close();
  });

  setUp(() {
    store = AppStore(secure: InMemorySecureStore());
  });

  tearDown(() {
    store.dispose();
  });

  /// 收集成稿流，断言与确定性服务端结果一致。
  Future<(String, int)> collect(Stream<String> stream) async {
    final buf = StringBuffer();
    var chunks = 0;
    await for (final c in stream) {
      buf.write(c);
      chunks++;
    }
    return (buf.toString(), chunks);
  }

  group('T-023 · 套路一：OpenAI 官方（OpenAI 兼容协议）', () {
    test('测试连接 → 拉取模型 → 成稿一次 全链跑通', () async {
      // ① 测试连接（真实延迟）
      final conn = await store.testConnection(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(conn.success, isTrue, reason: 'OpenAI 官方套路：测试连接必须成功');
      expect(conn.latencyMs, greaterThanOrEqualTo(0));

      // ② 拉取模型列表（下拉填充）
      final models = await store.fetchModels(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(models, contains(MockProviderServer.modelId));

      // ③ 成稿一次（流式）
      final (text, chunks) = await collect(store.draftTestOnce(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      ));
      expect(text, MockProviderServer.draftOf(AppStore.kDraftTestSentence));
      expect(chunks, greaterThan(1), reason: '成稿必须是流式多段产出');
    });
  });

  group('T-023 · 套路二：自定义 BaseURL（OpenAI 兼容）', () {
    test('测试连接 → 拉取模型 → 成稿一次 全链跑通', () async {
      final conn = await store.testConnection(
        platform: '自定义',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(conn.success, isTrue, reason: '自定义 BaseURL 套路：任意 OpenAI 兼容端点必须可接');

      final models = await store.fetchModels(
        platform: '自定义',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(models, contains(MockProviderServer.modelId));

      final (text, chunks) = await collect(store.draftTestOnce(
        platform: '自定义',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      ));
      expect(text, MockProviderServer.draftOf(AppStore.kDraftTestSentence));
      expect(chunks, greaterThan(1));
    });
  });

  group('T-023 · 套路三：Ollama 本地（无鉴权 + NDJSON 流式）', () {
    test('测试连接 → 拉取模型 → 成稿一次 全链跑通', () async {
      // ① 测试连接（/api/tags，无需 Key）
      final conn = await store.testConnection(
        platform: 'Ollama（本地）',
        baseUrl: server.ollamaBaseUrl,
        model: MockProviderServer.ollamaModelId,
      );
      expect(conn.success, isTrue, reason: '本地 Ollama 无需 Key，连接即成功');

      // ② 拉取模型列表（/api/tags models 数组）
      final models = await store.fetchModels(
        platform: 'Ollama（本地）',
        baseUrl: server.ollamaBaseUrl,
        model: MockProviderServer.ollamaModelId,
      );
      expect(models, contains(MockProviderServer.ollamaModelId));

      // ③ 成稿一次（NDJSON 流式）
      final (text, chunks) = await collect(store.draftTestOnce(
        platform: 'Ollama（本地）',
        baseUrl: server.ollamaBaseUrl,
        model: MockProviderServer.ollamaModelId,
      ));
      expect(text, MockProviderServer.draftOf(AppStore.kDraftTestSentence));
      expect(chunks, greaterThan(1), reason: 'Ollama NDJSON 也必须逐段流式');
    });
  });

  group('T-023 · 四类内联错误态', () {
    test('401：Key 错误 → authInvalid + 原始返回', () async {
      final conn = await store.testConnection(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: 'sk-wrong',
      );
      expect(conn.success, isFalse);
      expect(conn.errorCode, '401');
      expect(conn.errorMessage, contains('Incorrect API key'));

      // 成稿链路同样拦截：抛统一错误码
      await expectLater(
        store.draftTestOnce(
          platform: 'OpenAI',
          baseUrl: server.baseUrl,
          model: MockProviderServer.modelId,
          apiKey: 'sk-wrong',
        ).drain<void>(),
        throwsA(isA<LfProviderException>()
            .having((LfProviderException e) => e.code, 'code', LfErrorCode.authInvalid)
            .having((LfProviderException e) => e.httpStatus, 'httpStatus', 401)),
      );
    });

    test('429：限流 → rateLimited', () async {
      final conn = await store.testConnection(
        platform: '自定义',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.rateLimitedKey,
      );
      expect(conn.success, isFalse);
      expect(conn.errorCode, '429');
      expect(conn.errorMessage, contains('rate_limit_exceeded'));
    });

    test('模型不存在 → 404 model_not_found（三协议各自如实返回）', () async {
      // OpenAI 兼容：/chat/completions 白名单外模型
      await expectLater(
        store.draftTestOnce(
          platform: 'OpenAI',
          baseUrl: server.baseUrl,
          model: 'gpt-no-such-model',
          apiKey: MockProviderServer.validKey,
        ).drain<void>(),
        throwsA(isA<LfProviderException>()
            .having((LfProviderException e) => e.code, 'code', LfErrorCode.modelUnavailable)
            .having((LfProviderException e) => e.httpStatus, 'httpStatus', 404)
            .having((LfProviderException e) => e.detail, 'detail', contains('gpt-no-such-model'))),
      );

      // Ollama：未 pull 的模型 → 404 {"error":"model 'x' not found..."}
      await expectLater(
        store.draftTestOnce(
          platform: 'Ollama（本地）',
          baseUrl: server.ollamaBaseUrl,
          model: 'llama-does-not-exist',
        ).drain<void>(),
        throwsA(isA<LfProviderException>()
            .having((LfProviderException e) => e.code, 'code', LfErrorCode.modelUnavailable)
            .having((LfProviderException e) => e.detail, 'detail', contains('not found'))),
      );
    });

    test('BaseURL 填错 → networkUnreachable（连接拒绝）', () async {
      final conn = await store.testConnection(
        platform: 'OpenAI',
        baseUrl: 'http://127.0.0.1:1/v1', // 端口 1 必然拒绝
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(conn.success, isFalse);
      expect(conn.errorCode, LfErrorCode.networkUnreachable.name);

      await expectLater(
        store.draftTestOnce(
          platform: 'Ollama（本地）',
          baseUrl: 'http://127.0.0.1:1',
          model: MockProviderServer.ollamaModelId,
        ).drain<void>(),
        throwsA(isA<LfProviderException>()
            .having((LfProviderException e) => e.code, 'code', LfErrorCode.networkUnreachable)),
      );
    });
  });

  group('T-023 · 配置落库后的完整解析链（ADR-001）', () {
    test('OpenAI：Key 入 SecureStore，Profile 只留 keyRef，resolveProvider → real 成稿', () async {
      final profile = await store.addProfileWithKey(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
        healthy: true,
        latencyMs: 40,
      );
      expect(profile.keyRef, isNotNull);
      expect(profile.toJson().toString(), isNot(contains(MockProviderServer.validKey)),
          reason: 'ADR-001：Key 明文绝不进 Profile/JSON');
      expect(await store.secure.read(profile.keyRef!), MockProviderServer.validKey);

      final resolved = await store.resolveProvider(profile: profile);
      expect(store.lastProviderSource, ProviderSource.real);
      final (text, _) = await collect(resolved.draft(const DraftRequest(transcript: AppStore.kDraftTestSentence)));
      expect(text, MockProviderServer.draftOf(AppStore.kDraftTestSentence));
      resolved.dispose();
    });

    test('Ollama：无 Key 也算已配置（keyRef 为 null），resolveProvider → real', () async {
      final profile = await store.addProfileWithKey(
        platform: 'Ollama（本地）',
        baseUrl: server.ollamaBaseUrl,
        model: MockProviderServer.ollamaModelId,
        apiKey: null,
        healthy: true,
      );
      expect(profile.keyRef, isNull);
      expect(await store.profileHasKey(profile), isTrue, reason: '本地模型无需 Key 也算有');

      final resolved = await store.resolveProvider(profile: profile);
      expect(store.lastProviderSource, ProviderSource.real);
      final (text, _) = await collect(resolved.draft(const DraftRequest(transcript: AppStore.kDraftTestSentence)));
      expect(text, MockProviderServer.draftOf(AppStore.kDraftTestSentence));
      resolved.dispose();
    });

    test('OllamaProvider 独立实现直连假服务端（Provider 层冒烟）', () async {
      final p = OllamaProvider(model: MockProviderServer.ollamaModelId, baseUrl: server.ollamaBaseUrl);
      final conn = await p.testConnection();
      expect(conn.success, isTrue);
      expect(await p.listModels(), contains(MockProviderServer.ollamaModelId));
      p.dispose();
    });
  });
}
