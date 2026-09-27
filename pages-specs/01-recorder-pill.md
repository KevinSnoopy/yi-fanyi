# 01 · 录音条三态（Tab A 语音输入）— PRD §6 #1 · §2.1 · §5.1

实现：`app/lib/ui/pages/flow_page.dart`（FlowPage）+ `app/lib/ui/overlays/recorder_pill.dart`（RecorderPill）+ `app/lib/engine/recorder_state_machine.dart`（RecorderStateMachine）+ `app/lib/engine/draft_pipeline.dart`。
定位：成稿为主、翻译是开关（PRD v3.2）；Typeless 式 pill（160×36 基准）。

## 字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `sm.phase` | RecorderStatePhase | idle | — | 运行时（状态机） | idle→recording（按下）→transcribing→previewing（1.2s）→done/error；Esc 任意时刻取消（CallbackShortcuts） |
| `sm.translateOn` | bool | false | — | 运行时 | pill 右侧「译」开关点按切换；开=成稿→中→英双语写回 |
| `sm.previewText` | String | '' | — | 运行时 | 预览态展示；确认=`sm.confirm(previewText)` 落框 |
| `sm.error` | LfProviderException? | null | — | 运行时 | 非空→`_ProviderBanner` 切错误条（红底）：`成稿失败 · {code.name} · detail(≤120字)` + 「用演示流式重试」按钮 + ✕ 关闭（`sm.clearError`） |
| `_source` | ProviderSource | mock | — | 运行时（`store.resolveProvider()` 判定链） | 血缘明示：real→绿点「真实模型 · {platform}·{model} · 请求直连（ADR-001）」；mock→黄点 |
| `_modelLabel` | String | '演示流式 · MockProvider' | — | 运行时 | 状态条文本；真实时 `{platform} · {model}` |
| `_forceDemo` | bool | false | — | 运行时 | 错误条点「重试」置 true；**下次按住重新置 false**（真实优先判定链恢复） |
| `_input.text` | String | '' | — | 运行时（落框目标） | 成稿 onFinal 写入 + requestFocus；hint「按住下方 🎤 说话…（Esc 取消）」 |
| 宿主布景 | — | 微信·给李总的消息 | — | 硬编码 | ⚖️ C10 实现为准 |
| 「已发送 N 条」 | int | 2 | — | 硬编码 | ⚖️ C10 |

## 触发方式（互斥不重复）

| 入口 | 事件 | 行为 |
|---|---|---|
| 🎤 圆钮（右下 52×52） | onTapDown / onLongPressStart | `_startHold()`：`_forceDemo=false` + `sm.startRecording()` |
| 同上 | onTapUp/Cancel / onLongPressEnd/Cancel | `_endHold()`：仅 recording 态有效 → `_runPipeline()` |
| 全局热键 hk-a（默认按住 Fn，holdToRecord） | HotkeyEvent.down / up | down=_startHold / up=_endHold（仅订阅 `hotkeyEvents` 进程内流——原生模式下见契约表 §3-B3） |
| Esc | CallbackShortcuts | `pipeline.abort()` |

## 成稿链路（`_runPipeline`）

1. `_refreshProvider()`：`_forceDemo` ? 演示流式 : `store.resolveProvider()`（无 Profile/无 Key/未验证成功 → 演示流式；否则真实）——**每次录音热替换**，换模型/Key 下次录音生效
2. `pipeline.run(glossaryJson: store.glossaryJson(), tone: 'im', bilingual: store.bilingualWriteBack, onError, onFinal)`
3. onFinal：落框 + `store.addHistory(HistoryRecord(flow:'A', dir: translateOn?'中→英':'成稿', …))`
4. onError：toast `成稿失败 · {code}` + 状态机 error 态（**不自动降级**，PRD §7 兜底对象是「未配置」而非真实故障）

## 错误态汇总

| 错误 | 呈现 | 出口 |
|---|---|---|
| 真实模型失败（401/429/网络等） | 红条内联原始返回（≤120 字）+「用演示流式重试」 | 一键降级重跑 / ✕ 关闭 |
| 未配置模型 | 黄点「演示流式 · MockProvider（未配置可用模型）」 | 正常走演示流 |
| 用户取消（Esc / pill 取消） | 无错误 toast（`streamAborted` 判定） | 回 idle |
