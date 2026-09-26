/// 已配置的模型 Provider 档案（I 模型配置页数据实体）。
///
/// Key 明文不入此对象持久化 —— 走 [SecureStoreRef]（系统密钥串挂点），
/// 这里仅保存一个引用 id（ADR-001：配置本地保存，请求直连模型方）。
library;
import 'package:flutter/foundation.dart';

@immutable
class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.platform,
    required this.baseUrl,
    required this.model,
    this.keyRef,
    this.isDefault = false,
    this.latencyMs,
    this.healthy = false,
  });

  final String id;
  final String platform; // 平台名：OpenAI / Claude / Ollama（本地）…
  final String baseUrl;
  final String model;
  final String? keyRef; // SecureStore 引用 id；Ollama 本地无 Key 为 null
  final bool isDefault;
  final int? latencyMs; // 最近一次测试连接延迟
  final bool healthy;

  String get displayLabel => '$platform · $model';

  ProviderProfile copyWith({
    String? baseUrl,
    String? model,
    String? keyRef,
    bool? isDefault,
    int? latencyMs,
    bool? healthy,
  }) =>
      ProviderProfile(
        id: id,
        platform: platform,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        keyRef: keyRef ?? this.keyRef,
        isDefault: isDefault ?? this.isDefault,
        latencyMs: latencyMs ?? this.latencyMs,
        healthy: healthy ?? this.healthy,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'platform': platform,
        'baseUrl': baseUrl,
        'model': model,
        'keyRef': keyRef,
        'isDefault': isDefault,
        'latencyMs': latencyMs,
        'healthy': healthy,
      };

  factory ProviderProfile.fromJson(Map<String, Object?> json) => ProviderProfile(
        id: json['id']! as String,
        platform: json['platform']! as String,
        baseUrl: json['baseUrl']! as String,
        model: json['model']! as String,
        keyRef: json['keyRef'] as String?,
        isDefault: json['isDefault'] == true,
        latencyMs: json['latencyMs'] as int?,
        healthy: json['healthy'] == true,
      );
}

/// 历史记录条目（H 首页）。
@immutable
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.time,
    required this.dir,
    required this.source,
    required this.target,
    required this.meta,
    required this.flow,
    this.starred = false,
  });

  final String id;
  final String time; // 展示用 HH:mm
  final String dir; // 中→英 / 英→中 / OCR
  final String source;
  final String target;
  final String meta; // "86 字 · 1.1s"
  final String flow; // 流程来源 A/B/C/D/E
  final bool starred;

  HistoryRecord copyWith({bool? starred}) => HistoryRecord(
        id: id,
        time: time,
        dir: dir,
        source: source,
        target: target,
        meta: meta,
        flow: flow,
        starred: starred ?? this.starred,
      );

  Map<String, Object?> toJson() => {
        'id': id, 'time': time, 'dir': dir, 'source': source,
        'target': target, 'meta': meta, 'flow': flow, 'starred': starred,
      };

  factory HistoryRecord.fromJson(Map<String, Object?> json) => HistoryRecord(
        id: json['id']! as String,
        time: json['time']! as String,
        dir: json['dir']! as String,
        source: json['source']! as String,
        target: json['target']! as String,
        meta: json['meta']! as String,
        flow: json['flow']! as String,
        starred: json['starred'] == true,
      );
}

/// 术语表条目（K 偏好·术语）。
@immutable
class TermEntry {
  const TermEntry({required this.source, required this.target, required this.flag});

  final String source;
  final String target;
  final String flag; // both / zh / en

  Map<String, Object?> toJson() => {'source': source, 'target': target, 'flag': flag};

  factory TermEntry.fromJson(Map<String, Object?> json) => TermEntry(
        source: json['source']! as String,
        target: json['target']! as String,
        flag: json['flag']! as String,
      );
}

/// 术语分表。
@immutable
class TermGroup {
  const TermGroup({required this.name, required this.entries});

  final String name;
  final List<TermEntry> entries;
}

/// Skill 场景模板（对齐 Chatterfly 六场景，PRD §3）。
@immutable
class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.meta,
    this.custom = false,
  });

  final String id;
  final String name;
  final String desc;
  final String icon; // LfIcons key
  final String meta;
  final bool custom;
}

/// 修饰键（T-024 结构化组合键，供解析/序列化/冲突检测/原生注册共用）。
enum HotkeyModifier { ctrl, alt, shift, meta, fn }

/// 目标平台（冲突表与展示串分平台）。
enum HotkeyPlatform { macOS, windows, linux }

/// 结构化组合键 —— T-024 重绑录制与冲突检测的原子单位。
///
/// 展示串（`⌥ Space` / `Ctrl Alt D` / `按住 Fn`）与结构体双向可转，
/// 原生注册时按结构体下发，不传字符串（避免各端解析歧义）。
@immutable
class HotkeyCombo {
  const HotkeyCombo({
    this.modifiers = const <HotkeyModifier>{},
    this.key,
    this.hold = false,
    this.doubleTap = false,
  });

