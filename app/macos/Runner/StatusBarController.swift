import Cocoa
import FlutterMacOS

/// ADR-005 · macOS 菜单栏常驻控制器（Popover 范式，不是独立窗口 App）。
///
/// - 状态栏常驻「译」图标，点击弹 Popover（承载同一个 FlutterViewController）
/// - `LSUIElement = 1`：不出现 Dock 图标
/// - 双击 ⌥ / 点击菜单项 → 打开主窗口（设置、模型配置、历史）
final class StatusBarController: NSObject, NSPopoverDelegate {

  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let popover = NSPopover()
  private weak var flutterViewController: FlutterViewController?
  private weak var mainWindow: NSWindow?

  init(flutterViewController: FlutterViewController, mainWindow: NSWindow?) {
    self.flutterViewController = flutterViewController
    self.mainWindow = mainWindow
    super.init()

    if let button = statusItem.button {
      button.title = "译"
      button.action = #selector(togglePopover(_:))
      button.target = self
    }

    popover.contentSize = NSSize(width: 420, height: 620)
    popover.behavior = .transient
    popover.animates = true
    popover.delegate = self
    popover.contentViewController = flutterViewController
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  /// 热键「打开主窗口」。
  func openMainWindow() {
    mainWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  /// 浮层请求（T-022）：把 Flutter 视图搬到系统浮层里显示。
  func requestOverlay(_ request: [String: Any]) -> Bool {
    // 由 NativeBridgePlugin 的 OverlayPanelController 承担真正显示；
    // 这里只保证 Popover 已收起，避免两个浮层叠在一起。
    if popover.isShown { popover.performClose(nil) }
    return true
  }

  func popoverDidClose(_ notification: Notification) {
    // 释放焦点，交还给宿主应用（PRD §4 规则 4：不抢焦点）
    NSApp.hide(nil)
  }
}
