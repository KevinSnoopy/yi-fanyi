# 03 · 划词译文小窗（Tab C 划词翻译）— PRD §6 #3 · §2.2 流程 C

实现：`app/lib/ui/pages/flow_demos.dart`（FlowCPage）+ `overlays/floating_windows.dart`（SelectionMarker / SelectionPopover）。
宿主布景：Chrome · Medium 文章（正文含可点选高亮词）。

## 演示序列

| 态 | 标签 | 定时 | 内容 |
|---|---|---|---|
| 0 | 选词 | 0s | 正文高亮 initialWord |
| 1 | 弹窗 | 0.7s | SelectionMarker 出现 |
| 2 | 翻译 | 1.7s | 预置译文「忘记取消订阅」渐进 |
| 3 | 替换 | 3.0s | 选区词被译文替换 |

## 真实交互字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `_word` | String | 'forget to unsubscribe' | 非空（trim 后） | 运行时 | 展示词；open 时被 native 选区或页面点选覆盖 |
| `_live` | bool | false | — | 运行时 | 真实弹窗开关 |
| `_streamed` | String | '' | — | 运行时 | 流式译文 |
| `_streaming` | bool | false | — | 运行时 | SelectionPopover.translating |
| `_error` | String? | null | — | 运行时 | 弹窗内 `{code} · detail(≤120)`（替代译文位置） |
| `_latency` | String | '68ms'（演示初值） | — | 运行时 | 真实跑后覆盖为 Stopwatch 值 |
| `_tap` | TapGestureRecognizer | null | — | 运行时 | 正文高亮词点选 = open() 兜底入口 ⚖️ C11 |
| `id` | String | 'c-sel' | — | 常量 | overlay id；TriggerRequest.text=_word |

## 触发与流转

- 入口：热键 hk-c（默认 ⌥ D）down → `open()`；正文点选高亮词；`_TriggerHint`
- `open()`：`scope.trigger.readSelection()`（原生 AX 优先）→ null/空则用 `_word`（页面点选兜底，⚖️ C11）→ 空则 toast「未读取到选区」→ `requestOverlay(selectionPopover, text:word)` → `translate(word)`
- `translate()`：runner.start(sourceLang:'English', targetLang:'中文')（方向与 B 相反）
- `replace()`：`writeBack(_streamed)` → toast「已替换选区」→ close
- `copyOnly()` / `close()` 同 B 页语义
