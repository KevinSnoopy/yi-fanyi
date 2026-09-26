import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import 'app_store.dart';
import 'native_bridge.dart';

/// T-024 · 全局热键管理器 —— 注册 / 冲突检测 / 重绑。
///
/// 三层职责分离：
/// 1. **冲突检测**（纯函数）：系统保留表 + 第三方占用表 + 内部重复
/// 2. **原生注册**：下发 [HotkeySpec] 给 [NativeBridge]（macOS Carbon 全局热键）
/// 3. **进程内兜底**：无原生壳时（Web 预览）用 [HardwareHotkeyListener] 捕获
class HotkeyManager extends ChangeNotifier {
  HotkeyManager({
    required this.store,
    required this.platform,
    required this.bridge,
  });

  final AppStore store;
  final NativeBridge bridge;
  HotkeyPlatform platform;

  /// 临时禁用全部热键（PRD §4：演示/摸鱼模式）。
  bool paused = false;

  HotkeyRegisterReport? lastReport;

  List<HotkeyItem> get items => store.hotkeys;

  // ============================================================
  // 冲突检测（J 页红字提示占用方，PRD §4 规则 1）
  // ============================================================

  /// 全量检测：返回 `hotkeyId → 冲突描述`。
  Map<String, HotkeyConflict> detectConflicts() {
    final out = <String, HotkeyConflict>{};

    // ① 系统 / 第三方占用
    for (final item in items) {
      final combo = item.combo(platform);
      if (combo == null || combo.isEmpty) continue;
      for (final r in kReservedCombos) {
        if (!r.platforms.contains(platform)) continue;
        if (r.combo.sameAs(combo)) {
          out[item.id] = HotkeyConflict(
            hotkeyId: item.id,
            owner: r.owner,
            reason: r.reason,
            fatal: r.fatal,
          );
        }
      }
    }

    // ② 内部重复（两条热键绑到同一组合）
    final seen = <String, String>{};
    for (final item in items) {
      final combo = item.combo(platform);
      if (combo == null || combo.isEmpty) continue;
      final wire = combo.wire;
      final prev = seen[wire];
      if (prev != null) {
        out[item.id] = HotkeyConflict(
          hotkeyId: item.id,
          owner: '本应用「${_labelOf(prev)}」',
          reason: '与已绑定热键重复，后者不会生效',
          fatal: true,
        );
      } else {
        seen[wire] = item.id;
      }
    }
    return out;
  }

  HotkeyConflict? conflictOf(String id) => detectConflicts()[id];

  /// 冲突数量（状态栏/徽标展示）。
  int get conflictCount => detectConflicts().length;

  String _labelOf(String id) =>
      items.firstWhere((h) => h.id == id, orElse: () => items.first).label;

  // ============================================================
  // 注册
  // ============================================================

  List<HotkeySpec> specs() => [
        for (final h in items)
          if (!paused)
            HotkeySpec(
              id: h.id,
              trigger: h.combo(platform)?.wire ?? '',
              holdToRecord: h.holdToRecord,
            ),
      ];

  /// 注册全部热键（冲突项照常下发，由原生层决定成败并回传占用方）。
  Future<HotkeyRegisterReport> registerAll() async {
    if (paused) {
      await bridge.unregisterHotkeys();
      lastReport = HotkeyRegisterReport(total: items.length, registered: 0, native: false);
      notifyListeners();
      return lastReport!;
    }
    final specs = this.specs()..removeWhere((s) => s.trigger.isEmpty);
    final ok = await bridge.registerHotkeys(specs);
    final conflicts = detectConflicts();
    final report = HotkeyRegisterReport(
      total: specs.length,
      registered: ok ? specs.length - conflicts.length : 0,
      native: bridge.available,
      failures: {
        for (final c in conflicts.values)
          if (c.fatal) c.hotkeyId: '${c.owner} · ${c.reason}',
      },
    );
    lastReport = report;
    notifyListeners();
    return report;
  }

