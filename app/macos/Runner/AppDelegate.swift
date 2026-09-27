import Cocoa
import FlutterMacOS

/// 译语 LinguaFlow · macOS 原生壳入口（ADR-005 菜单栏范式）。
///
/// 装配顺序：
/// 1. 复用 MainFlutterWindow（nib）在 awakeFromNib 里建好的 FlutterViewController
///    —— **唯一实例**，Popover 与浮层共用；RegisterGeneratedPlugins 也只由
///    MainFlutterWindow 调一次（重复调用会注册到第二个引擎上，Dart isolate
///    跑在 MainFlutterWindow 的引擎里，通道将全部 MissingPluginException）
/// 2. 自研插件（NativeBridge / SecureStore）挂到**同一引擎**的 messenger
/// 3. 挂菜单栏 StatusBarController（LSUIElement=1，无 Dock 图标）
@main
class AppDelegate: FlutterAppDelegate {

  private var flutterViewController: FlutterViewController!
  private var statusBar: StatusBarController?

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // ① 复用 nib 建好的引擎（awakeFromNib 先于本回调执行，contentViewController 已就绪）
    let mainWindow =
      NSApp.windows.first { $0 is MainFlutterWindow } as? MainFlutterWindow
    if let vc = mainWindow?.contentViewController as? FlutterViewController {
      flutterViewController = vc
      // RegisterGeneratedPlugins 已在 MainFlutterWindow.awakeFromNib 调过，勿重复调用
    } else {
      // 兜底（nib 未就绪，不应发生）：自建引擎并自行注册生成插件
      flutterViewController = FlutterViewController()
      RegisterGeneratedPlugins(registry: flutterViewController)
    }

    // ② 自研 MethodChannel 插件 —— 必须挂在 Dart isolate 所在的引擎上
    if let registrar = flutterViewController.registrar(forPlugin: "NativeBridgePlugin") {
      NativeBridgePlugin.register(with: registrar)
    }
    if let registrar = flutterViewController.registrar(forPlugin: "SecureStorePlugin") {
      SecureStorePlugin.register(with: registrar)
    }

    // ③ 菜单栏常驻 + 主窗口（设置页）按需显示
    statusBar = StatusBarController(
      flutterViewController: flutterViewController,
      mainWindow: mainWindow ?? NSApp.windows.first)

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
