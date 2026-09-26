import Cocoa
import FlutterMacOS
import Security

/// T-021 · macOS Keychain 实现（`linguaflow/secure` 通道）。
///
/// Key 明文只进 Keychain（`kSecClassGenericPassword`），Dart 侧只留引用 id；
/// 与 ADR-001「配置本地保存、请求直连模型方」一致。
final class SecureStorePlugin: NSObject, FlutterPlugin {

  private static let service = "com.linguaflow.keys"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "linguaflow/secure", binaryMessenger: registrar.messenger)
    let instance = SecureStorePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let ref = args["ref"] as? String else {
      result(FlutterError(code: "bad_args", message: "ref required", details: nil))
      return
    }
    switch call.method {
    case "write":
      guard let secret = args["secret"] as? String else {
        result(FlutterError(code: "bad_args", message: "secret required", details: nil))
        return
      }
      result(write(ref: ref, secret: secret))
    case "read":
      result(read(ref: ref))
    case "delete":
      result(delete(ref: ref))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Keychain

  private func query(_ ref: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: SecureStorePlugin.service,
      kSecAttrAccount as String: ref,
    ]
  }

  private func write(ref: String, secret: String) -> NSNumber {
    let data = secret.data(using: .utf8)!
    var q = query(ref)
    q[kSecValueData as String] = data
    // 先删除旧值（SecItemUpdate 在部分场景下对 generic password 更稳）
    SecItemDelete(q as CFDictionary)
    let status = SecItemAdd(q as CFDictionary, nil)
    return NSNumber(value: status == errSecSuccess)
  }

  private func read(ref: String) -> String? {
    var q = query(ref)
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(q as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  @discardableResult
  private func delete(ref: String) -> NSNumber {
    let status = SecItemDelete(query(ref) as CFDictionary)
    return NSNumber(value: status == errSecSuccess || status == errSecItemNotFound)
  }
}
