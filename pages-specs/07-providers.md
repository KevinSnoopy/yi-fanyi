# 07 · 模型配置 · 灵魂页面（Tab I）— PRD §6 #7 · §5.3 ④

实现：`app/lib/ui/pages/settings_pages.dart`（ProvidersPage）。四态：0 空 / 1 列表 / 2 新增表单 / 3 测试结果。
ADR-001：Key 明文只进 SecureStore（macOS Keychain），Profile 只留 keyRef。

## 页面级状态

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 |
|---|---|---|---|---|---|
| `view` | int | 1 | — | 运行时 | 0/1/2/3 四态；`profiles.isEmpty && view==1` 强制回落空态 |
| `selectedPlat` | int | 0 | — | 运行时 | PlatGrid 选择 → `_applyPlatform(i)` 重置表单默认值 |
| `_obscure` | bool | true | — | 运行时 | Key 显示/隐藏按钮 |
| `_testing` | bool | false | — | 运行时 | 测试中 spinner |
| `_lastTest` | ConnectionTestResult? | null | — | 运行时 | 成功绿卡（latencyMs）/ 失败 InlineError |

## 表单字段

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `_baseUrl` | String | `store.formDefaults(platform).baseUrl`（OpenAI 兼容官方端点 / Ollama http://localhost:11434） | **必填**（空→view=3 错误卡 `config · BaseURL / 模型 / API Key 不能为空`） | 运行时（默认值来自 Provider 静态目录） | TextField；hint「流量直连该地址，零遥测（ADR-001 §2）」 |
| `_key` | String | '' | `_needsKey` 时**必填**（同上 config 错误）；Ollama 隐藏此行 | 运行时 → 保存后进 **SecureStore**（keyRef= `ref-{profileId}`） | obscureText + 显示/隐藏；Ollama 显示绿横幅「本地模型 · 无需 API Key，数据不出本机」 |
| `_model` | String | `formDefaults().model` | **必填**（同上） | 运行时 | TextField + 「拉取模型列表」按钮 → `_fetchModels()`（纯探测不落库） |
| `_models` | List<String> | [] | — | 运行时 | `take(40)`；Wrap 前 12 个 chip，点击回填 `_model`；空列表→「模型方返回空列表」 |
| `_modelError` | String? | null | — | 运行时 | 「拉取失败 · {e.code.name} · detail(≤160)」红字（LfProviderException 收敛码；其它异常原样 toString） |

## 成稿验证（T-023）

| 字段 | 类型 | 默认值 | 交互 / 错误态 |
|---|---|---|---|
| `_draftTesting` | bool | false | 「▶ 成稿试一句」按钮禁用态 |
| `_draftOutput` | String | '' | 流式增量实时拼接进 `_draftPanel` |
| `_draftError` | String? | null | `{e.code.name}（HTTP {status 或 '-'}）· detail(≤200)`；面板红边 + toast「成稿失败 · {code}」；**未降级，如实展示** |
| `_draftMs` | int? | null | 成功面板「成稿完成 · {platform}·{model} · {ms}ms · {n} 字」+ toast |

- 列表页入口：「▶ 成稿试一句（真实链路）」→ `_draftFromProfile(defaultProfile)`：**Key 从 SecureStore 读**（`store.readKey`）；无默认 Profile 时按钮禁用
- 表单页入口：FormFieldRow「成稿验证（真实链路）」→ `_draftOnce(表单当前值)`（不落库不写 Key）

## 动作与流转

| 动作 | 语义 |
|---|---|
| 「测试连接并保存」 | `_testAndSave()`：`store.testConnection`（真实 HTTP）→ 成功才 `addProfileWithKey(healthy:true, latencyMs)`（Key 进 SecureStore）→ 回列表 + toast「连接成功 · {platform} · {ms}ms」 |
| 失败态 | InlineError「测试失败 · {errorCode}」+ 模型方原始返回（≤220 字）+ 动作：「→ 返回修改 Key」「→ 先用本地模型试用」（跳 L）+ **「跳过测试，直接保存（标记为未验证）」**（healthy=false，⚖️ C15 实现为准） |
| 列表 ProviderRow | 点击=setDefault；删除=removeProfile（**连带删 Key**，ADR-001） |
| 当前默认卡 | `_CurrentModelRow`：displayLabel / Ollama→「本地 · 离线 · 零成本」否则「直连 {baseUrl}」/ Badge healthy?'在线':'未测' |

## 错误态码表（LfProviderException 收敛，ADR-007）

401（Key 无效）/ 429（限流）/ model_not_found / connectionTimeout（BaseURL 错）/ networkUnreachable（DNS/端口）/ config（本页表单校验）。原始 body ≤120/160/200/220 字分级截断展示。
