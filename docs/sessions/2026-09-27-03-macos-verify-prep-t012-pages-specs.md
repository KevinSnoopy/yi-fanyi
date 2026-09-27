# 会话回执 · 2026-09-27-03 · T-020 实机验证准备包 + T-011 收账 + T-012 页面字段级规格

> 多 Agent 接续协议留痕。本轮（Round-4）在 Linux 沙箱完成 macOS 实机验证的全部准备工作，
> 并按用户指令完成 T-011 追认收账与 T-012 字段级规格。
> **诚实声明：macOS 原生壳仍未实机编译（沙箱无 Xcode/macOS SDK），本轮修复 B1/B2 未经实机验证。**

## 领取任务

- **M1 · T-020 收尾**：实机验证准备包三件套（一键脚本 + 分步 checklist + MethodChannel 契约核对表，不一致即修）+ entitlements/TCC 顺带核对
- **M2 · T-011 收账**：TASKS.md 标 ✅ 并注记「由会话 10/11 实现覆盖」，不重做代码
- **M3 · T-012**：`pages-specs/` 13 页字段级规格（字段/类型/默认值/校验/来源/交互含错误态），冲突处标注「实现为准/待拍板」

## 环境恢复（Round-4 前置）

沙箱重置导致两项环境损坏，均已修复：

1. **DNS 劫持**：`/etc/hosts` 是 bind mount 会被还原，预写的 GitHub IP 消失 → git clone TLS 握手失败。修复：DoH（`dns.alidns.com/resolve`）解析 6 个 GitHub 域名真实 IP 写回 `/etc/hosts` + `~/.user_hosts`（持久化），`git -c http.version=HTTP/1.1` clone/push 均通
2. **Flutter SDK 消失**：`/opt/flutter-3.47` 不存在。修复：flutter-io.cn 镜像下载 `flutter_linux_3.47.5-stable.tar.xz` 解压恢复

## 交付明细

### M1-① `app/tool/macos_verify.sh` 一键验证脚本

8 步引导式验证（在真实 macOS 上执行）：

1. 环境自检（flutter / xcodebuild / macOS 版本）
2. `flutter build macos --debug` + `--release` 双构建（失败自动采集 `xcodebuild` 详细日志）
3. `flutter run -d macos` + `log stream --predicate 'process == "linguaflow"'` 双路日志采集
4-9. 六项原生能力分步交互引导：Keychain 读写 / Carbon 热键注册与触发 / AX 选区读取与三级降级注入 / NSPanel 悬浮窗 / StatusBar 菜单栏 / 四项 TCC 权限引导。每步给出「操作 → 预期 → 失败时采集什么」
10. 汇总归档 `result-draft.md`（含全部 log 片段），供回传分析

### M1-② `docs/macos-verify-checklist.md` 分步 checklist

0 前置条件 → 1 双构建（附预期失败模式表：证书/签名/deployment target）→ 2 启动 + 通道连通（**B1 修复判定点**：观察 MissingPluginException 是否消失）→ 3 六项能力（每项预标已知风险：R4 无 keyUp / R1 浮层承载 / R6 权限桩等）→ 4 附加观察（内存/启动耗时/菜单栏残留）→ 5 结果回传约定 → 6 覆盖矩阵（验证点 ↔ 代码位置 ↔ 风险编号）

### M1-③ `docs/method-channel-contract.md` 契约核对表（核心交付物）

逐通道逐方法比对 Dart 侧（`native_bridge.dart` / `secure_store.dart` / `system_trigger.dart`）与 8 个 Swift 文件（AppDelegate / MainFlutterWindow / NativeBridgePlugin / HotkeyManager / OverlayPanel / SecureStorePlugin / StatusBarController / TextInjector）：

