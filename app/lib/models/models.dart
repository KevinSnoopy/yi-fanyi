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

/// 热键项（J 快捷键页）。
@immutable
class HotkeyItem {
  const HotkeyItem({
    required this.id,
    required this.label,
    required this.mac,
    required this.win,
    this.conflictWith,
  });

  final String id;
  final String label;
  final String mac;
  final String win;

  /// 冲突对象描述（如 "macOS 截屏 ⌥⇧S"）；null = 可用
  final String? conflictWith;

  bool get hasConflict => conflictWith != null;
}