  /// 暂停 / 恢复（临时禁用全部热键）。
  Future<void> setPaused(bool v) async {
    paused = v;
    if (v) {
      await bridge.unregisterHotkeys();
    } else {
      await registerAll();
    }
    notifyListeners();
  }

  // ============================================================
  // 重绑
  // ============================================================

  /// 重绑（冲突也允许保存，但立刻写回 conflictWith 由 UI 标红）。
  Future<HotkeyConflict?> rebind(String id, HotkeyCombo combo) async {
    final i = items.indexWhere((h) => h.id == id);
    if (i < 0) return null;
    final old = items[i];
    final mac = platform == HotkeyPlatform.macOS ? combo.format(HotkeyPlatform.macOS) : old.mac;
    final win = platform == HotkeyPlatform.macOS ? old.win : combo.format(HotkeyPlatform.windows);
    store.setHotkey(old.copyWith(
      mac: mac,
      win: win,
      macCombo: platform == HotkeyPlatform.macOS ? combo : old.macCombo,
      winCombo: platform == HotkeyPlatform.macOS ? old.winCombo : combo,
    ));

    final conflict = detectConflicts()[id];
    if (conflict != null) {
      final cur = items.firstWhere((h) => h.id == id);
      store.setHotkey(cur.copyWith(conflictWith: '${conflict.owner} · ${conflict.reason}'));
    } else {
      final cur = items.firstWhere((h) => h.id == id);
      if (cur.conflictWith != null) store.setHotkey(cur.copyWith(conflictWith: null));
    }

    // 重绑后立即重新注册（原生热键需要重建监听）
    await registerAll();
    notifyListeners();
    return conflict;
  }

  /// 恢复出厂热键（清除全部重绑）。
  Future<void> resetToDefaults(List<HotkeyItem> defaults) async {
    store.resetHotkeys(defaults);
    await registerAll();
    notifyListeners();
  }

  /// 把当前检测到的冲突写回 store（J 页进入时调用一次，列表实时标红）。
  void syncConflictsToStore() {
    final conflicts = detectConflicts();
    for (final h in items) {
      final c = conflicts[h.id];
      final want = c == null ? null : '${c.owner} · ${c.reason}';
      if (h.conflictWith != want) {
        store.setHotkey(h.copyWith(conflictWith: want));
      }
    }
  }
}

/// 冲突描述（J 页红字 + 重绑后即时提示）。
@immutable
class HotkeyConflict {
  const HotkeyConflict({
    required this.hotkeyId,
    required this.owner,
    required this.reason,
    this.fatal = true,
  });

  final String hotkeyId;
  final String owner; // 占用方：'macOS Spotlight' / '微信截图'
  final String reason;
  final bool fatal; // true = 系统级占用，必定不生效
}

/// 注册结果（J 页 / 状态栏展示）。
@immutable
class HotkeyRegisterReport {
  const HotkeyRegisterReport({
    required this.total,
    required this.registered,
    this.native = false,
    this.failures = const {},
  });

  final int total;
  final int registered;
  final bool native;

  /// `hotkeyId → 失败原因`。
  final Map<String, String> failures;

  String get summary => native
      ? '原生全局热键：$registered/$total 生效'
      : '进程内热键（Web 预览）：$registered/$total 生效';
}

/// 系统 / 第三方已占用组合表（PRD §4 规则 1：含微信截图等常见占用）。
@immutable
class ReservedCombo {
  const ReservedCombo({
    required this.combo,
    required this.platforms,
    required this.owner,
    required this.reason,
    this.fatal = true,
  });

  final HotkeyCombo combo;
  final Set<HotkeyPlatform> platforms;
  final String owner;
  final String reason;
  final bool fatal;
}

