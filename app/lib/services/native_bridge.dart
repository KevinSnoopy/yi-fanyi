import 'package:flutter/services.dart';

/// 原生桥抽象（ADR-004）：Dart 业务层不直接调原生 API，统一走此接口。
///
/// 平台实现挂点：
/// - macOS:  Swift MethodChannel（全局热键、麦克风、焦点监测、文本注入）
/// - Windows: Kotlin/C++（Hook、热键、IME）
/// - Linux:  C++ + GTK 注入
/// - iOS:    Swift（键盘扩展、App Group）
/// - Android: Kotlin（输入法服务、前台录音）
/// - Web 预览: [NoopNativeBridge]（能力缺失降级，UI 可完整走查）
abstract class NativeBridge {
  /// 注册全局热键（唤起键单次触发 / 语音键按住触发，PRD §4 规则 2）。
  Future<bool> registerHotkeys(List<HotkeySpec> specs) async => false;

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
}

/// 热键规格。
class HotkeySpec {
  const HotkeySpec({required this.id, required this.trigger, this.holdToRecord = false});

  final String id; // 对应 HotkeyItem.id
  final String trigger; // 'fn' / 'alt+space' / 'alt+d' …
  final bool holdToRecord; // 语音键按住触发
}

/// 无操作实现（Web 预览 / 单测）：全部能力降级为可用 UI 走查路径。
class NoopNativeBridge extends NativeBridge {}
