import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/core/theme/tokens.dart';
import 'package:linguaflow/models/models.dart';
import 'package:linguaflow/providers/catalog.dart';
import 'package:linguaflow/services/app_store.dart';
import 'package:linguaflow/services/hotkeys.dart';
import 'package:linguaflow/services/secure_store.dart';
import 'package:linguaflow/services/service_scope.dart';
import 'package:linguaflow/services/system_trigger.dart';
import 'package:linguaflow/ui/pages/settings_pages.dart';

import 'helpers/fake_native_bridge.dart';
import 'helpers/mock_provider_server.dart';

/// 解除 flutter_test 的 HTTP 拦截（TestWidgetsFlutterBinding 会把所有请求
/// 打成空 400）：换回真实 HttpClient，直连本套件起的 MockProviderServer。
class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context) // 走 _HttpClient 真实实现；调 HttpClient() 会递归回本方法
        ..connectionTimeout = const Duration(seconds: 5);
}

/// T-023 · 模型配置页（I）三套真连接 widget 级验证：
/// 填表 → 测试连接并保存 → 成稿试一句；错误态内联展示。
void main() {
  late MockProviderServer server;
  late AppStore store;
  late LfServices services;

  setUpAll(() async {
    server = await MockProviderServer.start();
  });

  tearDownAll(() async {
    await server.close();
  });

  setUp(() {
    // 晚于 binding 初始化覆盖，保证 widget 测试内的 HTTP 走真实 localhost。
    HttpOverrides.global = _RealHttpOverrides();
    store = AppStore(secure: InMemorySecureStore());
    for (final p in store.profiles.toList()) {
      store.removeProfile(p.id); // 清掉种子数据，从空态开始走「新增」
    }
    final hotkeys = HotkeyManager(
      store: store,
      platform: HotkeyPlatform.macOS,
      bridge: FakeNativeBridge(),
    );
    services = LfServices(
      store: store,
      bridge: FakeNativeBridge(),
      hotkeys: hotkeys,
      trigger: SystemTriggerService(bridge: FakeNativeBridge()),
      toasts: ToastBus(),
      keyListener: HardwareHotkeyListener(manager: hotkeys),
    );
  });

  tearDown(() {
    HttpOverrides.global = null;
    services.dispose();
    store.dispose();
  });

  /// 推进若干帧（流式过程持续有帧，不能用 pumpAndSettle——spinner 永不停止）。
  /// 总时长 ≥3s，顺带把 toast 的 2.2s 自动消失 timer 推完，避免 pending timers。
  Future<void> pumpFor(WidgetTester tester, [int ms = 160, int times = 20]) async {
    for (var i = 0; i < times; i++) {
      await tester.pump(Duration(milliseconds: ms));
    }
  }


  /// 大视口承载：默认 800×600 逻辑视口装不下整张表单，
  /// 「测试连接并保存」等按钮会落在屏幕外导致 tap 不命中。
  Future<void> pumpHost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(store: store, services: services));
    await tester.pumpAndSettle();
  }

  group('T-023 · 套路一 OpenAI 官方（填 Key → 测试连接 → 拉取模型 → 成稿一次）', () {
    testWidgets('空态 → 添加 → 填表 → 测试连接并保存 → 列表出现 → 成稿试一句成功', (tester) async {
      await pumpHost(tester);

      // 空态 → 添加 Provider
      expect(find.text('还没有配置任何模型'), findsOneWidget);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      // 表单：默认选中 OpenAI（目录第 0 项）
      expect(kPlatformCatalog[0].name, 'OpenAI');
      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(3), reason: 'BaseURL / API Key / 模型三个输入框');

      // 填 BaseURL / Key / 模型（mock 服务端白名单模型）
      await tester.enterText(fields.at(0), server.baseUrl);
      await tester.enterText(fields.at(1), MockProviderServer.validKey);
      await tester.enterText(fields.at(2), MockProviderServer.modelId);

      // 测试连接并保存 → 成功 → 回列表
      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('测试连接并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);
      await tester.pumpAndSettle();

      expect(store.profiles.length, 1, reason: '测试成功后必须落库 Profile');
      expect(store.profiles.first.platform, 'OpenAI');
      expect(store.profiles.first.baseUrl, server.baseUrl);
      expect(store.profiles.first.healthy, isTrue);
      expect(store.profiles.first.keyRef, isNotNull);
      expect(await store.secure.read(store.profiles.first.keyRef!), MockProviderServer.validKey);

      // 列表出现当前默认卡 + 成稿试一句按钮
      expect(find.textContaining('已添加的 Provider'), findsOneWidget);
      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('▶ 成稿试一句（真实链路）'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);

      // 流式成稿结果进面板（确定性服务端输出）
      expect(
        find.textContaining(MockProviderServer.draftOf(AppStore.kDraftTestSentence)),
        findsOneWidget,
        reason: '成稿试一句的流式输出必须展示在面板里',
      );
      expect(find.textContaining('成稿完成'), findsOneWidget);
    });

    testWidgets('401：Key 填错 → 测试失败内联展示，不落库', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), server.baseUrl);
      await tester.enterText(fields.at(1), 'sk-definitely-wrong');
      await tester.enterText(fields.at(2), MockProviderServer.modelId);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('测试连接并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);
      await tester.pumpAndSettle();

      // 内联错误条：错误码 + 模型方原始返回
      expect(find.textContaining('测试失败 · 401'), findsOneWidget);
      expect(find.textContaining('Incorrect API key'), findsOneWidget);
      expect(store.profiles, isEmpty, reason: '鉴权失败不得静默落库');

      // 「跳过测试，直接保存」仍在（用户自主选择，healthy=false 标记未验证）
      expect(find.text('跳过测试，直接保存（标记为未验证）'), findsOneWidget);
    });

    testWidgets('429：限流 Key → 测试失败内联展示 429', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), server.baseUrl);
      await tester.enterText(fields.at(1), MockProviderServer.rateLimitedKey);
      await tester.enterText(fields.at(2), MockProviderServer.modelId);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('测试连接并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('测试失败 · 429'), findsOneWidget);
    });

    testWidgets('模型不存在 → 成稿试一句内联报 404 model_not_found', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), server.baseUrl);
      await tester.enterText(fields.at(1), MockProviderServer.validKey);
      await tester.enterText(fields.at(2), 'gpt-not-exist');

      // 不先测试连接，直接成稿试一句（模型名不存在要如实报错）
      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('▶ 成稿试一句'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);

      expect(find.textContaining('成稿失败'), findsOneWidget);
      expect(find.textContaining('modelUnavailable'), findsOneWidget,
          reason: '错误码必须收敛为 ADR-007 统一码（modelUnavailable）');
      expect(find.textContaining("'gpt-not-exist'"), findsOneWidget,
          reason: '错误条回显服务端 raw message（带引号区分输入框中的模型名）');
    });
  });

  group('T-023 · 套路三 Ollama 本地（无 Key 全链）', () {
    testWidgets('选 Ollama → 填本地 BaseURL → 测试连接并保存 → 成稿试一句成功', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      // 切到 Ollama 平台卡
      await tester.tap(find.text('Ollama'));
      await tester.pumpAndSettle();

      // Ollama 无 Key 行（「API Key」表单隐藏）
      expect(find.text('API Key'), findsNothing, reason: 'Ollama 本地无需 Key，表单应隐藏 Key 行');

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), server.ollamaBaseUrl);
      await tester.enterText(fields.at(1), MockProviderServer.ollamaModelId);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('测试连接并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);
      await tester.pumpAndSettle();

      expect(store.profiles.length, 1);
      expect(store.profiles.first.platform, 'Ollama（本地）');
      expect(store.profiles.first.keyRef, isNull, reason: '本地模型不写 Key');

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('▶ 成稿试一句（真实链路）'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);

      expect(
        find.textContaining(MockProviderServer.draftOf(AppStore.kDraftTestSentence)),
        findsOneWidget,
      );
    });
  });

  group('T-023 · 拉取模型列表（下拉填充）', () {
    testWidgets('拉取模型列表 → 白名单模型 chip 出现并可选中', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), server.baseUrl);
      await tester.enterText(fields.at(1), MockProviderServer.validKey);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.textContaining('拉取模型列表'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);

      expect(find.text(MockProviderServer.modelId), findsOneWidget,
          reason: '拉取到的模型以 chip 展示');

      // 点 chip → 回填模型输入框
      await tester.tap(find.text(MockProviderServer.modelId));
      await tester.pumpAndSettle();
      final modelCtl = tester.widget<TextField>(fields.at(2)).controller!.text;
      expect(modelCtl, MockProviderServer.modelId);
    });

    testWidgets('BaseURL 填错 → 拉取模型内联报 networkUnreachable', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.textContaining('添加 Provider'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'http://127.0.0.1:1/v1');
      await tester.enterText(fields.at(1), MockProviderServer.validKey);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.textContaining('拉取模型列表'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);

      expect(find.textContaining('拉取失败'), findsOneWidget);
      expect(find.textContaining('networkUnreachable'), findsOneWidget);
    });
  });
}

Widget _host({required AppStore store, required LfServices services}) => ServiceScope(
      services: services,
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true).copyWith(extensions: [LfScheme.light()]),
        home: Scaffold(body: ProvidersPage(store: store)),
      ),
    );
