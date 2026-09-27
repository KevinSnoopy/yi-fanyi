# 05 · 截图 OCR 双栏窗（Tab E OCR 翻译）— PRD §6 #5 · §3 P1

实现：`app/lib/ui/pages/flow_demos.dart`（FlowEPage）+ `overlays/floating_windows.dart`（OcrSelectionMask / OcrResultWindow）。
宿主布景：PDF · 合同节选（ARTICLE 3 · DELIVERY TERMS）。

## 演示序列（⚖️ C13：无真实截图/识别链路，PRD §3 定 P1）

| 态 | 标签 | 定时 | 内容 |
|---|---|---|---|
| 0 | 框选 | 0s | OcrSelectionMask（半透明遮罩 + 选框） |
| 1 | OCR 识别 | 1.2s | 识别中 |
| 2 | 双栏结果 | 2.6s | OcrResultWindow：左原文（合同 3.1 条英文）右译文（中文） |

## 字段表（演示驱动，无常驻持久化字段）

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 |
|---|---|---|---|---|---|
| `source` | String | 合同 3.1 英文条款常量 | — | 硬编码 | 双栏左 |
| `target` | String | 中文译文常量 | — | 硬编码 | 双栏右 |
| OcrResultWindow 动作 | — | — | — | — | onCopySource / onCopyTarget / onInject / onDone **均为空实现**（演示占位） |

## 备注

- 本页无 LiveFlowMixin（不走真实 Provider 链路）——OCR 属 P1 功能，Tab E 的职责是**冻结双栏窗交互形制**供 T-040 实装参照。
- 若后续实装：预期字段为 截图源 / 框选坐标 / OCR 引擎选择（本地 Vision / 云 OCR）/ 识别文本（可编辑）/ 译文，均持久化为「运行时+HistoryRecord」。
