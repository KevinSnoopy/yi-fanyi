# macOS 实机验证 Checklist（T-020 收尾）

> Round-4 准备包② · 配套 [`app/tool/macos_verify.sh`](../app/tool/macos_verify.sh)（一键脚本，自动完成构建 + 日志采集 + 逐步引导）与 [`docs/method-channel-contract.md`](./method-channel-contract.md)（契约核对，本 checklist 的「已知风险」均出自该表 §5）。
>
> **诚实口径**：macOS 原生壳八个 Swift 文件 + 本轮契约修复（B1 双引擎 / B2 反向事件）**均未实机编译**。本 checklist 的目标是一次真机会话拿到全部验证数据，失败项按「失败采集」归档贴回即可，不要求当场修完。

## 使用方式

- **推荐**：真机上 `bash app/tool/macos_verify.sh`，脚本会把下面的每一步作为交互引导打印，你只需按提示操作 + 回车，全部日志自动归档 `logs/macos-verify-<时间戳>/`。
- 手动逐项验证亦可：按下表执行，日志用 `flutter run -d macos 2>&1 | tee run.log` + `log stream --process '译语' --style compact` 双路采集。
- 每步的「失败采集」就是贴回日志的最小集合——**失败时把采集到的文件整包贴回，不要只贴一句话**。

## 0. 前置条件

- [ ] macOS 13+，Xcode 15+（`xcode-select -p` 有输出）
- [ ] Flutter SDK 可用：`flutter --version` ≥ 3.47
- [ ] 首次运行前：`cd app && flutter pub get`
- [ ] 准备一个 OpenAI 兼容 Key（或本地 Ollama，验证零 Key 链路）

## 1. 双构建（P0 · 决定后续一切）

| 步骤 | 命令 | 预期 |
|---|---|---|
| 1.1 | `flutter build macos --debug` | ✓ Built build/macos/Build/Products/Debug |
| 1.2 | `flutter build macos --release` | ✓ Built build/macos/Build/Products/Release |

**预期失败模式**（对应契约修复）：

| 症状 | 含义 | 采集 |
|---|---|---|
| `AppDelegate.swift` 编译错（`contentViewController as? FlutterViewController` 等） | 本轮 B1 修复与 Xcode 版本 API 差异 | build log 全文 |
| 8 个 Swift 文件任一类型错误（`AXUIElement as!`、`AXIsAttributeSettable(..., nil)`） | 契约表 R9 | build log 全文 |
| `generated_plugins_registrant` 重复定义 | B1 未生效（还是两个引擎都注册） | build log 全文 |

## 2. 启动 + 通道连通（P0 · 本轮修复的直接验证）

- [ ] 2.1 `flutter run -d macos` 启动，无 `MissingPluginException` 刷屏
- [ ] 2.2 菜单栏出现「译」图标（LSUIElement 生效，Dock **无**图标）
- [ ] 2.3 Tab I 模型配置填 Key 保存 → 无降级提示（状态栏应显示「系统密钥串」而非「混淆降级」）

> **判定意义**：2.3 通过 = 契约修复 B1（双引擎）生效——MethodChannel 已挂在 Dart isolate 所在引擎上。

失败采集：`flutter-run.log` 搜 `MissingPluginException`、`PlatformException`；`log-stream.log` 搜 `MethodChannel`。

## 3. 六项原生能力验证

### ① Keychain 存取（ADR-001 keyRef 链路）

- [ ] Key 保存成功；`security find-generic-password -s "com.linguaflow.keys"` 能查到条目
- [ ] 退出重启 app → Key 仍可用（read 链路）
- [ ] 删除 Profile → Keychain 条目一并消失（delete 链路）

失败采集：`security` 命令输出 + flutter-run.log 相关行。

### ② Carbon 全局热键（RegisterEventHotKey）

- [ ] Tab J 显示「原生全局热键 N/N 生效」（非「进程内（Web 预览）」）
- [ ] 焦点在**其它 app**时按唤起热键 → 记录现象（有无反应都算数据）
- [ ] 改绑一个冲突组合（如 Spotlight 的 ⌘Space）→ 红字提示

**已知风险（预期内，勿当新 bug 排查）**：契约表 §3-B3 —— 热键事件到达 Dart 后无 UI 消费者，「按了没反应」如实记录即可。**关键判定**：`flutter-run.log` 里 hotkey 事件是否到达（若有 Dart 侧 print/日志）+ log-stream.log 是否有 Carbon 报错。

