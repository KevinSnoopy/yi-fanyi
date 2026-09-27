# 10 · 首次引导三步 + 权限引导（Tab L）— PRD §6 #10 · §5.3 ⑥

实现：`app/lib/ui/pages/onboarding_page.dart`（OnboardingPage），五态向导（0 选平台 / 1 填 Key / 2 设热键 / 3 权限引导 / 4 完成），向导卡 560 宽居中，_dots 进度点。
T-025：真实权限自检 + 零 Key（Ollama）全链。混入 WidgetsBindingObserver（resumed 自动重检）。

## 字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `stateIdx` | int | 0 | — | 运行时（FlowDemoStateMixin） | 上一步/下一步/完成按钮流转；demo 控制可跳态 |
| `selectedPlat` | int | **5（Ollama 本地，零 Key 体验）** | — | 运行时 | PlatGrid（kOnboardingCatalog 6 平台）⚖️ C9 目录与 I 页不一致 |
| `_keyCtl` | String | '' | 非 Ollama 时测试成功才落库；表单本身无硬校验（失败可跳过） | 运行时 → SecureStore | obscure；hint「存入系统密钥串，明文不落盘」+ 四平台申请链接行 |
| `_baseUrlCtl` | String | 按平台 switch（OpenAI api.openai.com/v1 / Anthropic / Gemini / DeepSeek / 通义 / Ollama localhost:11434） | — | 运行时 | TextField |
| `_modelCtl` | String | 按平台（gpt-4o-mini / claude-sonnet-4 / gemini-2.0-flash / deepseek-chat / qwen-plus / qwen2.5:7b） | — | 运行时 | TextField |
| `_testing` / `_checkingLocal` | bool | false | — | 运行时 | spinner「测试连接中…/检测本地 Ollama…」 |
| `_testResult` | ConnectionTestResult? | null | — | 运行时 | `_testResultBar`：成功绿卡「连接成功 · {ms}ms · 已保存（{本地模型零 Key / Key 已存入系统密钥串}）」；失败红卡「测试失败 · {code}（未保存，可重试或跳过）」+ 模型方原始返回（≤3 行） |
| `_savedProfile` | ProviderProfile? | null | — | 运行时 | 成功才非空；完成态据此如实反映 |
| `_perms` | Map<String,bool> | {} | — | 运行时（bridge.permissionStatus()） | 三分态：true「已授权」绿 / false「待授权」警示 / null「未检测」（Web 预览空 map 如实标注）⚖️ 契约表 R6 桩值风险 |
| `_permChecking` | bool | false | — | 运行时 | spinner「检测中…」 |
| `store.onboarded` / `store.chosenPlatform` | bool / String? | false / null | — | **Profile** | 「开始使用」→ `setOnboarded(_plat.name)` + toast「首次引导完成 · {label 或 演示流式兜底}」 |

## 各步动作

| 步 | 按钮 | 语义 |
|---|---|---|
| 0 选平台 | 稍后再说 / 下一步 | 「稍后再说」直接跳权限步（3） |
| 1 填 Key | 上一步 / 测试连接并保存（或 Ollama：「检测本地连接」） / 跳过，先用演示流式 / 下一步 | `_testAndSave()`：testConnection 成功才 `addProfileWithKey`（Ollama apiKey=null）；Ollama 走 `_checkLocal()` 等价动作 |
| 2 设热键 | 上一步 / 下一步 | 展示 hk-a/hk-b 真实当前值（HotkeyRow 只读）+ 生效范围（原生全局 / 应用内） |
| 3 权限引导 | 上一步 / 完成 | 进态即 `_refreshPerms()`；两个 permCard：辅助功能（监听热键+注入文本）/ 输入监控（划词 C/D）；未授权→「打开设置」→ `openPermissionSettings(kind)` + toast「授权后回到本窗口，会自动重新检测」；resumed 自动重检；「重新检测」手动触发；Web 预览橙字「当前环境未接原生权限接口」 |
| 4 完成 | 开始使用 · 按住 Fn 说话 → | 落 onboarded；Badge：{label 或 演示流式}（live=configured）/ 零遥测 / 五端同步 |

## 错误态

- 测试失败：内联红卡（不落库）+ 仍可「跳过，先用演示流式」继续（绝不白屏，PRD §7）
- 401 错 Key： errorCode 内联；权限 bridge 异常：catch 后空 map（未检测态）