- §2 明细表：`linguaflow/secure` 3 方法（read/write/delete）+ `linguaflow/native` 11 方法（permissionStatus / openPermissionSettings / registerHotkey / unregisterHotkey / readSelectedText / injectText / showOverlay / hideOverlay / showNotification / setStatusBarTitle / getFrontmostApp）+ 反向事件 2 个（hotkey / overlayResult）
- §3 发现三处：**B1（P0 已修）** / **B2（P0 已修）** / **B3（P1 标注）**：`trigger.results` 流全库无订阅者（成稿结果事件无人消费，待实机后决定接 UI 还是删接口）
- §4 wire 串一致性：Dart `HotkeyCombo.wire` vs Swift `HotkeyCombo.parse` 两端字段序一致 ✓
- §5 风险清单 R1–R9（详见下文「风险移交」）
- §6 Info.plist + entitlements + TCC 核对：用途声明齐全；发现 **NSAppleEventsUsageDescription 张冠李戴**（声明了 AppleEvents 用途但代码未发 AppleEvent，真正需要的辅助功能 TCC 不走该键，已标注不阻塞）；**沙盒拍板项**：App Sandbox 开启时 CGEvent 合成事件注入他进程可能被拒（`com.apple.security.temporary-exception` 需审慎），**未擅改 entitlements，留用户拍板**

### 契约修复 · B1（P0）：AppDelegate 双引擎

**问题**：`AppDelegate.applicationDidFinishLaunching` 里新建第二个 `FlutterViewController` 并重复调用 `RegisterGeneratedPlugins`。nib 加载 `MainFlutterWindow` 时已在 `awakeFromNib` 建好唯一引擎并注册过插件；第二个 VC 是**无 Dart isolate 的裸引擎**——自研插件（NativeBridgePlugin / SecureStorePlugin）挂上去后，Dart 侧全部 `MissingPluginException`。这正是「Flutter 多引擎」经典坑在 macOS 壳的具体形态。

**修复**（`app/macos/Runner/AppDelegate.swift` 重写）：

```swift
let mainWindow = NSApp.windows.first { $0 is MainFlutterWindow } as? MainFlutterWindow
if let vc = mainWindow?.contentViewController as? FlutterViewController {
  flutterViewController = vc   // 复用 nib 建好的唯一引擎，RegisterGeneratedPlugins 已在 awakeFromNib 调过，勿重复
} else {
  // 兜底：nib 异常时自建引擎并注册（保留原逻辑作为降级路径）
}
```

### 契约修复 · B2（P0）：反向事件通道断线

**问题**：Swift → Dart 的 hotkey / overlayResult 事件经 `linguaflow/native` 通道反向 `invokeMethod`，但 `main.dart` 只传了 `bridge`（FallbackNativeBridge 包 ChannelNativeBridge），**没有把 `MethodChannel('linguaflow/native')` 本体传给 `SystemTriggerService`** → 按下全局热键后 Swift 发事件，Dart 侧无人接收 → 热键永远无响应。

**修复**：

- `app/lib/services/service_scope.dart`：`bootstrap()` 新增 `nativeChannel` 参数，透传 `SystemTriggerService(bridge:, channel: nativeChannel)`；补 `import 'package:flutter/services.dart'`
- `app/lib/main.dart`：

```dart
final services = LfServices.bootstrap(
  store: store,
  bridge: kIsWeb ? NoopNativeBridge() : FallbackNativeBridge(ChannelNativeBridge()),
  nativeChannel: kIsWeb ? null : const MethodChannel('linguaflow/native'),
);
```

### M2 · T-011 收账

TASKS.md 中 T-011（Provider 适配层 Dart 接口定义）⬜ → ✅（2026-09-27 收账），注记：**实际由会话 10/11 实现**（ADR-007 统一接口 + OpenAI/Anthropic/Ollama/自定义 BaseURL 四 Provider + 66/66 测试），Round-4 追认收账，勿重做。符合预期：会话 10 在实现 T-021 时已按 ADR-007 完成 `TranslationProvider` 接口与四实现（超出原任务的「三实现」），接口定义与实现本就一体交付。

### M3 · T-012 · `pages-specs/` 字段级规格（15 文件）

以 `app/lib/ui/pages/` 六个 dart 文件实际实现为基准逐页盘点：

