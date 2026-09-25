# ADR-003 · 五端覆盖，含 Linux

> **状态**：已决策（PRD v2.0）
> **决策日期**：2026-09-26

## 背景

竞品覆盖矩阵：

| 平台 | Typeless | Chatterfly | Bob | **译语** |
|---|---|---|---|---|
| macOS | ✓ | ✓ | ✓ | ✓ |
| Windows | ✓ | ✓ | ✗ | ✓ |
| Linux | ✗ | ✗ | ✗ | **✓** |
| iOS | ✓ | ✗ | ✗ | ✓（键盘扩展） |
| Android | ✓ | ✗ | ✗ | ✓（输入法） |

## 决策

**五端全覆盖**（macOS / Windows / Linux / iOS / Android），含 Linux。

## 论据

### 选覆盖的理由

1. **Linux 是开发者的关键阵地**：BYOK 目标用户（开发者、隐私敏感人群）很多用 Linux
2. **跨平台技术栈不是问题**：Flutter + 原生桥天然支持多端，Bob 没做只是因为它定位"Mac 工具"
3. **移动端是流量入口**：iOS/Android 键盘输入法是高频场景，但不能做到桌面端同等深度（iOS 限制）
4. **海外开源用户预期五端**：Sindre Sorhus 类用户的标准预期

### 优先级与节奏

- **P0**：桌面三端（macOS / Win / Linux）
- **P1**：Android + iOS（移动键盘是 P1，App 主页是 P1）

节奏：**先 macOS MVP → Win/Linux → 移动端**

### 移动端限制与对策

iOS：
- 键盘切换摩擦（PRD §2.6 已写对策）
- 键盘内不能录音（PRD §2.6 已写对策）
- 不占用 emoji 键位

Android：
- 比 iOS 宽松，可以做完整输入法
- 可以录音（前台 Service）

## 后果

- Flutter 跨平台成本可控
- 原生桥工作量不小（5 端的热键/剪贴板/IME/麦克风/钥匙串）
- 测试矩阵是 5 × 多个状态——前期只跑 macOS 一端验证

## 关联

- PRD §2.6 移动端
- PRD §3 P0 桌面三端 / P1 移动
- 与 ADR-004 Flutter 选型协同