/// 占用表（按 PRD §4 口径 + 主流软件实测占用整理）。
final List<ReservedCombo> kReservedCombos = [
  // ---- macOS 系统 ----
  ReservedCombo(
    combo: HotkeyCombo.parse('⌘ Space')!,
    platforms: {HotkeyPlatform.macOS},
    owner: 'macOS Spotlight',
    reason: '系统占用，无法拦截',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('⌃ Space')!,
    platforms: {HotkeyPlatform.macOS},
    owner: 'macOS 输入法切换',
    reason: '系统占用，无法拦截',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('⌘ ⇧ 4')!,
    platforms: {HotkeyPlatform.macOS},
    owner: 'macOS 截屏',
    reason: '系统占用，无法拦截',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('⌥ ⇧ S')!,
    platforms: {HotkeyPlatform.macOS},
    owner: 'macOS 截屏',
    reason: '系统占用（PRD §4 已知冲突），建议改绑 ⌥ J',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('⌘ Tab')!,
    platforms: {HotkeyPlatform.macOS},
    owner: 'macOS 应用切换',
    reason: '系统占用，无法拦截',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('⌥ Space')!,
    platforms: {HotkeyPlatform.macOS},
    owner: 'Alfred / Raycast（如已启用）',
    reason: '第三方常见占用，冲突时本应用不生效',
    fatal: false,
  ),

  // ---- Windows 系统 ----
  ReservedCombo(
    combo: HotkeyCombo.parse('Alt Space')!,
    platforms: {HotkeyPlatform.windows},
    owner: 'Windows 窗口系统菜单',
    reason: '系统占用，无法拦截（PRD 默认值，建议改绑 Alt+Space 之外的组合）',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Alt Delete')!,
    platforms: {HotkeyPlatform.windows},
    owner: 'Windows 安全桌面',
    reason: '系统保留，无法拦截',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Win L')!,
    platforms: {HotkeyPlatform.windows},
    owner: 'Windows 锁屏',
    reason: '系统保留，无法拦截',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Win Space')!,
    platforms: {HotkeyPlatform.windows},
    owner: 'Windows 输入法切换',
    reason: '系统占用',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Shift Esc')!,
    platforms: {HotkeyPlatform.windows},
    owner: 'Windows 任务管理器',
    reason: '系统保留，无法拦截',
  ),

  // ---- Windows 第三方 ----
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Alt A')!,
    platforms: {HotkeyPlatform.windows},
    owner: '微信截图',
    reason: '第三方占用，冲突时本应用不生效',
    fatal: false,
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Alt D')!,
    platforms: {HotkeyPlatform.windows},
    owner: '有道词典划词',
    reason: '第三方占用，冲突时本应用不生效',
    fatal: false,
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Alt S')!,
    platforms: {HotkeyPlatform.windows},
    owner: 'QQ / 网易有道截图',
    reason: '第三方常见占用，冲突时本应用不生效',
    fatal: false,
  ),

  // ---- Linux ----
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Alt Delete')!,
    platforms: {HotkeyPlatform.linux},
    owner: 'Linux 注销对话框',
    reason: '桌面环境保留',
  ),
  ReservedCombo(
    combo: HotkeyCombo.parse('Ctrl Alt T')!,
    platforms: {HotkeyPlatform.linux},
    owner: 'GNOME 终端',
    reason: '桌面环境默认占用，冲突时本应用不生效',
    fatal: false,
  ),
];

// ============================================================
// 进程内热键兜底（Web 预览 / 未接原生壳的桌面端）
// ============================================================

/// 热键事件（按下 / 松开 —— 语音键需要区分）。
class HotkeyEvent {
  const HotkeyEvent({required this.id, required this.down, required this.combo});

  final String id;
  final bool down;
  final HotkeyCombo combo;
}

/// 进程内键盘监听 —— 用 [HardwareKeyboard] 捕获组合键。
///
/// ⚠️ 仅在本应用有键盘焦点时有效（浏览器沙箱限制）；真正的全局热键
/// 必须由原生壳注册（macOS Carbon / Windows RegisterHotKey）。
class HardwareHotkeyListener {
  HardwareHotkeyListener({required this.manager});

  final HotkeyManager manager;

