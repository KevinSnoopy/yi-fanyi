import Carbon.HIToolbox
import Cocoa

/// T-024 · macOS 全局热键管理器（Carbon RegisterEventHotKey）。
///
/// 与 Dart 侧 [HotkeyManager] 的分工：
/// - Dart 负责冲突检测、展示串、持久化
/// - 原生只认 wire 串（`ctrl+alt+space` / `fn` / `alt+d` …），按下即回抛 hotkey 事件
///
/// 权限：全局热键需「辅助功能」授权；未授权时 RegisterEventHotKey 仍会成功但
/// 部分场景收不到事件，由 [permissionStatus] 暴露给 Dart 侧引导。
final class HotkeyManager {

  /// 热键事件回调（id + 是否按下）。
  var onTrigger: ((String, Bool) -> Void)?

  private var hotKeyRefs: [String: EventHotKeyRef] = [:]
  private var eventHandler: EventHandlerRef?
  private var specs: [[String: Any]] = []

  /// 注册热键。spec: {"id": "hk-b", "trigger": "alt+space", "holdToRecord": false}
  @discardableResult
  func register(specs: [[String: Any]]) -> Bool {
    unregisterAll()
    self.specs = specs
    installEventHandlerIfNeeded()

    for spec in specs {
      guard let id = spec["id"] as? String,
        let trigger = spec["trigger"] as? String, !trigger.isEmpty,
        let combo = HotkeyCombo.parse(trigger)
      else { continue }

      let hotKeyID = EventHotKeyID(signature: signature, id: UInt32(abs(id.hashValue) % UInt32.max))
      var ref: EventHotKeyRef?
      let status = RegisterEventHotKey(
        combo.keyCode, combo.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
      if status == noErr, let ref = ref {
        hotKeyRefs[id] = ref
        idByKeyID[Int(hotKeyID.id)] = id
      }
    }
    return !hotKeyRefs.isEmpty
  }

  func unregisterAll() {
    for (_, ref) in hotKeyRefs {
      UnregisterEventHotKey(ref)
    }
    hotKeyRefs.removeAll()
    idByKeyID.removeAll()
  }

  private let signature: OSType = 0x4C46_4657  // 'LFFW'
  private var idByKeyID: [Int: String] = [:]

  private func installEventHandlerIfNeeded() {
    guard eventHandler == nil else { return }
    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let selfPtr = Unmanaged.passUnretained(self).toOpaque()
    InstallEventHandler(
      GetApplicationEventTarget(), { _, event, userData -> OSStatus in
        guard let event = event, let userData = userData else {
          return OSStatus(eventNotHandledErr)
        }
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &hotKeyID)
        guard status == noErr else { return OSStatus(eventNotHandledErr) }
        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotKey(keyID: Int(hotKeyID.id))
        return noErr
      }, 1, &eventType, selfPtr, &eventHandler)
  }

  /// Carbon 只给「按下」事件；按住型语音键（Fn）的「松开」由 Dart 侧应用层
  /// KeyUp 补齐（Fn 单键无法作为 Carbon 热键注册，需在 App 内监听）。
  private func handleHotKey(keyID: Int) {
    guard let id = idByKeyID[keyID] else { return }
    onTrigger?(id, true)
  }

  deinit {
    unregisterAll()
    if let handler = eventHandler {
      RemoveEventHandler(handler)
    }
  }
}

/// wire 串 → Carbon 键码 + 修饰键。
struct HotkeyCombo {
  let keyCode: UInt32
  let modifiers: UInt32

  /// 解析 `ctrl+alt+shift+meta+fn+<key>`（顺序无关，大小写不敏感）。
  static func parse(_ wire: String) -> HotkeyCombo? {
    var mods: UInt32 = 0
    var keyToken: String?
    for token in wire.lowercased().split(separator: "+").map(String.init) {
      switch token {
      case "ctrl", "control": mods |= UInt32(controlKey)
      case "alt", "option": mods |= UInt32(optionKey)
      case "shift": mods |= UInt32(shiftKey)
      case "meta", "cmd", "command", "win": mods |= UInt32(cmdKey)
      case "fn": keyToken = keyToken ?? "fn"
      default: keyToken = token
      }
    }
    guard let key = keyToken, let code = keyCode(for: key) else { return nil }
    return HotkeyCombo(keyCode: code, modifiers: mods)
  }

  static func keyCode(for key: String) -> UInt32? {
    let map: [String: Int] = [
      "space": kVK_Space,
      "enter": kVK_Return,
      "escape": kVK_Escape,
      "tab": kVK_Tab,
      "fn": kVK_Function,
      "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E,
      "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J,
      "k": kVK_ANSI_K, "l": kVK_ANSI_L, "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O,
      "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
      "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X, "y": kVK_ANSI_Y,
      "z": kVK_ANSI_Z,
      "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4,
      "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9,
    ]
    guard let code = map[key] else { return nil }
    return UInt32(code)
  }
}
