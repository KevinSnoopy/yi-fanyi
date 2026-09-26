import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/core/theme/tokens.dart';
import 'package:linguaflow/models/models.dart';
import 'package:linguaflow/services/app_store.dart';
import 'package:linguaflow/services/hotkeys.dart';
import 'package:linguaflow/services/secure_store.dart';
import 'package:linguaflow/services/service_scope.dart';
import 'package:linguaflow/services/system_trigger.dart';
import 'package:linguaflow/ui/pages/flow_page.dart';

import 'helpers/fake_native_bridge.dart';
import 'helpers/mock_provider_server.dart';

/// T-021 / T-022 · 流程 A 端到端（widget 级）：按住说话 → 成稿 → 预览 → 落框。
///
/// 两条分支：
/// 1. 无可用模型 → 演示流式兜底落框（PRD §7 绝不白屏）
/// 2. 真实模型不可用 → 内联错误条 → 一键「用演示流式重试」→ 落框
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
    store = AppStore(secure: InMemorySecureStore());
    for (final p in store.profiles.toList()) {
      store.removeProfile(p.id);
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
    services.dispose();
    store.dispose();
  });

  Widget host() => ServiceScope(
        services: services,
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true)
              .copyWith(extensions: [LfScheme.light()]),
          home: Scaffold(body: FlowPage(store: store, showWindowChrome: false)),
        ),
      );

  Finder mic() => find.byIcon(Icons.mic_rounded);
  Finder stop() => find.byIcon(Icons.stop_rounded);

  /// 按住（down）→ 保持若干帧 → 松开（up）。
  Future<void> hold(WidgetTester tester) async {
    final g = await tester.startGesture(tester.getCenter(mic()));
    // 轻按需等手势竞技场判定（tap 与 long press 互斥）后才回调 onTapDown
    await tester.pump(const Duration(milliseconds: 160));
    await g.up();
    await tester.pump();
  }

  /// 推进到成稿 + 1.2s 预览窗口结束。
  Future<void> settleFlow(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  testWidgets('按住说话 → 成稿 → 落框（演示流式兜底）', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(mic(), findsOneWidget, reason: '底部必须有按住说话按钮');

    // ① 按下 → 录音态（PRD §2.1：按住期间图标变停止键）
    final g = await tester.startGesture(tester.getCenter(mic()));
    await tester.pump(const Duration(milliseconds: 160));
    expect(stop(), findsOneWidget);
    expect(mic(), findsNothing);

    // ② 松手 → 成稿 → 预览 → 1.2s 后自动落框
    await g.up();
    await tester.pump();
    await settleFlow(tester);

    expect(
      find.text(AppStore.kDemoDraftZh),
      findsOneWidget,
      reason: '演示流式必须把成稿写进宿主输入框（PRD §7 绝不白屏）',
    );
    expect(store.history.any((h) => h.flow == 'A'), isTrue);
    expect(mic(), findsOneWidget, reason: '落框后回到待机态，可继续下一轮');
  });

  testWidgets('真实模型不可用 → 错误条 → 一键降级演示流式', (tester) async {
    // 指向不可达地址，模拟「已配置但连不上」（flutter_test 会拦截真实 HTTP）
    await store.addProfileWithKey(
      platform: 'OpenAI',
      baseUrl: 'http://127.0.0.1:1/v1',
      model: MockProviderServer.modelId,
      apiKey: MockProviderServer.validKey,
      healthy: true,
      latencyMs: 60,
      isDefault: true,
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await hold(tester);
    await settleFlow(tester);

    // 真实链路被选中（不是悄悄退回演示）
    expect(store.lastProviderSource, ProviderSource.real);
    // 失败必须内联展示，不能白屏/静默
    expect(find.textContaining('成稿失败'), findsOneWidget);

    // 一键降级 → 演示流式落框
    await tester.tap(find.text('用演示流式重试'));
    await tester.pump();
    await settleFlow(tester);

    expect(find.text(AppStore.kDemoDraftZh), findsOneWidget);
  });
}
