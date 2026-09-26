import 'package:flutter/foundation.dart';

/// 系统密钥存储抽象（ADR-004 系统集成层挂点）。
///
/// - macOS/iOS: Keychain
/// - Windows:   DPAPI
/// - Linux:     libsecret
/// - Android:   EncryptedSharedPreferences
/// - Web:       内存实现（预览环境，明文不落盘）
abstract class SecureStore {
  Future<void> write(String ref, String secret);
  Future<String?> read(String ref);
  Future<void> delete(String ref);
}

/// 内存实现（Web 预览 / 单测）。桌面端由对应平台插件实现替换。
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _secrets = {};

  @override
  Future<void> write(String ref, String secret) async => _secrets[ref] = secret;

  @override
  Future<String?> read(String ref) async => _secrets[ref];

  @override
  Future<void> delete(String ref) async => _secrets.remove(ref);
}

/// ValueNotifier 版本，供配置页监听 Key 是否已保存。
class SecureStoreRef {
  SecureStoreRef(this.store);
  final SecureStore store;
  final ValueNotifier<int> revision = ValueNotifier(0);
}
