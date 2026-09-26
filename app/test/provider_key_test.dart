import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/models/models.dart';
import 'package:linguaflow/providers/mock_provider.dart';
import 'package:linguaflow/services/app_store.dart';
import 'package:linguaflow/services/secure_store.dart';

import 'helpers/mock_provider_server.dart';

/// T-021 · Key 安全边界（ADR-001）与真实 Provider 解析链（PRD §7 绝不白屏）。
///
/// 断言要点：
/// 1. 明文 Key 只进 SecureStore，Profile 与持久化 JSON 里只有 keyRef
/// 2. Key 缺失 / 从未验证成功 → 降级演示流式，绝不白屏
/// 3. Key 齐全且已验证 → 解析出真实 Provider 实例
void main() {
  late MockProviderServer server;
  late InMemorySecureStore secure;
  late AppStore store;

  const secret = 'sk-super-secret-key';

  setUpAll(() async {
    server = await MockProviderServer.start();
  });

  tearDownAll(() async {
    await server.close();
  });

  setUp(() {
    secure = InMemorySecureStore();
    store = AppStore(secure: secure);
    // 清掉出厂种子数据，保证每条用例从确定状态出发
    for (final p in store.profiles.toList()) {
      store.removeProfile(p.id);
    }
    expect(store.profiles, isEmpty);
  });

  tearDown(() {
    store.dispose();
  });

  group('T-021 · Key 生命周期（ADR-001）', () {
    test('addProfileWithKey：Key 入 SecureStore，Profile 只留 keyRef', () async {
      final p = await store.addProfileWithKey(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: secret,
        healthy: true,
        latencyMs: 120,
        isDefault: true,
      );

      expect(p.keyRef, isNotNull);
      expect(p.keyRef, keyRefFor(p.id) as Object?);
      // 真身只在安全存储里
      expect(await secure.read(p.keyRef!), secret);
      // Profile 本体与序列化结果都不含明文
      final json = p.toJson();
      expect(json.toString(), isNot(contains(secret)));
      expect(json['keyRef'], p.keyRef);
      // store 能取回真实 Key
      expect(await store.profileHasKey(p), isTrue);
    });

    test('removeProfileWithKey：删 Profile 连带删 Key（不留残留凭证）', () async {
      final p = await store.addProfileWithKey(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: 'm',
        apiKey: secret,
        healthy: true,
      );
      final ref = p.keyRef!;
      await store.removeProfileWithKey(p.id);
      expect(store.profiles.any((e) => e.id == p.id), isFalse);
      expect(await secure.has(ref), isFalse);
    });

    test('updateProfileKey：换 Key 后旧引用内容被覆盖', () async {
      final p = await store.addProfileWithKey(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: 'm',
        apiKey: secret,
        healthy: true,
      );
      store.invalidateProvider(p.id);
      await store.updateProfileKey(p.id, 'sk-rotated');
      expect(await secure.read(p.keyRef!), 'sk-rotated');
    });

    test('Ollama 本地模型：无需 Key 也算有', () async {
      final p = await store.addProfileWithKey(
        platform: 'Ollama',
        baseUrl: 'http://127.0.0.1:11434',
        model: 'qwen2.5',
        healthy: true,
      );
      expect(p.keyRef, isNull);
      expect(await store.profileHasKey(p), isTrue);
      expect(store.platformNeedsKey('Ollama'), isFalse);
    });
  });

  group('T-021 · resolveProvider 降级链（PRD §7）', () {
    test('无 Profile → 演示流式', () async {
      final p = await store.resolveProvider();
      expect(store.lastProviderSource, ProviderSource.mock);
      expect(p, isA<MockProvider>());
    });

    test('有 Profile 但 Key 未入库 → 演示流式', () async {
      store.addProfile(
        ProviderProfile(
          id: 'p-nokey',
          platform: 'OpenAI',
          baseUrl: server.baseUrl,
          model: 'm',
          keyRef: 'ref-missing',
          isDefault: true,
          healthy: true,
        ),
      );
      expect(await store.resolveProvider(), isA<MockProvider>());
      expect(store.lastProviderSource, ProviderSource.mock);
    });

    test('Key 齐全且已验证 → 真实 Provider', () async {
      await store.addProfileWithKey(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
        healthy: true,
        latencyMs: 80,
        isDefault: true,
      );
      final p = await store.resolveProvider();
      expect(store.lastProviderSource, ProviderSource.real);
      expect(p, isNot(isA<MockProvider>()));
      // 缓存命中：同一实例，避免 http.Client 泄漏
      expect(await store.resolveProvider(), same(p));
    });

    test('从未验证成功（healthy=false 且无延迟）→ 演示流式', () async {
      await store.addProfileWithKey(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: 'm',
        apiKey: MockProviderServer.validKey,
        healthy: false,
        isDefault: true,
      );
      expect(await store.resolveProvider(), isA<MockProvider>());
    });
  });

  group('T-021 · 真实连接测试与模型拉取', () {
    test('testConnection 成功', () async {
      final r = await store.testConnection(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(r.success, isTrue);
      expect(r.latencyMs, greaterThanOrEqualTo(0));
    });

    test('testConnection 401：错误码直通 I 页', () async {
      final r = await store.testConnection(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: 'sk-bad',
      );
      expect(r.success, isFalse);
      expect(r.errorCode, '401');
    });

    test('fetchModels：模型列表可用于 I 页下拉', () async {
      final models = await store.fetchModels(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: MockProviderServer.validKey,
      );
      expect(models, contains(MockProviderServer.modelId));
    });

    test('testConnection 不会把 Key 落库（纯探测）', () async {
      await store.testConnection(
        platform: 'OpenAI',
        baseUrl: server.baseUrl,
        model: MockProviderServer.modelId,
        apiKey: 'sk-probe-only',
      );
      expect(store.profiles, isEmpty);
      expect(await secure.has(keyRefFor('probe')), isFalse);
    });
  });
}