失败采集：Tab J 注册报告截图 + 两路日志相关行。

### ③ AX 注入写回（三级降级）

- [ ] 系统设置 → 隐私与安全性 → 辅助功能：勾选「译语」（首次触发 TCC）
- [ ] 备忘录选中文字 → Tab C 划词翻译 → 记录生效级别（①AX selectedText 直写 / ②AX value 覆盖 / ③剪贴板+⌘V）
- [ ] Tab A 成稿 → 「注入」写回焦点框

**已知风险**：沙盒下 ③CGEvent 合成 ⌘V 可能被系统丢弃（契约表 §6 拍板项）。**记录三级各自成败**——这是决定 Release 是否去 sandbox 的关键数据。

失败采集：目标 app 名 + 现象描述 + `log-stream.log` 搜 `AXError`。

### ④ NSPanel 悬浮窗

- [ ] Tab B 触发系统浮层 → 记录：①panel 是否弹出（边框/阴影/标题）②内容空白与否 ③关闭行为 ④连续触发是否叠层

**已知风险**：`attachFlutterView` 零调用（契约表 §5-R1）→ **大概率空白浮层**。数据用于拍板修复方案（独立 FlutterEngine vs 搬 view + 归位）。

### ⑤ StatusBar Popover

- [ ] 菜单栏「译」点击 → Popover 开合正常
- [ ] Popover 打开期间主窗口是否空白；关闭后焦点是否归还宿主 app（`popoverDidClose → NSApp.hide` 行为）

**已知风险**：同一 FlutterViewController 同时作为窗口 contentVC 与 Popover contentVC，view 归属可能抖动（契约表 §5 未单列，实测补数据）。

### ⑥ 权限引导（T-025 真实链路）

- [ ] Tab L 走到权限步 → 「打开系统设置」真实拉起（深链 `x-apple.systempreferences:…Privacy_Accessibility`）
- [ ] 授权后切走再切回 app（resumed）→ 权限状态自动刷新为「已授权」
- [ ] 「重新检测」手动触发可用

失败采集：深链落点截图（macOS 13+ 映射行为）+ flutter-run.log 搜 `openPermissionSettings`。

## 4. 附加观察项（有时间就做）

- [ ] 权限桩核对：麦克风未授权时 L 页显示什么（契约表 §5-R6：`hasMicPermission` 恒 true，预期误报「已授权」——确认后 Round-5 修）
- [ ] `notify()` 首次调用触发通知授权弹窗（Tab D 焦点变化 toast）
- [ ] release 构建的 app 双击启动（脱离 flutter run）全链复测 2/3 步

## 5. 结果回传约定

把 `logs/macos-verify-<ts>/` 整包（至少 `result-draft.md` + `flutter-run.log` + `log-stream.log` + `env.txt`）贴回。Agent 按：

1. 编译失败 → 按 build log 逐行修 Swift
2. 通道不通（2.3 失败）→ 复查 B1/B2 修复 + 双引擎残留
3. 能力项数据 → 更新 `docs/method-channel-contract.md` §5 风险表状态 → 制定 Round-5 Swift 修复清单（R1 浮层承载 / R3 overlayResult / R4 keyUp / R6 权限桩）

## 6. 覆盖矩阵（本轮准备包 vs 六项）

| 能力 | 契约核对（沙箱已完成） | 脚本步骤 | checklist | 风险预标 |
|---|---|---|---|---|
| Carbon 热键注册/冲突 | ✅ §2.2/§4 | 第 5 步 | ②/② | R2/R4 |
| AX 注入写回 | ✅ §2.2 | 第 6 步 | ③ | R5/沙盒 |
| Keychain（keyRef 链路） | ✅ §2.1 | 第 4 步 | ① | — |
| NSPanel 悬浮窗流式 | ✅ §2.2 | 第 7 步 | ④ | R1/R3/R7 |
| StatusBar 菜单 | ✅ §2.2 | 第 8 步 | ⑤ | VC 复用 |
| 权限引导 + resumed | ✅ §2.2 | 第 8 步 | ⑥ | R6 |
| entitlements/TCC | ✅ §6 | — | §0 + ③ | 沙盒拍板项 |