  final StreamController<HotkeyEvent> _bus = StreamController<HotkeyEvent>.broadcast();
  Stream<HotkeyEvent> get onTrigger => _bus.stream;

  bool Function(KeyEvent)? _handler;
  final Set<LogicalKeyboardKey> _pressed = {};

  void start() {
    if (_handler != null) return;
    _handler = _handle;
    HardwareKeyboard.instance.addHandler(_handler!);
  }

  void stop() {
    final h = _handler;
    if (h == null) return;
    HardwareKeyboard.instance.removeHandler(h);
    _handler = null;
    _pressed.clear();
  }

  bool _handle(KeyEvent event) {
    if (manager.paused) return false;

    // 构造当前按下的组合（以事件自带的按键集合为准，避免修饰键时序抖动）
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final mods = <HotkeyModifier>{};
    String? keyName;
    for (final k in pressed) {
      final m = hotkeyModifierOf(k);
      if (m != null) {
        mods.add(m);
      } else {
        keyName ??= hotkeyKeyNameOf(k);
      }
    }
    if (keyName == null) return false;

    final combo = HotkeyCombo(modifiers: mods, key: keyName);
    for (final item in manager.items) {
      final target = item.combo(manager.platform);
      if (target == null || !target.sameAs(combo)) continue;

      // 语音键按住触发：按下开始、松开结束（PRD §4 规则 2）
      final down = event is KeyDownEvent;
      if (item.holdToRecord) {
        if (down && _pressed.contains(event.logicalKey)) return false; // 去重自动重复
        down ? _pressed.add(event.logicalKey) : _pressed.remove(event.logicalKey);
      } else if (!down) {
        return false; // 唤起键只认按下
      }
      _bus.add(HotkeyEvent(id: item.id, down: down, combo: combo));
      return true;
    }
    return false;
  }

}

/// [LogicalKeyboardKey] → 修饰键（供重绑录制与监听共用）。
HotkeyModifier? hotkeyModifierOf(LogicalKeyboardKey k) => switch (k) {
      LogicalKeyboardKey.controlLeft ||
      LogicalKeyboardKey.controlRight ||
      LogicalKeyboardKey.control =>
        HotkeyModifier.ctrl,
      LogicalKeyboardKey.altLeft ||
      LogicalKeyboardKey.altRight ||
      LogicalKeyboardKey.alt =>
        HotkeyModifier.alt,
      LogicalKeyboardKey.shiftLeft ||
      LogicalKeyboardKey.shiftRight ||
      LogicalKeyboardKey.shift =>
        HotkeyModifier.shift,
      LogicalKeyboardKey.metaLeft ||
      LogicalKeyboardKey.metaRight ||
      LogicalKeyboardKey.meta =>
        HotkeyModifier.meta,
      LogicalKeyboardKey.fn => HotkeyModifier.fn,
      _ => null,
    };

/// [LogicalKeyboardKey] → 主键名（供重绑录制与监听共用）。
String? hotkeyKeyNameOf(LogicalKeyboardKey k) {
  if (k == LogicalKeyboardKey.space) return 'space';
  if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) return 'enter';
  if (k == LogicalKeyboardKey.escape) return 'escape';
  if (k == LogicalKeyboardKey.tab) return 'tab';
  if (k == LogicalKeyboardKey.fn) return 'fn';
  final label = k.keyLabel.toLowerCase();
  if (label.length == 1 && RegExp(r'[a-z0-9]').hasMatch(label)) return label;
  return null;
}

/// 当前平台（Web 端按 UA 粗判，桌面端由 [defaultTargetPlatform] 决定）。
HotkeyPlatform currentHotkeyPlatform() => switch (defaultTargetPlatform) {
      TargetPlatform.macOS => HotkeyPlatform.macOS,
      TargetPlatform.windows => HotkeyPlatform.windows,
      TargetPlatform.linux => HotkeyPlatform.linux,
      _ => HotkeyPlatform.macOS, // Web 预览按 macOS 口径展示（PRD 主参考系）
    };
