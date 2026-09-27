# MethodChannel 契约核对表（macOS 实机验证前置检查）

> T-020 收尾 · Round-4（2026-09-27）。逐通道比对 **Dart 侧实现**（`app/lib/services/{native_bridge,secure_store,system_trigger,service_scope}.dart`）与 **macOS 原生壳八个 Swift 文件**（`app/macos/Runner/`）的实际行为。
> 口径：以「实机上这条调用能不能走通」为标准，不只看签名。发现不一致的条目已当场修复（见 §3），无法在沙箱拍板的结构问题如实标注为「实机验证重点」（见 §5）。

## 1. 通道总览

| 通道 | Dart 侧 | Swift 侧 | 方法数（正向） | 反向事件 | 结论 |
|---|---|---|---|---|---|
| `linguaflow/secure` | `ChannelSecureStore` | `SecureStorePlugin.swift` | 3 | 无 | ✅ 契约一致 |
| `linguaflow/native` | `ChannelNativeBridge` | `NativeBridgePlugin.swift` | 11 | `hotkey` / `overlayResult` | ⚠️ 契约一致，**接线有 2 处 P0 缺陷（已修）+ 3 处结构性风险（待实机）** |

## 2. 逐方法明细

### 2.1 `linguaflow/secure`（Keychain，ADR-001 链路）

| 方法 | Dart 请求 | Swift 处理 | 返回 → Dart 消费 | 一致性 |
|---|---|---|---|---|
| `write` | `{'ref': String, 'secret': String}`，期待 `void` | `args["ref"]`/`args["secret"]` guard 必填；`SecItemDelete`（清旧值）+ `SecItemAdd`，service=`com.linguaflow.keys`，account=ref | `NSNumber(Bool)` → `invokeMethod<void>`（忽略返回值） | ✅ |
| `read` | `{'ref': String}`，期待 `String?` | `SecItemCopyMatching` + `kSecMatchLimitOne` | `String?`（无值/失败返回 nil → Dart null） | ✅ |
| `delete` | `{'ref': String}`，期待 `void` | `SecItemDelete`（`errSecItemNotFound` 也算成功） | `NSNumber(Bool)` → 忽略 | ✅ |
| 错误路径 | — | 参数缺失 → `FlutterError("bad_args")` → Dart `PlatformException` | `DelegatingSecureStore` **只捕获 `MissingPluginException`**，`PlatformException` 会向上抛 | ⚠️ 理论缺口：正常调用不触发（ref 恒由 `keyRefFor(profileId)` 生成）；若实机日志出现 `bad_args` 再修 |

Dart 调用方（`app_store.dart`）：`addProfileWithKey` 写 → `readKey` 读 → `removeProfileWithKey` 连带删。Key 明文只出现在 SecureStore，Profile 只留 `keyRef` —— 与 Swift 端 `kSecAttrAccount=ref` 一一对应。✅

### 2.2 `linguaflow/native`（热键 / 注入 / 浮层 / 通知）

