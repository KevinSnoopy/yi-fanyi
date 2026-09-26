import 'package:linguaflow/services/native_bridge.dart';

/// 测试替身：可断言「原生桥到底被怎么调了」（T-022 / T-024 行为验证）。
class FakeNativeBridge extends NativeBridge {
  FakeNativeBridge({
    this.availableFlag = true,
    this.overlayResult = true,
    this.hotkeyResult = true,
    this.selection,
  });

  final bool availableFlag;
  bool overlayResult;
  bool hotkeyResult;
  String? selection;

  final List<HotkeySpec> registered = <HotkeySpec>[];
  final List<SystemOverlaySpec> overlays = <SystemOverlaySpec>[];
  final List<String> hidden = <String>[];
  final List<String> injected = <String>[];
  final List<String> notifications = <String>[];
  int unregisterCalls = 0;

  @override
  bool get available => availableFlag;

  @override
  Future<bool> registerHotkeys(List<HotkeySpec> specs) async {
    registered
      ..clear()
      ..addAll(specs);
    return hotkeyResult;
  }

  @override
  Future<bool> unregisterHotkeys() async {
    unregisterCalls++;
    registered.clear();
    return true;
  }

  @override
  Future<void> injectText(String text) async {
    injected.add(text);
  }

  @override
  Future<String?> readSelection() async => selection;

  @override
  Future<bool> showOverlay(SystemOverlaySpec spec) async {
    overlays.add(spec);
    return overlayResult;
  }

  @override
  Future<void> hideOverlay(String id) async {
    hidden.add(id);
  }

  @override
  Future<void> notify({required String title, required String body}) async {
    notifications.add('$title｜$body');
  }
}
