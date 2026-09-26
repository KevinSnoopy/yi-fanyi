import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/services/native_bridge.dart';
import 'package:linguaflow/services/system_trigger.dart';

import 'helpers/fake_native_bridge.dart';

/// T-022 · 系统级触发（悬浮窗 / 快捷面板 / 划词浮层 / 通知）双落地验证。
///
/// 断言要点：
/// 1. 原生壳可用 → 走 system 浮层，不占用 in-app pending
/// 2. 原生壳不可用（Web 预览）→ 自动降级 in-app，行为一致
/// 3. 关闭 / 完成 / 选区读取 / 文本注入 / 通知 均落到原生桥
void main() {
  late FakeNativeBridge bridge;
  late SystemTriggerService trigger;

  const req = TriggerRequest(
    id: 'b-float',
    kind: SystemOverlayKind.floatingWindow,
    text: 'hello',
    placeholder: '说点什么…',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    bridge = FakeNativeBridge();
    trigger = SystemTriggerService(
      bridge: bridge,
      channel: const MethodChannel('linguaflow/native'),
    );
  });

  tearDown(() {
    trigger.dispose();
  });

  test('原生可用 → system 模式，spec 完整下发', () async {
    final mode = await trigger.request(req);
    expect(mode, TriggerMode.system);
    expect(trigger.isSystemBacked, isTrue);
    expect(trigger.pending, isNull);
    expect(bridge.overlays.single.id, 'b-float');
    expect(bridge.overlays.single.kind, SystemOverlayKind.floatingWindow);
    expect(bridge.overlays.single.text, 'hello');
    expect(bridge.overlays.single.placeholder, '说点什么…');
  });

  test('原生不可用 → 降级 in-app 浮层（Web 预览可完整走查）', () async {
    bridge.overlayResult = false;
    final mode = await trigger.request(req);
    expect(mode, TriggerMode.inApp);
    expect(trigger.isSystemBacked, isFalse);
    expect(trigger.pending, isNotNull);
    expect(trigger.pending!.id, 'b-float');
  });

  test('close：同时清原生与 in-app，并广播 close 结果', () async {
    bridge.overlayResult = false;
    await trigger.request(req);
    final events = <TriggerResult>[];
    final sub = trigger.results.listen(events.add);

    await trigger.close('b-float');
    await Future<void>.delayed(Duration.zero); // broadcast 事件异步派发
    expect(bridge.hidden, contains('b-float'));
    expect(trigger.pending, isNull);
    expect(events.single.action, 'close');
    expect(events.single.confirmed, isFalse);
    await sub.cancel();
  });

  test('completeInApp：写回动作带文本广播', () async {
    bridge.overlayResult = false;
    await trigger.request(req);
    final events = <TriggerResult>[];
    final sub = trigger.results.listen(events.add);

    trigger.completeInApp('b-float', text: '你好', action: 'submit');
    await Future<void>.delayed(Duration.zero);
    expect(trigger.pending, isNull);
    expect(events.single.text, '你好');
    expect(events.single.action, 'submit');
    expect(events.single.confirmed, isTrue);
    await sub.cancel();
  });

  test('readSelection：C 页优先用原生选区', () async {
    bridge.selection = 'LinguaFlow';
    expect(await trigger.readSelection(), 'LinguaFlow');
    bridge.selection = null;
    expect(await trigger.readSelection(), isNull, reason: '无原生时由页面点选兜底');
  });

  test('injectText / notify：写回与通知均落到原生桥', () async {
    await trigger.injectText('报价已确认');
    await trigger.notify(title: '译语', body: '已替换 1 处');
    expect(bridge.injected, contains('报价已确认'));
    expect(bridge.notifications, contains('译语｜已替换 1 处'));
  });

  test('原生 → Dart 反向事件：overlayResult 解析为结果流', () async {
    final events = <TriggerResult>[];
    final sub = trigger.results.listen(events.add);

    // 模拟原生侧调用 Dart（走与 NativeBridgePlugin 完全相同的通道与协议）
    const codec = StandardMethodCodec();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'linguaflow/native',
      codec.encodeMethodCall(const MethodCall('overlayResult', <String, Object?>{
        'id': 'c-pop',
        'action': 'replace',
        'text': 'quote',
        'confirmed': true,
      })),
      (ByteData? _) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(events.single.id, 'c-pop');
    expect(events.single.action, 'replace');
    expect(events.single.text, 'quote');
    expect(events.single.confirmed, isTrue);
    await sub.cancel();
  });

  test('热键反向事件：down/up 状态透传（流程 A 按住说话）', () async {
    final events = <TriggerResult>[];
    final sub = trigger.results.listen(events.add);

    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Future<void> emit(bool down) =>
        messenger.handlePlatformMessage(
          'linguaflow/native',
          codec.encodeMethodCall(MethodCall('hotkey', <String, Object?>{
            'id': 'hk-a',
            'down': down,
          })),
          (ByteData? _) {},
        );

    await emit(true);
    await emit(false);
    await Future<void>.delayed(Duration.zero);
    expect(events.map((e) => e.confirmed), [true, false]);
    expect(events.every((e) => e.action == 'hotkey'), isTrue);
    await sub.cancel();
  });
}
