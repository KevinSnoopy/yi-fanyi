import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_bridge.dart';

/// T-022 · 系统级触发服务 —— 悬浮窗 / 快捷面板 / 划词浮层 / 通知。
///
/// 同一套 API 两种落地：
/// - **system**：原生壳弹出 NSPanel / Win32 浮层（真全局、不抢焦点，PRD §4 规则 4）
/// - **inApp**：无原生壳（Web 预览）时退回 Dart 侧 Overlay —— 由宿主监听
///   [SystemTriggerService.pending] 渲染，行为与原生一致，便于完整走查
class SystemTriggerService extends ChangeNotifier {
  SystemTriggerService({required this.bridge, MethodChannel? channel}) {
    // 原生 → Dart：浮层结果回传（输入完成 / 复制 / 关闭）
    if (channel != null) {
      channel.setMethodCallHandler(_onNativeCall);
    }
  }

  final NativeBridge bridge;

  final StreamController<TriggerResult> _results =
      StreamController<TriggerResult>.broadcast();

  /// 浮层结果流（原生与 in-app 统一出口）。
  Stream<TriggerResult> get results => _results.stream;

  /// 待宿主渲染的 in-app 浮层（null = 当前无浮层）。
  TriggerRequest? pending;

  /// 最近一次触发的落地方式（状态栏展示：原生 / 应用内）。
  TriggerMode lastMode = TriggerMode.inApp;

  /// 原生壳可用时是否真的弹出了系统浮层。
  bool get isSystemBacked => lastMode == TriggerMode.system;

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'overlayResult':
        final args = Map<String, Object?>.from(call.arguments as Map<Object?, Object?>);
        _results.add(TriggerResult(
          id: '${args['id']}',
          action: '${args['action'] ?? 'submit'}',
          text: args['text'] as String?,
          confirmed: args['confirmed'] != false,
        ));
        return null;
      case 'hotkey':
        final args = Map<String, Object?>.from(call.arguments as Map<Object?, Object?>);
        _results.add(TriggerResult(
          id: '${args['id']}',
          action: 'hotkey',
          text: null,
          confirmed: args['down'] == true,
        ));
        return null;
      default:
        return null;
    }
  }

  /// 请求弹出浮层：优先原生，失败退回 in-app。
  Future<TriggerMode> request(TriggerRequest req) async {
    final ok = await bridge.showOverlay(
      SystemOverlaySpec(
        id: req.id,
        kind: req.kind,
        text: req.text,
        placeholder: req.placeholder,
        anchorX: req.anchor?.dx,
        anchorY: req.anchor?.dy,
      ),
    );
    if (ok) {
      lastMode = TriggerMode.system;
      pending = null;
      notifyListeners();
      return TriggerMode.system;
    }
    lastMode = TriggerMode.inApp;
    pending = req;
    notifyListeners();
    return TriggerMode.inApp;
  }

  /// in-app 浮层完成（宿主调用）。
  void completeInApp(
    String id, {
    String? text,
    bool confirmed = true,
    String action = 'submit',
  }) {
    if (pending?.id == id) {
      pending = null;
      notifyListeners();
    }
    _results.add(TriggerResult(id: id, action: action, text: text, confirmed: confirmed));
  }

  /// 关闭浮层（原生 + in-app 双清）。
  Future<void> close(String id) async {
    await bridge.hideOverlay(id);
    if (pending?.id == id) {
      pending = null;
      notifyListeners();
    }
    _results.add(TriggerResult(id: id, action: 'close', confirmed: false));
  }

  /// 读选区（流程 C）：原生 AX/CG 取选中文本；无原生时返回 null，由页面兜底。
  Future<String?> readSelection() => bridge.readSelection();

  /// 文本注入（流程 B/D 写回）：原生 AX 写入焦点框；降级写剪贴板。
  Future<void> injectText(String text) => bridge.injectText(text);

  /// 系统通知 + in-app toast 双发（失败/终止提示，PRD §4 规则 3）。
  Future<void> notify({required String title, required String body}) =>
      bridge.notify(title: title, body: body);
}

/// 浮层请求（Dart → 宿主/原生）。
@immutable
class TriggerRequest {
  const TriggerRequest({
    required this.id,
    required this.kind,
    this.text,
    this.placeholder,
    this.anchor,
  });

  final String id;
  final SystemOverlayKind kind;

  /// 预填文本（划词场景 = 选区原文）。
  final String? text;
  final String? placeholder;

  /// 锚点（in-app 用逻辑坐标；原生用屏幕坐标）。
  final Offset? anchor;
}

/// 浮层结果（原生/in-app 统一）。
@immutable
class TriggerResult {
  const TriggerResult({
    required this.id,
    required this.action,
    this.text,
    this.confirmed = true,
  });

  final String id;

  /// 'submit' 写回 / 'copy' 仅复制 / 'replace' 替换选区 / 'close' 关闭 / 'hotkey' 热键
  final String action;
  final String? text;
  final bool confirmed;
}

/// 触发落地方式。
enum TriggerMode {
  /// 原生系统浮层（macOS NSPanel / Windows 无焦点窗口）。
  system,

  /// 应用内降级浮层（Web 预览）。
  inApp,
}

/// in-app toast 总线（原生通知的降级呈现；原生成功时仍会同时 toast 以便走查）。
class ToastBus extends ChangeNotifier {
  String? message;
  int _seq = 0;

  /// 消息序号（宿主据此判定「新消息」并重置动画）。
  int get seq => _seq;

  Timer? _timer;

  void show(String msg, {Duration duration = const Duration(milliseconds: 2200)}) {
    message = msg;
    _seq++;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(duration, clear);
  }

  void clear() {
    message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
