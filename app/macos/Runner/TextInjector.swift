import ApplicationServices
import Cocoa

/// T-022 / 流程 A·D 写回 · macOS 文本注入器。
///
/// 双通道降级（对齐 PRD §4 规则「不抢焦点、不打断」）：
/// 1. **AX 直写**：取焦点元素的 AXUIElement，设置 selectedText / value —— 最快且保留撤销栈
/// 2. **剪贴板 + ⌘V**：AX 不可用时，暂存剪贴板 → 写入译文 → 发送 ⌘V → 还原剪贴板
///
/// 权限：需要「辅助功能」（AXIsProcessTrusted）；未授权时返回 false 由 Dart 侧引导。
final class TextInjector {

  /// 是否具备辅助功能权限（供权限引导展示）。
  static var isTrusted: Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  /// 读取当前选中文本（流程 C/D 划词取词）。
  static func readSelection() -> String? {
    guard isTrusted else { return nil }
    var element: AXUIElement?
    guard let systemWide = AXUIElementCreateSystemWide() as AXUIElement? else { return nil }
    var focused: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(
        systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
      let focusedElement = focused
    else { return nil }
    element = (focusedElement as! AXUIElement)

    var selectedValue: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(
        element!, kAXSelectedTextAttribute as CFString, &selectedValue) == .success,
      let text = selectedValue as? String, !text.isEmpty
    else { return nil }
    return text
  }

  /// 把文本写回当前焦点输入框（替换选中区；无选中则插入到光标处）。
  @discardableResult
  static func inject(_ text: String) -> Bool {
    guard isTrusted else { return false }

    var focused: CFTypeRef?
    let systemWide = AXUIElementCreateSystemWide()
    guard
      AXUIElementCopyAttributeValue(
        systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
      let element = focused
    else { return false }
    let axElement = element as! AXUIElement

    // ① 优先：替换当前选区
    if AXUIElementSetAttributeValue(
      axElement, kAXSelectedTextAttribute as CFString, text as CFTypeRef) == .success
    {
      return true
    }

    // ② 退而求其次：整体覆盖 value（多行输入框/文本域）
    if AXIsAttributeSettable(axElement, kAXValueAttribute as CFString, nil),
      AXUIElementSetAttributeValue(
        axElement, kAXValueAttribute as CFString, text as CFTypeRef) == .success
    {
      return true
    }

    // ③ 最后：剪贴板 + ⌘V（还原原剪贴板，避免污染用户数据）
    return pasteViaClipboard(text)
  }

  private static func pasteViaClipboard(_ text: String) -> Bool {
    let pasteboard = NSPasteboard.general
    let original = pasteboard.string(forType: .string)
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    let source = CGEventSource(stateID: .combinedSessionState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // V
    keyDown?.flags = .maskCommand
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
    keyUp?.flags = .maskCommand
    keyDown?.post(tap: .cgAnnotatedSessionEventTap)
    keyUp?.post(tap: .cgAnnotatedSessionEventTap)

    // 异步还原：粘贴是异步生效的，稍后恢复用户原剪贴板
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      pasteboard.clearContents()
      if let original = original {
        pasteboard.setString(original, forType: .string)
      }
    }
    return true
  }
}
