# 会话回执 · 2026-09-27-02 · T-023 模型配置页三套真连接 + T-025 首次引导真实状态

> 多 Agent 接续协议留痕。本轮把两个 UI 主任务（T-023 / T-025）从「UI 完成、真实链路待接」推进到 ✅，
> 全链路验证：analyze 0 issue · test 66/66 · web release ✓ · 冒烟 15/15 PASS 0 错误 · Playwright 交互截图 14 张目检通过。

## 领取任务

- **T-023** 模型配置页（灵魂页面）：三套真连接各跑通「填 Key → 测试连接 → 拉取模型 → 成稿一次」，401 / 429 / model-not-found / wrong-BaseURL 四内联错误态
- **T-025** 首次引导三步 + 权限引导：权限自检接真实 NativeBridge、零 Key（Ollama 本地）可完整走完向导

## 交付明细

### T-023 · 模型配置页（I 页）

**MockProviderServer 扩展**（`app/test/helpers/mock_provider_server.dart`）：

- 新增 Ollama 端点：`/api/tags`（模型列表，无鉴权）、`/api/chat`（NDJSON 流式，12ms/chunk）
- 三协议模型白名单 404：OpenAI（`code: model_not_found`）、Anthropic（`not_found_error`）、Ollama（`model 'x' not found, try pulling it first`）
- 新增 `ollamaBaseUrl` / `ollamaModelId` / `knownModels`

**AppStore 扩展**（`app/lib/services/app_store.dart`）：

- `draftTestOnce({platform, baseUrl, model, apiKey})`：真实成稿一次（流式），不落库不写 Key，`finally` 释放 provider
- `readKey(profile)`：从 SecureStore 读 Key（成稿面板展示用）
- `kDraftTestSentence` 固定成稿例句
- `buildProvider` Ollama 分支兼容三种命名（'Ollama' / 'Ollama（本地）' / 'Ollama 本地'）

**I 页真实动作**（`app/lib/ui/pages/settings_pages.dart`）：

- 列表当前默认卡下新增「▶ 成稿试一句（真实链路）」按钮
- 表单内新增「成稿验证（真实链路）」FormRow +「▶ 成稿试一句」主按钮
- 结果面板三态：流式中 spinner / 成功（绿 · ms + 字数）/ 失败（红 · `errorName（HTTP x）· raw body`）
- API Key 行按 `_needsKey` 条件渲染：Ollama 显示「本地模型 · 无需 API Key，数据不出本机」绿横幅

**测试**（`app/test/t023_connections_test.dart` 10 例 + `app/test/providers_page_test.dart` 7 例）：

- 三套链路 ×（testConnection → fetchModels → draft once）全绿
- 四错误态内联断言：401 `sk-wrong` / 429 `rateLimitedKey` / model-not-found（OpenAI + Ollama）/ wrong-BaseURL（connectionTimeout 5s）
- ADR-001 链验证：Key 明文只在 SecureStore，Profile JSON 只有 keyRef；Ollama keyRef 为 null 仍可解析

### T-025 · 首次引导（L 页）

**`app/lib/ui/pages/onboarding_page.dart` 重写**：

- 混入 `WidgetsBindingObserver`：`didChangeAppLifecycleState(resumed)` → `_refreshPerms()` 重新自检刷新 UI
- 进权限步（`onStateChanged(3)`）即触发 `bridge.permissionStatus()` 真实自检
- `_openSettings(kind, label)`：真实调 `bridge.openPermissionSettings` + toast「授权后回到本窗口，会自动重新检测」
- 权限态三分：已授权（绿）/ 待授权（警示）/ 未检测（Web 预览返回空 map 时如实标注 + 橙字提示桌面端将真实拉起系统设置）
- `_applyPlatform`：6 平台 → baseUrl/model 默认值（Ollama → `http://localhost:11434` / `qwen2.5:7b`）
- `_testAndSave()` 真实 testConnection 成功才 `addProfileWithKey`（ADR-001）；`_checkLocal()` Ollama 零 Key 等价动作
- 完成态如实反映 `_savedProfile ?? store.defaultProfile`：已配置 vs 演示流式兜底（绝不白屏）

