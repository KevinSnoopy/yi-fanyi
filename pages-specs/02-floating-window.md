# 02 · 迷你悬浮窗（Tab B 悬浮窗）— PRD §6 #2 · §2.2 流程 B

实现：`app/lib/ui/pages/flow_demos.dart`（FlowBPage）+ `app/lib/ui/overlays/floating_windows.dart`（MiniFloatingWindow 演示态）+ `overlays/live_overlays.dart`（LiveFloatingWindow 真实态）+ `services/system_trigger.dart`。
宿主布景：Slack · 工程频道。双落地：system（原生 NSPanel）/ inApp（页面内浮层）。

## 演示序列（FlowDemoStateMixin，定时器驱动）

| 态 | 标签 | 定时 | 内容 |
|---|---|---|---|
| 0 | 触发 | 0s | MiniFloatingWindow 空态 |
| 1 | 加载 | 0.6s | 加载指示 |
| 2 | 流式 | 1.5s | 预置文本 55% 渐进 |
| 3 | 完成 | 3.2s | 全文 + 复制/注入按钮 |

## 真实交互字段表（LiveFlowMixin + LiveFloatingWindow）

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `_live` | bool | false | — | 运行时 | true=真实浮层挂载；false=演示态 |
| `_input.text` | String | 预置中文例句 | 非空才 submit | 运行时 | 浮层输入框；open 时若为空自动读剪贴板（≤500 字才填入） |
| `_streamed` | String | '' | — | 运行时 | `runner.start` onDelta 增量渲染 |
| `_streaming` | bool | false | — | 运行时 | true=流式中（submit 置位） |
| `_error` | String? | null | — | 运行时 | `{e.code.name} · detail(≤140)` 浮层内展示；runner 返回空且 error 非空 → toast |
| `_latency` | String | '—' | — | 运行时 | Stopwatch 真实耗时 `{ms}ms` |
| `_host.text` | String | '' | — | 运行时 | 宿主输入框（写回落点）；writeBackAndClose 时写入 |
| `modelLabel` | String | 演示流式 | — | 运行时 | `runner.source==real ? '{platform}·{model}' : '演示流式 · MockProvider'` |
| `id`（浮层） | String | 'b-float' | — | 常量 | showOverlay/hideOverlay/close 共用 |

## 触发与流转

- 入口：热键 hk-b（默认 ⌥ Space）down → `open()`；兜底 `_TriggerHint` 点击
- `open()`：`cancelTimers()`（演示/真实互斥）→ `requestOverlay(TriggerRequest(id:'b-float', kind:floatingWindow))` → mode==system ? toast「已唤起系统悬浮窗（原生 NSPanel）」: toast「应用内降级」→ 空输入读剪贴板
- `submit()` → runner.start(sourceLang:'中文', targetLang:'English', style: store.translateStyle)
- `writeBackAndClose()`：`writeBack(_streamed, target:_host)`（原生 injectText / 降级剪贴板）→ toast → `close()`
- `copyOnly()`：Clipboard.setData → toast「译文已复制」
- `close()`：`runner.abort()` + `trigger.close('b-float')` + `_live=false`
