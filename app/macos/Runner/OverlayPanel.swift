import Cocoa

/// T-022 · 系统级浮层（NSPanel）—— 悬浮窗 / 划词小窗 / 快捷面板。
///
/// 关键约束（PRD §4 规则 4 / ADR-005）：
/// - `.nonactivatingPanel` + `becomesKeyOnlyIfNeeded`：**不抢焦点**，宿主应用继续可输入
/// - 入场：淡入 + 上移 8px，≤180ms
/// - 浮层内容由 Flutter 侧渲染（Dart 收到 `showOverlay` 后切页面），原生只负责
///   「在哪儿显示 + 多大 + 何时关」，UI 仍是同一套 Flutter 代码（五端一致）
final class OverlayPanelController {

  private var panel: NSPanel?
  private var flutterView: NSView?

  /// 承载 Flutter 视图（AppDelegate 在启动时注入）。
  func attachFlutterView(_ view: NSView) {
    flutterView = view
  }

  /// 显示浮层。anchor 为屏幕坐标（nil = 鼠标旁 / 屏幕中下方）。
  func show(id: String, width: Double, height: Double, anchorX: Double?, anchorY: Double?) {
    let origin: NSPoint
    if let x = anchorX, let y = anchorY {
      origin = NSPoint(x: x, y: y)
    } else if let mouse = NSApp.currentEvent?.locationInWindow {
      origin = mouse
    } else {
      origin = NSPoint(x: 200, y: 200)
    }
    show(id: id, frame: NSRect(x: origin.x, y: origin.y, width: width, height: height))
  }

  func show(id: String, frame: NSRect) {
    let panel = NSPanel(
      contentRect: frame,
      styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .closable],
      backing: .buffered, defer: false)
    panel.title = "译语 · \(id)"
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.becomesKeyOnlyIfNeeded = true
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.titlebarAppearsTransparent = true
    panel.animationBehavior = .utilityWindow

    if let view = flutterView {
      view.frame = NSRect(origin: .zero, size: frame.size)
      panel.contentView?.addSubview(view)
    }

    // 入场：淡入 + 上移 8px（≤180ms，PRD §4 规则 4）
    panel.alphaValue = 0
    let target = frame
    panel.setFrameOrigin(NSPoint(x: target.origin.x, y: target.origin.y - 8))
    panel.orderFrontRegardless()
    NSAnimationContext.runAnimationGroup { ctx in
      ctx.duration = 0.18
      ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
      panel.animator().alphaValue = 1
      panel.animator().setFrameOrigin(target.origin)
    }

    self.panel = panel
  }

  func hide(id: String) {
    guard let panel = panel else { return }
    NSAnimationContext.runAnimationGroup { ctx in
      ctx.duration = 0.14
      panel.animator().alphaValue = 0
    } completionHandler: {
      panel.orderOut(nil)
    }
    self.panel = nil
  }

  var isVisible: Bool { panel?.isVisible ?? false }
}