  /// 修饰键集合。
  final Set<HotkeyModifier> modifiers;

  /// 主键：'space' / 'd' / 'enter' / 'fn' / 'escape' …；纯修饰键组合为 null。
  final String? key;

  /// 按住触发（语音键：按下开始录音、松开结束 —— PRD §4 规则 2）。
  final bool hold;

  /// 双击修饰键触发（如「双击 ⌥」打开主窗口）。
  final bool doubleTap;

  bool get isEmpty => modifiers.isEmpty && key == null;

  HotkeyCombo copyWith({
    Set<HotkeyModifier>? modifiers,
    String? key,
    bool? hold,
    bool? doubleTap,
  }) =>
      HotkeyCombo(
        modifiers: modifiers ?? this.modifiers,
        key: key ?? this.key,
        hold: hold ?? this.hold,
        doubleTap: doubleTap ?? this.doubleTap,
      );

  /// 规范化键名（用于等价比较与原生下发）：全小写、空格归一。
  static String? normalizeKey(String? raw) {
    if (raw == null) return null;
    final k = raw.trim().toLowerCase();
    if (k.isEmpty) return null;
    return switch (k) {
      'space' || '空格' || ' ' => 'space',
      'enter' || 'return' || '↩' || '回车' => 'enter',
      'esc' || 'escape' => 'escape',
      'tab' => 'tab',
      'fn' => 'fn',
      _ => k,
    };
  }

  static HotkeyModifier? _modOf(String token) => switch (token) {
        '⌃' || 'ctrl' || 'control' || 'ctl' => HotkeyModifier.ctrl,
        '⌥' || 'alt' || 'option' || 'opt' => HotkeyModifier.alt,
        '⇧' || 'shift' => HotkeyModifier.shift,
        '⌘' || 'cmd' || 'command' || 'meta' || 'win' || 'super' => HotkeyModifier.meta,
        'fn' => HotkeyModifier.fn,
        _ => null,
      };

  /// 解析展示串（兼容 `⌥ Space` / `Ctrl Alt D` / `按住 Fn` / `双击 ⌥` / `⌥ ⇧ P`）。
  static HotkeyCombo? parse(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    var hold = false;
    var doubleTap = false;
    final mods = <HotkeyModifier>{};
    String? key;

    // 修饰语前缀
    var body = s;
    if (body.startsWith('按住') || body.toLowerCase().startsWith('hold ')) {
      hold = true;
      body = body.replaceFirst(RegExp(r'^(按住|hold\s+)', caseSensitive: false), '').trim();
    }
    if (body.startsWith('双击') || body.toLowerCase().startsWith('double')) {
      doubleTap = true;
      body = body.replaceFirst(RegExp(r'^(双击|double-?tap\s*)', caseSensitive: false), '').trim();
    }

    for (final token in body.split(RegExp(r'[\s+]+')).where((t) => t.isNotEmpty)) {
      final m = _modOf(token.toLowerCase());
      if (m != null) {
        // `Fn` 既可作修饰键也可作主键（按住 Fn = 主键为 fn）
        if (m == HotkeyModifier.fn && token.toLowerCase() == 'fn') {
          if (key == null) {
            key = 'fn';
            continue;
          }
        }
        mods.add(m);
        continue;
      }
      key = normalizeKey(token);
    }
    if (mods.isEmpty && key == null) return null;
    return HotkeyCombo(modifiers: mods, key: key, hold: hold, doubleTap: doubleTap);
  }

  /// 展示串（分平台：mac 用符号、Win/Linux 用单词 —— 对齐 PRD §4 表格口径）。
  String format(HotkeyPlatform platform) {
    final mac = platform == HotkeyPlatform.macOS;
    const macOrder = [HotkeyModifier.ctrl, HotkeyModifier.alt, HotkeyModifier.shift, HotkeyModifier.meta];
    const winOrder = [HotkeyModifier.ctrl, HotkeyModifier.alt, HotkeyModifier.shift, HotkeyModifier.meta];
    final order = mac ? macOrder : winOrder;
    final parts = <String>[
      for (final m in order)
        if (modifiers.contains(m))
          switch (m) {
            HotkeyModifier.ctrl => mac ? '⌃' : 'Ctrl',
            HotkeyModifier.alt => mac ? '⌥' : 'Alt',
            HotkeyModifier.shift => mac ? '⇧' : 'Shift',
            HotkeyModifier.meta => mac ? '⌘' : 'Win',
            HotkeyModifier.fn => 'Fn',
          },
    ];

    // 主键为 fn 时，符号体系里 Fn 直接放在修饰位后
    final k = key;
    if (k != null) {
      parts.add(switch (k) {
        'space' => mac ? 'Space' : 'Space',
        'enter' => mac ? '↩' : 'Enter',
        'escape' => 'Esc',
        'tab' => 'Tab',
        'fn' => 'Fn',
        _ => k.length == 1 ? k.toUpperCase() : k,
      });
    }

    var out = parts.join(mac ? '' : '+');
    if (mac) out = out.replaceAllMapped(RegExp(r'([⌃⌥⇧⌘])(?=[A-Za-z0-9↩])'), (m) => '${m[1]} ');
    if (doubleTap) out = mac ? '双击 $out' : '双击 $out';
    if (hold) out = mac ? '按住 $out' : '按住 $out';
    return out.trim();
  }

