# T-030 三端平移准备 · 平台差异矩阵（Round-5 · M3）

> 盘点范围：`app/lib` 全库 + `app/` 平台目录。**只盘点不写平台代码**（T-030 实施仍待 T-022~T-025 实机验收后领取）。
> 皮肤参照：[`pages-specs/n1-windows-skin.md`](../pages-specs/n1-windows-skin.md) / [`pages-specs/n2-android-skin.md`](../pages-specs/n2-android-skin.md)。

## 1. 现状：平台分支全景（lib 全库扫描）

| 位置 | 分支点 | 现状 | 三端影响 |
|---|---|---|---|
| `main.dart:25/34/39` | `kIsWeb` ×3 | Web → NoopSecureStore / NoopNativeBridge / 无 nativeChannel | 桌面三端共用同一原生路径，无 Web 特有 UI 分支 |
| `services/hotkeys.dart:474` | `defaultTargetPlatform` | `currentHotkeyPlatform()` mac/win/linux 三态；Web 按 macOS 口径展示 | **逻辑已三端就绪**，仅缺原生注册实现 |
| `services/hotkeys.dart:248-352` | `kReservedCombos` | mac 6 组 / win 8 组 / linux 2 组已预置 | Linux 表最薄（2 组），平移时需补 GNOME/KDE 系统占用 |
| `models/models.dart:283/397/401` | `HotkeyPlatform` | 展示串 mac 用符号 / win 用单词 | linux 展示串缺失（回退 win 单词风格，可接受） |
| `overlays/recorder_pill.dart:30` | `winSkin` 参数 | Fluent 皮肤：隐藏「译」开关、显示 Win+H 提示 | 由 n1 皮肤页传入，真 Windows 壳需按平台置位 |
| `ui/pages/platform_skins.dart` | N/O 两个演示页 | WindowsDemoPage / AndroidDemoPage（演示序列） | 三端平移的 UI 规格已冻结 |

**结论**：Dart 侧平台耦合极低——全库仅 3 处 `kIsWeb` + 1 处 `defaultTargetPlatform`，无 `dart:io`/`dart:html`/条件 import。UI 层天然可平移；差异全部集中在**原生壳与插件**。

## 2. 平台目录现状

| 目录 | 状态 |
|---|---|
| `app/macos/` | ✅ 唯一原生壳（8 Swift 文件：Carbon 热键 / AX 注入 / NSPanel / Keychain / StatusBar + B1/B2 修复），**未实机编译** |
| windows/ linux/ android/ ios/ | ❌ 均未生成（`flutter create --platforms=...` 即可补脚手架） |

## 3. 三端缺口矩阵（T-030 实施时的对齐清单）

### 3.1 Linux（PRD §1 五端承诺成员，优先级高于常规）

| 能力 | macOS 现状 | Linux 缺口 | 建议路径 |
|---|---|---|---|
| 全局热键 | Carbon `RegisterEventHotKey` | 无实现 | `hotkey_manager` 插件（X11）或自写 Wayland 协议通道；Wayland 全局热键受限是已知风险 |
| 文本注入 | AX 三级降级（selectedText/value/⌘V） | 无实现 | X11: XTEST 模拟键盘；Wayland: `xdg-desktop-portal` Remote 桌面接口（重） |
| 选区读取 | AX selectedText | 无实现 | X11 主选区（primary selection）天然可用，反而最简单 |
| Key/凭据 | Keychain（SecureStorePlugin） | 无实现 | `flutter_secure_storage` Linux 后端（libsecret/GNOME Keyring） |
| 浮层 NSPanel | NSPanel + FlutterViewController | 无实现 | 新 GTK 窗口（`window_manager` 置顶+无边框）；B1 双引擎教训同样适用 |
| 菜单栏 | NSStatusItem | 无实现 | `appindicator`/`tray_manager`（GNOME 需 AppIndicator 扩展，已知生态坑） |
| 权限引导 | TCC 深链 + resumed 刷新 | 无对应体系 | Linux 无 TCC；引导页平台分支直接跳过/展示说明 |

### 3.2 Windows

| 能力 | macOS 现状 | Windows 缺口 | 建议路径 |
|---|---|---|---|
| 全局热键 | Carbon | 无实现 | `RegisterHotKey` Win32（比 macOS 简单，`hotkey_manager` 已支持） |
| 文本注入 | AX 三级降级 | 无实现 | SendInput 合成 Ctrl+V + 剪贴板；UI Automation 读选区 |
| Key/凭据 | Keychain | 无实现 | `flutter_secure_storage` Windows 后端（DPAPI） |
| 浮层 | NSPanel | 无实现 | Win32 层窗口 + `window_manager`；WSL/高 DPI 缩放需验证 |
| 菜单栏 | NSStatusItem | 无实现 | `NotifyIcon` 托盘（`tray_manager`） |
| 皮肤 | — | n1 已冻结 | pill `winSkin` 置位 + Fluent 圆角/字体（Segoe UI）替换表见 n1 规格 |

### 3.3 共通（与平台无关，三端同享）

| 层 | 状态 |
|---|---|
| Provider 四实现 / SSE / 错误收敛 | ✅ 纯 Dart，零改动 |
| ADR-008 状态机 / DraftPipeline | ✅ 纯 Dart，零改动 |
| 13 页 UI + Token 体系（T-013） | ✅ 全走 `LfScheme`/`LfComponents`，无平台硬编码（⑤ kb 皮肤固定色仅 n2 演示用） |
| Profile/History 存储 | ✅ SharedPreferences 全端可用 |
| 66 项测试 | ✅ 与平台无关 |

## 4. n1 / n2 皮肤规格 → Token 映射

| 皮肤项 | 规格来源 | Token 落点（T-013 后） | 平移动作 |
|---|---|---|---|
| Windows pill：隐藏「译」开关、Win+H 提示 | n1 §触发 | `LfComponents.pill`（winSkin 分支已实现） | 真 Windows 壳按平台传 `winSkin: true` |
| Windows 字体 Segoe UI / 圆角 8px | n1 §外观 | `AppTheme.fontFamilyFallback` / `LfDimens.rBtn` | 皮肤层 Theme 覆盖，不动基础 Token |
| Android 键盘工具条 h36 | n2 / PRD §5.3 ⑤ | `LfComponents.kb.toolbarH` | T-031 输入法实装直接消费 |
| Android 键盘底色 #D1D4DA / #E4E6EB | n2 §观感 | `LfComponents.kb.keyboardBg/toolbarBg` | 同上；Material You 动态色是否覆盖待 T-031 拍板 |
| 系统键盘同高候选区「译文流」 | n2 §候选 | 候选区 fsMd 15（`LfDimens.fsMd`） | 同上 |

## 5. T-030 领取前置（阻塞链）

1. ⛔ macOS 实机验证回传（B1/B2/R1/R3/R4/R6 判定）——原生壳的正确性口径先立住，三端照抄架构才有意义
2. ⛔ C1–C16 拍板（决策单：[`pages-specs/decision-sheet-C1-C16.md`](../pages-specs/decision-sheet-C1-C16.md)）——C7/C8 接线改变 DraftPipeline 参数面
3. ⬜ 三端脚手架生成（`flutter create --platforms=windows,linux` 一条命令，T-030 开工第一步）
4. ⬜ 建议实施顺序：Windows（生态最接近、`hotkey_manager` 现成）→ Linux（X11 先行、Wayland 风险单列）
