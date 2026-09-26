import 'dart:async';

import 'package:flutter/foundation.dart';

/// ADR-008 · 录音条四态状态机（PRD v3.2 §2.1 流程 A）。
///
/// 状态流转：`idle → recording → drafting → preview → done → idle`
/// - `recording`：按住说话（波形 + 计时）
/// - `drafting`：松手 → 成稿中（翻译开关开时显示「翻译中」，流式字数）
/// - `preview`：1.2s 后悔窗口（可点展开编辑 / ✓ 确认 / ✗ 重说）
/// - `done`：已写入输入框（1.5s 后自动淡出回 idle）
///
/// 强制验收项（ADR-008）：三态并列展示 = 同一 [RecorderPhase] 枚举 + 同一
/// pill 组件 [ui/overlays/recorder_pill.dart]，位置外形动画一致。
enum RecorderPhase { idle, recording, drafting, preview, done }

enum PreviewDecision { autoWrite, confirmed, retry }

class RecorderStateMachine extends ChangeNotifier {
  RecorderStateMachine({this.previewWindow = const Duration(milliseconds: 1200)});

  final Duration previewWindow;

  RecorderPhase _phase = RecorderPhase.idle;
  bool _translateOn = false; // pill 右侧「译」开关，默认关（成稿为主）
  Duration _recorded = Duration.zero;
  int _streamedChars = 0;
  String _previewText = '';
  String _finalText = '';
  Timer? _ticker;
  Timer? _previewTimer;
  Timer? _doneTimer;

  RecorderPhase get phase => _phase;
  bool get translateOn => _translateOn;
  Duration get recorded => _recorded;
  int get streamedChars => _streamedChars;
  String get previewText => _previewText;
  String get finalText => _finalText;
  bool get isBusy => _phase != RecorderPhase.idle;

  /// 录音中（每 100ms 心跳计时，供波形动画与 0:07 计时）。
  void startRecording() {
    if (_phase == RecorderPhase.recording) return;
    _cancelTimers();
    _phase = RecorderPhase.recording;
    _recorded = Duration.zero;
    _streamedChars = 0;
    _previewText = '';
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _recorded += const Duration(milliseconds: 100);
      notifyListeners();
    });
    notifyListeners();
  }

  /// 松手 → 成稿中（外部 pipeline 持续上报已输出字数）。
  void beginDrafting() {
    if (_phase != RecorderPhase.recording) return;
    _ticker?.cancel();
    _phase = RecorderPhase.drafting;
    notifyListeners();
  }

  /// 流式增量上报（成稿/翻译输出字符数）。
  void reportStreamedChars(int n) {
    if (_phase != RecorderPhase.drafting) return;
    _streamedChars = n;
    notifyListeners();
  }

  /// 成稿完成 → 预览态（1.2s 后悔窗口，PRD §2.1 关键规则）。
  void showPreview(String text, {VoidCallback? onTimeout}) {
    _phase = RecorderPhase.preview;
    _previewText = text;
    _previewTimer?.cancel();
    _previewTimer = Timer(previewWindow, () {
      if (_phase == RecorderPhase.preview) {
        confirm(text); // 默认 1.2s 自动写入
        onTimeout?.call();
      }
    });
    notifyListeners();
  }

  /// 用户点 ✓ 或 1.2s 超时 → 写入。
  void confirm(String text) {
    _cancelTimers();
    _phase = RecorderPhase.done;
    _finalText = text;
    _doneTimer = Timer(const Duration(milliseconds: 1500), reset);
    notifyListeners();
  }

  /// 用户点 ✗ 重说 → 回录音态。
  void retry() {
    _cancelTimers();
    _phase = RecorderPhase.idle;
    _previewText = '';
    notifyListeners();
  }

  /// Esc 取消（任意态可取消，PRD §2.1）。
  void cancel() {
    _cancelTimers();
    _phase = RecorderPhase.idle;
    _recorded = Duration.zero;
    _streamedChars = 0;
    _previewText = '';
    notifyListeners();
  }

  /// 完成态淡出后回 idle。
  void reset() {
    _cancelTimers();
    _phase = RecorderPhase.idle;
    _recorded = Duration.zero;
    _streamedChars = 0;
    _previewText = '';
    notifyListeners();
  }

  /// 翻译开关切换（默认关 = 同语言成稿；开 = 写入目标语言）。
  void toggleTranslate() {
    _translateOn = !_translateOn;
    notifyListeners();
  }

  void _cancelTimers() {
    _ticker?.cancel();
    _previewTimer?.cancel();
    _doneTimer?.cancel();
    _ticker = null;
    _previewTimer = null;
    _doneTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

/// m:ss 计时格式（pill 录音态 0:02）。
String formatRecorded(Duration d) {
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '$m:${s.toString().padLeft(2, '0')}';
}
