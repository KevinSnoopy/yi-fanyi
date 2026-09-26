import 'package:flutter/services.dart';

import '../models/models.dart';

/// 原生桥抽象（ADR-004）：Dart 业务层不直接调原生 API，统一走此接口。
///
/// 平台实现挂点：
/// - macOS:  Swift MethodChannel（全局热键、麦克风、焦点监测、文本注入）
/// - Windows: C++/Win32（Hook、热键、IME）
/// - Linux:  C++ + GTK 注入
/// - iOS:    Swift（键盘扩展、App Group）
/// - Android: Kotlin（输入法服务、前台录音）
/// - Web 预览: [NoopNativeBridge]（能力缺失降级，UI 可完整走查）
abstract class NativeBridge {
  /// 原生能力是否可用（Web 预览为 false → UI 走降级路径）。
  bool get available => false;

  /// 注册全局热键（唤起键单次触发 / 语音键按住触发，PRD §4 规则 2）。
  Future<bool> registerHotkeys(List<HotkeySpec> specs) async => false;

  /// 注销全部热键（临时禁用 / 退出前清理）。
  Future<bool> unregisterHotkeys() async => false;

  /// 剪贴板写。
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 把文本注入当前焦点输入框（流程 A/D 写回动作；桌面端由原生桥完成）。
  Future<void> injectText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 麦克风录音可用性检测。
  Future<bool> hasMicPermission() async => false;

  /// 划词：读取当前选中文本（流程 C/D 挂点）。
  Future<String?> readSelection() async => null;

  /// 前台焦点应用名（per-app tone 自适应挂点，PRD §3 P1）。
  Future<String?> foregroundApp() async => null;

  /// 权限自检（macOS 辅助功能 / 输入监控；桌面端首次引导用）。
  Future<Map<String, bool>> permissionStatus() async => const {};

  /// 拉起系统授权页（macOS 系统设置 → 隐私与安全性）。
  Future<void> openPermissionSettings(String kind) async {}

  /// T-022 · 悬浮窗 / 快捷面板：显示系统级浮层。
  Future<bool> showOverlay(SystemOverlaySpec spec) async => false;

  /// T-022 · 关闭系统级浮层。
  Future<void> hideOverlay(String id) async {}

  /// T-022 · 系统通知（静默替换完成 / 失败 toast）。
  Future<void> notify({required String title, required String body}) async {}
}

/// 热键规格（下发给原生层；wire 串由 [HotkeyCombo.wire] 生成）。
class HotkeySpec {
  const HotkeySpec({
    required this.id,
    required this.trigger,
    this.holdToRecord = false,
  });

  final String id; // 对应 HotkeyItem.id
  final String trigger; // 'alt+space' / 'alt+d' / 'fn' …（wire 串）
  final bool holdToRecord; // 语音键按住触发

  Map<String, Object?> toMap() =>
      {'id': id, 'trigger': trigger, 'holdToRecord': holdToRecord};
}

/// T-022 · 系统级浮层规格。
class SystemOverlaySpec {
  const SystemOverlaySpec({
    required this.id,
    required this.kind,
    this.text,
    this.placeholder,
    this.anchorX,
    this.anchorY,
    this.width = 420,
    this.height = 220,
  });

  final String id;
  final SystemOverlayKind kind;
  final String? text; // 预填文本（划词翻译的原文）
  final String? placeholder;
  final double? anchorX; // 屏幕坐标（划词场景：选区旁）
  final double? anchorY;
  final double width;
  final double height;

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind.name,
        'text': text,
        'placeholder': placeholder,
        'anchorX': anchorX,
        'anchorY': anchorY,
        'width': width,
        'height': height,
      };
}

/// 系统级浮层类型（T-022 三类真实触发）。
enum SystemOverlayKind {
  /// 流程 B：鼠标旁迷你悬浮窗（可直接打字/粘贴）。
  floatingWindow,

  /// 流程 C：选区旁译文小窗。
  selectionPopover,

  /// 快捷面板（菜单栏 Popover，ADR-005）。
  quickPanel,
}

/// 无操作实现（Web 预览 / 单测）：全部能力降级为可用 UI 走查路径。
class NoopNativeBridge extends NativeBridge {}

