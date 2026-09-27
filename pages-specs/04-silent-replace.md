# 04 · 静默状态条（Tab D 静默替换）— PRD §6 #4 · §2.2 流程 D · §4 规则 3

实现：`app/lib/ui/pages/flow_demos.dart`（FlowDPage）+ `overlays/floating_windows.dart`（SilentBar）。
宿主布景：Chrome · GitHub Issue 评论（#1827 · Add dark mode toggle）。无窗口打断，仅底部状态条。

## 演示序列

| 态 | 标签 | 定时 |
|---|---|---|
| 0 | 打字中 | 0s |
| 1 | 翻译中 | 1.4s |
| 2 | 已替换 | 2.7s |

## 真实交互字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `_input.text` | String | '需要给页面添加一个深色模式开关' | 非空（空→toast「输入框是空的」） | 运行时 | 宿主输入框（替换发生地） |
| `_focus` | FocusNode | — | — | 运行时 | **PRD §4 规则 3 核心**：失焦且 runner.running → `runner.abort()` + `_live=false` + toast「焦点变化 · 静默替换已终止」+ `trigger.notify` 系统通知 |
| `_live` | bool | false | — | 运行时 | SilentBar 显示开关 |
| `_done` | bool | false | — | 运行时 | 完成态（输入框描边变品牌色） |
| `_processed` / `_total` | int | 0 / text.length | — | 运行时 | 进度条 `SilentBar(processed, total, done)` |
| `_error` | String? | null | — | 运行时 | 输入框下方红字「替换失败 · {code} · detail(≤120)」 |
| `_lastOriginal` | String? | null | — | 运行时 | 撤回快照：`undo()` 恢复原文 + toast「已撤回替换」 |

## 触发与流转

- 入口：热键 hk-d（mac 默认 ⌥ ↩ / win Ctrl Alt ↩）down → `silentReplace()`；`_TriggerHint`
- `silentReplace()`：`cancelTimers()` → 快照原文 → `runner.start(中文→English)`（onDelta 更新 `_processed`）→ 完成后 `_input.text=full` + `writeBack(full)` + toast「原文已被译文替换」+ `notify('静默替换完成', '{原文≤20} → {译文≤30}')`
- 失败：`full==null/empty` → `_live=false` + toast（error 或「翻译未完成」）