| 方法 | Dart 请求 | Swift 处理 | 返回 → Dart 消费 | 一致性 |
|---|---|---|---|---|
| `registerHotkeys` | `{'specs': [{'id','trigger','holdToRecord'}]}`，期待 `bool` | 逐条 `HotkeyCombo.parse(trigger)`（ctrl/alt/shift/meta/fn+键名 → Carbon 键码）→ `RegisterEventHotKey`；忽略 `holdToRecord` 字段 | `bool`（= 至少一条注册成功）→ `HotkeyManager.registerAll` 记入报告 | ✅（`holdToRecord` 被忽略：见 §5-R4） |
| `unregisterHotkeys` | 无参，期待 `bool` | `unregisterAll()`（先清理 refs，再 `RemoveEventHandler` 由 deinit 兜底） | `true` | ✅ |
| `injectText` | `{'text': String}`，期待 `void` | `TextInjector.inject`：①AX `selectedText` 直写 ②AX `value` 覆盖 ③剪贴板+CGEvent ⌘V（0.4s 还原） | Swift 返回 `Bool`，Dart 按 `void` 接（丢弃）——降级判定交给 `FallbackNativeBridge`（只看是否抛异常） | ✅ 但**返回值浪费**：注入实际失败（返回 false）时 Dart 不会走剪贴板降级。待实机验证后决定是否改为 `Future<bool>` 语义（见 §5-R5） |
| `readSelection` | 无参，期待 `String?` | `AXUIElementCopyAttributeValue(kAXSelectedTextAttribute)`；未授权/无选区返回 nil | `String?` | ✅ |
| `foregroundApp` | 无参，期待 `String?` | `NSWorkspace.shared.frontmostApplication?.localizedName` | `String?` | ✅（Dart 侧暂无 UI 消费者，P1 挂点） |
| `hasMicPermission` | 无参，期待 `bool` | **恒返回 `true`**（注释：AVFoundation 授权探测待补） | `bool` | ⚠️ 桩实现：实机麦克风未授权时误报。见 §5-R6 |
| `permissionStatus` | 无参，期待 `Map<String,bool>` | `{'accessibility': AXIsProcessTrusted, 'inputMonitoring': =accessibility（桩）, 'microphone': true（桩）}` | Map → Dart `e.value == true` 逐项收敛 | ⚠️ inputMonitoring/microphone 为桩值，accessibility 真实。见 §5-R6 |
| `openPermissionSettings` | `{'kind': 'accessibility'\|'inputMonitoring'\|'microphone'}`，期待 `void` | `x-apple.systempreferences:com.apple.preference.security?Privacy_*` 三分支 `NSWorkspace.open` | `nil` → void | ✅（macOS 13+ 深链映射到新系统设置，实机验证见 checklist 第 6 步） |
| `showOverlay` | `SystemOverlaySpec.toMap()`（id/kind/text/placeholder/anchorX/anchorY/width/height），期待 `bool` | 只读 `id/width/height/anchorX/anchorY`，**忽略 kind/text/placeholder**；建 NSPanel（`.nonactivatingPanel` + 淡入上移 8px/0.18s） | `true` → `SystemTriggerService.request` 判定 `TriggerMode.system` | ✅ 契约成立；但**浮层内容**依赖「Dart 收到 showOverlay 后切页面 + 原生把 Flutter 视图搬进 panel」——该承载链路当前断线，见 §5-R1 |
| `hideOverlay` | `{'id': String}`，期待 `void` | 淡出 0.14s + `orderOut`；**未把 flutterView 移回主窗口、未关闭面板实例**（`self.panel = nil` 后旧 panel 交由 ARC） | `nil` → void | ⚠️ 与 R1 同源，见 §5-R1 |
| `notify` | `{'title','body'}`，期待 `void` | `UNUserNotificationCenter.requestAuthorization([.alert,.sound])` → `add`；未授权静默丢弃 | `nil` → void | ✅（首次调用触发系统通知授权弹窗，checklist 第 7 步） |

### 2.3 反向事件（Swift → Dart）

| 事件 | Swift 发送 | Dart 接收 | 一致性 |
|---|---|---|---|
| `hotkey` | `NativeBridgePlugin.register` 里挂 `hotkeys.onTrigger` → `invokeMethod("hotkey", {'id': String, 'down': Bool})`；**只发 down=true**（Carbon 只回调 pressed） | `SystemTriggerService._onNativeCall` case `'hotkey'` → `results` 流（`confirmed = down == true`） | ✅ 签名一致；❗但见 §3-B2 与 §5-R2/R4 |
| `overlayResult` | **Swift 端无任何发送点**（panel 的 `.closable` 关闭按钮、面板内动作均未回传） | `_onNativeCall` case `'overlayResult'` 已备好（`{'id','action','text','confirmed'}`） | ❌ 单向缺口：系统浮层内发生的任何动作 Dart 永远收不到。B 流程「输入完成→写回」在原生模式下无回传通道。见 §5-R3 |

## 3. 核对发现与处置（本轮已修 2 处）

### B1 ·【P0 · 已修】双 FlutterViewController / RegisterGeneratedPlugins 双调用 → 全部通道实机必失效

