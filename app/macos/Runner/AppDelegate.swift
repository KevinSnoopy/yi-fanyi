import Cocoa
import FlutterMacOS

/// 译语 LinguaFlow · macOS 原生壳入口（ADR-005 菜单栏范式）。
///
/// 装配顺序：
/// 1. 建 FlutterViewController（唯一实例，Popover 与浮层共用）
/// 2. 注册插件 + 两个 MethodChannel 插件（native / secure）
/// 3. 挂菜单栏 StatusBarController（LSUIElement=1，无 Dock 图标）
@main
class AppDelegate: FlutterAppDelegate {

  private var flutterViewController: FlutterViewController!
  private var statusBar: StatusBarController?

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // ① Flutter 引擎（Popover / 浮层共用一个 VC，保证 UI 状态连续）
    flutterViewController = FlutterViewController()
    RegisterGeneratedPlugins(registry: flutterViewController)

    // ② 原生桥插件（全局热键 / 文本注入 / 浮层 / 通知 / Keychain）
    if let registrar = flutterViewController.registrar(forPlugin: "NativeBridgePlugin") {
      NativeBridgePlugin.register(with: registrar)
    }
    if let registrar = flutterViewController.registrar(forPlugin: "SecureStorePlugin") {
      SecureStorePlugin.register(with: registrar)
    }

    // ③ 菜单栏常驻 + 主窗口（设置页）按需显示
    let mainWindow =
      NSApp.windows.first { $0 is MainFlutterWindow }
      ?? NSApp.windows.first
    statusBar = StatusBarController(
      flutterViewController: flutterViewController,
      mainWindow: mainWindow)

    super.applicationDidFinishLaunching(aNotification)
  }

  /// 菜单项 / 双击 ⌥「打开主窗口」。
  @IBAction func openMainWindow(_ sender: Any?) {
    statusBar?.openMainWindow()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // 菜单栏 App：最后一个窗口关闭后**不退出**（ADR-005）
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