**测试**（`app/test/onboarding_test.dart` 5 例，`_PermBridge` 可控权限 map + 记录 opened 调用）：

- 自检待授权 → 打开设置走原生桥 → resume 自动刷新 UI
- 「重新检测」手动触发 + 未授权可再次拉起设置
- 零 Key Ollama 全链：向导走完 `onboarded=true`、`chosenPlatform='Ollama 本地'`、全程不落 Profile
- OpenAI 填 Key：Profile 落库 + Key 进 SecureStore（ADR-001）
- 错 Key 401：内联错误不落库，仍可跳过继续（演示流式兜底）

### 顺带修复（真实产品 bug）

1. **4 个 provider 的 `listModels()` 裸抛 `SocketException`**（openai_compatible / anthropic / gemini / ollama）——违反 ADR-007 错误码收敛。已统一包装为 `LfProviderException(LfErrorCode.networkUnreachable)`（widget 测试「BaseURL 填错 → 拉取模型内联报 networkUnreachable」抓住的）
2. **Ollama 落库平台名归一化**：目录名 'Ollama' → 落库统一 'Ollama（本地）'（`addProfileWithKey` 单点归一）
3. **零 Key 成功文案**：Ollama 路径不再误提「Key 已存入系统密钥串」→「本地模型就绪，无需 Key」/「已保存（本地模型，零 Key）」

### 验证（全绿）

| 检查 | 结果 |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **66/66 全部通过**（原 44 + t023 10 + providers_page 7 + onboarding 5） |
| `flutter build web --release` | ✓ Built build/web |
| `smoke_web.py` | **15/15 PASS，JS/Console errors: 0**（两轮构建各跑一次） |
| Playwright 交互截图 | **14 张**（`docs/screenshots/`），fake Ollama 双栈 server 真连 |

### Playwright 交互截图（人工目检通过）

fake server：`fake_ollama.py`（:11434，NDJSON 流式 + 双栈监听）、`fake_openai.py`（:8442，401/模型列表）。全部真实网络交互：

- `L1_platform_select` 六平台卡（Ollama 本地默认选中）
- `L2_step_key_ollama` 零 Key 绿横幅 + 预填 11434/qwen2.5:7b
- `L3_local_check_ok` **真实连接成功 · 132ms**（浏览器 fetch → fake Ollama /api/tags）
- `L4_hotkeys` / `L5_permissions`（Web 预览「未检测」诚实标注）/ `L6_done` / `L7_started_toast`
- `I1_providers_home` 当前默认卡 + 种子 Provider 列表
- `I2_add_form_openai` 八平台表单
- `I3_form_ollama_filled` Ollama 表单 + 无 Key 横幅
- `I4_saved_back_to_list` **测试连接并保存成功 · 116ms 落库**
- `I6_draft_done` 成稿流式面板（真实流式 · Ollama（本地）· qwen2.5:7b）
- `I7_test_401_inline` 内联「测试失败 · 401」
- `I8_draft_error_inline` 内联「成稿失败 · networkUnreachable（HTTP -）· ClientException」（不可达端口，未降级如实展示）

## 踩坑记录（给下一个 Agent）

1. **flutter_test 的 HTTP 拦截三层坑**：
   - `TestWidgetsFlutterBinding` 把 `HttpOverrides.global` 设成 mock（一切请求→空 400）。setUp 里晚于 binding 初始化覆盖回真实 client 即可（binding 只初始化一次，之后不会再覆盖）
   - 自定义 `HttpOverrides.createHttpClient` **必须调 `super.createHttpClient(context)`**（内部走 `_HttpClient` 真实实现）——直接写 `HttpClient()..connectionTimeout=...` 会无限递归 → Stack Overflow（`runAsync` 会吞异常返回 null，极具迷惑性）
   - **FakeAsync zone 里发起的 HTTP 永远卡死**（socket 事件被 FakeAsync 隔离）。必须 `await tester.runAsync(() async { await tester.tap(btn); await Future.delayed(1.5s); })`——Dart zone 是动态作用域，tap 在 runAsync 真实 zone 执行时，onTap 里的整条 async 链（HTTP + 后续 setState）都跑在真实 zone