- **13 页**：01-recorder-pill（A）/ 02-floating-window（B）/ 03-selection-popover（C）/ 04-silent-replace（D）/ 05-ocr-window（E）/ 06-home（H）/ 07-providers（I）/ 08-hotkeys（J）/ 09-prefs-terms-skills（K）/ 10-onboarding（L）/ 11-mobile-app-privacy（M）/ 12-ios-keyboard（F? 移动键盘页）/ 13-menubar-popover（Popover 最近译文）
- **+2 皮肤**：n1-windows-skin / n2-android-skin（三端平移参照）
- 每份字段表含：字段名 / 类型 / 默认值 / 校验规则 / 来源（Profile | SecureStore | 运行时）/ 交互（含错误态）
- 冲突处理约定：**以实现为准**；实现与 v7 原型不一致处标 ⚖️，编号 C1–C16 汇总于 [`pages-specs/README.md`](../../pages-specs/README.md)（含 13+2 页映射表），**留用户拍板，Agent 不自行裁决**

## 回归验证

```
flutter analyze  → No issues found! (6.0s)
flutter test     → 00:18 +66: All tests passed!
```

B1/B2 修复引入的 `MethodChannel` import 已确认补齐，全量回归通过。macOS 侧因沙箱无 SDK 不可编译，见诚实声明。

## 风险移交（R1–R9，实机验证时重点观察）

| 编号 | 风险 | 等级 |
|---|---|---|
| R1 | 浮层承载断线：`attachFlutterView` 全库零调用，NSPanel 显示后内容可能空白 | P1 |
| R3 | `overlayResult` 反向事件 Swift 侧无发送点（通道通但无数据） | P1 |
| R4 | Carbon `RegisterEventHotKey` 只发 pressed 无 keyUp，按住型热键（流程 A）无法区分松开 | P1 |
| R5 | `injectText` 返回值被丢弃，注入失败静默 | P2 |
| R6 | 权限查询部分为桩（返回固定值），TCC 真实状态待实机确认 | P1 |
| R7 | NSPanel 重复创建风险（多次 showOverlay 未复用） | P2 |
| R8 | `Hashable.hashValue` 跨平台理论溢出（热键匹配用） | P3 |
| R9 | Swift 侧强转无保护（`as!`） | P2 |
| B3 | `trigger.results` 流全库无订阅者 | P1 |

## 遗留与下一步

- **macOS 实机验证**（最大遗留）：用户在真实 macOS 上跑 `bash app/tool/macos_verify.sh`，按 checklist 走六项，`result-draft.md` 回传后下轮分析日志修 Swift（重点 B3 / R1 / R3 / R4 / R6）
- **沙盒 entitlements 拍板**：App Sandbox × CGEvent 注入张力，见契约文档 §6
- **pages-specs C1–C16 拍板**：逐项定「实现为准 / 原型为准」
- **T-013 Design Token** 可平行动工（pages-specs 已给组件规格参照）
- **T-030 三端平移准备**：n1/n2 皮肤规格已就位，可盘点条件编译

## 诚实声明

1. **macOS 原生壳未实机编译**：本沙箱为 Linux，无 Xcode/macOS SDK。所有 Swift 改动仅保证语法与 API 层面正确（对照 Apple 官方文档），不构成「已验证」
2. **B1/B2 修复未经实机验证**：修复通过全量 Dart 回归（analyze 0 issue + test 66/66），但「MissingPluginException 消失」「热键事件可达」需实机跑 `macos_verify.sh` 步骤 2–3 才算验证
3. **准备包覆盖范围**：脚本/checklist/契约表覆盖静态可核对的全部维度（方法签名 / 通道名 / wire 格式 / entitlements 键 / Info.plist 用途声明）；运行时行为（热键延迟 / 注入成功率 / 浮层渲染）不在本轮覆盖内
4. T-011 收账为**追认**：代码由会话 10/11 交付，本轮仅核对接口与测试覆盖后落账，未改动 Provider 代码
