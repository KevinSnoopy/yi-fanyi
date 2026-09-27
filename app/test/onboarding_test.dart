import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/core/theme/tokens.dart';
import 'package:linguaflow/models/models.dart';
import 'package:linguaflow/services/app_store.dart';
import 'package:linguaflow/services/hotkeys.dart';
import 'package:linguaflow/services/secure_store.dart';
import 'package:linguaflow/services/service_scope.dart';
import 'package:linguaflow/services/system_trigger.dart';
import 'package:linguaflow/ui/pages/onboarding_page.dart';

import 'helpers/fake_native_bridge.dart';
import 'helpers/mock_provider_server.dart';

/// 可控权限状态的测试替身（T-025：自检 / 打开设置 / resume 刷新）。
class _PermBridge extends FakeNativeBridge {
  Map<String, bool> perms = {};
  final List<String> opened = [];

  @override
  Future<Map<String, bool>> permissionStatus() async => perms;

  @override
  Future<void> openPermissionSettings(String kind) async {
    opened.add(kind);
  }
}

/// 解除 flutter_test 的 HTTP 拦截（同 providers_page_test）：换回真实
/// HttpClient，让向导内的 testConnection 直连 MockProviderServer。
class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context) // 走 _HttpClient 真实实现；调 HttpClient() 会递归回本方法
        ..connectionTimeout = const Duration(seconds: 5);
}