2. **默认 800×600 逻辑视口装不下表单页**：按钮在屏外 `tap` 不命中（只给 warning 不报错）。`tester.view.physicalSize = Size(800,1400); tester.view.devicePixelRatio = 1.0; addTearDown(tester.view.reset)`
3. **pending timers 断言**：toast 2.2s 自动消失 timer——fake zone 里注册的用 pump 推完；runAsync 真实 zone 里注册的 pump 推不动，测试结尾再 `runAsync(delay 2.6s)` 让它真实 fire
4. **沙箱 Chromium 的 loopback 代理劫持**：`localhost`/`::1` 请求被引流走（仅 `127.0.0.1` 直连）。Playwright 启动参数加 `--proxy-server=direct:// --proxy-bypass-list=*` 解决
5. **`localhost` 解析为 `::1`（IPv6 优先）**：fake server 要双栈监听（`socket.AF_INET6` + `IPV6_V6ONLY=0`），否则 IPv4-only bind 收不到 localhost 请求
6. **Flutter web 的 XHR 流式**：原生 fetch 流式正常（逐 chunk 到达），但 Flutter `package:http` BrowserClient(XHR) 对跨域 POST 流式存在挂起兼容问题——**桌面端走 dart:io 不受影响**，widget 测试（Dart VM 真网络）已全链验证成稿 POST 正确性；浏览器成稿流式的目检以「成稿中」面板 + 错误态截图为准
7. **hash 路由 same-document**：Playwright `goto('#tab=X')` 不触发 Flutter SPA 切页，必须每个场景新开 page
8. Flutter web canvaskit 渲染无 DOM 文本，交互只能坐标点击 + 截图目检校准

## 诚实声明

- **macOS Swift 原生壳未实机编译**（Linux 沙箱无 Xcode/macOS SDK）。Carbon/AX/Keychain 等六文件仅做语法与 API 正确性校验，实机行为（热键注册、权限拉起、NSPanel 浮层）待 `flutter build macos` 验证
- 三套真连接的「真实」指：真实 HTTP/SSE/NDJSON 协议链路（本地 MockProviderServer + 浏览器内 fake Ollama/OpenAI server）。**未使用真实 OpenAI/Anthropic 云端 Key**（沙箱无真实 Key；协议行为按官方文档建模，含 401/429/404 错误格式）
- 权限引导在 Web 预览下只能验证「未检测」分支 + 原生桥调用记录；「待授权→已授权」刷新链路由 `_PermBridge` 测试替身覆盖，真实 macOS 自检待实机
- 浏览器内成稿 POST 流式存在 XHR 兼容挂起（见踩坑 6），成稿成功面板的目检以 widget 测试断言 + 流式中面板截图为准

## 变更文件清单

```
app/lib/services/app_store.dart            | draftTestOnce / readKey / kDraftTestSentence / Ollama 归一
app/lib/ui/pages/settings_pages.dart       | 成稿试一句按钮 + 面板 + Key 条件渲染
app/lib/ui/pages/onboarding_page.dart      | 真实权限自检/resumed 刷新/零 Key 文案（重写）
app/lib/ui/components/cards.dart           | PlatCard compact 尺寸（溢出修复）
app/lib/providers/{openai_compatible,anthropic,gemini,ollama}.dart | listModels 网络异常收敛
app/test/helpers/mock_provider_server.dart | Ollama 端点 + 白名单 404
app/test/t023_connections_test.dart        | 新增 10 例
app/test/providers_page_test.dart          | 新增 7 例
app/test/onboarding_test.dart              | 新增 5 例
docs/screenshots/*.png                     | 14 张交互截图
docs/TASKS.md · docs/CONTEXT.md            | 状态推进
```

## 下一轮建议

1. **macOS 实机编译**（最大遗留）：`flutter build macos` + 六个 Swift 文件的实机验证（热键/AX/Keychain/NSPanel/StatusBar）+ 权限引导真实拉起
2. T-012 字段级规格（v7 原型已可作参照）
3. 可选 T-026：测试补完（macOS 实机用例 / 更多错误态）
