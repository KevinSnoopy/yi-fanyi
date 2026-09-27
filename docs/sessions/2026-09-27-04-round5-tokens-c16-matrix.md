# 会话回执 · 2026-09-27-04 · Round-5（B 分支）T-013 Token 落地 + C1–C16 决策单 + T-030 矩阵

> 多 Agent 接续协议留痕。本轮未收到 macOS 实机日志（用户消息未给 result-draft），
> 按预案走 **B 分支**。**诚实声明：macOS 原生壳仍未实机编译，B1/B2 修复未经实机验证。**

## 领取任务（Round-5 · B 分支）

- **M1 · T-013** Design Token 落地：Token 表（浅/深主题 + 组件规格 ①–⑥）落 `app/lib/ui/tokens/`
- **M2** C1–C16 整理为「二选一 + 建议」决策单，待用户逐项拍板
- **M3 · T-030 准备** 三端差异矩阵（不写平台代码）

## M1 · T-013 ✅ Design Token 落地

### 结构（Token 唯一出口 `app/lib/ui/tokens/`）

| 文件 | 内容 |
|---|---|
| `lf_scheme.dart` | `LfScheme` ThemeExtension：31 项浅/深色彩（brand/accent/bg*/text*/divider*/状态色/渐变/6 档投影/menubar*/mac 红绿灯），由旧 `core/theme/tokens.dart` 1:1 平移 |
| `lf_dimens.dart` | `LfDimens`：字阶 7 档 / 圆角 5 档 / 尺寸 9 项 / 动效 4 项 / 链路节奏（1.2s 后悔窗口、1.5s 淡出） |
| `lf_components.dart` | **新增** `LfComponents`：PRD §5.3 组件规格 ①–⑥ 聚合——`pill`（160×36 基准/三态体/「译」开关/mic 圆钮 52）、`floatWin`（380×自适应/进度条 h2/原文 12 译文 15）、`selection`（320/图标钮 24）、`settings`（960×640/导航 190）、`kb`（工具条 36/iOS 皮肤固定色）、`onboarding`（三步/面板 560） |
| `tokens.dart` | barrel 统一出口 |
| `README.md` | **Token 全表**（色彩/几何/组件①–⑥ 逐项列值）+ PRD §5.2 对照 + 差异清单 T-A/T-B/T-C |

### 迁移与对齐

- 删除旧 `app/lib/core/theme/tokens.dart`；`core/theme/` 只留 `app_theme.dart`（改 import 指向新出口）
- 全库 **18 处 import 迁移**（14 UI + main.dart + 3 test），package 路径 `linguaflow/ui/tokens/tokens.dart`
- 页面硬编码改消费 Token：`phone_frames.dart` 键盘底色/工具条 → `LfComponents.kb.*`；`flow_page.dart` mic 圆钮 52×52 → `LfComponents.pill.micFab`
- 取值口径：**现行实现实测**（逐文件扫过 recorder_pill/floating_windows/flow_page/phone_frames/onboarding），与 pages-specs 规格一致；未擅改任何视觉数值

### Token 层差异（⚖️ 待拍板，拍板前实现为准）

- **T-A**：悬浮窗底深色 alpha——PRD §5.2 写 88%（#1E1F24E0），实现 92%（与浅色对称）。建议实现为准 + 改 PRD
- **T-B**：原文区底深色——PRD 写 #26282F，实现（原型值）#26282E，尾位舍入无视觉差。建议实现为准
- **T-C**：PRD §5.2 为最小集，实现另有 20+ 补充 token（bgSource 深/warning/menubar*/shadow 6 档等），已在 tokens/README.md 全表登记，无需动作

## M2 · C1–C16 决策单

产出 [`pages-specs/decision-sheet-C1-C16.md`](../../pages-specs/decision-sheet-C1-C16.md)：

- 16 项逐条「二选一（A 实现为准 / B 原型·PRD 为准）+ Agent 建议 + 拍板栏」
- **最小拍板集**：C3=B（历史行回看详情）、C4=A（隐藏 CSV/应用范围死按钮）、C5=A'（去「新建」假入口）、C6=B-lite（术语全量渲染+删除）、C7=B（预览窗口三档接入 DraftPipeline）、C8=B（自动检测接入判定链）、C9=B-lite（平台目录统一 8 个单一来源），其余 A——用户回一句「按建议来」即可整批落地
- Token 层 T-A/T-B 可并入同一句拍板

## M3 · T-030 三端差异矩阵

产出 [`docs/t030-platform-matrix.md`](../t030-platform-matrix.md)（**只盘点，未写平台代码**）：

- **全库扫描结论**：Dart 侧平台耦合极低——`kIsWeb` 仅 main.dart 3 处、`defaultTargetPlatform` 仅 hotkeys.dart 1 处，无 `dart:io`/`dart:html`/条件 import；UI 层（13 页 + Token 体系）天然可平移
- **平台目录**：仅 `app/macos/` 原生壳存在；windows/linux/android/ios 脚手架未生成
- **缺口矩阵**：Linux（X11 XTEST 注入 / 主选区读取 / libsecret 凭据 / AppIndicator 托盘 / Wayland 热键受限风险）与 Windows（RegisterHotKey / UI Automation / DPAPI / NotifyIcon）逐能力列建议路径；共通层（Provider/状态机/UI/存储/66 测试）零改动
- **n1/n2 皮肤 → Token 映射**：winSkin 分支已实现待真壳置位；`LfComponents.kb.*` 直接供 T-031 消费
- **领取前置**：实机验证回传 + C1–C16 拍板

## 回归验证

```
flutter analyze → No issues found!
flutter test   → 00:32 +66: All tests passed!
```

环境备注（本机 macOS，非前几轮 Linux 沙箱）：SDK 用 fvm 3.38.9（满足 pubspec ≥3.4.0）；两坑——① 系统代理劫持 flutter_tester localhost WebSocket 导致测试假失败，需去代理环境变量重跑；② 字体资产缺失先 `bash tool/fetch_fonts.sh`。均已记入 CONTEXT.md §6。

## 遗留与下一步

1. **macOS 实机验证**（最大遗留）：跑 `bash app/tool/macos_verify.sh` → result-draft 回传 → Round-6 转 A 分支修 Swift（重点 B1 判定/R1/R3/R4/R6 + B3 订阅者）
2. **C1–C16 + T-A/T-B 拍板** → 改代码对齐（C7/C8 接线是真代码任务）
3. T-030 在前置满足后领取（脚手架生成是第一步）