- **现象**：`MainFlutterWindow.awakeFromNib` 建了一个 VC 并注册生成插件（Dart isolate 跑在这里）；`AppDelegate.applicationDidFinishLaunching` 又 `FlutterViewController()` 新建第二个引擎并 `RegisterGeneratedPlugins`，随后 `NativeBridgePlugin.register`/`SecureStorePlugin.register` 都注册在**第二个引擎**的 messenger 上。
- **后果**：实机上 Dart 调 `linguaflow/secure`、`linguaflow/native` 全部 `MissingPluginException` → `DelegatingSecureStore`/`FallbackNativeBridge` **静默降级**（Key 不进 Keychain、热键不注册、AX 注入不可用），UI 不崩但原生能力全灭，且从日志很难第一时间定位。
- **修复**：`AppDelegate.swift` 改为复用 `MainFlutterWindow.contentViewController`（唯一实例），删除重复的 VC 创建与 `RegisterGeneratedPlugins` 调用；两个自研插件挂到同一引擎。回执 `2026-09-27-01` 中「Popover 与浮层共用一个 VC」的设计意图由此才真正成立。

### B2 ·【P0 · 已修】反向 hotkey 事件 handler 从未注册

- **现象**：`SystemTriggerService` 构造参数支持 `channel`，但 `LfServices.bootstrap` 组装时**没传**（`SystemTriggerService(bridge: effectiveBridge)`），`setMethodCallHandler` 未挂。
- **后果**：即使 B1 修好、Swift 侧 Carbon 回调正常 `invokeMethod("hotkey", ...)`，Dart 侧也无人接收——全局热键触发后 UI 毫无反应。
- **修复**：`bootstrap` 增加 `nativeChannel` 参数；`main.dart` 非 Web 时传 `MethodChannel('linguaflow/native')`。测试不受影响（所有测试直接构造 `SystemTriggerService`，不经 bootstrap）。

### B3 ·【P1 · 本轮标注，未修】`trigger.results` 流全库无订阅者

原生 hotkey 事件进入 `SystemTriggerService.results` 广播流后，`flow_page.dart` / `flow_demos.dart` 均只订阅**进程内** `hotkeyEvents`（`HardwareHotkeyListener`），无人消费 `results`。这意味着 B2 修复后事件能到 Dart，但**仍不会触发任何页面动作**。
处置理由：正确做法需要产品决策（把 `results` 里的 hotkey 动作桥接进 `hotkeyEvents` 语义流，还是让宿主统一订阅），且必须先有实机日志确认原生事件确实到达，避免修在错误的层。已列入 checklist 第 4 步观察项与 Round-5 候选。

## 4. wire 串 / 键码两端一致性（T-024 重点）

| 项 | Dart（`models.dart HotkeyCombo.wire`） | Swift（`HotkeyCombo.parse`） | 结论 |
|---|---|---|---|
| 修饰键名 | `ctrl/alt/shift/meta/fn`（枚举 name 顺序拼接） | 接受 `ctrl/control`、`alt/option`、`shift`、`meta/cmd/command/win`、`fn` 特判 | ✅ 超集兼容 |
| 主键名 | `space/enter/escape/tab/fn` + 单字符 `a-z0-9`（`normalizeKey` 归一） | 同集映射到 `kVK_*` | ✅ |
| 「按住 Fn」 | `wire = "fn"`（纯修饰键） | `parse("fn")` → `kVK_Function` + 0 修饰键 → `RegisterEventHotKey` 对 Fn 键**大概率失败**（Fn 是硬件级键，不过应用事件循环）——Swift 注释已自知 | ⚠️ 失败时 `register` 返回 false → Dart 报告 `native: false` → 进程内兜底接管。实机需确认该回退路径（checklist 第 4 步） |
| `hold`/`doubleTap` 语义 | `HotkeySpec.holdToRecord` 单独下发 | Swift 忽略该字段；只发 down=true | ⚠️ R4 |
| 冲突表 | `kReservedCombos`（Spotlight/输入法/截屏/Alfred…） | 无（原生只认注册成败） | ✅ 分层设计如此 |