/// T-025 · 首次引导三步向导接真实状态（widget 级）：
/// 1. 权限自检接真实 NativeBridge → 打开设置 → 回到应用（resumed）重新自检刷新
/// 2. 零 Key（Ollama 本地）也能完整走完向导
/// 3. 填 Key → 真实 testConnection → addProfileWithKey（Key 进 SecureStore）
void main() {
  late MockProviderServer server;
  late AppStore store;
  late _PermBridge bridge;
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
      store.removeProfile(p.id);
    }
    bridge = _PermBridge();
    final hotkeys = HotkeyManager(
      store: store,
      platform: HotkeyPlatform.macOS,
      bridge: bridge,
    );
    services = LfServices(
      store: store,
      bridge: bridge,
      hotkeys: hotkeys,
      trigger: SystemTriggerService(bridge: bridge),
      toasts: ToastBus(),
      keyListener: HardwareHotkeyListener(manager: hotkeys),
    );
  });

  tearDown(() {
    HttpOverrides.global = null;
    services.dispose();
    store.dispose();
  });

  Future<void> pumpFor(WidgetTester tester, [int ms = 160, int times = 20]) async {
    for (var i = 0; i < times; i++) {
      await tester.pump(Duration(milliseconds: ms));
    }
  }

  Future<void> pumpWizard(WidgetTester tester) async {
    await tester.pumpWidget(
      ServiceScope(
        services: services,
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true).copyWith(extensions: [LfScheme.light()]),
          home: Scaffold(body: OnboardingPage(store: store)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 演示控制条按钮（FlowDemoPage 的 1..N 状态直切）。
  Future<void> gotoStep(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('T-025 · 权限引导接真实状态', () {
    testWidgets('自检待授权 → 打开设置走原生桥 → 授权后 resume 自动刷新 UI', (tester) async {
      bridge.perms = {'accessibility': false, 'inputMonitoring': false, 'microphone': true};
      await pumpWizard(tester);

      // 进权限步（onStateChanged(3) 触发真实自检）
      await gotoStep(tester, '4. 权限引导');
      await tester.pumpAndSettle();

      expect(find.textContaining('· 待授权'), findsNWidgets(2),
          reason: '辅助功能 + 输入监控初始都应是待授权');
      expect(find.textContaining('· 已授权'), findsNothing);

      // 「打开设置」→ 真实调原生桥 openPermissionSettings('accessibility')
      await tester.tap(find.text('打开设置').first);
      await tester.pump();
      expect(bridge.opened, contains('accessibility'));

      // 用户在系统设置里完成授权后回到应用 → lifecycle resumed → 重新自检
      bridge.perms = {'accessibility': true, 'inputMonitoring': false, 'microphone': true};
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.textContaining('· 已授权'), findsOneWidget,
          reason: '辅助功能卡必须刷成已授权（回到应用自动重新自检）');
      expect(find.textContaining('· 待授权'), findsOneWidget,
          reason: '输入监控仍待授权，如实展示');

      // 收尾：推掉 fake toast timer（2.2s 自动消失），再让真实 zone 里
      // runAsync 期间注册的 toast timer 真实 fire 完，避免 pending timers。
      await pumpFor(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2600)));
    });

    testWidgets('「重新检测」手动触发自检；未授权时按钮可再次拉起设置', (tester) async {
      bridge.perms = {};
      await pumpWizard(tester);
      await gotoStep(tester, '4. 权限引导');
      await tester.pumpAndSettle();

      // Web 预览态：原生桥可用但返回空 map → 「未检测」
      expect(find.textContaining('· 未检测'), findsNWidgets(2));

      // 手动重新检测（模拟桌面端自检恢复）
      bridge.perms = {'accessibility': false, 'inputMonitoring': false};
      await tester.tap(find.text('重新检测'));
      await tester.pumpAndSettle();
      expect(find.textContaining('· 待授权'), findsNWidgets(2));

      await tester.tap(find.text('打开设置').first);
      await tester.pump();
      expect(bridge.opened, contains('accessibility'));

      // 收尾：推掉 fake toast timer（2.2s 自动消失），再让真实 zone 里
      // runAsync 期间注册的 toast timer 真实 fire 完，避免 pending timers。
      await pumpFor(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2600)));
    });
  });

  group('T-025 · 零 Key 完成本地模型试用（Ollama 本地）', () {
    testWidgets('选 Ollama → 跳过 Key 检测 → 完成 → onboarded 落状态，全程不落 Profile', (tester) async {
      bridge.perms = {'accessibility': true, 'inputMonitoring': true};
      await pumpWizard(tester);

      // 态 0：选「Ollama 本地」（默认已选中 index 5，点一次确保）
      await tester.tap(find.text('Ollama 本地'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 态 1：本地模型提示卡 + 无 Key 输入行
      expect(find.textContaining('无需 API Key'), findsOneWidget);
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2), reason: 'Ollama 只有 BaseURL / 模型两个输入框，无 Key 行');

      // 不检测直接跳过 → 态 2 热键（真实来自 store.hotkeys）
      await tester.tap(find.text('跳过，直接下一步'));
      await tester.pumpAndSettle();
      expect(find.text('按住说话（流程 A）'), findsOneWidget);
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 态 3 权限：已授权状态卡
      expect(find.textContaining('· 已授权'), findsNWidgets(2));
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      // 态 4：真实结果 —— 未配置 → 演示流式兜底（绝不白屏）
      expect(find.textContaining('演示流式'), findsAtLeastNWidgets(1));

      await tester.tap(find.textContaining('开始使用'));
      await tester.pumpAndSettle();

      expect(store.onboarded, isTrue);
      expect(store.chosenPlatform, 'Ollama 本地');
      expect(store.profiles, isEmpty, reason: '零 Key 路径不应写入任何 Profile');

      // 收尾：推掉 fake toast timer（2.2s 自动消失），再让真实 zone 里
      // runAsync 期间注册的 toast timer 真实 fire 完，避免 pending timers。
      await pumpFor(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2600)));
    });
  });

  group('T-025 · 填 Key 真实保存', () {
    testWidgets('OpenAI + 正确 Key → 测试连接成功 → Profile 落库且 Key 进 SecureStore', (tester) async {
      await pumpWizard(tester);

      // 态 0：选 OpenAI
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 态 1：三个真实输入框（Key / BaseURL / 模型）
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), MockProviderServer.validKey);
      await tester.enterText(fields.at(1), server.baseUrl);
      await tester.enterText(fields.at(2), MockProviderServer.modelId);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('测试连接并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('连接成功'), findsOneWidget);
      expect(find.textContaining('Key 已存入系统密钥串'), findsOneWidget);
      expect(store.profiles.length, 1);
      final p = store.profiles.first;
      expect(p.platform, 'OpenAI');
      expect(p.baseUrl, server.baseUrl);
      expect(p.keyRef, isNotNull);
      expect(await store.secure.read(p.keyRef!), MockProviderServer.validKey,
          reason: 'ADR-001：Key 明文只在 SecureStore');

      // 走完向导
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('开始使用'));
      await tester.pumpAndSettle();

      expect(store.onboarded, isTrue);
      expect(store.chosenPlatform, 'OpenAI');

      // 收尾：推掉 fake toast timer（2.2s 自动消失），再让真实 zone 里
      // runAsync 期间注册的 toast timer 真实 fire 完，避免 pending timers。
      await pumpFor(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2600)));
    });

    testWidgets('Key 填错 → 内联 401 错误，不落库，仍可跳过继续', (tester) async {
      await pumpWizard(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'sk-wrong-key');
      await tester.enterText(fields.at(1), server.baseUrl);
      await tester.enterText(fields.at(2), MockProviderServer.modelId);

      await tester.runAsync(() async {
        // tap 与后续等待同处 runAsync 真实 zone：onTap 内发起的 HTTP 才能真正完成
        await tester.tap(find.text('测试连接并保存'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await pumpFor(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('测试失败 · 401'), findsOneWidget);
      expect(find.textContaining('Incorrect API key'), findsOneWidget);
      expect(store.profiles, isEmpty, reason: '鉴权失败不得静默保存');

      // 跳过仍可继续（如实标注走演示流式）
      await tester.tap(find.text('跳过，先用演示流式'));
      await tester.pumpAndSettle();
      expect(find.text('按住说话（流程 A）'), findsOneWidget);

      // 收尾：推掉 fake toast timer（2.2s 自动消失），再让真实 zone 里
      // runAsync 期间注册的 toast timer 真实 fire 完，避免 pending timers。
      await pumpFor(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2600)));
    });
  });
}