/// MethodChannel 实现 —— 桌面/移动端由原生壳提供 `linguaflow/native` 通道
/// （macOS 见 `macos/Runner/NativeBridgePlugin.swift`）。
///
/// 通道不存在（Web 预览）时每个方法抛 [MissingPluginException]，
/// 由 [FallbackNativeBridge] 兜底为降级行为，保证 UI 不崩。
class ChannelNativeBridge extends NativeBridge {
  ChannelNativeBridge({MethodChannel? channel})
      : _ch = channel ?? const MethodChannel('linguaflow/native');

  final MethodChannel _ch;

  @override
  bool get available => true;

  @override
  Future<bool> registerHotkeys(List<HotkeySpec> specs) async =>
      await _ch.invokeMethod<bool>('registerHotkeys', {
        'specs': specs.map((s) => s.toMap()).toList(),
      }) ??
      false;

  @override
  Future<bool> unregisterHotkeys() async =>
      await _ch.invokeMethod<bool>('unregisterHotkeys') ?? false;

  @override
  Future<void> injectText(String text) =>
      _ch.invokeMethod<void>('injectText', {'text': text});

  @override
  Future<bool> hasMicPermission() async =>
      await _ch.invokeMethod<bool>('hasMicPermission') ?? false;

  @override
  Future<String?> readSelection() => _ch.invokeMethod<String>('readSelection');

  @override
  Future<String?> foregroundApp() => _ch.invokeMethod<String>('foregroundApp');

  @override
  Future<Map<String, bool>> permissionStatus() async {
    final m = await _ch.invokeMethod<Map<Object?, Object?>>('permissionStatus');
    if (m == null) return const {};
    return {for (final e in m.entries) '${e.key}': e.value == true};
  }

  @override
  Future<void> openPermissionSettings(String kind) =>
      _ch.invokeMethod<void>('openPermissionSettings', {'kind': kind});

  @override
  Future<bool> showOverlay(SystemOverlaySpec spec) async =>
      await _ch.invokeMethod<bool>('showOverlay', spec.toMap()) ?? false;

  @override
  Future<void> hideOverlay(String id) =>
      _ch.invokeMethod<void>('hideOverlay', {'id': id});

  @override
  Future<void> notify({required String title, required String body}) =>
      _ch.invokeMethod<void>('notify', {'title': title, 'body': body});
}

/// 降级包装：原生能力缺失时（Web 预览）自动退回 Dart 侧等价行为。
class FallbackNativeBridge extends NativeBridge {
  FallbackNativeBridge(this._primary);

  final NativeBridge _primary;

  bool _nativeOk = true;

  /// 当前是否走原生通道（false = 已降级，UI 可提示「Web 预览模式」）。
  bool get nativeOk => _nativeOk;

  @override
  bool get available => _nativeOk && _primary.available;

  Future<T> _try<T>(Future<T> Function() call, T fallback) async {
    if (!_nativeOk) return fallback;
    try {
      return await call();
    } on MissingPluginException {
      _nativeOk = false;
      return fallback;
    } on PlatformException {
      _nativeOk = false;
      return fallback;
    }
  }

  @override
  Future<bool> registerHotkeys(List<HotkeySpec> specs) =>
      _try(() => _primary.registerHotkeys(specs), false);

  @override
  Future<bool> unregisterHotkeys() => _try(() => _primary.unregisterHotkeys(), false);

  @override
  Future<void> injectText(String text) async {
    final ok = await _try(() async {
      await _primary.injectText(text);
      return true;
    }, false);
    if (!ok) await super.injectText(text); // 降级：写剪贴板
  }

  @override
  Future<bool> hasMicPermission() => _try(() => _primary.hasMicPermission(), false);

  @override
  Future<String?> readSelection() => _try(() => _primary.readSelection(), null);

  @override
  Future<String?> foregroundApp() => _try(() => _primary.foregroundApp(), null);

  @override
  Future<Map<String, bool>> permissionStatus() =>
      _try(() => _primary.permissionStatus(), const {});

  @override
  Future<void> openPermissionSettings(String kind) =>
      _try(() async => _primary.openPermissionSettings(kind), null);

  @override
  Future<bool> showOverlay(SystemOverlaySpec spec) =>
      _try(() => _primary.showOverlay(spec), false);

  @override
  Future<void> hideOverlay(String id) => _try(() => _primary.hideOverlay(id), null);

  @override
  Future<void> notify({required String title, required String body}) =>
      _try(() => _primary.notify(title: title, body: body), null);
}