## 5. 结构性风险清单（实机验证重点，本轮不擅自重构）

| # | 等级 | 风险 | 位置 | 验证/修复路径 |
|---|---|---|---|---|
| R1 | P0 | **浮层承载链路断线**：`OverlayPanelController.attachFlutterView` 全工程零调用 → `showOverlay` 弹出的 NSPanel 内容为空白；且设计上「把主 FlutterView 搬进 panel」会让主窗口空白、`hide` 后也不搬回 | `OverlayPanel.swift` / `AppDelegate.swift` / `NativeBridgePlugin.swift:31` | checklist 第 3 步实机确认后拍板：方案 A 浮层挂独立 FlutterEngine（隔离但状态不同步）；方案 B 保留搬 view 但补 hide 归位 + 主窗口冻结页。**需实机数据** |
| R2 | P1 | **`trigger.results` 无消费者**（见 §3-B3） | `service_scope.dart` / 各页面 | 实机确认 hotkey 事件到达后，把 `results` 的 hotkey 桥接到 `hotkeyEvents` 或宿主统一订阅 |
| R3 | P1 | **`overlayResult` Swift 无发送点**：panel 关闭按钮/面板内动作不回传，B 流程原生模式下「输入完成→写回」无闭环 | `OverlayPanel.swift`（`.closable` 无回调） | 补 `NSWindowDelegate windowWillClose` → `invokeMethod("overlayResult", {'action':'close'})`；面板内文本动作需要新增原生桥方法（建议 Round-5） |
| R4 | P1 | **按住型热键无 up 事件**：Carbon 只回调 pressed，`down=false` 永远收不到；后台场景（app 非焦点）进程内 `HardwareHotkeyListener` 也收不到 KeyUp → 流程 A「按住说话、松手成稿」的全局触发版本无法结束录音 | `HotkeyManager.swift:84-87`（注释已自知） | 需补 CGEventTap（keyUp 监听，需「输入监控」TCC 授权）或改用 NSEvent global monitor。实机先验证：前台按住场景由进程内 KeyUp 补齐是否够用 |
| R5 | P2 | `injectText` 返回值被 Dart 丢弃：AX 三级降级全失败（返回 false）时，Dart 侧 `FallbackNativeBridge` 不知道失败，不会走「写剪贴板」兜底 | `native_bridge.dart:150` | 实机确认后把 `ChannelNativeBridge.injectText` 改 `Future<bool>` 并在 false 时降级 |
| R6 | P2 | **权限桩实现**：`hasMicPermission` 恒 true；`inputMonitoringGranted` 直接复用 `isTrusted`。首引导 L 页在麦克风未授权时会显示「已授权」 | `NativeBridgePlugin.swift:102-111` | 实机补 `AVCaptureDevice.authorizationStatus(.audio)` 与 `CGPreflightListenEventAccess()` |
| R7 | P2 | NSPanel 每次 `show` 新建实例、连续触发叠加多层浮层；`.closable` 手动关闭不通知 Dart | `OverlayPanel.swift:33` | 实机确认复现频率后改为单例复用 |
| R8 | P3 | `UInt32(abs(id.hashValue) % UInt32.max)`：`hashValue == Int.min` 时 `abs` 溢出 trap（概率 ~2⁻⁶³）；Swift hash 随机化导致跨运行 id 变化——仅运行期内自洽，无跨会话依赖，安全 | `HotkeyManager.swift:34` | 记录在案，可不修 |
| R9 | P3 | `TextInjector` 的 `as! AXUIElement` 强转、`AXIsAttributeSettable(..., nil)` 传 nil 指针——Swift/ObjC 混编语义上成立，但属脆弱写法，实机编译即验真 | `TextInjector.swift` | 编译过即通过；失败按 Xcode 报错修 |

## 6. Info.plist / Entitlements / TCC 核对（M1.4）

### Info.plist（`app/macos/Runner/Info.plist`）

