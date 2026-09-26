import 'package:flutter_test/flutter_test.dart';
import 'package:linguaflow/models/models.dart';
import 'package:linguaflow/services/app_store.dart';
import 'package:linguaflow/services/hotkeys.dart';
import 'package:linguaflow/services/secure_store.dart';

import 'helpers/fake_native_bridge.dart';

/// T-024 · 全局热键：结构化组合键解析、冲突检测、真实重绑与注册报告。
void main() {
  late AppStore store;
  late FakeNativeBridge bridge;
  late HotkeyManager manager;

  setUp(() {
    store = AppStore(secure: InMemorySecureStore());
    store.resetHotkeys(AppStore.kDefaultHotkeys);
    bridge = FakeNativeBridge();
    manager = HotkeyManager(
      store: store,
      platform: HotkeyPlatform.macOS,
      bridge: bridge,
    );
  });

  tearDown(() {
    store.dispose();
  });

  group('T-024 · HotkeyCombo 解析与格式化', () {
    test('解析符号串 / 单词串 / 按住 / 双击', () {
      final a = HotkeyCombo.parse('⌥ Space')!;
      expect(a.modifiers, {HotkeyModifier.alt});
      expect(a.key, 'space');

      final b = HotkeyCombo.parse('Ctrl Alt D')!;
      expect(b.modifiers, {HotkeyModifier.ctrl, HotkeyModifier.alt});
      expect(b.key, 'd');

      final c = HotkeyCombo.parse('按住 Fn')!;
      expect(c.hold, isTrue);
      expect(c.key, 'fn');
      expect(c.modifiers, isEmpty);

      final d = HotkeyCombo.parse('双击 ⌥')!;
      expect(d.doubleTap, isTrue);
      expect(d.key, isNull);
      expect(d.modifiers, {HotkeyModifier.alt});
    });

    test('分平台展示：mac 用符号、Win 用单词', () {
      final combo = HotkeyCombo.parse('Ctrl Alt D')!;
      expect(combo.format(HotkeyPlatform.macOS), contains('⌃'));
      expect(combo.format(HotkeyPlatform.macOS), contains('⌥'));
      expect(combo.format(HotkeyPlatform.windows), 'Ctrl+Alt+D');
    });

    test('wire 串稳定且可往返（原生下发不随展示语言变化）', () {
      final combo = HotkeyCombo.parse('⌥ D')!;
      expect(combo.wire, 'alt+d');
      final rt = HotkeyCombo.fromJson(combo.toJson());
      expect(rt.sameAs(combo), isTrue);
      expect(rt.wire, combo.wire);
    });

    test('sameAs 顺序无关、区分 hold/doubleTap', () {
      final a = HotkeyCombo.parse('Ctrl Alt D')!;
      final b = HotkeyCombo.parse('Alt Ctrl D')!;
      expect(a.sameAs(b), isTrue);
      expect(a.copyWith(hold: true).sameAs(a), isFalse);
      expect(a.copyWith(doubleTap: true).sameAs(a), isFalse);
    });

    test('回车键归一：↩ / Enter / return 等价', () {
      expect(HotkeyCombo.parse('⌥ ↩')!.key, 'enter');
      expect(HotkeyCombo.parse('Alt Enter')!.key, 'enter');
      expect(HotkeyCombo.parse('Alt Return')!.key, 'enter');
    });
  });

  group('T-024 · 冲突检测', () {
    test('系统级占用被识别（⌘ Space → Spotlight）', () async {
      final conflict = await manager.rebind(
        'hk-b',
        HotkeyCombo.parse('⌘ Space')!,
      );
      expect(conflict, isNotNull);
      expect(conflict!.owner, contains('Spotlight'));
      expect(conflict.fatal, isTrue);
      // 冲突写回 item，J 页据此标红
      expect(store.hotkeys.firstWhere((h) => h.id == 'hk-b').conflictWith,
          contains('Spotlight'));
    });

    test('第三方占用为软冲突（⌥ Space → Alfred/Raycast，fatal=false）', () {
      final c = manager.conflictOf('hk-b');
      expect(c, isNotNull);
      expect(c!.owner, contains('Alfred'));
      expect(c.fatal, isFalse);
    });

    test('内部重复：两条热键绑同一组合 → 后者报冲突', () async {
      await manager.rebind('hk-c', HotkeyCombo.parse('⌥ D')!); // 与自身默认同
      await manager.rebind('hk-d', HotkeyCombo.parse('⌥ D')!); // 抢位
      final c = manager.conflictOf('hk-d');
      expect(c, isNotNull);
      expect(c!.owner, contains('本应用'));
      expect(c.fatal, isTrue);
    });

    test('syncConflictsToStore：无冲突项清空 conflictWith', () async {
      manager.syncConflictsToStore();
      final c = await manager.rebind('hk-d', HotkeyCombo.parse('⌥ K')!);
      expect(c, isNull);
      expect(store.hotkeys.firstWhere((h) => h.id == 'hk-d').conflictWith, isNull);
    });
  });

  group('T-024 · 注册与暂停', () {
    test('registerAll 下发全部 wire 串并生成报告', () async {
      final report = await manager.registerAll();
      expect(report.native, isTrue);
      expect(report.total, AppStore.kDefaultHotkeys.length);
      expect(bridge.registered.map((s) => s.id), contains('hk-a'));
      expect(bridge.registered.firstWhere((s) => s.id == 'hk-a').holdToRecord, isTrue);
      expect(bridge.registered.firstWhere((s) => s.id == 'hk-b').trigger, 'alt+space');
    });

    test('paused：注销原生热键且不下发', () async {
      await manager.setPaused(true);
      expect(bridge.unregisterCalls, greaterThanOrEqualTo(1));
      expect(manager.specs(), isEmpty);
      expect(manager.conflictCount, greaterThanOrEqualTo(0));
      await manager.setPaused(false);
      expect(manager.specs().length, AppStore.kDefaultHotkeys.length);
    });

    test('恢复出厂热键', () async {
      await manager.rebind('hk-c', HotkeyCombo.parse('⌘ K')!);
      expect(store.hotkeys.firstWhere((h) => h.id == 'hk-c').macCombo!.key, 'k');
      await manager.resetToDefaults(AppStore.kDefaultHotkeys);
      expect(store.hotkeys.firstWhere((h) => h.id == 'hk-c').macCombo!.key, 'd');
    });
  });
}
