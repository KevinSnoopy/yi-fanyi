import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_store.dart';
import 'hotkeys.dart';
import 'native_bridge.dart';
import 'system_trigger.dart';

/// 运行期服务集合 —— T-022 / T-024 的非 UI 单例，在 `main()` 里装配一次。
class LfServices {
  LfServices({
    required this.store,
    required this.bridge,
    required this.hotkeys,
    required this.trigger,
    required this.toasts,
    required this.keyListener,
  });

  final AppStore store;

  /// 原生桥（桌面端 MethodChannel；Web 预览降级）。
  final NativeBridge bridge;

  /// 全局热键管理器。
  final HotkeyManager hotkeys;

  /// 系统触发服务。
  final SystemTriggerService trigger;

  /// Toast 总线。
  final ToastBus toasts;

  /// 进程内热键兜底监听（无原生全局热键时启用）。
  final HardwareHotkeyListener keyListener;

  /// 热键事件流（页面按需订阅自己的热键 id）。
  Stream<HotkeyEvent> get hotkeyEvents => keyListener.onTrigger;

  /// 启动：注册热键 + 起进程内监听。
  Future<void> init() async {
    keyListener.start();
    hotkeys.syncConflictsToStore();
    await hotkeys.registerAll();
  }

  void dispose() {
    keyListener.stop();
    toasts.dispose();
  }

  /// 装配（供 main 使用）：Web 预览自动降级为进程内实现。
  static LfServices bootstrap({
    required AppStore store,
    NativeBridge? bridge,
  }) {
    final effectiveBridge = bridge ?? NoopNativeBridge();
    final manager = HotkeyManager(
      store: store,
      platform: currentHotkeyPlatform(),
      bridge: effectiveBridge,
    );
    final trigger = SystemTriggerService(bridge: effectiveBridge);
    return LfServices(
      store: store,
      bridge: effectiveBridge,
      hotkeys: manager,
      trigger: trigger,
      toasts: ToastBus(),
      keyListener: HardwareHotkeyListener(manager: manager),
    );
  }
}

/// 服务作用域 —— 把 [LfServices] 沿 widget 树下发给各页面（T-022 / T-024）。
///
/// 避免给 15 个页面构造函数逐个加参数；页面用 `ServiceScope.of(context)`
/// 取用，未挂载作用域时（单测/孤立预览）返回 null 走降级。
class ServiceScope extends InheritedWidget {
  const ServiceScope({
    super.key,
    required this.services,
    required super.child,
  });

  final LfServices services;

  HotkeyManager get hotkeys => services.hotkeys;
  SystemTriggerService get trigger => services.trigger;
  ToastBus get toasts => services.toasts;
  AppStore get store => services.store;
  NativeBridge get bridge => services.bridge;

  static ServiceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServiceScope>();

  static ServiceScope of(BuildContext context) {
    final s = maybeOf(context);
    assert(s != null, 'ServiceScope 未挂载：请在 AppShell 外层包一层 ServiceScope');
    return s!;
  }

  @override
  bool updateShouldNotify(ServiceScope oldWidget) => services != oldWidget.services;
}