| 项 | 值 | 核对结论 |
|---|---|---|
| `LSUIElement` | `true` | ✅ ADR-005 菜单栏范式，无 Dock 图标 |
| `NSMicrophoneUsageDescription` | 中文文案 | ✅ TCC 首次请求弹窗必需 |
| `NSInputMonitoringUsageDescription` | 中文文案 | ✅ 预留（当前代码无 CGEventTap 监听；R4 修复启用时生效） |
| `NSAppleEventsUsageDescription` | 文案写的是「辅助功能权限才能写入输入框」 | ⚠️ 该 key 管的是 AppleEvents（AppleScript/osascript）授权，与 AX 无关；文案张冠李戴。AX 授权走「系统设置→隐私与安全性→辅助功能」，无需 Info.plist key。建议下轮改为真实 AppleEvents 用途或删除 |

### Entitlements

| 项 | DebugProfile | Release | 核对结论 |
|---|---|---|---|
| `com.apple.security.app-sandbox` | ✅ true | ✅ true | ⚠️ **与 AX 写回/CGEvent 合成事件存在张力，需拍板**（下详） |
| `com.apple.security.network.client` | ✅ | ✅ | ✅ ADR-001 直连 BaseURL 必需 |
| `com.apple.security.network.server` | ✅（仅 Debug） | — | ✅ Flutter debug VM Service 需要 |
| `com.apple.security.cs.allow-jit` | ✅（仅 Debug） | — | ✅ Flutter debug JIT 需要（DartVM debug 模式） |
| `com.apple.security.device.audio-input` | ✅ | ✅ | ✅ 流程 A 录音必需 |
| AX / 输入监控专项 entitlement | 无 | 无 | ✅ 正确——macOS 无「AX entitlement」，AX 走 TCC「辅助功能」用户授权；entitlements 层不需要额外声明 |

**沙盒拍板项（⧗ 需用户决策，Agent 不代决）**：
- **沙盒内**：`AXUIElementSetAttributeValue` 写入其它 app 的输入框，在获得「辅助功能」TCC 授权后**部分可用**（Apple 对沙盒 app 的 AX 写限制无公开契约，实测为准）；而 **`CGEvent.post` 合成 ⌘V 在沙盒下大概率被系统丢弃**（合成输入事件与 App Sandbox 不兼容）→ `TextInjector` 第③级降级失效，注入成功率下降。
- **去沙盒**（Developer ID 分发，买断/自用工具的常见选择，ADR-002 口径）：三级降级全通，但失去沙盒保护、且 macOS 14+ 的 notarization 流程要多签 hardened runtime。
- 建议：本地实机验证阶段先**保留现状**（沙盒开），用 checklist 第 5 步实测三级注入各自成败；若③失效且流程 D 写回不可用，再决策 Release 去 sandbox。**本轮不改 entitlements 文件。**

### TCC 权限清单（实机首次运行会依次触发）

| 权限 | 触发动作 | 系统落点 |
|---|---|---|
| 麦克风 | 流程 A 按住说话 | 隐私与安全性 → 麦克风（有 Info.plist 文案） |
| 辅助功能 | `permissionStatus()` 自检 / 首次 AX 注入 | 隐私与安全性 → 辅助功能（勾选译语 app） |
| 通知 | `notify()` 首次调用 | 允许「译语」发送通知 |
| 输入监控 | 暂未触发（无 CGEventTap；R4 修复后） | 隐私与安全性 → 输入监控 |

## 7. 修复涉及文件（本轮）

```
app/macos/Runner/AppDelegate.swift   # B1：复用 MainFlutterWindow 的唯一引擎
app/lib/services/service_scope.dart  # B2：bootstrap 增加 nativeChannel 透传
app/lib/main.dart                    # B2：非 Web 传 MethodChannel('linguaflow/native')
docs/method-channel-contract.md      # 本表
```

> 诚实声明：以上 Swift/Dart 修改**未经过实机编译验证**（Linux 沙箱无 Xcode/macOS SDK）。B1 属结构性修正，逻辑上消除双引擎；实机 `flutter build macos` 时请优先观察 checklist 第 1 步的编译输出。
