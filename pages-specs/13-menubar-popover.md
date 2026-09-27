# 13 · 托盘/菜单栏菜单（ADR-005 Popover 范式）— PRD §6 #13

实现：**原生壳** `app/macos/Runner/StatusBarController.swift`（NSStatusItem + NSPopover）+ `AppDelegate.swift`；Flutter 侧无独立 Tab（Popover 承载与主窗口同一个 FlutterViewController）。
状态：**未实机验证**（准备包覆盖：checklist ⑤；契约风险见 method-channel-contract.md §5）。

## 原生侧字段表

| 字段 | 类型 | 默认值 | 来源 | 交互 |
|---|---|---|---|---|
| `statusItem` | NSStatusItem | variableLength | 运行时 | 按钮标题「译」（文字，非图标）；action=togglePopover |
| `popover` | NSPopover | contentSize 420×620 / behavior=.transient / animates | 运行时 | 点击状态栏开合；点击外部自动关（transient） |
| `popover.contentViewController` | FlutterViewController | 与主窗口同一个实例（B1 修复后成立） | — | Popover 内即完整 Flutter UI（AppShell 任意 Tab） |
| `popoverDidClose` | 回调 | `NSApp.hide(nil)` | — | 关闭后把焦点交还宿主 app（PRD §4 规则 4 不抢焦点） |
| `openMainWindow()` | 方法 | makeKeyAndOrderFront + activate | — | 菜单项 / 双击 ⌥ 打开主窗口（IBAction `openMainWindow(_:)` 连 MainMenu.nib——**nib 连线未实机验证**） |
| `requestOverlay(_:)` | 方法 | 收起 Popover（防浮层叠放）→ true | — | T-022 浮层请求前置；**当前无调用方**（记录） |

## PRD §6 #13 要求 vs 现状

| 要求 | 现状 | 口径 |
|---|---|---|
| 最近一条译文 + 复制/注入按钮（Popover 补全，v6 已画） | Popover 内容=整个 Flutter AppShell，**无「最近译文」专用首页**；最近译文可经 Tab H 历史列表查看 | ⚖️ 待拍板：a) Popover 直开 Tab A（当前行为）b) 加专用「菜单栏首页」Tab（最近译文 + 快捷动作） |
| LSUIElement 无 Dock 图标 | Info.plist LSUIElement=true | 实现为准（待实机确认） |
| 双击 ⌥ 打开主窗口 | 仅 openMainWindow 挂点，无双击 ⌥ 监听（需 R4 的输入监听通道） | ⚖️ 待拍板实装方式 |
