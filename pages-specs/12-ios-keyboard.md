# 12 · 移动端键盘（Tab G）— PRD §6 #12 · §5（B.5 验收项）

实现：`app/lib/ui/pages/mobile_pages.dart`（IosKbDemoPage）。五态演示序列（定时器），**UI 形制冻结**供 T-031/T-032 实装（Android 输入法 / iOS 键盘扩展）。

## 演示序列

| 态 | 标签 | 定时 | 内容 |
|---|---|---|---|
| 0 | 键盘展开 | 0s | IosKeyboard 基础态（系统键盘区 + 工具条） |
| 1 | 选语种 | 1.5s | 工具条语种瞬切 UI |
| 2 | 输入 | 3.0s | 输入框出现原文「下周三能签吗？」 |
| 3 | 翻译中 | 4.5s | 键盘区加载态 |
| 4 | 候选词 | 6.0s | 三条候选：Can we sign it by next Wednesday? / Can we sign by next Wed? / Shall we sign by next Wed? |

## 字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 |
|---|---|---|---|---|---|
| `original` | String | '下周三能签吗？' | — | 硬编码 | 态 2 输入行 + 态 4 候选源 |
| `candidates` | List<String> | 上述三条 | — | 硬编码 | 态 4 候选流 |
| `stateIdx` | int | 0（自动重放） | — | 运行时 | demo 控制跳态 |
| WechatThread | name/incoming | '给 Daniel' / 'Great, let's set up a call.' | — | 硬编码 | 白绿气泡布景 |
| _IosInputRow | text | null→original（态≥2） | — | 运行时 | mic 圆钮 + 输入框 + 表情 |

## 备注

- 本页无真实翻译链路（不挂 LiveFlowMixin）；键盘内「译文流」由 candidates 静态呈现。
- 实装预期（T-031/T-032）：键盘扩展内 BYOK 直连（Key 经 App Group 共享）、候选词上屏、术语表联动、未启用键盘的引导跳系统设置（PRD §7）。
