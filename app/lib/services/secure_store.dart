import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 系统密钥存储抽象（ADR-004 系统集成层挂点 / ADR-001 数据边界）。
///
/// Key 明文**永不**进入 ProviderProfile 与 SharedPreferences 配置 JSON ——
/// 只落引用 id（`keyRef`），真身由本接口的平台实现保管：
///
/// | 平台 | 实现 | 落点 |
/// |---|---|---|
/// | macOS / iOS | [ChannelSecureStore] | Keychain（`kSecClassGenericPassword`） |
/// | Windows | [ChannelSecureStore] | DPAPI（CredWrite / Credential Manager） |
/// | Linux | [ChannelSecureStore] | libsecret（Secret Service D-Bus） |
/// | Android | [ChannelSecureStore] | EncryptedSharedPreferences（Keystore） |
/// | Web / 无原生壳 | [PrefsSecureStore] | 混淆落盘（降级，UI 明示） |
/// | 单测 | [InMemorySecureStore] | 进程内存 |
abstract class SecureStore {
  Future<void> write(String ref, String secret);
  Future<String?> read(String ref);
  Future<void> delete(String ref);
}

/// 便捷查询：该引用是否已有非空密钥（所有实现共用，不走 `implements` 必填）。
extension SecureStoreX on SecureStore {
  Future<bool> has(String ref) async => (await read(ref))?.isNotEmpty ?? false;
}

/// 内存实现（Web 预览 / 单测）。
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _secrets = {};

  @override
  Future<void> write(String ref, String secret) async => _secrets[ref] = secret;

  @override
  Future<String?> read(String ref) async => _secrets[ref];

  @override
  Future<void> delete(String ref) async => _secrets.remove(ref);
}

/// 系统密钥串实现（MethodChannel `linguaflow/secure`）。
///
/// 桌面/移动端由原生壳提供（macOS Keychain、Windows DPAPI、Linux libsecret）；
/// 通道不存在（Web 预览）时抛 [MissingPluginException]，由调用方降级。
class ChannelSecureStore implements SecureStore {
  ChannelSecureStore({MethodChannel? channel})
      : _ch = channel ?? const MethodChannel('linguaflow/secure');

  final MethodChannel _ch;

  @override
  Future<void> write(String ref, String secret) =>
      _ch.invokeMethod<void>('write', {'ref': ref, 'secret': secret});

  @override
  Future<String?> read(String ref) =>
      _ch.invokeMethod<String>('read', {'ref': ref});

  @override
  Future<void> delete(String ref) =>
      _ch.invokeMethod<void>('delete', {'ref': ref});
}

/// 降级实现：SharedPreferences 混淆落盘（Web 预览 / 未接原生壳的桌面端）。
///
/// ⚠️ 这不是密码学安全存储 —— 仅用于「无 Keychain 环境也能完整走查配置链路」，
/// 桌面端正式版必须走 [ChannelSecureStore]。UI 需在展示层明示降级状态。
class PrefsSecureStore implements SecureStore {
  PrefsSecureStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String _prefix = 'lf.secret.';

  /// 混淆密钥：进程内随机，重启后变化 → 落盘串不可跨会话直接复用。
  /// 目的仅为避免 `grep` 到明文 Key，不承担安全职责。
  static final List<int> _mask =
      List<int>.generate(32, (i) => Random.secure().nextInt(256), growable: false);

  String _obfuscate(String plain) {
    final bytes = utf8.encode(plain);
    final out = List<int>.filled(bytes.length, 0);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ _mask[i % _mask.length];
    }
    return base64Encode(out);
  }

  String _deobfuscate(String stored) {
    final bytes = base64Decode(stored);
    final out = List<int>.filled(bytes.length, 0);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ _mask[i % _mask.length];
    }
    return utf8.decode(out);
  }

  @override
  Future<void> write(String ref, String secret) =>
      _prefs.setString('$_prefix$ref', _obfuscate(secret));

  @override
  Future<String?> read(String ref) async {
    final v = await _prefs.getString('$_prefix$ref');
    if (v == null) return null;
    try {
      return _deobfuscate(v);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> delete(String ref) => _prefs.remove('$_prefix$ref');
}

/// 平台自适应装配：优先系统密钥串，取不到再降级（T-021）。
///
/// [fallback] 在原生通道不可用时顶上（Web 预览 / 单测传内存实现）。
class DelegatingSecureStore implements SecureStore {
  DelegatingSecureStore({SecureStore? primary, SecureStore? fallback})
      : _primary = primary,
        _fallback = fallback;

  final SecureStore? _primary;
  final SecureStore? _fallback;

  bool _primaryOk = true;

  /// 当前是否走系统密钥串（false = 已降级，UI 需提示）。
  bool get isSystemBacked => _primaryOk;

  Future<SecureStore> _resolve() async {
    final primary = _primary;
    if (!_primaryOk || primary == null) {
      return _fallback ?? InMemorySecureStore();
    }
    return primary;
  }

  @override
  Future<void> write(String ref, String secret) async {
    final s = await _resolve();
    try {
      await s.write(ref, secret);
    } on MissingPluginException {
      _primaryOk = false;
      await (_fallback ?? InMemorySecureStore()).write(ref, secret);
    }
  }

  @override
  Future<String?> read(String ref) async {
    final s = await _resolve();
    try {
      return await s.read(ref);
    } on MissingPluginException {
      _primaryOk = false;
      return (_fallback ?? InMemorySecureStore()).read(ref);
    }
  }

  @override
  Future<void> delete(String ref) async {
    final s = await _resolve();
    try {
      await s.delete(ref);
    } on MissingPluginException {
      _primaryOk = false;
      await (_fallback ?? InMemorySecureStore()).delete(ref);
    }
  }
}

/// ValueNotifier 版本，供配置页监听 Key 是否已保存。
class SecureStoreRef {
  SecureStoreRef(this.store);
  final SecureStore store;
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> put(String ref, String secret) async {
    await store.write(ref, secret);
    revision.value++;
  }

  Future<void> drop(String ref) async {
    await store.delete(ref);
    revision.value++;
  }
}

/// 生成 Key 引用 id（profile.id 派生，便于删除时一并清理）。
String keyRefFor(String profileId) => 'ref-$profileId';