  /// 原生下发串（稳定、可解析，不随展示语言变化）。
  String get wire => [
        for (final m in const [HotkeyModifier.ctrl, HotkeyModifier.alt, HotkeyModifier.shift, HotkeyModifier.meta, HotkeyModifier.fn])
          if (modifiers.contains(m)) m.name,
        if (key != null) key!,
      ].join('+');

  /// 等价比较（顺序无关）。
  bool sameAs(HotkeyCombo other) =>
      hold == other.hold &&
      doubleTap == other.doubleTap &&
      key == other.key &&
      modifiers.length == other.modifiers.length &&
      modifiers.every(other.modifiers.contains);

  Map<String, Object?> toJson() => {
        'modifiers': [for (final m in modifiers) m.name],
        'key': key,
        'hold': hold,
        'doubleTap': doubleTap,
      };

  factory HotkeyCombo.fromJson(Map<String, Object?> json) => HotkeyCombo(
        modifiers: {
          for (final m in (json['modifiers'] as List<Object?>? ?? const []))
            HotkeyModifier.values.firstWhere(
              (e) => e.name == m,
              orElse: () => HotkeyModifier.alt,
            ),
        },
        key: json['key'] as String?,
        hold: json['hold'] == true,
        doubleTap: json['doubleTap'] == true,
      );

  @override
  bool operator ==(Object other) =>
      other is HotkeyCombo && other.wire == wire && other.hold == hold && other.doubleTap == doubleTap;

  @override
  int get hashCode => Object.hash(wire, hold, doubleTap);

  @override
  String toString() => wire;
}

/// 热键项（J 快捷键页）。
@immutable
class HotkeyItem {
  const HotkeyItem({
    required this.id,
    required this.label,
    required this.mac,
    required this.win,
    this.conflictWith,
    this.holdToRecord = false,
    this.macCombo,
    this.winCombo,
  });

  final String id;
  final String label;
  final String mac;
  final String win;

  /// 冲突对象描述（由 [HotkeyManager] 实时检测写回；null = 可用）
  final String? conflictWith;

  /// 语音键：按住触发（PRD §4 规则 2）。
  final bool holdToRecord;

  /// 结构化组合键（重绑后写入；为空时从展示串解析）。
  final HotkeyCombo? macCombo;
  final HotkeyCombo? winCombo;

  bool get hasConflict => conflictWith != null;

  /// 按平台取展示串。
  String display(HotkeyPlatform p) => p == HotkeyPlatform.macOS ? mac : win;

  /// 按平台取结构体（缺失则现场解析展示串）。
  HotkeyCombo? combo(HotkeyPlatform p) =>
      (p == HotkeyPlatform.macOS ? macCombo : winCombo) ?? HotkeyCombo.parse(display(p));

  HotkeyItem copyWith({
    String? label,
    String? mac,
    String? win,
    Object? conflictWith = _sentinel,
    bool? holdToRecord,
    HotkeyCombo? macCombo,
    HotkeyCombo? winCombo,
  }) =>
      HotkeyItem(
        id: id,
        label: label ?? this.label,
        mac: mac ?? this.mac,
        win: win ?? this.win,
        conflictWith: identical(conflictWith, _sentinel)
            ? this.conflictWith
            : conflictWith as String?,
        holdToRecord: holdToRecord ?? this.holdToRecord,
        macCombo: macCombo ?? this.macCombo,
        winCombo: winCombo ?? this.winCombo,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'mac': mac,
        'win': win,
        'conflictWith': conflictWith,
        'holdToRecord': holdToRecord,
        'macCombo': macCombo?.toJson(),
        'winCombo': winCombo?.toJson(),
      };

  factory HotkeyItem.fromJson(Map<String, Object?> json) => HotkeyItem(
        id: json['id']! as String,
        label: json['label']! as String,
        mac: json['mac']! as String,
        win: json['win']! as String,
        conflictWith: json['conflictWith'] as String?,
        holdToRecord: json['holdToRecord'] == true,
        macCombo: json['macCombo'] == null
            ? null
            : HotkeyCombo.fromJson(json['macCombo']! as Map<String, Object?>),
        winCombo: json['winCombo'] == null
            ? null
            : HotkeyCombo.fromJson(json['winCombo']! as Map<String, Object?>),
      );
}

/// copyWith 中区分「不传」与「传 null」的哨兵。
const Object _sentinel = Object();
